/**
 * 华为云 IoTDA 应用侧 API 服务
 *
 * 改造自旧版设备侧 API。改为应用侧 API 体系：
 * - 鉴权：IAM 用户名/密码换取 X-Subject-Token（替代旧 deviceSecret HMAC）
 * - 请求头：X-Auth-Token（替代旧 access_token）
 * - URL：/v5/iot/{projectId}/devices/{deviceId}/...（替代旧 /v5/devices/...）
 *
 * 兼容性：保留旧 init(deviceId, secret, server, projectId) 重载，内部标记 deprecated。
 * 新代码请使用 init(config: IotAppConfig)。
 *
 * 参考实现：wanglian/pages/DisplayPage.ets
 */
import { http } from '@kit.NetworkKit';
import { IamAuthUtil } from './IamAuthUtil';
import { IotTokenManager } from './IotTokenManager';
import { Logger } from 'common-base';
import type {
  IotAppConfig,
  DeviceShadowService,
  DeviceShadowResponse,
  SmartRoomProperties,
  AppSideCommandResponse
} from './IotTypes';

const TAG = 'IotService';

/** smartRoom 服务 ID */
const SERVICE_SMART_ROOM = 'smartRoom';

/**
 * IoT 命令下发参数类（每个命令类型对应一个 class，ArkTS 不允许 object literal → Record）
 *
 * 命令名与 paras key 与嵌入式端 mqtt.c handle_cloud_command() 完全对齐：
 * - SetLamp  → LampStatus  (ON/OFF)
 * - SetCond  → CondStatus  (ON/OFF)
 * - SetVent  → VentStatus  (ON/OFF)
 */
class SetLampParas {
  LampStatus: string;
  constructor(on: boolean) { this.LampStatus = on ? 'ON' : 'OFF'; }
}
class SetCondParas {
  CondStatus: string;
  constructor(on: boolean) { this.CondStatus = on ? 'ON' : 'OFF'; }
}
class SetVentParas {
  VentStatus: string;
  constructor(on: boolean) { this.VentStatus = on ? 'ON' : 'OFF'; }
}

/** sendCommand 请求体 */
class CommandBody {
  service_id: string;
  command_name: string;
  paras: Object;
  constructor(serviceId: string, commandName: string, paras: Object) {
    this.service_id = serviceId;
    this.command_name = commandName;
    this.paras = paras;
  }
}

export class IotService {
  private static instance: IotService;

  private config: IotAppConfig | null = null;

  /** token 缓存器（与旧版保持一致，缓存 X-Subject-Token） */
  private tokenManager: IotTokenManager = new IotTokenManager();

  private constructor() {}

  static getInstance(): IotService {
    if (!IotService.instance) {
      IotService.instance = new IotService();
    }
    return IotService.instance;
  }

  /**
   * 初始化（新签名，推荐）
   *
   * 接收完整应用侧配置，含 IAM 凭据 + IoTDA endpoint + projectId + deviceId。
   */
  init(config: IotAppConfig): void;

  /**
   * 初始化（旧签名，兼容保留 - 已 deprecated）
   *
   * 旧参数转换为 IotAppConfig 时，IAM 凭据为空，需另行调用新 init。
   */
  init(deviceId: string, deviceSecret: string, serverAddress: string, projectId?: string): void;

  init(arg1: IotAppConfig | string, deviceSecret?: string, serverAddress?: string, projectId?: string): void {
    if (typeof arg1 === 'object' && arg1 !== null) {
      this.config = arg1;
      Logger.info(TAG, 'IoT 服务初始化完成（应用侧 API），设备：' + arg1.deviceId);
      return;
    }
    // 旧签名降级路径：仅能记录，调用方需后续用新 init 重置
    Logger.warn(TAG, '检测到旧版 init 签名，请迁移至 init(config: IotAppConfig)');
  }

