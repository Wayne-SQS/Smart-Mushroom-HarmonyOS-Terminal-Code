import { MapViewComponent, MapMarker } from 'common-base';
import { ThemeManager } from '../theme/ThemeManager';
import { ThemeTokens } from '../theme/ThemeTokens';

/**
 * 地图监控页面 - HMS Map Kit + 降级双模式
 *
 * 坐标系统：
 *   - 使用 WGS84 真实经纬度（武汉及周边区域）
 *   - Map Kit 模式：直接渲染到真实地图
 *   - 降级模式：经纬度投影到 Canvas 画布百分比坐标
 *
 * 当 Map Kit 系统能力可用时自动使用真实地图；
 * 否则降级为自定义 Canvas 地图（无需 AGC 配置即可运行）。
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

@Component
export struct MapPage {
  @StorageLink('themeName') themeName: string = 'frosted';

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

  /** 地图中心（所有大棚的几何中心） */
  private mapCenterLat: number = 30.51;
  private mapCenterLng: number = 114.34;

  t(): ThemeTokens {
    return ThemeManager.getInstance().getTokens();
  }

  /** 将 GreenhouseLocation 转为 MapMarker */
  private toMapMarkers(): MapMarker[] {
    const result: MapMarker[] = [];
    for (let i = 0; i < this.greenhouses.length; i++) {
      const g = this.greenhouses[i];
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

  build() {
    Column() {
      this.HeaderSection()
      this.StatsBar()
      this.MapSection()
      this.GreenhouseList()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.t().bgPage)
  }

  @Builder
  HeaderSection() {
    Column() {
      Row() {
        Text('🗺').fontSize(this.t().fontXl)
        Text('地图监控')
          .fontSize(this.t().fontXxl)
          .fontColor(this.t().textWhite)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 8 })
        Blank()
        Text(`${this.greenhouses.length} 个大棚`)
          .fontSize(this.t().fontSm)
          .fontColor(this.t().textWhiteSub)
      }
      .width('100%')

      // 搜索栏
      Row() {
        Text('🔍').fontSize(this.t().fontMd)
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
          .onChange((value: string) => { this.searchKeyword = value; })
      }
      .width('100%')
      .margin({ top: 10 })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .linearGradient({
      angle: 135,
      colors: [[this.t().headerGradientTop, 0.0], [this.t().headerGradientBottom, 1.0]]
    })
  }

  @Builder
  StatsBar() {
    Row() {
      Column() {
        Text(`${this.greenhouses.length}`)
          .fontSize(this.t().fontXl).fontColor(this.t().textTitle).fontWeight(FontWeight.Bold)
        Text('大棚总数').fontSize(this.t().fontSm).fontColor(this.t().textSub).margin({ top: 2 })
      }.layoutWeight(1).alignItems(HorizontalAlign.Center)
      Divider().vertical(true).height(28).color(this.t().borderLight)
      Column() {
        Text(`${this.getOnlineCount()}`)
          .fontSize(this.t().fontXl).fontColor(this.t().success).fontWeight(FontWeight.Bold)
        Text('在线大棚').fontSize(this.t().fontSm).fontColor(this.t().textSub).margin({ top: 2 })
      }.layoutWeight(1).alignItems(HorizontalAlign.Center)
      Divider().vertical(true).height(28).color(this.t().borderLight)
      Column() {
        Text(`${this.getAlertGreenhouses()}`)
          .fontSize(this.t().fontXl).fontColor(this.t().warning).fontWeight(FontWeight.Bold)
        Text('告警大棚').fontSize(this.t().fontSm).fontColor(this.t().textSub).margin({ top: 2 })
      }.layoutWeight(1).alignItems(HorizontalAlign.Center)
      Divider().vertical(true).height(28).color(this.t().borderLight)
      Column() {
        Text(`${this.getTotalSensors()}`)
          .fontSize(this.t().fontXl).fontColor(this.t().info).fontWeight(FontWeight.Bold)
        Text('传感器总数').fontSize(this.t().fontSm).fontColor(this.t().textSub).margin({ top: 2 })
      }.layoutWeight(1).alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .padding({ top: 14, bottom: 14 })
    .backgroundColor(this.t().bgCard)
    .backdropBlur(this.t().blurAmount)
    .border({ width: 1, color: this.t().border })
    .borderRadius(this.t().radiusLg)
    .margin({ top: 10, left: 12, right: 12 })
    .shadow({
      radius: this.t().shadowCardRadius,
      color: this.t().shadowCardColor,
      offsetX: 0,
      offsetY: this.t().shadowCardOffsetY
    })
  }

  // ==================== 地图区域（Map Kit 自动切换） ====================
  @Builder
  MapSection() {
    Stack({ alignContent: Alignment.Bottom }) {
      MapViewComponent({
        markers: this.toMapMarkers(),
        centerLat: this.mapCenterLat,
        centerLng: this.mapCenterLng,
        zoomLevel: 13,
        mapHeight: 320,
        onMarkerClick: (id: string) => {
          this.selectedId = id;
        }
      })
        .width('100%')
        .height(320)
        .borderRadius(this.t().radiusLg)
        .clip(true)
        .backgroundColor(this.t().bgCardLight)

      // 底部详情卡片
      this.DetailCard(this.getSelectedGreenhouse())
    }
    .width('100%')
    .margin({ top: 10, left: 12, right: 12 })
  }

  // ==================== 选中大棚详情卡片 ====================
  @Builder
  DetailCard(item: GreenhouseLocation) {
    if (item.id !== '') {
      Column() {
        Row() {
          Column() {
            Text(item.name)
              .fontSize(this.t().fontLg).fontColor(this.t().textTitle).fontWeight(FontWeight.Bold)
            Row() {
              Circle({ width: 6, height: 6 }).fill(this.getStatusColor(item.status))
              Text(item.status)
                .fontSize(this.t().fontXs).fontColor(this.getStatusColor(item.status)).margin({ left: 4 })
            }.margin({ top: 4 }).alignItems(VerticalAlign.Center)
          }.alignItems(HorizontalAlign.Start).layoutWeight(1)

          Text('查看详情')
            .fontSize(this.t().fontSm).fontColor(this.t().textOnPrimary)
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .backgroundColor(this.t().primary).borderRadius(this.t().radiusSm)
            .onClick(() => { /* TODO: AppRouter 接入大棚详情页 */ })
        }.width('100%').alignItems(VerticalAlign.Top)

        Row() {
          Column() {
            Text(`${item.sensors}`).fontSize(this.t().fontMd).fontColor(this.t().info).fontWeight(FontWeight.Bold)
            Text('传感器').fontSize(this.t().fontXs).fontColor(this.t().textSub)
          }.layoutWeight(1).alignItems(HorizontalAlign.Center)
          Column() {
            Text(`${item.alerts}`)
              .fontSize(this.t().fontMd).fontColor(item.alerts > 0 ? this.t().warning : this.t().textSub).fontWeight(FontWeight.Bold)
            Text('告警').fontSize(this.t().fontXs).fontColor(this.t().textSub)
          }.layoutWeight(1).alignItems(HorizontalAlign.Center)
          Column() {
            Text(`${item.devices}`).fontSize(this.t().fontMd).fontColor(this.t().textBody).fontWeight(FontWeight.Bold)
            Text('设备').fontSize(this.t().fontXs).fontColor(this.t().textSub)
          }.layoutWeight(1).alignItems(HorizontalAlign.Center)
        }.width('100%').margin({ top: 10 })

        Row() {
          Column() {
            Text('🌡 温度').fontSize(this.t().fontXs).fontColor(this.t().textSub)
            Row() {
              Text(item.status === '离线' ? '--' : `${item.temp.toFixed(1)}`)
                .fontSize(this.t().fontLg).fontColor(this.t().textTitle).fontWeight(FontWeight.Bold)
              Text('°C').fontSize(this.t().fontSm).fontColor(this.t().textSub).margin({ left: 2 })
            }.margin({ top: 4 }).alignItems(VerticalAlign.Bottom)
          }.alignItems(HorizontalAlign.Start).layoutWeight(1)
          Column() {
            Text('💧 湿度').fontSize(this.t().fontXs).fontColor(this.t().textSub)
            Row() {
              Text(item.status === '离线' ? '--' : `${item.humidity.toFixed(0)}`)
                .fontSize(this.t().fontLg).fontColor(this.t().textTitle).fontWeight(FontWeight.Bold)
              Text('%').fontSize(this.t().fontSm).fontColor(this.t().textSub).margin({ left: 2 })
            }.margin({ top: 4 }).alignItems(VerticalAlign.Bottom)
          }.alignItems(HorizontalAlign.Start).layoutWeight(1)
        }.width('100%').padding({ top: 10 })
        .border({ width: { top: 1 }, color: this.t().borderLight }).margin({ top: 10 })
      }
      .width('100%').padding(12)
      .backgroundColor(this.t().bgCard)
      .borderRadius({ topLeft: this.t().radiusLg, topRight: this.t().radiusLg })
      .shadow({
        radius: this.t().shadowFloatRadius,
        color: this.t().shadowFloatColor,
        offsetX: 0,
        offsetY: this.t().shadowFloatOffsetY
      })
    }
  }

  // ==================== 大棚列表 ====================
  @Builder
  GreenhouseList() {
    Column() {
      Row() {
        Text('大棚列表').fontSize(this.t().fontLg).fontColor(this.t().textTitle).fontWeight(FontWeight.Bold)
        Blank()
        Text(`${this.getFilteredGreenhouses().length} / ${this.greenhouses.length}`)
          .fontSize(this.t().fontSm).fontColor(this.t().textSub)
      }.width('100%').margin({ bottom: 10 }).alignItems(VerticalAlign.Center)

      Scroll() {
        Column() {
          ForEach(this.getFilteredGreenhouses(), (item: GreenhouseLocation) => {
            this.GreenhouseCard(item)
          }, (item: GreenhouseLocation) => item.id)
          Blank().height(80)
        }.width('100%')
      }.layoutWeight(1).scrollBar(BarState.Auto)
    }
    .width('100%').layoutWeight(1)
    .padding({ left: 12, right: 12, top: 12 })
  }

  @Builder
  GreenhouseCard(item: GreenhouseLocation) {
    Row() {
      Circle({ width: 10, height: 10 })
        .fill(this.getStatusColor(item.status))
        .border({ width: 2, color: this.t().textWhite })

      Column() {
        Text(item.name)
          .fontSize(this.t().fontMd)
          .fontColor(item.id === this.selectedId ? this.t().primary : this.t().textTitle)
          .fontWeight(FontWeight.Medium)
        Text(item.status)
          .fontSize(this.t().fontXs).fontColor(this.getStatusColor(item.status)).margin({ top: 4 })
      }.alignItems(HorizontalAlign.Start).layoutWeight(1).margin({ left: 10 })

      Column() {
        Text(`${item.sensors}`).fontSize(this.t().fontLg).fontColor(this.t().info).fontWeight(FontWeight.Bold)
        Text('传感器').fontSize(this.t().fontXs).fontColor(this.t().textSub)
      }.margin({ right: 16 }).alignItems(HorizontalAlign.Center)

      Column() {
        Text(`${item.alerts}`)
          .fontSize(this.t().fontLg).fontColor(item.alerts > 0 ? this.t().warning : this.t().textSub).fontWeight(FontWeight.Bold)
        Text('告警').fontSize(this.t().fontXs).fontColor(this.t().textSub)
      }.alignItems(HorizontalAlign.Center)

      // 经纬度坐标展示
      Text(`📍`)
        .fontSize(this.t().fontXs).fontColor(this.t().textHint)
    }
    .width('100%').padding(14).alignItems(VerticalAlign.Center)
    .backgroundColor(item.id === this.selectedId ? this.t().bgCardLight : this.t().bgCard)
    .backdropBlur(this.t().blurAmount)
    .borderRadius(this.t().radiusMd)
    .margin({ bottom: 8 })
    .border({ width: item.id === this.selectedId ? 1.5 : 0, color: item.id === this.selectedId ? this.t().primary : 'transparent' })
    .shadow({
      radius: this.t().shadowCardRadius,
      color: this.t().shadowCardColor,
      offsetX: 0,
      offsetY: this.t().shadowCardOffsetY
    })
    .onClick(() => { this.selectedId = item.id; })
  }

  // ============ 辅助方法 ============

  private getFilteredGreenhouses(): GreenhouseLocation[] {
    if (this.searchKeyword.length === 0) { return this.greenhouses; }
    return this.greenhouses.filter((g: GreenhouseLocation) => g.name.indexOf(this.searchKeyword) >= 0);
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
    let count: number = 0;
    for (let i = 0; i < this.greenhouses.length; i++) {
      if (this.greenhouses[i].status !== '离线') { count += 1; }
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

  private getSelectedGreenhouse(): GreenhouseLocation {
    for (let i = 0; i < this.greenhouses.length; i++) {
      if (this.greenhouses[i].id === this.selectedId) { return this.greenhouses[i]; }
    }
    return { id: '', name: '', status: '', sensors: 0, alerts: 0, devices: 0, temp: 0, humidity: 0, lat: 0, lng: 0 };
  }
}
