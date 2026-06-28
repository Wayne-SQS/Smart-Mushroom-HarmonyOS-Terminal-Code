import { StyleConstants, BreakpointConstants, AdaptiveUtils } from 'common-base';
import { AlertItem } from '../model/GreenhouseModel';

/**
 * 告警中心页面 - 多端适配
 *
 * 响应式：
 * - 告警列表 GridRow 多列：xs/sm 1列 / md 2列 / lg 2列 / xl 3列
 * - XL 屏内容限宽居中
 * - 统计条带图标美化
 */

interface AlertFilter {
  readonly id: string;
  label: string;
}

@Component
export struct AlertPage {
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointConstants.SM;

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
      .backgroundColor(StyleConstants.BG_PAGE)
    } else {
      Column() {
        this.ContentBody()
      }
      .width('100%')
      .height('100%')
      .backgroundColor(StyleConstants.BG_PAGE)
    }
  }

  @Builder
  ContentBody() {
    this.HeaderSection()
    this.StatsBar()
    this.FilterTabs()
    this.AlertList()
  }

  /** 是否需要内容限宽（大屏） */
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

  /** 告警卡片 GridCol span：xs/sm 12 / md 6 / lg 6 / xl 4 */
  private getAlertSpan(): number {
    const cols = AdaptiveUtils.getCardColumns(this.currentBreakpoint);
    return Math.floor(12 / cols);
  }

  // ==================== 顶部 Header ====================
  @Builder
  HeaderSection() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column()
        .width('100%')
        .height(140)
        .linearGradient({
          angle: 135,
          colors: [[StyleConstants.PRIMARY_DARK, 0.0], [StyleConstants.PRIMARY, 0.6], ['#388E3C', 1.0]]
        })

      Row() {
        Column() {
          Text('告警中心')
            .fontSize(AdaptiveUtils.getTitleFontSize(this.currentBreakpoint))
            .fontColor(StyleConstants.TEXT_WHITE)
            .fontWeight(FontWeight.Bold)
          Text(`未读 ${this.getUnreadCount()} · 危险 ${this.getDangerCount()}`)
            .fontSize(StyleConstants.FONT_SM)
            .fontColor(StyleConstants.TEXT_WHITE_SUB)
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        // 未读数徽章
        if (this.getUnreadCount() > 0) {
          Text(this.getUnreadCount().toString())
            .fontSize(StyleConstants.FONT_SM)
            .fontColor(StyleConstants.TEXT_WHITE)
            .backgroundColor(StyleConstants.DANGER)
            .borderRadius(12)
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .margin({ right: 8 })
            .textAlign(TextAlign.Center)
            .shadow({ radius: 4, color: StyleConstants.DANGER, offsetX: 0, offsetY: 0 })
        }

        // 全部已读按钮
        Text('全部已读')
          .fontSize(StyleConstants.FONT_SM)
          .fontColor(StyleConstants.TEXT_WHITE)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor('#FFFFFF20')
          .borderRadius(StyleConstants.RADIUS_SM)
          .onClick(() => {
            this.markAllRead();
          })
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
      this.StatMetric('📊', this.alerts.length.toString(), '总告警数', StyleConstants.PRIMARY)
      Divider().vertical(true).height(36).color(StyleConstants.BORDER_LIGHT)
      this.StatMetric('🔴', this.getUnreadCount().toString(), '未读', StyleConstants.DANGER)
      Divider().vertical(true).height(36).color(StyleConstants.BORDER_LIGHT)
      this.StatMetric('⚠', this.getDangerCount().toString(), '危险', StyleConstants.WARNING)
    }
    .width('100%')
    .padding({ top: 18, bottom: 18 })
    .backgroundColor(StyleConstants.BG_CARD)
    .borderRadius(StyleConstants.RADIUS_LG)
    .shadow({
      radius: StyleConstants.SHADOW_CARD_RADIUS,
      color: StyleConstants.SHADOW_CARD_COLOR,
      offsetX: 0,
      offsetY: StyleConstants.SHADOW_CARD_OFFSETY
    })
    .margin({ top: -20, left: this.getPagePadding(), right: this.getPagePadding() })
  }

  @Builder
  StatMetric(icon: string, value: string, label: string, color: string) {
    Column() {
      Text(icon)
        .fontSize(18)
        .width(36)
        .height(36)
        .textAlign(TextAlign.Center)
        .borderRadius(18)
        .backgroundColor(color + '18')
      Text(value)
        .fontSize(StyleConstants.FONT_XL)
        .fontColor(color)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 6 })
      Text(label)
        .fontSize(StyleConstants.FONT_SM)
        .fontColor(StyleConstants.TEXT_SUB)
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
          .fontSize(StyleConstants.FONT_SM)
          .fontColor(this.currentFilter === filter.id ? StyleConstants.TEXT_WHITE : StyleConstants.TEXT_SUB)
          .backgroundColor(this.currentFilter === filter.id ? StyleConstants.PRIMARY : StyleConstants.BG_CARD_LIGHT)
          .padding({ left: 16, right: 16, top: 6, bottom: 6 })
          .borderRadius(StyleConstants.RADIUS_SM)
          .margin({ right: 8 })
          .onClick(() => {
            this.currentFilter = filter.id;
          })
      })
    }
    .width('100%')
    .padding({ left: this.getPagePadding(), right: this.getPagePadding(), top: 12 })
  }

  // ==================== 告警列表（响应式多列） ====================
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

  // ==================== 空状态 ====================
  @Builder
  EmptyState() {
    Column() {
      Text('🌿')
        .fontSize(64)
      Text('暂无告警，大棚运行正常')
        .fontSize(StyleConstants.FONT_MD)
        .fontColor(StyleConstants.TEXT_HINT)
        .margin({ top: 12 })
    }
    .width('100%')
    .padding({ top: 80, bottom: 80 })
    .alignItems(HorizontalAlign.Center)
  }

  // ==================== 单条告警卡片 ====================
  @Builder
  AlertCard(item: AlertItem) {
    Row() {
      // 等级色条
      Column()
        .width(4)
        .height('100%')
        .backgroundColor(this.getLevelColor(item.level))
        .borderRadius(2)

      // 内容区
      Column() {
        Row() {
          // 等级徽章
          Text(this.getLevelText(item.level))
            .fontSize(StyleConstants.FONT_XS)
            .fontColor(this.getLevelColor(item.level))
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .backgroundColor(this.getLevelColor(item.level) + '20')
            .borderRadius(4)

          Blank()

          // 状态徽章 + 未读红点
          if (this.isUnread(item.id)) {
            Row() {
              Circle({ width: 6, height: 6 })
                .fill(StyleConstants.DANGER)
              Text('未读')
                .fontSize(StyleConstants.FONT_XS)
                .fontColor(StyleConstants.DANGER)
                .margin({ left: 4 })
            }
          } else {
            Text('已读')
              .fontSize(StyleConstants.FONT_XS)
              .fontColor(StyleConstants.TEXT_HINT)
          }
        }
        .width('100%')

        Text(item.message)
          .fontSize(StyleConstants.FONT_MD)
          .fontColor(StyleConstants.TEXT_TITLE)
          .fontWeight(FontWeight.Medium)
          .margin({ top: 8 })
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row() {
          Text('📍 ' + item.device)
            .fontSize(StyleConstants.FONT_XS)
            .fontColor(StyleConstants.TEXT_SUB)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
          Text(item.time)
            .fontSize(StyleConstants.FONT_XS)
            .fontColor(StyleConstants.TEXT_HINT)
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
    .backgroundColor(StyleConstants.BG_CARD)
    .borderRadius(StyleConstants.RADIUS_MD)
    .shadow({
      radius: 4,
      color: '#0A000000',
      offsetX: 0,
      offsetY: 1
    })
    .onClick(() => {
      this.markRead(item.id);
    })
  }

  // ==================== 私有方法 ====================
  private isUnread(id: string): boolean {
    return this.readIds.indexOf(id) === -1;
  }

  private getFilteredAlerts(): AlertItem[] {
    if (this.currentFilter === 'all') {
      return this.alerts;
    }
    if (this.currentFilter === 'unread') {
      return this.alerts.filter((item: AlertItem) => {
        return this.isUnread(item.id);
      });
    }
    if (this.currentFilter === 'danger') {
      return this.alerts.filter((item: AlertItem) => {
        return item.level === 1;
      });
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
      if (newReadIds.indexOf(item.id) === -1) {
        newReadIds.push(item.id);
      }
    });
    this.readIds = newReadIds;
  }

  private getUnreadCount(): number {
    let count: number = 0;
    this.alerts.forEach((item: AlertItem) => {
      if (this.isUnread(item.id)) {
        count = count + 1;
      }
    });
    return count;
  }

  private getDangerCount(): number {
    let count: number = 0;
    this.alerts.forEach((item: AlertItem) => {
      if (item.level === 1) {
        count = count + 1;
      }
    });
    return count;
  }

  private getLevelColor(level: number): string {
    if (level === 1) {
      return StyleConstants.DANGER;
    }
    return StyleConstants.WARNING;
  }

  private getLevelText(level: number): string {
    if (level === 1) {
      return '危险';
    }
    return '警告';
  }
}
