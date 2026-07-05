# 🍄 Smart Mushroom — 侧边端（Python AI 服务端）

> ⚠️ **侧边端需在鸿蒙端启动前运行**，它为鸿蒙端提供 AI 病害识别能力。

## 📋 概述

侧边端是基于 Python 的 AI 识别服务，运行在电脑上，通过**华为云 IoTDA** 与鸿蒙端联动：

1. 鸿蒙端下发 `recognizeOnce` 命令到华为云
2. 侧边端（Python 程序）通过 MQTT 接收命令
3. 调用摄像头截图 → AI 模型识别蘑菇病害状态
4. 识别结果上报至华为云设备属性
5. 鸿蒙端读取设备属性，展示识别结果

## 📁 项目结构

```
sidecar/
├── ai_model/                              # AI 模型相关
│   ├── mushroom_cnn.pth                   # 训练好的 CNN 模型权重
│   ├── mushroom_train.ipynb               # 蘑菇病害3分类 CNN 训练代码
│   └── mushroom_test.ipynb                # 模型测试 / 单张图片预测
├── integration/                           # 华为云集成
│   └── 华为云_摄像头_AI识别_完整集成.ipynb    # 完整集成：命令订阅 + 截图 + AI识别 + 结果上报
├── captures/                              # 运行时自动生成：摄像头截图存放目录
├── requirements.txt                       # Python 依赖清单
└── README.md                              # 本文件
```

## 🚀 快速开始

### 环境要求

| 依赖 | 版本 |
|------|------|
| Python | ≥ 3.10 |
| PyTorch | ≥ 2.0.0 |
| Jupyter | ≥ 1.0.0 |

### 安装依赖

```bash
# 推荐使用 conda 或 venv 创建独立环境
conda create -n mushroom python=3.10
conda activate mushroom

cd sidecar
pip install -r requirements.txt
```

### 运行步骤

#### 第1步：测试 AI 模型（可选）

打开 `ai_model/mushroom_test.ipynb`，运行所有单元格，确认模型能正常加载和预测。

#### 第2步：启动完整集成服务

打开 `integration/华为云_摄像头_AI识别_完整集成.ipynb`，依次运行：

1. **第1步单元格** — 单独测试 AI 模型识别截图
2. **第2步单元格** — 完整集成（保持运行不要停）

程序启动后会：
- 连接华为云 IoTDA（MQTT over TLS）
- 订阅命令 Topic：`$oc/devices/{deviceId}/sys/commands/#`
- 等待 `recognizeOnce` 命令

#### 第3步：启动鸿蒙端

侧边端运行后，再启动鸿蒙 HarmonyOS 终端应用即可正常使用 AI 识别功能。

## 🧠 AI 模型说明

**MushroomCNN** — 蘑菇病害3分类卷积神经网络：

| 类别 | 英文名 | 说明 |
|------|--------|------|
| 健康菌丝 | Healthy | 菌丝生长正常，无污染 |
| 单一感染 | Single_Infected | 单一霉菌污染 |
| 混合感染 | Mixed_Infected | 多种霉菌混合污染 |

### 网络结构

```
Input (3×100×100)
  → Conv2d(3→32, 3×3) → ReLU → MaxPool(2) → Dropout(0.25)
  → Conv2d(32→64, 3×3) → ReLU → MaxPool(2) → Dropout(0.25)
  → Conv2d(64→128, 3×3) → ReLU → MaxPool(2) → Dropout(0.25)
  → Flatten
  → Linear(128×12×12 → 512) → ReLU → Dropout(0.5)
  → Linear(512 → 3)  → Softmax → 3分类输出
```

### 训练数据

- 数据集：Mushroom Disease Dataset（健康菌丝 299张 / 单一感染 147张 / 混合感染 315张）
- 训练/验证划分：8:2
- Epochs：20，优化器：Adam，学习率：0.0001

## 📡 华为云集成流程

```
IoTDA 控制台 / 鸿蒙端 下发 recognizeOnce 命令
        ↓
侧边端 MQTT 收到命令
        ↓
摄像头截图（captures/ 目录）
        ↓
MushroomCNN AI 模型识别（3分类）
        ↓
属性上报（plantStatus / confidence / captureTime）
        ↓
回复命令执行结果
```

## 🔧 配置说明

在 `integration/华为云_摄像头_AI识别_完整集成.ipynb` 的**配置区**修改以下参数：

```python
CAMERA_URL = "http://192.168.43.98:8080/stream"   # 摄像头 RTSP/HTTP 地址
MODEL_PATH = r"ai_model/mushroom_cnn.pth"          # 模型路径
# 华为云 IoTDA 连接参数（需与鸿蒙端对应）
HOST = "your-iotda-endpoint"
CLIENT_ID = "your-client-id"
USERNAME = "your-username"
PASSWORD = "your-password"
```

> ⚠️ 华为云 IoTDA 凭证需与鸿蒙端 `IotConfig.ets` 中的设备对应。
