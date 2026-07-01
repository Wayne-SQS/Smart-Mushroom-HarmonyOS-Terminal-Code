import { MapViewComponent, MapMarker, MapViewColors, BreakpointConstants, AdaptiveUtils } from 'common-base';
import { ThemeManager } from '../theme/ThemeManager';
import { ThemeTokens } from '../theme/ThemeTokens';
import { Logger } from 'common-base';
import { IotService } from '../service/IotService';
import promptAction from '@ohos.promptAction';

const TAG = 'MapPage';

/**
 * 地图监控页面 - 断点分栏 + 双模式地图 + 多端降级
 *
 * 多端适配策略（不写 deviceInfo.deviceType，只用断点 + canIUse）：
 *   - XS（wearable）：极简模式，只列表，点项跳 DashboardPage
 *   - SM（手机竖屏）：上下分栏（地图上 40% + 列表下 60%）
 *   - MD/LG/XL（平板/2in1/PC）：左右分栏（列表左 40% + 地图右 60%）
 *
 * 地图模式：MapViewComponent 内部 canIUse('SystemCapability.Map.Core') 自动切换
 *   - 真实 Map Kit：渲染真实瓦片，支持缩放/平移
 *   - Canvas 降级：经纬度投影自绘
 *
 * 交互：
 *   - 状态筛选（全部/正常/告警/离线）Tab 式切换
 *   - 告警排序开关（开启时按 alerts 降序）
 *   - 搜索联动地图（过滤列表 + 高亮首个匹配项）
 *   - 列表项内联展开详情（手风琴式，只展开一个）
 *   - "查看详情"跳 DashboardPage（传 greenhouseId 占位）
 */

interface GreenhouseLocation {
  readonly id: string;
  name: string;
  status: string;
  sensors: number;
  alerts: number;
  devices: number;
  temp: number;
  humidity: number;
  /** 纬度（WGS84） */
  lat: number;
  /** 经度（WGS84） */
  lng: number;
}

/** 状态筛选枚举 */
type StatusFilter = 'all' | 'normal' | 'alert' | 'offline';

/**
 * 大棚详情路由参数
 *
 * 用于 MapPage 跳转 DashboardPage 时传递 greenhouseId。
 * 显式声明 interface 避免 Record<string, Object> 字面量违反
 * ArkTS no-untyped-obj-literals 规则。
 */
interface GreenhouseNavParam {
  readonly greenhouseId: string;
}

@Component
export struct MapPage {
  @StorageLink('themeName') themeName: string = 'frosted';
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointConstants.SM;

  /** 大棚位置数据（武汉周边真实经纬度） */
  @State greenhouses: GreenhouseLocation[] = [
    { id: '1', name: '1号蘑菇大棚', status: '运行正常', sensors: 12, alerts: 0, devices: 8, temp: 22.5, humidity: 85, lat: 30.52, lng: 114.32 },
    { id: '2', name: '2号蘑菇大棚', status: '运行正常', sensors: 10, alerts: 0, devices: 6, temp: 21.8, humidity: 82, lat: 30.55, lng: 114.28 },
    { id: '3', name: '3号蘑菇大棚', status: 'CO₂偏高',   sensors: 11, alerts: 2, devices: 7, temp: 24.1, humidity: 88, lat: 30.48, lng: 114.35 },
    { id: '4', name: '育种室',       status: '运行正常', sensors: 6,  alerts: 0, devices: 4, temp: 25.0, humidity: 70, lat: 30.53, lng: 114.38 },
    { id: '5', name: '5号实验棚',   status: '温度偏低', sensors: 8,  alerts: 1, devices: 5, temp: 14.2, humidity: 78, lat: 30.47, lng: 114.30 },
    { id: '6', name: '6号香菇棚',   status: '运行正常', sensors: 9,  alerts: 0, devices: 6, temp: 18.5, humidity: 80, lat: 30.56, lng: 114.40 },
    { id: '7', name: '7号金针菇棚', status: '运行正常', sensors: 7,  alerts: 0, devices: 5, temp: 10.2, humidity: 90, lat: 30.50, lng: 114.42 },
    { id: '8', name: '菌种储存室',   status: '离线',     sensors: 4,  alerts: 3, devices: 3, temp: 0,    humidity: 0,  lat: 30.49, lng: 114.26 }
  ];
  @State selectedId: string = '1';
  @State searchKeyword: string = '';
  @State statusFilter: StatusFilter = 'all';
  @State alertSortEnabled: boolean = false;

  /** 地图高级功能开关（仅真实 Map Kit 模式生效，Canvas 降级模式无影响） */
  @State isSatellite: boolean = false;        // 卫星图切换
  @State enableCluster: boolean = false;      // 标记聚合 Cluster
  @State enableMyLocation: boolean = false;   // 我的位置图层 + 按钮

  /** 方案 D 重构新增状态 */
  @State isMapFullscreen: boolean = false;    // 地图全屏模式（列表收为底部 mini bar）
  @State isSearchVisible: boolean = false;    // 搜索 overlay 浮层可见性
  @State sheetVisible: boolean = false;       // 详情 BottomSheet 可见性
  @State sheetItem: GreenhouseLocation = MapPage.EMPTY_GREENHOUSE;  // BottomSheet 当前展示的大棚
  @State isIotOnline: boolean = false;        // IoT 设备连接状态
  @State iotCheckDone: boolean = false;       // IoT 检测是否完成

