import { ThemeManager } from '../theme/ThemeManager';
import { ThemeTokens } from '../theme/ThemeTokens';

/**
 * 地图监控页面 - 主题驱动
 * 当前为占位地图，后续集成 HMS Map Kit
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
  x: number;
  y: number;
}

@Component
export struct MapPage {
  @StorageLink('themeName') themeName: string = 'frosted';

  @State greenhouses: GreenhouseLocation[] = [
    { id: '1', name: '1号蘑菇大棚', status: '运行正常', sensors: 12, alerts: 0, devices: 8, temp: 22.5, humidity: 85, x: 25, y: 35 },
    { id: '2', name: '2号蘑菇大棚', status: '运行正常', sensors: 10, alerts: 0, devices: 6, temp: 21.8, humidity: 82, x: 55, y: 20 },
    { id: '3', name: '3号蘑菇大棚', status: 'CO₂偏高', sensors: 11, alerts: 2, devices: 7, temp: 24.1, humidity: 88, x: 40, y: 60 },
    { id: '4', name: '育种室', status: '运行正常', sensors: 6, alerts: 0, devices: 4, temp: 25.0, humidity: 70, x: 70, y: 50 },
    { id: '5', name: '5号实验棚', status: '温度偏低', sensors: 8, alerts: 1, devices: 5, temp: 14.2, humidity: 78, x: 20, y: 75 },
    { id: '6', name: '6号香菇棚', status: '运行正常', sensors: 9, alerts: 0, devices: 6, temp: 18.5, humidity: 80, x: 80, y: 75 },
    { id: '7', name: '7号金针菇棚', status: '运行正常', sensors: 7, alerts: 0, devices: 5, temp: 10.2, humidity: 90, x: 60, y: 80 },
    { id: '8', name: '菌种储存室', status: '离线', sensors: 4, alerts: 3, devices: 3, temp: 0, humidity: 0, x: 35, y: 15 }
  ];
  @State selectedId: string = '1';
  @State searchKeyword: string = '';

  t(): ThemeTokens {
    return ThemeManager.getInstance().getTokens();
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

  @Builder
  MapSection() {
    Stack({ alignContent: Alignment.Bottom }) {
      Stack() {
        // 模拟地图背景（固定自然绿色调，不随主题变化）
        Column()
          .width('100%')
          .height('100%')
          .linearGradient({
            angle: 180,
            colors: [['#E8F5E9', 0.0], ['#C8E6C9', 0.5], ['#A5D6A7', 1.0]]
          })

        // 网格横线
        Column() {
          ForEach([0, 1, 2, 3, 4, 5], () => {
            Row().width('100%').height(1).backgroundColor('#FFFFFF80')
          })
        }.width('100%').height('100%').justifyContent(FlexAlign.SpaceEvenly)

        // 网格竖线
        Row() {
          ForEach([0, 1, 2, 3, 4, 5, 6], () => {
            Column().width(1).height('100%').backgroundColor('#FFFFFF60')
          })
        }.width('100%').height('100%').justifyContent(FlexAlign.SpaceEvenly)

        // 大棚标记
        ForEach(this.getFilteredGreenhouses(), (item: GreenhouseLocation) => {
          this.Marker(item)
        }, (item: GreenhouseLocation) => item.id)

        // 比例尺
        Row() {
          Column().width(2).height(8).backgroundColor(this.t().textSub)
          Column().width(56).height(2).backgroundColor(this.t().textSub)
          Column().width(2).height(8).backgroundColor(this.t().textSub)
          Text(' 50m').fontSize(this.t().fontXs).fontColor(this.t().textSub)
        }.alignItems(VerticalAlign.Center).position({ x: 12, y: 12 })

        // 底部提示
        Row() {
          Text('📍 后续集成 HMS Map Kit')
            .fontSize(this.t().fontXs).fontColor(this.t().textSub)
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor(this.t().bgCard)
            .borderRadius(this.t().radiusSm)
        }.position({ x: '50%', y: 12 }).translate({ x: '-50%' })
      }
      .width('100%').height('100%')

      this.DetailCard(this.getSelectedGreenhouse())
    }
    .width('100%').height(320)
    .margin({ top: 10, left: 12, right: 12 })
    .borderRadius(this.t().radiusLg)
    .clip(true)
    .backgroundColor(this.t().bgCardLight)
  }

  @Builder
  Marker(item: GreenhouseLocation) {
    Stack() {
      // 选中态光环
      Circle({ width: 30, height: 30 })
        .fill(this.t().bgCardLight)
        .opacity(item.id === this.selectedId ? 1 : 0)
        .scale({ x: item.id === this.selectedId ? 1.4 : 1, y: item.id === this.selectedId ? 1.4 : 1 })
        .animation({ duration: 300, curve: Curve.EaseOut })

      Circle({ width: 14, height: 14 })
        .fill(this.getStatusColor(item.status))
        .border({ width: 2, color: this.t().textWhite })
        .scale({ x: item.id === this.selectedId ? 1.2 : 1, y: item.id === this.selectedId ? 1.2 : 1 })
        .animation({ duration: 200, curve: Curve.EaseOut })

      if (item.id === this.selectedId) {
        Text(item.name)
          .fontSize(this.t().fontXs).fontColor(this.t().textOnPrimary)
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .backgroundColor(this.t().primary)
          .borderRadius(this.t().radiusSm)
          .position({ x: '50%', y: -22 }).translate({ x: '-50%' })
      }
    }
    .position({ x: `${item.x}%`, y: `${item.y}%` })
    .onClick(() => { this.selectedId = item.id; })
  }

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
            .onClick(() => { /* AppRouter 接入点 */ })
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

  // ============ 私有方法 ============

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
    return { id: '', name: '', status: '', sensors: 0, alerts: 0, devices: 0, temp: 0, humidity: 0, x: 0, y: 0 };
  }
}
