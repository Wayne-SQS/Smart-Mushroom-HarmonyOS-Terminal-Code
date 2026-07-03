"""
Comprehensive document updater v3 — all table writes use set_cell_text helper.
"""
import os, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
from docx import Document
from docx.oxml import OxmlElement

DOC_PATH = r'D:\SoftwareAction\docs\鸿蒙技术开发文档.docx'


def set_cell_text(cell, text):
    """Set cell text reliably, creating paragraph/run if needed."""
    # Clear existing runs
    for p in cell.paragraphs:
        for r in p.runs:
            r.text = ''
    # Ensure paragraph exists
    if not cell.paragraphs:
        p_elem = OxmlElement('w:p')
        cell._element.append(p_elem)
    p = cell.paragraphs[0]
    # Ensure run exists
    if not p.runs:
        p.add_run(text)
    else:
        p.runs[0].text = text


def replace_para_text(para, old, new):
    """Replace text across runs. Returns True if replaced."""
    full = para.text
    if old not in full:
        return False
    # Try direct run replacement first
    for r in para.runs:
        if old in r.text:
            r.text = r.text.replace(old, new)
            return True
    # Fallback: put result in first run, clear others
    combined = ''.join(r.text for r in para.runs)
    if old in combined:
        result = combined.replace(old, new, 1)
        if para.runs:
            para.runs[0].text = result
            for r in para.runs[1:]:
                r.text = ''
        return True
    return False


