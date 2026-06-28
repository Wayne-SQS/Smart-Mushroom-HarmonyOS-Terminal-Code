/**
 * 华为云 IAM 鉴权工具（应用侧 API）
 *
 * 通过用户名/密码向 IAM 服务换取 X-Subject-Token，
 * 该 token 作为 X-Auth-Token 用于后续 IoTDA 应用侧接口调用。
 *
 * 参考实现：wanglian/pages/DisplayPage.ets L17-L59
 * 官方文档：https://support.huaweicloud.com/api-iam/iam_30_0001.html
 */
import { http } from '@kit.NetworkKit';
import { Logger } from 'common-base';
import type { IotAppConfig, IamAuthRequest } from './IotTypes';

const TAG = 'IamAuthUtil';

/** IAM 鉴权服务固定地址前缀（按 region 拼接） */
const IAM_HOST = 'iam.cn-north-4.myhuaweicloud.com';
const IAM_PATH = '/v3/auth/tokens';

export class IamAuthUtil {
  /**
   * 申请 X-Subject-Token
   *
   * 流程：
   * 1. 用 config 构造 IamAuthRequest
   * 2. POST 到 IAM 接口
   * 3. 从响应 header 提取 'x-subject-token'
   *
   * @param config 应用侧 API 配置（含 IAM 账号信息）
   * @returns X-Subject-Token 字符串
   * @throws 网络异常 / HTTP 非 201 / header 缺失 token 时抛出
   */
  static async requestToken(config: IotAppConfig): Promise<string> {
    const requestBody: IamAuthRequest = {
      auth: {
        identity: {
          methods: ['password'],
          password: {
            user: {
              name: config.username,
              password: config.password,
              domain: { name: config.domainName }
            }
          }
        },
        scope: {
          project: { name: config.region }
        }
      }
    };

    const url = 'https://' + IAM_HOST + IAM_PATH;
    Logger.info(TAG, '开始申请 IAM Token，URL：' + url);

    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': 'application/json' },
        extraData: JSON.stringify(requestBody)
      });

      // IAM 接口成功返回 201
      if (response.responseCode !== 201 && response.responseCode !== 200) {
        Logger.error(TAG, 'IAM 鉴权失败：HTTP ' + response.responseCode);
        throw new Error('IAM 鉴权失败：HTTP ' + response.responseCode);
      }

      // 从 header 提取 X-Subject-Token
      const token = response.header['x-subject-token'] as string;
      if (!token) {
        Logger.error(TAG, '响应中未找到 x-subject-token');
        throw new Error('IAM 响应缺失 X-Subject-Token');
      }

      Logger.info(TAG, 'IAM Token 获取成功，长度：' + token.length);
      return token;
    } catch (err) {
      Logger.error(TAG, 'IAM 请求异常');
      throw new Error('IAM 请求异常: ' + String(err));
    } finally {
      httpRequest.destroy();
    }
  }
}
