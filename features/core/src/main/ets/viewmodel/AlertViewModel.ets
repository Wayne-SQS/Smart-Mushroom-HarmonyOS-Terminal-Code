import { SensorType } from 'common-base';
import { SensorDataItem, AlertItem } from '../model/GreenhouseModel';
import { BaseViewModel } from './BaseViewModel';

/** 告警过滤模式 */
type AlertFilter = 'all' | 'unread' | 'danger';

/** 告警构建中间结构 */
interface AlertInfo {
  message: string;
  device: string;
}

/**
 * 告警 ViewModel
 *
 * 从传感器数据派生告警信息，支持已读 / 未读状态与筛选。
 *
 * 告警规则：
 * - sensor.status === 1 → 警告告警（level=0）
 * - sensor.status === 2 → 危险告警（level=1）
 * - status === 0 不生成告警
 *
 * 告警 ID 格式：`alert-${sensor.type}`，保证跨刷新稳定（保留已读状态）。
 *
 * 建议 action 推断：
 * - 温度高 → 通风降温；温度低 → 加热升温
 * - 湿度低 → 喷雾增湿；湿度高 → 通风降湿
 * - CO2 高 → 通风
 * - 光照低 → 补光；光照高 → 遮阳
 */
export class AlertViewModel extends BaseViewModel {
  /** 告警列表 */
  alerts: AlertItem[] = [];
  /** 未读数量 */
  unreadCount: number = 0;
  /** 当前过滤模式 */
  filter: AlertFilter = 'all';

  /** 已读告警 ID 集合 */
  private readIds: Set<string> = new Set();

  /**
   * 加载告警数据
   *
   * 告警依赖传感器数据，由 loadFromSensors 注入；
   * loadData() 仅刷新未读计数。
   */
  async loadData(): Promise<void> {
    await this.handleAsync(async () => {
      this.updateUnreadCount();
    });
  }

  /**
   * 从传感器数据同步告警
   *
   * - status===1 → 警告（level=0）
   * - status===2 → 危险（level=1）
   * - 已读状态按 alert ID 保留
   *
   * @param sensors 传感器数据数组（来自 DashboardViewModel）
   */
  loadFromSensors(sensors: SensorDataItem[]): void {
    const newAlerts: AlertItem[] = [];
    for (let i = 0; i < sensors.length; i++) {
      const sensor = sensors[i];
      if (sensor.status === 0) {
        continue;
      }
      const info = this.buildAlertInfo(sensor);
      if (info === null) {
        continue;
      }
      const level = sensor.status === 2 ? 1 : 0;
      const alertId = 'alert-' + sensor.type;
      newAlerts.push({
        id: alertId,
        level: level,
        message: info.message,
        time: this.formatTimeNow(),
        device: info.device
      });
    }
    this.alerts = newAlerts;
    // 清理已不存在的告警 ID，保留仍存在告警的已读状态
    this.cleanupReadIds();
    this.updateUnreadCount();
  }

  /** 标记单条告警为已读 */
  markRead(id: string): void {
    this.readIds.add(id);
    this.updateUnreadCount();
  }

  /** 标记所有告警为已读 */
  markAllRead(): void {
    for (let i = 0; i < this.alerts.length; i++) {
      this.readIds.add(this.alerts[i].id);
    }
    this.updateUnreadCount();
  }

  /** 清空所有告警与已读记录 */
  clearAll(): void {
    this.alerts = [];
    this.readIds.clear();
    this.updateUnreadCount();
  }

  /** 设置过滤模式 */
  setFilter(filter: AlertFilter): void {
    this.filter = filter;
  }

  /**
   * 根据当前 filter 返回筛选后的告警列表
   *
   * - 'all'：全部
   * - 'unread'：未读
   * - 'danger'：危险（level=1）
   */
  getFilteredAlerts(): AlertItem[] {
    if (this.filter === 'all') {
      return this.alerts;
    }
    const result: AlertItem[] = [];
    for (let i = 0; i < this.alerts.length; i++) {
      const alert = this.alerts[i];
      if (this.filter === 'unread') {
        if (!this.readIds.has(alert.id)) {
          result.push(alert);
        }
      } else if (this.filter === 'danger') {
        if (alert.level === 1) {
          result.push(alert);
        }
      }
    }
    return result;
  }

  /**
   * 构建告警信息（message + device）
   *
   * 使用 switch 显式分支按 type 构造消息，避免动态属性访问。
   */
  private buildAlertInfo(sensor: SensorDataItem): AlertInfo | null {
    const value = sensor.value;
    const isHigh = value > sensor.max;
    const isLow = value < sensor.min;
    const action = this.inferAction(sensor.type, isHigh, isLow);
    switch (sensor.type) {
      case SensorType.TEMPERATURE:
        return {
          message: '温度 ' + value + '°C，建议' + action,
          device: '温度传感器-A区'
        };
      case SensorType.HUMIDITY:
        return {
          message: '空气湿度 ' + value + '%，建议' + action,
          device: '湿度传感器-A区'
        };
      case SensorType.CO2:
        return {
          message: 'CO₂浓度 ' + value + 'ppm，建议' + action,
          device: 'CO2传感器-A区'
        };
      case SensorType.LIGHT:
        return {
          message: '光照强度 ' + value + 'lux，建议' + action,
          device: '光照传感器-B区'
        };
      case SensorType.SOIL_MOISTURE:
        return {
          message: '土壤湿度 ' + value + '%，建议' + action,
          device: '土壤湿度-3号'
        };
      case SensorType.SOIL_TEMP:
        return {
          message: '土壤温度 ' + value + '°C，建议' + action,
          device: '土壤温度传感器'
        };
      default:
        return null;
    }
  }

  /** 推断建议动作（基于类型与超限方向） */
  private inferAction(type: string, isHigh: boolean, isLow: boolean): string {
    switch (type) {
      case SensorType.TEMPERATURE:
        return isHigh ? '通风降温' : '加热升温';
      case SensorType.HUMIDITY:
        return isLow ? '喷雾增湿' : '通风降湿';
      case SensorType.CO2:
        return isHigh ? '通风' : '检查';
      case SensorType.LIGHT:
        return isLow ? '补光' : '遮阳';
      case SensorType.SOIL_MOISTURE:
        return isLow ? '灌溉' : '排水';
      case SensorType.SOIL_TEMP:
        return isHigh ? '通风降温' : '加热升温';
      default:
        return '检查';
    }
  }

  /**
   * 清理已不存在的告警 ID
   *
   * 重建 readIds，仅保留当前 alerts 中仍存在的 ID。
   */
  private cleanupReadIds(): void {
    const newReadIds: Set<string> = new Set();
    for (let i = 0; i < this.alerts.length; i++) {
      const id = this.alerts[i].id;
      if (this.readIds.has(id)) {
        newReadIds.add(id);
      }
    }
    this.readIds = newReadIds;
  }

  /** 重新计算未读数量 */
  private updateUnreadCount(): void {
    let unread = 0;
    for (let i = 0; i < this.alerts.length; i++) {
      if (!this.readIds.has(this.alerts[i].id)) {
        unread++;
      }
    }
    this.unreadCount = unread;
  }

  /** 格式化当前时间为 HH:mm */
  private formatTimeNow(): string {
    const date = new Date();
    const hours = date.getHours();
    const minutes = date.getMinutes();
    const hour = hours < 10 ? '0' + hours : '' + hours;
    const minute = minutes < 10 ? '0' + minutes : '' + minutes;
    return hour + ':' + minute;
  }
}
