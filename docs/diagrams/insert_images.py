"""Insert diagram PNGs into the Word document at appropriate section positions.
Approach: Add paragraphs at end, then reorder in XML tree."""
import os
from docx import Document
from docx.shared import Inches, Cm
from docx.oxml.ns import qn
from docx.oxml import OxmlElement

DOC_PATH = r'D:\SoftwareAction\docs\鸿蒙技术开发文档.docx'
OUT_PATH = DOC_PATH  # 直接覆盖原文档
PNG_DIR = r'D:\SoftwareAction\docs\diagrams\png'

INSERTIONS = [
    ('3.1', '02_module_architecture.png', '图3-2 三层模块依赖关系图'),
    ('4.1', 'new_01_startup_routing.png', '图4-2 系统启动与路由流程'),
    ('5.1', '04_breakpoints.png', '图5-2 五端断点映射图'),
    ('5.4', '05_dual_layout.png', '图5-3 双模式入口布局对比图'),
    ('7.2 AppStorage', 'new_03_appstorage.png', '图7-2 全局状态管理机制'),
    ('8.1', '03_theme_flow.png', '图8-2 主题切换数据流图'),
    ('9.1', 'new_04_iot_end2end.png', '图9-2 IoT 端到端通信架构'),
    ('11.3', '08_mapkit_mvvm.png', '图11-2 MapViewComponent 双模式决策树'),
    ('12.4', 'new_02_mvvm_layers.png', '图12-2 MVVM 分层架构'),
]

def make_centered_image_para(doc, image_path, width_inches=5.5):
    """Create a centered paragraph with an image. Returns the paragraph."""
    para = doc.add_paragraph()
    para.alignment = 1  # center
    run = para.add_run()
    run.add_picture(image_path, width=Inches(width_inches))
    return para

def make_caption_para(doc, text):
    """Create a centered caption paragraph."""
    para = doc.add_paragraph()
    para.alignment = 1  # center
    run = para.add_run()
    run.text = text
    run.font.size = Cm(0.28)  # ~8pt
    run.font.color.rgb = None  # will set via XML
    # Set color to gray
    rPr = run._element.get_or_add_rPr()
    color = OxmlElement('w:color')
    color.set(qn('w:val'), '888888')
    rPr.append(color)
    return para

def make_spacer(doc):
    """Create a small spacer paragraph."""
    para = doc.add_paragraph()
    pPr = para._element.get_or_add_pPr()
    spacing = OxmlElement('w:spacing')
    spacing.set(qn('w:after'), '160')
    pPr.append(spacing)
    return para

def find_section_start_para(doc, keyword):
    """Find the heading paragraph that starts a section."""
    for para in doc.paragraphs:
        text = para.text.strip()
        style = para.style.name if para.style else ''
        if keyword in text and 'Heading' in style:
            return para
    return None

def find_section_end_para(doc, start_keyword):
    """Find the last content paragraph of a section (before next heading).
    Falls back to the heading paragraph if section has no content paragraphs (e.g. table-only sections)."""
    found = False
    last_content = None
    heading_para = None
    for para in doc.paragraphs:
        text = para.text.strip()
        style = para.style.name if para.style else ''

        if not found:
            if start_keyword in text and 'Heading' in style:
                found = True
                heading_para = para
            continue

        if 'Heading' in style:
            # Hit next heading → return last_content or fallback to heading
            return last_content if last_content is not None else heading_para

        if text:
            last_content = para

    return last_content if last_content is not None else heading_para

def move_element_after(target_element, element_to_move):
    """Move element_to_move right after target_element in the XML tree."""
    target_element.addnext(element_to_move)

def insert_at_position(doc, section_keyword, image_path, caption_text):
    """Insert image + caption after a section."""
    target = find_section_end_para(doc, section_keyword)
    if target is None:
        print(f'  SKIP: cannot find section end for "{section_keyword}"')
        return False

    # Create elements at the end of document
    img_para = make_centered_image_para(doc, image_path)
    cap_para = make_caption_para(doc, caption_text)
    spacer = make_spacer(doc)

    # Move them after the target paragraph
    # Move in reverse order: spacer, caption, image
    move_element_after(target._element, img_para._element)
    move_element_after(img_para._element, cap_para._element)
    move_element_after(cap_para._element, spacer._element)

    print(f'  OK [{caption_text[:30]}...] after section "{section_keyword}"')
    return True

def main():
    print(f'Opening document...')
    doc = Document(DOC_PATH)

    for keyword, png_name, caption in INSERTIONS:
        png_path = os.path.join(PNG_DIR, png_name)
        if not os.path.exists(png_path):
            print(f'  SKIP: {png_name} not found')
            continue
        insert_at_position(doc, keyword, png_path, caption)

    print(f'\nSaving to: {OUT_PATH}')
    doc.save(OUT_PATH)
    print('Done!')
    print(f'Output: {OUT_PATH}')

if __name__ == '__main__':
    main()
