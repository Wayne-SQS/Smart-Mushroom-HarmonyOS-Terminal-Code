/**
 * 主题 A — 雾透玻璃 � theme_frosted（蘑菇棕点缀版）
 *
 * 设计原则：
 *   1. 棕色只作「点缀」（Header 渐变 / primary / 传感器色），背景走中性白，
 *      避免大面积泛黄。
 *   2. 全部使用 6 位 hex（#RRGGBB），禁用 8 位 hex ——
 *      API 24 模拟器对 #RRGGBBAA 解析不稳定，会导致颜色发黄/失效（见 harmony-kb.md 7.1）。
 *   3. 深色模式由 EntryAbility 锁定 COLOR_MODE_LIGHT，避免系统反转 token（见 harmony-kb.md 7.2）。
 *
 * 配色与应用图标（MUSHROOM_CAP #B07A3E）及 LoginPage 蘑菇插画统一。
 */
import { ThemeTokens } from './ThemeTokens';

export const FROSTED_THEME: ThemeTokens = {
  name: 'frosted',

  // 品牌（菌菇棕系，与应用图标 #B07A3E 同系）— 仅作点缀，不作背景
  primary: '#C68642',      // 菌菇棕（主按钮、选中态、装饰）
  primaryLight: '#D4A06A', // 中菌菇棕（hover、进度条底色、图表条）— 比原来 #E0B58A 更深更饱和
  primaryDark: '#8B5A2B',  // 深菌菇（按下态，白字对比度 5.8:1 达标）
  accent: '#7A9E6E',       // 状态绿（蘑菇+植物，强调色）
  accentLight: '#C9DBBF', // 浅草绿（选中背景）

  // 功能色（柔和土系，均为 6 位 hex）
  success: '#7A9E6E',      // 状态绿（正常）
  warning: '#E6A23C',      // 琥珀（预警）
  danger: '#E06C75',       // 警告红（蘑菇配色）
  info: '#6B8E9E',         // 雾蓝（信息提示）
  purple: '#A88BA8',       // 灰紫（数据可视化）

  // 背景（中性白系，避免大面积泛黄；均为不透明 6 位 hex）
  bgPage: '#F5F6F7',       // 暖灰白（接近纯白，微暖不黄）
  bgCard: '#FFFFFF',       // 纯白卡片
  bgCardLight: '#E8E8E8', // 浅灰（次级卡片/非选中按钮背景）— 比原来 #F8F9FA 明显加深，确保可见
  bgOverlay: '#E8E8E8',    // 弹窗遮罩
  bgTabBar: '#FFFFFF',     // 底部导航

  // Header 渐变（深棕底，保证白字对比度 ≥ 7:1；棕色集中在此承担蘑菇主题感）
  headerGradientTop: '#5C3A1E',    // 深菌菇棕
  headerGradientBottom: '#3D2812', // 更深棕（底部回深）

  // 文字（中性深灰，避免棕系文字加重泛黄感；对比度均达 WCAG AA）
  textTitle: '#2A2A2A',    // 近黑（标题，≈12:1 on 白卡）
  textBody: '#3A3A3A',     // 深灰（正文，≈9:1）
  textSub: '#6A6A6A',      // 中灰（辅助，≈5.6:1 达标AA）
  textHint: '#9A9A9A',     // 浅灰（占位/提示，≈3.4:1 ⚠️≥14fp）
  textWhite: '#FFFFFF',    // 纯白（深色底文字）
  textWhiteSub: '#F0F0F0', // 浅灰白（深色底辅助，≈11:1）

  // 边框 & 分割线（中性灰，避免暖色边框叠加泛黄）
  divider: '#E8E8E8',       // 中性分割线
  border: '#DDDDDD',        // 中性边框
  borderLight: '#DCDCDC',   // 浅灰边 — 比原来 #EFEFEF 加深以便看清按钮边框

  // 传感器配色（仅供装饰，严禁作为文字色；均为 6 位 hex 土系）
  colorTemp: '#E8A87C',     // 暖陶（温度）
  colorHumidity: '#7EB5D6', // 雾蓝（湿度）
  colorCo2: '#A88BA8',      // 灰紫（CO2）
  colorLight: '#F0D585',    // 暖黄（光照）
  colorSoil: '#7A9E6E',     // 草绿（土壤）
  colorPh: '#D88AA0',       // 粉紫（pH）

  // 圆角（保持大圆角，圆润亲和）
  radiusSm: 12,
  radiusMd: 16,
  radiusLg: 20,
  radiusXl: 28,
  radiusFull: 9999,

  // 阴影（中性灰投影，均为 6 位 hex；仅 Header 阴影用棕色强化蘑菇感）
  shadowCardRadius: 12,
  shadowCardColor: '#C8C8C8',   // 中性灰投影
  shadowCardOffsetY: 4,
  shadowHoverRadius: 20,
  shadowHoverColor: '#BCBCBC',  // 中性灰投影
  shadowHoverOffsetY: 8,
  shadowHeaderRadius: 32,
  shadowHeaderColor: '#8B5A2B',  // 深棕 Header 投影（点缀，强化蘑菇感）
  shadowHeaderOffsetY: 6,
  shadowFloatRadius: 40,
  shadowFloatColor: '#C8C8C8',  // 中性浮层阴影
  shadowFloatOffsetY: 12,
  // 按压态：半径变小、阴影变深变近，模拟「按下凹陷」
  shadowPressedRadius: 4,
  shadowPressedColor: '#A8A8A8',
  shadowPressedOffsetY: 2,
  // 禁用态：几乎无投影，仅极淡边框暗示不可点击
  shadowDisabledRadius: 0,
  shadowDisabledColor: '#E8E8E8',
  shadowDisabledOffsetY: 0,

  // 毛玻璃（backdropBlur 强度，黑白主题=0；数值非颜色，不受 8 位 hex 限制）
  blurAmount: 16,

  // 文字颜色（彩色底上的文字）
  textOnPrimary: '#FFFFFF',  // 白字配 primaryDark 按钮底（primary 偏浅，按钮底用 primaryDark）
  textOnDanger: '#FFFFFF',    // 白字配 danger 红
  textOnWarning: '#3D2E00',  // 深棕字配琥珀底

  // 禁用态（中性灰，避免棕色加重泛黄）
  disabled: '#DDDDDD',        // 中灰背景（禁用态按钮）— 比原来 #F0F0F0 加深，更清晰可辨
  disabledText: '#999999',   // 中灰文字（禁用态）— 比原来 #BFBFBF 更深，提升可读性
  disabledBorder: '#D0D0D0', // 中灰边框 — 比原来 #E8E8E8 更明显

  // 字号（小字号场景；大字号场景用 AdaptiveUtils 断点自适应）
  fontXs: 10,
  fontSm: 13,
  fontMd: 15,
  fontLg: 18,
  fontXl: 22,
  fontXxl: 34,

  // 字重（统一管理，避免页面散落 fontWeight 数值）
  fontWeightTitle: 500,    // Medium
  fontWeightBody: 400,     // Regular
  fontWeightHint: 300,     // Light
  fontWeightButton: 500,   // Medium
  fontWeightMono: 700,     // Bold（数值强调）

  // 字体族（传感器数值专用等宽，对齐整齐不跳动）
  fontMonoFamily: 'HarmonyOS Sans Mono',

  // 卡片质感（顶部 1px 高光，6 位 hex 模拟半透明高光，避免 8 位 hex 解析风险）
  cardHighlightColor: '#FFFCF7',  // 极淡暖白（在白卡 #FFFFFF 上微弱浮现）
  cardHighlightWidth: 1,

  // 动画（雾透弹性，黑白主题关闭）
  animationEnabled: true,
  animationDuration: 400,
};
