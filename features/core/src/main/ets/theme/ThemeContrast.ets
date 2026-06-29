/**
 * 主题 B — 极致黑白 ⚫ theme_contrast
 *
 * 关键词：纯黑纯白、高对比、无修饰、专业克制
 *
 * 所有半透明色使用 8 位 hex（#RRGGBBAA）。
 */
import { ThemeTokens } from './ThemeTokens';

export const CONTRAST_THEME: ThemeTokens = {
  name: 'contrast',

  // 品牌
  primary: '#000000',
  primaryLight: '#333333',
  primaryDark: '#000000',
  accent: '#0052D9',
  accentLight: '#EBF2FF',

  // 功能色
  success: '#00A83C',
  warning: '#F5A623',
  danger: '#E6001A',
  info: '#0052D9',
  purple: '#7B2D8E',

  // 背景
  bgPage: '#F3F3F3',
  bgCard: '#FFFFFF',
  bgCardLight: '#FAFAFA',
  bgOverlay: '#73000000',
  bgTabBar: '#FFFFFF',

  // Header 渐变
  headerGradientTop: '#000000',
  headerGradientBottom: '#000000',

  // 文字
  textTitle: '#000000',
  textBody: '#1A1A1A',
  textSub: '#555555',
  textHint: '#777777',
  textWhite: '#FFFFFF',
  textWhiteSub: '#BBBBBB',

  // 边框 & 分割线
  divider: '#E5E5E5',
  border: '#D5D5D5',
  borderLight: '#EBEBEB',

  // 传感器配色
  colorTemp: '#E6391E',
  colorHumidity: '#0052D9',
  colorCo2: '#7B2D8E',
  colorLight: '#E67300',
  colorSoil: '#00A83C',
  colorPh: '#C4006D',

  // 圆角
  radiusSm: 2,
  radiusMd: 4,
  radiusLg: 6,
  radiusXl: 8,
  radiusFull: 9999,

  // 阴影（极简：细边框为主，辅以极淡投影增强层次）
  shadowCardRadius: 2,
  shadowCardColor: '#14000000',
  shadowCardOffsetY: 1,
  shadowHoverRadius: 0,
  shadowHoverColor: '#00000000',
  shadowHoverOffsetY: 0,
  shadowHeaderRadius: 4,
  shadowHeaderColor: '#33000000',
  shadowHeaderOffsetY: 2,
  shadowFloatRadius: 8,
  shadowFloatColor: '#26000000',
  shadowFloatOffsetY: 4,

  // 毛玻璃
  blurAmount: 0,

  // 文字颜色
  textOnPrimary: '#FFFFFF',
  textOnDanger: '#FFFFFF',
  textOnWarning: '#000000',

  // 字号
  fontXs: 10,
  fontSm: 13,
  fontMd: 15,
  fontLg: 18,
  fontXl: 22,
  fontXxl: 34,

  // 动画
  animationEnabled: false,
  animationDuration: 0,
};
