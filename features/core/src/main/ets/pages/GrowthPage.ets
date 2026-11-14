import { BreakpointConstants, AdaptiveUtils, LayoutConstants } from 'common-base';
import { ThemeManager } from '../theme/ThemeManager';
import { ThemeTokens } from '../theme/ThemeTokens';
import { GrowthBatch } from '../model/GreenhouseModel';
import { GrowthViewModel } from '../viewmodel/GrowthViewModel';
import { StateView } from '../components/StateView';
import { PageHeader } from '../components/PageHeader';
import promptAction from '@ohos.promptAction';

/**
 * 蘑菇生长日记页面 - 主题驱动
 *
 * 数据真实性：批次为本地台账（isDemoData），页面显式标注来源；
 * 累计产量无数据源时显示 '--'，不编造合计。
 */

@Component
export struct GrowthPage {
  @StorageLink('themeName') themeName: string = 'frosted';
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointConstants.SM;

  @State batches: GrowthBatch[] = [];
  @State totalYield: string = '--';
  @State currentBatches: number = 0;
  @State harvestedBatches: number = 0;
  @State loading: boolean = true;

  private viewModel: GrowthViewModel = new GrowthViewModel();
  private disposed: boolean = false;

  t(): ThemeTokens {
    return ThemeManager.getInstance().getTokens();
  }

  aboutToAppear(): void {
    this.disposed = false;
    this.loadBatches();
  }

  aboutToDisappear(): void {
    this.disposed = true;
  }

  private async loadBatches(): Promise<void> {
    this.loading = true;
    await this.viewModel.loadData();
    if (this.disposed) {
      return;
    }
    this.loading = false;
    this.batches = [...this.viewModel.batches];
    this.totalYield = this.viewModel.totalYield;
    this.currentBatches = this.viewModel.currentBatches;
    this.harvestedBatches = this.viewModel.harvestedBatches;
  }

  private getPagePadding(): number {
    return AdaptiveUtils.getPagePadding(this.currentBreakpoint);
  }

  private getCardGap(): number {
    return AdaptiveUtils.getCardGap(this.currentBreakpoint);
  }

  private getBatchSpan(): number {
    const cols = AdaptiveUtils.getCardColumns(this.currentBreakpoint);
    return Math.floor(12 / cols);
  }

