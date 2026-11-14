import { BreakpointConstants, AdaptiveUtils, LayoutConstants, Logger } from 'common-base';
import { ThemeManager } from '../theme/ThemeManager';
import { ThemeTokens } from '../theme/ThemeTokens';
import { IotService } from '../service/IotService';
import { PageHeader } from '../components/PageHeader';
import promptAction from '@ohos.promptAction';

const TAG = 'DeviceDetailPage';

/**
 * 设备详情子页面（NavDestination）
 *
 * 传感器类设备：设备基本信息 + 连接状态 + 最近上报时间
 * 控制器类设备：设备基本信息 + 当前开关状态 + 控制按钮
 *
 * 注意：传感器实时数值（温度/湿度/CO₂/光照等）已在首页 DashboardPage 展示，
 *       本页不重复展示，聚焦设备管理本身。
 */

interface DeviceDetailParam {
  id: string;
  name: string;
  type: string;
  status: number;
  lastUpdate: string;
  location: string;
}

@Component
export struct DeviceDetailPage {
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointConstants.SM;
  @StorageLink('themeName') themeName: string = 'frosted';
  /** 设备路由参数（由 Index.ets NavDestination 构建时通过 AppStorage 传入） */
  @StorageLink('deviceDetailParam') param: DeviceDetailParam = {
    id: '', name: '', type: '', status: 0, lastUpdate: '', location: ''
  };

  /** 控制器当前开关状态 */
  @State lampOn: boolean = false;
  @State condOn: boolean = false;
  @State ventOn: boolean = false;
  @State buzzerOn: boolean = false;
  /** 控制器状态是否已加载（true 才可信，避免把「未取到」当成「关闭」） */
  @State controllerStatesLoaded: boolean = false;
  /** 控制器状态加载失败原因 */
  @State stateError: string = '';
  /** 是否正在下发命令 */
  @State sendingCommand: boolean = false;

  /** 页面已销毁标记：异步回调据此丢弃 setState */
  private disposed: boolean = false;

  t(): ThemeTokens {
    return ThemeManager.getInstance().getTokens();
  }

  aboutToAppear(): void {
    this.disposed = false;
    Logger.info(TAG, '设备详情页打开：' + this.param.name);
    if (this.isController()) {
      this.loadControllerStates();
    }
  }

  aboutToDisappear(): void {
    this.disposed = true;
  }

  /** 是否为控制器类设备 */
  private isController(): boolean {
    return this.param.type === '控制器';
  }

  /** 判断当前设备是否包含指定关键词（匹配名称） */
  private hasControl(keyword: string): boolean {
    return this.param.name.includes(keyword);
  }

  /** 加载控制器当前状态 */
  private async loadControllerStates(): Promise<void> {
    this.stateError = '';
    try {
      const props = await IotService.getInstance().getSmartRoomProperties();
      if (this.disposed) {
        return;
      }
      // props 为空表示影子无此服务，不能默认成「全部关闭」
      if (!props) {
        this.stateError = '未获取到控制器状态，请检查设备在线情况';
        return;
      }
      this.lampOn = props.LampST === 'ON';
      this.condOn = props.CondST === 'ON';
      this.ventOn = props.VentST === 'ON';
      this.buzzerOn = props.BuzzerST === 'ON';
      this.controllerStatesLoaded = true;
    } catch (err) {
      if (this.disposed) {
        return;
      }
      const msg = err instanceof Error ? err.message : String(err);
      this.stateError = msg;
      this.controllerStatesLoaded = false;
      Logger.warn(TAG, '获取控制器状态失败：' + msg);
    }
  }

