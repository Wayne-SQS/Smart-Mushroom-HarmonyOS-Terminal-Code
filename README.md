# 🍄 Smart Mushroom — 智慧蘑菇大棚 IoT 管理系统

[![HarmonyOS](https://img.shields.io/badge/HarmonyOS-6.1.1(24)-orange?logo=harmonyos)](https://developer.huawei.com/consumer/cn/)
[![ArkTS](https://img.shields.io/badge/ArkTS-blue)](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-overview)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

一套基于 **HarmonyOS ArkTS + ArkUI** 的蘑菇大棚物联网管理系统，通过华为云 IoTDA 接入 ESP32 系列硬件设备，实现环境监测、远程控制、AI 植物识别、视频监控、地图定位与数据可视化。

---

## 📖 目录

- [功能一览](#-功能一览)
- [技术架构](#-技术架构)
- [项目结构](#-项目结构)
- [快速开始](#-快速开始)
- [IoT 数据流](#-iot-数据流)
- [截图预览](#-截图预览)
- [开发路线](#-开发路线)
- [贡献指南](#-贡献指南)

---

## ✨ 功能一览

### 🌡️ 环境监测
- 温度、湿度、光照、CO₂、烟雾浓度等传感器**实时数据仪表盘**
- 支持 **24 小时趋势柱状图** 与 **7 天趋势折线图**
- 环形仪表盘直观展示各指标占范围比例
- 传感器状态分级：正常 / 预警 / 危险（基于阈值自动计算）

### 🎛️ 远程控制
- 补光灯、通风扇、空调、蜂鸣器**一键开关**
- 控制命令通过华为云 IoTDA 同步下发至 ESP32
- 设备在线/离线状态实时可见

### 🗺️ 大棚地图
- 双模式地图渲染：**华为 MapKit**（设备支持时）+ **Canvas 回退**（通用兜底）
- 大棚标记点 3D 微型化标注，聚合簇展示
- 卫星图/标准图切换、定位、搜索等交互

### 🪴 生长日记
- 蘑菇生长阶段全生命周期追踪（菌丝期 → 原基期 → 子实体期 → 采收期）
- 环境数据与生长阶段关联展示
- 批次管理：新建/归档/查询

### ⚠️ 智能告警
- 传感器阈值越界自动预警
- 告警历史本地持久化
- 未读告警数角标提醒

### 📹 ESP32-CAM 视频监控
- TCP Socket 直连 ESP32-CAM，接收 MJPEG 流
- JPEG 帧解码并渲染为实时视频画面
- 支持全屏展开

### 🤖 plantAI 植物识别
- ESP32-CAM 触发一次性 AI 识别
- 病害/长势分析结果回传展示

### 📝 环境配方
- 内置平菇、香菇、金针菇、杏鲍菇标准环境参数
- 一键应用配方到 IoTDA 期望属性
- 支持用户自定义配方

### 🎨 双主题系统
- **毛玻璃主题**（Frosted）：柔和绿色质感，`backdropBlur` 模糊面板
- **高对比主题**（Contrast）：黑白极简，无障碍友好
- 全局 106 项主题 Token，一键切换

### 📱 响应式多端适配
- 支持 **6 种设备形态**：手机、平板、2in1、手表、车机、智慧屏
- 五档断点（XS / SM / MD / LG / XL）自适应布局
- 窄屏底部 Tab + 宽屏侧边导航栏双模式

---

## 🏗️ 技术架构

```
┌─────────────────────────────────────────┐
│              entry (HAP)                 │
│  产品入口 · Index · AppRouter · 主题     │
├─────────────────────────────────────────┤
│           features/core (HAR)            │
│  业务逻辑 · ViewModel · IoT Service     │
│  页面: Dashboard / Device / Map /        │
│  Growth / Alert / Recipe / VideoMonitor  │
├─────────────────────────────────────────┤
│            common/base (HAR)             │
│  公共组件 · 工具类 · 常量 · 图表         │
│  BarChart / LineChart / Gauge / MapView  │
└─────────────────────────────────────────┘
```

**依赖规则（严格单向）：**
```
entry → features/core → common/base
```
- ❌ 不可反向引用
- ❌ 不可跨层横向引用

### 技术栈

| 类别 | 技术 |
|------|------|
| 语言 | ArkTS (TypeScript 超集) |
| UI 框架 | ArkUI (声明式) |
| 应用模型 | Stage Model |
| 状态管理 | V1（@State/@Prop/@Link/@Provide/@Consume） + V2（@ObservedV2/@Trace/@Local/@Param） |
| HTTP 通信 | `@kit.NetworkKit` (http) |
| 加密认证 | `@kit.CryptoArchitectureKit` (HMAC-SHA256) |
| 地图 | `@kit.MapKit` + Canvas 自绘回退 |
| 视频流 | `@ohos.net.socket` (TCP Socket) + `@ohos.multimedia.image` |
| 云服务 | 华为云 IoTDA（设备影子 + 命令下发）+ IAM（鉴权） |
| 持久化 | `@ohos.data.preferences` |
| 构建 | Hvigor |
| 测试 | `@ohos/hypium` + `@ohos/hamock` |
| API 版本 | 6.1.1(24) |

---

## 📁 项目结构

```
SoftwareAction/
├── entry/                              # 产品入口 (HAP)
│   ├── src/main/ets/
│   │   ├── entryability/               # UIAbility + IoT 初始化
│   │   ├── entrybackupability/         # 备份扩展
│   │   └── pages/
│   │       └── Index.ets               # 入口页（Tabs + 响应式布局）
│   └── src/test/                       # 单元测试
│
├── features/core/                      # 业务核心 (HAR)
│   └── src/main/ets/
│       ├── pages/                      # 8 个业务页面
│       │   ├── DashboardPage.ets       # 仪表盘首页
│       │   ├── DevicePage.ets          # 设备管理
│       │   ├── MapPage.ets             # 大棚地图
│       │   ├── GrowthPage.ets          # 生长日记
│       │   ├── AlertPage.ets           # 告警中心
│       │   ├── RecipePage.ets          # 环境配方
│       │   ├── ProfilePage.ets         # 个人中心
│       │   └── VideoMonitorPage.ets    # ESP32-CAM 视频
│       ├── viewmodel/                  # MVVM ViewModel 层
│       ├── model/                      # 数据模型
│       └── service/                    # IoT 服务层（华为云 IoTDA）
│           ├── IotService.ets          # 单例 · 影子查询 · 命令下发
│           ├── IamAuthUtil.ets         # IAM Token 鉴权
│           ├── IotTokenManager.ets     # Token 缓存
│           ├── IotAuthUtil.ets         # HMAC-SHA256 加密
│           └── IotTypes.ets            # 类型定义
│
├── common/base/                        # 公共基础 (HAR)
│   └── src/main/ets/
│       ├── components/                 # 通用组件
│       │   ├── ChartComponent.ets      # 图表基类 + 工具
│       │   ├── BarChartComponent.ets   # 柱状图
│       │   ├── LineChartComponent.ets  # 折线图
│       │   ├── GaugeComponent.ets      # 环形仪表盘
│       │   └── MapViewComponent.ets    # 地图（MapKit + Canvas）
│       ├── constants/                  # 常量定义
│       │   ├── BreakpointConstants.ets # 断点系统
│       │   ├── StyleConstants.ets      # 设计 Token
│       │   └── SensorType.ets          # 传感器类型
│       └── utils/                      # 工具类
│           ├── Logger.ets              # 日志
│           └── CapabilityUtils.ets     # 设备能力检测
│
├── docs/                               # 设计文档 & 知识库
│   ├── harmony-kb.md                   # HarmonyOS 开发知识库
│   ├── 后续开发计划.md                   # 开发路线图
│   └── 美化.md                         # 主题设计方案
│
├── CLAUDE.md                           # AI 辅助开发指南
├── build-profile.json5                 # 项目构建配置
└── README.md                           # 本文件
```

---

## 🚀 快速开始

### 环境要求

| 工具 | 版本 |
|------|------|
| DevEco Studio | ≥ 5.0.3 |
| HarmonyOS SDK | API 6.1.1(24) |
| Node.js | ≥ 18.x |
| ohpm | ≥ 1.3.x |

### 构建 & 运行

```bash
# 1. 克隆仓库
git clone https://github.com/Wayne-SQS/Smart-Mushroom-HarmonyOS-Terminal-Code.git
cd Smart-Mushroom-HarmonyOS-Terminal-Code

# 2. 配置华为云 IoTDA 凭证
cp IotConfig.example.ets entry/src/main/ets/entryability/IotConfig.ets
# 编辑 IotConfig.ets，填入你的华为云设备凭证

# 3. 安装依赖
ohpm install

# 4. 编译 Debug HAP
hvigorw assembleHap -p buildMode=debug

# 5. 运行单元测试
hvigorw test

# 6. 部署到设备/模拟器
# 在 DevEco Studio 中点击 Run → Run 'entry'
```

### 配置 IoTDA

在 `entry/src/main/ets/entryability/IotConfig.ets` 中填入：

```typescript
import { IotAppConfig } from 'features-core';

export const IOT_CONFIG: IotAppConfig = {
  deviceId: 'your-device-id',
  secret: 'your-device-secret',
  serverAddress: 'your-iotda-endpoint',
  region: 'cn-north-4',          // 华为云区域
  projectId: 'your-project-id',
  iamAccount: 'your-iam-account',
  iamPassword: 'your-iam-password',
};
```

> ⚠️ `IotConfig.ets` 包含真实凭证，已通过 `.gitignore` 排除提交。模板文件 `IotConfig.example.ets` 可以安全提交。

---

## 📡 IoT 数据流

```
ESP32 硬件
  ├── DHT11 温湿度传感器
  ├── LDR 光照传感器
  ├── MQ2 烟雾传感器
  ├── CO₂ 传感器
  ├── LED 补光灯
  ├── 风扇 (通风)
  ├── 空调
  ├── 蜂鸣器
  └── ESP32-CAM (AI + 视频)
        │
        ▼ MQTT
  华为云 IoTDA
        │
        ▼ HTTP (IAM Token 鉴权)
  IotService
        │
        ▼
  ViewModel (数据转换 + 状态计算)
        │
        ▼
  @State → ArkUI 页面渲染
```

**命令下发路径：**
```
用户点击控制按钮 → IotService.sendCommand()
  → IoTDA 同步命令 → ESP32 执行 → 设备影子更新
```

---

## 📸 截图预览

| 仪表盘 | 设备管理 | 大棚地图 |
|:---:|:---:|:---:|
| ![Dashboard](screenshots/dashboard.png) | ![Device](screenshots/device.png) | ![Map](screenshots/map.png) |

| 生长日记 | 告警中心 | 环境配方 |
|:---:|:---:|:---:|
| ![Growth](screenshots/growth.png) | ![Alert](screenshots/alert.png) | ![Recipe](screenshots/recipe.png) |

> 📌 截图占位，后续补充实际运行截图。

---

## 🗺️ 开发路线

### ✅ 已完成

- [x] UI 框架 + 8 个业务页面
- [x] 华为云 IoTDA 数据对接（IAM 鉴权 + 设备影子 + 命令下发）
- [x] Navigation 路由 + Tab/侧边栏双模式
- [x] Canvas 图表组件（柱状图 / 折线图 / 环形仪表盘）
- [x] 双模式地图（MapKit + Canvas 回退）
- [x] 告警系统 + 阈值自动计算
- [x] 环境配方管理
- [x] 双主题系统（毛玻璃 + 高对比）
- [x] 五档断点响应式布局
- [x] ESP32-CAM 视频监控（TCP Socket + MJPEG 解码）

### 🚧 进行中 / 计划

- [ ] 多端适配完善（手表 / 智慧屏 / 2in1 键鼠交互）
- [ ] plantAI 识别结果 UI 对接
- [ ] 趋势预测 + 智能预警（基于历史数据）
- [ ] 推送通知（后台保活）
- [ ] 性能优化（LazyForEach 改造长列表、Profilier 分析）
- [ ] 单元测试 / UI 测试完善
- [ ] 签名打包可发布 HAP

详见 [docs/后续开发计划.md](docs/后续开发计划.md)

---

## 🤝 贡献指南

### Git 分支规范

```
main              — 发布分支（受保护）
develop           — 日常开发
feature/xxx       — 功能分支
bugfix/xxx        — 修复分支
```

### Commit 规范

```
<type>(<scope>): <subject>

type:   feat / fix / refactor / style / docs / test / chore
scope:  common / feature / product / ui / api
```

示例：
```
feat(feature): 新增 ESP32-CAM 视频监控页面
fix(ui): 修复主题切换时 TabContent 不刷新的问题
refactor(common): 地图组件抽取 Canvas 回退模式
```

### 代码规范

- 零 `any`：所有变量显式声明类型
- 异步操作必须 `try-catch`
- 可选链 `?.` 和空值合并 `??` 保底
- `@ComponentV2` + `@ObservedV2` 优先用于新代码
- 严禁 Commit 真实凭证（`**/IotConfig.ets` 已在 `.gitignore`）

详见 [CLAUDE.md](CLAUDE.md) 获取完整约定。

---

## 📄 License

MIT License © 2026 [Wayne-SQS](https://github.com/Wayne-SQS)

---

<p align="center">
  <sub>Built with ❤️ using HarmonyOS ArkTS + ArkUI</sub>
</p>
