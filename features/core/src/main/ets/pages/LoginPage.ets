/**
 * 登录页面（假登录，纯UI演示）
 *
 * 布局策略：
 * 1. 窄屏（XS/SM）：单列垂直居中，Logo → 表单 → 按钮
 * 2. 宽屏（MD/LG/XL）：左右 50-50 分栏
 *    - 左栏：品牌展示区（渐变底 + 装饰像素画 + Slogan）
 *    - 右栏：登录卡片（毛玻璃，水平/垂直居中）
 *
 * 主题驱动：所有颜色/圆角/字号来自 ThemeTokens，与主界面风格一致。
 * 登录行为：点击按钮后模拟 1.2s 加载，写入 AppStorage.isLoggedIn=true，
 * 由外层 Index 监听变化切换到主界面。
 *
 * 注意：@Builder 方法返回 void，不能链式调用属性修饰符，
 *      需用容器组件（Column/Row）包裹后再设置属性。
 */

import { BreakpointConstants, AdaptiveUtils } from 'common-base';
import { ThemeManager } from '../theme/ThemeManager';
import { ThemeTokens } from '../theme/ThemeTokens';
import { promptAction } from '@kit.ArkUI';

@Component
export struct LoginPage {
  @State username: string = '';
  @State password: string = '';
  @State isLogging: boolean = false;
  @State remember: boolean = true;
  @StorageLink('themeName') themeName: string = 'frosted';
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointConstants.SM;
  @StorageLink('isLoggedIn') @Watch('onLoginStateChanged') isLoggedIn: boolean = false;

  t(): ThemeTokens {
    return ThemeManager.getInstance().getTokens();
  }

  private onLoginStateChanged(): void {
    // 占位：状态变化时由外层 Index 监听并切换页面
  }

  /** 双栏布局（宽屏） */
  private isSplitLayout(): boolean {
    return AdaptiveUtils.isLargeScreen(this.currentBreakpoint);
  }

