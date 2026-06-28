/**
 * 应用样式常量
 *
 * 视觉风格：自然生态 + 科技感
 * 主色调：森林绿 + 蘑菇暖棕 + 数据蓝
 */

export class StyleConstants {
  // ==================== 品牌色 ====================
  static readonly PRIMARY: string = '#2E7D32';
  static readonly PRIMARY_LIGHT: string = '#4CAF50';
  static readonly PRIMARY_DARK: string = '#1B5E20';
  static readonly ACCENT: string = '#8D6E63';
  static readonly ACCENT_LIGHT: string = '#BCAAA4';

  // ==================== 功能色 ====================
  static readonly SUCCESS: string = '#52C41A';
  static readonly WARNING: string = '#FAAD14';
  static readonly DANGER: string = '#FF4D4F';
  static readonly INFO: string = '#1890FF';
  static readonly PURPLE: string = '#722ED1';

  // ==================== 背景色 ====================
  static readonly BG_PAGE: string = '#F0F4F0';
  static readonly BG_CARD: string = '#FFFFFF';
  static readonly BG_CARD_LIGHT: string = '#F5F9F5';
  static readonly BG_DARK_CARD: string = '#1A2E1A';

  // ==================== 文字色 ====================
  static readonly TEXT_TITLE: string = '#1A1A1A';
  static readonly TEXT_BODY: string = '#333333';
  static readonly TEXT_SUB: string = '#666666';
  static readonly TEXT_HINT: string = '#999999';
  static readonly TEXT_WHITE: string = '#FFFFFF';
  static readonly TEXT_WHITE_SUB: string = '#FFFFFFCC';

  // ==================== 分割线/边框 ====================
  static readonly DIVIDER: string = '#E8E8E8';
  static readonly BORDER: string = '#E0E0E0';
  static readonly BORDER_LIGHT: string = '#F0F0F0';

  // ==================== 传感器配色 ====================
  static readonly COLOR_TEMP: string = '#FF7043';
  static readonly COLOR_HUMIDITY: string = '#42A5F5';
  static readonly COLOR_CO2: string = '#7E57C2';
  static readonly COLOR_LIGHT: string = '#FFA726';
  static readonly COLOR_SOIL: string = '#43A047';
  static readonly COLOR_PH: string = '#AB47BC';

  // ==================== 圆角 vp ====================
  static readonly RADIUS_SM: number = 8;
  static readonly RADIUS_MD: number = 12;
  static readonly RADIUS_LG: number = 16;
  static readonly RADIUS_XL: number = 24;

  // ==================== 间距 vp ====================
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
