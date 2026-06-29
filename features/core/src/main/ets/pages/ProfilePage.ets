import { BreakpointConstants, AdaptiveUtils } from 'common-base';
import { ThemeManager } from '../theme/ThemeManager';
import { ThemeTokens } from '../theme/ThemeTokens';

/**
 * 个人中心页面 - 多端适配（主题驱动）
 *
 * 主题切换入口位于"设置"菜单项，点击后弹出主题选择对话框。
 */

interface MenuItem {
  readonly id: string;
  icon: string;
  title: string;
  subtitle: string;
}

@Component
export struct ProfilePage {
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointConstants.SM;
  @StorageLink('themeName') themeName: string = 'frosted';

  @State userName: string = '蘑菇种植员';
  @State userRole: string = '大棚管理员';
  @State greenhouseCount: number = 4;
  @State showThemeDialog: boolean = false;
  @State selectedTheme: string = 'frosted';

  private menuGroups: MenuItem[][] = [
    [
      { id: 'devices', icon: '📱', title: '设备管理', subtitle: '查看所有传感器设备' },
      { id: 'alerts', icon: '🔔', title: '告警中心', subtitle: '2条待处理告警' },
      { id: 'growth', icon: '🍄', title: '生长日记', subtitle: '3个在培批次' }
    ],
    [
      { id: 'recipe', icon: '📋', title: '环境配方', subtitle: '平菇/香菇/金针菇' },
      { id: 'voice', icon: '🎙', title: '语音控制', subtitle: '已关闭' },
      { id: 'notify', icon: '📨', title: '消息通知', subtitle: '推送设置' }
    ],
    [
      { id: 'about', icon: 'ℹ', title: '关于应用', subtitle: 'v1.0.0' },
      { id: 'settings', icon: '⚙', title: '设置', subtitle: '主题/语言/缓存' }
    ]
  ];

