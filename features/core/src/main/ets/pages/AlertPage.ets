import { BreakpointConstants, AdaptiveUtils, LayoutConstants, Logger } from 'common-base';
import { AlertItem } from '../model/GreenhouseModel';
import { DashboardViewModel } from '../viewmodel/DashboardViewModel';
import { AlertViewModel } from '../viewmodel/AlertViewModel';
import { ThemeManager } from '../theme/ThemeManager';
import { ThemeTokens } from '../theme/ThemeTokens';
import { StateView } from '../components/StateView';
import { PageHeader } from '../components/PageHeader';

/**
 * 告警中心页面 - 多端适配（主题驱动）
 *
 * 数据真实性：告警不再使用静态示例数组，改为从设备影子实时值派生
 * （温度/湿度/CO2/光照/土壤湿度超限才会产生告警）。
 * 请求失败时展示错误态 + 重试，绝不展示编造的告警条目。
 */

interface AlertFilter {
  readonly id: string;
  label: string;
}

@Component
export struct AlertPage {
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointConstants.SM;
  @StorageLink('themeName') themeName: string = 'frosted';

  @State alerts: AlertItem[] = [];
  @State readIds: string[] = [];
  @State currentFilter: string = 'all';
  /** 加载态 */
  @State loading: boolean = true;
  /** 失败信息（空串表示正常） */
  @State errorMsg: string = '';

  private dashboardViewModel: DashboardViewModel = new DashboardViewModel();
  private alertViewModel: AlertViewModel = new AlertViewModel();
  /** 页面已销毁标记 */
  private disposed: boolean = false;

  private filters: AlertFilter[] = [
    { id: 'all', label: '全部' },
    { id: 'unread', label: '未读' },
    { id: 'danger', label: '危险' }
  ];

  t(): ThemeTokens {
    return ThemeManager.getInstance().getTokens();
  }

  aboutToAppear(): void {
    this.disposed = false;
    this.loadAlerts();
  }

  aboutToDisappear(): void {
    this.disposed = true;
  }

  /**
   * 从设备影子加载真实传感器数据并派生告警
   */
  private async loadAlerts(): Promise<void> {
    this.loading = true;
    this.errorMsg = '';
    await this.dashboardViewModel.loadData();
    if (this.disposed) {
      return;
    }
    this.loading = false;
    if (this.dashboardViewModel.hasError()) {
      this.errorMsg = this.dashboardViewModel.errorMsg;
      Logger.warn('AlertPage', '告警数据加载失败：' + this.errorMsg);
      return;
    }
    this.alertViewModel.loadFromSensors(this.dashboardViewModel.sensors);
    this.alerts = [...this.alertViewModel.alerts];
    // 只保留仍存在的告警的已读状态
    const alive: string[] = [];
    for (let i = 0; i < this.alerts.length; i++) {
      if (this.readIds.indexOf(this.alerts[i].id) !== -1) {
        alive.push(this.alerts[i].id);
      }
    }
    this.readIds = alive;
  }

  build() {
    if (this.shouldLimitWidth()) {
      Row() {
        Blank().layoutWeight(1)
        Column() {
          this.ContentBody()
        }
        .width(this.getContentWidth())
        .height('100%')
        Blank().layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.t().bgPage)
    } else {
      Column() {
        this.ContentBody()
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.t().bgPage)
    }
  }

  @Builder
  ContentBody() {
    PageHeader({
      title: '告警中心',
      subtitle: `未读 ${this.getUnreadCount()} · 危险 ${this.getDangerCount()}`,
      showBack: true,
      backLabel: '返回',
      actionLabel: this.getUnreadCount() > 0 ? '全部已读' : '',
      onBack: () => {
        this.onBack();
      },
      onAction: () => {
        this.markAllRead();
      }
    })

    if (this.loading) {
      StateView({ mode: 'loading', title: '正在读取告警' })
    } else if (this.errorMsg.length > 0) {
      StateView({
        mode: 'error',
        title: '告警加载失败',
        message: this.errorMsg,
        retryLabel: '重新加载',
        onRetry: () => {
          this.loadAlerts();
        }
      })
    } else {
      this.StatsBar()
      this.FilterTabs()
      this.AlertList()
    }
  }

