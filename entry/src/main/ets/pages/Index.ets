import { BreakpointConstants, AdaptiveUtils } from 'common-base';
import {
  DashboardPage,
  DevicePage,
  MapPage,
  ProfilePage,
  AlertPage,
  GrowthPage,
  RecipePage,
  VideoMonitorPage,
  ThemeManager,
  ThemeTokens
} from 'features-core';
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
  /** 监听主题切换，框架自动触发 build() 重绘 */
  @StorageLink('themeName') themeName: string = 'frosted';

  /** 一行获取当前主题 token（主题切换后 build() 重跑，自动取到新值） */
  t(): ThemeTokens {
    return ThemeManager.getInstance().getTokens();
  }

  private tabs: TabItem[] = [
    { title: '首页', icon: 'home' },
    { title: '设备', icon: 'device' },
    { title: '地图', icon: 'map' },
    { title: '我的', icon: 'profile' }
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

  /**
   * 窄屏：底部 Tabs（毛玻璃 TabBar）
   *
   * 关键设计：每个 TabContent 内使用 if/else 条件渲染子页面。
   * 为什么不用 TabContent { DashboardPage() } 直接嵌套？
   *   Tabs 组件会保留所有 TabContent 子组件实例，非活跃页面的
   *   @StorageLink('themeName') 可能不会触发 build()，导致切回时
   *   仍显示旧主题颜色。条件渲染确保切页时旧页面销毁、新页面重建，
   *   新建时从 ThemeManager 读取最新主题，与宽屏布局行为一致。
   */
  @Builder
  TabsBottom() {
    // 用 Navigation 包裹 Tabs，让窄屏也能响应 navPathStack.pushPath
    // （否则 MapPage 等 TabContent 内的页面无法跳转到 NavDestination 子页）
    Navigation(this.navPathStack) {
      Tabs({ barPosition: BarPosition.End, index: this.currentIndex }) {
        TabContent() {
          if (this.currentIndex === 0) {
            DashboardPage()
          }
        }
        .tabBar(this.TabBuilder(0))

        TabContent() {
          if (this.currentIndex === 1) {
            DevicePage()
          }
        }
        .tabBar(this.TabBuilder(1))

        TabContent() {
          if (this.currentIndex === 2) {
            MapPage()
          }
        }
        .tabBar(this.TabBuilder(2))

        TabContent() {
          if (this.currentIndex === 3) {
            ProfilePage()
          }
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
      // 毛玻璃 TabBar：半透白底 + backdropBlur 模糊下层内容 + 顶边白线
      .backgroundColor(this.t().bgTabBar)
      .backdropBlur(this.t().blurAmount)
      .border({ width: { top: 0.5 }, color: this.t().border })
    }
    .mode(NavigationMode.Stack)
    .hideTitleBar(true)
    .navDestination(this.PageDestination)
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
    .mode(NavigationMode.Stack)
    .hideTitleBar(true)
    .navDestination(this.PageDestination)
    .width('100%')
    .height('100%')
  }

  /**
   * 导航矢量图标（纯几何绘制，多端统一，替代 emoji）
   *
   * 设计基准 20×20vp，与 MapPage.MapIcon 风格一致：
   * 纯 Circle/Rect/Path/Stack 组合，color 参数着色，主题感知。
   * 类型：home（首页）/ device（设备）/ map（地图）/ profile（我的）
   */
  @Builder
  NavIcon(type: string, color: string) {
    if (type === 'home') {
      // 房子：屋顶三角（Path）+ 房身（圆角 Rect）
      Column({ space: -2 }) {
        Path()
          .width(20).height(10)
          .commands('M1 9 L10 1 L19 9 Z')
          .fill(color)
        Rect({ width: 13, height: 9 }).fill(color).borderRadius(1.5)
      }
      .width(20).height(20)
      .justifyContent(FlexAlign.Center)
    } else if (type === 'device') {
      // 手机：圆角外框 + 底部 home 圆点
      Column() {
        Rect({ width: 11, height: 16 })
          .fill(Color.Transparent)
          .border({ width: 1.5, color: color })
          .borderRadius(2.5)
        Circle({ width: 2, height: 2 }).fill(color).margin({ top: 1 })
      }
      .width(20).height(20)
      .justifyContent(FlexAlign.Center)
    } else if (type === 'map') {
      // 地图图钉：实心圆 + 旋转方块尾
      Column({ space: -3 }) {
        Circle({ width: 11, height: 11 }).fill(color)
        Rect({ width: 5, height: 5 }).fill(color).rotate({ angle: 45 })
      }
      .width(20).height(20)
      .justifyContent(FlexAlign.Center)
    } else if (type === 'profile') {
      // 人形：圆头 + 圆角肩膀
      Column({ space: -1 }) {
        Circle({ width: 8, height: 8 }).fill(color)
        Rect({ width: 14, height: 7 }).fill(color).borderRadius(3.5)
      }
      .width(20).height(20)
      .justifyContent(FlexAlign.Center)
    }
  }

  /** 蘑菇 Logo（侧栏顶部，36×36vp，纯几何） */
  @Builder
  MushroomLogo(color: string) {
    Column({ space: -3 }) {
      Circle({ width: 24, height: 24 }).fill(color)
      Rect({ width: 12, height: 13 }).fill(color).borderRadius(3)
    }
    .width(36).height(36)
    .justifyContent(FlexAlign.Center)
  }

  /** 侧栏导航（宽屏专用，毛玻璃底） */
  @Builder
  SideNavBar() {
    Column() {
      // 顶部 Logo（矢量蘑菇 + 标题，220vp 宽侧栏适配）
      Column() {
        this.MushroomLogo(this.t().primary)
        Text('蘑菇大棚')
          .fontSize(this.t().fontMd)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.t().textTitle)
          .margin({ top: 8 })
      }
      .width('100%')
      .padding({ top: 28, bottom: 20 })
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
        .fontSize(this.t().fontXs)
        .fontColor(this.t().textSub)
        .padding({ bottom: 16 })
    }
    .width(AdaptiveUtils.getSideBarWidth())
    .height('100%')
    // 毛玻璃侧栏：半透底 + backdropBlur + 右边白线
    .backgroundColor(this.t().bgTabBar)
    .backdropBlur(this.t().blurAmount)
    .border({ width: { right: 0.5 }, color: this.t().borderLight })
  }

  @Builder
  SideNavItem(tab: TabItem, index: number) {
    Row() {
      this.NavIcon(tab.icon, this.currentIndex === index ? this.t().primary : this.t().textSub)
      Text(tab.title)
        .fontSize(this.t().fontSm)
        .fontColor(this.currentIndex === index ? this.t().primary : this.t().textSub)
        .margin({ left: 12 })
      Blank()
    }
    .width('100%')
    .height(48)
    .padding({ left: 20, right: 16 })
    .alignItems(VerticalAlign.Center)
    // 选中态：用 bgCardLight 区分（不使用 alpha 拼接）；未选中：透明
    .backgroundColor(this.currentIndex === index ? this.t().bgCardLight : 'transparent')
    .border({
      width: { left: 3 },
      color: this.currentIndex === index ? this.t().primary : 'transparent'
    })
    .margin({ bottom: 4 })
    .onClick(() => {
      this.currentIndex = index;
    })
  }

  @Builder
  PageDestination(name: string) {
    if (name === 'AlertPage') {
      NavDestination() {
        AlertPage()
      }
      .hideTitleBar(true)
    } else if (name === 'GrowthPage') {
      NavDestination() {
        GrowthPage()
      }
      .hideTitleBar(true)
    } else if (name === 'RecipePage') {
      NavDestination() {
        RecipePage()
      }
      .hideTitleBar(true)
    } else if (name === 'DashboardPage') {
      // 复用 DashboardPage 作为大棚详情占位（MapPage "查看详情"跳转目标）
      NavDestination() {
        DashboardPage()
      }
      .hideTitleBar(true)
    } else if (name === 'VideoMonitorPage') {
      // 视频监控页（ESP32-CAM TCP 视频流）
      NavDestination() {
        VideoMonitorPage()
      }
      .hideTitleBar(true)
    }
  }

  @Builder
  TabBuilder(index: number) {
    Column() {
      this.NavIcon(this.tabs[index].icon, this.currentIndex === index ? this.t().primary : this.t().textSub)
      Text(this.tabs[index].title)
        .fontSize(this.t().fontXs)
        .fontColor(this.currentIndex === index ? this.t().primary : this.t().textSub)
        .margin({ top: 4 })
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
