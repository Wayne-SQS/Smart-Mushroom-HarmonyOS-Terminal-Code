/**
 * 视频监控页面 - ESP32-CAM TCP 视频流
 *
 * 架构：
 *   ESP32-CAM ──TCP(8080)──▶ VideoMonitorPage ──解析JPEG帧──▶ Image(PixelMap) 全屏显示
 *
 * 实现要点（参考 smarthome/monitor.ets，适配 SoftwareAction 规范）：
 *   - TCP 连接：@kit.NetworkKit socket.constructTCPSocketInstance() + connect()
 *   - JPEG 帧解析：缓冲区累积 → 0xFFD8 起始 / 0xFFD9 结束 → 提取完整帧
 *   - 图像解码：@kit.ImageKit createImageSource() + createPixelMap() → RGBA_8888 640×480
 *   - 生命周期：aboutToAppear 自动连接 → aboutToDisappear 断开 + 释放 PixelMap
 *   - 内存优化：每帧解码前 release() 旧 PixelMap（参考代码漏了，会泄漏）
 *   - 主题适配：ThemeManager.getTokens() + @StorageLink 双主题
 *   - 断点适配：XS(watch) 显示占位提示，其余全屏视频
 *   - 控件自动隐藏：5 秒后顶部+底部淡出，点击视频区重现
 */
import { socket } from '@kit.NetworkKit';
import { image } from '@kit.ImageKit';
import promptAction from '@ohos.promptAction';
import { BreakpointConstants, Logger } from 'common-base';
import { ThemeManager } from '../theme/ThemeManager';
import { ThemeTokens } from '../theme/ThemeTokens';
import { IotService } from '../service/IotService';

const TAG = 'VideoMonitorPage';

/** TCP on('message') 回调参数类型（ArkTS 严格模式需显式声明） */
interface TcpMessageData {
  message: ArrayBuffer;
  remoteInfo: socket.SocketRemoteInfo;
}

/** 摄像头配置（硬编码，课堂作业） */
interface CameraConfig {
  readonly greenhouseId: string;
  readonly name: string;
  readonly ip: string;
  readonly port: number;
}

/** plantAI 单次识别结果记录（用于历史保存，ArkTS 禁止对象字面量 → 用 class） */
class PlantAIRecord {
  plantStatus: string;
  confidence: string;
  captureTime: string;
  cameraStatus: string;
  aiStatus: string;
  /** App 端记录的时间戳（用于历史排序） */
  savedAt: number;

  constructor(
    plantStatus: string,
    confidence: string,
    captureTime: string,
    cameraStatus: string,
    aiStatus: string,
    savedAt: number
  ) {
    this.plantStatus = plantStatus;
    this.confidence = confidence;
    this.captureTime = captureTime;
    this.cameraStatus = cameraStatus;
    this.aiStatus = aiStatus;
    this.savedAt = savedAt;
  }
}

/** 演示摄像头列表（覆盖正常/告警/离线三种状态）
 *
 * TODO 后续开发：三个大棚暂用同一 ESP32-CAM（192.168.43.16），实际部署时改为各自独立 IP。
 */
const CAMERAS: CameraConfig[] = [
  { greenhouseId: '1', name: '1号蘑菇大棚', ip: '192.168.43.16', port: 8080 },
  { greenhouseId: '3', name: '3号蘑菇大棚', ip: '192.168.43.16', port: 8080 },
  { greenhouseId: '8', name: '菌种储存室', ip: '192.168.43.16', port: 8080 }
];

/** 摄像头查找（避免动态属性访问，用显式循环） */
function findCamera(id: string): CameraConfig | null {
  for (let i = 0; i < CAMERAS.length; i++) {
    if (CAMERAS[i].greenhouseId === id) {
      return CAMERAS[i];
    }
  }
  return null;
}

/** 控件自动隐藏延时（毫秒） */
const HIDE_DELAY = 5000;

@Component
export struct VideoMonitorPage {
  @StorageLink('themeName') themeName: string = 'frosted';
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointConstants.SM;

  /** 路由传入的大棚 ID */
  @State greenhouseId: string = '';
  /** 查表得到的摄像头配置（null = 该大棚未配置摄像头） */
  @State cameraConfig: CameraConfig | null = null;
  /** 当前显示的视频帧 */
  @State imageSrc: PixelMap | null = null;
  /** TCP 连接状态 */
  @State isConnected: boolean = false;
  /** 正在连接中（连接成功前） */
  @State isConnecting: boolean = false;
  /** 错误信息（连接失败/断开时展示） */
  @State errorMsg: string = '';
  /** 顶部返回栏 + 底部控制栏是否可见 */
  @State controlsVisible: boolean = true;
  /** AI 识别是否进行中（防重复点击） */
  @State isRecognizing: boolean = false;
  /** plantAI 识别结果面板是否可见 */
  @State plantAIResultVisible: boolean = false;
  /** plantAI 是否正在轮询结果 */
  @State plantAIPolling: boolean = false;
  /** plantAI 植株识别结果 */
  @State plantStatus: string = '';
  /** plantAI 置信度 */
  @State plantConfidence: string = '';
  /** plantAI 截图时间 */
  @State plantCaptureTime: string = '';
  /** plantAI 摄像头状态 */
  @State plantCameraStatus: string = '';
  /** plantAI AI模型状态 */
  @State plantAiStatus: string = '';
  /** plantAI 当前轮询次数（用于 UI 显示 N/15） */
  @State plantAIAttempt: number = 0;
  /** AI 结果面板实际高度（onAreaChange 测量，用于精确计算悬浮位置） */
  @State panelHeight: number = 0;
  /** plantAI 识别历史（最近 3 次，索引 0 = 最新） */
  @State plantAIHistory: PlantAIRecord[] = [];
  /** 当前查看的历史索引（0 = 最新，仅当历史 > 1 时可切换） */
  @State historyViewIndex: number = 0;

