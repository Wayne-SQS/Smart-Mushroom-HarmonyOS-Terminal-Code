import { StyleConstants, BreakpointConstants, AdaptiveUtils } from 'common-base';

/**
 * 个人中心页面 - 多端适配
 *
 * 响应式：
 * - 菜单分组 GridRow 多列：xs/sm 1列 / md 2列 / lg 2列 / xl 3列
 * - XL 屏内容限宽居中
 * - 大屏头像区水平铺开，窄屏保持原样
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

  @State userName: string = '蘑菇种植员';
  @State userRole: string = '大棚管理员';
  @State greenhouseCount: number = 4;

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
      .backgroundColor(StyleConstants.BG_PAGE)
    } else {
      Column() {
        this.ContentBody()
      }
      .width('100%')
      .height('100%')
      .backgroundColor(StyleConstants.BG_PAGE)
    }
  }

  @Builder
  ContentBody() {
    this.HeaderSection()
    Scroll() {
      Column() {
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

  /** 是否需要内容限宽（大屏） */
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

  /** 菜单分组 GridCol span：xs/sm 12 / md 6 / lg 6 / xl 4 */
  private getMenuSpan(): number {
    const cols = AdaptiveUtils.getCardColumns(this.currentBreakpoint);
    return Math.floor(12 / cols);
  }

  // ==================== 顶部 Header ====================
  @Builder
  HeaderSection() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column()
        .width('100%')
        .height(200)
        .linearGradient({
          angle: 135,
          colors: [[StyleConstants.PRIMARY_DARK, 0.0], [StyleConstants.PRIMARY, 0.6], ['#388E3C', 1.0]]
        })

      Column() {
        Blank().height(44)

        Row() {
          // 头像
          Column() {
            Text('🍄')
              .fontSize(40)
          }
          .width(64)
          .height(64)
          .borderRadius(32)
          .backgroundColor('#FFFFFF30')
          .justifyContent(FlexAlign.Center)
          .shadow({ radius: 8, color: '#33000000', offsetX: 0, offsetY: 2 })

          // 用户信息
          Column() {
            Text(this.userName)
              .fontSize(AdaptiveUtils.getTitleFontSize(this.currentBreakpoint))
              .fontColor(StyleConstants.TEXT_WHITE)
              .fontWeight(FontWeight.Bold)
            Text(this.userRole)
              .fontSize(StyleConstants.FONT_SM)
              .fontColor(StyleConstants.TEXT_WHITE_SUB)
              .margin({ top: 4 })
          }
          .margin({ left: 16 })
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          // 大棚数量徽章
          Column() {
            Text(this.greenhouseCount.toString())
              .fontSize(StyleConstants.FONT_XXL)
              .fontColor(StyleConstants.TEXT_WHITE)
              .fontWeight(FontWeight.Bold)
            Text('大棚')
              .fontSize(StyleConstants.FONT_XS)
              .fontColor(StyleConstants.TEXT_WHITE_SUB)
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

  // ==================== 菜单分组卡片 ====================
  @Builder
  MenuGroup(group: MenuItem[]) {
    Column() {
      ForEach(group, (item: MenuItem, index: number) => {
        this.MenuItemRow(item, index === group.length - 1)
      })
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 6, bottom: 6 })
    .backgroundColor(StyleConstants.BG_CARD)
    .borderRadius(StyleConstants.RADIUS_LG)
    .shadow({
      radius: 4,
      color: '#0A000000',
      offsetX: 0,
      offsetY: 1
    })
  }

  @Builder
  MenuItemRow(item: MenuItem, isLast: boolean) {
    Row() {
      // 图标背景
      Text(item.icon)
        .fontSize(20)
        .width(36)
        .height(36)
        .textAlign(TextAlign.Center)
        .borderRadius(18)
        .backgroundColor(StyleConstants.BG_CARD_LIGHT)

      Column() {
        Text(item.title)
          .fontSize(StyleConstants.FONT_MD)
          .fontColor(StyleConstants.TEXT_TITLE)
          .fontWeight(FontWeight.Medium)
        Text(item.subtitle)
          .fontSize(StyleConstants.FONT_XS)
          .fontColor(StyleConstants.TEXT_HINT)
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 12 })

      Text('›')
        .fontSize(StyleConstants.FONT_LG)
        .fontColor(StyleConstants.TEXT_HINT)
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
    .border({ width: { bottom: isLast ? 0 : 0.5 }, color: StyleConstants.BORDER_LIGHT })
    .onClick(() => {
      this.onMenuClick(item.id);
    })
  }

  private onMenuClick(id: string): void {
    let target: string = '';
    if (id === 'alerts') {
      target = 'AlertPage';
    } else if (id === 'growth') {
      target = 'GrowthPage';
    } else if (id === 'recipe') {
      target = 'RecipePage';
    }
    if (target.length > 0) {
      try {
        const stack = AppStorage.get<NavPathStack>('navPathStack');
        if (stack) {
          stack.pushPath({ name: target });
        }
      } catch {
        // ignore
      }
    }
  }
}
