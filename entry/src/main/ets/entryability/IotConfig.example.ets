/**
 * 华为云 IoTDA 应用侧 API 配置模板
 *
 * 使用方法：
 * 1. 复制此文件为 IotConfig.ets（同目录下）
 * 2. 填入你的华为云 IoTDA 凭据
 * 3. IotConfig.ets 已被 .gitignore 排除，不会提交到仓库
 *
 * 凭据获取路径：华为云控制台 → IoTDA → 设备接入 → 应用侧 API 对接信息
 */
import { IotAppConfig } from 'features-core';

export const IOT_CONFIG: IotAppConfig = {
  username: '<YOUR_IAM_USERNAME>',
  password: '<YOUR_IAM_PASSWORD>',
  domainName: '<YOUR_DOMAIN_NAME>',
  region: 'cn-north-4',
  iotdaEndpoint: '<YOUR_IOTDA_ENDPOINT>.iotda-app.cn-north-4.myhuaweicloud.com',
  projectId: '<YOUR_PROJECT_ID>',
  deviceId: '<YOUR_DEVICE_ID>'
};
