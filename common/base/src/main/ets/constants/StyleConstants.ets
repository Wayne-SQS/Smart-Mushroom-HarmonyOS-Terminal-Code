/**
 * 应用样式常量（全局唯一视觉基线）
 *
 * 视觉风格：低饱和、简洁、高对比。
 * 配色与 features/core/theme 的 ThemeTokens 保持同一套色板：
 * 菌菇棕作主色，中性灰作背景，传感器色仅用于装饰。
 *
 * 说明：颜色/圆角/字号优先从 ThemeTokens 取（支持双主题），
 * 本文件的 Layout 常量用于「与主题无关的尺寸规则」——
 * 间距 4/8/12/16/24/32、圆角 8/12/16、按钮 40/36、标题栏 56。
 */

export class StyleConstants {
  // ==================== 品牌色（与 FROSTED_THEME 对齐） ====================
  static readonly PRIMARY: string = '#C68642';
  static readonly PRIMARY_LIGHT: string = '#D4A06A';
  static readonly PRIMARY_DARK: string = '#8B5A2B';
  static readonly ACCENT: string = '#7A9E6E';
  static readonly ACCENT_LIGHT: string = '#C9DBBF';

  // ==================== 功能色 ====================
  static readonly SUCCESS: string = '#7A9E6E';
  static readonly WARNING: string = '#E6A23C';
  static readonly DANGER: string = '#E06C75';
  static readonly INFO: string = '#6B8E9E';
  static readonly PURPLE: string = '#A88BA8';

  // ==================== 背景色 ====================
  static readonly BG_PAGE: string = '#F5F6F7';
  static readonly BG_CARD: string = '#FFFFFF';
  static readonly BG_CARD_LIGHT: string = '#E8E8E8';
  static readonly BG_DARK_CARD: string = '#1A1A1A';

  // ==================== 文字色 ====================
  static readonly TEXT_TITLE: string = '#2A2A2A';
  static readonly TEXT_BODY: string = '#3A3A3A';
  static readonly TEXT_SUB: string = '#6A6A6A';
  static readonly TEXT_HINT: string = '#9A9A9A';
  static readonly TEXT_WHITE: string = '#FFFFFF';
  static readonly TEXT_WHITE_SUB: string = '#F0F0F0';

  // ==================== 分割线/边框 ====================
  static readonly DIVIDER: string = '#E8E8E8';
  static readonly BORDER: string = '#DDDDDD';
  static readonly BORDER_LIGHT: string = '#DCDCDC';

  // ==================== 传感器配色（仅装饰） ====================
  static readonly COLOR_TEMP: string = '#E8A87C';
  static readonly COLOR_HUMIDITY: string = '#7EB5D6';
  static readonly COLOR_CO2: string = '#A88BA8';
  static readonly COLOR_LIGHT: string = '#F0D585';
  static readonly COLOR_SOIL: string = '#7A9E6E';
  static readonly COLOR_PH: string = '#D88AA0';

  // ==================== 圆角 vp（8 / 12 / 16） ====================
  static readonly RADIUS_SM: number = 8;
  static readonly RADIUS_MD: number = 12;
  static readonly RADIUS_LG: number = 16;
  static readonly RADIUS_XL: number = 24;

  // ==================== 间距 vp（4 的倍数） ====================
  static readonly SPACE_XS: number = 4;
  static readonly SPACE_SM: number = 8;
  static readonly SPACE_MD: number = 12;
  static readonly SPACE_LG: number = 16;
  static readonly SPACE_XL: number = 24;
  static readonly SPACE_XXL: number = 32;

  // ==================== 字号 fp ====================
  static readonly FONT_XS: number = 10;
  static readonly FONT_SM: number = 12;
  static readonly FONT_MD: number = 14;
  static readonly FONT_LG: number = 16;
  static readonly FONT_XL: number = 18;
  static readonly FONT_XXL: number = 22;
  static readonly FONT_TITLE: number = 28;
  static readonly FONT_DATA: number = 36;

