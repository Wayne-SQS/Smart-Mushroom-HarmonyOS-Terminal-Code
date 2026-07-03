"""Set all text in docx paragraphs and tables to black (#000000)."""
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
from docx import Document
from docx.shared import RGBColor
from docx.oxml.ns import qn
from docx.oxml import OxmlElement

DOC_PATH = r'D:\SoftwareAction\docs\鸿蒙技术开发文档.docx'

BLACK = RGBColor(0, 0, 0)

def force_black(run):
    """Force a run's text color to black, removing any existing color."""
    rPr = run._element.get_or_add_rPr()
    # Remove existing color elements
    for color_tag in rPr.findall(qn('w:color')):
        rPr.remove(color_tag)
    # Add black color
    color = OxmlElement('w:color')
    color.set(qn('w:val'), '000000')
    rPr.append(color)

def main():
    doc = Document(DOC_PATH)
    count_p = 0
    count_t = 0

    # Paragraph runs
    for para in doc.paragraphs:
        for run in para.runs:
            if run.font.color and run.font.color.rgb:
                # Only fix non-black non-auto colors
                if str(run.font.color.rgb) != '000000':
                    force_black(run)
                    count_p += 1
            elif run.font.color and run.font.color.type is None:
                # Auto/default color — leave as is
                pass

    # Table runs
    for table in doc.tables:
        for row in table.rows:
            for cell in row.cells:
                for para in cell.paragraphs:
                    for run in para.runs:
                        force_black(run)
                        count_t += 1

    doc.save(DOC_PATH)
    print(f'Updated {count_p} paragraph runs + {count_t} table runs to black')
    print(f'Saved: {DOC_PATH}')

if __name__ == '__main__':
    main()
