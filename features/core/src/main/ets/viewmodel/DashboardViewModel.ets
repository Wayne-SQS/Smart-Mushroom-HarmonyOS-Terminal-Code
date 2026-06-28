import { Logger, SensorType, StyleConstants } from 'common-base';
import { IotService } from '../service/IotService';
import { SensorDataItem, AlertItem, ControlItem } from '../model/GreenhouseModel';
import { BaseViewModel } from './BaseViewModel';

const TAG = 'DashboardViewModel';
/** 华为云 IoTDA 实际服务 ID */
const SMART_ROOM_SERVICE_ID = 'smartRoom';

/** 仪表盘概览统计 */
interface DashboardOverview {
  onlineDevices: number;
  todayYield: string;
  currentBatches: number;
}

/**
 * 大棚仪表盘 ViewModel
 *
 * 负责整合传感器数据、快捷控制项、概览统计与告警列表。
 *
 * 数据来源：
 * - 传感器：IoT 设备影子 smartRoom 服务（失败时降级为 mock 数据）
 * - 控制项：本地状态 → IotService 下发 SetLamp/SetCond/SetVent 命令
 * - 告警：由 AlertViewModel.loadFromSensors 派生
 *
 * 硬件协议对齐：命令名/参数 key 与嵌入式端 mqtt.c handle_cloud_command() 完全一致。
 *
 * 状态计算规则（基于 min/max）：
 * - 值在 [min, max] 范围内 → status 0（正常）
 * - 超出范围 < 10% → status 0（容差）
 * - 超出范围 10%~20% → status 1（警告）
 * - 超出范围 ≥ 20% → status 2（危险）
 */
export class DashboardViewModel extends BaseViewModel {
  /** 传感器数据列表（默认 mock，IoT 可用时覆盖） */
  sensors: SensorDataItem[] = [
    { type: SensorType.TEMPERATURE, value: 22.5, min: 15, max: 28, status: 0 },
    { type: SensorType.HUMIDITY, value: 85, min: 70, max: 95, status: 0 },
    { type: SensorType.CO2, value: 1200, min: 400, max: 1500, status: 1 },
    { type: SensorType.LIGHT, value: 350, min: 100, max: 800, status: 0 },
    { type: SensorType.SOIL_MOISTURE, value: 68, min: 50, max: 80, status: 0 },
    { type: SensorType.SOIL_TEMP, value: 20.3, min: 15, max: 25, status: 0 }
  ];

  /** 快捷控制项（与嵌入式端 mqtt.c 支持的 3 个执行器对齐） */
  controls: ControlItem[] = [
    { id: 'fan', name: '通风', icon: '🌬', active: true, color: StyleConstants.INFO },
    { id: 'condi', name: '空调', icon: '❄', active: false, color: StyleConstants.PRIMARY_LIGHT },
    { id: 'light', name: '补光', icon: '💡', active: false, color: StyleConstants.WARNING }
  ];

  /** 概览统计 */
  overview: DashboardOverview = {
    onlineDevices: 7,
    todayYield: '12.5kg',
    currentBatches: 3
  };

  /** 告警列表（默认空，由 AlertViewModel 派生；保留字段供 UI 直接绑定） */
  alerts: AlertItem[] = [];

  /**
   * 加载仪表盘数据
   *
   * 流程：
   * 1. 调用 IoT 查询 smartRoom 服务属性
   * 2. 服务不存在或加载失败 → 保持 mock 数据
   * 3. 成功则按属性键映射到对应传感器并重算 status
   * 4. 同步 LampST/CondST 到 controls 状态
   */
  async loadData(): Promise<void> {
    await this.handleAsync(async () => {
      const props = await IotService.getInstance().getDeviceProperties(SMART_ROOM_SERVICE_ID);
      if (props === null) {
        Logger.warn(TAG, 'smartRoom 服务不存在，保持 mock 数据');
        return;
      }
      this.applyProperties(props);
      this.syncControlState(props);
    });
  }

  /**
   * 切换控制项状态
   *
   * 采用乐观更新策略：先改本地状态，IoT 失败时回滚。
   *
   * 控制项 → 命令映射（与嵌入式 mqtt.c handle_cloud_command 对齐）：
   * - fan   → smartRoom/SetVent  (paras={VentStatus:'ON'/'OFF'})
   * - condi → smartRoom/SetCond  (paras={CondStatus:'ON'/'OFF'})
   * - light → smartRoom/SetLamp  (paras={LampStatus:'ON'/'OFF'})
   *
   * @param controlId 控制项 ID（fan/condi/light）
   * @param on 是否开启
   */
  async refreshControl(controlId: string, on: boolean): Promise<void> {
    this.setControlActive(controlId, on);
    this.errorMsg = '';
    await this.handleAsync(async () => {
      const iot = IotService.getInstance();
      if (controlId === 'light') {
        await iot.controlLight(on);
      } else if (controlId === 'fan') {
        await iot.controlFan(on);
      } else if (controlId === 'condi') {
        await iot.controlCondi(on);
      } else {
        Logger.warn(TAG, '未知控制项：' + controlId);
      }
    });
    if (this.errorMsg.length > 0) {
      // 失败回滚
      this.setControlActive(controlId, !on);
      Logger.warn(TAG, '命令下发失败，已回滚：' + this.errorMsg);
    } else {
      Logger.info(TAG, '命令下发成功：' + controlId + ' → ' + (on ? 'ON' : 'OFF'));
    }
  }

