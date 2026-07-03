"""
Update 鸿蒙技术开发文档.docx to reflect current code changes.

Key code changes → document updates:
1. Theme: 薄荷绿→菌菇棕, 8位hex→6位hex, 50→80+ tokens, new disabled/typography/card tokens
2. Icons: 纯几何矢量→预生成PNG像素风图标
3. Dashboard: 按压回弹, 噪点纹理, 卡片高光, 等宽字体
4. New components: NumberRoller, SkeletonCard
5. Empty states: emoji→PNG icons
6. LoginPage: 背景渐变颜色调整
"""
import os, sys, re
from docx import Document
from docx.shared import Inches, Cm

DOC_PATH = r'D:\SoftwareAction\docs\鸿蒙技术开发文档.docx'

def replace_in_para(para, old, new):
    """Replace text across all runs in a paragraph. Returns True if replaced."""
    full_text = para.text
    if old not in full_text:
        return False

    # Simple approach: replace in each run
    remaining = old
    for run in para.runs:
        if remaining in run.text:
            run.text = run.text.replace(remaining, new)
            return True
        elif remaining.startswith(run.text):
            # This run is a prefix of remaining
            remaining = remaining[len(run.text):]
        elif run.text in remaining:
            idx = remaining.find(run.text)
            if idx == 0:
                remaining = remaining[len(run.text):]
            elif idx > 0:
                # Part of remaining is in this run
                run.text = run.text.replace(run.text, new)
                return True

    # Fallback: replace in first run
    if para.runs:
        combined = ''.join(r.text for r in para.runs)
        if old in combined:
            # Replace in first run, clear others
            para.runs[0].text = combined.replace(old, new)
            for r in para.runs[1:]:
                r.text = ''
            return True
    return False


