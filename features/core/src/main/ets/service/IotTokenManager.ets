/**
 * 华为云 IoT 设备 Token 管理器
 *
 * 负责 access_token 的缓存、过期判断，避免重复鉴权。
 * 在设备侧使用，token 过期后自动重新获取。
 */
import { Logger } from 'common-base';

const TAG = 'IotTokenManager';

export class IotTokenManager {
  private accessToken: string = '';
  private tokenExpireAt: number = 0; // 过期时间戳（毫秒）

  /**
   * 存储 token 及过期时间
   */
  setToken(token: string, expiresInSeconds: number): void {
    this.accessToken = token;
    this.tokenExpireAt = Date.now() + expiresInSeconds * 1000;
    Logger.info(TAG, `Token 已缓存，有效期至：${new Date(this.tokenExpireAt).toISOString()}`);
  }

  /**
   * 获取有效的 token，过期返回 null
   */
  getToken(): string | null {
    if (this.accessToken && Date.now() < this.tokenExpireAt - 60000) {
      // 提前 1 分钟刷新，避免临界过期
      return this.accessToken;
    }
    Logger.warn(TAG, 'Token 已过期或不存在');
    return null;
  }

  /**
   * 检查 token 是否有效
   */
  isTokenValid(): boolean {
    return this.getToken() !== null;
  }

  /**
   * 清除 token
   */
  clearToken(): void {
    this.accessToken = '';
    this.tokenExpireAt = 0;
    Logger.info(TAG, 'Token 已清除');
  }
}
