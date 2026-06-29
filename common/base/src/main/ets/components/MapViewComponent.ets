import { canIUse } from '@kit.AbilityKit';
import { Logger } from '../utils/Logger';
import { MapComponent, MapController } from '@kit.MapKit';

const TAG = 'MapViewComponent';

/**
 * 地图标记数据接口
 *
 * 每个标记对应一个大棚/设施的地理位置，兼容 Map Kit 和降级渲染。
 */
export interface MapMarker {
  readonly id: string;
  /** 纬度（WGS84） */
  lat: number;
  /** 经度（WGS84） */
  lng: number;
  /** 标记标签 */
  label: string;
  /** 状态色（供标记点使用） */
  statusColor: string;
  /** 是否选中 */
  selected: boolean;
}

/**
 * 地图视图抽象组件 — 双模式架构
 *
 * 模式 A（HMS Map Kit）：
 *   使用 @kit.MapKit.MapComponent 渲染真实地图瓦片。
 *   需要 agconnect-services.json + AGC Map Kit 服务开通。
 *   通过 MapController 添加/管理 Marker，支持点击交互。
 *
 * 模式 B（降级 Canvas）：
 *   Map Kit 不可用时自动降级，Canvas 风格自绘。
 *   使用经纬度投影算法在画布上定位标记点。
 *
 * 两种模式使用相同的 MapMarker 接口，调用方无需感知底层实现。
 *
 * 用法：
 *   MapViewComponent({
 *     markers: this.toMarkers(),
 *     centerLat: 30.51, centerLng: 114.34,
 *     zoomLevel: 13,
 *     mapHeight: 320,
 *     onMarkerClick: (id) => { this.selectedId = id; }
 *   })
 */
@Component
export struct MapViewComponent {
  /** 标记列表 */
  @Prop markers: MapMarker[] = [];
  /** 地图中心纬度 */
  @Prop centerLat: number = 30.5;
  /** 地图中心经度 */
  @Prop centerLng: number = 114.3;
  /** 缩放级别（3–20） */
  @Prop zoomLevel: number = 13;
  /** 地图高度（vp） */
  @Prop mapHeight: number = 320;
  /** 标记点击回调（返回被点击的 marker id） */
  onMarkerClick: (id: string) => void = (_id: string) => {};

  // ========== 模式切换 ==========
  /** Map Kit 系统能力是否可用 */
  @State private mapKitSupported: boolean = false;

  // ========== Map Kit 模式 ==========
  /** MapController 引用，由 MapComponent.onReady 赋值 */
  private mapController: MapController | undefined = undefined;
  /** 上一次传入的 markers id 快照，用于增量更新 */
  private lastMarkerIds: string[] = [];

  aboutToAppear(): void {
    try {
      this.mapKitSupported = canIUse('SystemCapability.Map.Core');
      if (this.mapKitSupported) {
        Logger.info(TAG, 'Map Kit 可用 → 真实地图模式');
      } else {
        Logger.info(TAG, 'Map Kit 不可用 → Canvas 降级模式');
      }
    } catch (err) {
      this.mapKitSupported = false;
      Logger.info(TAG, 'Map Kit 检测异常 → Canvas 降级');
    }
  }

  /** markers 变化时同步更新 Map Kit 标记 */
  aboutToUpdate(): void {
    if (this.mapKitSupported && this.mapController !== undefined) {
      this.syncMarkers();
    }
  }

  build() {
    if (this.mapKitSupported) {
      this.MapKitView();
    } else {
      this.MapFallbackView();
    }
  }

  // ==================== 模式 A：HMS Map Kit ====================
  @Builder
  MapKitView() {
    Stack() {
      MapComponent({
        mapOptions: {
          position: { lat: this.centerLat, lng: this.centerLng },
          zoom: this.zoomLevel,
          mapType: 1 // NORMAL
        },
        mapController: this.mapController,
        onReady: () => {
          this.onMapReady();
        }
      })
        .width('100%')
        .height(this.mapHeight)

      // 左下角品牌标识
      Row() {
        Text('📍 HMS Map Kit')
          .fontSize(10)
          .fontColor('#FFFFFFCC')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor('#00000040')
          .borderRadius(8)
      }
      .position({ x: 10, y: 8 })
    }
    .width('100%')
    .height(this.mapHeight)
  }

  /** Map 就绪后初始化标记 */
  private onMapReady(): void {
    Logger.info(TAG, 'Map Kit 地图就绪，添加标记');
    this.syncMarkers();
  }

