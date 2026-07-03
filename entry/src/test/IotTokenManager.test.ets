import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { IotTokenManager } from 'features-core';

export default function iotTokenManagerTest() {
  describe('IotTokenManager', () => {
    beforeAll(() => {});
    beforeEach(() => {});
    afterEach(() => {});
    afterAll(() => {});

    describe('getToken() / setToken()', () => {
      it('初始 getToken() 返回 null', 0, () => {
        const mgr = new IotTokenManager();
        mgr.clearToken();
        expect(mgr.getToken()).assertNull();
      });

      it('setToken() 后 getToken() 返回设置的 token', 0, () => {
        const mgr = new IotTokenManager();
        mgr.setToken('test-token-123', 3600);
        expect(mgr.getToken()).assertEqual('test-token-123');
      });

      it('getToken/setToken: clearToken() 后 getToken() 返回 null', 0, () => {
        const mgr = new IotTokenManager();
        mgr.setToken('initial-token', 3600);
        mgr.clearToken();
        expect(mgr.getToken()).assertNull();
      });
    });

    describe('isTokenValid()', () => {
      it('无 token 时 isTokenValid() 为 false', 0, () => {
        const mgr = new IotTokenManager();
        mgr.clearToken();
        expect(mgr.isTokenValid()).assertFalse();
      });

      it('有效 token 时 isTokenValid() 为 true', 0, () => {
        const mgr = new IotTokenManager();
        mgr.setToken('valid-token-abc', 3600);
        expect(mgr.isTokenValid()).assertTrue();
      });
    });

    describe('clearToken()', () => {
      it('clearToken: clearToken() 后 getToken() 返回 null', 0, () => {
        const mgr = new IotTokenManager();
        mgr.setToken('temp-token', 3600);
        mgr.clearToken();
        expect(mgr.getToken()).assertNull();
      });

      it('clearToken() 后 isTokenValid() 为 false', 0, () => {
        const mgr = new IotTokenManager();
        mgr.setToken('temp-token', 3600);
        mgr.clearToken();
        expect(mgr.isTokenValid()).assertFalse();
      });
    });
  });
}