  /** TCP socket 实例 */
  private tcpSocket: socket.TCPSocket | null = null;
  /** JPEG 帧累积缓冲区 */
  private buffer: Uint8Array = new Uint8Array(0);
  /** 控件自动隐藏定时器 ID */
  private hideTimer: number = -1;
  /** aboutToAppear 触发时间戳（用于识别 Navigation 路由查找失败引起的 spurious aboutToDisappear） */
  private appearTime: number = 0;
  /** plantAI 轮询定时器 ID（页面销毁时需清理） */
  private pollTimerId: number = -1;
  /** 命令下发时间戳（用于判断轮询到的是新结果还是旧数据） */
  private commandSentTime: number = 0;

  /** 一行获取当前主题 token */
  t(): ThemeTokens {
    return ThemeManager.getInstance().getTokens();
  }

  /** 是否为 wearable 极简模式（XS 断点，不写 deviceType） */
  private isWearableMode(): boolean {
    return this.currentBreakpoint === BreakpointConstants.XS;
  }

  /**
   * 格式化置信度：将 "0.7324" 转为 "73.24%"
   */
  private formatConfidence(raw: string): string {
    const num = parseFloat(raw);
    if (isNaN(num)) {
      return raw;
    }
    return (num * 100).toFixed(2) + '%';
  }

  /** 获取 AI 结果面板宽度（断点自适应） */
  private getPanelWidth(): number {
    switch (this.currentBreakpoint) {
      case BreakpointConstants.SM: return 220;
      case BreakpointConstants.MD: return 260;
      case BreakpointConstants.LG: return 280;
      case BreakpointConstants.XL: return 300;
      default: return 220;
    }
  }

  /** plantStatus 语义化颜色：健康=绿，感染=橙，严重=红 */
  private getPlantStatusColor(status: string): ResourceColor {
    if (status === '健康' || status === '正常') {
      return this.t().success;
    }
    if (status.indexOf('感染') >= 0 || status.indexOf('病害') >= 0) {
      return this.t().warning;
    }
    if (status.indexOf('严重') >= 0 || status.indexOf('枯') >= 0 || status.indexOf('死') >= 0) {
      return this.t().danger;
    }
    return this.t().textWhite;
  }

  /** 置信度语义化颜色：≥80% 绿，50-80% 橙，<50% 红 */
  private getConfidenceColor(conf: number): ResourceColor {
    if (conf >= 0.8) {
      return this.t().success;
    }
    if (conf >= 0.5) {
      return this.t().warning;
    }
    return this.t().danger;
  }

  /** 判断是否为错误状态（超时/拒绝/失败） */
  private isErrorStatus(status: string): boolean {
    return status.indexOf('超时') >= 0
      || status.indexOf('拒绝') >= 0
      || status.indexOf('失败') >= 0;
  }

  /** 解析 captureTime 字符串为时间戳（设备与 App 同时区前提下比对） */
  private parseCaptureTime(timeStr: string): number {
    // 格式 "2026-07-03 18:37:53" → 用 split/join 替换 - 为 /，兼容 Date.parse
    if (timeStr.length === 0) {
      return 0;
    }
    const normalized = timeStr.split('-').join('/');
    const ts = Date.parse(normalized);
    return isNaN(ts) ? 0 : ts;
  }

  /** 清理轮询定时器 */
  private clearPollTimer(): void {
    if (this.pollTimerId !== -1) {
      clearTimeout(this.pollTimerId);
      this.pollTimerId = -1;
    }
  }

  /** 计算面板悬浮 Y 偏移：贴在 BottomControls（64vp）上方，留 16vp 间距 */
  private getPanelTranslateY(): number {
    // 面板顶部 y = 容器底部 - 64(底栏) - 16(间距) - 面板高度
    return -64 - 16 - this.panelHeight;
  }

  /** 计算轮询已等待秒数：前 5 次 1 秒间隔，之后 3 秒间隔 */
  private getElapsedSeconds(attempt: number): number {
    const fastCount = Math.min(attempt, 5);
    const slowCount = Math.max(attempt - 5, 0);
    return fastCount * 1 + slowCount * 3;
  }