  // ==================== 卡片阴影 ====================
  static readonly SHADOW_CARD_RADIUS: number = 8;
  static readonly SHADOW_CARD_COLOR: string = '#0D000000';
  static readonly SHADOW_CARD_OFFSETY: number = 2;

  static readonly SHADOW_FLOAT_RADIUS: number = 16;
  static readonly SHADOW_FLOAT_COLOR: string = '#1A000000';
  static readonly SHADOW_FLOAT_OFFSETY: number = 4;
}

/**
 * 布局与控件尺寸常量（与主题无关的统一骨架规则）
 *
 * 所有页面/组件引用此处，禁止再写魔法数字。
 */
export class LayoutConstants {
  /** 卡片圆角（12）+ 1px 描边 + 极浅阴影 */
  static readonly CARD_RADIUS: number = StyleConstants.RADIUS_MD;
  /** 卡片/输入框描边宽度 */
  static readonly CARD_BORDER_WIDTH: number = 1;
  /** 顶部标题栏高度（不含安全区） */
  static readonly HEADER_HEIGHT: number = 56;
  /** 顶部标题栏最小高度（含安全区时） */
  static readonly HEADER_MIN_HEIGHT: number = 56;
  /** 主按钮高度（通栏） */
  static readonly BUTTON_HEIGHT_PRIMARY: number = 40;
  /** 次按钮高度（描边） */
  static readonly BUTTON_HEIGHT_SECONDARY: number = 36;
  /** 小号操作按钮高度 */
  static readonly BUTTON_HEIGHT_SMALL: number = 32;
  /** 图标容器尺寸 */
  static readonly ICON_BOX_SM: number = 32;
  static readonly ICON_BOX_MD: number = 40;
  static readonly ICON_BOX_LG: number = 48;
  /** 设置项行高 */
  static readonly ROW_HEIGHT_LIST_ITEM: number = 52;
  /** 分割线宽度 */
  static readonly HAIRLINE: number = 0.5;
  /** 列表底部留白（避开 TabBar） */
  static readonly BOTTOM_SAFE_SPACE: number = 80;
  /** 内容最大宽度（无断点信息时的兜底） */
  static readonly CONTENT_MAX_WIDTH: number = 960;
}

/** 传感器类型枚举 */
export enum SensorType {
  TEMPERATURE = 'temperature',
  HUMIDITY = 'humidity',
  CO2 = 'co2',
  LIGHT = 'light',
  SOIL_MOISTURE = 'soil_moisture',
  SOIL_TEMP = 'soil_temp',
  PH = 'ph'
}

/** 传感器显示配置 */
export interface SensorDisplayConfig {
  readonly name: string;
  readonly unit: string;
  readonly icon: string;
  readonly color: string;
}

/** 传感器配置工具 */
export class SensorConfigUtil {
  private static readonly CONFIG_MAP: Record<string, SensorDisplayConfig> = {
    [SensorType.TEMPERATURE]: { name: '温度', unit: '°C', icon: '🌡', color: StyleConstants.COLOR_TEMP },
    [SensorType.HUMIDITY]: { name: '空气湿度', unit: '%', icon: '💧', color: StyleConstants.COLOR_HUMIDITY },
    [SensorType.CO2]: { name: 'CO₂浓度', unit: 'ppm', icon: '🌫', color: StyleConstants.COLOR_CO2 },
    [SensorType.LIGHT]: { name: '光照强度', unit: 'lux', icon: '☀', color: StyleConstants.COLOR_LIGHT },
    [SensorType.SOIL_MOISTURE]: { name: '土壤湿度', unit: '%', icon: '🌱', color: StyleConstants.COLOR_SOIL },
    [SensorType.SOIL_TEMP]: { name: '土壤温度', unit: '°C', icon: '🌍', color: StyleConstants.COLOR_TEMP },
    [SensorType.PH]: { name: 'pH值', unit: '', icon: '⚗', color: StyleConstants.COLOR_PH }
  };

  static getConfig(type: SensorType): SensorDisplayConfig {
    const config = SensorConfigUtil.CONFIG_MAP[type];
    if (config) {
      return config;
    }
    return { name: '未知', unit: '', icon: '📊', color: '#666666' };
  }
}
