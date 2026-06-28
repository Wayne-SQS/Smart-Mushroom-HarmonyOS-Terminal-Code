/**
 * IotService 使用示例（应用侧 API 版本）
 *
 * 演示如何初始化、查询 smartRoom 服务属性、控制灯/风扇/空调开关。
 *
 * ⚠️ 凭据安全：真实凭据请从 IotConfig.ets 导入，切勿硬编码到示例代码。
 *   参照 entry/src/main/ets/entryability/IotConfig.example.ets 配置。
 */
import { IotService } from './IotService';
import type { IotAppConfig, SmartRoomProperties } from './IotTypes';

const IOT_CONFIG: IotAppConfig = {
  username: '<YOUR_IAM_USERNAME>',
  password: '<YOUR_IAM_PASSWORD>',
  domainName: '<YOUR_DOMAIN_NAME>',
  region: 'cn-north-4',
  iotdaEndpoint: '<YOUR_IOTDA_ENDPOINT>.iotda-app.cn-north-4.myhuaweicloud.com',
  projectId: '<YOUR_PROJECT_ID>',
  deviceId: '<YOUR_DEVICE_ID>'
};

/** 初始化 IoT 服务（应用启动时调用一次） */
function exampleInit(): void {
  const iot = IotService.getInstance();
  iot.init(IOT_CONFIG);
}

/** 查询 smartRoom 服务属性（强类型） */
async function exampleGetSmartRoomProperties(): Promise<void> {
  const iot = IotService.getInstance();
  const props: SmartRoomProperties | null = await iot.getSmartRoomProperties();
  if (props) {
    console.info('温度 Temp：' + props.Temp + ' °C');
    console.info('湿度 Humi：' + props.Humi + ' %');
    console.info('光照 Lumi：' + props.Lumi);
    console.info('CO₂：' + props.CO2 + ' ppm');
    console.info('烟雾 Smoke：' + props.Smoke);
    console.info('灯状态 LampST：' + props.LampST);
    console.info('空调状态 CondST：' + props.CondST);
    console.info('风扇状态 VentST：' + props.VentST);
  } else {
    console.warn('未获取到 smartRoom 属性数据');
  }
}

/** 通用查询影子原始数据（调试用） */
async function exampleQueryShadow(): Promise<void> {
  const iot = IotService.getInstance();
  const shadow = await iot.queryDeviceShadow();
  console.info('设备影子数据：' + JSON.stringify(shadow));
}

/** 按服务 ID 取属性（通用） */
async function exampleGetProperties(): Promise<void> {
  const iot = IotService.getInstance();
  const props = await iot.getDeviceProperties('smartRoom');
  if (props) {
    console.info('smartRoom 属性：' + JSON.stringify(props));
  } else {
    console.warn('未找到 smartRoom 服务');
  }
}

/** 控制灯（补光） — 对应硬件 SetLamp 命令 */
async function exampleControlLight(): Promise<void> {
  const iot = IotService.getInstance();
  await iot.controlLight(true);   // 开灯
  await iot.controlLight(false);  // 关灯
}

/** 控制排风扇 — 对应硬件 SetVent 命令 */
async function exampleControlFan(): Promise<void> {
  const iot = IotService.getInstance();
  await iot.controlFan(true);
  await iot.controlFan(false);
}

/** 控制空调 — 对应硬件 SetCond 命令 */
async function exampleControlCondi(): Promise<void> {
  const iot = IotService.getInstance();
  await iot.controlCondi(true);
  await iot.controlCondi(false);
}

/** 设备在线检测 */
async function exampleCheckOnline(): Promise<void> {
  const iot = IotService.getInstance();
  const online = await iot.isDeviceOnline();
  console.info('设备在线：' + online);
}
