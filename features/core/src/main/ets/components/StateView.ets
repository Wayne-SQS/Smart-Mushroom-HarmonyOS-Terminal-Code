import { LayoutConstants } from 'common-base';
import { ThemeManager } from '../theme/ThemeManager';
import { ThemeTokens } from '../theme/ThemeTokens';

/**
 * 数据页三态公共组件：加载中 / 空数据 / 失败重试
 *
 * 设计约束：
 * - 只使用 ThemeTokens 颜色与 LayoutConstants 尺寸，零硬编码色值
 * - 失败态必须提供可点击的「重试」次按钮（36 高描边），不允许静默降级
 * - 文案朴素，不使用 emoji
 *
 * 用法：
 *   StateView({ mode: 'loading', title: '正在加载环境数据' })
 *   StateView({ mode: 'error', title: '数据加载失败', message: this.errorMsg,
 *               onRetry: () => { this.reload(); } })
 */
@Component
export struct StateView {
  /** 三态模式 */
  @Prop mode: string = 'loading';
  /** 主标题 */
  @Prop title: string = '';
  /** 补充说明（失败原因 / 空态提示） */
  @Prop message: string = '';
  /** 重试按钮文案 */
  @Prop retryLabel: string = '重试';
  /** 重试回调（仅 error 态生效） */
  onRetry: () => void = () => {};
  /** 垂直内边距 */
  @Prop verticalPadding: number = 32;

  private t(): ThemeTokens {
    return ThemeManager.getInstance().getTokens();
  }

  build() {
    Column({ space: LayoutConstants.SPACE_SM }) {
      if (this.mode === 'loading') {
        LoadingProgress()
          .width(28)
          .height(28)
          .color(this.t().primary)
      } else {
        // 状态指示条：失败用危险色，空态用中性色，替代图标避免 emoji
        Row()
          .width(28)
          .height(3)
          .borderRadius(2)
          .backgroundColor(this.mode === 'error' ? this.t().danger : this.t().border)
      }

      Text(this.title.length > 0 ? this.title : (this.mode === 'loading' ? '正在加载' : '暂无数据'))
        .fontSize(this.t().fontMd)
        .fontColor(this.t().textTitle)
        .fontWeight(this.t().fontWeightTitle)
        .textAlign(TextAlign.Center)

      if (this.message.length > 0) {
        Text(this.message)
          .fontSize(this.t().fontSm)
          .fontColor(this.t().textSub)
          .textAlign(TextAlign.Center)
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .padding({ left: LayoutConstants.CARD_RADIUS, right: LayoutConstants.CARD_RADIUS })
      }

      if (this.mode === 'error') {
        Button(this.retryLabel)
          .height(LayoutConstants.BUTTON_HEIGHT_SECONDARY)
          .fontSize(this.t().fontSm)
          .fontWeight(this.t().fontWeightButton)
          .fontColor(this.t().primary)
          .backgroundColor(Color.Transparent)
          .border({
            width: LayoutConstants.CARD_BORDER_WIDTH,
            color: this.t().primary,
            radius: LayoutConstants.CARD_RADIUS
          })
          .padding({ left: LayoutConstants.SPACE_XL, right: LayoutConstants.SPACE_XL })
          .margin({ top: LayoutConstants.SPACE_XS })
          .onClick(() => {
            this.onRetry();
          })
      }
    }
    .width('100%')
    .padding({ top: this.verticalPadding, bottom: this.verticalPadding })
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}
