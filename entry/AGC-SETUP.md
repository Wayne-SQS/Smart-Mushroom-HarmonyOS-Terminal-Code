# HMS Map Kit 集成指南

## 当前状态

MapPage 已集成双模式地图：
- **降级模式（默认）**：Canvas 自绘地图，使用真实经纬度投影，无需任何配置即可运行
- **HMS Map Kit 模式**：真实地图瓦片，需要以下配置

## 启用 HMS Map Kit

### 1. 注册 AppGallery Connect

1. 登录 [AppGallery Connect](https://developer.huawei.com/consumer/cn/service/josp/agc/index.html)
2. 创建项目 → 添加应用（HarmonyOS 平台）
3. 包名：`com.example.softwareaction`
4. 下载 `agconnect-services.json`

### 2. 放置配置文件

将 `agconnect-services.json` 放到：
```
entry/src/main/agconnect-services.json
```

> ⚠️ 此文件包含 API Key，已被 `.gitignore` 排除，切勿提交到仓库

### 3. 开启 Map Kit 服务

在 AGC 控制台 → 我的项目 → 你的应用 → 构建 → Map Kit：
1. 点击"立即开通"
2. 同意服务协议
3. 等待服务开通（约 1-2 分钟）

### 4. 运行效果

完成后，MapPage 会自动检测到 Map Kit 可用（`canIUse('SystemCapability.Map.Core')` → `true`），切换到真实地图渲染模式。

## 降级说明

如果上述步骤未完成，MapPage 仍可正常使用——降级为 Canvas 自绘地图，标记点使用经纬度投影坐标，功能完全一致。两种模式共享同一套 MapMarker 接口，页面代码无需任何修改。

## 额外：位置权限

已在 `module.json5` 中添加 `ohos.permission.APPROXIMATELY_LOCATION` 权限声明。首次启动时系统会弹窗请求用户授权，拒绝不影响地图基础功能。
