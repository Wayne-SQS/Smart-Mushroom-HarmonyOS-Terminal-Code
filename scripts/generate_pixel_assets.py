"""
生成像素风 Tab 图标与空状态插画 - 配合蘑菇大棚 IoT 应用
风格：纯 pixel art，深棕描边，菌菇棕系配色
设计在小尺寸像素网格上，渲染时用 NEAREST 放大保持清晰锯齿

输出：
  Tab 专属图标（96/64/48 px，共 4 × 3 = 12 个）
    ic_tab_home.png      蘑菇屋（三角屋顶 + 方形屋身 + 顶部小蘑菇）
    ic_tab_device.png    传感器方块 + 天线
    ic_tab_alert.png     感叹号圆牌
    ic_tab_profile.png   蘑菇头 + 人脸

  空状态插画（256x256 px，共 3 个）
    empty_no_alert.png        笑脸蘑菇 + 对勾
    empty_no_device.png       蘑菇 + 问号
    empty_network_error.png   断开的云 + 悲伤蘑菇

配色取自 ThemeFrosted.ets 菌菇棕系
"""

from PIL import Image
import os

OUTPUT_DIR = r"d:\SoftwareAction\entry\src\main\resources\base\media"

# ==================== 主题配色（菌菇棕系） ====================
PRIMARY = (198, 134, 66)         # #C68642 菌菇棕
PRIMARY_DARK = (139, 90, 43)     # #8B5A2B 深菌菇棕
SUCCESS = (122, 158, 110)        # #7A9E6E 草绿
WARNING = (230, 162, 60)         # #E6A23C 琥珀
DANGER = (224, 108, 117)         # #E06C75 警告红
BG = (245, 246, 247)             # #F5F6F7 中性白
OUTLINE = (60, 40, 20)           # #3C2814 深棕描边
STEM = (245, 230, 205)           # 菌柄
STEM_SHADOW = (220, 200, 170)    # 茎阴影
SPOT = (255, 245, 225)           # 蘑菇斑点（白）
CAP_HI = (224, 181, 138)         # 菌盖高光（浅菌菇棕）
CLOUD = (200, 210, 220)          # 云朵灰蓝
CLOUD_DARK = (140, 155, 170)     # 云朵深色
TRANSPARENT = (0, 0, 0, 0)


class PixelCanvas:
    """小尺寸像素网格画布，渲染时按 NEAREST 放大保持锯齿"""

    def __init__(self, grid_w, grid_h):
        self.w = grid_w
        self.h = grid_h
        self.img = Image.new('RGBA', (grid_w, grid_h), TRANSPARENT)
        self.px = self.img.load()

    def set(self, x, y, color):
        if color is None:
            return
        if 0 <= x < self.w and 0 <= y < self.h:
            self.px[x, y] = color

    def rect(self, x, y, w, h, color):
        for dy in range(h):
            for dx in range(w):
                self.set(x + dx, y + dy, color)

    def hline(self, x, y, w, color):
        for dx in range(w):
            self.set(x + dx, y, color)

    def vline(self, x, y, h, color):
        for dy in range(h):
            self.set(x, y + dy, color)

    def fill_triangle_iso(self, apex_x, apex_y, base_y, half_width, color):
        """以 (apex_x, apex_y) 为顶点的等腰三角形，底边在 base_y"""
        for y in range(apex_y, base_y + 1):
            t = (y - apex_y) / max(1, base_y - apex_y)
            half = int(half_width * t)
            for x in range(apex_x - half, apex_x + half + 1):
                self.set(x, y, color)

    def fill_half_circle_top(self, cx, cy, r, color):
        """以 (cx, cy) 为圆心，绘制上半圆（y <= cy）"""
        for y in range(cy - r, cy + 1):
            dx = int((r * r - (y - cy) ** 2) ** 0.5)
            for x in range(cx - dx, cx + dx + 1):
                self.set(x, y, color)

    def outline_half_circle_top(self, cx, cy, r, color):
        """上半圆轮廓（左右边缘 + 顶部）"""
        for y in range(cy - r, cy + 1):
            dx = int((r * r - (y - cy) ** 2) ** 0.5)
            self.set(cx - dx, y, color)
            if dx > 0:
                self.set(cx + dx, y, color)

    def fill_circle(self, cx, cy, r, color):
        """实心圆"""
        for y in range(cy - r, cy + r + 1):
            dx = int((r * r - (y - cy) ** 2) ** 0.5)
            for x in range(cx - dx, cx + dx + 1):
                self.set(x, y, color)

    def outline_circle(self, cx, cy, r, color):
        """圆轮廓（midpoint 算法，1px 宽）"""
        if r <= 0:
            self.set(cx, cy, color)
            return
        x = r
        y = 0
        err = 0
        while x >= y:
            self.set(cx + x, cy + y, color)
            self.set(cx + y, cy + x, color)
            self.set(cx - y, cy + x, color)
            self.set(cx - x, cy + y, color)
            self.set(cx - x, cy - y, color)
            self.set(cx - y, cy - x, color)
            self.set(cx + y, cy - x, color)
            self.set(cx + x, cy - y, color)
            y += 1
            err += 1 + 2 * y
            if 2 * (err - x) + 1 > 0:
                x -= 1
                err += 1 - 2 * x

    def render(self, target_size):
        """NEAREST 放大保持锯齿"""
        return self.img.resize((target_size, target_size), Image.NEAREST)