  /** 假登录：不校验账号密码，任意内容均可"登录成功" */
  private doLogin(): void {
    if (this.isLogging) {
      return;
    }
    this.isLogging = true;
    setTimeout(() => {
      this.isLogging = false;
      this.isLoggedIn = true;
      AppStorage.setOrCreate<boolean>('isLoggedIn', true);
      try {
        promptAction.showToast({
          message: '登录成功，欢迎回来',
          duration: 1500
        });
      } catch (_) {
        // ignore
      }
    }, 1200);
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      this.BackgroundLayer()

      if (this.isSplitLayout()) {
        Row() {
          Column() {
            this.BrandPanel()
          }
          .layoutWeight(1)
          .height('100%')

          Column() {
            this.FormPanel()
          }
          .layoutWeight(1)
          .height('100%')
        }
        .width('100%')
        .height('100%')
      } else {
        Scroll() {
          Column() {
            this.MobileBrandHeader()
            Column() {
              this.FormCard()
            }
            .margin({ top: AdaptiveUtils.getPagePadding(this.currentBreakpoint) + 12 })
          }
          .width('100%')
          .padding({
            left: AdaptiveUtils.getPagePadding(this.currentBreakpoint),
            right: AdaptiveUtils.getPagePadding(this.currentBreakpoint),
            top: 48,
            bottom: 32
          })
        }
        .scrollBar(BarState.Off)
        .width('100%')
        .height('100%')
        .align(Alignment.Top)
      }
    }
    .width('100%')
    .height('100%')
  }

  // ==================== 背景层 ====================
  @Builder
  BackgroundLayer() {
    Column()
      .width('100%')
      .height('100%')
      .linearGradient({
        direction: GradientDirection.RightBottom,
        colors: this.t().name === 'frosted'
          ? [
            [this.t().bgPage, 0.0],
            ['#F6F1E4', 0.4],
            ['#F2E8D5', 0.8],
            [this.t().bgPage, 1.0]
          ]
          : [
            ['#F5F5F5', 0.0],
            ['#ECECEC', 0.5],
            ['#FAFAFA', 1.0]
          ]
      })
  }

  // ==================== 宽屏左栏：品牌展示 ====================
  @Builder
  BrandPanel() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width(520)
        .height(520)
        .borderRadius(260)
        .linearGradient({
          direction: GradientDirection.RightBottom,
          colors: [
            [this.t().primaryLight + 'CC', 0.0],
            [this.t().accentLight + 'AA', 0.5],
            [this.t().primary + '22', 1.0]
          ]
        })
        .blur(30)
        .translate({ x: -60, y: -80 })
        .opacity(0.7)

      Column()
        .width(380)
        .height(380)
        .borderRadius(190)
        .linearGradient({
          direction: GradientDirection.LeftTop,
          colors: [
            [this.t().accentLight + 'BB', 0.0],
            [this.t().success + '44', 1.0]
          ]
        })
        .blur(24)
        .translate({ x: 80, y: 80 })
        .opacity(0.5)

      Column({ space: 24 }) {
        this.PixelMushroomLogo(140)

        Column({ space: 10 }) {
          Text('蘑菇大棚 IoT 管理系统')
            .fontSize(AdaptiveUtils.getTitleFontSize(this.currentBreakpoint) + 6)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.t().textTitle)
          Text('Smart Greenhouse Management Platform')
            .fontSize(this.t().fontSm)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.t().textSub)
            .letterSpacing(1.2)
        }
        .margin({ top: 12 })

        Column({ space: 14 }) {
          this.SloganItem('实时监测', '温湿度 / CO₂ / 光照 全方位感知')
          this.SloganItem('智能控制', '补光 / 通风 / 空调 远程联动')
          this.SloganItem('数据决策', '生长曲线 + AI 识别 + 配方指导')
        }
        .width(420)
        .padding(20)
        .borderRadius(this.t().radiusLg)
        .backgroundColor(this.t().bgCard)
        .opacity(0.92)
        .backdropBlur(this.t().blurAmount)
        .border({ width: 1, color: this.t().borderLight })
        .margin({ top: 16 })

        Text('v1.0.0  ·  HarmonyOS NEXT 6.1.1')
          .fontSize(this.t().fontXs)
          .fontColor(this.t().textHint)
          .margin({ top: 20 })
      }
      .width('80%')
      .constraintSize({ maxWidth: 560 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  SloganItem(title: string, desc: string) {
    Row({ space: 14 }) {
      Stack({ alignContent: Alignment.Center }) {
        Circle({ width: 40, height: 40 })
          .fill(this.t().primaryLight + '88')
        Circle({ width: 18, height: 18 })
          .fill(this.t().primary)
      }
      Column({ space: 3 }) {
        Text(title)
          .fontSize(this.t().fontMd)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.t().textTitle)
        Text(desc)
          .fontSize(this.t().fontXs)
          .fontColor(this.t().textSub)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
  }

  // ==================== 窄屏顶部品牌区 ====================
  @Builder
  MobileBrandHeader() {
    Column({ space: 10 }) {
      this.PixelMushroomLogo(96)
      Text('蘑菇大棚')
        .fontSize(AdaptiveUtils.getTitleFontSize(this.currentBreakpoint) + 2)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.t().textTitle)
      Text('IoT 智能管理系统')
        .fontSize(this.t().fontSm)
        .fontColor(this.t().textSub)
        .letterSpacing(0.8)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .padding({ top: 12 })
  }

  // ==================== 宽屏右栏：表单容器 ====================
  @Builder
  FormPanel() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width(260)
        .height(260)
        .borderRadius(130)
        .linearGradient({
          direction: GradientDirection.RightBottom,
          colors: [
            [this.t().accentLight + '66', 0.0],
            [this.t().primaryLight + '33', 1.0]
          ]
        })
        .blur(20)
        .translate({ x: 120, y: -160 })
        .opacity(0.55)

      Column() {
        this.FormCard()
      }
      .width('78%')
      .constraintSize({ maxWidth: 460 })
    }
    .width('100%')
    .height('100%')
  }

  // ==================== 登录表单卡片（宽窄屏共用） ====================
  @Builder
  FormCard() {
    Column({ space: 22 }) {
      Column({ space: 6 }) {
        Text('欢迎登录')
          .fontSize(AdaptiveUtils.getTitleFontSize(this.currentBreakpoint) + 2)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.t().textTitle)
        Text('请输入账号信息，开始您的智慧种植之旅')
          .fontSize(this.t().fontSm)
          .fontColor(this.t().textSub)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      Column({ space: 8 }) {
        Text('账号')
          .fontSize(this.t().fontSm)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.t().textBody)
        this.InputField('请输入账号 / 手机号', this.username, true,
          (v: string) => { this.username = v; }, 'user')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      Column({ space: 8 }) {
        Text('密码')
          .fontSize(this.t().fontSm)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.t().textBody)
        this.InputField('请输入登录密码', this.password, false,
          (v: string) => { this.password = v; }, 'lock')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      Row() {
        Row({ space: 8 }) {
          Stack({ alignContent: Alignment.Center }) {
            Rect({ width: 18, height: 18 })
              .fill(this.remember ? this.t().primary : this.t().bgCard)
              .borderRadius(5)
              .border({
                width: this.remember ? 0 : 1.2,
                color: this.t().border
              })
            if (this.remember) {
              Path()
                .width(10).height(8)
                .commands('M1 4 L4 7 L9 1.5')
                .stroke(this.t().textWhite)
                .strokeWidth(1.8)
                .fill(Color.Transparent)
                .strokeLineCap(LineCapStyle.Round)
                .strokeLineJoin(LineJoinStyle.Round)
            }
          }
          .width(20)
          .height(20)
          .onClick(() => { this.remember = !this.remember; })

          Text('记住我')
            .fontSize(this.t().fontSm)
            .fontColor(this.t().textSub)
            .onClick(() => { this.remember = !this.remember; })
        }

        Blank()

        Text('忘记密码？')
          .fontSize(this.t().fontSm)
          .fontColor(this.t().primary)
          .fontWeight(FontWeight.Medium)
          .onClick(() => {
            try {
              promptAction.showToast({ message: '演示版：请联系系统管理员重置', duration: 1500 });
            } catch (_) { /* ignore */ }
          })
      }
      .width('100%')
      .height(36)

      Button(this.isLogging ? '登录中...' : '登 录')
        .width('100%')
        .height(48)
        .fontSize(this.t().fontMd)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.t().textOnPrimary)
        .backgroundColor(this.isLogging ? this.t().primaryLight : this.t().primary)
        .borderRadius(this.t().radiusMd)
        .enabled(!this.isLogging)
        .shadow({
          radius: this.t().shadowHoverRadius,
          color: this.t().primary + '55',
          offsetY: 6
        })
        .onClick(() => { this.doLogin(); })

      Row() {
        Column()
          .height(0.5)
          .layoutWeight(1)
          .backgroundColor(this.t().divider)
        Text('或使用其他方式')
          .fontSize(this.t().fontXs)
          .fontColor(this.t().textHint)
          .margin({ left: 14, right: 14 })
        Column()
          .height(0.5)
          .layoutWeight(1)
          .backgroundColor(this.t().divider)
      }
      .width('100%')
      .margin({ top: 4 })

      Row({ space: 32 }) {
        this.ThirdLoginIcon('W', this.t().primary, this.t().primaryLight)
        this.ThirdLoginIcon('Q', this.t().accent, this.t().accentLight)
        this.ThirdLoginIcon('G', this.t().danger, '#F8D7D7')
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ top: 2 })

      Row({ space: 4 }) {
        Text('还没有账号？')
          .fontSize(this.t().fontSm)
          .fontColor(this.t().textSub)
        Text('立即注册')
          .fontSize(this.t().fontSm)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.t().primary)
          .onClick(() => {
            try {
              promptAction.showToast({ message: '演示版：注册功能暂未开放', duration: 1500 });
            } catch (_) { /* ignore */ }
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .padding(28)
    .borderRadius(this.t().radiusXl)
    .backgroundColor(this.t().bgCard + 'F5')
    .backdropBlur(this.t().blurAmount)
    .border({ width: 1, color: this.t().borderLight })
    .shadow({
      radius: this.t().shadowFloatRadius,
      color: this.t().shadowFloatColor,
      offsetY: this.t().shadowFloatOffsetY
    })
  }

  @Builder
  InputField(
    placeholder: string,
    value: string,
    isPlain: boolean,
    onChange: (v: string) => void,
    iconType: string
  ) {
    Row({ space: 10 }) {
      this.InputIcon(iconType)

      if (isPlain) {
        TextInput({ placeholder: placeholder, text: value })
          .layoutWeight(1)
          .fontSize(this.t().fontMd)
          .fontColor(this.t().textTitle)
          .placeholderColor(this.t().textHint)
          .backgroundColor(Color.Transparent)
          .height(40)
          .onChange((v: string) => onChange(v))
      } else {
        TextInput({ placeholder: placeholder, text: value })
          .type(InputType.Password)
          .layoutWeight(1)
          .fontSize(this.t().fontMd)
          .fontColor(this.t().textTitle)
          .placeholderColor(this.t().textHint)
          .backgroundColor(Color.Transparent)
          .height(40)
          .onChange((v: string) => onChange(v))
      }
    }
    .width('100%')
    .height(48)
    .padding({ left: 14, right: 14 })
    .backgroundColor(this.t().bgCardLight)
    .borderRadius(this.t().radiusMd)
    .border({ width: 1, color: this.t().borderLight })
  }

  @Builder
  InputIcon(type: string) {
    if (type === 'user') {
      Column({ space: -1 }) {
        Circle({ width: 10, height: 10 }).fill(this.t().textSub)
        Rect({ width: 16, height: 9 })
          .fill(this.t().textSub)
          .borderRadius(4)
      }
      .width(20)
      .height(20)
      .justifyContent(FlexAlign.Center)
      .opacity(0.85)
    } else if (type === 'lock') {
      Column({ space: -2 }) {
        Path()
          .width(14).height(10)
          .commands('M2 9 L2 5 A5 5 0 0 1 12 5 L12 9')
          .stroke(this.t().textSub)
          .strokeWidth(1.8)
          .fill(Color.Transparent)
          .strokeLineCap(LineCapStyle.Round)
        Rect({ width: 16, height: 11 })
          .fill(this.t().textSub)
          .borderRadius(3)
        Circle({ width: 3, height: 3 }).fill(this.t().bgCardLight)
          .margin({ top: -7 })
      }
      .width(20)
      .height(20)
      .justifyContent(FlexAlign.Center)
      .opacity(0.85)
    }
  }

  @Builder
  ThirdLoginIcon(label: string, fg: string, bg: string) {
    Stack({ alignContent: Alignment.Center }) {
      Circle({ width: 44, height: 44 })
        .fill(bg)
        .opacity(0.5)
      Circle({ width: 44, height: 44 })
        .fill(Color.Transparent)
        .border({ width: 1, color: this.t().borderLight })
      Text(label)
        .fontSize(this.t().fontMd)
        .fontWeight(FontWeight.Bold)
        .fontColor(fg)
    }
    .width(44)
    .height(44)
    .onClick(() => {
      try {
        promptAction.showToast({ message: `演示版：${label} 登录暂未开放`, duration: 1500 });
      } catch (_) { /* ignore */ }
    })
  }

  // ==================== 像素蘑菇 Logo（纯几何绘制，与图标设计呼应） ====================
  @Builder
  PixelMushroomLogo(size: number) {
    Stack({ alignContent: Alignment.Bottom }) {
      Circle({ width: size + 28, height: size + 28 })
        .fill(this.t().primaryLight + '55')
        .blur(10)

      Column({ space: -Math.round(size * 0.04) }) {
        Column({ space: 0 }) {
          Rect({ width: size * 0.48, height: size * 0.07 })
            .fill('#F5E0C8')
            .margin({ left: size * 0.26 })
          Rect({ width: size * 0.72, height: size * 0.1 })
            .fill(MUSHROOM_L_CAP_HL)
            .borderRadius({ topLeft: size * 0.08, topRight: size * 0.08 })
          Rect({ width: size * 0.86, height: size * 0.11 })
            .fill(MUSHROOM_L_CAP_L)
          Rect({ width: size * 0.92, height: size * 0.12 })
            .fill(MUSHROOM_L_CAP)
          Rect({ width: size * 0.94, height: size * 0.09 })
            .fill(MUSHROOM_L_CAP_D)
          Row({ space: size * 0.08 }) {
            Rect({ width: size * 0.1, height: size * 0.055 })
              .fill('#FFFBF3')
              .borderRadius(3)
              .margin({ left: size * 0.04 })
            Rect({ width: size * 0.08, height: size * 0.045 })
              .fill('#FFFBF3')
              .borderRadius(2)
            Rect({ width: size * 0.09, height: size * 0.05 })
              .fill('#FFFBF3')
              .borderRadius(3)
              .margin({ right: size * 0.04 })
          }
          .width(size)
          .justifyContent(FlexAlign.SpaceAround)
          .margin({ top: -size * 0.18 })
        }
        .zIndex(2)

        Row() {
          Blank()
          Column() {
            Rect({ width: size * 0.44, height: size * 0.36 })
              .fill(MUSHROOM_L_STEM)
              .borderRadius({ bottomLeft: size * 0.06, bottomRight: size * 0.06 })
            Rect({ width: size * 0.08, height: size * 0.28 })
              .fill(MUSHROOM_L_STEM_S)
              .margin({ top: -size * 0.34, right: size * 0.30 })
          }
          .margin({ top: -size * 0.02 })
          Blank()
        }
        .width(size)
        .zIndex(1)
      }
      .width(size)
      .height(size * 0.92)
    }
    .width(size + 28)
    .height(size + 16)
  }
}

// Logo 专用常量（避免依赖 ThemeTokens，保持独立性）
const MUSHROOM_L_CAP_HL: string = '#E6C29B';
const MUSHROOM_L_CAP_L: string = '#CD9B5F';
const MUSHROOM_L_CAP: string = '#B07A3E';
const MUSHROOM_L_CAP_D: string = '#8B5A2B';
const MUSHROOM_L_STEM: string = '#F5E6CD';
const MUSHROOM_L_STEM_S: string = '#DCC8AA';
