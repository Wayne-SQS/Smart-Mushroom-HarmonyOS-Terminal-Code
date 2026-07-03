import { ThemeManager } from '../theme/ThemeManager';
import { ThemeTokens } from '../theme/ThemeTokens';

/**
 * 骨架屏卡片组件
 *
 * 加载占位骨架：3 个灰色圆角块模拟卡片结构（标题条 + 数值条 + 辅助条），
 * 配合从左到右的 shimmer 扫光动画，提示数据正在加载。
 *
 * 主题适配：
 *   - 雾透主题（animationEnabled=true）：执行 shimmer 扫光循环。
 *   - 黑白主题（animationEnabled=false）：仅静态骨架，不扫光。
 *   - 背景色用 token.bgCardLight，骨架块用 token.divider，圆角用 token.radiusSm。
 *   - 扫光色 #FFFFFF（6 位 hex，符合 frosted 主题规范），通过 opacity 0.4 实现半透明。
 *
 * 用法：
 *   SkeletonCard({ cardWidth: '100%', cardHeight: 80 })
 */
@Component
export struct SkeletonCard {
  /** 卡片宽度（string），默认 '100%'（避免与基类 width()/height() 方法同名） */
  @Prop cardWidth: string = '100%';
  /** 卡片高度（vp），默认 80 */
  @Prop cardHeight: number = 80;

  /**
   * 扫光横向位移百分比（相对扫光块自身宽度）。
   * -100 = 完全在卡片左侧外，200 = 完全在卡片右侧外。
   * 由 animateTo 驱动从 -100 到 200 做线性循环。
   */
  @State shimmerX: number = -100;

  /** 主题 token 快捷取值 */
  private t(): ThemeTokens {
    return ThemeManager.getInstance().getTokens();
  }

  aboutToAppear(): void {
    if (this.t().animationEnabled) {
      // 雾透主题：启动 shimmer 扫光循环
      this.startShimmer();
    }
  }

  /** 启动扫光无限循环动画（白色半透明矩形从左到右移动） */
  private startShimmer(): void {
    animateTo({
      duration: 1500,
      curve: Curve.Linear,
      iterations: -1, // 无限循环
    }, () => {
      this.shimmerX = 200;
    });
  }

  build() {
    Stack() {
      // 骨架结构层：3 个灰色圆角块
      Column() {
        // 标题条：40% 宽 × 12 高
        Row()
          .width('40%')
          .height(12)
          .backgroundColor(this.t().divider)
          .borderRadius(this.t().radiusSm)
          .margin({ bottom: 10 })

        // 数值条：60% 宽 × 20 高
        Row()
          .width('60%')
          .height(20)
          .backgroundColor(this.t().divider)
          .borderRadius(this.t().radiusSm)
          .margin({ bottom: 8 })

        // 辅助条：30% 宽 × 10 高
        Row()
          .width('30%')
          .height(10)
          .backgroundColor(this.t().divider)
          .borderRadius(this.t().radiusSm)
      }
      .width('100%')
      .height('100%')
      .padding(12)
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Center)

      // 扫光层：仅动画主题显示（黑白主题渲染静态骨架即可）
      if (this.t().animationEnabled) {
        Row()
          .width('50%')
          .height('100%')
          .backgroundColor('#FFFFFF')
          .opacity(0.4)
          .translate({ x: `${this.shimmerX}%` })
      }
    }
    .width(this.cardWidth)
    .height(this.cardHeight)
    .backgroundColor(this.t().bgCardLight)
    .borderRadius(this.t().radiusSm)
    .clip(true) // 裁剪扫光超出卡片边界的部分
  }
}
