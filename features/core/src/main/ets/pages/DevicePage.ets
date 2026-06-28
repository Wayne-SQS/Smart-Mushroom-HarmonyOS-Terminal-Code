import { StyleConstants, BreakpointConstants, AdaptiveUtils } from 'common-base';
import { DeviceItem } from '../model/GreenhouseModel';

/**
 * 设备管理页面 - 多端适配
 *
 * 响应式：
 * - 设备列表 GridRow 多列：xs/sm 1列 / md 2列 / lg 3列 / xl 4列
 * - XL 屏内容限宽居中
 * - 卡片间距随断点变化
 */

@Component
export struct DevicePage {
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointConstants.SM;

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
    this.DeviceList()
  }

  /** 是否需要内容限宽（大屏） */
  private shouldLimitWidth(): boolean {
    return AdaptiveUtils.getMaxContentWidth(this.currentBreakpoint) > 0;
  }

  /** 内容区宽度：XL 屏限宽，其他全宽 */
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

  /** 设备列表 GridCol span：12 / 列数 */
  private getDeviceSpan(): number {
    const cols = AdaptiveUtils.getDeviceColumns(this.currentBreakpoint);
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

      Column() {
        Blank().height(40)
        Row() {
          Column() {
            Text('设备管理')
              .fontSize(AdaptiveUtils.getTitleFontSize(this.currentBreakpoint))
              .fontColor(StyleConstants.TEXT_WHITE)
              .fontWeight(FontWeight.Bold)
            Text(`共 ${this.totalCount} 台设备 · 在线 ${this.onlineCount}`)
              .fontSize(StyleConstants.FONT_SM)
              .fontColor(StyleConstants.TEXT_WHITE_SUB)
              .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Text('+ 添加')
            .fontSize(StyleConstants.FONT_MD)
            .fontColor(StyleConstants.TEXT_WHITE)
            .padding({ left: 14, right: 14, top: 8, bottom: 8 })
            .backgroundColor('#FFFFFF20')
            .borderRadius(StyleConstants.RADIUS_SM)
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
      this.StatMetric('📡', this.totalCount.toString(), '设备总数', StyleConstants.PRIMARY)
      Divider().vertical(true).height(36).color(StyleConstants.BORDER_LIGHT)
      this.StatMetric('🟢', this.onlineCount.toString(), '在线', StyleConstants.SUCCESS)
      Divider().vertical(true).height(36).color(StyleConstants.BORDER_LIGHT)
      this.StatMetric('🔴', this.offlineCount.toString(), '离线', StyleConstants.DANGER)
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

  // ==================== 设备列表（响应式多列） ====================
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
        // 设备图标
        Column() {
          Text(this.getDeviceIcon(item.type))
            .fontSize(28)
        }
        .width(48)
        .height(48)
        .borderRadius(24)
        .backgroundColor(this.getStatusColor(item.status) + '18')
        .justifyContent(FlexAlign.Center)

        // 状态点
        Blank()
        Circle({ width: 8, height: 8 })
          .fill(this.getStatusColor(item.status))
          .shadow({ radius: 4, color: this.getStatusColor(item.status), offsetX: 0, offsetY: 0 })
      }
      .width('100%')

      // 设备名
      Text(item.name)
        .fontSize(StyleConstants.FONT_MD)
        .fontColor(StyleConstants.TEXT_TITLE)
        .fontWeight(FontWeight.Medium)
        .margin({ top: 10 })
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      // 类型 + 位置
      Row() {
        Text(item.type)
          .fontSize(StyleConstants.FONT_XS)
          .fontColor(StyleConstants.TEXT_SUB)
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .backgroundColor(StyleConstants.BG_CARD_LIGHT)
          .borderRadius(4)
        Text(item.location)
          .fontSize(StyleConstants.FONT_XS)
          .fontColor(StyleConstants.TEXT_HINT)
          .margin({ left: 8 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
      }
      .width('100%')
      .margin({ top: 6 })

      // 底部状态行
      Row() {
        Text(this.getStatusText(item.status))
          .fontSize(StyleConstants.FONT_XS)
          .fontColor(this.getStatusColor(item.status))
        Blank()
        Text(item.lastUpdate)
          .fontSize(StyleConstants.FONT_XS)
          .fontColor(StyleConstants.TEXT_HINT)
      }
      .width('100%')
      .margin({ top: 8 })
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
  }

  private getStatusColor(status: number): string {
    if (status === 1) {
      return StyleConstants.SUCCESS;
    }
    if (status === 2) {
      return StyleConstants.DANGER;
    }
    return StyleConstants.TEXT_HINT;
  }

  private getStatusText(status: number): string {
    if (status === 1) {
      return '● 在线';
    }
    if (status === 2) {
      return '● 故障';
    }
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