  /**
   * 鉴权：换取 IAM X-Subject-Token
   *
   * 使用 tokenManager 缓存，避免重复请求。
   */
  async authenticate(): Promise<string> {
    const cachedToken = this.tokenManager.getToken();
    if (cachedToken) {
      return cachedToken;
    }

    if (!this.config) {
      throw new Error('IoT 服务未初始化，请先调用 init(config)');
    }

    const token = await IamAuthUtil.requestToken(this.config);
    // IAM token 默认 24h，这里保守按 23h 缓存
    this.tokenManager.setToken(token, 23 * 3600);
    return token;
  }

  /** 获取有效 token（公开方法，外部可主动获取） */
  async getAccessToken(): Promise<string> {
    return await this.authenticate();
  }

  /**
   * 查询设备影子
   *
   * GET /v5/iot/{projectId}/devices/{deviceId}/shadow
   */
  async queryDeviceShadow(): Promise<DeviceShadowResponse> {
    await this.ensureAuthenticated();

    const url = this.buildShadowUrl();
    const token = this.tokenManager.getToken() ?? '';

    try {
      const httpRequest = http.createHttp();
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        header: {
          'Content-Type': 'application/json',
          'X-Auth-Token': token
        }
      });
      httpRequest.destroy();

      if (response.responseCode !== 200) {
        Logger.error(TAG, '影子查询失败：HTTP ' + response.responseCode);
        throw new Error('影子查询失败：HTTP ' + response.responseCode);
      }

