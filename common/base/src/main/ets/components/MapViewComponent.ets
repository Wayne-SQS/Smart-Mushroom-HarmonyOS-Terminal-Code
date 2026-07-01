import { Logger } from '../utils/Logger';
import { MapComponent, map, mapCommon } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

const TAG = 'MapViewComponent';

/**
 * 地图标记数据接口
 */
export interface MapMarker {
  readonly id: string;
  lat: number;
  lng: number;
  label: string;
  statusColor: string;
  selected: boolean;
}

/**
 * Canvas 降级模式颜色配置
 */
export interface MapViewColors {
  bgGradientTop: string;
  bgGradientMid: string;
  bgGradientBottom: string;
  gridLine: string;
  metaText: string;
  metaBg: string;
  markerBorder: string;
  markerGlow: string;
  labelBg: string;
  labelText: string;
}

/**
 * 地图视图组件
 */
@Component
export struct MapViewComponent {
  @Prop @Watch('onMarkersChange') markers: MapMarker[] = [];
  @Prop centerLat: number = 30.5;
  @Prop centerLng: number = 114.3;
  @Prop mapHeight: number = 320;
  @Prop colors: MapViewColors | null = null;
  @Prop @Watch('onMapTypeChange') isSatellite: boolean = false;
  @Prop @Watch('onClusterToggle') enableCluster: boolean = false;
  @Prop @Watch('onMyLocationToggle') enableMyLocation: boolean = false;
  onMarkerClick: (id: string) => void = (_id: string) => {};

  /** 是否支持 Map Kit */
  @State private useMapKit: boolean = false;
  /** Map Kit 控制器 */
  private mapCtrl: map.MapComponentController | null = null;
  /** 已添加的 Marker 列表 */
  private markerList: map.Marker[] = [];
  /** Cluster overlay */
  private clusterOverlay: map.ClusterOverlay | null = null;

  /** ======== 地图初始化参数 ======== */
  private mapOpts: mapCommon.MapOptions = {
    position: {
      target: { latitude: 30.5, longitude: 114.3 },
      zoom: 12
    },
    mapType: mapCommon.MapType.STANDARD
  };

  /** ======== 地图就绪回调 ======== */
  private onMapReady: AsyncCallback<map.MapComponentController> =
    (err: Object, ctrl: map.MapComponentController) => {
      if (err) {
        Logger.error(TAG, `Map Kit 就绪失败: ${JSON.stringify(err)}`);
        this.useMapKit = false;
        return;
      }
      this.mapCtrl = ctrl;
      Logger.info(TAG, 'Map Kit 就绪成功');
      this.applyMapType();
      this.applyMyLocation();
      this.syncMarkers();
    };

  aboutToAppear(): void {
    try {
      this.useMapKit = canIUse('SystemCapability.Map.Core');
    } catch (e) {
      this.useMapKit = false;
    }
    this.mapOpts = {
      position: {
        target: { latitude: this.centerLat, longitude: this.centerLng },
        zoom: 12
      },
      mapType: mapCommon.MapType.STANDARD
    };
    Logger.info(TAG, this.useMapKit ? 'Map Kit 模式' : 'Canvas 降级模式');
  }

  build() {
    if (this.useMapKit) {
      Column() {
        MapComponent({
          mapOptions: this.mapOpts,
          mapCallback: this.onMapReady
        })
          .width('100%')
          .height(this.getH())
      }
      .width('100%')
      .height(this.getH())
    } else {
      this.CanvasView();
    }
  }