  build() {
    Column() {
      PageHeader({
        title: '生长日记',
        subtitle: `在培 ${this.currentBatches} · 已采收 ${this.harvestedBatches}`,
        actionLabel: '新建',
        onAction: () => {
          this.onCreateBatch();
        }
      })
      this.StatsCard()
      if (this.loading) {
        StateView({ mode: 'loading', title: '正在读取批次' })
      } else {
        this.DataSourceNote()
        this.BatchList()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.t().bgPage)
  }

  /** 数据来源说明 */
  @Builder
  DataSourceNote() {
    Text('批次数据为本地台账，暂未与云端同步')
      .fontSize(this.t().fontXs)
      .fontColor(this.t().textHint)
      .width('100%')
      .padding({ left: this.getPagePadding(), right: this.getPagePadding(), top: LayoutConstants.SPACE_SM })
  }

  @Builder
  StatsCard() {
    Row() {
      Column() {
        Text(this.totalYield)
          .fontSize(this.t().fontXl)
          .fontColor(this.t().accent)
          .fontWeight(FontWeight.Bold)
        Text('累计产量')
          .fontSize(this.t().fontSm)
          .fontColor(this.t().textSub)
          .margin({ top: 2 })
      }
      .layoutWeight(1).alignItems(HorizontalAlign.Center)

      Divider().vertical(true).height(32).color(this.t().borderLight)

      Column() {
        Text(this.currentBatches.toString())
          .fontSize(this.t().fontXl)
          .fontColor(this.t().primary)
          .fontWeight(FontWeight.Bold)
        Text('在培批次')
          .fontSize(this.t().fontSm)
          .fontColor(this.t().textSub)
          .margin({ top: 2 })
      }
      .layoutWeight(1).alignItems(HorizontalAlign.Center)

      Divider().vertical(true).height(32).color(this.t().borderLight)

      Column() {
        Text(this.harvestedBatches.toString())
          .fontSize(this.t().fontXl)
          .fontColor(this.t().info)
          .fontWeight(FontWeight.Bold)
        Text('已采收')
          .fontSize(this.t().fontSm)
          .fontColor(this.t().textSub)
          .margin({ top: 2 })
      }
      .layoutWeight(1).alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .padding({ top: 16, bottom: 16 })
    .backgroundColor(this.t().bgCard)
    .backdropBlur(this.t().blurAmount)
    .border({ width: 1, color: this.t().border })
    .borderRadius(this.t().radiusLg)
    .margin({ top: LayoutConstants.SPACE_MD, left: this.getPagePadding(), right: this.getPagePadding() })
    .shadow({
      radius: this.t().shadowCardRadius,
      color: this.t().shadowCardColor,
      offsetX: 0,
      offsetY: this.t().shadowCardOffsetY
    })
  }

  // ==================== 批次列表（GridRow 五档断点） ====================
  @Builder
  BatchList() {
    Scroll() {
      Column() {
        Text('在培批次')
          .fontSize(this.t().fontLg)
          .fontColor(this.t().textTitle)
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .margin({ bottom: LayoutConstants.SPACE_MD })

        if (this.batches.length === 0) {
          StateView({
            mode: 'empty',
            title: '暂无批次',
            message: '建立批次后可在此查看生长进度',
            verticalPadding: 32
          })
        } else {
          GridRow({
            gutter: { x: this.getCardGap(), y: this.getCardGap() }
          }) {
            ForEach(this.batches, (item: GrowthBatch) => {
              GridCol({ span: this.getBatchSpan() }) {
                this.BatchCard(item)
              }
            })
          }
          .width('100%')
        }

        Blank().height(80)
      }
      .width('100%')
      .padding({ left: this.getPagePadding(), right: this.getPagePadding(), top: LayoutConstants.SPACE_MD })
    }
    .layoutWeight(1)
    .scrollBar(BarState.Auto)
  }

  @Builder
  BatchCard(item: GrowthBatch) {
    Column() {
      Row() {
        Text(item.mushroomType)
          .fontSize(this.t().fontLg)
          .fontColor(this.t().textTitle)
          .fontWeight(FontWeight.Bold)
        Blank()
        Text(item.status)
          .fontSize(this.t().fontXs)
          .fontColor(this.getStatusColor(item.status))
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .backgroundColor(this.t().bgCardLight)
          .borderRadius(4)
      }
      .width('100%')

      Row() {
        Column() {
          Text(`第${item.day}天`)
            .fontSize(this.t().fontMd)
            .fontColor(this.t().textBody)
            .fontWeight(FontWeight.Medium)
          Text(`开始: ${item.startDate}`)
            .fontSize(this.t().fontXs)
            .fontColor(this.t().textSub)
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)

        Blank()

        Column() {
          if (item.yield !== '-') {
            Text(item.yield)
              .fontSize(this.t().fontLg)
              .fontColor(this.t().success)
              .fontWeight(FontWeight.Bold)
            Text('产量')
              .fontSize(this.t().fontXs)
              .fontColor(this.t().textSub)
          } else {
            Text(this.getExpectedHarvest(item.day))
              .fontSize(this.t().fontSm)
              .fontColor(this.t().warning)
            Text('预计采收')
              .fontSize(this.t().fontXs)
              .fontColor(this.t().textSub)
              .margin({ top: 2 })
          }
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')
      .margin({ top: 10 })

      // 生长进度条（day 非法时按 0 处理，避免 NaN 参与 layoutWeight）
      Row() {
        Column()
          .layoutWeight(this.getProgress(item.day))
          .height(4)
          .backgroundColor(this.getStatusColor(item.status))
          .borderRadius(2)
        Column()
          .layoutWeight(1 - this.getProgress(item.day))
          .height(4)
          .backgroundColor(this.t().borderLight)
          .borderRadius(2)
      }
      .width('100%')
      .margin({ top: 10 })
    }
    .width('100%')
    .padding(LayoutConstants.SPACE_LG)
    .backgroundColor(this.t().bgCard)
    .backdropBlur(this.t().blurAmount)
    .border({ width: LayoutConstants.CARD_BORDER_WIDTH, color: this.t().border })
    .borderRadius(this.t().radiusMd)
    .shadow({
      radius: this.t().shadowCardRadius,
      color: this.t().shadowCardColor,
      offsetX: 0,
      offsetY: this.t().shadowCardOffsetY
    })
  }

  /** 生长进度（0~1），非法天数按 0 处理 */
  private getProgress(day: number): number {
    if (!Number.isFinite(day) || day <= 0) {
      return 0.01;
    }
    return Math.min(Math.max(day / 30, 0.01), 0.99);
  }

  private getStatusColor(status: string): string {
    if (status === '采收中') { return this.t().success; }
    if (status === '原基形成期') { return this.t().warning; }
    return this.t().info;
  }

  private getExpectedHarvest(currentDay: number): string {
    if (!Number.isFinite(currentDay)) { return '--'; }
    const remaining = 30 - currentDay;
    if (remaining <= 0) { return '可采收'; }
    return `${remaining}天后`;
  }

  /** 新建批次：功能未接入，明确告知而不是静默无响应 */
  private onCreateBatch(): void {
    promptAction.showToast({
      message: '新建批次功能尚未接入',
      duration: 2000
    });
  }
}