  private onBack(): void {
    try {
      const stack = AppStorage.get<NavPathStack>('navPathStack');
      if (stack) {
        stack.pop();
      }
    } catch (err) {
      Logger.warn('AlertPage', '返回失败');
    }
  }

  private shouldLimitWidth(): boolean {
    return AdaptiveUtils.getMaxContentWidth(this.currentBreakpoint) > 0;
  }

  private getContentWidth(): string {
    const max = AdaptiveUtils.getMaxContentWidth(this.currentBreakpoint);
    return max > 0 ? max.toString() : '100%';
  }

  private getPagePadding(): number {
    return AdaptiveUtils.getPagePadding(this.currentBreakpoint);
  }

  private getCardGap(): number {
    return AdaptiveUtils.getCardGap(this.currentBreakpoint);
  }

  private getAlertSpan(): number {
    const cols = AdaptiveUtils.getCardColumns(this.currentBreakpoint);
    return Math.floor(12 / cols);
  }

  // ==================== 统计条 ====================
  @Builder
  StatsBar() {
    Row() {
      this.StatMetric(this.alerts.length.toString(), '总告警数', this.t().primary)
      Divider().vertical(true).height(36).color(this.t().borderLight)
      this.StatMetric(this.getUnreadCount().toString(), '未读', this.t().danger)
      Divider().vertical(true).height(36).color(this.t().borderLight)
      this.StatMetric(this.getDangerCount().toString(), '危险', this.t().warning)
    }
    .width('100%')
    .padding({ top: 18, bottom: 18 })
    .backgroundColor(this.t().bgCard)
    .borderRadius(this.t().radiusLg)
    .shadow({
      radius: this.t().shadowCardRadius,
      color: this.t().shadowCardColor,
      offsetX: 0,
      offsetY: this.t().shadowCardOffsetY
    })
    .margin({ top: LayoutConstants.SPACE_MD, left: this.getPagePadding(), right: this.getPagePadding() })
  }

