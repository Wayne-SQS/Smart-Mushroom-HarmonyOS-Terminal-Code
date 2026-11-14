import { LayoutConstants, AdaptiveUtils, BreakpointConstants } from 'common-base';
import { ThemeManager } from '../theme/ThemeManager';
import { ThemeTokens } from '../theme/ThemeTokens';

/**
 * 统一页面标题栏
 *
 * 结构：安全区上边距（8）+ 返回 / 标题 / 副标题 / 右侧操作
 * 视觉：深色渐变底（headerGradientTop → headerGradientBottom），白字高对比，
 *       与 Dashboard 首屏保持同一层级语言。
 *
 * 约束：
 * - 高度固定 LayoutConstants.HEADER_HEIGHT（56）+ 8vp 顶部内边距
 * - 右侧操作按钮 32 高、8 圆角；不传 actionLabel 时不渲染
 * - 不使用 emoji，返回用「←」几何字符
 */
@Component
export struct PageHeader {
  @Prop title: string = '';
  @Prop subtitle: string = '';
  @Prop showBack: boolean = false;
  @Prop backLabel: string = '返回';
  @Prop actionLabel: string = '';
  onAction: () => void = () => {};
  onBack: () => void = () => {};
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointConstants.SM;

  private t(): ThemeTokens {
    return ThemeManager.getInstance().getTokens();
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column()
        .width('100%')
        .height(LayoutConstants.HEADER_HEIGHT + LayoutConstants.SPACE_SM)
        .linearGradient({
          angle: 135,
          colors: [[this.t().headerGradientTop, 0.0], [this.t().headerGradientBottom, 1.0]]
        })

      Row() {
        if (this.showBack) {
          Row({ space: LayoutConstants.SPACE_XS }) {
            Text('←')
              .fontSize(this.t().fontLg)
              .fontColor(this.t().textWhite)
            Text(this.backLabel)
              .fontSize(this.t().fontSm)
              .fontColor(this.t().textWhite)
          }
          .height(LayoutConstants.BUTTON_HEIGHT_SMALL)
          .padding({ right: LayoutConstants.SPACE_MD })
          .onClick(() => {
            this.onBack();
          })
        }

        Column({ space: LayoutConstants.SPACE_XS }) {
          Text(this.title)
            .fontSize(AdaptiveUtils.getTitleFontSize(this.currentBreakpoint))
            .fontColor(this.t().textWhite)
            .fontWeight(this.t().fontWeightTitle)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          if (this.subtitle.length > 0) {
            Text(this.subtitle)
              .fontSize(this.t().fontSm)
              .fontColor(this.t().textWhiteSub)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
        .layoutWeight(1)
        .alignItems(this.showBack ? HorizontalAlign.Center : HorizontalAlign.Start)

        if (this.actionLabel.length > 0) {
          Text(this.actionLabel)
            .fontSize(this.t().fontSm)
            .fontColor(this.t().textWhite)
            .height(LayoutConstants.BUTTON_HEIGHT_SMALL)
            .padding({ left: LayoutConstants.SPACE_MD, right: LayoutConstants.SPACE_MD })
            .border({
              width: LayoutConstants.CARD_BORDER_WIDTH,
              color: this.t().textWhiteSub,
              radius: LayoutConstants.RADIUS_SM
            })
            .textAlign(TextAlign.Center)
            .onClick(() => {
              this.onAction();
            })
        }
      }
      .width('100%')
      .height(LayoutConstants.HEADER_HEIGHT + LayoutConstants.SPACE_SM)
      .padding({
        left: AdaptiveUtils.getPagePadding(this.currentBreakpoint),
        right: AdaptiveUtils.getPagePadding(this.currentBreakpoint),
        top: LayoutConstants.SPACE_SM
      })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .height(LayoutConstants.HEADER_HEIGHT + LayoutConstants.SPACE_SM)
  }
}