  /** 空哨兵对象，避免 sheetItem 为 null 触发类型断言 */
  private static readonly EMPTY_GREENHOUSE: GreenhouseLocation = {
    id: '', name: '', status: '', sensors: 0, alerts: 0, devices: 0,
    temp: 0, humidity: 0, lat: 0, lng: 0
  };

  /** 地图中心（所有大棚的几何中心） */
  private mapCenterLat: number = 30.51;
  private mapCenterLng: number = 114.34;

  t(): ThemeTokens {
    return ThemeManager.getInstance().getTokens();
  }

  /** 是否为 wearable 极简模式（XS 断点，不写 deviceType） */
  private isWearableMode(): boolean {
    return this.currentBreakpoint === BreakpointConstants.XS;
  }

  /** 是否为宽屏分栏模式（MD/LG/XL） */
  private isWideSplitMode(): boolean {
    return this.currentBreakpoint === BreakpointConstants.MD
      || this.currentBreakpoint === BreakpointConstants.LG
      || this.currentBreakpoint === BreakpointConstants.XL;
  }

  /** 将 GreenhouseLocation 转为 MapMarker */
  private toMapMarkers(): MapMarker[] {
    const result: MapMarker[] = [];
    const filtered = this.getFilteredGreenhouses();
    for (let i = 0; i < filtered.length; i++) {
      const g = filtered[i];
      result.push({
        id: g.id,
        lat: g.lat,
        lng: g.lng,
        label: g.name,
        statusColor: this.getStatusColor(g.status),
        selected: g.id === this.selectedId
      });
    }
    return result;
  }

  /** 从 ThemeTokens 构造 Canvas 降级模式颜色 */
  private buildMapViewColors(): MapViewColors {
    const tk = this.t();
    return {
      bgGradientTop: tk.bgCardLight,
      bgGradientMid: tk.bgCard,
      bgGradientBottom: tk.bgCardLight,
      gridLine: tk.borderLight,
      metaText: tk.textHint,
      metaBg: tk.bgCard,
      markerBorder: tk.textWhite,
      markerGlow: tk.textWhite,
      labelBg: tk.textTitle,
      labelText: tk.textWhite
    };
  }

  aboutToAppear(): void {
    this.checkIotStatus();
  }

  /** 检测 IoT 设备连接状态，同步更新大棚状态 */
  private async checkIotStatus(): Promise<void> {
    try {
      this.isIotOnline = await IotService.getInstance().isDeviceOnline();
      Logger.info(TAG, `IoT 设备在线状态: ${this.isIotOnline}`);
    } catch (e) {
      this.isIotOnline = false;
      Logger.warn(TAG, `IoT 检测失败: ${JSON.stringify(e)}`);
    }
    this.iotCheckDone = true;
    // 根据真实 IoT 状态更新大棚数据
    this.applyIotStatus();
  }

  /** 把 IoT 在线状态写进大棚数据 */
  private applyIotStatus(): void {
    const updated: GreenhouseLocation[] = [];
    for (let i = 0; i < this.greenhouses.length; i++) {
      const g = this.greenhouses[i];
      // 1号大棚对应真实 IoT 设备
      if (g.id === '1') {
        const newStatus = this.isIotOnline ? '运行正常' : 'IoT未连接';
        updated.push({
          id: g.id, name: g.name, status: newStatus,
          sensors: this.isIotOnline ? g.sensors : 0,
          alerts: g.alerts, devices: g.devices,
          temp: this.isIotOnline ? g.temp : 0,
          humidity: this.isIotOnline ? g.humidity : 0,
          lat: g.lat, lng: g.lng
        });
      } else {
        updated.push(g);
      }
    }
    this.greenhouses = updated;
  }

  build() {
    Stack() {
      // 主内容层（根据断点 + 全屏状态选择布局）
      if (this.isWearableMode()) {
        this.WearableLayout();
      } else if (this.isMapFullscreen) {
        this.FullscreenMapLayout();
      } else if (this.isWideSplitMode()) {
        this.WideSplitLayout();
      } else {
        this.NarrowStackLayout();
      }

      // 搜索 overlay（顶部覆盖 HeaderSection）
      if (this.isSearchVisible && !this.isWearableMode()) {
        this.SearchOverlay();
      }

      // BottomSheet 遮罩
      if (this.sheetVisible) {
        this.SheetBackdrop();
      }

      // BottomSheet 内容（底部弹起）
      if (this.sheetVisible) {
        Column() {
          this.BottomSheet(this.sheetItem);
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.End)
      }
    }
    .width('100%')
    .height('100%')
  }