  /** 下发控制命令（同一时刻只允许一条，防重复提交） */
  private async toggleControl(
    name: string,
    action: () => Promise<Object>
  ): Promise<void> {
    if (this.sendingCommand) {
      return;
    }
    this.sendingCommand = true;
    try {
      await action();
      promptAction.showToast({ message: `${name} 命令已下发`, duration: 1500 });
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      promptAction.showToast({ message: `${name} 控制失败：${msg}`, duration: 2000 });
      Logger.warn(TAG, name + ' 控制失败：' + msg);
    } finally {
      if (!this.disposed) {
        this.sendingCommand = false;
      }
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
      title: this.param.name,
      subtitle: this.getDeviceTypeLabel(),
      showBack: true,
      backLabel: '返回',
      onBack: () => {
        this.onBack();
      }
    })
    Scroll() {
      Column() {
        if (this.isController() && this.stateError.length > 0) {
          this.StateErrorBanner()
        }
        this.BasicInfoCard()
        this.StatusInfoCard()
        if (this.isController()) {
          this.ControllerPanel()
        }
        Blank().height(40)
      }
      .width('100%')
      .padding({ left: this.getPagePadding(), right: this.getPagePadding() })
    }
    .layoutWeight(1)
    .scrollBar(BarState.Auto)
  }

  /** 控制器状态加载失败：局部错误条 + 重试 */
  @Builder
  StateErrorBanner() {
    Row() {
      Column() {
        Text('控制器状态加载失败')
          .fontSize(this.t().fontSm)
          .fontColor(this.t().danger)
          .fontWeight(this.t().fontWeightTitle)
        Text(this.stateError)
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
          this.loadControllerStates();
        })
    }
    .width('100%')
    .padding(LayoutConstants.SPACE_MD)
    .backgroundColor(this.t().bgCard)
    .border({ width: LayoutConstants.CARD_BORDER_WIDTH, color: this.t().border })
    .borderRadius(this.t().radiusMd)
    .margin({ top: LayoutConstants.SPACE_MD })
  }

  // ==================== Header 已由 PageHeader 统一提供 ====================

  // ==================== 基本信息卡片 ====================
  @Builder
  BasicInfoCard() {
    Column() {
      Row() {
        Text('基本信息')
          .fontSize(this.t().fontLg)
          .fontColor(this.t().textTitle)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .margin({ bottom: 12 })

      this.InfoRow('设备名称', this.param.name)
      Divider().color(this.t().borderLight).margin({ top: 8, bottom: 8 })
      this.InfoRow('设备类型', this.param.type)
      Divider().color(this.t().borderLight).margin({ top: 8, bottom: 8 })
      this.InfoRow('安装位置', this.param.location)
      Divider().color(this.t().borderLight).margin({ top: 8, bottom: 8 })
      this.InfoRow('设备 ID', this.param.id)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.t().bgCard)
    .borderRadius(this.t().radiusLg)
    .shadow({
      radius: this.t().shadowCardRadius,
      color: this.t().shadowCardColor,
      offsetX: 0,
      offsetY: this.t().shadowCardOffsetY
    })
    .margin({ top: -20 })
  }

  @Builder
  InfoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(this.t().fontSm)
        .fontColor(this.t().textSub)
        .width(72)
      Text(value)
        .fontSize(this.t().fontMd)
        .fontColor(this.t().textTitle)
        .layoutWeight(1)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
  }

  // ==================== 连接状态卡片 ====================
  @Builder
  StatusInfoCard() {
    Column() {
      Row() {
        Text('连接状态')
          .fontSize(this.t().fontLg)
          .fontColor(this.t().textTitle)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .margin({ bottom: 12 })

      Row() {
        Circle({ width: 10, height: 10 })
          .fill(this.param.status === 1 ? this.t().success :
            (this.param.status === 2 ? this.t().danger : this.t().textSub))
          .shadow({
            radius: this.param.status === 1 ? 6 : 0,
            color: this.param.status === 1 ? this.t().success : 'transparent',
            offsetX: 0,
            offsetY: 0
          })
        Text(this.getStatusLabel())
          .fontSize(this.t().fontMd)
          .fontColor(this.param.status === 1 ? this.t().success :
            (this.param.status === 2 ? this.t().danger : this.t().textSub))
          .fontWeight(FontWeight.Medium)
          .margin({ left: 8 })
        Blank()
        Text('最近上报')
          .fontSize(this.t().fontXs)
          .fontColor(this.t().textSub)
          .margin({ right: 4 })
        Text(this.param.lastUpdate)
          .fontSize(this.t().fontXs)
          .fontColor(this.t().textSub)
      }
      .width('100%')

      // 状态指示条
      Row()
        .width('100%')
        .height(4)
        .borderRadius(2)
        .backgroundColor(this.t().bgCardLight)
        .margin({ top: 12 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.t().bgCard)
    .borderRadius(this.t().radiusLg)
    .shadow({
      radius: this.t().shadowCardRadius,
      color: this.t().shadowCardColor,
      offsetX: 0,
      offsetY: this.t().shadowCardOffsetY
    })
    .margin({ top: 12 })
  }

  // ==================== 控制器面板（仅控制器类设备显示） ====================
  @Builder
  ControllerPanel() {
    Column() {
      Row() {
        Text('设备控制')
          .fontSize(this.t().fontLg)
          .fontColor(this.t().textTitle)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .margin({ bottom: 12 })

      if (!this.controllerStatesLoaded) {
        Row() {
          LoadingProgress()
            .width(20)
            .height(20)
            .color(this.t().primary)
          Text('加载控制状态...')
            .fontSize(this.t().fontSm)
            .fontColor(this.t().textSub)
            .margin({ left: 8 })
        }
        .width('100%')
        .height(60)
        .justifyContent(FlexAlign.Center)
      } else {
        // 根据设备名称匹配对应的控制项
        if (this.hasControl('补光')) {
          this.ControlSwitch(
            '补', '补光灯', this.lampOn,
            (on: boolean) => {
              this.lampOn = on;
              this.toggleControl('补光灯', () => IotService.getInstance().controlLight(on));
            }
          )
        }
        if (this.hasControl('通风')) {
          this.ControlSwitch(
            '风', '通风扇', this.ventOn,
            (on: boolean) => {
              this.ventOn = on;
              this.toggleControl('通风扇', () => IotService.getInstance().controlFan(on));
            }
          )
        }
        if (this.hasControl('喷雾')) {
          this.ControlSwitch(
            '雾', '喷雾/空调', this.condOn,
            (on: boolean) => {
              this.condOn = on;
              this.toggleControl('喷雾/空调', () => IotService.getInstance().controlCondi(on));
            }
          )
        }
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.t().bgCard)
    .borderRadius(this.t().radiusLg)
    .shadow({
      radius: this.t().shadowCardRadius,
      color: this.t().shadowCardColor,
      offsetX: 0,
      offsetY: this.t().shadowCardOffsetY
    })
    .margin({ top: 12 })
  }

  @Builder
  ControlSwitch(
    icon: string,
    label: string,
    isOn: boolean,
    onToggle: (on: boolean) => void
  ) {
    Row() {
      Text(icon)
        .fontSize(this.t().fontSm)
        .fontColor(this.t().primary)
        .width(LayoutConstants.ICON_BOX_SM)
        .height(LayoutConstants.ICON_BOX_SM)
        .textAlign(TextAlign.Center)
        .backgroundColor(this.t().bgCardLight)
        .borderRadius(this.t().radiusSm)
      Text(label)
        .fontSize(this.t().fontMd)
        .fontColor(this.t().textTitle)
        .fontWeight(FontWeight.Medium)
        .margin({ left: 12 })
      Blank()
      if (this.controllerStatesLoaded) {
        Toggle({ type: ToggleType.Switch, isOn: isOn })
          .selectedColor(this.t().primary)
          .onChange((on: boolean) => {
            onToggle(on);
          })
      } else {
        // 未取到云端状态时不允许操作，也不假装是「关闭」
        Text('状态未知')
          .fontSize(this.t().fontXs)
          .fontColor(this.t().textHint)
      }
    }
    .width('100%')
    .height(LayoutConstants.ROW_HEIGHT_LIST_ITEM)
    .enabled(this.controllerStatesLoaded && !this.sendingCommand)
  }

  // ==================== 工具方法 ====================
  private getDeviceTypeLabel(): string {
    if (this.isController()) {
      return '控制设备';
    }
    return this.param.type + '传感器';
  }

  private getStatusLabel(): string {
    if (this.param.status === 1) { return '在线'; }
    if (this.param.status === 2) { return '故障'; }
    return '离线';
  }

  private onBack(): void {
    try {
      const stack = AppStorage.get<NavPathStack>('navPathStack');
      if (stack) {
        stack.pop();
      }
    } catch (err) {
      Logger.warn(TAG, '返回失败');
    }
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
}
