# HarmonyOS 开发知识库

> 本文件为 SoftwareAction 项目的鸿蒙开发外挂知识库,整理官方文档入口、关键 Kit 速查、本项目用到的 API 模式。
> 维护者:Claude(AI 辅助开发);更新策略:遇到新 Kit / API 时即时补充。

---

## 一、官方权威入口

| 入口 | 链接 | 用途 |
|---|---|---|
| 开发者官网 | https://developer.huawei.com/consumer/cn/ | 主入口 |
| 文档中心 | https://developer.huawei.com/consumer/cn/doc/ | 全部文档 |
| 应用开发导读 | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/application-dev-guide | 开发总览 |
| API 参考 V5 | https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/ | 所有 Kit 接口签名 |
| 示例代码 | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/application-dev-sample-V5 | 官方场景示例 |
| Codelabs | https://developer.huawei.com/consumer/cn/codelabs/ | 实战教程 |
| 版本说明 | https://developer.huawei.com/consumer/cn/doc/harmonyos-releases/overview-allversion | 各版本变化 |

---

## 二、核心语言与框架

### ArkTS(优选主力语言)
- 入门:[arkts-get-started](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-get-started)
- 概览:[arkts-overview](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-overview)
- **状态管理 V1 装饰器**:@Entry / @Component / @State / @Prop / @Link / @Provide / @Consume / @Observed / @ObjectLink
- **状态管理 V2 装饰器(新代码优先)**:@ComponentV2 / @ObservedV2 / @Local / @Param / @Event / @Trace
- **本项目当前约定**:沿用 V1,跨多层组件时考虑 V2

### ArkUI(UI 框架)
- 概览:[arkui-overview](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkui-overview)
- 关键组件:`Column / Row / Stack / Scroll / List / GridRow / GridCol / Tabs / Navigation`
- 状态渲染:`if/else` 用于条件渲染,`ForEach` ≤100 项,`LazyForEach + cachedCount + @Reusable` >100 项
- 动画原则:只对 `translate / scale / opacity` 做动画,禁止动画 `width / height / margin / padding`
- 布局深度 ≤5 层,合并同向嵌套

### Stage 模型(应用框架)
- [Ability Kit 概览](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/abilitykit-overview)
- 入口:`UIAbility` → `onWindowStageCreate` → 加载 `pages/Index.ets`
- 本项目入口:`entry/src/main/ets/entryability/EntryAbility.ets`
- 路由:`Navigation + NavPathStack + NavDestination`,大屏自动切 Split 模式

---

## 三、本项目高频 Kit 速查

### 1. NetworkKit(http 模块)— IoT HTTP 请求主力

```typescript
import { http } from '@kit.NetworkKit';

const instance = http.createHttp();
const res = await instance.request(url, {
  method: http.RequestMethod.POST,
  header: { 'Content-Type': 'application/json', 'X-Auth-Token': token },
  extraData: JSON.stringify(body)
});
instance.destroy(); // 必须手动释放
```

- API 参考:[http-V5](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/js-apis-http)
- 注意:`http.createHttp()` 返回的实例用完必须 `destroy()`,否则资源泄漏
- 必须权限:`ohos.permission.INTERNET`(已在 module.json5 配置)

### 2. RemoteCommunicationKit(rcp 模块)— 高级会话(模板代码用)

```typescript
import { rcp } from '@kit.RemoteCommunicationKit';
const session = rcp.createSession();
session.post(url, content).then(res => ...).catch(err => ...);
```

- API 参考:[rcp-V5](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/js-apis-rcp)
- 适用:会话复用、自动重试场景;本项目主路径用 http 模块,rcp 留作模板参考

### 3. CryptoArchitectureKit — HMAC 加密

```typescript
import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { buffer } from '@kit.ArkTS';

const keyGen = cryptoFramework.createSymKeyGenerator('HMAC');
const symKey = await keyGen.convertKey({ data: new Uint8Array(buffer.from(timestamp).buffer) });
const mac = cryptoFramework.createMac('SHA256');
await mac.init(symKey);
await mac.update({ data: new Uint8Array(buffer.from(secret, 'utf-8').buffer) });
const result = await mac.doFinal();
// 转 hex 字符串
```

- API 参考:[cryptoFramework-V5](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/js-apis-cryptoFramework)
- 旧 `IotAuthUtil.generatePassword` 用到,新应用侧 API 改 IAM 不再需要 HMAC,但保留工具

### 4. ArkData / Preferences — 本地持久化

```typescript
import Preferences from '@ohos.data.preferences';
const prefs = await Preferences.getPreferences(ctx, 'login_info');
await prefs.put('username', value);
await prefs.flush(); // 必须 flush 才落盘
const value = await prefs.get('username', '');
```

