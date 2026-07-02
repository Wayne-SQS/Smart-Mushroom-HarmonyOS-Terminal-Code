# 智慧蘑菇鸿蒙端 (Smart-Mushroom-HarmonyOS-Terminal-Code)

基于 HarmonyOS (ArkTS + ArkUI, Stage 模型) 开发的**蘑菇大棚 IoT 管理系统**，旨在为农业物联网提供现代化的跨终端控制体验。本项目深度对接华为云 IoTDA，支持真实设备的影子查询、数据上报和指令下发。

## ✨ 主要特性

- **跨设备响应式布局 (Responsive Layout)**: 针对手机、折叠屏、平板等不同设备尺寸提供无缝的 UI 体验。窄屏（如手机）采用底部导航 Tabs，宽屏自动切换为侧边栏 + `Navigation` 堆栈式导航。
- **华为云 IoT 集成 (IoT Integration)**: 采用 IAM 身份认证，支持设备属性上报、影子查询，以及对灯光、风扇、空调、蜂鸣器等硬件设备的实时状态控制。新增 `plantAI` 支持基于 ESP32-CAM 摄像头的植物病害与长势识别服务。
- **动态主题系统 (Dynamic Theming)**: 内置自研双主题引擎，包含磨砂毛玻璃风格 (`ThemeFrosted`) 与高对比度扁平风格 (`ThemeContrast`)，一键全局切换。
- **独立数据可视化组件 (Data Visualization)**: 不依赖第三方库，使用底层 Canvas API 实现了一套高性能图表组件，包含响应式的柱状图 (BarChart)、折线图 (LineChart) 和仪表盘 (Gauge)。
- **自研地图模块 (Map & Geo)**: 支持双模式自动切换的地图组件（有系统能力时使用 `@kit.MapKit`，无系统能力则降级为 Canvas 实现），内置全套自定义几何体绘制图标，支持设备集群渲染和交互。
- **严格的三层架构 (3-Layer Architecture)**:
  - `common/base` (HAR): 底层公共能力与复用 UI 组件。
  - `features/core` (HAR): 核心业务逻辑、ViewModel 状态管理以及 IoT API 封装。
  - `entry` (HAP): 聚合产物，负责系统入口、全局导航路由管理 (AppRouter)。

## 🛠️ 技术栈

- **开发语言**: ArkTS
- **UI 框架**: ArkUI
- **应用模型**: Stage Model
- **目标 API**: 6.1.1 (24)
- **支持终端**: Phone, Tablet, 2in1, Car, Wearable, TV
- **服务端**: 华为云 IoTDA

## 📁 核心架构

```text
├── common/base        # (HAR) 基础库、通用 UI 组件 (Chart, Gauge, MapView)、工具类 (Logger, AdaptiveUtils)
├── features/core      # (HAR) 核心业务页面 (首页, 设备, 地图, 警告, 种植档案)、ViewModel、IoT Service 模块
├── entry              # (HAP) 整体应用 Ability 挂载点、路由分发配置
└── docs               # (文档) 开发计划、项目知识库与设计文档
```
*模块依赖原则*：`entry` → `features/core` → `common/base`。禁止同层反向调用与跨级调用，保证代码的强解耦性。

## 🚀 快速开始

### 1. 环境准备
- 安装最新版的 DevEco Studio。
- 配置支持 HarmonyOS 目标 API 版本的 SDK 环境。

### 2. 配置 IoT 凭证 (核心步骤)
出于安全考虑，真实的华为云凭据不会提交到代码库。项目根目录提供了配置模板 `IotConfig.example.ets`，请在使用前配置：

```bash
# 请将模板文件复制并重命名为 IotConfig.ets (此文件已被 .gitignore 忽略)
# 注意: IotConfig.ets 实际存放路径请以代码引用为准，通常在 entry/src/main/ets/entryability/
cp entry/src/main/ets/entryability/IotConfig.example.ets entry/src/main/ets/entryability/IotConfig.ets
```
在 `IotConfig.ets` 中填入你个人的华为云账号、IAM 密码、区域及产品等参数。

### 3. 构建与运行

可以在 DevEco Studio IDE 界面直接点击 Run/Build，或者通过命令行执行 `hvigorw` 构建命令：

```bash
# 构建 Debug 版本 HAP
hvigorw assembleHap -p buildMode=debug

# 构建 Release 版本 HAP
hvigorw assembleHap -p buildMode=release

# 遇到异常时清理并重新构建
hvigorw clean && hvigorw assembleHap -p buildMode=debug
```

## 🧪 测试与规范检查

- **单元测试 (Unit Test)**: `hvigorw test` (入口文件 `entry/src/test/List.test.ets`)
- **UI 集成测试 (UI Test)**: `hvigorw ohosTest` (需要连接真机或模拟器)
- **规范检查 (Linting)**: 基于 DevEco Studio 集成的 `Code Linter`，检查规则配置于 `code-linter.json5`。

## 📖 参考文档

- 项目知识库、API 用法及开发规范汇总：[`docs/harmony-kb.md`](./docs/harmony-kb.md)
- 后续开发计划与进度：[`docs/后续开发计划.md`](./docs/后续开发计划.md)
- 美化与主题系统设计文档：[`docs/美化.md`](./docs/美化.md)

---
*声明: 项目中的敏感鉴权信息仅在本地保存，禁止通过任何形式 push 至远端仓库！*