# ==================== Tab 图标（16x16 网格） ====================

def draw_tab_home(c):
    """首页 - 蘑菇屋（三角屋顶 + 方形屋身 + 顶部小蘑菇）"""
    # 顶部小蘑菇（屋顶装饰）
    c.set(8, 1, PRIMARY)
    c.hline(7, 2, 3, PRIMARY)
    c.hline(6, 3, 5, PRIMARY)
    c.hline(6, 4, 5, PRIMARY)
    c.set(8, 3, SPOT)              # 白色斑点
    c.hline(7, 5, 3, STEM)         # 茎

    # 三角屋顶（深棕）
    c.fill_triangle_iso(8, 6, 10, 6, PRIMARY_DARK)
    # 屋顶高光（浅棕）
    c.set(7, 7, CAP_HI)
    c.set(8, 8, CAP_HI)
    c.set(7, 9, CAP_HI)

    # 屋身（方框 + 奶油填充）：x=2..14, y=11..15
    c.hline(2, 11, 13, OUTLINE)    # 顶
    c.hline(2, 15, 13, OUTLINE)    # 底
    c.vline(2, 11, 5, OUTLINE)     # 左
    c.vline(14, 11, 5, OUTLINE)    # 右
    for x in range(3, 14):
        for y in range(12, 15):
            c.set(x, y, BG)

    # 门（深棕）
    c.rect(7, 12, 2, 3, PRIMARY_DARK)
    c.set(7, 12, OUTLINE)          # 门顶描边
    c.set(8, 13, OUTLINE)          # 门把手

    # 窗户（草绿） + 十字
    c.rect(4, 12, 2, 2, SUCCESS)
    c.rect(10, 12, 2, 2, SUCCESS)
    c.set(5, 13, OUTLINE)
    c.set(11, 13, OUTLINE)


def draw_tab_device(c):
    """设备 - 传感器方块 + 天线 + 信号波"""
    # 信号波（顶部弧）
    c.set(6, 0, SUCCESS)
    c.set(9, 0, SUCCESS)
    c.set(5, 1, SUCCESS)
    c.set(10, 1, SUCCESS)

    # 天线顶 + 杆
    c.set(7, 1, DANGER)
    c.set(8, 1, DANGER)
    c.vline(7, 2, 2, OUTLINE)
    c.vline(8, 2, 2, OUTLINE)

    # 传感器主体（方框）：x=2..13, y=4..14
    c.hline(2, 4, 12, OUTLINE)
    c.hline(2, 14, 12, OUTLINE)
    c.vline(2, 4, 11, OUTLINE)
    c.vline(13, 4, 11, OUTLINE)
    for x in range(3, 13):
        for y in range(5, 14):
            c.set(x, y, BG)

    # 屏幕（深色矩形）
    c.rect(4, 5, 8, 5, PRIMARY_DARK)
    c.hline(4, 5, 8, OUTLINE)
    c.hline(4, 9, 8, OUTLINE)
    c.vline(4, 5, 5, OUTLINE)
    c.vline(11, 5, 5, OUTLINE)
    # 屏幕内波形 / 数据点
    c.set(5, 8, SUCCESS)
    c.set(6, 7, SUCCESS)
    c.set(7, 8, SUCCESS)
    c.set(8, 7, SUCCESS)
    c.set(9, 8, SUCCESS)
    c.set(10, 7, SUCCESS)

    # 底部指示灯（绿/橙/红）
    c.set(4, 12, SUCCESS)
    c.set(5, 12, SUCCESS)
    c.set(7, 12, WARNING)
    c.set(8, 12, WARNING)
    c.set(10, 12, DANGER)
    c.set(11, 12, DANGER)