  @Builder
  StatMetric(value: string, label: string, accentColor: string) {
    Column() {
      Row()
        .width(20)
        .height(3)
        .borderRadius(2)
        .backgroundColor(accentColor)
        .margin({ bottom: LayoutConstants.SPACE_XS })
      Text(value)
        .fontSize(this.t().fontXl)
        .fontColor(this.t().textTitle)
        .fontWeight(FontWeight.Bold)
      Text(label)
        .fontSize(this.t().fontSm)
        .fontColor(this.t().textSub)
        .margin({ top: 2 })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  // ==================== 筛选 Tab ====================
  @Builder
  FilterTabs() {
    Row() {
      ForEach(this.filters, (filter: AlertFilter) => {
        Text(filter.label)
          .fontSize(this.t().fontSm)
          .fontColor(this.currentFilter === filter.id ? this.t().textOnPrimary : this.t().textSub)
          .backgroundColor(this.currentFilter === filter.id ? this.t().primary : this.t().bgCardLight)
          .padding({ left: 16, right: 16, top: 6, bottom: 6 })
          .borderRadius(this.t().radiusSm)
          .margin({ right: 8 })
          .onClick(() => { this.currentFilter = filter.id; })
      })
    }
    .width('100%')
    .padding({ left: this.getPagePadding(), right: this.getPagePadding(), top: LayoutConstants.SPACE_MD })
  }

  // ==================== 告警列表 ====================
  @Builder
  AlertList() {
    Scroll() {
      Column() {
        if (this.getFilteredAlerts().length === 0) {
          this.EmptyState()
        } else {
          GridRow({
            gutter: { x: this.getCardGap(), y: this.getCardGap() }
          }) {
            ForEach(this.getFilteredAlerts(), (item: AlertItem) => {
              GridCol({ span: this.getAlertSpan() }) {
                this.AlertCard(item)
              }
            })
          }
          .width('100%')
        }
        Blank().height(80)
      }
      .width('100%')
      .padding({
        left: this.getPagePadding(),
        right: this.getPagePadding(),
        top: LayoutConstants.SPACE_MD
      })
    }
    .layoutWeight(1)
    .scrollBar(BarState.Auto)
  }

  @Builder
  EmptyState() {
    Column() {
      Image($r('app.media.empty_no_alert'))
        .width(128)
        .height(128)
        .objectFit(ImageFit.Contain)
      Text(this.currentFilter === 'all' ? '当前无告警，环境指标均在阈值内' : '当前筛选条件下暂无告警')
        .fontSize(this.t().fontMd)
        .fontColor(this.t().textSub)
        .margin({ top: 12 })
    }
    .width('100%')
    .padding({ top: 60, bottom: 60 })
    .alignItems(HorizontalAlign.Center)
  }

  // ==================== 告警卡片（彩色左侧竖线） ====================
  @Builder
  AlertCard(item: AlertItem) {
    Row() {
      // 等级色条（装饰，不用做文字色）
      Column()
        .width(4)
        .height(64)
        .backgroundColor(this.getLevelColor(item.level))
        .borderRadius(2)

      Column() {
        Row() {
          Text(this.getLevelText(item.level))
            .fontSize(this.t().fontXs)
            .fontColor(this.getLevelColor(item.level))
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .backgroundColor(this.t().bgCardLight)
            .borderRadius(4)

          Blank()

          if (this.isUnread(item.id)) {
            Row() {
              Circle({ width: 6, height: 6 })
                .fill(this.t().danger)
              Text('未读')
                .fontSize(this.t().fontXs)
                .fontColor(this.t().danger)
                .margin({ left: 4 })
            }
          } else {
            Text('已读')
              .fontSize(this.t().fontXs)
              .fontColor(this.t().textSub)
          }
        }
        .width('100%')

        Text(item.message)
          .fontSize(this.t().fontMd)
          .fontColor(this.t().textTitle)
          .fontWeight(FontWeight.Medium)
          .margin({ top: 8 })
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row() {
          Text(item.device)
            .fontSize(this.t().fontXs)
            .fontColor(this.t().textSub)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
          Text(item.time)
            .fontSize(this.t().fontXs)
            .fontColor(this.t().textSub)
            .margin({ left: 8 })
        }
        .width('100%')
        .margin({ top: 6 })
      }
      .layoutWeight(1)
      .margin({ left: 12 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(14)
    .backgroundColor(this.t().bgCard)
    .backdropBlur(this.t().blurAmount)
    .border({ width: 1, color: this.t().border })
    .borderRadius(this.t().radiusMd)
    .shadow({
      radius: this.t().shadowCardRadius,
      color: this.t().shadowCardColor,
      offsetX: 0,
      offsetY: this.t().shadowCardOffsetY
    })
    .onClick(() => { this.markRead(item.id); })
  }

  // ==================== 私有方法 ====================
  private isUnread(id: string): boolean {
    return this.readIds.indexOf(id) === -1;
  }

  private getFilteredAlerts(): AlertItem[] {
    if (this.currentFilter === 'all') { return this.alerts; }
    if (this.currentFilter === 'unread') {
      return this.alerts.filter((item: AlertItem) => this.isUnread(item.id));
    }
    if (this.currentFilter === 'danger') {
      return this.alerts.filter((item: AlertItem) => item.level === 1);
    }
    return this.alerts;
  }

  private markRead(id: string): void {
    if (this.readIds.indexOf(id) === -1) {
      this.readIds = [...this.readIds, id];
    }
  }

  private markAllRead(): void {
    const newReadIds: string[] = [...this.readIds];
    this.alerts.forEach((item: AlertItem) => {
      if (newReadIds.indexOf(item.id) === -1) { newReadIds.push(item.id); }
    });
    this.readIds = newReadIds;
  }

  private getUnreadCount(): number {
    let count: number = 0;
    this.alerts.forEach((item: AlertItem) => {
      if (this.isUnread(item.id)) { count = count + 1; }
    });
    return count;
  }

  private getDangerCount(): number {
    let count: number = 0;
    this.alerts.forEach((item: AlertItem) => {
      if (item.level === 1) { count = count + 1; }
    });
    return count;
  }

  private getLevelColor(level: number): string {
    return level === 1 ? this.t().danger : this.t().warning;
  }

  private getLevelText(level: number): string {
    return level === 1 ? '危险' : '警告';
  }
}
