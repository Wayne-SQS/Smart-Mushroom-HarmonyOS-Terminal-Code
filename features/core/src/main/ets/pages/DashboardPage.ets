import { StyleConstants, SensorType, SensorConfigUtil, BreakpointConstants, AdaptiveUtils, Logger, BarChartComponent, ChartPoint } from 'common-base';
import { SensorDataItem, AlertItem, ControlItem } from '../model/GreenhouseModel';
import { DashboardViewModel } from '../viewmodel/DashboardViewModel';
import { AlertViewModel } from '../viewmodel/AlertViewModel';
import promptAction from '@ohos.promptAction';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = 'DashboardPage';

/**
 * 首页 - 大棚环境仪表盘
 *
 * 数据驱动：
 * - @State 初始化为空，aboutToAppear 同步 viewModel mock 数据避免首帧空白
 * - 异步加载云端属性，成功后覆盖 mock，失败保持 mock
 * - 概览卡片由 @State overview* 字段驱动（来自 viewModel.overview）
 * - 告警由 AlertViewModel.loadFromSensors 从 sensors 派生，Page 不再持有硬编码 alerts
 *
 * 响应式：GridRow/GridCol 适配多端断点
 */
@Component
export struct DashboardPage {
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointConstants.SM;
  @State greenhouseName: string = '1号蘑菇大棚';
  @State greenhouseStatus: string = '运行正常';
  @State weather: string = '多云 18°C';
  @State activeAlerts: number = 0;

  // 传感器 / 控制 / 告警：初始为空，aboutToAppear 同步 mock
  @State sensors: SensorDataItem[] = [];
  @State controls: ControlItem[] = [];
  @State alerts: AlertItem[] = [];

  // 概览统计：由 viewModel.overview 同步
  @State overviewOnline: number = 0;
  @State overviewYield: string = '--';
  @State overviewBatches: number = 0;

  // 24h 趋势数据（mock 演示，可后续接入历史接口）
  @State trendData: ChartPoint[] = [];

  private viewModel: DashboardViewModel = new DashboardViewModel();
  private alertViewModel: AlertViewModel = new AlertViewModel();

  aboutToAppear(): void {
    // 1. 同步 mock 数据，避免首帧空白
    this.sensors = [...this.viewModel.sensors];
    this.controls = [...this.viewModel.controls];
    this.syncOverview();
    this.syncAlerts();
    this.buildTrendData();
    // 2. 异步加载云端属性
    this.loadFromViewModel();
  }

  private async loadFromViewModel(): Promise<void> {
    try {
      await this.viewModel.loadData();
      this.sensors = [...this.viewModel.sensors];
      this.controls = [...this.viewModel.controls];
      this.syncOverview();
      this.syncAlerts();
      Logger.info(TAG, '仪表盘数据加载完成');
    } catch (err) {
      Logger.warn(TAG, '数据加载失败，使用 mock 数据');
    }
  }

  private syncOverview(): void {
    this.overviewOnline = this.viewModel.overview.onlineDevices;
    this.overviewYield = this.viewModel.overview.todayYield;
    this.overviewBatches = this.viewModel.overview.currentBatches;
  }

  /** 从 sensors 派生告警，更新 activeAlerts 计数 */
  private syncAlerts(): void {
    this.alertViewModel.loadFromSensors(this.viewModel.sensors);
    this.alerts = [...this.alertViewModel.alerts];
    this.activeAlerts = this.alerts.length;
  }

  /** 构造 24h 趋势 mock 数据（取当前温度上下浮动） */
  private buildTrendData(): void {
    const baseTemp = this.sensors.length > 0 ? this.sensors[0].value : 22;
    const points: ChartPoint[] = [];
    for (let i = 0; i < 12; i++) {
      const variation = Math.sin(i * 0.6) * 3 + (i % 3) - 1;
      points.push({ label: (i * 2) + 'h', value: Math.round((baseTemp + variation) * 10) / 10 });
    }
    this.trendData = points;
  }

  private async onControlToggle(item: ControlItem): Promise<void> {
    const newActive: boolean = !item.active;
    // 乐观更新 UI
    const updated: ControlItem[] = this.controls.map((c: ControlItem) => {
      if (c.id === item.id) {
        return { id: c.id, name: c.name, icon: c.icon, active: newActive, color: c.color };
      }
      return c;
    });
    this.controls = updated;

    // 显示操作中提示
    promptAction.showToast({
      message: `正在${newActive ? '开启' : '关闭'}${item.name}...`,
      duration: 1000
    });

    // 调用 ViewModel 下发命令
    await this.viewModel.refreshControl(item.id, newActive);

    // 同步结果（成功保持 / 失败回滚）
    this.controls = [...this.viewModel.controls];

    if (this.viewModel.errorMsg.length > 0) {
      promptAction.showToast({
        message: `${item.name}${newActive ? '开启' : '关闭'}失败`,
        duration: 2000
      });
      Logger.warn(TAG, '控制下发失败：' + this.viewModel.errorMsg);
    } else {
      promptAction.showToast({
        message: `${item.name}已${newActive ? '开启' : '关闭'}`,
        duration: 1500
      });
    }
  }

