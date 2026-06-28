/**
 * 华为云 IoT 设备鉴权工具
 *
 * 使用 HMAC-SHA256 算法，以时间戳为密钥对 device_secret 进行加密，
 * 生成设备鉴权所需的 password 参数。
 */
import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { buffer } from '@kit.ArkTS';
import { Logger } from 'common-base';

const TAG = 'IotAuth';

export class IotAuthUtil {
  /**
   * 生成设备鉴权密码
   * password = HMAC-SHA256(timestamp, secret)，结果转为 64 位十六进制字符串
   *
   * @param secret 设备密钥（在 IoT 平台注册设备时获取）
   * @param timestamp 时间戳，格式：YYYYMMDDHH
   * @returns 加密后的 64 位十六进制密码字符串
   */
  static async generatePassword(secret: string, timestamp: string): Promise<string> {
    try {
      // 1. 创建 HMAC 对称密钥生成器
      const symKeyGenerator = cryptoFramework.createSymKeyGenerator('HMAC');

      // 2. 将时间戳转为 Uint8Array，生成对称密钥
      const symKeyData = new Uint8Array(buffer.from(timestamp).buffer);
      const symKey = await symKeyGenerator.convertKey({ data: symKeyData });

      // 3. 创建 SHA256 消息认证码实例
      const mac = cryptoFramework.createMac('SHA256');

      // 4. 使用时间戳密钥初始化
      await mac.init(symKey);

      // 5. 传入待加密数据（设备密钥）
      await mac.update({
        data: new Uint8Array(buffer.from(secret, 'utf-8').buffer)
      });

      // 6. 获取加密结果
      const result = await mac.doFinal();

      // 7. 转为 64 位十六进制字符串
      let password = '';
      if (result && result.data) {
        result.data.forEach((item: number) => {
          password += item.toString(16).padStart(2, '0');
        });
      }

      Logger.info(TAG, '密码生成成功，长度：' + password.length);
      return password;
    } catch (err) {
      Logger.error(TAG, '密码生成失败');
      throw new Error('密码生成失败: ' + String(err));
    }
  }

  /**
   * 生成当前时间戳（格式：YYYYMMDDHH）
   */
  static generateTimestamp(): string {
    const now = new Date();
    const year = now.getUTCFullYear().toString();
    const month = (now.getUTCMonth() + 1).toString().padStart(2, '0');
    const day = now.getUTCDate().toString().padStart(2, '0');
    const hour = now.getUTCHours().toString().padStart(2, '0');
    return year + month + day + hour;
  }

  /**
   * 生成 UTC 事件时间（格式：YYYY-MM-DDTHH:mm:ss.SSSZ）
   */
  static generateEventTime(): string {
    const now = new Date();
    const year = now.getUTCFullYear();
    const month = (now.getUTCMonth() + 1).toString().padStart(2, '0');
    const day = now.getUTCDate().toString().padStart(2, '0');
    const hours = now.getUTCHours().toString().padStart(2, '0');
    const minutes = now.getUTCMinutes().toString().padStart(2, '0');
    const seconds = now.getUTCSeconds().toString().padStart(2, '0');
    const millis = now.getUTCMilliseconds().toString().padStart(3, '0');
    return year + '-' + month + '-' + day + 'T' + hours + ':' + minutes + ':' + seconds + '.' + millis + 'Z';
  }
}