  // ==================== wearable 极简布局（XS） ====================
  @Builder
  WearableLayout() {
    Column() {
      // 简化 Header（只有标题）
      Row() {
        Stack({ alignContent: Alignment.Center }) {
          this.MapIcon('map', this.t().textTitle)
        }
        .width(20).height(20)
        Text('大棚')
          .fontSize(this.t().fontLg)
          .fontColor(this.t().textTitle)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 6 })
        Blank()
        Text(`${this.getFilteredGreenhouses().length}`)
          .fontSize(this.t().fontSm)
          .fontColor(this.t().textSub)
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })

      // 紧凑列表（无地图、无统计条）
      Scroll() {
        Column() {
          ForEach(this.getFilteredGreenhouses(), (item: GreenhouseLocation) => {
            this.WearableListItem(item)
          }, (item: GreenhouseLocation) => item.id)
          Blank().height(40)
        }.width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.t().bgPage)
  }

  /** wearable 紧凑列表项（点击直接跳 DashboardPage） */
  @Builder
  WearableListItem(item: GreenhouseLocation) {
    Row() {
      Circle({ width: 8, height: 8 }).fill(this.getStatusColor(item.status))
      Text(item.name)
        .fontSize(this.t().fontSm)
        .fontColor(this.t().textTitle)
        .margin({ left: 8 })
        .layoutWeight(1)
      if (item.alerts > 0) {
        Text(`${item.alerts}`)
          .fontSize(this.t().fontXs)
          .fontColor(this.t().textWhite)
          .backgroundColor(this.t().warning)
          .borderRadius(8)
          .padding({ left: 4, right: 4, top: 1, bottom: 1 })
      }
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.navigateToDashboard(item.id);
    })
  }

  // ==================== 宽屏左右分栏布局（MD/LG/XL） ====================
  @Builder
  WideSplitLayout() {
    Column() {
      this.HeaderSection()
      Row() {
        // 左侧列表（40%）
        Column() {
          this.ListPanel()
        }
        .width('40%')
        .height('100%')

        // 右侧地图（60%）
        Column() {
          this.MapPanel()
        }
        .width('60%')
        .height('100%')
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.t().bgPage)
  }

  // ==================== 窄屏上下分栏布局（SM） ====================
  @Builder
  NarrowStackLayout() {
    Column() {
      this.HeaderSection()
      // 地图（40%）
      Column() {
        this.MapPanel()
      }
      .width('100%')
      .height('40%')

      // 列表（剩余）
      Column() {
        this.ListPanel()
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.t().bgPage)
  }

  // ==================== 地图全屏布局（点击 expand 按钮触发） ====================
  @Builder
  FullscreenMapLayout() {
    Stack() {
      // 全屏地图（铺满）
      MapViewComponent({
        markers: this.toMapMarkers(),
        centerLat: this.mapCenterLat,
        centerLng: this.mapCenterLng,
        mapHeight: 0,
        colors: this.buildMapViewColors(),
        isSatellite: this.isSatellite,
        enableCluster: this.enableCluster,
        enableMyLocation: this.enableMyLocation,
        onMarkerClick: (id: string) => {
          this.selectedId = id;
          const item = this.findGreenhouseById(id);
          if (item) {
            this.sheetItem = item;
            this.sheetVisible = true;
          }
        }
      })
        .width('100%')
        .height('100%')

      // 顶部浮层（返回按钮 + 控制按钮组）
      Row() {
        Stack({ alignContent: Alignment.Center }) {
          this.MapIcon('contract', this.t().textWhite)
        }
        .width(30)
        .height(30)
        .backgroundColor(this.t().bgCardLight)
        .backdropBlur(this.t().blurAmount)
        .borderRadius(this.t().radiusFull)
        .onClick(() => {
          this.isMapFullscreen = false;
        })
        Blank()
        this.MapControlButtons()
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 12 })
      .alignItems(VerticalAlign.Center)
      .position({ x: 0, y: 0 })

      // 底部 mini bar（点击恢复分栏）
      Row() {
        Stack({ alignContent: Alignment.Center }) {
          this.MapIcon('list', this.t().textTitle)
        }
        .width(20).height(20)
        Text(`查看大棚列表（${this.greenhouses.length}）`)
          .fontSize(this.t().fontSm)
          .fontColor(this.t().textTitle)
          .margin({ left: 8 })
          .layoutWeight(1)
        Stack({ alignContent: Alignment.Center }) {
          this.MapIcon('contract', this.t().textHint)
        }
        .width(20).height(20)
      }
      .width('90%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor(this.t().bgCard)
      .backdropBlur(this.t().blurAmount)
      .borderRadius(this.t().radiusLg)
      .border({ width: 1, color: this.t().borderLight })
      .position({ x: '5%', y: '100%' })
      .translate({ y: '-100%' })
      .margin({ bottom: 16 })
      .onClick(() => {
        this.isMapFullscreen = false;
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.t().bgPage)
  }

  // ==================== Header（极简化：标题 + 统计 chip + 搜索图标） ====================
  @Builder
  HeaderSection() {
    Row() {
      Stack({ alignContent: Alignment.Center }) {
        this.MapIcon('map', this.t().textWhite)
      }
      .width(22).height(22)
      Text('地图监控')
        .fontSize(this.t().fontXxl)
        .fontColor(this.t().textWhite)
        .fontWeight(FontWeight.Bold)
        .margin({ left: 8 })

      Blank()

      // 紧凑统计 chip：「10/12 在线 · 2 告警」
      Text(this.getStatsSummary())
        .fontSize(this.t().fontXs)
        .fontColor(this.t().textWhite)
        .backgroundColor(this.t().bgCardLight)
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .borderRadius(this.t().radiusFull)

      // 搜索图标按钮（点击展开搜索 overlay）
      Stack({ alignContent: Alignment.Center }) {
        this.MapIcon('search', this.t().textWhite)
      }
      .width(30)
      .height(30)
      .margin({ left: 8 })
      .onClick(() => {
        this.isSearchVisible = true;
      })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .alignItems(VerticalAlign.Center)
    .linearGradient({
      angle: 135,
      colors: [[this.t().headerGradientTop, 0.0], [this.t().headerGradientBottom, 1.0]]
    })
  }

  /** 搜索 overlay（点击 Header 搜索图标触发，顶部覆盖） */
  @Builder
  SearchOverlay() {
    Column() {
      Row() {
        Stack({ alignContent: Alignment.Center }) {
          this.MapIcon('close', this.t().textWhite)
        }
        .width(30)
        .height(30)
        .onClick(() => {
          this.isSearchVisible = false;
          this.searchKeyword = '';
        })
        Stack({ alignContent: Alignment.Center }) {
          this.MapIcon('search', this.t().textTitle)
        }
        .width(20).height(20).margin({ left: 4 })
        TextInput({ text: this.searchKeyword, placeholder: '搜索大棚名称' })
          .fontSize(this.t().fontMd)
          .fontColor(this.t().textTitle)
          .placeholderColor(this.t().textWhiteSub)
          .backgroundColor(this.t().bgCardLight)
          .borderRadius(this.t().radiusSm)
          .layoutWeight(1)
          .margin({ left: 8 })
          .height(36)
          .padding({ left: 10, right: 10 })
          .onChange((value: string) => {
            this.searchKeyword = value;
            this.onSearchChange(value);
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .alignItems(VerticalAlign.Center)
      .linearGradient({
        angle: 135,
        colors: [[this.t().headerGradientTop, 0.0], [this.t().headerGradientBottom, 1.0]]
      })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /** 状态筛选 chip */
  @Builder
  StatusFilterChip(opt: StatusFilterOption) {
    Text(opt.label)
      .fontSize(this.t().fontXs)
      .fontColor(this.statusFilter === opt.value ? this.t().textOnPrimary : this.t().textWhiteSub)
      .padding({ left: 8, right: 8, top: 4, bottom: 4 })
      .margin({ right: 6 })
      .backgroundColor(this.statusFilter === opt.value ? this.t().primary : this.t().bgCardLight)
      .borderRadius(this.t().radiusFull)
      .onClick(() => {
        this.statusFilter = opt.value;
      })
  }

  // ==================== 地图面板（含底部浮层按钮） ====================
  @Builder
  MapPanel() {
    Column() {
      Stack({ alignContent: Alignment.Bottom }) {
        MapViewComponent({
          markers: this.toMapMarkers(),
          centerLat: this.mapCenterLat,
          centerLng: this.mapCenterLng,
          mapHeight: this.getMapHeight(),
          colors: this.buildMapViewColors(),
          isSatellite: this.isSatellite,
          enableCluster: this.enableCluster,
          enableMyLocation: this.enableMyLocation,
          onMarkerClick: (id: string) => {
            this.selectedId = id;
            const item = this.findGreenhouseById(id);
            if (item) {
              this.sheetItem = item;
              this.sheetVisible = true;
            }
          }
        })
          .width('100%')
          .height('100%')
          .borderRadius(this.t().radiusLg)
          .clip(true)
          .backgroundColor(this.t().bgCardLight)

        // 浮层控制按钮组（底部横排，wearable 不显示）
        if (!this.isWearableMode()) {
          Row() {
            this.MapControlButtons()
          }
          .margin({ bottom: 12 })
        }
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
  }

  /**
   * 地图浮层控制按钮组（底部横排，4 个按钮）
   *
   *   - satellite   卫星图切换（isSatellite）
   *   - cluster     标记聚合 Cluster（enableCluster）
   *   - location    我的位置（enableMyLocation）
   *   - expand/contract  全屏切换（isMapFullscreen）
   *
   * 每个按钮 30×30px，内部图标约 12×12px，使用纯几何图形替代 emoji
   */
  @Builder
  MapControlButtons() {
    Row() {
      this.MapButtonWithIcon('satellite', this.isSatellite, () => {
        this.isSatellite = !this.isSatellite;
      })
      this.MapButtonWithIcon('cluster', this.enableCluster, () => {
        this.enableCluster = !this.enableCluster;
      })
      this.MapButtonWithIcon('location', this.enableMyLocation, () => {
        this.onLocationToggle();
      })
      this.MapButtonWithIcon(this.isMapFullscreen ? 'contract' : 'expand', this.isMapFullscreen, () => {
        this.isMapFullscreen = !this.isMapFullscreen;
      })
    }
    .padding({ left: 6, right: 6, top: 4, bottom: 4 })
    .backgroundColor(this.t().bgCardLight)
    .backdropBlur(this.t().blurAmount)
    .borderRadius(this.t().radiusFull)
    .border({ width: 1, color: this.t().borderLight })
    .shadow({
      radius: this.t().shadowCardRadius,
      color: this.t().shadowCardColor,
      offsetX: 0,
      offsetY: this.t().shadowCardOffsetY
    })
  }

  /**
   * 自定义几何图标工厂
   *
   * 所有图标控制在 12-14px 尺寸内，全部由 Circle / Rect / Stack / Row / Column 构成，
   * 不依赖 emoji 或外部图片资源。color 参数由调用方根据激活状态传入。
   */
  @Builder
  MapIcon(type: string, color: string) {
    if (type === 'satellite') {
      // 卫星：同心圆（外环扫描 + 内实心）
      Stack({ alignContent: Alignment.Center }) {
        Circle({ width: 13, height: 13 }).fill(Color.Transparent).border({ width: 1.2, color: color })
        Circle({ width: 3.5, height: 3.5 }).fill(color)
      }
    } else if (type === 'cluster') {
      // 聚合：2×2 方块网格（带微小圆角）
      Column({ space: 1.5 }) {
        Row({ space: 1.5 }) {
          Rect({ width: 3.5, height: 3.5 }).fill(color).borderRadius(1)
          Rect({ width: 3.5, height: 3.5 }).fill(color).borderRadius(1)
        }
        Row({ space: 1.5 }) {
          Rect({ width: 3.5, height: 3.5 }).fill(color).borderRadius(1)
          Rect({ width: 3.5, height: 3.5 }).fill(color).borderRadius(1)
        }
      }
    } else if (type === 'location') {
      // 定位：十字准星（圆环 + 十字线）
      Stack({ alignContent: Alignment.Center }) {
        Circle({ width: 13, height: 13 }).fill(Color.Transparent).border({ width: 1.2, color: color })
        Row().width(15).height(1.2).backgroundColor(color)
        Column().width(1.2).height(15).backgroundColor(color)
      }
    } else if (type === 'expand') {
      // 全屏展开：两条对角 L 形角标（左上 + 右下）
      Stack({ alignContent: Alignment.Center }) {
        // 左上角
        Row() {
          Column().width(1.5).height(7).backgroundColor(color)
          Column().width(7).height(1.5).backgroundColor(color)
        }.position({ x: -3.5, y: -3.5 })
        // 右下角
        Row() {
          Column().width(7).height(1.5).backgroundColor(color)
          Column().width(1.5).height(7).backgroundColor(color)
        }.position({ x: 3.5, y: 3.5 })
      }
    } else if (type === 'contract') {
      // 全屏退出：两条对角 L 形角标（右上 + 左下）
      Stack({ alignContent: Alignment.Center }) {
        // 右上角
        Row() {
          Column().width(7).height(1.5).backgroundColor(color)
          Column().width(1.5).height(7).backgroundColor(color)
        }.position({ x: 3.5, y: -3.5 })
        // 左下角
        Row() {
          Column().width(1.5).height(7).backgroundColor(color)
          Column().width(7).height(1.5).backgroundColor(color)
        }.position({ x: -3.5, y: 3.5 })
      }
    } else if (type === 'search') {
      // 搜索：放大镜（圆环 + 短手柄）
      Stack({ alignContent: Alignment.Center }) {
        Circle({ width: 10, height: 10 }).fill(Color.Transparent).border({ width: 1.2, color: color })
        Rect({ width: 4.5, height: 1.2 }).fill(color).rotate({ angle: 45 }).position({ x: 5, y: 5 })
      }
    } else if (type === 'close') {
      // 关闭：细 X 形（两条旋转短线）
      Stack({ alignContent: Alignment.Center }) {
        Rect({ width: 11, height: 1.3 }).fill(color).rotate({ angle: 45 })
        Rect({ width: 11, height: 1.3 }).fill(color).rotate({ angle: -45 })
      }
    } else if (type === 'alert') {
      // 告警：圆环 + 叹号（竖线 + 圆点）
      Column({ space: 1 }) {
        Rect({ width: 1.5, height: 3.5 }).fill(color)
        Circle({ width: 2, height: 2 }).fill(color)
      }
    } else if (type === 'map') {
      // 地图图钉：实心圆 + 细尾
      Column({ space: -0.5 }) {
        Circle({ width: 8, height: 8 }).fill(color)
        // 小三角尖（用极窄 Rect 旋转模拟）
        Rect({ width: 4, height: 4 }).fill(color).rotate({ angle: 45 }).margin({ top: -2.5 })
      }
    } else if (type === 'list') {
      // 列表：三条横线
      Column({ space: 2 }) {
        Rect({ width: 13, height: 1.5 }).fill(color).borderRadius(0.75)
        Rect({ width: 13, height: 1.5 }).fill(color).borderRadius(0.75)
        Rect({ width: 10, height: 1.5 }).fill(color).borderRadius(0.75)
      }
    } else if (type === 'thermo') {
      // 温度计：细柱 + 底部圆环
      Column({ space: -1 }) {
        Rect({ width: 2.5, height: 9 }).fill(color).borderRadius(1.25)
        Circle({ width: 6, height: 6 }).fill(Color.Transparent).border({ width: 1.2, color: color })
      }
    } else if (type === 'humidity') {
      // 湿度：水滴形（小实心圆 + 尖顶）
      Column({ space: -1.5 }) {
        Rect({ width: 4, height: 4 }).fill(color).rotate({ angle: 45 }).margin({ bottom: -2 })
        Circle({ width: 7, height: 7 }).fill(color)
      }
    } else if (type === 'pin') {
      // 小型定位点（8px 实心圆）
      Circle({ width: 8, height: 8 }).fill(color)
    }
  }

  /**
   * 图标容器 — 在控制按钮中居中放置 MapIcon
   * 实际使用时图标跟随按钮一起被点击（pointerEvents 穿透）。
   */
  @Builder
  MapButtonWithIcon(iconType: string, isOn: boolean, action: () => void) {
    Stack({ alignContent: Alignment.Center }) {
      // 按钮底
      Column()
        .width(30)
        .height(30)
        .backgroundColor(isOn ? this.t().primary : this.t().bgCard)
        .borderRadius(this.t().radiusFull)
      // 图标（居中）
      this.MapIcon(iconType, isOn ? this.t().textOnPrimary : this.t().textTitle)
    }
    .width(30)
    .height(30)
    .margin({ top: 3, bottom: 3 })
    .onClick(() => { action(); })
  }

  /** 定位按钮点击处理（首次开启时提示用户授权） */
  private onLocationToggle(): void {
    this.enableMyLocation = !this.enableMyLocation;
    if (this.enableMyLocation) {
      try {
        promptAction.showToast({
          message: '已开启"我的位置"按钮，若未显示定位点请在系统设置授权定位权限',
          duration: 3000
        });
      } catch (e) {
        Logger.warn(TAG, `Toast 显示失败: ${JSON.stringify(e)}`);
      }
    }
  }

  /** 地图高度（宽屏填满，窄屏固定） */
  private getMapHeight(): number {
    // 宽屏填满父容器，传 0 让组件用 height('100%')
    // 窄屏由父容器 height('40%') 控制
    return 0;
  }

  // ==================== 列表面板（顶部状态筛选 + 告警排序 icon） ====================
  @Builder
  ListPanel() {
    Column() {
      // 状态筛选 Tab 行（横向可滚动，避免窄屏挤压）
      Scroll() {
        Row() {
          ForEach(this.getStatusFilterOptions(), (opt: StatusFilterOption) => {
            this.StatusFilterChip(opt)
          }, (opt: StatusFilterOption) => opt.value)
          Blank()
          // 告警排序 icon Toggle
          Stack({ alignContent: Alignment.Center }) {
            this.MapIcon('alert', this.alertSortEnabled ? this.t().warning : this.t().textSub)
          }
          .width(28)
          .height(28)
          .backgroundColor(this.alertSortEnabled ? this.t().bgCardLight : Color.Transparent)
          .borderRadius(this.t().radiusFull)
          .margin({ left: 8 })
          .onClick(() => {
            this.alertSortEnabled = !this.alertSortEnabled;
          })
        }
        .width('100%')
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
      .padding({ left: 12, right: 12, top: 8, bottom: 4 })

      // 列表标题
      Row() {
        Text('大棚列表').fontSize(this.t().fontMd).fontColor(this.t().textTitle).fontWeight(FontWeight.Bold)
        Blank()
        Text(`${this.getFilteredGreenhouses().length} / ${this.greenhouses.length}`)
          .fontSize(this.t().fontSm)
          .fontColor(this.t().textSub)
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 4, bottom: 6 })
      .alignItems(VerticalAlign.Center)

      // 可滚动列表
      Scroll() {
        Column() {
          ForEach(this.getFilteredGreenhouses(), (item: GreenhouseLocation) => {
            this.GreenhouseCard(item)
          }, (item: GreenhouseLocation) => item.id)
          Blank().height(60)
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
      .padding({ left: 12, right: 12 })
    }
    .width('100%')
    .height('100%')
  }

  /** 大棚卡片（紧凑版：点击触发 BottomSheet 详情，不再内联展开） */
  @Builder
  GreenhouseCard(item: GreenhouseLocation) {
    Row() {
      // 状态指示点
      Circle({ width: 10, height: 10 })
        .fill(this.getStatusColor(item.status))
        .border({ width: 2, color: this.t().textWhite })

      // 名称 + 状态
      Column() {
        Text(item.name)
          .fontSize(this.t().fontMd)
          .fontColor(item.id === this.selectedId ? this.t().primary : this.t().textTitle)
          .fontWeight(FontWeight.Medium)
        Text(item.status)
          .fontSize(this.t().fontXs)
          .fontColor(this.getStatusColor(item.status))
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 10 })

      // 告警徽标（无告警时不占位）
      if (item.alerts > 0) {
        Text(`${item.alerts}`)
          .fontSize(this.t().fontXs)
          .fontColor(this.t().textWhite)
          .backgroundColor(this.t().warning)
          .borderRadius(this.t().radiusFull)
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .margin({ right: 8 })
      }

      // 进入详情箭头
      Text('›')
        .fontSize(this.t().fontXl)
        .fontColor(this.t().textHint)
    }
    .width('100%')
    .padding(14)
    .alignItems(VerticalAlign.Center)
    .backgroundColor(item.id === this.selectedId ? this.t().bgCardLight : this.t().bgCard)
    .backdropBlur(this.t().blurAmount)
    .borderRadius(this.t().radiusMd)
    .margin({ bottom: 8 })
    .border({
      width: item.id === this.selectedId ? 1.5 : 1,
      color: item.id === this.selectedId ? this.t().primary : this.t().borderLight
    })
    .shadow({
      radius: this.t().shadowCardRadius,
      color: this.t().shadowCardColor,
      offsetX: 0,
      offsetY: this.t().shadowCardOffsetY
    })
    .onClick(() => {
      // 点击列表项 → 弹起 BottomSheet 详情
      this.selectedId = item.id;
      this.sheetItem = item;
      this.sheetVisible = true;
    })
  }

  /** BottomSheet 遮罩（点击关闭） */
  @Builder
  SheetBackdrop() {
    Column()
      .width('100%')
      .height('100%')
      .backgroundColor('#80000000')
      .onClick(() => {
        this.closeSheet();
      })
  }

  /** BottomSheet 半屏详情（点击列表项或地图 marker 触发） */
  @Builder
  BottomSheet(item: GreenhouseLocation) {
    Column() {
      // 拖拽指示器
      Row()
        .width(40)
        .height(4)
        .backgroundColor(this.t().textHint)
        .borderRadius(2)
        .margin({ top: 12, bottom: 12 })

      // 标题行：状态点 + 名称 + 关闭按钮
      Row() {
        Circle({ width: 10, height: 10 })
          .fill(this.getStatusColor(item.status))
          .border({ width: 2, color: this.t().textWhite })
        Text(item.name)
          .fontSize(this.t().fontXxl)
          .fontColor(this.t().textTitle)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 8 })
          .layoutWeight(1)
        Stack({ alignContent: Alignment.Center }) {
          this.MapIcon('close', this.t().textHint)
        }
        .width(28)
        .height(28)
        .onClick(() => {
          this.closeSheet();
        })
      }
      .width('100%')
      .padding({ left: 20, right: 20 })
      .alignItems(VerticalAlign.Center)

      // 状态标签
      Text(item.status)
        .fontSize(this.t().fontXs)
        .fontColor(this.t().textWhite)
        .backgroundColor(this.getStatusColor(item.status))
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .borderRadius(this.t().radiusFull)
        .margin({ top: 8, left: 20 })
        .alignSelf(ItemAlign.Start)

      // 统计三列
      Row() {
        Column() {
          Text(`${item.sensors}`).fontSize(this.t().fontMd).fontColor(this.t().info).fontWeight(FontWeight.Bold)
          Text('传感器').fontSize(this.t().fontXs).fontColor(this.t().textSub)
        }.layoutWeight(1).alignItems(HorizontalAlign.Center)
        Column() {
          Text(`${item.devices}`).fontSize(this.t().fontMd).fontColor(this.t().textBody).fontWeight(FontWeight.Bold)
          Text('设备').fontSize(this.t().fontXs).fontColor(this.t().textSub)
        }.layoutWeight(1).alignItems(HorizontalAlign.Center)
        Column() {
          Text(`${item.alerts}`)
            .fontSize(this.t().fontMd)
            .fontColor(item.alerts > 0 ? this.t().warning : this.t().textSub)
            .fontWeight(FontWeight.Bold)
          Text('告警').fontSize(this.t().fontXs).fontColor(this.t().textSub)
        }.layoutWeight(1).alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .padding({ top: 16, bottom: 16, left: 20, right: 20 })
      .border({ width: { top: 1, bottom: 1 }, color: this.t().borderLight })

      // 温湿度
      Row() {
        Column() {
          Row({ space: 3 }) {
            Stack({ alignContent: Alignment.Center }) {
              this.MapIcon('thermo', this.t().textSub)
            }
            .width(12).height(12)
            Text('温度').fontSize(this.t().fontXs).fontColor(this.t().textSub)
          }
          Row() {
            Text(item.status === '离线' ? '--' : `${item.temp.toFixed(1)}`)
              .fontSize(this.t().fontLg)
              .fontColor(this.t().textTitle)
              .fontWeight(FontWeight.Bold)
            Text('°C').fontSize(this.t().fontSm).fontColor(this.t().textSub).margin({ left: 2 })
          }
          .margin({ top: 4 })
          .alignItems(VerticalAlign.Bottom)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Column() {
          Row({ space: 3 }) {
            Stack({ alignContent: Alignment.Center }) {
              this.MapIcon('humidity', this.t().textSub)
            }
            .width(12).height(12)
            Text('湿度').fontSize(this.t().fontXs).fontColor(this.t().textSub)
          }
          Row() {
            Text(item.status === '离线' ? '--' : `${item.humidity.toFixed(0)}`)
              .fontSize(this.t().fontLg)
              .fontColor(this.t().textTitle)
              .fontWeight(FontWeight.Bold)
            Text('%').fontSize(this.t().fontSm).fontColor(this.t().textSub).margin({ left: 2 })
          }
          .margin({ top: 4 })
          .alignItems(VerticalAlign.Bottom)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .padding({ top: 12, bottom: 16, left: 20, right: 20 })

      // 经纬度
      Row({ space: 4 }) {
        Stack({ alignContent: Alignment.Center }) {
          this.MapIcon('pin', this.t().textHint)
        }
        .width(10).height(10)
        Text(`${item.lat.toFixed(4)}, ${item.lng.toFixed(4)}`)
          .fontSize(this.t().fontXs)
          .fontColor(this.t().textHint)
      }
      .padding({ left: 20, right: 20, bottom: 12 })

      // 查看完整详情按钮
      Text('查看完整详情')
        .fontSize(this.t().fontSm)
        .fontColor(this.t().textOnPrimary)
        .backgroundColor(this.t().primary)
        .borderRadius(this.t().radiusSm)
        .padding({ left: 16, right: 16, top: 10, bottom: 10 })
        .margin({ left: 20, right: 20, bottom: 20 })
        .alignSelf(ItemAlign.Stretch)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          this.closeSheet();
          this.navigateToDashboard(item.id);
        })
    }
    .width('100%')
    .height('55%')
    .backgroundColor(this.t().bgCard)
    .borderRadius({ topLeft: 20, topRight: 20 })
    .shadow({
      radius: this.t().shadowCardRadius * 2,
      color: this.t().shadowCardColor,
      offsetX: 0,
      offsetY: -2
    })
  }

  // ============ 辅助方法 ============

  /** 状态筛选选项 */
  private getStatusFilterOptions(): StatusFilterOption[] {
    const options: StatusFilterOption[] = [
      { label: '全部', value: 'all' },
      { label: '正常', value: 'normal' },
      { label: '告警', value: 'alert' },
      { label: '离线', value: 'offline' }
    ];
    return options;
  }

  /** 按筛选 + 搜索 + 排序获取列表 */
  private getFilteredGreenhouses(): GreenhouseLocation[] {
    let list: GreenhouseLocation[] = [];

    // 1. 状态筛选
    for (let i = 0; i < this.greenhouses.length; i++) {
      const g = this.greenhouses[i];
      if (this.matchesStatusFilter(g, this.statusFilter)) {
        list.push(g);
      }
    }

    // 2. 关键词搜索
    if (this.searchKeyword.length > 0) {
      const filtered: GreenhouseLocation[] = [];
      for (let i = 0; i < list.length; i++) {
        if (list[i].name.indexOf(this.searchKeyword) >= 0) {
          filtered.push(list[i]);
        }
      }
      list = filtered;
    }

    // 3. 告警排序（降序）
    if (this.alertSortEnabled) {
      list.sort((a: GreenhouseLocation, b: GreenhouseLocation) => {
        return b.alerts - a.alerts;
      });
    }

    return list;
  }

  /** 判断大棚是否匹配状态筛选 */
  private matchesStatusFilter(g: GreenhouseLocation, filter: StatusFilter): boolean {
    if (filter === 'all') {
      return true;
    }
    if (filter === 'normal') {
      return g.status === '运行正常';
    }
    if (filter === 'offline') {
      return g.status === '离线';
    }
    // alert：既非正常也非离线
    return g.status !== '运行正常' && g.status !== '离线';
  }

  /** 搜索关键词变化时联动地图（高亮首个匹配项） */
  private onSearchChange(keyword: string): void {
    if (keyword.length === 0) {
      return;
    }
    const filtered = this.getFilteredGreenhouses();
    if (filtered.length > 0) {
      this.selectedId = filtered[0].id;
    }
  }

  /** 跳转 DashboardPage（传 greenhouseId 占位） */
  private navigateToDashboard(greenhouseId: string): void {
    try {
      const stack = AppStorage.get<NavPathStack>('navPathStack');
      if (stack) {
        const param: GreenhouseNavParam = { greenhouseId: greenhouseId };
        stack.pushPath({ name: 'DashboardPage', param: param });
      }
    } catch (err) {
      Logger.warn(TAG, `路由跳转失败: ${JSON.stringify(err)}`);
    }
  }

  private getStatusColor(status: string): string {
    if (status === '运行正常') { return this.t().success; }
    if (status === '离线') { return this.t().textSub; }
    return this.t().warning;
  }

  private getTotalSensors(): number {
    let total: number = 0;
    for (let i = 0; i < this.greenhouses.length; i++) { total += this.greenhouses[i].sensors; }
    return total;
  }

  private getOnlineCount(): number {
    // IoT 离线时只有真实设备在线才是真在线，其余都是假数据
    if (!this.iotCheckDone || !this.isIotOnline) { return 0; }
    let count: number = 0;
    for (let i = 0; i < this.greenhouses.length; i++) {
      if (this.greenhouses[i].status !== '离线' && this.greenhouses[i].status !== 'IoT未连接') { count += 1; }
    }
    return count;
  }

  private getAlertGreenhouses(): number {
    let count: number = 0;
    for (let i = 0; i < this.greenhouses.length; i++) {
      if (this.greenhouses[i].alerts > 0) { count += 1; }
    }
    return count;
  }

  /** 关闭 BottomSheet 并清空当前展示项 */
  private closeSheet(): void {
    this.sheetVisible = false;
    this.sheetItem = MapPage.EMPTY_GREENHOUSE;
  }

  /** 根据 id 查找大棚数据（找不到返回 null） */
  private findGreenhouseById(id: string): GreenhouseLocation | null {
    for (let i = 0; i < this.greenhouses.length; i++) {
      if (this.greenhouses[i].id === id) {
        return this.greenhouses[i];
      }
    }
    return null;
  }

  /** 生成 Header chip 用的紧凑统计文案：「10/12 在线 · 2 告警」 */
  private getStatsSummary(): string {
    if (!this.iotCheckDone) {
      return `检测中...`;
    }
    if (!this.isIotOnline) {
      return `🔴 IoT 离线 · 无真实数据`;
    }
    const online: number = this.getOnlineCount();
    const alerts: number = this.getAlertGreenhouses();
    return `🟢 IoT 在线 · ${online}台 · ${alerts} 告警`;
  }
}

/** 状态筛选选项接口 */
interface StatusFilterOption {
  label: string;
  value: StatusFilter;
}
