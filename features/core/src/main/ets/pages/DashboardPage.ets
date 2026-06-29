import { SensorType, SensorConfigUtil, BreakpointConstants, AdaptiveUtils, Logger, BarChartComponent, ChartPoint } from 'common-base';
import { SensorDataItem, AlertItem, ControlItem } from '../model/GreenhouseModel';
import { DashboardViewModel } from '../viewmodel/DashboardViewModel';
import { AlertViewModel } from '../viewmodel/AlertViewModel';
import { ThemeManager } from '../theme/ThemeManager';
import { ThemeTokens } from '../theme/ThemeTokens';
import promptAction from '@ohos.promptAction';

const TAG = 'DashboardPage';

/**
 * 首页 - 大棚环境仪表盘
 *
 * 主题驱动：所有颜色从 this.t 读取（ThemeManager 单例），零硬编码。
 * 毛玻璃：卡片用 backdropBlur，装饰光晕用 blur，严禁混用。
 * 字号：小字号用 this.t().fontXs~fontXl，大字号（传感器数值/概览数字）用 AdaptiveUtils 断点自适应。
 * 动画：脉冲动画只动 scale（复合属性），黑白主题 animationEnabled=false 时跳过。
 */
@Component
export struct DashboardPage {
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointConstants.SM;
  /** 监听主题切换，框架自动触发 build() 重绘 */
  @StorageLink('themeName') themeName: string = 'frosted';

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

  // 脉冲动画状态
  @State pulseScale: number = 1;
  @State pulsingId: string = '';

  // 卡片 stagger 入场
  @State cardEntrance: number = 0; // 0→6，每完成一张 +1
  private staggerTimers: number[] = [];

  // 呼吸光晕（危险传感器）
  @State breathingPhase: number = 0; // 0→1→0 循环
  private breathingActive: boolean = false;
  private breathingTimer: number = -1;

  private viewModel: DashboardViewModel = new DashboardViewModel();
  private alertViewModel: AlertViewModel = new AlertViewModel();

  /** 一行获取所有 token */
  t(): ThemeTokens {
    return ThemeManager.getInstance().getTokens();
  }

  aboutToAppear(): void {
    // 1. 同步 mock 数据，避免首帧空白
    this.sensors = [...this.viewModel.sensors];
    this.controls = [...this.viewModel.controls];
    this.syncOverview();
    this.syncAlerts();
    this.buildTrendData();
    // 2. 异步加载云端属性
    this.loadFromViewModel();
    // 3. 入场动画（黑白主题跳过）
    if (this.t().animationEnabled) {
      this.startStaggerEntrance();
      this.checkBreathingGlow();
    }
  }

  aboutToDisappear(): void {
    this.stopStaggerEntrance();
    this.stopBreathingGlow();
  }

  /** 卡片 stagger 渐入：6 张传感器 + 1 概览 + 1 趋势 + 1 控制 + 1 告警 = 10 层 */
  private startStaggerEntrance(): void {
    const count = 10;
    for (let i = 0; i < count; i++) {
      const timer = setTimeout(() => {
        this.cardEntrance = this.cardEntrance + 1;
      }, i * 50);
      this.staggerTimers.push(timer);
    }
  }

  private stopStaggerEntrance(): void {
    for (let i = 0; i < this.staggerTimers.length; i++) {
      clearTimeout(this.staggerTimers[i]);
    }
    this.staggerTimers = [];
  }

  /** 检测是否有危险状态传感器，有则启动呼吸光晕 */
  private checkBreathingGlow(): void {
    const hasDanger = this.sensors.some((s: SensorDataItem) => s.status >= 2);
    if (hasDanger && !this.breathingActive) {
      this.breathingActive = true;
      this.breathLoop();
    }
  }