- API 参考:[@ohos.data.preferences](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/js-apis-data-preferences)
- 场景:登录态记忆、配置缓存、断网降级数据

### 5. NetworkKit(net 模块)— 网络状态

```typescript
import connection from '@ohos.net.connection';
connection.hasDefaultNet().then(has => ...);
```

- 用于 IoT 网络异常时降级到 mock 数据前的检测

### 6. PromptAction / prompt — Toast 提示

```typescript
import promptAction from '@ohos.promptAction';
promptAction.showToast({ message: '操作成功', duration: 1500 });
```

- API 参考:[@ohos.promptAction](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/js-apis-promptAction)
- V5 起 `prompt` 已废弃,优先 `promptAction`

### 7. AbilityKit — UIAbility 与 Want

- 模块入口:`EntryAbility extends UIAbility`
- 生命周期:`onCreate → onWindowStageCreate → onForeground → onBackground → onWindowStageDestroy → onDestroy`
- 跨能力跳转:`context.startAbility(want)`

---

## 四、华为云 IoT 应用侧 API 文档入口(本项目另一根支柱)

> 用户已提供 deviceId / projectId / 鉴权账号,详见 [IotService.ets](../features/core/src/main/ets/service/IotService.ets) 头部常量。

| 接口 | 文档入口 | 本项目用途 |
|---|---|---|
| IAM 获取 Token | https://support.huaweicloud.com/api-iam/iam_30_0001.html | 鉴权,返回 X-Subject-Token |
| IoTDA 设备影子查询 | https://support.huaweicloud.com/api-IoT/iot_06_v5_0072.html | GET 设备当前属性 |
| IoTDA 命令下发 | https://support.huaweicloud.com/api-IoT/iot_06_v5_0038.html | POST 控制灯 |
| IoTDA 设备列表 | https://support.huaweicloud.com/api-IoT/iot_06_v5_0059.html | DevicePage 设备列表 |
| IoTDA 设备状态 | https://support.huaweicloud.com/api-IoT/iot_06_v5_0054.html | 在线/离线判断 |

### IoTDA 平台侧关键文档(开发必看)

| 主题 | 文档入口 | 说明 |
|---|---|---|
| IoTDA 总览 | https://support.huaweicloud.com/iotpad/ | 平台能力总览 |
| **物模型(产品模型)** | https://support.huaweicloud.com/usermanual-iothub/iot_01_000007.html | **必看**:服务/属性/命令在控制台的定义 |
| 设备 MQTT 接入 | https://support.huaweicloud.com/devg-iothub/iot_02_3000.html | 硬件侧(固件)用的接入协议 |
| 设备属性上报 | https://support.huaweicloud.com/devg-iothub/iot_02_3002.html | 硬件 MQTT 上报 JSON 格式 |
| 命令下发格式 | https://support.huaweicloud.com/devg-iothub/iot_02_3005.html | 平台 → 设备的命令 JSON |
| 应用侧 API 总览 | https://support.huaweicloud.com/api-IoT/iot_06_0001.html | 鸿蒙端调用的接口集 |

### 鉴权流程

```
1. POST https://iam.cn-north-4.myhuaweicloud.com/v3/auth/tokens
   Body: { auth: { identity: { methods: ['password'], password: { user: {...} } }, scope: { project: {...} } } }
2. 从响应 header 取 X-Subject-Token
3. 后续所有 IoTDA 请求 header 携带: X-Auth-Token: <token>
4. Token 有效期默认 24h,过期需重新获取
```

### 本项目实际属性(smartRoom 服务)

| 属性名 | 含义 | 取值示例 |
|---|---|---|
| Temp | 温度 °C | "27.7" |
| Humi | 湿度 % | "51.3" |
| Lumi | 光照 | "63" |
| Dist | 距离 cm | "-1" 表示无障碍 |
| LampST | 灯状态 | "ON" / "OFF" |
| CondST | 空调状态 | "ON" / "OFF" |

> **⚠️ 大小写敏感警告**:华为云 IoTDA 影子中的属性键大小写严格区分,鸿蒙端读取时必须与 IoTDA 控制台**物模型定义**完全一致,否则读到 `undefined`。
>
> **本项目最终以控制台物模型为准**:
> - 服务 ID:`smartRoom`
> - 灯状态属性:`LampST`(大写 T)
> - 空调状态属性:`CondST`(大写 T)
>
> **历史代码仅供参考**(命名不一致,不要照抄):
> - `wanglian/21_huaweiiot/mqtt/mqtt.c` 历史上报过 `smartPet` / `LampST`
> - `wanglian/25_smart_home/mqtt/mqtt.c` 历史上报过 `SmartAGR` / `LampSt`(小写 t) / `CondiSt`
>
> 出现数据读不到时,第一时间去 IoTDA 控制台 → 产品 → 物模型 核对属性名,以控制台为准。

