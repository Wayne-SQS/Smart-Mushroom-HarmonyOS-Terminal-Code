/**
 * 完整设计令牌接口
 *
 * 设计原则：每新增一个颜色或数值，必须同时在两个主题中定义，
 * 切换时原子替换，不会出现混合状态。
 *
 * 字号说明：本接口中的 fontXs~fontXxl 用于「小字号场景」
 * （标题/正文/辅助文字/单位/标签等）。传感器数值、概览数字、图表数据等
 * 「大字号场景」不要用这里的 fontXxl，应使用 AdaptiveUtils.getXxxFontSize(breakpoint)
 * 断点自适应，避免手机端字号过大。
 *
 * 颜色格式约定：所有半透明色统一使用 8 位 hex（#RRGGBBAA），
 * 不使用 rgba()。ArkUI 对 rgba() 的解析在部分属性和 SDK 版本下不稳定。
 */
export interface ThemeTokens {
  /** 主题名（'frosted' | 'contrast'） */
  readonly name: string;

  // ==================== 品牌 ====================
  readonly primary: string;
  readonly primaryLight: string;
  readonly primaryDark: string;
  readonly accent: string;
  readonly accentLight: string;

  // ==================== 功能色 ====================
  readonly success: string;
  readonly warning: string;
  readonly danger: string;
  readonly info: string;
  readonly purple: string;

  // ==================== 背景 ====================
  readonly bgPage: string;
  readonly bgCard: string;
  readonly bgCardLight: string;
  readonly bgOverlay: string;
  readonly bgTabBar: string;

  // ==================== Header 渐变（深色底，保证白字对比度） ====================
  readonly headerGradientTop: string;
  readonly headerGradientBottom: string;

  // ==================== 文字 ====================
  readonly textTitle: string;
  readonly textBody: string;
  readonly textSub: string;
  readonly textHint: string;
  readonly textWhite: string;
  readonly textWhiteSub: string;

  // ==================== 边框 ====================
  readonly divider: string;
  readonly border: string;
  readonly borderLight: string;

  // ==================== 传感器配色（仅供装饰，严禁作为文字色） ====================
  readonly colorTemp: string;
  readonly colorHumidity: string;
  readonly colorCo2: string;
  readonly colorLight: string;
  readonly colorSoil: string;
  readonly colorPh: string;

  // ==================== 圆角（vp） ====================
  readonly radiusSm: number;
  readonly radiusMd: number;
  readonly radiusLg: number;
  readonly radiusXl: number;
  readonly radiusFull: number;

  // ==================== 阴影 ====================
  readonly shadowCardRadius: number;
  readonly shadowCardColor: string;
  readonly shadowCardOffsetY: number;
  readonly shadowHoverRadius: number;
  readonly shadowHoverColor: string;
  readonly shadowHoverOffsetY: number;
  readonly shadowHeaderRadius: number;
  readonly shadowHeaderColor: string;
  readonly shadowHeaderOffsetY: number;
  readonly shadowFloatRadius: number;
  readonly shadowFloatColor: string;
  readonly shadowFloatOffsetY: number;
  /** 按压态阴影（卡片被按下时切换） */
  readonly shadowPressedRadius: number;
  readonly shadowPressedColor: string;
  readonly shadowPressedOffsetY: number;
  /** 禁用态阴影（按钮/卡片禁用时切换） */
  readonly shadowDisabledRadius: number;
  readonly shadowDisabledColor: string;
  readonly shadowDisabledOffsetY: number;

  // ==================== 毛玻璃 ====================
  /** backdropBlur 强度（黑白主题=0，条件化设置避免无效渲染） */
  readonly blurAmount: number;

  // ==================== 文字颜色（彩色底上的文字） ====================
  readonly textOnPrimary: string;
  readonly textOnDanger: string;
  readonly textOnWarning: string;

  // ==================== 禁用态 ====================
  readonly disabled: string;        // 禁用背景
  readonly disabledText: string;    // 禁用文字
  readonly disabledBorder: string;  // 禁用边框

  // ==================== 字号（小字号场景；大字号场景用 AdaptiveUtils 断点自适应） ====================
  readonly fontXs: number;
  readonly fontSm: number;
  readonly fontMd: number;
  readonly fontLg: number;
  readonly fontXl: number;
  readonly fontXxl: number;

  // ==================== 字重 ====================
  readonly fontWeightTitle: number;   // 标题 Medium 500
  readonly fontWeightBody: number;    // 正文 Regular 400
  readonly fontWeightHint: number;    // 提示 Light 300
  readonly fontWeightButton: number;  // 按钮 Medium 500
  readonly fontWeightMono: number;    // 数值 Bold 700

  // ==================== 字体族 ====================
  /** 等宽字体族名（传感器数值专用，对齐整齐不跳动） */
  readonly fontMonoFamily: string;

  // ==================== 卡片质感 ====================
  /** 卡片顶部 1px 高光描边色（极淡，增强立体层次） */
  readonly cardHighlightColor: string;
  /** 高光描边宽度（vp） */
  readonly cardHighlightWidth: number;

  // ==================== 动画 ====================
  readonly animationEnabled: boolean;
  readonly animationDuration: number;
}