def main():
    doc = Document(DOC_PATH)
    count = 0

    # ============================================================
    # 1. P[159]: 50 -> 80 tokens
    # ============================================================
    for p in doc.paragraphs:
        if replace_para_text(p, '定义约 50 个只读属性', '定义约 80 个只读属性'):
            count += 1; print('OK: 50 -> 80 tokens')
            break

    # ============================================================
    # 2. P[161]: 8位hex -> 6位hex
    # ============================================================
    old_hex = '半透明色统一使用 8 位 hex（#RRGGBBAA），不用 rgba()'
    new_hex = '所有颜色统一使用 6 位 hex（#RRGGBB），因 API 24 模拟器对 8 位 hex（#RRGGBBAA）解析不稳定会导致颜色发黄/失效'
    for p in doc.paragraphs:
        if replace_para_text(p, old_hex, new_hex):
            count += 1; print('OK: 8hex -> 6hex')
            break

    # ============================================================
    # 3. P[161] suffix: 字号描述扩展
    # ============================================================
    old_font = '小字号场景用 ThemeTokens 基准字号。'
    new_font = ('小字号场景用 ThemeTokens 基准字号。传感器数值统一使用等宽字体 '
                'HarmonyOS Sans Mono（fontMonoFamily）配合 fontWeightMono: 700，'
                '对齐整齐不跳动。新增字重体系（fontWeightTitle/Body/Hint/Button/Mono）'
                '统一管理页面各级文字粗细。')
    for p in doc.paragraphs:
        if replace_para_text(p, old_font, new_font):
            count += 1; print('OK: font/typography note updated')
            break

    # ============================================================
    # 4. Table[10]: ThemeTokens categories - add rows + update brand
    # ============================================================
    for table in doc.tables:
        hdr = [c.text.strip() for c in table.rows[0].cells]
        if hdr == ['分类', '属性示例', '数量']:
            new_rows = [
                ('禁用态', 'disabled, disabledText, disabledBorder', '3'),
                ('字重', 'fontWeightTitle(500), fontWeightBody(400), fontWeightHint(300), fontWeightButton(500), fontWeightMono(700)', '5'),
                ('字体族', 'fontMonoFamily（传感器数值等宽）', '1'),
                ('卡片质感', 'cardHighlightColor, cardHighlightWidth（顶部 1px 高光）', '2'),
            ]
            for label, examples, num in new_rows:
                row = table.add_row()
                set_cell_text(row.cells[0], label)
                set_cell_text(row.cells[1], examples)
                set_cell_text(row.cells[2], num)
            count += 1; print('OK: ThemeTokens table +4 rows')

            for row in table.rows:
                if row.cells[0].text.strip() == '品牌色':
                    set_cell_text(row.cells[1], 'primary(#C68642菌菇棕), primaryLight(#E0B58A), primaryDark(#8B5A2B), accent(#7A9E6E草绿), accentLight(#C9DBBF)')
                    count += 1; print('OK: brand colors updated in table')
            break

    # ============================================================
    # 5. Table[11]: 双主题差异表 - update + add rows
    # ============================================================
    for table in doc.tables:
        hdr = [c.text.strip() for c in table.rows[0].cells]
        if 'ThemeFrosted' in hdr[1] and 'ThemeContrast' in hdr[2]:
            for row in table.rows:
                dim = row.cells[0].text.strip()
                if dim == '主色':
                    set_cell_text(row.cells[1], '#C68642 菌菇棕（仅点缀，不作背景）')
                    set_cell_text(row.cells[2], '#8B5A2B 深菌菇棕（按钮/选中态）')
                    count += 1; print('OK: 主色 updated')
                elif dim == '强调色':
                    set_cell_text(row.cells[1], '#7A9E6E 草绿（蘑菇+植物）')
                    set_cell_text(row.cells[2], '#0052D9 标准蓝')
                    count += 1; print('OK: 强调色 updated')
                elif dim == '功能色':
                    set_cell_text(row.cells[1], '柔和土系（success #7A9E6E, warning #E6A23C, danger #E06C75）')
                    count += 1; print('OK: 功能色 updated')
                elif dim == '背景页':
                    set_cell_text(row.cells[1], '#F5F6F7 暖灰白（微暖不黄）')
                    count += 1; print('OK: bgPage updated')

            new_rows = [
                ('按压态阴影', 'shadowPressed*（半径4, 变深变近模拟凹陷）', 'shadowPressed*（半径1, 极简）'),
                ('禁用态', 'disabled #F0F0F0 + disabledText #BFBFBF', 'disabled #E5E5E5 + disabledText #B0B0B0'),
                ('字重体系', 'fontWeightTitle/Body/Hint/Button/Mono（500/400/300/500/700）', 'fontWeightTitle/Body/Hint/Button/Mono（600/400/300/600/700）'),
                ('等宽字体', 'HarmonyOS Sans Mono（传感器数值对齐）', 'HarmonyOS Sans Mono（传感器数值对齐）'),
                ('卡片高光', 'cardHighlightColor #FFFCF7（1px暖白）', 'cardHighlightColor #FAFAFA（1px极淡灰）'),
            ]
            for dim, frosted, contrast in new_rows:
                row = table.add_row()
                set_cell_text(row.cells[0], dim)
                set_cell_text(row.cells[1], frosted)
                set_cell_text(row.cells[2], contrast)
            count += 1; print(f'OK: 双主题差异表 +{len(new_rows)} rows')
            break

    # ============================================================
    # 6. 5.7 NavIcon -> PNG icons
    # ============================================================
    old_icon1 = ('的 NavIcon(type, color) 用纯 ArkUI 几何组件（Path/Circle/Rect/Column）'
                 '绘制 4 个导航图标（home/device/map/profile），基准 20×20vp，'
                 'color 参数着色实现主题感知，与')
    new_icon1 = ('采用像素风预生成 PNG 图标系统，共 7 组主题图标（home/device/profile/alert/'
                 'greenhouse/chart/sensor），每组 3 种尺寸（48×48 / 64×64 / 128×128），'
                 '通过 Image($r(\'app.media.xxx\')) 引用，零运行时绘制开销，保证多端渲染一致。'
                 'MushroomLogo 同步从纯几何绘制改为 ic_tab_home 图标。与')
    for p in doc.paragraphs:
        if replace_para_text(p, old_icon1, new_icon1):
            count += 1; print('OK: NavIcon -> PNG icons')
            break

    old_icon2 = ('[MapPage.MapIcon](file:///d:/SoftwareAction/features/core/src/main/ets/pages/MapPage.ets) '
                 '风格统一，替代 emoji 保证多端渲染一致（鸿蒙多端字体差异会导致 emoji 渲染不一致）。')
    new_icon2 = ('[MapPage.MapIcon](file:///d:/SoftwareAction/features/core/src/main/ets/pages/MapPage.ets) '
                 '风格统一。MapPage 中的 MapIcon 保留纯几何绘制方案（Circle/Rect/Stack），'
                 '因其需要 color 参数动态着色实现主题适配。')
    for p in doc.paragraphs:
        if replace_para_text(p, old_icon2, new_icon2):
            count += 1; print('OK: MapIcon note updated')
            break

    for p in doc.paragraphs:
        if replace_para_text(p, '5.7 矢量图标自绘（ArkUI 几何组件）',
                             '5.7 像素风图标系统（预生成 PNG + 主题适配）'):
            count += 1; print('OK: 5.7 heading updated')
            break

    # ============================================================
    # 7. 8.1 架构设计段落 - add mushroom brown note
    # ============================================================
    for p in doc.paragraphs:
        if 'PersistentStorage + AppStorage + ThemeManager 单例' in p.text:
            if '菌菇棕' not in p.text:
                if p.runs:
                    p.runs[-1].text += (
                        ' 当前 frosted 主题配色从薄荷绿迭代为菌菇棕系（与应用图标 #B07A3E 统一），'
                        '所有颜色 token 改为 6 位 hex（#RRGGBB）确保 API 24 兼容。')
                    count += 1; print('OK: 8.1 architecture note')
                    break

    # ============================================================
    # 8. 第十六章 技术亮点 - update theme description
    # ============================================================
    old_highlight = ('双主题原子替换：PersistentStorage 持久化（鸿蒙特有）+ AppStorage 真相源 '
                     '+ @StorageLink 双向绑定 + ThemeManager 单例，雾透玻璃与极致黑白两套设计语言，'
                     'backdropBlur 毛玻璃效果。')
    new_highlight = ('双主题原子替换：PersistentStorage 持久化（鸿蒙特有）+ AppStorage 真相源 '
                     '+ @StorageLink 双向绑定 + ThemeManager 单例，菌菇棕点缀雾透玻璃与深棕极致黑白两套设计语言，'
                     'backdropBlur 毛玻璃效果，80+ token 属性含字重体系、等宽字体、卡片高光、'
                     '按压态/禁用态阴影。')
    for p in doc.paragraphs:
        if replace_para_text(p, old_highlight, new_highlight):
            count += 1; print('OK: tech highlights updated')
            break

    # ============================================================
    # Save
    # ============================================================
    doc.save(DOC_PATH)
    print(f'\n=== Done: {count} updates applied ===')
    print(f'Saved: {DOC_PATH}')


if __name__ == '__main__':
    main()
