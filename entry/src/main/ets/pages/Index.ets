import { StyleConstants, BreakpointConstants, AdaptiveUtils } from 'common-base';
import { DashboardPage, DevicePage, MapPage, ProfilePage, AlertPage, GrowthPage, RecipePage } from 'features-core';
import { AppRouter } from './AppRouter';

/**
 * 应用入口页 - 一次开发多端部署
 *
 * 多端适配策略：
 * 1. Navigation Auto 模式：窄屏 Stack 推入式 / 宽屏 Split 分栏（系统自动选择）
 * 2. Tabs 位置自适应：
 *    - 窄屏（XS/SM）→ 底部横向 Tabs（barPosition=End）
 *    - 宽屏（MD/LG/XL）→ 左侧竖向导航栏（自定义 SideNavBar）
 * 3. XL 屏内容限宽：由各页面内部统一处理（AdaptiveUtils.getMaxContentWidth）
 * 4. 断点通过 onAreaChange 监听窗口尺寸变化，写入 AppStorage 全局共享
 */

@Entry
@Component
struct Index {
  @State currentIndex: number = 0;
  @State navPathStack: NavPathStack = AppRouter.getStack();
  @State currentBreakpoint: string = BreakpointConstants.SM;

  private tabs: TabItem[] = [
    { title: '首页', icon: '🏠' },
    { title: '设备', icon: '📱' },
    { title: '地图', icon: '📍' },
    { title: '我的', icon: '👤' }
  ];

  aboutToAppear(): void {
    AppStorage.setOrCreate<NavPathStack>('navPathStack', this.navPathStack);
    AppStorage.setOrCreate<string>('currentBreakpoint', this.currentBreakpoint);
  }

  /** 是否使用侧栏导航（宽屏） */
  private isSideBarLayout(): boolean {
    return AdaptiveUtils.isDualPane(this.currentBreakpoint);
  }

  build() {
    Row() {
      // 宽屏：左侧竖向导航栏
      if (this.isSideBarLayout()) {
        this.SideNavBar()
      }

      // 主内容区
      Column() {
        if (this.isSideBarLayout()) {
          // 宽屏：内容区 + 顶部不显示 tabBar（已用 SideNavBar 替代）
          this.TabContentArea()
        } else {
          // 窄屏：Tabs 在底部
          this.TabsBottom()
        }
      }
      .layoutWeight(1)
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .onAreaChange((_: Area, newArea: Area) => {
      const w = newArea.width as number;
      let bp = BreakpointConstants.SM;
      if (w >= BreakpointConstants.BREAKPOINT_XL) {
        bp = BreakpointConstants.XL;
      } else if (w >= BreakpointConstants.BREAKPOINT_LG) {
        bp = BreakpointConstants.LG;
      } else if (w >= BreakpointConstants.BREAKPOINT_MD) {
        bp = BreakpointConstants.MD;
      } else if (w >= BreakpointConstants.BREAKPOINT_SM) {
        bp = BreakpointConstants.SM;
      } else {
        bp = BreakpointConstants.XS;
      }
      if (bp !== this.currentBreakpoint) {
        this.currentBreakpoint = bp;
        AppStorage.setOrCreate<string>('currentBreakpoint', bp);
      }
    })
  }

  /** 窄屏：底部 Tabs */
  @Builder
  TabsBottom() {
    Tabs({ barPosition: BarPosition.End, index: this.currentIndex }) {
      TabContent() {
        DashboardPage()
      }
      .tabBar(this.TabBuilder(0))

      TabContent() {
        DevicePage()
      }
      .tabBar(this.TabBuilder(1))

      TabContent() {
        MapPage()
      }
      .tabBar(this.TabBuilder(2))

      TabContent() {
        ProfilePage()
      }
      .tabBar(this.TabBuilder(3))
    }
    .scrollable(false)
    .barMode(BarMode.Fixed)
    .barHeight(56)
    .onChange((index: number) => {
      this.currentIndex = index;
    })
    .width('100%')
    .height('100%')
  }

  /** 宽屏：仅内容区，导航由 SideNavBar 承担 */
  @Builder
  TabContentArea() {
    Navigation(this.navPathStack) {
      Column() {
        if (this.currentIndex === 0) {
          DashboardPage()
        } else if (this.currentIndex === 1) {
          DevicePage()
        } else if (this.currentIndex === 2) {
          MapPage()
        } else {
          ProfilePage()
        }
      }
      .width('100%')
      .height('100%')
    }
    .mode(NavigationMode.Auto)
    .hideTitleBar(true)
    .navDestination(this.PageDestination)
    .width('100%')
    .height('100%')
  }

  /** 侧栏导航（宽屏专用） */
  @Builder
  SideNavBar() {
    Column() {
      // 顶部 Logo
      Column() {
        Text('🍄')
          .fontSize(32)
        Text('蘑菇大棚')
          .fontSize(StyleConstants.FONT_SM)
          .fontColor(StyleConstants.TEXT_SUB)
          .margin({ top: 4 })
      }
      .width('100%')
      .padding({ top: 24, bottom: 16 })
      .alignItems(HorizontalAlign.Center)

      // 竖向菜单
      Column() {
        ForEach(this.tabs, (tab: TabItem, index: number) => {
          this.SideNavItem(tab, index)
        })
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ top: 8 })

      // 底部版本信息
      Text('v1.0.0')
        .fontSize(StyleConstants.FONT_XS)
        .fontColor(StyleConstants.TEXT_HINT)
        .padding({ bottom: 16 })
    }
    .width(96)
    .height('100%')
    .backgroundColor(StyleConstants.BG_CARD)
    .border({ width: { right: 0.5 }, color: StyleConstants.BORDER_LIGHT })
  }

  @Builder
  SideNavItem(tab: TabItem, index: number) {
    Column() {
      Text(tab.icon)
        .fontSize(24)
      Text(tab.title)
        .fontSize(StyleConstants.FONT_XS)
        .fontColor(this.currentIndex === index ? StyleConstants.PRIMARY : StyleConstants.TEXT_SUB)
        .margin({ top: 4 })
    }
    .width('100%')
    .height(64)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.currentIndex === index ? StyleConstants.PRIMARY + '14' : StyleConstants.BG_CARD)
    .border({
      width: { left: 3 },
      color: this.currentIndex === index ? StyleConstants.PRIMARY : 'transparent'
    })
    .margin({ bottom: 4 })
    .onClick(() => {
      this.currentIndex = index;
    })
  }

  @Builder
  PageDestination(name: string) {
    if (name === 'AlertPage') {
      AlertPage()
    } else if (name === 'GrowthPage') {
      GrowthPage()
    } else if (name === 'RecipePage') {
      RecipePage()
    }
  }

  @Builder
  TabBuilder(index: number) {
    Column() {
      Text(this.tabs[index].icon)
        .fontSize(22)
        .fontColor(this.currentIndex === index ? StyleConstants.PRIMARY : StyleConstants.TEXT_HINT)
      Text(this.tabs[index].title)
        .fontSize(StyleConstants.FONT_XS)
        .fontColor(this.currentIndex === index ? StyleConstants.PRIMARY : StyleConstants.TEXT_HINT)
        .margin({ top: 2 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}

interface TabItem {
  title: string;
  icon: string;
}
