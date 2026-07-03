import { BreakpointConstants, AdaptiveUtils } from 'common-base';
import { DeviceItem } from '../model/GreenhouseModel';
import { DeviceViewModel } from '../viewmodel/DeviceViewModel';
import { ThemeManager } from '../theme/ThemeManager';
import { ThemeTokens } from '../theme/ThemeTokens';
import { Logger } from 'common-base';

/**
 * 设备管理页面 - 多端适配（主题驱动）
 *
 * 定位：设备清单 + 在线状态 + 设备控制入口
 * 传感器数据展示在 DashboardPage（首页），本页不重复展示数值。
 */

@Component
export struct DevicePage {
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointConstants.SM;
  @StorageLink('themeName') themeName: string = 'frosted';

  @State devices: DeviceItem[] = [];
  @State totalCount: number = 0;
  @State onlineCount: number = 0;
  @State offlineCount: number = 0;
  /** 搜索关键词 */
  @State searchKeyword: string = '';
  /** 状态筛选：''=全部 'online'=在线 'offline'=离线 'fault'=故障 */
  @State statusFilter: string = '';
  /** 是否正在刷新 */
  @State isRefreshing: boolean = false;

  private viewModel: DeviceViewModel = new DeviceViewModel();

  t(): ThemeTokens {
    return ThemeManager.getInstance().getTokens();
  }

  aboutToAppear(): void {
    this.syncFromViewModel();
    this.loadDeviceData();
  }

  /** 从 ViewModel 同步数据到状态 */
  private syncFromViewModel(): void {
    this.devices = [...this.viewModel.devices];
    this.totalCount = this.viewModel.totalCount;
    this.onlineCount = this.viewModel.onlineCount;
    this.offlineCount = this.viewModel.offlineCount;
  }

  /** 加载设备数据（IoT 在线状态同步，失败降级到 mock） */
  private async loadDeviceData(): Promise<void> {
    await this.viewModel.loadData();
    this.syncFromViewModel();
  }

  /** 下拉刷新 */
  private async onRefresh(): Promise<void> {
    this.isRefreshing = true;
    await this.loadDeviceData();
    this.isRefreshing = false;
  }

  /** 搜索 + 筛选后的设备列表 */
  private getFilteredDevices(): DeviceItem[] {
    let list = this.devices;
    // 关键词过滤（名称 / 类型 / 位置）
    if (this.searchKeyword.trim().length > 0) {
      const kw = this.searchKeyword.trim().toLowerCase();
      list = list.filter((d: DeviceItem) =>
        d.name.toLowerCase().includes(kw) ||
        d.type.toLowerCase().includes(kw) ||
        d.location.toLowerCase().includes(kw)
      );
    }
    // 状态筛选
    if (this.statusFilter === 'online') {
      list = list.filter((d: DeviceItem) => d.status === 1);
    } else if (this.statusFilter === 'offline') {
      list = list.filter((d: DeviceItem) => d.status === 0);
    } else if (this.statusFilter === 'fault') {
      list = list.filter((d: DeviceItem) => d.status === 2);
    }
    return list;
  }

  /** 点击设备卡片 → 跳转详情页 */
  private onDeviceClick(item: DeviceItem): void {
    try {
      AppStorage.setOrCreate('deviceDetailParam', {
        id: item.id,
        name: item.name,
        type: item.type,
        status: item.status,
        lastUpdate: item.lastUpdate,
        location: item.location
      });
      const stack = AppStorage.get<NavPathStack>('navPathStack');
      if (stack) {
        stack.pushPath({ name: 'DeviceDetailPage' });
      }
    } catch (err) {
      Logger.warn('DevicePage', '路由跳转失败');
    }
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
    this.SearchAndFilterBar()
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
            .onClick(() => {
              this.onAddDevice();
            })
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

  // ==================== 搜索 + 状态筛选 ====================
  @Builder
  SearchAndFilterBar() {
    Column() {
      // 搜索栏
      Row() {
        Search({
          placeholder: '搜索设备名称、类型、位置...',
          value: this.searchKeyword
        })
          .width('100%')
          .height(40)
          .backgroundColor(this.t().bgCardLight)
          .borderRadius(this.t().radiusSm)
          .onChange((value: string) => {
            this.searchKeyword = value;
          })
          .onSubmit((value: string) => {
            this.searchKeyword = value;
          })
      }
      .width('100%')

      // 状态筛选 chips
      Row() {
        this.FilterChip('全部', '', this.statusFilter === '')
        this.FilterChip('在线', 'online', this.statusFilter === 'online')
        this.FilterChip('离线', 'offline', this.statusFilter === 'offline')
        this.FilterChip('故障', 'fault', this.statusFilter === 'fault')
      }
      .width('100%')
      .margin({ top: 8 })
    }
    .width('100%')
    .padding({
      left: this.getPagePadding(),
      right: this.getPagePadding(),
      top: 12
    })
  }

  @Builder
  FilterChip(label: string, filterKey: string, isActive: boolean) {
    Text(label)
      .fontSize(this.t().fontXs)
      .fontColor(isActive ? this.t().textWhite : this.t().textSub)
      .fontWeight(isActive ? FontWeight.Medium : FontWeight.Normal)
      .padding({ left: 12, right: 12, top: 4, bottom: 4 })
      .backgroundColor(isActive ? this.t().primary : this.t().bgCardLight)
      .borderRadius(14)
      .margin({ right: 8 })
      .onClick(() => {
        this.statusFilter = filterKey;
      })
  }

  // ==================== 设备列表 ====================
  @Builder
  DeviceList() {
    Refresh({ refreshing: $$this.isRefreshing }) {
      Scroll() {
        Column() {
          if (this.getFilteredDevices().length === 0) {
            this.EmptyState()
          } else {
            GridRow({
              gutter: { x: this.getCardGap(), y: this.getCardGap() }
            }) {
              ForEach(this.getFilteredDevices(), (item: DeviceItem) => {
                GridCol({ span: this.getDeviceSpan() }) {
                  this.DeviceCard(item)
                }
              })
            }
            .width('100%')
            .padding({
              left: this.getPagePadding(),
              right: this.getPagePadding(),
              top: 4
            })
          }
          Blank().height(80)
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
    }
    .onRefreshing(() => {
      this.onRefresh();
    })
    .layoutWeight(1)
  }

  /** 空状态占位 */
  @Builder
  EmptyState() {
    Column() {
      Text('📭')
        .fontSize(48)
        .opacity(0.4)
      Text('没有匹配的设备')
        .fontSize(this.t().fontMd)
        .fontColor(this.t().textSub)
        .margin({ top: 8 })
    }
    .width('100%')
    .padding({ top: 60, bottom: 60 })
    .alignItems(HorizontalAlign.Center)
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
    .onClick(() => {
      this.onDeviceClick(item);
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

  /** "+ 添加"按钮点击 — 弹出添加设备对话框 */
  private onAddDevice(): void {
    // 预留：后续实现添加设备表单（CustomDialog / 底部 Sheet）
    // 当前仅给出提示
    AlertDialog.show({
      title: '添加设备',
      message: '添加设备功能正在开发中，敬请期待。',
      confirm: {
        value: '知道了',
        fontColor: this.t().primary,
        action: () => {}
      }
    });
  }
}
