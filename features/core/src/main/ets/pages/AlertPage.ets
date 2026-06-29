import { BreakpointConstants, AdaptiveUtils } from 'common-base';
import { AlertItem } from '../model/GreenhouseModel';
import { ThemeManager } from '../theme/ThemeManager';
import { ThemeTokens } from '../theme/ThemeTokens';

/**
 * 告警中心页面 - 多端适配（主题驱动）
 */

interface AlertFilter {
  readonly id: string;
  label: string;
}

@Component
export struct AlertPage {
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointConstants.SM;
  @StorageLink('themeName') themeName: string = 'frosted';

  @State alerts: AlertItem[] = [
    { id: '1', level: 1, message: 'CO₂浓度偏高(1200ppm)，建议通风', time: '2分钟前', device: 'CO2传感器-A区' },
    { id: '2', level: 0, message: '3号传感器离线', time: '15分钟前', device: '土壤湿度-3号' },
    { id: '3', level: 0, message: '温度偏低(12°C)', time: '1小时前', device: '温度传感器-B区' },
    { id: '4', level: 1, message: '湿度超上限(98%)', time: '2小时前', device: '湿度传感器-A区' },
    { id: '5', level: 0, message: '光照不足(80lux)', time: '3小时前', device: '光照传感器-B区' }
  ];
  @State readIds: string[] = ['3'];
  @State currentFilter: string = 'all';

  private filters: AlertFilter[] = [
    { id: 'all', label: '全部' },
    { id: 'unread', label: '未读' },
    { id: 'danger', label: '危险' }
  ];

  t(): ThemeTokens {
    return ThemeManager.getInstance().getTokens();
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
    this.HeaderSection()
    this.StatsBar()
    this.FilterTabs()
    this.AlertList()
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

  // ==================== Header ====================
  @Builder
  HeaderSection() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column()
        .width('100%')
        .height(140)
        .linearGradient({
          angle: 135,
          colors: [[this.t().headerGradientTop, 0.0], [this.t().headerGradientBottom, 1.0]]
        })

      Row() {
        Column() {
          Text('告警中心')
            .fontSize(AdaptiveUtils.getTitleFontSize(this.currentBreakpoint))
            .fontColor(this.t().textWhite)
            .fontWeight(FontWeight.Bold)
          Text(`未读 ${this.getUnreadCount()} · 危险 ${this.getDangerCount()}`)
            .fontSize(this.t().fontSm)
            .fontColor(this.t().textWhiteSub)
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        if (this.getUnreadCount() > 0) {
          Text(this.getUnreadCount().toString())
            .fontSize(this.t().fontSm)
            .fontColor(this.t().textOnDanger)
            .backgroundColor(this.t().danger)
            .borderRadius(12)
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .margin({ right: 8 })
            .textAlign(TextAlign.Center)
            .shadow({ radius: 4, color: this.t().danger, offsetX: 0, offsetY: 0 })
        }

        Text('全部已读')
          .fontSize(this.t().fontSm)
          .fontColor(this.t().textWhite)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor(this.t().bgCardLight)
          .borderRadius(this.t().radiusSm)
          .onClick(() => { this.markAllRead(); })
      }
      .width('100%')
      .height(140)
      .padding({ left: this.getPagePadding(), right: this.getPagePadding() })
    }
    .width('100%')
    .height(140)
  }

  // ==================== 统计条 ====================
  @Builder
  StatsBar() {
    Row() {
      this.StatMetric('📊', this.alerts.length.toString(), '总告警数', this.t().primary)
      Divider().vertical(true).height(36).color(this.t().borderLight)
      this.StatMetric('🔴', this.getUnreadCount().toString(), '未读', this.t().danger)
      Divider().vertical(true).height(36).color(this.t().borderLight)
      this.StatMetric('⚠', this.getDangerCount().toString(), '危险', this.t().warning)
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
    .margin({ top: -20, left: this.getPagePadding(), right: this.getPagePadding() })
  }

  @Builder
  StatMetric(icon: string, value: string, label: string, accentColor: string) {
    Column() {
      Text(icon)
        .fontSize(18)
        .width(36)
        .height(36)
        .textAlign(TextAlign.Center)
        .borderRadius(18)
        .backgroundColor(this.t().bgCardLight)
      Text(value)
        .fontSize(this.t().fontXl)
        .fontColor(this.t().textTitle)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 6 })
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
    .padding({ left: this.getPagePadding(), right: this.getPagePadding(), top: 12 })
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
        top: 12
      })
    }
    .layoutWeight(1)
    .scrollBar(BarState.Auto)
  }

  @Builder
  EmptyState() {
    Column() {
      Text('🌿')
        .fontSize(64)
      Text('暂无告警，大棚运行正常')
        .fontSize(this.t().fontMd)
        .fontColor(this.t().textSub)
        .margin({ top: 12 })
    }
    .width('100%')
    .padding({ top: 80, bottom: 80 })
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
          Text('📍 ' + item.device)
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