  t(): ThemeTokens {
    return ThemeManager.getInstance().getTokens();
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
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

      // 主题选择对话框
      if (this.showThemeDialog) {
        this.ThemeDialog()
      }
    }
  }

  @Builder
  ContentBody() {
    this.HeaderSection()
    Scroll() {
      Column() {
        // 主题切换卡片（独立分组，醒目位置）
        this.ThemeSwitcher()

        GridRow({
          gutter: { x: this.getCardGap(), y: this.getCardGap() }
        }) {
          ForEach(this.menuGroups, (group: MenuItem[]) => {
            GridCol({ span: this.getMenuSpan() }) {
              this.MenuGroup(group)
            }
          })
        }
        .width('100%')
        .padding({
          left: this.getPagePadding(),
          right: this.getPagePadding(),
          top: 12
        })
        Blank().height(80)
      }
      .width('100%')
    }
    .layoutWeight(1)
    .scrollBar(BarState.Auto)
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

  private getCardGap(): number {
    return AdaptiveUtils.getCardGap(this.currentBreakpoint);
  }

  private getMenuSpan(): number {
    const cols = AdaptiveUtils.getCardColumns(this.currentBreakpoint);
    return Math.floor(12 / cols);
  }

  // ==================== Header ====================
  @Builder
  HeaderSection() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column()
        .width('100%')
        .height(200)
        .linearGradient({
          angle: 135,
          colors: [[this.t().headerGradientTop, 0.0], [this.t().headerGradientBottom, 1.0]]
        })

      Column() {
        Blank().height(44)

        Row() {
          Column() {
            Text('🍄')
              .fontSize(40)
          }
          .width(64)
          .height(64)
          .borderRadius(32)
          .backgroundColor(this.t().bgCardLight)
          .justifyContent(FlexAlign.Center)
          .shadow({ radius: 8, color: this.t().shadowFloatColor, offsetX: 0, offsetY: 2 })

          Column() {
            Text(this.userName)
              .fontSize(AdaptiveUtils.getTitleFontSize(this.currentBreakpoint))
              .fontColor(this.t().textWhite)
              .fontWeight(FontWeight.Bold)
            Text(this.userRole)
              .fontSize(this.t().fontSm)
              .fontColor(this.t().textWhiteSub)
              .margin({ top: 4 })
          }
          .margin({ left: 16 })
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Column() {
            Text(this.greenhouseCount.toString())
              .fontSize(this.t().fontXxl)
              .fontColor(this.t().textWhite)
              .fontWeight(FontWeight.Bold)
            Text('大棚')
              .fontSize(this.t().fontXs)
              .fontColor(this.t().textWhiteSub)
          }
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .padding({ left: this.getPagePadding(), right: this.getPagePadding() })
      }
      .width('100%')
    }
    .width('100%')
    .height(200)
  }

  // ==================== 主题切换入口 ====================
  @Builder
  ThemeSwitcher() {
    Row() {
      Text(this.t().name === 'frosted' ? '🌸' : '⚫')
        .fontSize(24)
        .width(44)
        .height(44)
        .textAlign(TextAlign.Center)
        .borderRadius(22)
        .backgroundColor(this.t().bgCardLight)

      Column() {
        Text('主题风格')
          .fontSize(this.t().fontMd)
          .fontColor(this.t().textTitle)
          .fontWeight(FontWeight.Medium)
        Text(this.t().name === 'frosted' ? '雾透玻璃 · 毛玻璃质感' : '极致黑白 · 高对比极简')
          .fontSize(this.t().fontXs)
          .fontColor(this.t().textSub)
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 12 })

      Text('切换 ›')
        .fontSize(this.t().fontSm)
        .fontColor(this.t().primary)
        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        .backgroundColor(this.t().bgCardLight)
        .borderRadius(this.t().radiusSm)
        .onClick(() => {
          this.selectedTheme = this.t().name;
          this.showThemeDialog = true;
        })
    }
    .width('100%')
    .padding(14)
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
    .margin({ top: 12, left: this.getPagePadding(), right: this.getPagePadding() })
  }

  // ==================== 主题选择对话框 ====================
  @Builder
  ThemeDialog() {
    Column()
      .width('100%')
      .height('100%')
      .backgroundColor(this.t().bgOverlay)
      .onClick(() => { this.showThemeDialog = false; })
      .justifyContent(FlexAlign.Center)

    Column() {
      Text('选择主题风格')
        .fontSize(this.t().fontLg)
        .fontColor(this.t().textTitle)
        .fontWeight(FontWeight.Bold)
        .padding({ top: 20, bottom: 16 })

      Row() {
        this.ThemeOption('frosted', '🌸', '雾透玻璃', '浅色淡彩 · 毛玻璃 · 弹性动画')
        this.ThemeOption('contrast', '⚫', '极致黑白', '纯黑纯白 · 高对比 · 专业克制')
      }
      .width('100%')
      .padding({ left: 20, right: 20 })

      Row() {
        Text('取消')
          .fontSize(this.t().fontMd)
          .fontColor(this.t().textSub)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .padding({ top: 10, bottom: 10 })
          .backgroundColor(this.t().bgCardLight)
          .borderRadius(this.t().radiusSm)
          .onClick(() => { this.showThemeDialog = false; })

        Blank().width(12)

        Text('确定')
          .fontSize(this.t().fontMd)
          .fontColor(this.t().textOnPrimary)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .padding({ top: 10, bottom: 10 })
          .backgroundColor(this.t().primary)
          .borderRadius(this.t().radiusSm)
          .onClick(() => {
            // 1. 先更新 ThemeManager.current（同步，保证 rebuild 时 t() 读到新主题）
            ThemeManager.getInstance().setTheme(this.selectedTheme);
            // 2. 再写 @StorageLink → 触发所有页面 rebuild → t() → getTokens() → 新主题
            this.themeName = this.selectedTheme;
            this.showThemeDialog = false;
          })
      }
      .width('100%')
      .padding(20)
    }
    .width('90%')
    .backgroundColor(this.t().bgCard)
    .borderRadius(this.t().radiusXl)
    .shadow({
      radius: this.t().shadowFloatRadius,
      color: this.t().shadowFloatColor,
      offsetX: 0,
      offsetY: this.t().shadowFloatOffsetY
    })
  }

  @Builder
  ThemeOption(themeId: string, icon: string, title: string, desc: string) {
    Column() {
      Text(icon).fontSize(40)
      Text(title)
        .fontSize(this.t().fontMd)
        .fontColor(this.t().textTitle)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 8 })
      Text(desc)
        .fontSize(this.t().fontXs)
        .fontColor(this.t().textSub)
        .margin({ top: 4 })
      if (this.selectedTheme === themeId) {
        Text('✓')
          .fontSize(20)
          .fontColor(this.t().primary)
          .margin({ top: 8 })
      }
    }
    .layoutWeight(1)
    .padding(16)
    .margin(8)
    .borderRadius(this.t().radiusMd)
    .backgroundColor(this.selectedTheme === themeId ? this.t().bgCardLight : this.t().bgCardLight)
    .border({
      width: this.selectedTheme === themeId ? 2 : 1,
      color: this.selectedTheme === themeId ? this.t().primary : this.t().border
    })
    .onClick(() => {
      this.selectedTheme = themeId;
    })
  }

  // ==================== 菜单分组 ====================
  @Builder
  MenuGroup(group: MenuItem[]) {
    Column() {
      ForEach(group, (item: MenuItem, index: number) => {
        this.MenuItemRow(item, index === group.length - 1)
      })
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 6, bottom: 6 })
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
  }

  @Builder
  MenuItemRow(item: MenuItem, isLast: boolean) {
    Row() {
      Text(item.icon)
        .fontSize(20)
        .width(36)
        .height(36)
        .textAlign(TextAlign.Center)
        .borderRadius(18)
        .backgroundColor(this.t().bgCardLight)

      Column() {
        Text(item.title)
          .fontSize(this.t().fontMd)
          .fontColor(this.t().textTitle)
          .fontWeight(FontWeight.Medium)
        Text(item.subtitle)
          .fontSize(this.t().fontXs)
          .fontColor(this.t().textSub)
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 12 })

      Text('›')
        .fontSize(this.t().fontLg)
        .fontColor(this.t().textSub)
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
    .border({ width: { bottom: isLast ? 0 : 0.5 }, color: this.t().borderLight })
    .onClick(() => { this.onMenuClick(item.id); })
  }

  private onMenuClick(id: string): void {
    let target: string = '';
    if (id === 'alerts') { target = 'AlertPage'; }
    else if (id === 'growth') { target = 'GrowthPage'; }
    else if (id === 'recipe') { target = 'RecipePage'; }
    if (target.length > 0) {
      try {
        const stack = AppStorage.get<NavPathStack>('navPathStack');
        if (stack) { stack.pushPath({ name: target }); }
      } catch {
        // ignore
      }
    }
  }
}