def draw_tab_alert(c):
    """告警 - 感叹号圆牌"""
    # 红色圆牌（外圈填充 + 描边）
    c.fill_circle(8, 8, 7, DANGER)
    c.outline_circle(8, 8, 7, OUTLINE)

    # 内圈（白色背景 + 描边）
    c.fill_circle(8, 8, 5, BG)
    c.outline_circle(8, 8, 5, OUTLINE)

    # 感叹号（深色）
    # 顶部竖条
    c.rect(7, 4, 2, 5, OUTLINE)
    # 底部圆点
    c.rect(7, 10, 2, 2, OUTLINE)


def draw_tab_profile(c):
    """我的 - 蘑菇头 + 人脸"""
    # 蘑菇帽（半圆）：圆心 (8, 7)，半径 6
    cx, cy, r = 8, 7, 6
    c.fill_half_circle_top(cx, cy, r, PRIMARY)
    c.outline_half_circle_top(cx, cy, r, PRIMARY_DARK)
    # 帽底部边
    c.hline(cx - r, cy, 2 * r + 1, PRIMARY_DARK)

    # 蘑菇斑点（白）
    c.set(5, 4, SPOT)
    c.set(10, 5, SPOT)
    c.set(8, 3, SPOT)
    c.set(11, 6, SPOT)

    # 帽子高光
    c.set(4, 5, CAP_HI)
    c.set(5, 6, CAP_HI)

    # 茎（米色矩形）：x=5..10, y=8..14
    c.rect(5, 8, 6, 7, STEM)
    c.vline(5, 8, 7, STEM_SHADOW)
    c.vline(10, 8, 7, STEM_SHADOW)
    c.hline(5, 14, 6, PRIMARY_DARK)
    # 茎顶边（与帽相接处）
    c.hline(5, 8, 6, OUTLINE)

    # 眼睛（2x2 深色）
    c.rect(6, 10, 1, 2, OUTLINE)
    c.rect(9, 10, 1, 2, OUTLINE)

    # 微笑（弧线）
    c.hline(7, 12, 2, OUTLINE)     # 嘴底
    c.set(6, 11, OUTLINE)          # 左嘴角
    c.set(9, 11, OUTLINE)          # 右嘴角
    c.set(7, 13, OUTLINE)          # 嘴下中
    c.set(8, 13, OUTLINE)


# ==================== 空状态插画（32x32 网格） ====================