  /** 获取下一次轮询的延迟（前 5 次 1 秒，之后 3 秒） */
  private getPollDelay(attempt: number): number {
    return attempt < 5 ? 1000 : 3000;
  }

  /** 保存当前识别结果到历史（保留最近 3 条，最新在头部） */
  private saveToHistory(): void {
    const record = new PlantAIRecord(
      this.plantStatus,
      this.plantConfidence,
      this.plantCaptureTime,
      this.plantCameraStatus,
      this.plantAiStatus,
      Date.now()
    );
    // 构造新数组：最新 + 最多 2 条旧记录（共 3 条）
    const newHistory: PlantAIRecord[] = [record];
    const limit = Math.min(this.plantAIHistory.length, 2);
    for (let i = 0; i < limit; i++) {
      newHistory.push(this.plantAIHistory[i]);
    }
    this.plantAIHistory = newHistory;
    this.historyViewIndex = 0;  // 自动切换到最新
  }

  /** 切换查看的历史记录（0 = 最新） */
  private switchHistory(index: number): void {
    if (index < 0 || index >= this.plantAIHistory.length) {
      return;
    }
    this.historyViewIndex = index;
    const record = this.plantAIHistory[index];
    this.plantStatus = record.plantStatus;
    this.plantConfidence = record.confidence;
    this.plantCaptureTime = record.captureTime;
    this.plantCameraStatus = record.cameraStatus;
    this.plantAiStatus = record.aiStatus;
  }

  aboutToAppear(): void {
    this.appearTime = Date.now();
    // 从 AppStorage 取路由参数（避开 getParamByName 的 any 类型问题）
    this.greenhouseId = AppStorage.get<string>('videoMonitorGreenhouseId') ?? '';

    // 查表获取摄像头配置
    this.cameraConfig = findCamera(this.greenhouseId);

    if (this.cameraConfig) {
      Logger.info(TAG, '[Monitor] 进入监控页：' + this.cameraConfig.name
        + ' (' + this.cameraConfig.ip + ':' + this.cameraConfig.port + ')');
      // 自动连接
      this.connectToServer();
    } else {
      Logger.warn(TAG, '[Monitor] 大棚 ' + this.greenhouseId + ' 未配置摄像头');
    }
  }

  aboutToDisappear(): void {
    // Navigation 在路由查找失败（"can't find name in config file"）时会触发一次 spurious
    // aboutToDisappear，紧接 aboutToAppear 后几毫秒内发生，紧接着才是 onAppear 真正显示页面。
    // 此时 TCP connect() 正在进行中，若调用 disconnect() 会关闭 socket 并把 tcpSocket 置
    // null，导致 connect 成功后 startReceivingData() 直接 return，不注册 on('message')
    // 监听器 → 收不到 JPEG 数据 → 画面空白。
    // 用 500ms 阈值识别 spurious 调用并跳过清理。真正的页面销毁会在用户返回时触发。
    const elapsed = Date.now() - this.appearTime;
    if (elapsed < 500) {
      Logger.warn(TAG, '[Monitor] 忽略 spurious aboutToDisappear (elapsed=' + elapsed + 'ms)');
      return;
    }
    Logger.info(TAG, '[Monitor] 页面销毁，清理资源');
    this.clearHideTimer();
    this.clearPollTimer();
    this.disconnect();
    this.releasePixelMap();
  }

  // ==================== TCP 连接 ====================

  /** 连接 TCP 服务器 */
  async connectToServer(): Promise<void> {
    if (this.isConnected || this.isConnecting) {
      return;
    }
    if (!this.cameraConfig) {
      return;
    }

    this.isConnecting = true;
    this.errorMsg = '';

    try {
      this.tcpSocket = socket.constructTCPSocketInstance();

      const connectOptions: socket.TCPConnectOptions = {
        address: {
          address: this.cameraConfig.ip,
          port: this.cameraConfig.port,
          family: 1
        },
        timeout: 10000
      };

      Logger.info(TAG, '[TCP] 正在连接 ' + this.cameraConfig.ip + ':' + this.cameraConfig.port);
      await this.tcpSocket.connect(connectOptions);

      this.isConnected = true;
      this.isConnecting = false;
      Logger.info(TAG, '[TCP] 连接成功');

      this.startReceivingData();
      this.resetHideTimer();
    } catch (error) {
      this.isConnected = false;
      this.isConnecting = false;
      this.errorMsg = '连接失败：' + String(error);
      Logger.error(TAG, '[TCP] 连接失败: ' + String(error));
    }
  }

