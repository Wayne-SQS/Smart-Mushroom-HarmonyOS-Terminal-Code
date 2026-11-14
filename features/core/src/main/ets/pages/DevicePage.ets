import { BreakpointConstants, AdaptiveUtils, LayoutConstants, Logger } from 'common-base';
import { DeviceItem } from '../model/GreenhouseModel';
import { DeviceViewModel } from '../viewmodel/DeviceViewModel';
import { ThemeManager } from '../theme/ThemeManager';
import { ThemeTokens } from '../theme/ThemeTokens';
import { StateView } from '../components/StateView';
import { PageHeader } from '../components/PageHeader';

/**
 * 设备管理页面 - 多端适配（主题驱动）
 *
 * 定位：设备清单 + 在线状态 + 设备控制入口
 * 传感器数据展示在 DashboardPage（首页），本页不重复展示数值。
 *
 * 数据真实性：
 * - 设备清单是本地台账（云端无 listDevices 接口），页面明确标注来源
 * - 在线状态来自设备影子；请求失败时展示错误条 + 重试，不把失败伪造成「离线」
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
  /** 首次加载态 */
  @State loading: boolean = true;
  /** 在线状态加载失败信息（空串表示正常） */
  @State errorMsg: string = '';

  private viewModel: DeviceViewModel = new DeviceViewModel();
  /** 页面已销毁标记：异步回调据此丢弃 setState */
  private disposed: boolean = false;

  t(): ThemeTokens {
    return ThemeManager.getInstance().getTokens();
  }

  aboutToAppear(): void {
    this.disposed = false;
    this.syncFromViewModel();
    this.loadDeviceData();
  }

  aboutToDisappear(): void {
    this.disposed = true;
  }

  /** 从 ViewModel 同步数据到状态 */
  private syncFromViewModel(): void {
    this.devices = [...this.viewModel.devices];
    this.totalCount = this.viewModel.totalCount;
    this.onlineCount = this.viewModel.onlineCount;
    this.offlineCount = this.viewModel.offlineCount;
  }

  /**
   * 加载设备在线状态
   *
   * 失败时保留本地台账，但显式暴露 errorMsg 供用户重试；
   * 不再把失败静默降级成「全部离线」。
   */
  private async loadDeviceData(): Promise<void> {
    this.loading = true;
    this.errorMsg = '';
    await this.viewModel.loadData();
    if (this.disposed) {
      return;
    }
    this.loading = false;
    if (this.viewModel.hasError()) {
      this.errorMsg = this.viewModel.errorMsg;
    }
    this.syncFromViewModel();
  }

  /** 下拉刷新 */
  private async onRefresh(): Promise<void> {
    this.isRefreshing = true;
    await this.loadDeviceData();
    if (this.disposed) {
      return;
    }
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
      // 只统计「确认离线」，未知状态不冒充离线
      list = list.filter((d: DeviceItem) => d.status === 0 && d.lastUpdate === '离线');
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
    PageHeader({
      title: '设备管理',
      subtitle: `共 ${this.totalCount} 台 · 在线 ${this.onlineCount}`,
      actionLabel: '添加',
      onAction: () => {
        this.onAddDevice();
      }
    })

    if (this.loading) {
      StateView({ mode: 'loading', title: '正在同步设备状态' })
    } else {
      this.StatsBar()
      if (this.errorMsg.length > 0) {
        this.StatusErrorBanner()
      }
      this.DataSourceNote()
      this.SearchAndFilterBar()
      this.DeviceList()
    }
  }

  /** 在线状态获取失败：局部错误条 + 重试（本地台账仍可浏览） */
  @Builder
  StatusErrorBanner() {
    Row() {
      Column() {
        Text('设备在线状态同步失败')
          .fontSize(this.t().fontSm)
          .fontColor(this.t().danger)
          .fontWeight(this.t().fontWeightTitle)
        Text(this.errorMsg)
          .fontSize(this.t().fontXs)
          .fontColor(this.t().textSub)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text('重试')
        .fontSize(this.t().fontSm)
        .fontColor(this.t().primary)
        .height(LayoutConstants.BUTTON_HEIGHT_SMALL)
        .padding({ left: LayoutConstants.SPACE_MD, right: LayoutConstants.SPACE_MD })
        .border({
          width: LayoutConstants.CARD_BORDER_WIDTH,
          color: this.t().primary,
          radius: LayoutConstants.RADIUS_SM
        })
        .textAlign(TextAlign.Center)
        .onClick(() => {
          this.loadDeviceData();
        })
    }
    .width('100%')
    .padding({
      left: this.getPagePadding(),
      right: this.getPagePadding(),
      top: LayoutConstants.SPACE_SM,
      bottom: LayoutConstants.SPACE_SM
    })
    .margin({ top: LayoutConstants.SPACE_MD })
  }

  /** 数据来源说明：避免用户误以为设备清单来自云端 */
  @Builder
  DataSourceNote() {
    Text(this.viewModel.isDemoData ? '设备清单为本地台账，在线状态来自设备影子' : '设备在线状态来自设备影子')
      .fontSize(this.t().fontXs)
      .fontColor(this.t().textHint)
      .width('100%')
      .padding({ left: this.getPagePadding(), right: this.getPagePadding(), top: LayoutConstants.SPACE_SM })
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

  // ==================== Header 已由 PageHeader 统一提供 ====================

  // ==================== 统计条 ====================
  @Builder
  StatsBar() {
    Row() {
      this.StatMetric(this.totalCount.toString(), '设备总数', this.t().primary)
      Divider().vertical(true).height(36).color(this.t().borderLight)
      this.StatMetric(this.onlineCount.toString(), '在线', this.t().success)
      Divider().vertical(true).height(36).color(this.t().borderLight)
      this.StatMetric(this.offlineCount.toString(), '离线', this.t().danger)
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
      // 装饰色条替代 emoji 图标
      Row()
        .width(20)
        .height(3)
        .borderRadius(2)
        .backgroundColor(accentColor)
        .margin({ bottom: LayoutConstants.SPACE_XS })
      Text(value)
        .fontSize(AdaptiveUtils.getOverviewFontSize(this.currentBreakpoint))
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
        this.FilterChip('全部', '')
        this.FilterChip('在线', 'online')
        this.FilterChip('离线', 'offline')
        this.FilterChip('故障', 'fault')
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
  FilterChip(label: string, filterKey: string) {
    Text(label)
      .fontSize(this.t().fontXs)
      .fontColor(this.statusFilter === filterKey ? this.t().textWhite : this.t().textSub)
      .fontWeight(this.statusFilter === filterKey ? FontWeight.Medium : FontWeight.Normal)
      .padding({ left: 12, right: 12, top: 4, bottom: 4 })
      .backgroundColor(this.statusFilter === filterKey ? this.t().primary : this.t().bgCardLight)
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
      Image($r('app.media.empty_no_device'))
        .width(96)
        .height(96)
        .objectFit(ImageFit.Contain)
        .opacity(0.6)
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
          Text(this.getDeviceBadge(item.type))
            .fontSize(this.t().fontLg)
            .fontColor(this.t().primary)
            .fontWeight(this.t().fontWeightTitle)
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
    if (status === 1) { return '在线'; }
    if (status === 2) { return '故障'; }
    return '离线';
  }

  /** 设备类型标签（单字，替代 emoji 图标） */
  private getDeviceBadge(type: string): string {
    switch (type) {
      case '温度': return '温';
      case '湿度': return '湿';
      case 'CO₂': return '碳';
      case '光照': return '光';
      case '土壤湿度': return '土';
      case '控制器': return '控';
      default: return '设';
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