def draw_empty_no_alert(c):
    """无告警 - 笑脸蘑菇 + 对勾徽章"""
    # 蘑菇主体居中（稍偏左）
    cx, cy, r = 13, 16, 8

    # 蘑菇帽（半圆 + 描边）
    c.fill_half_circle_top(cx, cy, r, PRIMARY)
    c.outline_half_circle_top(cx, cy, r, PRIMARY_DARK)
    c.hline(cx - r, cy, 2 * r + 1, PRIMARY_DARK)

    # 帽子高光（浅棕）
    c.set(cx - 4, cy - 6, CAP_HI)
    c.set(cx - 5, cy - 5, CAP_HI)
    c.set(cx - 3, cy - 7, CAP_HI)

    # 蘑菇斑点（白）
    c.set(cx + 2, cy - 6, SPOT)
    c.set(cx + 5, cy - 4, SPOT)
    c.set(cx - 1, cy - 7, SPOT)
    c.set(cx + 4, cy - 2, SPOT)
    c.set(cx + 6, cy - 1, SPOT)

    # 茎（米色矩形）
    sx, sy, sw, sh = cx - 4, cy + 1, 9, 11
    c.rect(sx, sy, sw, sh, STEM)
    c.vline(sx, sy, sh, STEM_SHADOW)
    c.vline(sx + sw - 1, sy, sh, STEM_SHADOW)
    c.hline(sx, sy + sh - 1, sw, PRIMARY_DARK)
    c.hline(sx, sy, sw, OUTLINE)

    # 眼睛（眯眯眼弧线）
    # 左眼
    c.set(cx - 4, cy + 4, OUTLINE)
    c.set(cx - 3, cy + 5, OUTLINE)
    c.set(cx - 2, cy + 5, OUTLINE)
    c.set(cx - 5, cy + 5, OUTLINE)
    # 右眼
    c.set(cx + 4, cy + 4, OUTLINE)
    c.set(cx + 3, cy + 5, OUTLINE)
    c.set(cx + 2, cy + 5, OUTLINE)
    c.set(cx + 5, cy + 5, OUTLINE)

    # 微笑（弧线 - 嘴巴）
    c.hline(cx - 1, cy + 8, 3, OUTLINE)
    c.set(cx - 2, cy + 7, OUTLINE)
    c.set(cx + 2, cy + 7, OUTLINE)
    c.set(cx - 2, cy + 9, OUTLINE)
    c.set(cx + 2, cy + 9, OUTLINE)

    # 腮红（橙色）
    c.set(cx - 5, cy + 6, WARNING)
    c.set(cx + 5, cy + 6, WARNING)

    # 对勾徽章（右上角，绿色圆 + 白色勾）
    bcx, bcy, br = 26, 6, 4
    c.fill_circle(bcx, bcy, br, SUCCESS)
    c.outline_circle(bcx, bcy, br, OUTLINE)
    # 白色对勾
    c.set(bcx - 1, bcy + 1, SPOT)
    c.set(bcx, bcy + 2, SPOT)
    c.set(bcx + 1, bcy + 1, SPOT)
    c.set(bcx + 2, bcy, SPOT)
    c.set(bcx + 3, bcy - 1, SPOT)


def draw_empty_no_device(c):
    """无设备 - 蘑菇 + 问号徽章"""
    # 蘑菇居中（稍偏左）
    cx, cy, r = 12, 17, 7

    # 蘑菇帽
    c.fill_half_circle_top(cx, cy, r, PRIMARY)
    c.outline_half_circle_top(cx, cy, r, PRIMARY_DARK)
    c.hline(cx - r, cy, 2 * r + 1, PRIMARY_DARK)

    # 帽子高光
    c.set(cx - 3, cy - 5, CAP_HI)
    c.set(cx - 4, cy - 4, CAP_HI)

    # 蘑菇斑点
    c.set(cx + 1, cy - 5, SPOT)
    c.set(cx + 4, cy - 3, SPOT)
    c.set(cx - 2, cy - 6, SPOT)
    c.set(cx + 3, cy - 1, SPOT)

    # 茎
    sx, sy, sw, sh = cx - 4, cy + 1, 9, 10
    c.rect(sx, sy, sw, sh, STEM)
    c.vline(sx, sy, sh, STEM_SHADOW)
    c.vline(sx + sw - 1, sy, sh, STEM_SHADOW)
    c.hline(sx, sy + sh - 1, sw, PRIMARY_DARK)
    c.hline(sx, sy, sw, OUTLINE)

    # 眼睛（圆点）
    c.set(cx - 2, cy + 4, OUTLINE)
    c.set(cx + 2, cy + 4, OUTLINE)
    c.set(cx - 2, cy + 5, OUTLINE)
    c.set(cx + 2, cy + 5, OUTLINE)

    # 困惑表情（嘴歪）
    c.set(cx - 1, cy + 7, OUTLINE)
    c.set(cx, cy + 7, OUTLINE)
    c.set(cx + 1, cy + 8, OUTLINE)
    c.set(cx - 2, cy + 8, OUTLINE)

    # 问号徽章（右上角，琥珀色圆 + 白色问号）
    bcx, bcy, br = 25, 7, 5
    c.fill_circle(bcx, bcy, br, WARNING)
    c.outline_circle(bcx, bcy, br, OUTLINE)
    # 白色问号
    # 顶部弯钩
    c.set(bcx - 1, bcy - 2, SPOT)
    c.set(bcx, bcy - 3, SPOT)
    c.set(bcx + 1, bcy - 3, SPOT)
    c.set(bcx + 2, bcy - 2, SPOT)
    c.set(bcx + 2, bcy - 1, SPOT)
    c.set(bcx + 1, bcy, SPOT)
    c.set(bcx, bcy + 1, SPOT)
    # 底部点
    c.set(bcx, bcy + 3, SPOT)