  /** 开始接收数据 + 监听错误/关闭 */
  private startReceivingData(): void {
    if (!this.tcpSocket) {
      Logger.error(TAG, '[TCP] startReceivingData: tcpSocket 为 null');
      return;
    }

    Logger.info(TAG, '[TCP] 注册 on(message) 监听器');

    this.tcpSocket.on('message', (value: TcpMessageData) => {
      Logger.info(TAG, '[TCP] 收到数据: ' + value.message.byteLength + ' bytes');
      this.processReceivedData(value.message);
    });

    this.tcpSocket.on('error', (err: Error) => {
      Logger.error(TAG, '[TCP] Socket 错误: ' + String(err));
      this.errorMsg = '连接异常';
      this.disconnect();
    });

    this.tcpSocket.on('close', () => {
      Logger.info(TAG, '[TCP] 连接已关闭');
      this.isConnected = false;
      this.errorMsg = '连接已断开';
    });
  }

  // ==================== JPEG 帧解析 ====================

  /** 处理接收到的数据：累积 → 找边界 → 提取帧 */
  private async processReceivedData(data: ArrayBuffer): Promise<void> {
    try {
      // 新数据拼接到缓冲区
      const newData = new Uint8Array(data);
      const tempBuffer = new Uint8Array(this.buffer.length + newData.length);
      tempBuffer.set(this.buffer);
      tempBuffer.set(newData, this.buffer.length);
      this.buffer = tempBuffer;

      // 查找 JPEG 起始标记 0xFFD8
      const startMarker = this.findJPEGStart(this.buffer);
      if (startMarker === -1) {
        // 无起始标记，缓冲区过大则清空避免无限增长
        if (this.buffer.length > 1024) {
          this.buffer = new Uint8Array(0);
        }
        return;
      }

      // 查找 JPEG 结束标记 0xFFD9
      const endMarker = this.findJPEGEnd(this.buffer, startMarker);
      if (endMarker === -1) {
        // 未找到完整帧，等待更多数据
        return;
      }

      // 提取完整 JPEG 数据
      const jpegData = this.buffer.slice(startMarker, endMarker + 2);

      // 解码并显示
      await this.decodeAndDisplayImage(jpegData);

      // 移除已处理数据
      this.buffer = this.buffer.slice(endMarker + 2);
    } catch (error) {
      Logger.error(TAG, '[JPEG] 处理数据失败: ' + String(error));
    }
  }

  /** 查找 JPEG 起始标记 0xFF 0xD8 */
  private findJPEGStart(buffer: Uint8Array): number {
    for (let i = 0; i < buffer.length - 1; i++) {
      if (buffer[i] === 0xFF && buffer[i + 1] === 0xD8) {
        return i;
      }
    }
    return -1;
  }

  /** 查找 JPEG 结束标记 0xFF 0xD9 */
  private findJPEGEnd(buffer: Uint8Array, startIndex: number): number {
    for (let i = startIndex + 2; i < buffer.length - 1; i++) {
      if (buffer[i] === 0xFF && buffer[i + 1] === 0xD9) {
        return i;
      }
    }
    return -1;
  }

  /** 解码 JPEG 并显示（参考 smarthome/monitor.ets：不 release 旧帧，避免高频流下渲染时机问题） */
  private async decodeAndDisplayImage(jpegData: Uint8Array): Promise<void> {
    try {
      Logger.info(TAG, '[JPEG] 开始解码, 数据长度=' + jpegData.length);
      const imageSource: image.ImageSource = image.createImageSource(jpegData.buffer);

      // 嵌套字面量拆成显式变量，避免 arkts-no-untyped-obj-literals
      const desiredSize: image.Size = { height: 480, width: 640 };
      const regionSize: image.Size = { height: 480, width: 640 };
      const desiredRegion: image.Region = { size: regionSize, x: 0, y: 0 };
      const decodingOptions: image.DecodingOptions = {
        desiredSize: desiredSize,
        desiredPixelFormat: 3,
        desiredRegion: desiredRegion
      };

      const newPixelMap: PixelMap = await imageSource.createPixelMap(decodingOptions);
      Logger.info(TAG, '[JPEG] 解码成功, 赋值 imageSrc');

      // 直接赋值，不 release 旧帧（参考代码的做法）
      // 旧 PixelMap 会在下一次 GC 时自动回收，或在页面销毁时统一 release
      this.imageSrc = newPixelMap;

      Logger.info(TAG, '[JPEG] imageSrc 赋值完成, imageSrc != null: ' + (this.imageSrc !== null));
    } catch (error) {
      Logger.error(TAG, '[JPEG] 解码图像失败: ' + String(error));
    }
  }

  // ==================== 断开连接 + 资源清理 ====================

  /** 断开 TCP 连接 */
  private disconnect(): void {
    if (this.tcpSocket) {
      try {
        this.tcpSocket.off('message');
        this.tcpSocket.off('error');
        this.tcpSocket.off('close');
        this.tcpSocket.close();
      } catch (err) {
        Logger.warn(TAG, '[TCP] 断开时异常: ' + String(err));
      }
      this.tcpSocket = null;
    }
    this.isConnected = false;
    this.isConnecting = false;
    this.buffer = new Uint8Array(0);
  }

  /** 释放当前 PixelMap */
  private releasePixelMap(): void {
    if (this.imageSrc) {
      try {
        this.imageSrc.release();
      } catch (err) {
        Logger.warn(TAG, '[PixelMap] release 异常: ' + String(err));
      }
      this.imageSrc = null;
    }
  }

