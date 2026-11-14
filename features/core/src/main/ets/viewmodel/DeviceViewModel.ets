import { Logger } from 'common-base';
import { IotService } from '../service/IotService';
import { DeviceItem } from '../model/GreenhouseModel';
import { BaseViewModel } from './BaseViewModel';

const TAG = 'DeviceViewModel';

/**
 * 设备管理 ViewModel
 *
 * 设备清单来自本地台账（云端暂无 listDevices 接口），因此明确标记 isDemoData，
 * 页面必须显示「本地台账」提示，不得让用户误以为全部来自云端。
 *
 * 在线状态是唯一可验证的实时字段：
 * - isDeviceOnline() 成功 → 传感器类设备按真实在线状态更新
 * - 请求失败 → errorMsg 写入，页面渲染错误态 + 重试，绝不把设备静默改成「离线」
 */
export class DeviceViewModel extends BaseViewModel {
  /** 本地设备台账（示例数据，页面需明示） */
  devices: DeviceItem[] = [
    { id: '1', name: '温度传感器-A区', type: '温度', status: 0, lastUpdate: '--', location: 'A区东侧' },
    { id: '2', name: '湿度传感器-A区', type: '湿度', status: 0, lastUpdate: '--', location: 'A区西侧' },
    { id: '3', name: 'CO2传感器-A区', type: 'CO₂', status: 0, lastUpdate: '--', location: 'A区中央' },
    { id: '4', name: '光照传感器-B区', type: '光照', status: 0, lastUpdate: '--', location: 'B区顶部' },
    { id: '5', name: '土壤湿度-3号', type: '土壤湿度', status: 0, lastUpdate: '--', location: 'C区3号位' },
    { id: '6', name: '通风控制器', type: '控制器', status: 0, lastUpdate: '--', location: '大棚东墙' },
    { id: '7', name: '喷雾系统', type: '控制器', status: 0, lastUpdate: '--', location: '大棚顶部' },
    { id: '8', name: '补光灯组', type: '控制器', status: 0, lastUpdate: '--', location: 'B区顶部' }
  ];

  /** 设备清单是否为本地台账（非云端拉取），页面据此展示数据来源提示 */
  readonly isDemoData: boolean = true;

  /** 设备总数 */
  totalCount: number = 0;
  /** 在线设备数 */
  onlineCount: number = 0;
  /** 离线设备数 */
  offlineCount: number = 0;

  constructor() {
    super();
    this.updateCounts();
  }

  /**
   * 加载设备在线状态
   *
   * 失败时由 handleAsync 写入 errorMsg，状态保持「未知」而不是伪造成离线。
   */
  async loadData(): Promise<void> {
    await this.handleAsync(async () => {
      const online = await IotService.getInstance().isDeviceOnline();
      Logger.info(TAG, '设备在线状态：' + online);
      for (let i = 0; i < this.devices.length; i++) {
        const dev = this.devices[i];
        if (dev.type === '控制器') {
          continue;
        }
        dev.status = online ? 1 : 0;
        dev.lastUpdate = online ? '在线' : '离线';
      }
    });
    this.updateCounts();
  }

  /**
   * 刷新单个设备状态
   *
   * @param deviceId 设备 ID
   */
  async refreshStatus(deviceId: string): Promise<void> {
    if (this.isLoading) {
      return;
    }
    await this.handleAsync(async () => {
      const online = await IotService.getInstance().isDeviceOnline();
      for (let i = 0; i < this.devices.length; i++) {
        if (this.devices[i].id === deviceId) {
          if (this.devices[i].type !== '控制器') {
            this.devices[i].status = online ? 1 : 0;
            this.devices[i].lastUpdate = online ? '在线' : '离线';
          }
          break;
        }
      }
    });
    this.updateCounts();
  }

  /** 重新计算设备总数 / 在线 / 离线（0 = 未知，不计入离线） */
  private updateCounts(): void {
    let online = 0;
    let offline = 0;
    for (let i = 0; i < this.devices.length; i++) {
      if (this.devices[i].status === 1) {
        online++;
      } else if (this.devices[i].status === 0 && this.devices[i].lastUpdate === '离线') {
        offline++;
      }
    }
    this.totalCount = this.devices.length;
    this.onlineCount = online;
    this.offlineCount = offline;
  }
}
