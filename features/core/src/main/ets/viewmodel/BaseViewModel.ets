import { Logger } from 'common-base';

const TAG = 'BaseViewModel';

/**
 * ViewModel 抽象基类
 *
 * 提供通用状态管理（loading / error / timestamp）与异步错误处理能力。
 * 所有业务 ViewModel 应继承本类并实现 loadData()。
 *
 * 设计要点：
 * - 纯 TS 类，不使用 ArkTS 装饰器
 * - 所有 async 操作由 handleAsync 统一包装 try-catch
 * - 失败时返回 null，调用方据此降级到 mock 数据
 */
export abstract class BaseViewModel {
  /** 是否正在加载 */
  isLoading: boolean = false;
  /** 错误信息（空字符串表示无错误） */
  errorMsg: string = '';
  /** 最后一次成功更新时间（格式：YYYY-MM-DD HH:mm:ss） */
  lastUpdateTime: string = '';

  /** 设置加载状态 */
  protected setLoading(state: boolean): void {
    this.isLoading = state;
  }

  /** 设置错误信息 */
  protected setError(msg: string): void {
    this.errorMsg = msg;
  }

  /** 更新最后更新时间戳为当前时间 */
  protected updateTimestamp(): void {
    this.lastUpdateTime = this.formatNow();
  }

  /**
   * 统一异步操作包装：
   * - 自动管理 loading 状态
   * - try-catch 捕获异常并写入 errorMsg
   * - 失败时返回 null，调用方据此降级
   *
   * @param fn 异步操作函数
   * @returns 成功返回函数结果，失败返回 null
   */
  protected async handleAsync<T>(fn: () => Promise<T>): Promise<T | null> {
    this.setLoading(true);
    this.setError('');
    try {
      const result = await fn();
      this.updateTimestamp();
      return result;
    } catch (err) {
      let msg = '操作失败';
      if (err instanceof Error) {
        msg = err.message;
      } else if (typeof err === 'string') {
        msg = err;
      }
      this.setError(msg);
      Logger.error(TAG, '异步操作失败：' + msg);
      return null;
    } finally {
      this.setLoading(false);
    }
  }

  /** 子类必须实现：加载数据 */
  abstract loadData(): Promise<void>;

  /** 格式化当前时间为 YYYY-MM-DD HH:mm:ss */
  private formatNow(): string {
    const date = new Date();
    const year = date.getFullYear();
    const month = this.padZero(date.getMonth() + 1);
    const day = this.padZero(date.getDate());
    const hour = this.padZero(date.getHours());
    const minute = this.padZero(date.getMinutes());
    const second = this.padZero(date.getSeconds());
    return year + '-' + month + '-' + day + ' ' + hour + ':' + minute + ':' + second;
  }

  /** 数字补零（< 10 前面补 0） */
  private padZero(n: number): string {
    return n < 10 ? '0' + n : '' + n;
  }
}
