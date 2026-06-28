/**
 * 大棚 UI 数据模型
 */

/** 传感器数据项 */
export interface SensorDataItem {
  readonly type: string;
  value: number;
  min: number;
  max: number;
  status: number; // 0=正常 1=警告 2=危险
}

/** 告警信息 */
export interface AlertItem {
  readonly id: string;
  level: number; // 0=警告 1=危险
  message: string;
  time: string;
  device: string;
}

/** 设备信息 */
export interface DeviceItem {
  readonly id: string;
  name: string;
  type: string;
  status: number; // 0=离线 1=在线 2=故障
  lastUpdate: string;
  location: string;
}

/** 生长批次 */
export interface GrowthBatch {
  readonly id: string;
  mushroomType: string;
  startDate: string;
  day: number;
  status: string;
  yield: string;
}

/** 快捷控制项 */
export interface ControlItem {
  readonly id: string;
  name: string;
  icon: string;
  active: boolean;
  color: string;
}