def draw_empty_network_error(c):
    """网络错误 - 断开的云 + 悲伤蘑菇"""
    # 云朵（左半边）
    cl_y = 3
    c.rect(2, cl_y + 2, 10, 4, CLOUD)
    c.rect(4, cl_y, 6, 2, CLOUD)
    c.fill_circle(5, cl_y + 3, 2, CLOUD)
    c.fill_circle(9, cl_y + 3, 2, CLOUD)
    # 云朵描边
    c.hline(2, cl_y + 2, 10, OUTLINE)
    c.hline(2, cl_y + 5, 10, OUTLINE)
    c.vline(2, cl_y + 2, 4, OUTLINE)
    c.vline(11, cl_y + 2, 4, OUTLINE)
    c.hline(4, cl_y, 6, OUTLINE)
    c.vline(4, cl_y, 2, OUTLINE)
    c.vline(9, cl_y, 2, OUTLINE)

    # 云朵2（右半边，与左半边有断裂）
    c.rect(19, cl_y + 2, 10, 4, CLOUD)
    c.rect(21, cl_y, 6, 2, CLOUD)
    c.fill_circle(22, cl_y + 3, 2, CLOUD)
    c.fill_circle(26, cl_y + 3, 2, CLOUD)
    c.hline(19, cl_y + 2, 10, OUTLINE)
    c.hline(19, cl_y + 5, 10, OUTLINE)
    c.vline(19, cl_y + 2, 4, OUTLINE)
    c.vline(28, cl_y + 2, 4, OUTLINE)
    c.hline(21, cl_y, 6, OUTLINE)
    c.vline(21, cl_y, 2, OUTLINE)
    c.vline(26, cl_y, 2, OUTLINE)

    # 中间闪电符号（琥珀色，表示断开）
    bolt_x, bolt_y = 14, 4
    c.set(bolt_x, bolt_y, WARNING)
    c.set(bolt_x, bolt_y + 1, WARNING)
    c.set(bolt_x - 1, bolt_y + 1, WARNING)
    c.set(bolt_x + 1, bolt_y + 2, WARNING)
    c.set(bolt_x, bolt_y + 3, WARNING)
    c.set(bolt_x - 1, bolt_y + 3, WARNING)
    c.set(bolt_x, bolt_y + 4, WARNING)

    # 闪电描边
    c.set(bolt_x - 1, bolt_y, OUTLINE)
    c.set(bolt_x + 1, bolt_y, OUTLINE)
    c.set(bolt_x + 1, bolt_y + 1, OUTLINE)
    c.set(bolt_x + 2, bolt_y + 2, OUTLINE)
    c.set(bolt_x + 1, bolt_y + 3, OUTLINE)
    c.set(bolt_x + 1, bolt_y + 4, OUTLINE)
    c.set(bolt_x - 1, bolt_y + 5, OUTLINE)

    # 悲伤蘑菇（下方居中）
    cx, cy, r = 16, 22, 6
    # 帽
    c.fill_half_circle_top(cx, cy, r, PRIMARY)
    c.outline_half_circle_top(cx, cy, r, PRIMARY_DARK)
    c.hline(cx - r, cy, 2 * r + 1, PRIMARY_DARK)

    # 帽子高光
    c.set(cx - 3, cy - 4, CAP_HI)
    c.set(cx - 4, cy - 3, CAP_HI)

    # 斑点
    c.set(cx + 1, cy - 4, SPOT)
    c.set(cx + 3, cy - 2, SPOT)
    c.set(cx - 1, cy - 5, SPOT)
    c.set(cx + 4, cy - 1, SPOT)

    # 茎
    sx, sy, sw, sh = cx - 3, cy + 1, 7, 7
    c.rect(sx, sy, sw, sh, STEM)
    c.vline(sx, sy, sh, STEM_SHADOW)
    c.vline(sx + sw - 1, sy, sh, STEM_SHADOW)
    c.hline(sx, sy + sh - 1, sw, PRIMARY_DARK)
    c.hline(sx, sy, sw, OUTLINE)

    # 眼睛（悲伤 - 弧线向下）
    c.set(cx - 2, cy + 3, OUTLINE)
    c.set(cx - 2, cy + 4, OUTLINE)
    c.set(cx - 1, cy + 4, OUTLINE)
    c.set(cx + 2, cy + 3, OUTLINE)
    c.set(cx + 2, cy + 4, OUTLINE)
    c.set(cx + 1, cy + 4, OUTLINE)

    # 悲伤嘴（倒弧）
    c.hline(cx - 1, cy + 6, 3, OUTLINE)
    c.set(cx - 2, cy + 7, OUTLINE)
    c.set(cx + 2, cy + 7, OUTLINE)

    # 眼泪
    c.set(cx - 4, cy + 5, DANGER)
    c.set(cx + 4, cy + 5, DANGER)


