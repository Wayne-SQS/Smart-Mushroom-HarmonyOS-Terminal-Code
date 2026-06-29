/**
 * 主题管理器单例
 *
 * 架构（社区最佳实践）：
 *   PersistentStorage.persistProp('themeName', 'frosted')
 *     → AppStorage 全局唯一真相源 + 自动磁盘持久化
 *     → @StorageLink 双向绑定到所有页面
 *     → 组件写 this.themeName = newValue → 自动同步全部页面 + 磁盘
 *
 * ThemeManager 只负责：持有 theme token 映射 + setTheme 同步更新
 * 不再手动操作 preferences，完全交由 PersistentStorage 处理。
 */
import { ThemeTokens } from './ThemeTokens';
import { FROSTED_THEME } from './ThemeFrosted';
import { CONTRAST_THEME } from './ThemeContrast';

const THEME_FROSTED = 'frosted';
const THEME_CONTRAST = 'contrast';

export class ThemeManager {
  private static instance: ThemeManager;
  private current: ThemeTokens = FROSTED_THEME;

  private constructor() {
    // 持久化绑定：AppStorage('themeName') 的变更自动写入磁盘
    PersistentStorage.persistProp('themeName', THEME_FROSTED);
  }

  static getInstance(): ThemeManager {
    if (!ThemeManager.instance) {
      ThemeManager.instance = new ThemeManager();
    }
    return ThemeManager.instance;
  }

  /**
   * 从 AppStorage 恢复主题状态到 this.current（由 EntryAbility 调用一次）
   * 由于 PersistentStorage.persistProp 会在构造时自动从磁盘恢复，
   * 这里只需同步 current 字段。
   */
  init(): void {
    const name = AppStorage.get<string>('themeName');
    if (name === THEME_CONTRAST) {
      this.current = CONTRAST_THEME;
    } else {
      this.current = FROSTED_THEME;
    }
  }

  getTokens(): ThemeTokens {
    return this.current;
  }

  isFrosted(): boolean {
    return this.current.name === THEME_FROSTED;
  }

  /**
   * 切换主题（同步更新 current，AppStorage 由组件 @StorageLink 写入）
   *
   * 必须在 @StorageLink 写入之前调用，确保 rebuild 时 getTokens() 返回新主题。
   */
  setTheme(themeName: string): void {
    this.current = (themeName === THEME_CONTRAST) ? CONTRAST_THEME : FROSTED_THEME;
  }

  /** 在两个主题间切换 */
  toggle(): void {
    this.current = this.isFrosted() ? CONTRAST_THEME : FROSTED_THEME;
  }
}