  // ==================== Canvas 降级 ====================
  @Builder
  CanvasView() {
    Stack({ alignContent: Alignment.Bottom }) {
      Stack() {
        Column()
          .width('100%')
          .height('100%')
          .linearGradient({
            angle: 180,
            colors: [
              [this.c('bgGradientTop', '#E8F5E9'), 0.0],
              [this.c('bgGradientMid', '#C8E6C9'), 0.5],
              [this.c('bgGradientBottom', '#A5D6A7'), 1.0]
            ]
          })
        Column() {
          ForEach([0, 1, 2, 3, 4, 5], (_: number) => {
            Row().width('100%').height(1).backgroundColor(this.c('gridLine', '#FFFFFF80'))
          }, (_: number, i: number) => `h${i}`)
        }.width('100%').height('100%').justifyContent(FlexAlign.SpaceEvenly)
        Row() {
          ForEach([0, 1, 2, 3, 4, 5, 6], (_: number) => {
            Column().width(1).height('100%').backgroundColor(this.c('gridLine', '#FFFFFF60'))
          }, (_: number, i: number) => `v${i}`)
        }.width('100%').height('100%').justifyContent(FlexAlign.SpaceEvenly)
        ForEach(this.markers, (item: MapMarker) => {
          this.Dot(item)
        }, (item: MapMarker) => item.id)
        Row() {
          Column().width(2).height(8).backgroundColor(this.c('metaText', '#999'))
          Column().width(56).height(2).backgroundColor(this.c('metaText', '#999'))
          Column().width(2).height(8).backgroundColor(this.c('metaText', '#999'))
          Text(' 500m').fontSize(10).fontColor(this.c('metaText', '#999'))
        }.alignItems(VerticalAlign.Center).position({ x: 10, y: 8 })
        Row() {
          Text('Canvas 降级地图').fontSize(10).fontColor(this.c('metaText', '#999'))
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor(this.c('metaBg', '#FFFFFFD9')).borderRadius(8)
        }.position({ x: '50%', y: 12 }).translate({ x: '-50%' })
      }.width('100%').height('100%')
    }.width('100%').height(this.getH())
  }

  /**
   * 精致微型 3D 图钉标点
   *
   * 结构（从底到顶）：
   *   - 图钉尖：3.5px 旋转方块 → 只露下半三角（被上方圆遮住上半）
   *   - 实心主体：6px statusColor 填充圆 + 1px 白边框
   *   - 暗部月牙：4px 半透明黑圆偏右下 → 模拟球体阴影（立体感）
   *   - 高光点：1.5px 白色半透明圆偏左上 → 模拟镜面反射（玻璃质感）
   *   - 地面投影：.shadow() 下沉 1.5px → 悬浮立体感
   *   - 选中光晕：14px 半透明白色圆（仅选中可见）
   *   - 标签：选中时显示在标点上方 12px 处
   *
   * 总尺寸约 8×10px（主体 6px + 尖 3px），比原来 11-18px 缩小约 45%
   */
  @Builder
  Dot(item: MapMarker) {
    Stack({ alignContent: Alignment.Center }) {
      // ---- 选中光晕（最底层）----
      Circle({ width: 14, height: 14 })
        .fill(this.c('markerGlow', '#FFFFFF'))
        .opacity(item.selected ? 0.3 : 0)
        .scale({ x: item.selected ? 1.45 : 1, y: item.selected ? 1.45 : 1 })
        .animation({ duration: 300, curve: Curve.EaseOut })

      // ---- 图钉主体（圆 + 三角尖）----
      Column({ space: -2 }) {
        // 圆主体：底部阴影 → 实色圆 → 高光
        Stack({ alignContent: Alignment.Center }) {
          // 暗部月牙 - 偏右下制造球体立体感
          Circle({ width: 4.5, height: 4.5 })
            .fill('#000000')
            .opacity(0.1)
            .position({ x: 0.6, y: 0.8 })
          // 实心主体
          Circle({ width: 6, height: 6 })
            .fill(item.statusColor)
            .border({ width: 1, color: this.c('markerBorder', '#FFFFFF') })
          // 高光 - 偏左上
          Circle({ width: 1.5, height: 1.5 })
            .fill('#FFFFFF')
            .opacity(0.6)
            .position({ x: -1, y: -1.2 })
        }
        // 图钉三角尖（菱形上半被圆遮住，只露下半 = 三角尖）
        Rect({ width: 3.5, height: 3.5 })
          .fill(item.statusColor)
          .rotate({ angle: 45 })
      }
      .scale({ x: item.selected ? 1.2 : 1, y: item.selected ? 1.2 : 1 })
      .animation({ duration: 200, curve: Curve.EaseOut })
      // 地面投影 → 立体悬浮
      .shadow({ radius: 3, color: '#00000025', offsetX: 0, offsetY: 1.5 })

      // ---- 标签（选中时显示在标点上方）----
      if (item.selected) {
        Text(item.label)
          .fontSize(8)
          .fontColor(this.c('labelText', '#FFFFFF'))
          .padding({ left: 4, right: 4, top: 1.5, bottom: 1.5 })
          .backgroundColor(this.c('labelBg', '#333333'))
          .borderRadius(5)
          .position({ x: 0, y: -13 })
      }
    }
    .position({ x: this.lngX(item.lng), y: this.latY(item.lat) })
    .translate({ x: '-50%', y: '-50%' })
    .onClick(() => { this.onMarkerClick(item.id); })
  }