# ==================== 主函数 ====================

TAB_ICONS = [
    ('ic_tab_home', draw_tab_home, 16),
    ('ic_tab_device', draw_tab_device, 16),
    ('ic_tab_alert', draw_tab_alert, 16),
    ('ic_tab_profile', draw_tab_profile, 16),
]

EMPTY_STATES = [
    ('empty_no_alert', draw_empty_no_alert, 32),
    ('empty_no_device', draw_empty_no_device, 32),
    ('empty_network_error', draw_empty_network_error, 32),
]

TAB_SIZES = [96, 64, 48]
EMPTY_SIZE = 256


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    print("=" * 60)
    print("生成像素风 Tab 图标 & 空状态插画（菌菇棕系配色）")
    print("=" * 60)

    print("\n[1] Tab 专属像素图标（96/64/48 px）")
    for name, fn, grid in TAB_ICONS:
        for sz in TAB_SIZES:
            canvas = PixelCanvas(grid, grid)
            fn(canvas)
            img = canvas.render(sz)
            suffix = '' if sz == 96 else f'_{sz}'
            path = os.path.join(OUTPUT_DIR, f"{name}{suffix}.png")
            img.save(path, "PNG", optimize=True)
        print(f"  ✅ {name}.png / {name}_64.png / {name}_48.png")

    print("\n[2] 空状态像素插画（256x256 px）")
    for name, fn, grid in EMPTY_STATES:
        canvas = PixelCanvas(grid, grid)
        fn(canvas)
        img = canvas.render(EMPTY_SIZE)
        path = os.path.join(OUTPUT_DIR, f"{name}.png")
        img.save(path, "PNG", optimize=True)
        print(f"  ✅ {name}.png  (256x256 px)")

    print("\n配色：")
    print(f"  PRIMARY      #C68642 菌菇棕")
    print(f"  PRIMARY_DARK #8B5A2B 深菌菇棕")
    print(f"  SUCCESS      #7A9E6E 草绿")
    print(f"  WARNING      #E6A23C 琥珀")
    print(f"  DANGER       #E06C75 警告红")
    print(f"  BG           #F5F6F7 中性白")
    print(f"  OUTLINE      #3C2814 深棕描边")
    print(f"\n输出目录：{OUTPUT_DIR}")
    print(f"共生成 {len(TAB_ICONS) * len(TAB_SIZES) + len(EMPTY_STATES)} 个文件"
          f"（{len(TAB_ICONS)} Tab × {len(TAB_SIZES)} 尺寸 + {len(EMPTY_STATES)} 空状态）")


if __name__ == "__main__":
    main()
