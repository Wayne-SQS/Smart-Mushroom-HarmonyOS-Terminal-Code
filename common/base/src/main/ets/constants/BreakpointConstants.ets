/**
 * 断点常量定义
 *
 * XS (0~320)    → 手表
 * SM (320~600)  → 手机竖屏
 * MD (600~840)  → 折叠屏/小平板
 * LG (840~1440) → 平板横屏
 * XL (1440+)    → 大屏PC
 */

export class BreakpointConstants {
  static readonly XS: string = 'xs';
  static readonly SM: string = 'sm';
  static readonly MD: string = 'md';
  static readonly LG: string = 'lg';
  static readonly XL: string = 'xl';

  /** 断点阈值 vp */
  static readonly BREAKPOINT_SM: number = 320;
  static readonly BREAKPOINT_MD: number = 600;
  static readonly BREAKPOINT_LG: number = 840;
  static readonly BREAKPOINT_XL: number = 1440;
}

/** 自适应工具：根据断点返回列数/间距/字号 */
export class AdaptiveUtils {
  /**
   * 根据断点获取GridCol列数
   * xs: 2列  sm: 2列  md: 3列  lg: 4列  xl: 6列
   */
  static getSensorColumns(breakpoint: string): number {
    switch (breakpoint) {
      case BreakpointConstants.XS: return 2;
      case BreakpointConstants.SM: return 2;
      case BreakpointConstants.MD: return 3;
      case BreakpointConstants.LG: return 4;
      case BreakpointConstants.XL: return 6;
      default: return 2;
    }
  }

  /**
   * 根据断点获取传感器卡片数据字号
   */
  static getSensorDataFontSize(breakpoint: string): number {
    switch (breakpoint) {
      case BreakpointConstants.XS: return 16;
      case BreakpointConstants.SM: return 18;
      case BreakpointConstants.MD: return 20;
      case BreakpointConstants.LG: return 24;
      case BreakpointConstants.XL: return 28;
      default: return 18;
    }
  }

  /**
   * 根据断点获取传感器卡片内边距
   */
  static getSensorCardPadding(breakpoint: string): number {
    switch (breakpoint) {
      case BreakpointConstants.XS: return 6;
      case BreakpointConstants.SM: return 8;
      case BreakpointConstants.MD: return 10;
      case BreakpointConstants.LG: return 12;
      case BreakpointConstants.XL: return 14;
      default: return 8;
    }
  }

  /**
   * 根据断点获取页面内边距
   * xs: 8vp  sm: 12vp  md: 16vp  lg: 24vp  xl: 32vp
   */
  static getPagePadding(breakpoint: string): number {
    switch (breakpoint) {
      case BreakpointConstants.XS: return 8;
      case BreakpointConstants.SM: return 12;
      case BreakpointConstants.MD: return 16;
      case BreakpointConstants.LG: return 24;
      case BreakpointConstants.XL: return 32;
      default: return 12;
    }
  }

  /**
   * 根据断点获取卡片间距
   */
  static getCardGap(breakpoint: string): number {
    switch (breakpoint) {
      case BreakpointConstants.XS: return 6;
      case BreakpointConstants.SM: return 10;
      case BreakpointConstants.MD: return 12;
      case BreakpointConstants.LG: return 16;
      case BreakpointConstants.XL: return 20;
      default: return 10;
    }
  }

  /**
   * 根据断点判断是否显示双栏布局
   */
  static isDualPane(breakpoint: string): boolean {
    return breakpoint === BreakpointConstants.MD
      || breakpoint === BreakpointConstants.LG
      || breakpoint === BreakpointConstants.XL;
  }

  /**
   * 根据断点判断是否为大屏
   */
  static isLargeScreen(breakpoint: string): boolean {
    return breakpoint === BreakpointConstants.LG
      || breakpoint === BreakpointConstants.XL;
  }

  /**
   * XL 屏内容最大宽度（vp）
   *
   * 超大屏（PC/大平板）下，主内容区不应无限拉伸，
   * 用此值限宽居中，避免单行过长影响阅读。
   */
  static getMaxContentWidth(breakpoint: string): number {
    switch (breakpoint) {
      case BreakpointConstants.XL: return 1280;
      case BreakpointConstants.LG: return 1100;
      default: return 0; // 不限宽
    }
  }

  /**
   * 根据断点获取设备列表列数
   * xs/sm: 1列  md: 2列  lg: 3列  xl: 4列
   */
  static getDeviceColumns(breakpoint: string): number {
    switch (breakpoint) {
      case BreakpointConstants.XS: return 1;
      case BreakpointConstants.SM: return 1;
      case BreakpointConstants.MD: return 2;
      case BreakpointConstants.LG: return 3;
      case BreakpointConstants.XL: return 4;
      default: return 1;
    }
  }

  /**
   * 根据断点获取配方/告警卡片列数
   * xs: 1列  sm: 1列  md: 2列  lg: 2列  xl: 3列
   */
  static getCardColumns(breakpoint: string): number {
    switch (breakpoint) {
      case BreakpointConstants.XS: return 1;
      case BreakpointConstants.SM: return 1;
      case BreakpointConstants.MD: return 2;
      case BreakpointConstants.LG: return 2;
      case BreakpointConstants.XL: return 3;
      default: return 1;
    }
  }

  /**
   * 根据断点获取主标题字号
   */
  static getTitleFontSize(breakpoint: string): number {
    switch (breakpoint) {
      case BreakpointConstants.XS: return 18;
      case BreakpointConstants.SM: return 20;
      case BreakpointConstants.MD: return 22;
      case BreakpointConstants.LG: return 24;
      case BreakpointConstants.XL: return 26;
      default: return 20;
    }
  }
}
