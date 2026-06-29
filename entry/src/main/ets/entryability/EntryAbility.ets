import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { IotService, ThemeManager } from 'features-core';
import { IOT_CONFIG } from './IotConfig';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    // 锁定浅色模式：双主题（雾透/黑白）均在浅色底色上设计，
    // 跟随系统深色会导致淡彩 token 被系统反转 → 发黄
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }

    // 初始化 IoT 服务（应用侧 API），全局单例，所有 ViewModel 共用
    try {
      IotService.getInstance().init(IOT_CONFIG);
      hilog.info(DOMAIN, 'testTag', '%{public}s', 'IoT service initialized');
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to init IoT service. Cause: %{public}s', JSON.stringify(err));
    }

    // 主题初始化（同步）：
    // PersistentStorage.persistProp 在构造函数自动从磁盘恢复 → AppStorage
    // init() 仅同步 current 字段到 ThemeManager
    try {
      ThemeManager.getInstance().init();
      hilog.info(DOMAIN, 'testTag', '%{public}s', 'Theme manager initialized');
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to init theme manager. Cause: %{public}s', JSON.stringify(err));
    }

    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}