  private onAlertClick(): void {
    try {
      const stack = AppStorage.get<NavPathStack>('navPathStack');
      if (stack) {
        stack.pushPath({ name: 'AlertPage' });
      }
    } catch (err) {
      Logger.warn(TAG, '路由跳转失败');
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
    } else {
      Column() {
        this.ContentBody()
      }
      .width('100%')
      .height('100%')
    }
  }

  @Builder
  ContentBody() {
    this.HeaderSection()
    Scroll() {
      Column() {
        this.OverviewCard()
        this.SensorGrid()
        this.TrendSection()
        this.QuickControlSection()
        this.AlertSection()
        Blank().height(80)
      }
      .width('100%')
      .padding({ left: this.getPagePadding(), right: this.getPagePadding() })
    }
    .layoutWeight(1)
    .scrollBar(BarState.Auto)
    .backgroundColor(StyleConstants.BG_PAGE)
  }

  private getPagePadding(): number {
    return AdaptiveUtils.getPagePadding(this.currentBreakpoint);
  }

  /** 是否需要内容限宽（大屏） */
  private shouldLimitWidth(): boolean {
    return AdaptiveUtils.getMaxContentWidth(this.currentBreakpoint) > 0;
  }

  /** XL 屏限宽居中 */
  private getContentWidth(): string {
    const max = AdaptiveUtils.getMaxContentWidth(this.currentBreakpoint);
    return max > 0 ? max.toString() : '100%';
  }

  private getSensorSpan(): number {
    const cols: number = AdaptiveUtils.getSensorColumns(this.currentBreakpoint);
    // 总列数 12 列，每个传感器卡片占 12/cols 列
    return Math.floor(12 / cols);
  }

  // ==================== 顶部 Header ====================
  @Builder
  HeaderSection() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column()
        .width('100%')
        .height(180)
        .linearGradient({
          angle: 135,
          colors: [[StyleConstants.PRIMARY_DARK, 0.0], [StyleConstants.PRIMARY, 0.5], ['#388E3C', 1.0]]
        })

      Column() {
        Blank().height(44)

        Row() {
          Column() {
            Text(this.greenhouseName)
              .fontSize(StyleConstants.FONT_XL)
              .fontColor(StyleConstants.TEXT_WHITE)
              .fontWeight(FontWeight.Bold)
            Row() {
              Circle({ width: 8, height: 8 })
                .fill(StyleConstants.SUCCESS)
                .shadow({ radius: 4, color: StyleConstants.SUCCESS, offsetX: 0, offsetY: 0 })
              Text(this.greenhouseStatus)
                .fontSize(StyleConstants.FONT_SM)
                .fontColor(StyleConstants.TEXT_WHITE_SUB)
                .margin({ left: 6 })
            }
            .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Start)

          Blank()

          Column() {
            Text('☁').fontSize(28)
            Text(this.weather)
              .fontSize(StyleConstants.FONT_SM)
              .fontColor(StyleConstants.TEXT_WHITE_SUB)
              .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .padding({ left: 20, right: 20 })

        if (this.activeAlerts > 0) {
          Row() {
            Text('⚠').fontSize(14).fontColor(StyleConstants.WARNING)
            Text(`${this.activeAlerts}条待处理告警`)
              .fontSize(StyleConstants.FONT_SM)
              .fontColor(StyleConstants.TEXT_WHITE)
              .margin({ left: 6 })
            Blank()
            Text('查看 >')
              .fontSize(StyleConstants.FONT_SM)
              .fontColor(StyleConstants.TEXT_WHITE_SUB)
          }
          .width('100%')
          .height(36)
          .padding({ left: 16, right: 16 })
          .margin({ top: 12 })
          .backgroundColor('#FFFFFF20')
          .borderRadius(StyleConstants.RADIUS_SM)
          .onClick(() => {
            this.onAlertClick();
          })
        }
      }
      .width('100%')
    }
    .width('100%')
    .height(180)
  }

