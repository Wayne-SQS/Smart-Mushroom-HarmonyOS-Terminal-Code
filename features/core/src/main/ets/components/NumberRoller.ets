import { ThemeManager } from '../theme/ThemeManager';
import { ThemeTokens } from '../theme/ThemeTokens';

/**
 * 数字滚动组件
 *
 * 通用数值滚动展示：value 变化时用 animateTo 从旧值线性插值到新值，
 * 平滑过渡。适用于传感器数值、概览统计等需要数字跳动的场景。
 *
 * 主题适配：
 *   - 雾透主题（animationEnabled=true）：执行 tween 滚动动画。
 *   - 黑白主题（animationEnabled=false）：直接跳变，不滚动。
 *   - 字体族用 token.fontMonoFamily（等宽字体，避免数字跳动），字重用 fontWeightMono。
 *
 * 用法：
 *   NumberRoller({ value: 23.5, fontSize: 48, fontColor: this.t().textTitle, decimals: 1 })
 */
@Component
export struct NumberRoller {
  /** 目标数值 */
  @Prop @Watch('onValueChange') value: number = 0;
  /** 字号（vp） */
  @Prop fontSize: number = 16;
  /** 字色（由父级从 token 传入，零硬编码） */
  @Prop fontColor: string = '#000000';
  /** 滚动时长（ms），默认 400 */
  @Prop duration: number = 400;
  /** 小数位数，默认 1 */
  @Prop decimals: number = 1;

  /** 当前显示值，由 animateTo 逐帧插值驱动 */
  @State currentValue: number = 0;

  /** 主题 token 快捷取值 */
  private t(): ThemeTokens {
    return ThemeManager.getInstance().getTokens();
  }

  aboutToAppear(): void {
    // 初始化为传入值，避免首次出现一次从 0 滚到目标值的动画
    this.currentValue = this.value;
  }

  /** value 变化时触发：动画主题 tween 滚动；静态主题直接跳变 */
  onValueChange(): void {
    if (!this.t().animationEnabled) {
      // 黑白主题：跳变不滚动
      this.currentValue = this.value;
      return;
    }
    // 雾透主题：animateTo 驱动 currentValue 从旧值线性插值到新值
    animateTo({
      duration: this.duration,
      curve: Curve.Linear,
      iterations: 1,
    }, () => {
      this.currentValue = this.value;
    });
  }

  /** 按小数位格式化当前显示值 */
  private formatValue(v: number): string {
    return v.toFixed(this.decimals);
  }

  build() {
    Text(this.formatValue(this.currentValue))
      .fontSize(this.fontSize)
      .fontColor(this.fontColor)
      .fontFamily(this.t().fontMonoFamily)
      .fontWeight(this.t().fontWeightMono)
  }
}
