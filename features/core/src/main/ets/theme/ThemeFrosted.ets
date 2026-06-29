/**
 * 主题 A — 雾透玻璃 🌸 theme_frosted
 *
 * 关键词：浅色、发白淡彩、毛玻璃、年轻、弹性动画
 *
 * 所有半透明色使用 8 位 hex（#RRGGBBAA），ArkUI API 12+ 官方推荐格式。
 * 毛玻璃三件套：半透白底 + backdropBlur + 白边。
 */
import { ThemeTokens } from './ThemeTokens';

export const FROSTED_THEME: ThemeTokens = {
  name: 'frosted',

  // 品牌
  primary: '#7EC8A3',
  primaryLight: '#B5E3CC',
  primaryDark: '#5DAF8A',
  accent: '#A8C8F0',
  accentLight: '#D6E6F8',

  // 功能色
  success: '#B5E0C3',
  warning: '#F5E0B0',
  danger: '#F0B8B8',
  info: '#B0D0F0',
  purple: '#D0C0F0',

  // 背景
  bgPage: '#F2F5F9',
  bgCard: '#FFFFFF',
  bgCardLight: '#F0F4F2',
  bgOverlay: '#E8E8E8',
  bgTabBar: '#FFFFFF',

  // Header 渐变
  headerGradientTop: '#2C3E50',
  headerGradientBottom: '#1A252F',

  // 文字
  textTitle: '#1A2A35',
  textBody: '#324550',
  textSub: '#546E7A',
  textHint: '#7E929F',
  textWhite: '#FFFFFF',
  textWhiteSub: '#B0BEC5',

  // 边框 & 分割线
  divider: '#DCE1E5',
  border: '#D5DBE0',
  borderLight: '#E8ECEF',

  // 传感器配色（仅供装饰，严禁作为文字色）
  colorTemp: '#F2B8B0',
  colorHumidity: '#A8D0F0',
  colorCo2: '#C0B8E8',
  colorLight: '#F0E0B0',
  colorSoil: '#B0D8C0',
  colorPh: '#D8C0E0',

  // 圆角
  radiusSm: 12,
  radiusMd: 16,
  radiusLg: 20,
  radiusXl: 28,
  radiusFull: 9999,

  // 阴影
  shadowCardRadius: 12,
  shadowCardColor: '#C8D4CD',
  shadowCardOffsetY: 4,
  shadowHoverRadius: 20,
  shadowHoverColor: '#BCC9C2',
  shadowHoverOffsetY: 8,
  shadowHeaderRadius: 32,
  shadowHeaderColor: '#C0D0C8',
  shadowHeaderOffsetY: 6,
  shadowFloatRadius: 40,
  shadowFloatColor: '#C8C8C8',
  shadowFloatOffsetY: 12,

  // 毛玻璃
  blurAmount: 16,

  // 文字颜色
  textOnPrimary: '#FFFFFF',
  textOnDanger: '#FFFFFF',
  textOnWarning: '#3D2E00',

  // 字号
  fontXs: 10,
  fontSm: 13,
  fontMd: 15,
  fontLg: 18,
  fontXl: 22,
  fontXxl: 34,

  // 动画
  animationEnabled: true,
  animationDuration: 400,
};