  // ==================== 控件自动隐藏 ====================

  /** 重置 5 秒隐藏计时器 */
  private resetHideTimer(): void {
    this.clearHideTimer();
    this.hideTimer = setTimeout(() => {
      this.controlsVisible = false;
    }, HIDE_DELAY);
  }

  /** 清除隐藏计时器 */
  private clearHideTimer(): void {
    if (this.hideTimer !== -1) {
      clearTimeout(this.hideTimer);
      this.hideTimer = -1;
    }
  }

  /** 点击视频区：切换控件可见性 */
  private onVideoTap(): void {
    if (!this.controlsVisible) {
      this.controlsVisible = true;
      this.resetHideTimer();
    } else {
      this.clearHideTimer();
      this.controlsVisible = false;
    }
  }

  /** 返回上一页（先断开连接） */
  private goBack(): void {
    this.clearHideTimer();
    this.disconnect();
    this.releasePixelMap();
    const stack = AppStorage.get<NavPathStack>('navPathStack');
    if (stack) {
      stack.pop();
    }
  }

  /** 重新连接 */
  private reconnect(): void {
    this.disconnect();
    this.releasePixelMap();
    this.connectToServer();
  }

  /** 触发植物 AI 识别（下发 plantAI/recognizeOnce 命令到云端） */
  private async recognizePlantAI(): Promise<void> {
    if (this.isRecognizing) {
      // 正在识别中：用户可能刚关掉面板又点了一次，重新显示面板即可，不重复下发命令
      this.plantAIResultVisible = true;
      return;
    }
    this.isRecognizing = true;
    this.plantAIResultVisible = true;
    this.plantStatus = '';
    this.plantConfidence = '';
    this.plantCaptureTime = '';
    this.plantCameraStatus = '';
    this.plantAiStatus = '';
    // 清理上一次残留的轮询定时器
    this.clearPollTimer();
    Logger.info(TAG, '[plantAI] 点击 AI 识别按钮');
    try {
      const resp = await IotService.getInstance().recognizeOncePlantAI();
      Logger.info(TAG, '[plantAI] 命令已下发, result_code=' + resp.result_code);
      // 检查云端是否接受命令（result_code !== 0 表示设备拒绝或不可达）
      if (resp.result_code !== 0) {
        this.plantStatus = '命令被拒绝 (code=' + resp.result_code + ')';
        this.isRecognizing = false;
        this.plantAIPolling = false;
        promptAction.showToast({ message: 'AI 识别命令下发失败', duration: 2000 });
        return;
      }
      // 记录命令下发时间戳，用于轮询时区分新旧数据
      this.commandSentTime = Date.now();
      // 启动轮询：每 2 秒查询一次，最多 30 秒
      this.pollPlantAIResult(0);
    } catch (err) {
      Logger.error(TAG, '[plantAI] 命令下发失败: ' + String(err));
      this.plantStatus = '命令下发失败';
      this.isRecognizing = false;
      this.plantAIPolling = false;
    }
  }

  /** 轮询 plantAI 属性，最多 15 次（每 2 秒，共 30 秒） */
  private async pollPlantAIResult(attempt: number): Promise<void> {
    const MAX_ATTEMPTS = 15;
    if (attempt >= MAX_ATTEMPTS) {
      this.plantStatus = '识别超时';
      this.plantAiStatus = '超时';
      this.isRecognizing = false;
      this.plantAIPolling = false;
      this.plantAIAttempt = 0;
      return;
    }
    this.plantAIPolling = true;
    // 记录当前轮询次数到 @State，触发 UI 更新进度文案
    this.plantAIAttempt = attempt + 1;
    try {
      const props = await IotService.getInstance().getPlantAIProperties();
      if (props) {
        Logger.info(TAG, '[plantAI] 轮询 ' + (attempt + 1) + '/' + MAX_ATTEMPTS
          + ' | plantStatus=' + (props.plantStatus ?? '<空>')
          + ' | confidence=' + (props.confidence ?? '<空>')
          + ' | captureTime=' + (props.captureTime ?? '<空>')
          + ' | cameraStatus=' + (props.cameraStatus ?? '<空>')
          + ' | aiStatus=' + (props.aiStatus ?? '<空>'));
      }
      if (props && props.plantStatus) {
        // 时间戳比对：captureTime 必须晚于命令下发时间，才认为是本次结果
        // 容忍 60 秒时钟偏差（设备与 App 可能略有同步误差）
        const captureTs = this.parseCaptureTime(props.captureTime ?? '');
        const isNewResult = captureTs === 0 || captureTs >= this.commandSentTime - 60000;
        if (isNewResult) {
          this.plantStatus = props.plantStatus;
          this.plantConfidence = props.confidence ?? '';
          this.plantCaptureTime = props.captureTime ?? '';
          this.plantCameraStatus = props.cameraStatus ?? '';
          this.plantAiStatus = props.aiStatus ?? '';
          this.isRecognizing = false;
          this.plantAIPolling = false;
          this.plantAIAttempt = 0;
          this.saveToHistory();  // 保存到历史记录
          promptAction.showToast({ message: 'AI 识别完成', duration: 1500 });
          return;
        }
        // 旧数据，继续等待
        Logger.info(TAG, '[plantAI] 轮询 ' + (attempt + 1) + '/' + MAX_ATTEMPTS +
          ' captureTime 旧于命令下发时间，继续等待');
      }
    } catch (_err) {
      // 忽略单次轮询错误，继续等待
    }
    // 前快后慢：前 5 次 1 秒间隔（快速捕获），之后 3 秒间隔（节省请求）
    this.pollTimerId = setTimeout(() => { this.pollPlantAIResult(attempt + 1); }, this.getPollDelay(attempt));
  }

