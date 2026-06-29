import { BreakpointConstants, AdaptiveUtils } from 'common-base';
import { DeviceItem } from '../model/GreenhouseModel';
import { ThemeManager } from '../theme/ThemeManager';
import { ThemeTokens } from '../theme/ThemeTokens';

/**
 * 设备管理页面 - 多端适配（主题驱动）
 */

@Component
export struct DevicePage {
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointConstants.SM;
  @StorageLink('themeName') themeName: string = 'frosted';

  @State devices: DeviceItem[] = [
    { id: '1', name: '温度传感器-A区', type: '温度', status: 1, lastUpdate: '10秒前', location: 'A区东侧' },
    { id: '2', name: '湿度传感器-A区', type: '湿度', status: 1, lastUpdate: '8秒前', location: 'A区西侧' },
    { id: '3', name: 'CO2传感器-A区', type: 'CO₂', status: 1, lastUpdate: '15秒前', location: 'A区中央' },
    { id: '4', name: '光照传感器-B区', type: '光照', status: 1, lastUpdate: '5秒前', location: 'B区顶部' },
    { id: '5', name: '土壤湿度-3号', type: '土壤湿度', status: 0, lastUpdate: '15分钟前', location: 'C区3号位' },
    { id: '6', name: '通风控制器', type: '控制器', status: 1, lastUpdate: '运行中', location: '大棚东墙' },
    { id: '7', name: '喷雾系统', type: '控制器', status: 1, lastUpdate: '待机', location: '大棚顶部' },
    { id: '8', name: '补光灯组', type: '控制器', status: 0, lastUpdate: '已关闭', location: 'B区顶部' }
  ];

  @State totalCount: number = 8;
  @State onlineCount: number = 7;
  @State offlineCount: number = 1;

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
    this.DeviceList()
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

  private getDeviceSpan(): number {
    const cols = AdaptiveUtils.getDeviceColumns(this.currentBreakpoint);
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

      Column() {
        Blank().height(40)
        Row() {
          Column() {
            Text('设备管理')
              .fontSize(AdaptiveUtils.getTitleFontSize(this.currentBreakpoint))
              .fontColor(this.t().textWhite)
              .fontWeight(FontWeight.Bold)
            Text(`共 ${this.totalCount} 台设备 · 在线 ${this.onlineCount}`)
              .fontSize(this.t().fontSm)
              .fontColor(this.t().textWhiteSub)
              .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Text('+ 添加')
            .fontSize(this.t().fontMd)
            .fontColor(this.t().textWhite)
            .padding({ left: 14, right: 14, top: 8, bottom: 8 })
            .backgroundColor(this.t().bgCardLight)
            .borderRadius(this.t().radiusSm)
        }
        .width('100%')
        .padding({ left: this.getPagePadding(), right: this.getPagePadding() })
      }
      .width('100%')
    }
    .width('100%')
    .height(140)
  }

  // ==================== 统计条 ====================
  @Builder
  StatsBar() {
    Row() {
      this.StatMetric('📡', this.totalCount.toString(), '设备总数', this.t().primary)
      Divider().vertical(true).height(36).color(this.t().borderLight)
      this.StatMetric('🟢', this.onlineCount.toString(), '在线', this.t().success)
      Divider().vertical(true).height(36).color(this.t().borderLight)
      this.StatMetric('🔴', this.offlineCount.toString(), '离线', this.t().danger)
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
      // 大字号走 AdaptiveUtils 断点自适应
      Text(value)
        .fontSize(AdaptiveUtils.getOverviewFontSize(this.currentBreakpoint))
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

  // ==================== 设备列表 ====================
  @Builder
  DeviceList() {
    Scroll() {
      Column() {
        GridRow({
          gutter: { x: this.getCardGap(), y: this.getCardGap() }
        }) {
          ForEach(this.devices, (item: DeviceItem) => {
            GridCol({ span: this.getDeviceSpan() }) {
              this.DeviceCard(item)
            }
          })
        }
        .width('100%')
        .padding({
          left: this.getPagePadding(),
          right: this.getPagePadding(),
          top: 12
        })
        Blank().height(80)
      }
      .width('100%')
    }
    .layoutWeight(1)
    .scrollBar(BarState.Auto)
    .margin({ top: 8 })
  }

  @Builder
  DeviceCard(item: DeviceItem) {
    Column() {
      Row() {
        Column() {
          Text(this.getDeviceIcon(item.type))
            .fontSize(28)
        }
        .width(48)
        .height(48)
        .borderRadius(24)
        .backgroundColor(this.t().bgCardLight)
        .justifyContent(FlexAlign.Center)

        Blank()
        Circle({ width: 8, height: 8 })
          .fill(this.getStatusColor(item.status))
          .shadow({ radius: 4, color: this.getStatusColor(item.status), offsetX: 0, offsetY: 0 })
      }
      .width('100%')

      Text(item.name)
        .fontSize(this.t().fontMd)
        .fontColor(this.t().textTitle)
        .fontWeight(FontWeight.Medium)
        .margin({ top: 10 })
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Row() {
        Text(item.type)
          .fontSize(this.t().fontXs)
          .fontColor(this.t().textSub)
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .backgroundColor(this.t().bgCardLight)
          .borderRadius(4)
        Text(item.location)
          .fontSize(this.t().fontXs)
          .fontColor(this.t().textSub)
          .margin({ left: 8 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
      }
      .width('100%')
      .margin({ top: 6 })

      Row() {
        Text(this.getStatusText(item.status))
          .fontSize(this.t().fontXs)
          .fontColor(this.getStatusColor(item.status))
        Blank()
        Text(item.lastUpdate)
          .fontSize(this.t().fontXs)
          .fontColor(this.t().textSub)
      }
      .width('100%')
      .margin({ top: 8 })
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
  }

  private getStatusColor(status: number): string {
    if (status === 1) { return this.t().success; }
    if (status === 2) { return this.t().danger; }
    return this.t().textSub;
  }

  private getStatusText(status: number): string {
    if (status === 1) { return '● 在线'; }
    if (status === 2) { return '● 故障'; }
    return '● 离线';
  }

  private getDeviceIcon(type: string): string {
    switch (type) {
      case '温度': return '🌡';
      case '湿度': return '💧';
      case 'CO₂': return '🌫';
      case '光照': return '☀';
      case '土壤湿度': return '🌱';
      case '控制器': return '⚙';
      default: return '📊';
    }
  }
}
