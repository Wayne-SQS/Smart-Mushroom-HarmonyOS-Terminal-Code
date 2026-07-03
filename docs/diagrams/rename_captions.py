"""Expand short figure captions to detailed descriptions matching 图X-Y convention."""
import os, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
from docx import Document

DOC_PATH = r'D:\SoftwareAction\docs\鸿蒙技术开发文档.docx'

RENAMES = [
    ('图3-2 三层模块依赖关系图',
     '图3-2 三层模块依赖关系图 — entry(HAP)→features/core(HAR)→common/base(HAR) 单向依赖，红色虚线标注禁止反向和横向调用'),
    ('图4-2 系统启动与路由流程',
     '图4-2 系统启动与路由流程 — UIAbility.onCreate → WindowStage.loadContent → Index → NavPathStack → Navigation(Stack) → Route Decision 分支到各页面，表达 Stage Model + Declarative Routing 核心机制'),
    ('图5-2 五端断点映射图',
     '图5-2 五端断点映射图 — XS(手表)/SM(手机竖屏)/MD(折叠屏)/LG(平板)/XL(PC)，标注各断点列数和布局模式切换'),
    ('图5-3 双模式入口布局对比图',
     '图5-3 双模式入口布局对比 — 窄屏 XS/SM 使用底部 Tabs(barPosition=End)，宽屏 MD/LG/XL 使用 SideNavBar(220vp)+Navigation(Stack)'),
    ('图7-2 全局状态管理机制',
     '图7-2 全局状态管理机制 — AppStorage Global State Hub (Single Source of Truth) 管理 navPathStack/themeName/currentBreakpoint/deviceType 五个全局键，通过 @StorageLink 双向绑定触发 UI 重渲染'),
    ('图8-2 主题切换数据流图',
     '图8-2 主题切换数据流图 — PersistentStorage ↔ AppStorage ↔ @StorageLink ↔ ThemeManager → 全部页面 rebuild，菌菇棕点缀雾透玻璃与深棕极致黑白双主题'),
    ('图9-2 IoT 端到端通信架构',
     '图9-2 IoT 端到端通信架构 — ESP32-CAM 设备→MQTT/TCP→IoTDA→IotService(含IAM鉴权+Token 23h缓存)→ViewModel→ArkUI Pages，用户交互形成闭环反馈控制'),
    ('图11-2 MapViewComponent 双模式决策树',
     '图11-2 MapViewComponent 双模式决策树 — canIUse(SystemCapability.Map.Core) 运行时能力检测，MapKit 真实地图 / Canvas 自绘降级双路径'),
    ('图12-2 MVVM 分层架构',
     '图12-2 MVVM 分层架构 — UI Layer→ViewModel Layer→Service Layer→Infrastructure Layer 四层解耦，ViewModel 纯逻辑层无 ArkUI 装饰器，Service 统一封装外部依赖，Infrastructure 可替换性保证'),
]

def main():
    doc = Document(DOC_PATH)
    updated = 0
    for para in doc.paragraphs:
        for old_prefix, new_text in RENAMES:
            if para.text.strip().startswith(old_prefix):
                for run in para.runs:
                    if old_prefix in run.text:
                        run.text = run.text.replace(old_prefix, new_text)
                        updated += 1
                        print(f'  OK: {old_prefix[:30]}...')
                        break
                else:
                    combined = ''.join(r.text for r in para.runs)
                    if old_prefix in combined and para.runs:
                        para.runs[0].text = combined.replace(old_prefix, new_text)
                        for r in para.runs[1:]:
                            r.text = ''
                        updated += 1
                        print(f'  OK (combined): {old_prefix[:30]}...')
                break

    doc.save(DOC_PATH)
    print(f'\nDone! Updated {updated} captions')

if __name__ == '__main__':
    main()