  // ==================== Map Kit 功能 ====================

  private applyMapType(): void {
    if (!this.mapCtrl) { return; }
    try {
      this.mapCtrl.setMapType(
        this.isSatellite ? mapCommon.MapType.SATELLITE : mapCommon.MapType.STANDARD
      );
    } catch (e) {
      Logger.warn(TAG, `setMapType 失败: ${JSON.stringify(e)}`);
    }
  }

  private applyMyLocation(): void {
    if (!this.mapCtrl) { return; }
    try {
      this.mapCtrl.setMyLocationEnabled(this.enableMyLocation);
      this.mapCtrl.setMyLocationControlsEnabled(this.enableMyLocation);
    } catch (e) {
      Logger.warn(TAG, `setMyLocation 失败: ${JSON.stringify(e)}`);
    }
  }

  private async syncMarkers(): Promise<void> {
    if (!this.mapCtrl) { return; }
    // 清旧
    for (let i = 0; i < this.markerList.length; i++) {
      try { this.markerList[i].remove(); } catch (e) { /* ignore */ }
    }
    this.markerList = [];
    if (this.clusterOverlay) {
      try { this.clusterOverlay.remove(); } catch (e) { /* ignore */ }
      this.clusterOverlay = null;
    }
    // Cluster 路径
    if (this.enableCluster) {
      const items: mapCommon.ClusterItem[] = [];
      for (let i = 0; i < this.markers.length; i++) {
        items.push({ position: { latitude: this.markers[i].lat, longitude: this.markers[i].lng } });
      }
      try {
        this.clusterOverlay = await this.mapCtrl.addClusterOverlay({ distance: 60, clusterItems: items });
      } catch (e) {
        Logger.warn(TAG, `Cluster 失败: ${JSON.stringify(e)}`);
      }
      return;
    }
    // Marker 路径
    for (let i = 0; i < this.markers.length; i++) {
      const m = this.markers[i];
      try {
        const mk = await this.mapCtrl.addMarker({
          position: { latitude: m.lat, longitude: m.lng },
          clickable: true,
          title: m.label
        });
        if (mk) { this.markerList.push(mk); }
      } catch (e) {
        Logger.warn(TAG, `Marker 失败: ${JSON.stringify(e)}`);
      }
    }
  }

  // ======== @Watch 回调 ========
  onMarkersChange(_p: string): void { this.syncMarkers(); }
  onMapTypeChange(_p: string): void { this.applyMapType(); }
  onClusterToggle(_p: string): void { this.syncMarkers(); }
  onMyLocationToggle(_p: string): void { this.applyMyLocation(); }

  // ======== 工具方法 ========
  private c(key: string, fallback: string): string {
    if (!this.colors) { return fallback; }
    switch (key) {
      case 'bgGradientTop': return this.colors.bgGradientTop;
      case 'bgGradientMid': return this.colors.bgGradientMid;
      case 'bgGradientBottom': return this.colors.bgGradientBottom;
      case 'gridLine': return this.colors.gridLine;
      case 'metaText': return this.colors.metaText;
      case 'metaBg': return this.colors.metaBg;
      case 'markerBorder': return this.colors.markerBorder;
      case 'markerGlow': return this.colors.markerGlow;
      case 'labelBg': return this.colors.labelBg;
      case 'labelText': return this.colors.labelText;
      default: return fallback;
    }
  }
  private getH(): Length { return this.mapHeight > 0 ? this.mapHeight : '100%'; }
  private lngX(lng: number): string {
    const p = 50 + (lng - this.centerLng) * 15;
    return `${Math.max(5, Math.min(95, p))}%`;
  }
  private latY(lat: number): string {
    const p = 50 + (this.centerLat - lat) * 17;
    return `${Math.max(5, Math.min(95, p))}%`;
  }
}
