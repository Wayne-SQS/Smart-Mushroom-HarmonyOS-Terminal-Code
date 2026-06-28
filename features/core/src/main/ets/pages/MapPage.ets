import { StyleConstants } from 'common-base';

/**
 * 地图监控页面
 *
 * 展示大棚在地图上的位置分布与交互
 * 后续集成 HMS Map Kit 实现真实地图
 * 当前为占位UI，预留地图接入点
 *
 * 交互能力：
 * 1. 顶部搜索栏过滤大棚名称
 * 2. 顶部统计条（总数/在线/告警/传感器总数）
 * 3. 占位地图：网格坐标系 + 大棚标记 + 选中态光环动画 + 比例尺
 * 4. 点击标记或列表卡片 → 同步 selectedId → 浮层详情卡片
 * 5. 详情卡片：名称/状态徽章 + 传感器/告警/设备 + 温湿度 2x2 mini grid + 查看详情按钮
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

  build() {
    Column() {
      this.HeaderSection()
      this.StatsBar()
      this.MapSection()
      this.GreenhouseList()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(StyleConstants.BG_PAGE)
  }

  @Builder
  HeaderSection() {
    Column() {
      Row() {
        Text('🗺')
          .fontSize(StyleConstants.FONT_XL)
        Text('地图监控')
          .fontSize(StyleConstants.FONT_XXL)
          .fontColor(StyleConstants.TEXT_WHITE)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 8 })
        Blank()
        Text(`${this.greenhouses.length} 个大棚`)
          .fontSize(StyleConstants.FONT_SM)
          .fontColor(StyleConstants.TEXT_WHITE_SUB)
      }
      .width('100%')

      Row() {
        Text('🔍')
          .fontSize(StyleConstants.FONT_MD)
        TextInput({ text: this.searchKeyword, placeholder: '搜索大棚名称' })
          .fontSize(StyleConstants.FONT_MD)
          .fontColor(StyleConstants.TEXT_TITLE)
          .placeholderColor(StyleConstants.TEXT_WHITE_SUB)
          .backgroundColor('#FFFFFF20')
          .borderRadius(StyleConstants.RADIUS_SM)
          .layoutWeight(1)
          .margin({ left: 8 })
          .height(36)
          .padding({ left: 10, right: 10 })
          .onChange((value: string) => {
            this.searchKeyword = value;
          })
      }
      .width('100%')
      .margin({ top: 10 })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .linearGradient({
      angle: 135,
      colors: [[StyleConstants.PRIMARY_DARK, 0.0], [StyleConstants.PRIMARY, 0.6], [StyleConstants.PRIMARY_LIGHT, 1.0]]
    })
  }

  @Builder
  StatsBar() {
    Row() {
      Column() {
        Text(`${this.greenhouses.length}`)
          .fontSize(StyleConstants.FONT_XL)
          .fontColor(StyleConstants.TEXT_TITLE)
          .fontWeight(FontWeight.Bold)
        Text('大棚总数')
          .fontSize(StyleConstants.FONT_SM)
          .fontColor(StyleConstants.TEXT_SUB)
          .margin({ top: 2 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)

      Divider().vertical(true).height(28).color(StyleConstants.BORDER_LIGHT)

      Column() {
        Text(`${this.getOnlineCount()}`)
          .fontSize(StyleConstants.FONT_XL)
          .fontColor(StyleConstants.SUCCESS)
          .fontWeight(FontWeight.Bold)
        Text('在线大棚')
          .fontSize(StyleConstants.FONT_SM)
          .fontColor(StyleConstants.TEXT_SUB)
          .margin({ top: 2 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)

      Divider().vertical(true).height(28).color(StyleConstants.BORDER_LIGHT)

      Column() {
        Text(`${this.getAlertGreenhouses()}`)
          .fontSize(StyleConstants.FONT_XL)
          .fontColor(StyleConstants.WARNING)
          .fontWeight(FontWeight.Bold)
        Text('告警大棚')
          .fontSize(StyleConstants.FONT_SM)
          .fontColor(StyleConstants.TEXT_SUB)
          .margin({ top: 2 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)

      Divider().vertical(true).height(28).color(StyleConstants.BORDER_LIGHT)

      Column() {
        Text(`${this.getTotalSensors()}`)
          .fontSize(StyleConstants.FONT_XL)
          .fontColor(StyleConstants.INFO)
          .fontWeight(FontWeight.Bold)
        Text('传感器总数')
          .fontSize(StyleConstants.FONT_SM)
          .fontColor(StyleConstants.TEXT_SUB)
          .margin({ top: 2 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .padding({ top: 14, bottom: 14 })
    .backgroundColor(StyleConstants.BG_CARD)
    .borderRadius(StyleConstants.RADIUS_LG)
    .margin({ top: 10, left: 12, right: 12 })
    .shadow({
      radius: StyleConstants.SHADOW_CARD_RADIUS,
      color: StyleConstants.SHADOW_CARD_COLOR,
      offsetX: 0,
      offsetY: StyleConstants.SHADOW_CARD_OFFSETY
    })
  }

  @Builder
  MapSection() {
    Stack({ alignContent: Alignment.Bottom }) {
      Stack() {
        // 模拟地图背景
        Column()
          .width('100%')
          .height('100%')
          .linearGradient({
            angle: 180,
            colors: [['#E8F5E9', 0.0], ['#C8E6C9', 0.5], ['#A5D6A7', 1.0]]
          })

        // 网格坐标系 - 横线
        Column() {
          ForEach([0, 1, 2, 3, 4, 5], () => {
            Row().width('100%').height(1).backgroundColor('#FFFFFF80')
          })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.SpaceEvenly)

        // 网格坐标系 - 竖线
        Row() {
          ForEach([0, 1, 2, 3, 4, 5, 6], () => {
            Column().width(1).height('100%').backgroundColor('#FFFFFF60')
          })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.SpaceEvenly)

        // 大棚标记点
        ForEach(this.getFilteredGreenhouses(), (item: GreenhouseLocation) => {
          this.Marker(item)
        }, (item: GreenhouseLocation) => item.id)

        // 比例尺指示器
        Row() {
          Column().width(2).height(8).backgroundColor(StyleConstants.TEXT_SUB)
          Column().width(56).height(2).backgroundColor(StyleConstants.TEXT_SUB)
          Column().width(2).height(8).backgroundColor(StyleConstants.TEXT_SUB)
          Text(' 50m')
            .fontSize(StyleConstants.FONT_XS)
            .fontColor(StyleConstants.TEXT_SUB)
        }
        .alignItems(VerticalAlign.Center)
        .position({ x: 12, y: 12 })

        // 底部提示（保留 HMS Map Kit 接入点）
        Row() {
          Text('📍 后续集成 HMS Map Kit')
            .fontSize(StyleConstants.FONT_XS)
            .fontColor(StyleConstants.TEXT_SUB)
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor('#FFFFFFCC')
            .borderRadius(StyleConstants.RADIUS_SM)
        }
        .position({ x: '50%', y: 12 })
        .translate({ x: '-50%' })
      }
      .width('100%')
      .height('100%')

      // 选中大棚的详情卡片浮层
      this.DetailCard(this.getSelectedGreenhouse())
    }
    .width('100%')
    .height(320)
    .margin({ top: 10, left: 12, right: 12 })
    .borderRadius(StyleConstants.RADIUS_LG)
    .clip(true)
    .backgroundColor(StyleConstants.BG_CARD_LIGHT)
  }

  @Builder
  Marker(item: GreenhouseLocation) {
    Stack() {
      // 选中态光环（动画）
      Circle({ width: 30, height: 30 })
        .fill(this.getStatusColor(item.status) + '40')
        .opacity(item.id === this.selectedId ? 1 : 0)
        .scale({ x: item.id === this.selectedId ? 1.4 : 1, y: item.id === this.selectedId ? 1.4 : 1 })
        .animation({ duration: 300, curve: Curve.EaseOut })

      // 标记圆点
      Circle({ width: 14, height: 14 })
        .fill(this.getStatusColor(item.status))
        .border({ width: 2, color: '#FFFFFF' })
        .scale({ x: item.id === this.selectedId ? 1.2 : 1, y: item.id === this.selectedId ? 1.2 : 1 })
        .animation({ duration: 200, curve: Curve.EaseOut })

      // 选中态名称标签
      if (item.id === this.selectedId) {
        Text(item.name)
          .fontSize(StyleConstants.FONT_XS)
          .fontColor(StyleConstants.TEXT_WHITE)
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .backgroundColor(StyleConstants.PRIMARY)
          .borderRadius(StyleConstants.RADIUS_SM)
          .position({ x: '50%', y: -22 })
          .translate({ x: '-50%' })
      }
    }
    .position({ x: `${item.x}%`, y: `${item.y}%` })
    .onClick(() => {
      this.selectedId = item.id;
    })
  }

  @Builder
  DetailCard(item: GreenhouseLocation) {
    if (item.id !== '') {
      Column() {
        Row() {
          Column() {
            Text(item.name)
              .fontSize(StyleConstants.FONT_LG)
              .fontColor(StyleConstants.TEXT_TITLE)
              .fontWeight(FontWeight.Bold)
            Row() {
              Circle({ width: 6, height: 6 })
                .fill(this.getStatusColor(item.status))
              Text(item.status)
                .fontSize(StyleConstants.FONT_XS)
                .fontColor(this.getStatusColor(item.status))
                .margin({ left: 4 })
            }
            .margin({ top: 4 })
            .alignItems(VerticalAlign.Center)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          // 查看详情按钮（预留 AppRouter.push 接入点）
          Text('查看详情')
            .fontSize(StyleConstants.FONT_SM)
            .fontColor(StyleConstants.TEXT_WHITE)
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .backgroundColor(StyleConstants.PRIMARY)
            .borderRadius(StyleConstants.RADIUS_SM)
            .onClick(() => {
              // AppRouter 位于 entry 模块，features/core 无法直接 import
              // 由容器层注入跳转回调，此处保留接入点
            })
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)

        // 传感器 / 告警 / 设备 数量
        Row() {
          Column() {
            Text(`${item.sensors}`)
              .fontSize(StyleConstants.FONT_MD)
              .fontColor(StyleConstants.INFO)
              .fontWeight(FontWeight.Bold)
            Text('传感器')
              .fontSize(StyleConstants.FONT_XS)
              .fontColor(StyleConstants.TEXT_HINT)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)

          Column() {
            Text(`${item.alerts}`)
              .fontSize(StyleConstants.FONT_MD)
              .fontColor(item.alerts > 0 ? StyleConstants.WARNING : StyleConstants.TEXT_HINT)
              .fontWeight(FontWeight.Bold)
            Text('告警')
              .fontSize(StyleConstants.FONT_XS)
              .fontColor(StyleConstants.TEXT_HINT)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)

          Column() {
            Text(`${item.devices}`)
              .fontSize(StyleConstants.FONT_MD)
              .fontColor(StyleConstants.TEXT_BODY)
              .fontWeight(FontWeight.Bold)
            Text('设备')
              .fontSize(StyleConstants.FONT_XS)
              .fontColor(StyleConstants.TEXT_HINT)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .margin({ top: 10 })

        // 温湿度 2x2 mini grid（标签行 + 数值行）
        Row() {
          // 温度列
          Column() {
            Text('🌡 温度')
              .fontSize(StyleConstants.FONT_XS)
              .fontColor(StyleConstants.TEXT_HINT)
            Row() {
              Text(item.status === '离线' ? '--' : `${item.temp.toFixed(1)}`)
                .fontSize(StyleConstants.FONT_LG)
                .fontColor(StyleConstants.COLOR_TEMP)
                .fontWeight(FontWeight.Bold)
              Text('°C')
                .fontSize(StyleConstants.FONT_SM)
                .fontColor(StyleConstants.TEXT_HINT)
                .margin({ left: 2 })
            }
            .margin({ top: 4 })
            .alignItems(VerticalAlign.Bottom)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          // 湿度列
          Column() {
            Text('💧 湿度')
              .fontSize(StyleConstants.FONT_XS)
              .fontColor(StyleConstants.TEXT_HINT)
            Row() {
              Text(item.status === '离线' ? '--' : `${item.humidity.toFixed(0)}`)
                .fontSize(StyleConstants.FONT_LG)
                .fontColor(StyleConstants.COLOR_HUMIDITY)
                .fontWeight(FontWeight.Bold)
              Text('%')
                .fontSize(StyleConstants.FONT_SM)
                .fontColor(StyleConstants.TEXT_HINT)
                .margin({ left: 2 })
            }
            .margin({ top: 4 })
            .alignItems(VerticalAlign.Bottom)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')
        .padding({ top: 10 })
        .border({ width: { top: 1 }, color: StyleConstants.BORDER_LIGHT })
        .margin({ top: 10 })
      }
      .width('100%')
      .padding(12)
      .backgroundColor(StyleConstants.BG_CARD)
      .borderRadius({ topLeft: StyleConstants.RADIUS_LG, topRight: StyleConstants.RADIUS_LG })
      .shadow({
        radius: StyleConstants.SHADOW_FLOAT_RADIUS,
        color: StyleConstants.SHADOW_FLOAT_COLOR,
        offsetX: 0,
        offsetY: StyleConstants.SHADOW_FLOAT_OFFSETY
      })
    }
  }

  @Builder
  GreenhouseList() {
    Column() {
      Row() {
        Text('大棚列表')
          .fontSize(StyleConstants.FONT_LG)
          .fontColor(StyleConstants.TEXT_TITLE)
          .fontWeight(FontWeight.Bold)
        Blank()
        Text(`${this.getFilteredGreenhouses().length} / ${this.greenhouses.length}`)
          .fontSize(StyleConstants.FONT_SM)
          .fontColor(StyleConstants.TEXT_HINT)
      }
      .width('100%')
      .margin({ bottom: 10 })
      .alignItems(VerticalAlign.Center)

      Scroll() {
        Column() {
          ForEach(this.getFilteredGreenhouses(), (item: GreenhouseLocation) => {
            this.GreenhouseCard(item)
          }, (item: GreenhouseLocation) => item.id)
          Blank().height(80)
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
    }
    .width('100%')
    .layoutWeight(1)
    .padding({ left: 12, right: 12, top: 12 })
  }

  @Builder
  GreenhouseCard(item: GreenhouseLocation) {
    Row() {
      // 状态色点
      Circle({ width: 10, height: 10 })
        .fill(this.getStatusColor(item.status))
        .border({ width: 2, color: '#FFFFFF' })

      // 大棚信息
      Column() {
        Text(item.name)
          .fontSize(StyleConstants.FONT_MD)
          .fontColor(item.id === this.selectedId ? StyleConstants.PRIMARY : StyleConstants.TEXT_TITLE)
          .fontWeight(FontWeight.Medium)
        Text(item.status)
          .fontSize(StyleConstants.FONT_XS)
          .fontColor(this.getStatusColor(item.status))
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 10 })

      // 传感器数
      Column() {
        Text(`${item.sensors}`)
          .fontSize(StyleConstants.FONT_LG)
          .fontColor(StyleConstants.INFO)
          .fontWeight(FontWeight.Bold)
        Text('传感器')
          .fontSize(StyleConstants.FONT_XS)
          .fontColor(StyleConstants.TEXT_HINT)
      }
      .margin({ right: 16 })
      .alignItems(HorizontalAlign.Center)

      // 告警数
      Column() {
        Text(`${item.alerts}`)
          .fontSize(StyleConstants.FONT_LG)
          .fontColor(item.alerts > 0 ? StyleConstants.WARNING : StyleConstants.TEXT_HINT)
          .fontWeight(FontWeight.Bold)
        Text('告警')
          .fontSize(StyleConstants.FONT_XS)
          .fontColor(StyleConstants.TEXT_HINT)
      }
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .padding(14)
    .alignItems(VerticalAlign.Center)
    .backgroundColor(item.id === this.selectedId ? StyleConstants.BG_CARD_LIGHT : StyleConstants.BG_CARD)
    .borderRadius(StyleConstants.RADIUS_MD)
    .margin({ bottom: 8 })
    .borderWidth(item.id === this.selectedId ? 1.5 : 0)
    .borderColor(item.id === this.selectedId ? StyleConstants.PRIMARY : StyleConstants.BG_CARD)
    .shadow({
      radius: 4,
      color: '#0A000000',
      offsetX: 0,
      offsetY: 1
    })
    .onClick(() => {
      this.selectedId = item.id;
    })
  }

  // ============ 私有方法 ============

  private getFilteredGreenhouses(): GreenhouseLocation[] {
    if (this.searchKeyword.length === 0) {
      return this.greenhouses;
    }
    return this.greenhouses.filter((g: GreenhouseLocation) => g.name.indexOf(this.searchKeyword) >= 0);
  }

  private getStatusColor(status: string): string {
    if (status === '运行正常') {
      return StyleConstants.SUCCESS;
    }
    if (status === '离线') {
      return StyleConstants.TEXT_HINT;
    }
    return StyleConstants.WARNING;
  }

  private getTotalSensors(): number {
    let total: number = 0;
    const list: GreenhouseLocation[] = this.greenhouses;
    for (let i = 0; i < list.length; i++) {
      total += list[i].sensors;
    }
    return total;
  }

  private getOnlineCount(): number {
    let count: number = 0;
    const list: GreenhouseLocation[] = this.greenhouses;
    for (let i = 0; i < list.length; i++) {
      if (list[i].status !== '离线') {
        count += 1;
      }
    }
    return count;
  }

  private getAlertGreenhouses(): number {
    let count: number = 0;
    const list: GreenhouseLocation[] = this.greenhouses;
    for (let i = 0; i < list.length; i++) {
      if (list[i].alerts > 0) {
        count += 1;
      }
    }
    return count;
  }

  private getSelectedGreenhouse(): GreenhouseLocation {
    const list: GreenhouseLocation[] = this.greenhouses;
    for (let i = 0; i < list.length; i++) {
      if (list[i].id === this.selectedId) {
        return list[i];
      }
    }
    // 兜底：返回空对象，避免 undefined 流入 UI（ArkTS 禁止 undefined 跨组件传递）
    return {
      id: '',
      name: '',
      status: '',
      sensors: 0,
      alerts: 0,
      devices: 0,
      temp: 0,
      humidity: 0,
      x: 0,
      y: 0
    };
  }
}