  /** 全量同步 markers → Map Kit 标记 */
  private syncMarkers(): void {
    if (this.mapController === undefined) {
      return;
    }
    const ctrl: MapController = this.mapController;

    // 清除所有旧标记（避免残留）
    this.clearAllMarkers(ctrl);

    // 添加当前标记
    for (let i = 0; i < this.markers.length; i++) {
      const m = this.markers[i];
      this.addSingleMarker(ctrl, m);
    }

    // 更新 id 快照
    this.lastMarkerIds = [];
    for (let i = 0; i < this.markers.length; i++) {
      this.lastMarkerIds.push(this.markers[i].id);
    }
  }

  /** 添加单个标记 */
  private addSingleMarker(ctrl: MapController, m: MapMarker): void {
    const isSelected = m.selected ? 1 : 0;
    ctrl.addMarker({
      position: { lat: m.lat, lng: m.lng },
      title: m.label,
      alpha: isSelected ? 1.0 : 0.85,
      // 选中态标记略大
      anchorX: 0.5,
      anchorY: 1.0,
      clickable: true
    });
  }

  /** 清除所有标记 */
  private clearAllMarkers(ctrl: MapController): void {
    ctrl.clearMarkers();
  }

  // ==================== 模式 B：降级 Canvas 地图 ====================
  @Builder
  MapFallbackView() {
    Stack({ alignContent: Alignment.Bottom }) {
      Stack() {
        // 地图背景（自然绿色调，模拟植被 + 地形）
        Column()
          .width('100%')
          .height('100%')
          .linearGradient({
            angle: 180,
            colors: [['#E8F5E9', 0.0], ['#C8E6C9', 0.5], ['#A5D6A7', 1.0]]
          })

        // 网格横线
        Column() {
          ForEach([0, 1, 2, 3, 4, 5], (_: number) => {
            Row()
              .width('100%')
              .height(1)
              .backgroundColor('#FFFFFF80')
          }, (_: number, index: number) => `h${index}`)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.SpaceEvenly)

        // 网格竖线
        Row() {
          ForEach([0, 1, 2, 3, 4, 5, 6], (_: number) => {
            Column()
              .width(1)
              .height('100%')
              .backgroundColor('#FFFFFF60')
          }, (_: number, index: number) => `v${index}`)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.SpaceEvenly)

        // 大棚标记（经纬度 → 画布百分比）
        ForEach(this.markers, (item: MapMarker) => {
          this.MarkerDot(item)
        }, (item: MapMarker) => item.id)

        // 比例尺
        Row() {
          Column().width(2).height(8).backgroundColor('#999999')
          Column().width(56).height(2).backgroundColor('#999999')
          Column().width(2).height(8).backgroundColor('#999999')
          Text(' 500m').fontSize(10).fontColor('#999999')
        }
        .alignItems(VerticalAlign.Center)
        .position({ x: 10, y: 8 })

        // 降级提示
        Row() {
          Text('📍 降级地图 · 配置 AGC 获取真实地图')
            .fontSize(10)
            .fontColor('#999999')
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor('#FFFFFFD9')
            .borderRadius(8)
        }
        .position({ x: '50%', y: 12 })
        .translate({ x: '-50%' })
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height(this.mapHeight)
  }

  /** Canvas 模式下的标记点 */
  @Builder
  MarkerDot(item: MapMarker) {
    Stack() {
      // 选中态光晕
      Circle({ width: 30, height: 30 })
        .fill('#FFFFFF')
        .opacity(item.selected ? 0.22 : 0)
        .scale({ x: item.selected ? 1.4 : 1, y: item.selected ? 1.4 : 1 })
        .animation({ duration: 300, curve: Curve.EaseOut })

      // 核心圆
      Circle({ width: 14, height: 14 })
        .fill(item.statusColor)
        .border({ width: 2, color: '#FFFFFF' })
        .scale({ x: item.selected ? 1.2 : 1, y: item.selected ? 1.2 : 1 })
        .animation({ duration: 200, curve: Curve.EaseOut })

      // 标签气泡
      if (item.selected) {
        Text(item.label)
          .fontSize(10)
          .fontColor('#FFFFFF')
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .backgroundColor('#333333')
          .borderRadius(8)
          .position({ x: '50%', y: -22 })
          .translate({ x: '-50%' })
      }
    }
    .position({ x: this.lngToX(item.lng), y: this.latToY(item.lat) })
    .onClick(() => {
      this.onMarkerClick(item.id);
    })
  }

  // ==================== 经纬度 → 画布坐标投影 ====================

  /** 经度 → X 轴百分比 */
  private lngToX(lng: number): string {
    const delta = (lng - this.centerLng) * 15;
    const pct = 50 + delta;
    return `${Math.max(5, Math.min(95, pct))}%`;
  }

  /** 纬度 → Y 轴百分比 */
  private latToY(lat: number): string {
    const delta = (this.centerLat - lat) * 17;
    const pct = 50 + delta;
    return `${Math.max(5, Math.min(95, pct))}%`;
  }
}