  private breathLoop(): void {
    if (!this.breathingActive) { return; }
    animateTo({
      duration: 1500,
      curve: Curve.EaseInOut,
      iterations: 1,
      onFinish: () => {
        this.breathingPhase = this.breathingPhase > 0.5 ? 0 : 1;
        this.breathLoop();
      }
    }, () => {
      this.breathingPhase = this.breathingPhase > 0.5 ? 0 : 1;
    });
  }

  private stopBreathingGlow(): void {
    this.breathingActive = false;
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

  /** 触发脉冲动画（黑白主题 animationEnabled=false 时跳过） */
  private triggerPulse(itemId: string): void {
    if (!this.t().animationEnabled) {
      return;
    }
    this.pulsingId = itemId;
    animateTo({
      duration: this.t().animationDuration,
      curve: Curve.EaseOut,
      onFinish: () => {
        this.pulseScale = 1;
        this.pulsingId = '';
      }
    }, () => {
      this.pulseScale = 1.3;
    });
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
    .backgroundColor(this.t().bgPage)
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

  /** 状态色：0=正常 1=警告 2=危险 */
  private getStatusColor(status: number): string {
    switch (status) {
      case 0: return this.t().success;
      case 1: return this.t().warning;
      case 2: return this.t().danger;
      default: return this.t().success;
    }
  }

  /**
   * 控制项强调色（主题感知，替代 StyleConstants 静态色）
   *
   * 雾透主题：柔和的品牌色系；黑白主题：高对比纯色。
   * 用于控制按钮的激活态边框与文字。
   */
  private getControlAccentColor(controlId: string): string {
    switch (controlId) {
      case 'fan':   return this.t().info;
      case 'condi': return this.t().primary;
      case 'light': return this.t().warning;
      default:      return this.t().primary;
    }
  }

  // ==================== 顶部 Header（深色渐变 + 装饰光晕） ====================
  @Builder
  HeaderSection() {
    Stack({ alignContent: Alignment.TopStart }) {
      // 背景：深色渐变（保证白字对比度）
      Column()
        .width('100%')
        .height(180)
        .linearGradient({
          angle: 150,
          colors: [
            [this.t().headerGradientTop, 0.0],
            [this.t().headerGradientBottom, 1.0]
          ]
        })

      // 右上装饰光晕 — 用 .blur() 模糊自身（不是 backdropBlur）
      Ellipse()
        .width(200)
        .height(200)
        .fill(this.t().primary)
        .blur(60)
        .opacity(0.15)
        .position({ x: '60%', y: '-30%' })

      // 左下装饰光晕
      Ellipse()
        .width(150)
        .height(150)
        .fill(this.t().primaryLight)
        .blur(50)
        .opacity(0.1)
        .position({ x: '-10%', y: '60%' })

      // 内容层（大棚名、状态、天气、告警条）
      Column() {
        Blank().height(44)

        Row() {
          Column() {
            Text(this.greenhouseName)
              .fontSize(this.t().fontXl)
              .fontColor(this.t().textWhite)
              .fontWeight(FontWeight.Bold)
            Row() {
              Circle({ width: 8, height: 8 })
                .fill(this.t().success)
                .shadow({ radius: 4, color: this.t().success, offsetX: 0, offsetY: 0 })
              Text(this.greenhouseStatus)
                .fontSize(this.t().fontSm)
                .fontColor(this.t().textWhiteSub)
                .margin({ left: 6 })
            }
            .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Start)

          Blank()

          Column() {
            Text('☁').fontSize(28)
            Text(this.weather)
              .fontSize(this.t().fontSm)
              .fontColor(this.t().textWhiteSub)
              .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .padding({ left: 20, right: 20 })

        if (this.activeAlerts > 0) {
          Row() {
            Text('⚠').fontSize(this.t().fontSm).fontColor(this.t().warning)
            Text(`${this.activeAlerts}条待处理告警`)
              .fontSize(this.t().fontSm)
              .fontColor(this.t().textTitle)
              .margin({ left: 6 })
            Blank()
            Text('查看 >')
              .fontSize(this.t().fontSm)
              .fontColor(this.t().textSub)
          }
          .width('100%')
          .height(36)
          .padding({ left: 16, right: 16 })
          .margin({ top: 12 })
          .backgroundColor(this.t().bgCardLight)
          .borderRadius(this.t().radiusSm)
          .onClick(() => {
            this.onAlertClick();
          })
        }
      }
      .width('100%')
    }
    .width('100%')
    .height(180)
    .shadow({
      radius: this.t().shadowHeaderRadius,
      color: this.t().shadowHeaderColor,
      offsetX: 0,
      offsetY: this.t().shadowHeaderOffsetY
    })
  }

  // ==================== 概览卡片（毛玻璃 + 大字号断点自适应） ====================
  @Builder
  OverviewCard() {
    Row() {
      this.StatItem('在线设备', this.overviewOnline.toString(), this.t().success)
      Divider().vertical(true).height(36).color(this.t().divider)
      this.StatItem('今日采收', this.overviewYield, this.t().info)
      Divider().vertical(true).height(36).color(this.t().divider)
      this.StatItem('在培批次', this.overviewBatches.toString(), this.t().warning)
    }
    .opacity(this.cardEntrance > 5 ? 1 : 0)
    .translate({ y: this.cardEntrance > 5 ? 0 : 16 })
    .animation({ duration: 400, curve: Curve.EaseOut })
    .width('100%')
    .padding({ top: 18, bottom: 18 })
    .backgroundColor(this.t().bgCard)
    .backdropBlur(this.t().blurAmount)
    .border({ width: 1, color: this.t().border })
    .borderRadius(this.t().radiusLg)
    .shadow({
      radius: this.t().shadowCardRadius,
      color: this.t().shadowCardColor,
      offsetX: 0,
      offsetY: this.t().shadowCardOffsetY
    })
    .margin({ top: 14 })
  }

  @Builder
  StatItem(label: string, value: string, accentColor: string) {
    Column() {
      // 装饰彩条（accentColor 仅供装饰，不作文字色）
      Row()
        .width(24)
        .height(3)
        .borderRadius(2)
        .backgroundColor(accentColor)
        .margin({ bottom: 8 })
      // 大字号走 AdaptiveUtils 断点自适应，不走 token 固定字号
      Text(value)
        .fontSize(AdaptiveUtils.getOverviewFontSize(this.currentBreakpoint))
        .fontColor(this.t().textTitle)
        .fontWeight(FontWeight.Bold)
      Text(label)
        .fontSize(this.t().fontSm)
        .fontColor(this.t().textSub)
        .margin({ top: 4 })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  // ==================== 传感器网格（毛玻璃 + 状态光晕） ====================
  @Builder
  SensorGrid() {
    GridRow({ gutter: { x: 10, y: 10 } }) {
      ForEach(this.sensors, (item: SensorDataItem, index: number) => {
        GridCol({ span: this.getSensorSpan() }) {
            this.SensorCard(item, index)
          }
          .opacity(this.cardEntrance > index ? 1 : 0)
          .translate({ y: this.cardEntrance > index ? 0 : 20 })
          .animation({ duration: 400, curve: Curve.EaseOut })
      })
    }
    .width('100%')
    .margin({ top: 12 })
  }

  @Builder
  SensorCard(item: SensorDataItem, index: number) {
    Stack() {
      // 状态光晕 — 危险传感器呼吸：opacity 由 breathingPhase 驱动
      Ellipse()
        .width('80%')
        .height(30)
        .fill(this.getStatusColor(item.status))
        .blur(20)
        .opacity(item.status >= 2 && this.breathingActive
          ? 0.2 + this.breathingPhase * 0.5  // 呼吸：0.2 ↔ 0.7
          : 0.4)
        .position({ x: '10%', y: '70%' })

      Column() {
        // 图标 + 状态点
        Row() {
          Text(SensorConfigUtil.getConfig(item.type as SensorType).icon).fontSize(this.t().fontSm)
          Text(SensorConfigUtil.getConfig(item.type as SensorType).name)
            .fontSize(this.t().fontXs)
            .fontColor(this.t().textSub)
            .margin({ left: 6 })
            .maxLines(1)
          Blank()
          Circle({ width: 5, height: 5 })
            .fill(this.getStatusColor(item.status))
        }
        .width('100%')

        // 数值 + 单位（大字号走 AdaptiveUtils 断点自适应）
        Row() {
          Text(item.value.toFixed(1))
            .fontSize(AdaptiveUtils.getSensorDataFontSize(this.currentBreakpoint))
            .fontColor(this.t().textTitle)
            .fontWeight(FontWeight.Bold)
          Text(SensorConfigUtil.getConfig(item.type as SensorType).unit)
            .fontSize(this.t().fontXs)
            .fontColor(this.t().textSub)
            .margin({ left: 2, bottom: 2 })
        }
        .alignItems(VerticalAlign.Bottom)
        .margin({ top: 2 })
      }
      .width('100%')
      .padding({
        left: 8,
        right: AdaptiveUtils.getSensorCardPadding(this.currentBreakpoint),
        top: AdaptiveUtils.getSensorCardPadding(this.currentBreakpoint),
        bottom: AdaptiveUtils.getSensorCardPadding(this.currentBreakpoint)
      })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
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
  }

  // ==================== 趋势图（毛玻璃卡片） ====================
  @Builder
  TrendSection() {
    Column() {
      Row() {
        Text('24小时趋势')
          .fontSize(this.t().fontLg)
          .fontColor(this.t().textTitle)
          .fontWeight(FontWeight.Bold)
        Blank()
        Text('温度 °C')
          .fontSize(this.t().fontSm)
          .fontColor(this.t().textSub)
      }
      .width('100%')
      .margin({ bottom: 10 })

      if (this.trendData.length > 0) {
        BarChartComponent({
          data: this.trendData,
          barColor: this.t().primaryLight,
          labelColor: this.t().textTitle,
          axisColor: this.t().textSub,
          baselineColor: this.t().divider,
          chartHeight: 160
        })
      } else {
        Column()
          .width('100%')
          .height(160)
          .backgroundColor(this.t().bgCardLight)
          .borderRadius(this.t().radiusSm)
      }
    }
    .width('100%')
    .padding(14)
    .backgroundColor(this.t().bgCard)
    .backdropBlur(this.t().blurAmount)
    .border({ width: 1, color: this.t().border })
    .borderRadius(this.t().radiusLg)
    .margin({ top: 12 })
    .shadow({
      radius: this.t().shadowCardRadius,
      color: this.t().shadowCardColor,
      offsetX: 0,
      offsetY: this.t().shadowCardOffsetY
    })
    .opacity(this.cardEntrance > 6 ? 1 : 0)
    .translate({ y: this.cardEntrance > 6 ? 0 : 16 })
    .animation({ duration: 400, curve: Curve.EaseOut })
  }

  // ==================== 快捷控制（脉冲动画） ====================
  @Builder
  QuickControlSection() {
    Column() {
      Row() {
        Text('快捷控制')
          .fontSize(this.t().fontLg)
          .fontColor(this.t().textTitle)
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
                  .fill(this.t().success)
                  .position({ x: 28, y: 2 })
                  .shadow({ radius: 4, color: this.t().success, offsetX: 0, offsetY: 0 })
              }
            }
            .width(52)
            .height(52)
            .borderRadius(26)
            // 禁止 alpha 拼接：用 bgCard（更不透明）区分激活态，bgCardLight 区分非激活态
            .backgroundColor(item.active ? this.t().bgCard : this.t().bgCardLight)
            .border({ width: item.active ? 2 : 0, color: this.getControlAccentColor(item.id) })
            // 脉冲动画只动 scale（复合属性），黑白主题跳过
            .scale(this.pulsingId === item.id
              ? { x: this.pulseScale, y: this.pulseScale }
              : { x: 1, y: 1 })
            .animation({ duration: this.t().animationDuration, curve: Curve.EaseOut })

            Text(item.name)
              .fontSize(this.t().fontSm)
              .fontColor(item.active ? this.getControlAccentColor(item.id) : this.t().textSub)
              .margin({ top: 6 })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
          .onClick(() => {
            this.triggerPulse(item.id);
            this.onControlToggle(item);
          })
        })
      }
      .width('100%')
    }
    .width('100%')
    .padding(14)
    .backgroundColor(this.t().bgCard)
    .backdropBlur(this.t().blurAmount)
    .border({ width: 1, color: this.t().border })
    .borderRadius(this.t().radiusLg)
    .margin({ top: 12 })
    .shadow({
      radius: this.t().shadowCardRadius,
      color: this.t().shadowCardColor,
      offsetX: 0,
      offsetY: this.t().shadowCardOffsetY
    })
    .opacity(this.cardEntrance > 7 ? 1 : 0)
    .translate({ y: this.cardEntrance > 7 ? 0 : 16 })
    .animation({ duration: 400, curve: Curve.EaseOut })
  }

  // ==================== 实时告警（毛玻璃卡片） ====================
  @Builder
  AlertSection() {
    Column() {
      Row() {
        Text('实时告警')
          .fontSize(this.t().fontLg)
          .fontColor(this.t().textTitle)
          .fontWeight(FontWeight.Bold)
        Blank()
        Text(`${this.alerts.length}条`)
          .fontSize(this.t().fontSm)
          .fontColor(this.alerts.length > 0 ? this.t().danger : this.t().textSub)
      }
      .width('100%')
      .margin({ bottom: 10 })

      if (this.alerts.length === 0) {
        Row() {
          Text('✓').fontSize(this.t().fontMd).fontColor(this.t().success)
          Text('所有传感器正常')
            .fontSize(this.t().fontSm)
            .fontColor(this.t().textSub)
            .margin({ left: 8 })
        }
        .width('100%')
        .height(48)
        .padding({ left: 14, right: 14 })
        .backgroundColor(this.t().bgCardLight)
        .borderRadius(this.t().radiusSm)
      } else {
        ForEach(this.alerts, (item: AlertItem) => {
          Row() {
            Column()
              .width(3)
              .height(40)
              .backgroundColor(item.level === 1 ? this.t().danger : this.t().warning)
              .borderRadius({ topLeft: 2, bottomLeft: 2 })

            Column() {
              Text(item.message)
                .fontSize(this.t().fontMd)
                .fontColor(this.t().textTitle)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(`${item.device} · ${item.time}`)
                .fontSize(this.t().fontXs)
                .fontColor(this.t().textSub)
                .margin({ top: 4 })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
            .padding({ left: 10, right: 8 })

            Text(item.level === 1 ? '危险' : '警告')
              .fontSize(this.t().fontXs)
              .fontColor(item.level === 1 ? this.t().danger : this.t().warning)
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .borderRadius(4)
              // 禁止 alpha 拼接：用 bgCardLight 替代 color + '18'
              .backgroundColor(this.t().bgCardLight)
          }
          .width('100%')
          .height(56)
          .backgroundColor(this.t().bgCardLight)
          .borderRadius(this.t().radiusSm)
          .margin({ bottom: 8 })
        })
      }
    }
    .width('100%')
    .padding(14)
    .backgroundColor(this.t().bgCard)
    .backdropBlur(this.t().blurAmount)
    .border({ width: 1, color: this.t().border })
    .borderRadius(this.t().radiusLg)
    .margin({ top: 12 })
    .shadow({
      radius: this.t().shadowCardRadius,
      color: this.t().shadowCardColor,
      offsetX: 0,
      offsetY: this.t().shadowCardOffsetY
    })
    .opacity(this.cardEntrance > 8 ? 1 : 0)
    .translate({ y: this.cardEntrance > 8 ? 0 : 16 })
    .animation({ duration: 400, curve: Curve.EaseOut })
  }
}
