import { canIUse } from '@kit.AbilityKit';
import { MapComponent } from '@kit.MapKit';
import { Logger } from '../utils/Logger';

const TAG = 'MapViewComponent';

/**
 * 地图标记数据接口
 *
 * 每个标记对应一个大棚/设施的地理位置，兼容 HMS Map Kit 和降级渲染。
 */
export interface MapMarker {
  readonly id: string;
  /** 纬度 */
  lat: number;
  /** 经度 */
  lng: number;
  /** 标记标签 */
  label: string;
  /** 状态色（供标记点使用） */
  statusColor: string;
  /** 是否选中 */
  selected: boolean;
}

/**
 * 地图视图抽象组件
 *
 * 双模式架构：
 *   - 模式 A（HMS Map Kit）：canIUse('SystemCapability.Map.Core') 为 true 时启用，
 *     使用 @kit.MapKit.MapComponent 渲染真实地图，需要 agconnect-services.json
 *   - 模式 B（降级 Canvas）：Map Kit 不可用时自动降级，Canvas 风格自绘（经纬度投影）
 *
 * 两种模式使用相同的 MapMarker 接口，调用方无需感知底层实现。
 *
 * 用法：
 *   MapViewComponent({
 *     markers: this.mapMarkers,
 *     centerLat: 30.5, centerLng: 114.3,
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
  /** 缩放级别（3-20，仅 Map Kit 模式生效） */
  @Prop zoomLevel: number = 13;
  /** 地图高度（vp） */
  @Prop mapHeight: number = 320;
  /** 标记点击回调 */
  onMarkerClick: (id: string) => void = (_id: string) => {};

  /** Map Kit 系统能力是否可用 */
  @State private mapKitSupported: boolean = false;

  aboutToAppear(): void {
    // 运行时检测 Map Kit 系统能力
    try {
      this.mapKitSupported = canIUse('SystemCapability.Map.Core');
      if (this.mapKitSupported) {
        Logger.info(TAG, 'Map Kit 系统能力可用，使用真实地图');
      } else {
        Logger.info(TAG, 'Map Kit 不可用，降级为 Canvas 地图');
      }
    } catch (err) {
      this.mapKitSupported = false;
      Logger.info(TAG, 'Map Kit 检测异常，降级为 Canvas 地图');
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
      // 使用系统 Map 组件渲染真实地图
      MapComponent({
        mapOptions: {
          position: { lat: this.centerLat, lng: this.centerLng },
          zoom: this.zoomLevel,
          mapType: 1 // NORMAL
        },
        mapController: undefined
      })
        .width('100%')
        .height(this.mapHeight)

      // 品牌标识
      Row() {
        Text('📍 HMS Map Kit')
          .fontSize(10)
          .fontColor('#FFFFFFCC')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor('#00000040')
          .borderRadius(8)
      }
      .position({ x: 12, y: 8 })
    }
    .width('100%')
    .height(this.mapHeight)
  }

  // ==================== 模式 B：降级 Canvas 地图 ====================
  @Builder
  MapFallbackView() {
    Stack({ alignContent: Alignment.Bottom }) {
      Stack() {
        // 地图背景（固定自然绿色调，不随主题变化）
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

        // 大棚标记（经纬度 → 画布相对位置）
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
        .position({ x: 12, y: 8 })

        // 底部降级提示
        Row() {
          Text('📍 降级地图 — 配置 AGC 后启用 HMS Map Kit')
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
      // 选中态光环
      Circle({ width: 30, height: 30 })
        .fill('#FFFFFF')
        .opacity(item.selected ? 0.15 : 0)
        .scale({ x: item.selected ? 1.4 : 1, y: item.selected ? 1.4 : 1 })
        .animation({ duration: 300, curve: Curve.EaseOut })

      // 标记核心圆
      Circle({ width: 14, height: 14 })
        .fill(item.statusColor)
        .border({ width: 2, color: '#FFFFFF' })
        .scale({ x: item.selected ? 1.2 : 1, y: item.selected ? 1.2 : 1 })
        .animation({ duration: 200, curve: Curve.EaseOut })

      // 选中时显示标签
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

  // ==================== 经纬度 → 画布坐标投影（降级用） ====================

  /**
   * 经度 → X 轴百分比
   *
   * 以 centerLng 为中心，将经纬度差值映射为画布百分比坐标。
   * 1 度经度约等于画布宽度的 15%（zoom 模拟）。
   */
  private lngToX(lng: number): string {
    const delta = (lng - this.centerLng) * 15;
    const pct = 50 + delta;
    return `${Math.max(5, Math.min(95, pct))}%`;
  }

  /**
   * 纬度 → Y 轴百分比
   *
   * 以 centerLat 为中心（注意：纬度向上减小 → Y 向下增大，取反）。
   */
  private latToY(lat: number): string {
    const delta = (this.centerLat - lat) * 17;
    const pct = 50 + delta;
    return `${Math.max(5, Math.min(95, pct))}%`;
  }
}
