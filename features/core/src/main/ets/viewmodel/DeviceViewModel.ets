import { Logger } from 'common-base';
import { IotService } from '../service/IotService';
import { DeviceItem } from '../model/GreenhouseModel';
import { BaseViewModel } from './BaseViewModel';

const TAG = 'DeviceViewModel';

/**
 * 设备管理 ViewModel
 *
 * 设备列表当前为本地 mock（IotService 暂未提供 listDevices API），
 * 仅 status 字段尝试从 IoT 同步：
 * - isDeviceOnline() 返回 true → 传感器类设备标记为在线
 * - 返回 false → 传感器类设备标记为离线
 * - 控制器类设备保持 mock 状态（不受 IoT 在线状态影响）
 *
 * 失败时整体保持 mock 状态。
 */
export class DeviceViewModel extends BaseViewModel {
  /** 设备列表（默认 mock） */
  devices: DeviceItem[] = [
    { id: '1', name: '温度传感器-A区', type: '温度', status: 1, lastUpdate: '10秒前', location: 'A区东侧' },
    { id: '2', name: '湿度传感器-A区', type: '湿度', status: 1, lastUpdate: '8秒前', location: 'A区西侧' },
    { id: '3', name: 'CO2传感器-A区', type: 'CO₂', status: 1, lastUpdate: '15秒前', location: 'A区中央' },
    { id: '4', name: '光照传感器-B区', type: '光照', status: 1, lastUpdate: '5秒前', location: 'B区顶部' },
    { id: '5', name: '土壤湿度-3号', type: '土壤湿度', status: 0, lastUpdate: '15分钟前', location: 'C区3号位' },
    { id: '6', name: '通风控制器', type: '控制器', status: 1, lastUpdate: '运行中', location: '大棚东墙' },
    { id: '7', name: '喷雾系统', type: '控制器', status: 1, lastUpdate: '待机', location: '大棚顶部' },
    { id: '8', name: '补光灯组', type: '控制器', status: 0, lastUpdate: '已关闭', location: 'B区顶部' }
  ];

  /** 设备总数 */
  totalCount: number = 8;
  /** 在线设备数 */
  onlineCount: number = 7;
  /** 离线设备数 */
  offlineCount: number = 1;

  /**
   * 加载设备数据
   *
   * 调用 IoT 同步传感器类设备在线状态；失败时保持 mock 状态。
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
        if (online) {
          dev.status = 1;
          dev.lastUpdate = '在线';
        } else {
          dev.status = 0;
          dev.lastUpdate = '离线';
        }
      }
    });
    // 无论成功失败，都重新计算统计
    this.updateCounts();
  }

  /**
   * 刷新单个设备状态
   *
   * @param deviceId 设备 ID
   */
  async refreshStatus(deviceId: string): Promise<void> {
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

  /** 重新计算设备总数 / 在线 / 离线 */
  private updateCounts(): void {
    let online = 0;
    let offline = 0;
    for (let i = 0; i < this.devices.length; i++) {
      if (this.devices[i].status === 1) {
        online++;
      } else {
        offline++;
      }
    }
    this.totalCount = this.devices.length;
    this.onlineCount = online;
    this.offlineCount = offline;
  }
}
