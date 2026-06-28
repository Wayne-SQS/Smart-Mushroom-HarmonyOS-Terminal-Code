/**
 * 设备能力检测工具
 *
 * 用于多端适配时检测设备类型与系统能力，
 * 所有差异 API 调用前应通过 CapabilityUtils 检测。
 *
 * 使用方式：
 *   if (CapabilityUtils.supportMap()) { ... }
 *   if (CapabilityUtils.isWearable()) { ... }
 */
import { BreakpointConstants } from '../constants/BreakpointConstants';

/** 设备类型枚举 */
export enum DeviceCategory {
  PHONE = 'phone',
  TABLET = 'tablet',
  TWO_IN_ONE = '2in1',
  CAR = 'car',
  WEARABLE = 'wearable',
  TV = 'tv',
  UNKNOWN = 'unknown'
}

/** 设备能力集合 */
export interface DeviceCapability {
  supportsMap: boolean;
  supportsChart: boolean;
  supportsComplexLayout: boolean;
  supportsKeyboard: boolean;
  supportsVoice: boolean;
  maxListItems: number;
}

export class CapabilityUtils {
  private static cachedDeviceType: string = '';

  /**
   * 获取当前设备类型（由 EntryAbility 在启动时通过 deviceInfo 注入）
   * 若未注入则返回 UNKNOWN
   */
  static getDeviceType(): string {
    if (CapabilityUtils.cachedDeviceType) {
      return CapabilityUtils.cachedDeviceType;
    }
    try {
      const stored = AppStorage.get<string>('deviceType');
      CapabilityUtils.cachedDeviceType = stored ? stored : DeviceCategory.UNKNOWN;
    } catch {
      CapabilityUtils.cachedDeviceType = DeviceCategory.UNKNOWN;
    }
    return CapabilityUtils.cachedDeviceType;
  }

  /**
   * 由 EntryAbility 调用注入设备类型
   */
  static setDeviceType(deviceType: string): void {
    CapabilityUtils.cachedDeviceType = deviceType;
    try {
      AppStorage.setOrCreate<string>('deviceType', deviceType);
    } catch {
      // ignore
    }
  }

  /**
   * 根据断点推断设备类别（用于无 deviceInfo 时的兜底）
   */
  static inferCategoryByBreakpoint(breakpoint: string): string {
    switch (breakpoint) {
      case BreakpointConstants.XS: return DeviceCategory.WEARABLE;
      case BreakpointConstants.SM: return DeviceCategory.PHONE;
      case BreakpointConstants.MD: return DeviceCategory.PHONE;
      case BreakpointConstants.LG: return DeviceCategory.TABLET;
      case BreakpointConstants.XL: return DeviceCategory.TWO_IN_ONE;
      default: return DeviceCategory.PHONE;
    }
  }

  // ==================== 设备类型判断 ====================

  static isWearable(): boolean {
    return CapabilityUtils.getDeviceType() === DeviceCategory.WEARABLE;
  }

  static isTV(): boolean {
    return CapabilityUtils.getDeviceType() === DeviceCategory.TV;
  }

  static isCar(): boolean {
    return CapabilityUtils.getDeviceType() === DeviceCategory.CAR;
  }

  static isPhone(): boolean {
    return CapabilityUtils.getDeviceType() === DeviceCategory.PHONE;
  }

  static isTablet(): boolean {
    return CapabilityUtils.getDeviceType() === DeviceCategory.TABLET;
  }

  static is2in1(): boolean {
    return CapabilityUtils.getDeviceType() === DeviceCategory.TWO_IN_ONE;
  }

  // ==================== 能力检测 ====================

  /**
   * 是否支持地图功能（手表/车机不支持）
   */
  static supportsMap(): boolean {
    const dt = CapabilityUtils.getDeviceType();
    return dt !== DeviceCategory.WEARABLE && dt !== DeviceCategory.CAR;
  }

  /**
   * 是否支持图表渲染（手表不支持复杂图表）
   */
  static supportsChart(): boolean {
    return !CapabilityUtils.isWearable();
  }

  /**
   * 是否支持复杂双栏布局（手表/手机竖屏不支持）
   */
  static supportsComplexLayout(breakpoint: string): boolean {
    if (CapabilityUtils.isWearable()) {
      return false;
    }
    return breakpoint === BreakpointConstants.MD
      || breakpoint === BreakpointConstants.LG
      || breakpoint === BreakpointConstants.XL;
  }

  /**
   * 是否支持键鼠交互（仅 2in1 / 大屏平板）
   */
  static supportsKeyboard(breakpoint: string): boolean {
    return CapabilityUtils.is2in1()
      || breakpoint === BreakpointConstants.XL
      || (CapabilityUtils.isTablet() && breakpoint === BreakpointConstants.LG);
  }

  /**
   * 是否支持语音控制
   */
  static supportsVoice(): boolean {
    if (CapabilityUtils.isWearable()) {
      return false;
    }
    return CapabilityUtils.canIUse('SpeechRecognizer');
  }

  /**
   * 列表最大建议条数（手表降级）
   */
  static maxListItems(): number {
    if (CapabilityUtils.isWearable()) {
      return 20;
    }
    if (CapabilityUtils.isTV()) {
      return 50;
    }
    return 10000;
  }

  /**
   * 获取当前设备的完整能力描述
   */
  static getCapability(breakpoint: string): DeviceCapability {
    return {
      supportsMap: CapabilityUtils.supportsMap(),
      supportsChart: CapabilityUtils.supportsChart(),
      supportsComplexLayout: CapabilityUtils.supportsComplexLayout(breakpoint),
      supportsKeyboard: CapabilityUtils.supportsKeyboard(breakpoint),
      supportsVoice: CapabilityUtils.supportsVoice(),
      maxListItems: CapabilityUtils.maxListItems()
    };
  }

  // ==================== canIUse 封装 ====================

  /**
   * 安全的 canIUse 封装，捕获异常并返回 false
   */
  static canIUse(api: string): boolean {
    try {
      return canIUse(api);
    } catch {
      return false;
    }
  }
}
