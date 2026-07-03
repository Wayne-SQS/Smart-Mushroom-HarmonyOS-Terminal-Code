import { BreakpointConstants, AdaptiveUtils, Logger } from 'common-base';
import { ThemeManager } from '../theme/ThemeManager';
import { ThemeTokens } from '../theme/ThemeTokens';
import { IotService } from '../service/IotService';
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
  /** 控制器状态是否已加载 */
  @State controllerStatesLoaded: boolean = false;
  /** 是否正在下发命令 */
  @State sendingCommand: boolean = false;

  t(): ThemeTokens {
    return ThemeManager.getInstance().getTokens();
  }

  aboutToAppear(): void {
    Logger.info(TAG, '设备详情页打开：' + this.param.name);
    if (this.isController()) {
      this.loadControllerStates();
    }
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
    try {
      const props = await IotService.getInstance().getSmartRoomProperties();
      if (props) {
        this.lampOn = props.LampST === 'ON';
        this.condOn = props.CondST === 'ON';
        this.ventOn = props.VentST === 'ON';
        this.buzzerOn = props.BuzzerST === 'ON';
      }
    } catch (err) {
      Logger.warn(TAG, '获取控制器状态失败，使用默认关闭状态');
    } finally {
      this.controllerStatesLoaded = true;
    }
  }

  /** 下发控制命令 */
  private async toggleControl(
    name: string,
    action: () => Promise<Object>
  ): Promise<void> {
    this.sendingCommand = true;
    try {
      await action();
      promptAction.showToast({ message: `${name} 命令已下发`, duration: 1500 });
    } catch (err) {
      promptAction.showToast({ message: `${name} 控制失败`, duration: 2000 });
      Logger.warn(TAG, name + ' 控制失败');
    } finally {
      this.sendingCommand = false;
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
    this.DetailHeader()
    Scroll() {
      Column() {
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

  // ==================== 顶部 Header（带返回按钮） ====================
  @Builder
  DetailHeader() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column()
        .width('100%')
        .height(140)
        .linearGradient({
          angle: 135,
          colors: [[this.t().headerGradientTop, 0.0], [this.t().headerGradientBottom, 1.0]]
        })

      Column() {
        Blank().height(40)
        Row() {
          // 返回按钮
          Row() {
            Text('←')
              .fontSize(20)
              .fontColor(this.t().textWhite)
            Text('返回')
              .fontSize(this.t().fontSm)
              .fontColor(this.t().textWhite)
              .margin({ left: 4 })
          }
          .onClick(() => {
            this.onBack();
          })

          Blank()

          Column() {
            Text(this.param.name)
              .fontSize(AdaptiveUtils.getTitleFontSize(this.currentBreakpoint))
              .fontColor(this.t().textWhite)
              .fontWeight(FontWeight.Bold)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(this.getDeviceTypeLabel())
              .fontSize(this.t().fontSm)
              .fontColor(this.t().textWhiteSub)
              .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Center)
          .layoutWeight(1)

          // 右侧占位（与左侧对称）
          Row().width(60)
        }
        .width('100%')
        .padding({ left: this.getPagePadding(), right: this.getPagePadding() })
      }
      .width('100%')
    }
    .width('100%')
    .height(140)
  }

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
            '💡', '补光灯', this.lampOn,
            (on: boolean) => {
              this.lampOn = on;
              this.toggleControl('补光灯', () => IotService.getInstance().controlLight(on));
            }
          )
        }
        if (this.hasControl('通风')) {
          this.ControlSwitch(
            '🌀', '通风扇', this.ventOn,
            (on: boolean) => {
              this.ventOn = on;
              this.toggleControl('通风扇', () => IotService.getInstance().controlFan(on));
            }
          )
        }
        if (this.hasControl('喷雾')) {
          this.ControlSwitch(
            '💨', '喷雾/空调', this.condOn,
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
      Text(icon).fontSize(28)
      Text(label)
        .fontSize(this.t().fontMd)
        .fontColor(this.t().textTitle)
        .fontWeight(FontWeight.Medium)
        .margin({ left: 12 })
      Blank()
      Toggle({ type: ToggleType.Switch, isOn: isOn })
        .selectedColor(this.t().primary)
        .onChange((on: boolean) => {
          onToggle(on);
        })
    }
    .width('100%')
    .height(52)
    .enabled(!this.sendingCommand)
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