  /**
   * 根据 LampST / CondST / VentST 同步 controls 数组中灯/空调/风扇的激活状态
   *
   * LampST='ON' → light.active=true
   * CondST='ON' → condi.active=true
   * VentST='ON' → fan.active=true
   */
  private syncControlState(props: Record<string, Object>): void {
    const lampSt = props['LampST'] as string | undefined;
    const condSt = props['CondST'] as string | undefined;
    const ventSt = props['VentST'] as string | undefined;
    if (lampSt !== undefined) {
      this.setControlActive('light', lampSt === 'ON' || lampSt === '1');
    }
    if (condSt !== undefined) {
      this.setControlActive('condi', condSt === 'ON' || condSt === '1');
    }
    if (ventSt !== undefined) {
      this.setControlActive('fan', ventSt === 'ON' || ventSt === '1');
    }
  }

  /**
   * 将 IoT 属性映射到 sensors 数组
   *
   * 使用 switch 显式分支按 type 取值，避免动态属性访问。
   */
  private applyProperties(props: Record<string, Object>): void {
    for (let i = 0; i < this.sensors.length; i++) {
      const sensor = this.sensors[i];
      const value = this.extractSensorValue(props, sensor.type);
      if (value !== null) {
        sensor.value = value;
        sensor.status = this.calculateStatus(value, sensor.min, sensor.max);
      }
    }
  }

  /**
   * 根据传感器类型从 props 提取数值
   *
   * 显式 switch 分支，避免 obj[dynamicKey] 动态访问。
   *
   * 映射关系（smartRoom 服务属性 → SensorType）：
   * - Temp  → TEMPERATURE    （硬件 DHT11）
   * - Humi  → HUMIDITY       （硬件 DHT11）
   * - Lumi  → LIGHT          （硬件 LDR）
   * - CO2   → CO2            （硬件 CO2 传感器）
   * - Dist  → SOIL_MOISTURE  （预留，硬件暂未上报，mock 兜底）
   * - LampST / CondST / VentST 不在此处映射，由 syncControlState() 处理
   * - SOIL_TEMP / PH：云平台暂未定义对应属性，保留 mock 值
   * - Smoke：云平台有此属性，当前未分配 SensorType（可后续新增 SMOKE 类型）
   */
  private extractSensorValue(props: Record<string, Object>, type: string): number | null {
    let raw: Object | undefined;
    switch (type) {
      case SensorType.TEMPERATURE:
        raw = props['Temp'];
        break;
      case SensorType.HUMIDITY:
        raw = props['Humi'];
        break;
      case SensorType.LIGHT:
        raw = props['Lumi'];
        break;
      case SensorType.CO2:
        raw = props['CO2'];
        break;
      case SensorType.SOIL_MOISTURE:
        raw = props['Dist'];
        break;
      case SensorType.SOIL_TEMP:
        // 云平台未定义土壤温度属性，保持 mock 值
        return null;
      default:
        return null;
    }
    return this.toNumber(raw);
  }

  /**
   * 安全转换为数值
   *
   * 支持 number / string / boolean，无效时返回 null。
   */
  private toNumber(value: Object | undefined): number | null {
    if (value === undefined || value === null) {
      return null;
    }
    if (typeof value === 'number') {
      return value;
    }
    if (typeof value === 'string') {
      const num = Number(value);
      return isNaN(num) ? null : num;
    }
    if (typeof value === 'boolean') {
      return value ? 1 : 0;
    }
    return null;
  }

  /**
   * 根据数值与 [min, max] 范围计算 status
   *
   * - 在范围内 → 0
   * - 超出范围 < 10%（容差）→ 0
   * - 超出范围 10%~20% → 1
   * - 超出范围 ≥ 20% → 2
   */
  private calculateStatus(value: number, min: number, max: number): number {
    if (value >= min && value <= max) {
      return 0;
    }
    const range = max - min;
    if (range <= 0) {
      return 1;
    }
    let overflow: number;
    if (value > max) {
      overflow = value - max;
    } else {
      overflow = min - value;
    }
    const ratio = overflow / range;
    if (ratio >= 0.2) {
      return 2;
    }
    if (ratio >= 0.1) {
      return 1;
    }
    return 0;
  }

  /** 设置控制项激活状态 */
  private setControlActive(controlId: string, on: boolean): void {
    for (let i = 0; i < this.controls.length; i++) {
      if (this.controls[i].id === controlId) {
        this.controls[i].active = on;
        break;
      }
    }
  }
}