  // ==================== 概览卡片 ====================
  @Builder
  OverviewCard() {
    Row() {
      this.OverviewMetric('📡', this.overviewOnline.toString(), '在线设备', StyleConstants.PRIMARY)
      Divider().vertical(true).height(36).color(StyleConstants.BORDER_LIGHT)
      this.OverviewMetric('🍄', this.overviewYield, '今日采收', StyleConstants.ACCENT)
      Divider().vertical(true).height(36).color(StyleConstants.BORDER_LIGHT)
      this.OverviewMetric('📦', this.overviewBatches.toString(), '在培批次', StyleConstants.INFO)
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
    .margin({ top: 14 })
  }

  @Builder
  OverviewMetric(icon: string, value: string, label: string, color: string) {
    Column() {
      Text(icon)
        .fontSize(20)
        .width(40)
        .height(40)
        .textAlign(TextAlign.Center)
        .borderRadius(20)
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

  // ==================== 传感器网格 ====================
  @Builder
  SensorGrid() {
    GridRow({ gutter: { x: 10, y: 10 } }) {
      ForEach(this.sensors, (item: SensorDataItem) => {
        GridCol({ span: this.getSensorSpan() }) {
            this.SensorCard(item)
          }
      })
    }
    .width('100%')
    .margin({ top: 12 })
  }

  @Builder
  SensorCard(item: SensorDataItem) {
    Row() {
      // 左侧色条 — 自动跟随内容高度，不用 height('100%')
      Column()
        .width(3)
        .alignSelf(ItemAlign.Stretch)
        .backgroundColor(item.status === 0 ? StyleConstants.SUCCESS : item.status === 1 ? StyleConstants.WARNING : StyleConstants.DANGER)
        .borderRadius(2)

      Column() {
        // 一行：图标 + 名称 + 状态点
        Row() {
          Text(SensorConfigUtil.getConfig(item.type as SensorType).icon).fontSize(12)
          Text(SensorConfigUtil.getConfig(item.type as SensorType).name)
            .fontSize(11)
            .fontColor(StyleConstants.TEXT_SUB)
            .margin({ left: 6 })
            .maxLines(1)
          Blank()
          Circle({ width: 5, height: 5 })
            .fill(item.status === 0 ? StyleConstants.SUCCESS : item.status === 1 ? StyleConstants.WARNING : StyleConstants.DANGER)
        }
        .width('100%')

        // 一行：数值 + 单位
        Row() {
          Text(item.value.toFixed(1))
            .fontSize(AdaptiveUtils.getSensorDataFontSize(this.currentBreakpoint))
            .fontColor(StyleConstants.TEXT_TITLE)
            .fontWeight(FontWeight.Bold)
          Text(SensorConfigUtil.getConfig(item.type as SensorType).unit)
            .fontSize(10)
            .fontColor(StyleConstants.TEXT_SUB)
            .margin({ left: 2, bottom: 2 })
        }
        .alignItems(VerticalAlign.Bottom)
        .margin({ top: 2 })
      }
      .layoutWeight(1)
      .padding({
        left: 8,
        right: AdaptiveUtils.getSensorCardPadding(this.currentBreakpoint),
        top: AdaptiveUtils.getSensorCardPadding(this.currentBreakpoint),
        bottom: AdaptiveUtils.getSensorCardPadding(this.currentBreakpoint)
      })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .backgroundColor(StyleConstants.BG_CARD)
    .borderRadius(StyleConstants.RADIUS_MD)
    .shadow({
      radius: 4,
      color: '#0A000000',
      offsetX: 0,
      offsetY: 1
    })
  }

  // ==================== 趋势图 ====================
  @Builder
  TrendSection() {
    Column() {
      Row() {
        Text('24小时趋势')
          .fontSize(StyleConstants.FONT_LG)
          .fontColor(StyleConstants.TEXT_TITLE)
          .fontWeight(FontWeight.Bold)
        Blank()
        Text('温度 °C')
          .fontSize(StyleConstants.FONT_SM)
          .fontColor(StyleConstants.TEXT_HINT)
      }
      .width('100%')
      .margin({ bottom: 10 })

      if (this.trendData.length > 0) {
        BarChartComponent({
          data: this.trendData,
          barColor: StyleConstants.PRIMARY_LIGHT,
          chartHeight: 160
        })
      } else {
        Column()
          .width('100%')
          .height(160)
          .backgroundColor(StyleConstants.BG_CARD_LIGHT)
          .borderRadius(StyleConstants.RADIUS_SM)
      }
    }
    .width('100%')
    .padding(14)
    .backgroundColor(StyleConstants.BG_CARD)
    .borderRadius(StyleConstants.RADIUS_LG)
    .margin({ top: 12 })
    .shadow({
      radius: 4,
      color: '#0A000000',
      offsetX: 0,
      offsetY: 1
    })
  }

  // ==================== 快捷控制 ====================
  @Builder
  QuickControlSection() {
    Column() {
      Row() {
        Text('快捷控制')
          .fontSize(StyleConstants.FONT_LG)
          .fontColor(StyleConstants.TEXT_TITLE)
          .fontWeight(FontWeight.Bold)
      }
      .margin({ bottom: 10 })

      Row() {
        ForEach(this.controls, (item: ControlItem) => {
          Column() {
            Stack() {
              Text(item.icon).fontSize(28)
              if (item.active) {
                Circle({ width: 10, height: 10 })
                  .fill(StyleConstants.SUCCESS)
                  .position({ x: 28, y: 2 })
                  .shadow({ radius: 4, color: StyleConstants.SUCCESS, offsetX: 0, offsetY: 0 })
              }
            }
            .width(52)
            .height(52)
            .borderRadius(26)
            .backgroundColor(item.active ? item.color + '20' : StyleConstants.BG_CARD_LIGHT)
            .border({ width: item.active ? 2 : 0, color: item.color })
            .scale(item.active ? { x: 1.05, y: 1.05 } : { x: 1.0, y: 1.0 })
            .animation({ duration: 200, curve: Curve.EaseOut })

            Text(item.name)
              .fontSize(StyleConstants.FONT_SM)
              .fontColor(item.active ? item.color : StyleConstants.TEXT_SUB)
              .margin({ top: 6 })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
          .onClick(() => {
            this.onControlToggle(item);
          })
        })
      }
      .width('100%')
    }
    .width('100%')
    .padding(14)
    .backgroundColor(StyleConstants.BG_CARD)
    .borderRadius(StyleConstants.RADIUS_LG)
    .margin({ top: 12 })
    .shadow({
      radius: 4,
      color: '#0A000000',
      offsetX: 0,
      offsetY: 1
    })
  }

  // ==================== 实时告警 ====================
  @Builder
  AlertSection() {
    Column() {
      Row() {
        Text('实时告警')
          .fontSize(StyleConstants.FONT_LG)
          .fontColor(StyleConstants.TEXT_TITLE)
          .fontWeight(FontWeight.Bold)
        Blank()
        Text(`${this.alerts.length}条`)
          .fontSize(StyleConstants.FONT_SM)
          .fontColor(this.alerts.length > 0 ? StyleConstants.DANGER : StyleConstants.TEXT_HINT)
      }
      .width('100%')
      .margin({ bottom: 10 })

      if (this.alerts.length === 0) {
        Row() {
          Text('✓').fontSize(16).fontColor(StyleConstants.SUCCESS)
          Text('所有传感器正常')
            .fontSize(StyleConstants.FONT_SM)
            .fontColor(StyleConstants.TEXT_SUB)
            .margin({ left: 8 })
        }
        .width('100%')
        .height(48)
        .padding({ left: 14, right: 14 })
        .backgroundColor(StyleConstants.BG_CARD_LIGHT)
        .borderRadius(StyleConstants.RADIUS_SM)
      } else {
        ForEach(this.alerts, (item: AlertItem) => {
          Row() {
            Column()
              .width(3)
              .height(40)
              .backgroundColor(item.level === 1 ? StyleConstants.DANGER : StyleConstants.WARNING)
              .borderRadius({ topLeft: 2, bottomLeft: 2 })

            Column() {
              Text(item.message)
                .fontSize(StyleConstants.FONT_MD)
                .fontColor(StyleConstants.TEXT_TITLE)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(`${item.device} · ${item.time}`)
                .fontSize(StyleConstants.FONT_XS)
                .fontColor(StyleConstants.TEXT_HINT)
                .margin({ top: 4 })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
            .padding({ left: 10, right: 8 })

            Text(item.level === 1 ? '危险' : '警告')
              .fontSize(StyleConstants.FONT_XS)
              .fontColor(item.level === 1 ? StyleConstants.DANGER : StyleConstants.WARNING)
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .borderRadius(4)
              .backgroundColor((item.level === 1 ? StyleConstants.DANGER : StyleConstants.WARNING) + '18')
          }
          .width('100%')
          .height(56)
          .backgroundColor(StyleConstants.BG_CARD_LIGHT)
          .borderRadius(StyleConstants.RADIUS_SM)
          .margin({ bottom: 8 })
        })
      }
    }
    .width('100%')
    .padding(14)
    .backgroundColor(StyleConstants.BG_CARD)
    .borderRadius(StyleConstants.RADIUS_LG)
    .margin({ top: 12 })
    .shadow({
      radius: 4,
      color: '#0A000000',
      offsetX: 0,
      offsetY: 1
    })
  }
}