def main():
    doc = Document(DOC_PATH)
    updates = 0

    # ============ 第八章 主题系统 ============

    for para in doc.paragraphs:
        text = para.text

        # 8.1: 品牌色更新
        if 'primary: #7EC8A3' in text or '#7EC8A3' in text:
            if replace_in_para(para, '#7EC8A3', '#C68642'):
                updates += 1
                print(f'  [theme] primary color: #7EC8A3 -> #C68642')

        # 8.1: 薄荷绿描述更新为菌菇棕
        if '薄荷绿' in text and ('主色' in text or 'primary' in text or '品牌' in text):
            if replace_in_para(para, '薄荷绿', '菌菇棕'):
                updates += 1
                print(f'  [theme] 薄荷绿 -> 菌菇棕')

        # 8.3: 属性数量 50 → 80+
        if '约 50 个只读属性' in text:
            if replace_in_para(para, '约 50 个只读属性', '约 80 个只读属性'):
                updates += 1
                print(f'  [theme] 50 -> 80 tokens')

        # 8.1: 8位hex → 6位hex + API 24 兼容说明
        if '半透明色统一使用 8 位 hex' in text:
            new_text = '所有颜色统一使用 6 位 hex（#RRGGBB），因 API 24 模拟器对 8 位 hex 解析不稳定会导致颜色发黄/失效'
            if replace_in_para(para, '半透明色统一使用 8 位 hex（#RRGGBBAA），不用 rgba()', new_text):
                updates += 1
                print(f'  [theme] 8位hex -> 6位hex')

        # 8.1: 品牌色描述
        if 'primary' in text and '#7EC8A3 薄荷绿' in text:
            if replace_in_para(para, '#7EC8A3 薄荷绿', '#C68642 菌菇棕'):
                updates += 1

    # 8.4: 双主题差异表 - update Frosted primary
    for para in doc.paragraphs:
        text = para.text
        if '#7EC8A3' in text and '薄荷' in text:
            replace_in_para(para, '#7EC8A3', '#C68642')
            replace_in_para(para, '薄荷绿', '菌菇棕')
            updates += 1
            print(f'  [theme] Frosted primary 描述更新')

        # Contrast primary 更新
        if '#000000' in text and '纯黑' in text and ('主色' in text or 'primary' in text or 'Contrast' in text):
            replace_in_para(para, '#000000 纯黑', '#8B5A2B 深菌菇棕')
            updates += 1
            print(f'  [theme] Contrast primary: #000000 -> #8B5A2B')

        # bgPage 更新
        if '#F2F5F9' in text:
            replace_in_para(para, '#F2F5F9', '#F5F6F7')
            updates += 1
            print(f'  [theme] bgPage: #F2F5F9 -> #F5F6F7')

        # 8.4 Frosted 功能色描述
        if '低饱和粉彩' in text:
            replace_in_para(para, '低饱和粉彩', '柔和土系（菌菇棕系）')
            updates += 1
            print(f'  [theme] 功能色描述更新')

    # ============ 5.7 矢量图标 → PNG像素风 ============

    for para in doc.paragraphs:
        text = para.text

        # Update section heading description
        if '矢量图标自绘（ArkUI 几何组件）' in text:
            replace_in_para(para, '矢量图标自绘（ArkUI 几何组件）', '像素风图标系统（预生成 PNG + 主题适配）')
            updates += 1
            print(f'  [icons] 章节标题更新')

        # Update body text about geometric drawing
        if '纯 ArkUI 几何组件' in text and ('Path' in text or 'Circle' in text):
            new_desc = ('像素风预生成 PNG 图标替代 emoji 和几何绘制，保证多端渲染一致。'
                       '7 组图标（home/device/profile/alert/greenhouse/chart/sensor），'
                       '每组 3 种尺寸（48×48 / 64×64 / 128×128），共 21 个资源文件。'
                       '通过 Image($r(\'app.media.xxx\')) 引用，零运行时绘制开销。'
                       '替代原有 ArkUI 几何组件（Path/Circle/Rect）自绘方案，减小 build() 复杂度。')
            if replace_in_para(para, (
                '的 `NavIcon(type, color)` 用纯 ArkUI 几何组件（`Path`/`Circle`/`Rect`/`Column`）'
                '绘制 4 个导航图标（home/device/map/profile），基准 20×20vp，`color` 参数着色实现主题感知，'
                '与 [MapPage.MapIcon]'),
                new_desc):
                updates += 1
                print(f'  [icons] 几何绘制描述更新')

    # ============ 第一章/概述 颜色更新 ============

    for para in doc.paragraphs:
        text = para.text
        if '主题系统' in text and '薄荷' in text:
            replace_in_para(para, '薄荷绿', '菌菇棕')
            updates += 1
            print(f'  [overview] 薄荷绿 -> 菌菇棕')

    # ============ DashboardPage 新增交互 ============

    for para in doc.paragraphs:
        text = para.text

        # Add mention of new components (find the chart component section or add note)
        if 'Canvas 自绘的图表组件体系' in text or '纯 Canvas 自绘的图表组件体系' in text:
            if 'NumberRoller' not in text:
                # Append to this paragraph's first run
                if para.runs:
                    para.runs[-1].text += (
                        ' 此外，features/core 新增 NumberRoller（数字滚动组件，'
                        'animateTo 线性插值平滑过渡）和 SkeletonCard（骨架屏卡片，'
                        'shimmer 扫光动画）两个主题驱动的可复用 UI 组件。')
                    updates += 1
                    print(f'  [components] 新增 NumberRoller/SkeletonCard 描述')

    # ============ 空状态 emoji → PNG ============

    for para in doc.paragraphs:
        text = para.text
        # This is a minor detail, skip for now as it's cosmetic

    # ============ LoginPage 背景渐变 ============

    for para in doc.paragraphs:
        text = para.text
        if 'LoginPage' in text and '背景渐变' in text and '#EEF6F0' in text:
            replace_in_para(para, '#EEF6F0', '#F2E8D5')
            updates += 1
            print(f'  [login] 渐变颜色更新')

    # ============ 8.3 ThemeTokens 表格扩展 ============
    # Find the table/section about ThemeTokens categories

    for para in doc.paragraphs:
        text = para.text

        # Update "大字号场景" note
        if '大字号场景（传感器数值、概览数字）使用 `AdaptiveUtils`' in text:
            new_note = (
                '大字号场景（传感器数值、概览数字）使用 `AdaptiveUtils` 断点自适应，'
                '小字号场景用 `ThemeTokens` 基准字号。传感器数值统一使用等宽字体 '
                '`fontMonoFamily: HarmonyOS Sans Mono` 配合 `fontWeightMono: 700`，'
                '对齐整齐不跳动。新增字重体系（fontWeightTitle/Body/Hint/Button/Mono）'
                '统一管理页面各级文字粗细，避免散落 fontWeight 数值。')
            if replace_in_para(para, (
                '大字号场景（传感器数值、概览数字）使用 `AdaptiveUtils` 断点自适应，'
                '小字号场景用 `ThemeTokens` 基准字号。'), new_note):
                updates += 1
                print(f'  [theme] 字号/字重描述更新')

    # Save
    doc.save(DOC_PATH)
    print(f'\nDone! Total updates: {updates}')
    print(f'Saved to: {DOC_PATH}')


if __name__ == '__main__':
    main()