      const rawParsed: Record<string, Object> = JSON.parse(response.result.toString()) as Record<string, Object>;
      const parsed = rawParsed;
      const shadowArr = (parsed['shadow'] as DeviceShadowService[]) ?? [];
      const result: DeviceShadowResponse = {
        device_id: (parsed['device_id'] as string) ?? this.config!.deviceId,
        shadow: shadowArr
      };
      Logger.info(TAG, '影子查询成功，服务数：' + result.shadow.length);
      return result;
    } catch (err) {
      Logger.error(TAG, '影子查询异常');
      throw new Error('影子查询异常: ' + String(err));
    }
  }

  /**
   * 获取指定服务的属性
   *
   * 应用侧返回的 shadow 数组中按 service_id 过滤。
   */
  async getDeviceProperties(serviceId: string): Promise<Record<string, Object> | null> {
    const shadow = await this.queryDeviceShadow();
    for (let i = 0; i < shadow.shadow.length; i++) {
      const svc = shadow.shadow[i];
      if (svc.service_id === serviceId && svc.reported && svc.reported.properties) {
        return svc.reported.properties;
      }
    }
    Logger.warn(TAG, '未找到服务 ' + serviceId + ' 的属性');
    return null;
  }

  /**
   * 便捷方法：获取 smartRoom 服务属性（强类型）
   *
   * 内部走 getDeviceProperties('smartRoom')，转换为 SmartRoomProperties。
   */
  async getSmartRoomProperties(): Promise<SmartRoomProperties | null> {
    const props = await this.getDeviceProperties(SERVICE_SMART_ROOM);
    if (!props) {
      return null;
    }
    const result: SmartRoomProperties = {
      Temp: props['Temp'] as string | undefined,
      Humi: props['Humi'] as string | undefined,
      Lumi: props['Lumi'] as string | undefined,
      LampST: props['LampST'] as string | undefined,
      CondST: props['CondST'] as string | undefined,
      VentST: props['VentST'] as string | undefined,
      Dist: props['Dist'] as string | undefined,
      Smoke: props['Smoke'] as string | undefined,
      CO2: props['CO2'] as string | undefined
    };
    return result;
  }

  /**
   * 下发命令（通用）
   *
   * POST /v5/iot/{projectId}/devices/{deviceId}/commands
   */
  async sendCommand(
    serviceId: string,
    commandName: string,
    paras: Object
  ): Promise<AppSideCommandResponse> {
    await this.ensureAuthenticated();

    const url = this.buildCommandUrl();
    const token = this.tokenManager.getToken() ?? '';

    const body = new CommandBody(serviceId, commandName, paras);

    Logger.info(TAG, '下发命令：' + commandName + '，服务：' + serviceId);

    try {
      const httpRequest = http.createHttp();
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
          'X-Auth-Token': token
        },
        extraData: JSON.stringify(body)
      });
      httpRequest.destroy();

      Logger.info(TAG, '命令下发结果：HTTP ' + response.responseCode);

      const result: AppSideCommandResponse = {
        command_id: '' + Date.now(),
        response: response.result ? JSON.parse(response.result.toString()) : {},
        result_code: response.responseCode === 200 ? 0 : response.responseCode
      };
      return result;
    } catch (err) {
      Logger.error(TAG, '命令下发异常');
      throw new Error('命令下发异常: ' + String(err));
    }
  }

  /**
   * 控制灯（补光灯）
   *
   * 对应嵌入式 mqtt.c 中 SetLamp 命令，paras={LampStatus: 'ON'/'OFF'}。
   */
  async controlLight(on: boolean): Promise<AppSideCommandResponse> {
    const paras = new SetLampParas(on);
    return await this.sendCommand(SERVICE_SMART_ROOM, 'SetLamp', paras);
  }

  /**
   * 控制排风扇/通风
   *
   * 对应嵌入式 mqtt.c 中 SetVent 命令，paras={VentStatus: 'ON'/'OFF'}。
   */
  async controlFan(on: boolean): Promise<AppSideCommandResponse> {
    const paras = new SetVentParas(on);
    return await this.sendCommand(SERVICE_SMART_ROOM, 'SetVent', paras);
  }

  /**
   * 控制空调/加热
   *
   * 对应嵌入式 mqtt.c 中 SetCond 命令，paras={CondStatus: 'ON'/'OFF'}。
   */
  async controlCondi(on: boolean): Promise<AppSideCommandResponse> {
    const paras = new SetCondParas(on);
    return await this.sendCommand(SERVICE_SMART_ROOM, 'SetCond', paras);
  }

  /**
   * 通用开关控制（兼容旧 API，内部走 sendCommand）
   *
   * @deprecated 推荐使用具体的 controlLight / controlFan / controlCondi 方法
   */
  async controlSwitch(serviceId: string, commandName: string, on: boolean): Promise<void> {
    const paras = new SetLampParas(on);
    await this.sendCommand(serviceId, commandName, paras);
  }

  /**
   * 设备在线检测（通过影子是否可查判断）
   */
  async isDeviceOnline(): Promise<boolean> {
    try {
      const shadow = await this.queryDeviceShadow();
      return shadow.shadow.length > 0;
    } catch {
      return false;
    }
  }

  /**
   * 获取单个属性最新值（通用）
   */
  async getLatestValue(serviceId: string, propertyName: string): Promise<Object | null> {
    const props = await this.getDeviceProperties(serviceId);
    if (props) {
      const value = props[propertyName];
      if (value !== undefined) {
        return value;
      }
    }
    return null;
  }

  // ============================ 内部工具方法 ============================

  /** 构造影子查询 URL */
  private buildShadowUrl(): string {
    const c = this.config!;
    return 'https://' + c.iotdaEndpoint + ':443/v5/iot/' + c.projectId + '/devices/' + c.deviceId + '/shadow';
  }

  /** 构造命令下发 URL */
  private buildCommandUrl(): string {
    const c = this.config!;
    return 'https://' + c.iotdaEndpoint + ':443/v5/iot/' + c.projectId + '/devices/' + c.deviceId + '/commands';
  }

  /** 鉴权前置检查 */
  private async ensureAuthenticated(): Promise<void> {
    if (!this.config) {
      throw new Error('IoT 服务未初始化，请先调用 init(config)');
    }
    await this.authenticate();
  }
}
