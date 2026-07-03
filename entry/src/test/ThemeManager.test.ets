import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { ThemeManager } from 'features-core';

export default function themeManagerTest() {
  describe('ThemeManager', () => {
    beforeAll(() => {});
    beforeEach(() => {});
    afterEach(() => {});
    afterAll(() => {});

    describe('getTokens() / isFrosted()', () => {
      it('getTokens() 默认返回 frosted 主题', 0, () => {
        const mgr = ThemeManager.getInstance();
        mgr.setTheme('frosted');
        const tokens = mgr.getTokens();
        expect(tokens != null).assertTrue();
        expect(tokens.name).assertEqual('frosted');
      });

      it('isFrosted() 默认为 true', 0, () => {
        const mgr = ThemeManager.getInstance();
        mgr.setTheme('frosted');
        expect(mgr.isFrosted()).assertTrue();
      });
    });

    describe('setTheme()', () => {
      it('setTheme("contrast") 后 isFrosted() 为 false', 0, () => {
        const mgr = ThemeManager.getInstance();
        mgr.setTheme('contrast');
        expect(mgr.isFrosted()).assertFalse();
      });

      it('setTheme("frosted") 后 isFrosted() 为 true', 0, () => {
        const mgr = ThemeManager.getInstance();
        mgr.setTheme('contrast');
        mgr.setTheme('frosted');
        expect(mgr.isFrosted()).assertTrue();
      });

      it('setTheme("unknown") 回退到 frosted 主题', 0, () => {
        const mgr = ThemeManager.getInstance();
        mgr.setTheme('unknown-theme');
        expect(mgr.isFrosted()).assertTrue();
      });

      it('setTheme("contrast") 后 getTokens().name 为 "contrast"', 0, () => {
        const mgr = ThemeManager.getInstance();
        mgr.setTheme('contrast');
        expect(mgr.getTokens().name).assertEqual('contrast');
      });
    });

    describe('toggle()', () => {
      it('toggle() 在 frosted 时切换到 contrast', 0, () => {
        const mgr = ThemeManager.getInstance();
        mgr.setTheme('frosted');
        expect(mgr.isFrosted()).assertTrue();
        mgr.toggle();
        expect(mgr.isFrosted()).assertFalse();
        expect(mgr.getTokens().name).assertEqual('contrast');
      });

      it('toggle() 在 contrast 时切换回 frosted', 0, () => {
        const mgr = ThemeManager.getInstance();
        mgr.setTheme('contrast');
        expect(mgr.isFrosted()).assertFalse();
        mgr.toggle();
        expect(mgr.isFrosted()).assertTrue();
        expect(mgr.getTokens().name).assertEqual('frosted');
      });

      it('连续 toggle() 两次回到原主题', 0, () => {
        const mgr = ThemeManager.getInstance();
        mgr.setTheme('frosted');
        mgr.toggle();
        mgr.toggle();
        expect(mgr.isFrosted()).assertTrue();
      });
    });
  });
}
