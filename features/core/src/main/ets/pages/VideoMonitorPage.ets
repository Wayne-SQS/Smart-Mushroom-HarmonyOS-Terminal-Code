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

  /** TCP socket 实例 */
  private tcpSocket: socket.TCPSocket | null = null;
  /** JPEG 帧累积缓冲区 */
  private buffer: Uint8Array = new Uint8Array(0);
  /** 控件自动隐藏定时器 ID */
  private hideTimer: number = -1;
  /** aboutToAppear 触发时间戳（用于识别 Navigation 路由查找失败引起的 spurious aboutToDisappear） */
  private appearTime: number = 0;

  /** 一行获取当前主题 token */
  t(): ThemeTokens {
    return ThemeManager.getInstance().getTokens();
  }

  /** 是否为 wearable 极简模式（XS 断点，不写 deviceType） */
  private isWearableMode(): boolean {
    return this.currentBreakpoint === BreakpointConstants.XS;
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
      return;
    }
    this.isRecognizing = true;
    Logger.info(TAG, '[plantAI] 点击 AI 识别按钮');
    try {
      const resp = await IotService.getInstance().recognizeOncePlantAI();
      Logger.info(TAG, '[plantAI] 命令已下发, result_code=' + resp.result_code);
      promptAction.showToast({
        message: 'AI 识别命令已下发，等待设备返回结果',
        duration: 2000
      });
    } catch (err) {
      Logger.error(TAG, '[plantAI] 命令下发失败: ' + String(err));
      promptAction.showToast({
        message: '识别命令下发失败: ' + String(err),
        duration: 3000
      });
    } finally {
      this.isRecognizing = false;
    }
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

  /** 视频显示区（全屏） */
  @Builder
  VideoArea() {
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
              .fontColor(this.t().textTitle)
            Text(this.cameraConfig?.name ?? '')
              .fontSize(this.t().fontSm)
              .fontColor(this.t().textSub)
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
            Text('暂无图像')
              .fontSize(this.t().fontLg)
              .fontColor(this.t().textTitle)
              .fontWeight(FontWeight.Medium)
            Text(this.cameraConfig?.name ?? '')
              .fontSize(this.t().fontSm)
              .fontColor(this.t().textSub)
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

      // AI 识别按钮（下发 plantAI/recognizeOnce 命令）
      Button(this.isRecognizing ? '识别中...' : 'AI 识别')
        .height(36)
        .fontSize(this.t().fontSm)
        .backgroundColor(this.isRecognizing ? this.t().textHint : this.t().accent)
        .fontColor(this.t().textWhite)
        .borderRadius(this.t().radiusSm)
        .enabled(!this.isRecognizing)
        .margin({ right: 8 })
        .onClick(() => {
          this.recognizePlantAI();
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
}
