/**
 * 华为云 IoT 设备接入 - 数据模型定义
 */

/** 设备鉴权请求参数 */
export interface DeviceAuthParams {
  device_id: string;
  sign_type: number;      // 0 表示 HMAC-SHA256
  timestamp: string;       // 格式：YYYYMMDDHH
  password: string;        // HMAC-SHA256 加密后的密钥
}

/** 设备鉴权响应 */
export interface DeviceAuthResponse {
  access_token: string;    // 设备 token，长度 32-256
  expires_in: number;      // 剩余有效时间，单位：秒
}

/** 设备属性上报 - 服务属性结构 */
export interface ServiceProperty {
  service_id: string;                    // 服务 ID
  properties: Record<string, Object>;   // 属性键值对
  event_time?: string;                   // UTC 时间，格式：YYYY-MM-DDTHH:mm:ss.SSSZ
}

/** 设备属性上报请求体 */
export interface PropertiesReportRequest {
  services: ServiceProperty[];
}

/** 设备影子 - 属性描述 */
export interface ShadowProperties {
  properties: Record<string, Object> | null;
  event_time: string | null;
}

/** 设备影子 - 服务影子 */
export interface DeviceShadowService {
  service_id: string;
  desired: ShadowProperties;
  reported: ShadowProperties;
  version: number;
}

/** 设备影子查询响应 */
export interface DeviceShadowResponse {
  device_id: string;
  shadow: DeviceShadowService[];
}

/** 设备命令下发 - 请求参数 */
export interface DeviceCommandParams {
  service_id: string;                    // 服务 ID
  command_name: string;                  // 命令名称
  paras: Record<string, Object>;        // 命令参数
}

/** 设备命令下发请求体 */
export interface DeviceCommandRequest {
  device_id: string;
  command: DeviceCommandParams;
}

/** 设备命令下发响应 */
export interface DeviceCommandResponse {
  command_id: string;
  response: Record<string, Object>;
  result_code: number;                   // 0 表示成功
}

/** IoT 平台 API 通用响应 */
export interface IotApiResponse<T> {
  data?: T;
  error_msg?: string;
  error_code?: string;
}

/** 认证 token */
export interface AuthToken {
  token: string;
  expiresAt: number;     // 过期时间戳（毫秒）
}

/** 设备基础信息 */
export interface DeviceInfo {
  device_id: string;
  node_id: string;
  device_name: string;
  product_id: string;
  status: string;        // ONLINE / OFFLINE / INACTIVE
  secret?: string;
}

/** 属性上报数据模型（示例 - 根据实际产品模型调整） */
export interface DevicePropertyData {
  temperature?: number;
  humidity?: number;
  status?: string;
}

// ============================================================================
// 应用侧 API 类型定义（IAM 鉴权 + IoTDA 应用侧接口）
// 与上方设备侧类型并存，新增代码请使用本节类型
// ============================================================================

/** IAM 账号域 */
export interface IamDomain {
  name: string;
}

/** IAM 鉴权 - 用户身份 */
export interface IamPasswordUser {
  name: string;            // IAM 用户名
  password: string;        // IAM 用户密码
  domain: IamDomain;       // 账号名
}

/** IAM 密码验证信息 */
export interface IamPasswordAuth {
  user: IamPasswordUser;
}

/** IAM 鉴权 - 身份信息 */
export interface IamIdentity {
  methods: string[];                    // 固定 ['password']
  password: IamPasswordAuth;
}

/** IAM 项目作用域 */
export interface IamProjectScope {
  name: string;                         // 区域 project name，如 cn-north-4
}

/** IAM 鉴权 - 作用域 */
export interface IamScope {
  project: IamProjectScope;
}

/** IAM 鉴权 - 认证信息 */
export interface IamAuthInfo {
  identity: IamIdentity;
  scope: IamScope;
}

/** IAM 鉴权 - 请求体 */
export interface IamAuthRequest {
  auth: IamAuthInfo;
}

/** 应用侧 API 配置参数 */
export interface IotAppConfig {
  /** IAM 用户名 */
  username: string;
  /** IAM 用户密码 */
  password: string;
  /** IAM 账号名（domain name） */
  domainName: string;
  /** 区域 project name，如 cn-north-4 */
  region: string;
  /** IoTDA 应用侧 endpoint，如 412aa055e1.st1.iotda-app.cn-north-4.myhuaweicloud.com */
  iotdaEndpoint: string;
  /** IoTDA 项目 ID */
  projectId: string;
  /** 目标设备 ID */
  deviceId: string;
}

/**
 * smartRoom 服务设备影子 reported.properties
 *
 * 包含云平台物模型中定义的全部属性（含硬件暂未上报的预留字段）。
 * 硬件 mqtt.c 实际上报：Temp / Humi / Lumi / LampST / CondST / VentST / Smoke / CO2
 */
export interface SmartRoomProperties {
  /** 温度 °C（字符串） */
  Temp?: string;
  /** 湿度 % */
  Humi?: string;
  /** 光照（LDR 光敏电阻值） */
  Lumi?: string;
  /** 灯状态：ON / OFF */
  LampST?: string;
  /** 空调状态：ON / OFF */
  CondST?: string;
  /** 排风扇状态：ON / OFF */
  VentST?: string;
  /** 距离 cm，-1 表示无障碍（预留，硬件暂未上报） */
  Dist?: string;
  /** 烟雾传感器值 */
  Smoke?: string;
  /** CO₂ 浓度 ppm */
  CO2?: string;
  /** 蜂鸣器状态：ON / OFF */
  BuzzerST?: string;
}

/** smartRoom 服务 - 灯控制命令参数 */
export interface LightCommandParas {
  /** 'ON' / 'OFF' */
  light: string;
}

/** smartRoom 服务 - 命令下发请求体 */
export interface SmartRoomCommandRequest {
  service_id: 'smartRoom';
  command_name: 'Light';
  paras: LightCommandParas;
}

/** 应用侧 API - 命令下发响应 */
export interface AppSideCommandResponse {
  command_id: string;
  response: Record<string, Object>;
  result_code: number;
}