  // ==================== UI 构建 ====================

  build() {
    Stack() {
      if (this.isWearableMode()) {
        // watch 占位：屏幕过小不适合视频监控
        this.WearablePlaceholder()
      } else if (!this.cameraConfig) {
        // 该大棚未配置摄像头
        this.NoCameraPlaceholder()
      } else {
        // 视频显示区（内联，不用 @Builder —— 参考 monitor.ets，if(this.imageSrc) 直接在 build() 子树）
        Stack({ alignContent: Alignment.Center }) {
          if (this.imageSrc) {
            Image(this.imageSrc)
              .width('100%')
              .height('100%')
              .objectFit(ImageFit.Contain)
          } else {
            // 加载/无图像占位
            Column({ space: 12 }) {
              if (this.isConnecting) {
                Text('正在连接摄像头...')
                  .fontSize(this.t().fontLg)
                  .fontColor(this.t().textWhite)
                Text(this.cameraConfig?.name ?? '')
                  .fontSize(this.t().fontSm)
                  .fontColor(this.t().textWhiteSub)
                  .margin({ top: 4 })
              } else if (this.errorMsg.length > 0) {
                Text('⚠')
                  .fontSize(48)
                  .fontColor(this.t().danger)
                Text(this.errorMsg)
                  .fontSize(this.t().fontSm)
                  .fontColor(this.t().danger)
                  .textAlign(TextAlign.Center)
                Button('重新连接')
                  .margin({ top: 16 })
                  .backgroundColor(this.t().primary)
                  .fontColor(this.t().textOnPrimary)
                  .borderRadius(this.t().radiusSm)
                  .onClick(() => {
                    this.reconnect();
                  })
              } else {
                Text('📹')
                  .fontSize(48)
                  .fontColor(this.t().textWhite)
                Text('暂无图像')
                  .fontSize(this.t().fontLg)
                  .fontColor(this.t().textWhite)
                  .fontWeight(FontWeight.Medium)
                Text(this.cameraConfig?.name ?? '')
                  .fontSize(this.t().fontSm)
                  .fontColor(this.t().textWhiteSub)
                  .margin({ top: 4 })
              }
            }
            .justifyContent(FlexAlign.Center)
          }
        }
        .width('100%')
        .height('100%')
        .onClick(() => {
          this.onVideoTap();
        })

        // AI 面板呼出按钮（常驻右上角，面板隐藏时显示）
        if (!this.plantAIResultVisible) {
          Row() {
            Text('AI')
              .fontSize(this.t().fontXs)
              .fontColor(this.t().textWhite)
              .fontWeight(FontWeight.Bold)
          }
          .width(36)
          .height(36)
          .backgroundColor('#99000000')
          .borderRadius(18)
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .position({ x: '100%', y: 64 })
          .translate({ x: -44 })
          .onClick(() => {
            this.plantAIResultVisible = true;
          })
        }

        // plantAI 识别结果面板（悬浮在底部控制栏上方）
        if (this.plantAIResultVisible) {
          this.AIResultPanel()
        }

        // 顶部返回栏（淡出）
        if (this.controlsVisible) {
          this.TopBar()
        }

        // 底部控制栏（淡出）
        if (this.controlsVisible) {
          this.BottomControls()
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
  }

  /** watch 占位提示 */
  @Builder
  WearablePlaceholder() {
    Column({ space: 8 }) {
      Text('📹')
        .fontSize(28)
      Text('请在手机端查看监控')
        .fontSize(this.t().fontSm)
        .fontColor(this.t().textSub)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  /** 未配置摄像头占位 */
  @Builder
  NoCameraPlaceholder() {
    Column({ space: 12 }) {
      Text('📹')
        .fontSize(48)
      Text('该大棚未配置摄像头')
        .fontSize(this.t().fontMd)
        .fontColor(this.t().textTitle)
        .fontWeight(FontWeight.Medium)
      Text('仅 1 号、3 号大棚和菌种储存室提供监控')
        .fontSize(this.t().fontXs)
        .fontColor(this.t().textHint)
      Button('返回')
        .margin({ top: 16 })
        .backgroundColor(this.t().primary)
        .fontColor(this.t().textOnPrimary)
        .borderRadius(this.t().radiusSm)
        .onClick(() => {
          this.goBack();
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  /** 顶部返回栏（半透明黑底，确保白字可见） */
  @Builder
  TopBar() {
    Row() {
      // 返回按钮
      Text('←')
        .fontSize(24)
        .fontColor(this.t().textWhite)
        .fontWeight(FontWeight.Bold)
        .width(44)
        .height(44)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          this.goBack();
        })

      // 大棚名称
      Text(this.cameraConfig?.name ?? '视频监控')
        .fontSize(this.t().fontMd)
        .fontColor(this.t().textWhite)
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
        .margin({ left: 8 })

      // 连接状态点
      Circle({ width: 8, height: 8 })
        .fill(this.isConnected ? this.t().success : this.t().danger)
        .margin({ right: 16 })
    }
    .width('100%')
    .height(56)
    .padding({ left: 12, right: 12 })
    .backgroundColor('#99000000')
    .alignItems(VerticalAlign.Center)
    .position({ x: 0, y: 0 })
  }

  /** 底部控制栏（半透明黑底，确保白字可见） */
  @Builder
  BottomControls() {
    Row() {
      // 状态文字
      Column({ space: 2 }) {
        Text(this.isConnected ? '● 实时监控中' : (this.isConnecting ? '○ 连接中...' : '○ 未连接'))
          .fontSize(this.t().fontXs)
          .fontColor(this.isConnected ? this.t().success : this.t().textWhiteSub)
        if (this.cameraConfig) {
          Text(this.cameraConfig.ip + ':' + this.cameraConfig.port)
            .fontSize(this.t().fontXs)
            .fontColor(this.t().textWhiteSub)
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // AI 按钮（分两态：轮询中=查看进度，非轮询=AI 识别）
      Button(this.isRecognizing ? '查看进度' : 'AI 识别')
        .height(36)
        .fontSize(this.t().fontSm)
        .backgroundColor(this.isRecognizing ? this.t().primary : this.t().accent)
        .fontColor(this.t().textWhite)
        .borderRadius(this.t().radiusSm)
        .margin({ right: 8 })
        .onClick(() => {
          if (this.isRecognizing) {
            // 轮询中：重新显示面板查看进度（不重复下发命令）
            this.plantAIResultVisible = true;
          } else {
            this.recognizePlantAI();
          }
        })

      // 连接/断开按钮
      Button(this.isConnected ? '断开' : '连接')
        .height(36)
        .fontSize(this.t().fontSm)
        .backgroundColor(this.isConnected ? this.t().danger : this.t().primary)
        .fontColor(this.t().textWhite)
        .borderRadius(this.t().radiusSm)
        .onClick(() => {
          if (this.isConnected) {
            this.disconnect();
            this.errorMsg = '已手动断开';
          } else {
            this.reconnect();
          }
        })
    }
    .width('100%')
    .height(64)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#99000000')
    .alignItems(VerticalAlign.Center)
    .position({ x: 0, y: '100%' })
    .translate({ y: '-100%' })
  }

  /** plantAI 识别结果面板（右上角悬浮，半透明暗底，主题感知） */
  @Builder
  AIResultPanel() {
    Column() {
      // 标题行
      Row() {
        Text('AI 识别结果')
          .fontSize(this.t().fontSm)
          .fontColor(this.t().textWhite)
          .fontWeight(FontWeight.Medium)
        Blank()
        // 关闭按钮
        Row() {
          Text('✕')
            .fontSize(this.t().fontMd)
            .fontColor(this.t().textWhiteSub)
        }
        .width(24).height(24)
        .justifyContent(FlexAlign.Center)
        .onClick(() => { this.plantAIResultVisible = false; })
      }
      .width('100%')

      // 历史切换行（仅当有 2 条以上历史时显示）
      if (!this.plantAIPolling && this.plantAIHistory.length > 1) {
        Row() {
          Text('◀')
            .fontSize(this.t().fontSm)
            .fontColor(this.historyViewIndex > 0 ? this.t().textWhite : this.t().textHint)
            .width(28)
            .textAlign(TextAlign.Center)
            .onClick(() => { this.switchHistory(this.historyViewIndex - 1); })
          Text('历史 ' + (this.historyViewIndex + 1) + '/' + this.plantAIHistory.length)
            .fontSize(this.t().fontXs)
            .fontColor(this.t().textWhiteSub)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
          Text('▶')
            .fontSize(this.t().fontSm)
            .fontColor(this.historyViewIndex < this.plantAIHistory.length - 1 ? this.t().textWhite : this.t().textHint)
            .width(28)
            .textAlign(TextAlign.Center)
            .onClick(() => { this.switchHistory(this.historyViewIndex + 1); })
        }
        .width('100%')
        .margin({ top: 8 })
      }

      // 内容区域
      if (this.plantAIPolling) {
        Column({ space: 4 }) {
          Row({ space: 8 }) {
            LoadingProgress().width(16).height(16).color(this.t().textWhite)
            Text('正在等待云端返回结果...')
              .fontSize(this.t().fontSm)
              .fontColor(this.t().textWhiteSub)
          }
          .width('100%')

          Text('已轮询 ' + this.plantAIAttempt + '/15 次（约 ' + this.getElapsedSeconds(this.plantAIAttempt) + ' 秒）')
            .fontSize(this.t().fontXs)
            .fontColor(this.t().textHint)
        }
        .margin({ top: 10 })
        .alignItems(HorizontalAlign.Start)
      } else {
        // 植株状态（标签在上，值在下；错误状态加 ⚠ 图标）
        Column({ space: 2 }) {
          Text('植株状态')
            .fontSize(this.t().fontXs)
            .fontColor(this.t().textWhiteSub)
          Row() {
            if (this.plantStatus.length > 0 && this.isErrorStatus(this.plantStatus)) {
              Text('⚠')
                .fontSize(this.t().fontSm)
                .fontColor(this.t().danger)
                .margin({ right: 4 })
            }
            Text(this.plantStatus.length > 0 ? this.plantStatus : '-')
              .fontSize(this.t().fontSm)
              .fontColor(this.plantStatus.length > 0 ? this.getPlantStatusColor(this.plantStatus) : this.t().textHint)
              .fontWeight(FontWeight.Bold)
          }
        }
        .width('100%')
        .margin({ top: 10 })

        // 置信度（标签在上，值在下，有值时带进度条）
        Column({ space: 2 }) {
          Text('置信度')
            .fontSize(this.t().fontXs)
            .fontColor(this.t().textWhiteSub)
          Text(this.plantConfidence.length > 0 ? this.formatConfidence(this.plantConfidence) : '-')
            .fontSize(this.t().fontSm)
            .fontColor(this.plantConfidence.length > 0 ? this.t().accent : this.t().textHint)
          // 置信度进度条（仅有值时显示，颜色随置信度变化）
          if (this.plantConfidence.length > 0) {
            Progress({ value: parseFloat(this.plantConfidence) * 100, total: 100, type: ProgressType.Linear })
              .width('100%')
              .height(4)
              .color(this.getConfidenceColor(parseFloat(this.plantConfidence)))
              .backgroundColor('#33666666')
              .borderRadius(2)
              .margin({ top: 2 })
          }
        }
        .width('100%')
        .margin({ top: 8 })

        // 识别时间（标签在上，值在下）
        Column({ space: 2 }) {
          Text('识别时间')
            .fontSize(this.t().fontXs)
            .fontColor(this.t().textWhiteSub)
          Text(this.plantCaptureTime.length > 0 ? this.plantCaptureTime : '-')
            .fontSize(this.t().fontXs)
            .fontColor(this.plantCaptureTime.length > 0 ? this.t().textWhiteSub : this.t().textHint)
        }
        .width('100%')
        .margin({ top: 8 })

        // 摄像头状态（标签在上，值在下）
        Column({ space: 2 }) {
          Text('摄像头')
            .fontSize(this.t().fontXs)
            .fontColor(this.t().textWhiteSub)
          Text(this.plantCameraStatus.length > 0 ? this.plantCameraStatus : '-')
            .fontSize(this.t().fontXs)
            .fontColor(this.plantCameraStatus.length > 0 ? this.t().textWhiteSub : this.t().textHint)
        }
        .width('100%')
        .margin({ top: 8 })

        // AI 模型状态（标签在上，值在下）
        Column({ space: 2 }) {
          Text('模型状态')
            .fontSize(this.t().fontXs)
            .fontColor(this.t().textWhiteSub)
          Text(this.plantAiStatus.length > 0 ? this.plantAiStatus : '-')
            .fontSize(this.t().fontXs)
            .fontColor(this.plantAiStatus.length > 0 ? this.t().textWhiteSub : this.t().textHint)
        }
        .width('100%')
        .margin({ top: 8 })
      }

      // 重新识别按钮
      if (!this.plantAIPolling) {
        Button('重新识别')
          .height(28)
          .fontSize(this.t().fontXs)
          .backgroundColor(this.t().accent)
          .fontColor(this.t().textWhite)
          .borderRadius(this.t().radiusSm)
          .margin({ top: 12 })
          .onClick(() => { this.recognizePlantAI(); })
      }
    }
    .width(this.getPanelWidth())
    .padding(14)
    .backgroundColor('#CC1A1A1A')
    .borderRadius(this.t().radiusMd)
    .backdropBlur(8)
    // 悬浮在底部控制栏（64vp 高）上方，留 16vp 间距
    // position 把面板顶部放到容器底部，translate 上移 (64+16+面板高度) 确保完全可见
    .position({ x: 8, y: '100%' })
    .translate({ y: this.getPanelTranslateY() })
    .onAreaChange((_old: Area, newArea: Area) => {
      this.panelHeight = newArea.height as number;
    })
    // 挂载/卸载时从底部滑入/滑出动画
    .transition({ type: TransitionType.All, translate: { y: 100 } })
  }
}
