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

  // 品牌（接菌菇棕点缀：primary 改为深棕，白字对比度 5.8:1 达 AA；
  //   保持黑白主调——仅按钮/选中态用棕色，背景仍纯黑纯白）
  primary: '#8B5A2B',      // 深菌菇棕（按钮底，达 AA 对比度）
  primaryLight: '#C68642', // 浅菌菇棕（hover/进度底）
  primaryDark: '#5C3A1E',  // 更深棕（按下态）
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
  bgCardLight: '#E8E8E8',
  bgOverlay: '#73000000',
  bgTabBar: '#FFFFFF',

  // Header 渐变（保持纯黑，保证极致对比）
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
  borderLight: '#D5D5D5',

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
  // 按压态：极淡黑投影，保持极简风
  shadowPressedRadius: 1,
  shadowPressedColor: '#28000000',
  shadowPressedOffsetY: 0,
  // 禁用态：无投影
  shadowDisabledRadius: 0,
  shadowDisabledColor: '#00000000',
  shadowDisabledOffsetY: 0,

  // 毛玻璃
  blurAmount: 0,

  // 文字颜色
  textOnPrimary: '#FFFFFF',
  textOnDanger: '#FFFFFF',
  textOnWarning: '#000000',

  // 禁用态（中性灰，与黑白主调一致）
  disabled: '#D0D0D0',
  disabledText: '#888888',
  disabledBorder: '#C8C8C8',

  // 字号
  fontXs: 10,
  fontSm: 13,
  fontMd: 15,
  fontLg: 18,
  fontXl: 22,
  fontXxl: 34,

  // 字重（黑白主题强调对比，标题用 SemiBold 600）
  fontWeightTitle: 600,    // SemiBold
  fontWeightBody: 400,     // Regular
  fontWeightHint: 300,     // Light
  fontWeightButton: 600,   // SemiBold
  fontWeightMono: 700,     // Bold（数值强调）

  // 字体族（传感器数值专用等宽）
  fontMonoFamily: 'HarmonyOS Sans Mono',

  // 卡片质感（顶部 1px 高光，黑白主题用极淡灰）
  cardHighlightColor: '#FAFAFA',
  cardHighlightWidth: 1,

  // 动画
  animationEnabled: false,
  animationDuration: 0,
};