### 命令下发格式

```json
POST /v5/iot/{projectId}/devices/{deviceId}/commands
{
  "service_id": "smartRoom",
  "command_name": "Light",
  "paras": { "light": "ON" }
}
```

> **命令命名约定**:命令名(`command_name`)和参数键(`paras.light`)也要与物模型中"命令"页签的定义完全一致。
> 硬件 `wanglian/25_smart_home/mqtt/mqtt.c` 接收的命令字段是 `Light` / `Door` / `Wind` / `Condi` / `Beep`,大小写不区分(用 strstr 模糊匹配)。
> 鸿蒙端下发时仍按物模型定义严格书写。

---

## 五、本项目代码模式约定

> 详见项目根 [CLAUDE.md](../CLAUDE.md),此处只列开发中高频踩坑点。

### 状态管理决策树
1. 当前组件内部 → `@State`
2. 父子 ≤2 层 → `@State + @Prop/@Link`
3. 父子 >2 层 → `@Provide + @Consume`
4. 嵌套对象属性 → `@Observed + @ObjectLink`
5. 跨页面全局 → `LocalStorage` / `AppStorage` / `StateStore`

### 响应式断点(本项目已采用)
- XS(0–320vp) / SM(320–600) / MD(600–840) / LG(840–1440) / XL(1440+)
- 使用 `GridRow/GridCol` + `breakpoints`,**禁止** 按设备类型 `deviceInfo.deviceType` 分支
- 本项目 `AppStorage.setOrCreate<string>('currentBreakpoint', bp)` 全局共享

### 安全与异常
- 所有设备能力 API 调用前 `canIUse()` 包裹
- 所有 async 操作必须 `try-catch`
- 链式访问用 `?.` 和 `??`
- **禁止使用 `any`**,所有变量显式类型
- 禁止无接口的对象字面量

### 性能
- `build()` 必须轻量,禁止网络请求 / 重计算 / 同步 I/O
- 长列表 ≤100 用 `ForEach`,>100 用 `LazyForEach + cachedCount + @Reusable`
- `@State` 在循环中读取需先缓存到 local 变量

---

## 六、参考实现位置

本项目从 `e:/桌面/软件实训/wanglian/pages/` 的演示代码迁移而来,参考对照:

| 本项目文件 | 参考源 | 说明 |
|---|---|---|
| `features/core/service/IotService.ets` | `wanglian/pages/DisplayPage.ets` | 鉴权 + 影子查询 + 命令下发 |
| `features/core/service/IamAuthUtil.ets` | `wanglian/pages/DisplayPage.ets` L17-L39 | IAM Token 请求体构造 |
| `entry/pages/landing.ets`(待迁移) | `wanglian/pages/landing.ets` | 登录页 + Preferences 记忆 |

---

## 七、API 24 (6.1.1) 实战踩坑记录 + 社区最佳实践

> 以下均为本项目在 API 24 模拟器上实际验证的结论，结合华为开发者社区最佳实践。

### 7.1 颜色格式：8 位 hex (#RRGGBBAA) 不可用

**结论：API 24 模拟器上 8 位 hex 颜色解析不稳定，部分属性失效。**

- ❌ `'#FFFFFFA6'` — 8 位 hex，不可用
- ✅ `'#FFFFFF'` — 6 位 hex，正常
- 本项目应对：所有 Token 颜色统一用 6 位 hex。

### 7.2 深色模式

必须锁定 `COLOR_MODE_LIGHT`，否则系统深色会反转自定义颜色导致发黄。

### 7.3 主题切换：PersistentStorage + AppStorage + @StorageLink（社区标准方案）

**来源**：51CTO 星光计划 + 腾讯云开发者总结

```typescript
// ThemeManager 构造函数
PersistentStorage.persistProp('themeName', 'frosted');
// ↑ 自动：磁盘 ⇄ AppStorage ⇄ @StorageLink 双向同步

// 组件中
@StorageLink('themeName') themeName: string = 'frosted';
// this.themeName = 'contrast' → AppStorage → PersistentStorage 自动落盘
```

**不需要**手动 preferences 存取。PersistentStorage 全自动。

### 7.4 ArkTS struct 中 getter 不可用

`private get xxx()` 在某些场景 `this` 绑定丢失返回 `undefined`，改用公开方法 `t()`。

### 7.5 @StorageLink 更新顺序

```typescript
// ✅ 正确：先更新数据，再触发刷新
ThemeManager.setTheme(newValue);  // 先更新 current
this.themeName = newValue;        // 再触发所有页面 rebuild
```

---

## 八、待补充事项
