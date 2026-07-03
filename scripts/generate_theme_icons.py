"""
生成蘑菇主题小图标 - 配合 ThemeFrosted 蘑菇棕系配色
风格：像素风，与应用图标 / LoginPage 蘑菇插画统一
配色：取自 ThemeFrosted.ets（primary #C68642 / success #7A9E6E 等）

输出：6 个装饰性小图标，透明背景 PNG，多尺寸
  ic_mushroom.png   蘑菇吉祥物（Header/空状态装饰）
  ic_greenhouse.png  大棚（设备/地图页）
  ic_plant.png       幼苗（生长页）
  ic_sensor.png      传感器节点（设备页）
  ic_chart.png       柱状图（趋势页）
  ic_alert.png       告警铃铛（告警页）
"""

from PIL import Image, ImageDraw
import os
import math

OUTPUT_DIR = r"d:\SoftwareAction\entry\src\main\resources\base\media"
SIZE = 256  # 主尺寸，同时输出 128 / 64

# ==================== 主题配色（取自 ThemeFrosted.ets） ====================
PRIMARY = (198, 134, 66)       # #C68642 菌菇棕
PRIMARY_LIGHT = (224, 181, 138)  # #E0B58A 浅菌菇
PRIMARY_DARK = (139, 90, 43)   # #8B5A2B 深菌菇
SUCCESS = (122, 158, 110)      # #7A9E6E 状态绿
WARNING = (230, 162, 60)       # #E6A23C 琥珀
DANGER = (224, 108, 117)       # #E06C75 警告红
INFO = (107, 142, 158)         # #6B8E9E 雾蓝
CREAM = (247, 243, 236)        # #F7F3EC 奶油白
STEM = (245, 230, 205)         # 菌柄色
STEM_SHADOW = (220, 200, 170)
SPOT = (255, 245, 225)
DARK = (58, 46, 42)            # #3A2E2A 深棕文字


def px(draw, x, y, w, h, color):
    """像素方块"""
    if w <= 0 or h <= 0:
        return
    draw.rectangle([int(x), int(y), int(x) + int(w) - 1, int(y) + int(h) - 1], fill=color)


def px_circle(draw, cx, cy, r, color):
    """像素圆"""
    for dy in range(-r, r + 1, 2):
        dx = int(math.sqrt(max(0, r * r - dy * dy)))
        draw.rectangle([cx - dx, cy + dy, cx + dx, cy + dy + 1], fill=color)


def new_canvas(size):
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def scale(s, ratio):
    return max(1, int(s * ratio))


def draw_mushroom_icon(draw, size):
    """蘑菇吉祥物 - 居中圆角蘑菇"""
    r = size / 256
    cx, cy = size // 2, int(size * 0.52)
    cap_w, cap_h = scale(150, r), scale(80, r)
    stem_w, stem_h = scale(60, r), scale(80, r)

    # 阴影
    draw.ellipse([cx - cap_w // 2 + 8, cy + stem_h // 2 - 4,
                  cx + cap_w // 2 - 8, cy + stem_h // 2 + 10], fill=(0, 0, 0, 35))

    # 茎
    stem_top = cy - stem_h // 2
    px(draw, cx - stem_w // 2, stem_top, stem_w, stem_h, STEM)
    px(draw, cx - stem_w // 2, stem_top, scale(8, r), stem_h, STEM_SHADOW)
    px(draw, cx + stem_w // 2 - scale(8, r), stem_top + scale(8, r),
       scale(6, r), stem_h - scale(16, r), (252, 242, 222))

    # 菌盖（半圆分层）
    cap_cy = stem_top - cap_h // 2 + scale(18, r)
    for dy in range(cap_h):
        ratio = 1.0 - dy / cap_h
        if ratio < 0:
            ratio = 0
        cw = int(cap_w // 2 * math.sqrt(ratio))
        y = cap_cy - cap_h // 2 + dy
        if dy < cap_h * 0.25:
            c = PRIMARY_LIGHT
        elif dy < cap_h * 0.6:
            c = PRIMARY
        else:
            c = PRIMARY_DARK
        px(draw, cx - cw, y, cw * 2, 2, c)

    # 菌盖底部深边
    px(draw, cx - cap_w // 2 + scale(12, r), cap_cy + cap_h // 2 - scale(4, r),
       cap_w - scale(24, r), scale(6, r), PRIMARY_DARK)

    # 白色斑点
    for sx, sy, sw in [(-scale(34, r), -scale(8, r), scale(14, r)),
                       (scale(26, r), -scale(16, r), scale(12, r)),
                       (-scale(8, r), -scale(32, r), scale(10, r))]:
        px(draw, cx + sx, cap_cy + sy, sw, int(sw * 0.7), SPOT)
        px(draw, cx + sx, cap_cy + sy, int(sw * 0.4), int(sw * 0.3), (255, 255, 245))


def draw_greenhouse_icon(draw, size):
    """大棚 - 拱形温室"""
    r = size / 256
    cx, cy = size // 2, int(size * 0.55)
    w, h = scale(180, r), scale(120, r)
    arch_r = w // 2
    base_h = int(h * 0.18)
    base_y = cy + h // 2 - base_h
    frame = (120, 140, 160)
    glass = (220, 235, 245)
    glass_light = (235, 245, 250)

    # 基座
    px(draw, cx - w // 2, base_y, w, base_h, (100, 120, 140))

    # 拱形玻璃
    steps = 30
    points = []
    for i in range(steps + 1):
        t = i / steps
        a = math.pi * t
        x = int(cx - arch_r * math.cos(a))
        y = int(cy - h // 2 + base_h + arch_r - arch_r * math.sin(a))
        points.append((x, y, t))

    for i in range(steps):
        x1, y1, t = points[i]
        x2, y2, _ = points[i + 1]
        glass_c = glass_light if t < 0.4 else glass
        px(draw, x1, y1, max(2, x2 - x1), max(2, y2 - y1), glass_c)

    # 竖框线
    for i in range(6):
        t = i / 5
        a = math.pi * t
        fx = int(cx - arch_r * math.cos(a))
        fy = int(cy - h // 2 + base_h + arch_r - arch_r * math.sin(a))
        px(draw, fx - 1, fy, 3, base_y - fy, frame)

    # 顶部状态灯（绿）
    px_circle(draw, cx, int(cy - h * 0.36), scale(8, r), SUCCESS)
    px_circle(draw, cx, int(cy - h * 0.36), scale(4, r), (180, 220, 170))


def draw_plant_icon(draw, size):
    """幼苗 - 两片叶子 + 茎"""
    r = size / 256
    cx, cy = size // 2, int(size * 0.62)
    # 茎
    px(draw, cx - scale(5, r), cy - scale(70, r), scale(10, r), scale(70, r), SUCCESS)
    # 左叶
    draw_ellipse_leaf(draw, cx - scale(40, r), cy - scale(50, r), scale(45, r), scale(30, r),
                      (145, 200, 115), (110, 175, 90))
    # 右叶
    draw_ellipse_leaf(draw, cx + scale(5, r), cy - scale(55, r), scale(45, r), scale(30, r),
                      (145, 200, 115), (110, 175, 90))
    # 土壤
    px(draw, cx - scale(50, r), cy, scale(100, r), scale(20, r), (120, 88, 55))
    px(draw, cx - scale(50, r), cy, scale(100, r), scale(4, r), (90, 65, 40))
    # 土粒
    for tx, ts in [(-30, 4), (-10, 3), (15, 5), (32, 3)]:
        px(draw, cx + tx, cy + 8, ts, ts, (90, 65, 40))


def draw_ellipse_leaf(draw, x, y, w, h, light, dark):
    """椭圆叶子"""
    for dy in range(h):
        ratio = 1.0 - abs(dy - h / 2) / (h / 2)
        cw = int(w / 2 * math.sqrt(max(0, ratio)))
        c = light if dy < h * 0.5 else dark
        px(draw, x + w // 2 - cw, y + dy, cw * 2, 2, c)
    # 叶脉
    px(draw, x + w // 2 - 1, y + 2, 2, h - 4, (80, 140, 70))


def draw_sensor_icon(draw, size):
    """传感器节点 - 圆形设备 + WiFi 弧"""
    r = size / 256
    cx, cy = size // 2, int(size * 0.5)
    body = scale(80, r)
    # 设备主体
    px(draw, cx - body // 2, cy - body // 2, body, body, (240, 240, 245))
    px(draw, cx - body // 2, cy - body // 2, body, scale(6, r), (180, 190, 200))
    px(draw, cx - body // 2, cy + body // 2 - scale(6, r), body, scale(6, r), (180, 190, 200))
    px(draw, cx - body // 2, cy - body // 2, scale(6, r), body, (180, 190, 200))
    px(draw, cx + body // 2 - scale(6, r), cy - body // 2, scale(6, r), body, (180, 190, 200))
    # 屏幕
    px(draw, cx - scale(25, r), cy - scale(20, r), scale(50, r), scale(34, r), INFO)
    # 数据条
    for i, bh in enumerate([14, 22, 18]):
        bx = cx - scale(20, r) + i * scale(15, r)
        px(draw, bx, cy + scale(10, r) - bh, scale(10, r), bh, (150, 200, 220))
    # WiFi 弧（顶部）
    for wi, radius in enumerate([scale(28, r), scale(40, r), scale(52, r)]):
        col = SUCCESS if wi == 2 else (60, 70, 80)
        for a in range(210, 331, 4):
            rad = math.radians(a)
            x = int(cx + radius * math.cos(rad))
            y = int(cy - body // 2 - scale(8, r) + radius * math.sin(rad))
            px(draw, x - 1, y - 1, 3, 3, col)
    # 状态点
    px_circle(draw, cx, cy - body // 2 - scale(8, r), scale(5, r), SUCCESS)


def draw_chart_icon(draw, size):
    """柱状图 - 4 根棕色柱"""
    r = size / 256
    cx, cy = size // 2, int(size * 0.55)
    w = scale(160, r)
    base_y = cy + scale(50, r)
    # 基线
    px(draw, cx - w // 2, base_y, w, scale(4, r), DARK)
    # 柱子（渐高）
    bars = [(0.18, 60), (0.40, 90), (0.62, 75), (0.84, 110)]
    for ratio, bh in bars:
        bx = cx - w // 2 + int(w * ratio) - scale(12, r)
        bh = scale(bh, r)
        # 柱主体
        px(draw, bx, base_y - bh, scale(24, r), bh, PRIMARY)
        # 顶部高光
        px(draw, bx, base_y - bh, scale(24, r), scale(6, r), PRIMARY_LIGHT)
        # 底部深色
        px(draw, bx, base_y - scale(6, r), scale(24, r), scale(6, r), PRIMARY_DARK)
    # 趋势线（绿点）
    for ratio, bh in bars:
        bx = cx - w // 2 + int(w * ratio) - scale(4, r)
        px_circle(draw, bx, base_y - scale(bh, r) - scale(8, r), scale(4, r), SUCCESS)


def draw_alert_icon(draw, size):
    """告警铃铛"""
    r = size / 256
    cx, cy = size // 2, int(size * 0.5)
    w = scale(120, r)
    h = scale(110, r)
    # 铃身（梯形/钟形）
    for dy in range(h):
        ratio = dy / h
        cw = int(w * (0.3 + 0.7 * math.sqrt(ratio)))
        c = WARNING if dy < h * 0.7 else (200, 140, 40)
        px(draw, cx - cw // 2, cy - h // 2 + dy, cw, 2, c)
    # 顶部圆钮
    px_circle(draw, cx, cy - h // 2 - scale(8, r), scale(8, r), (200, 140, 40))
    # 底部横条
    px(draw, cx - w // 2 - scale(8, r), cy + h // 2, w + scale(16, r), scale(8, r), PRIMARY_DARK)
    # 摆锤（红点）
    px_circle(draw, cx, cy + h // 2 + scale(14, r), scale(8, r), DANGER)
    # 感叹号
    px(draw, cx - scale(4, r), cy - h // 4, scale(8, r), scale(30, r), DARK)
    px(draw, cx - scale(4, r), cy + scale(10, r), scale(8, r), scale(8, r), DARK)


ICONS = [
    ('ic_mushroom', draw_mushroom_icon),
    ('ic_greenhouse', draw_greenhouse_icon),
    ('ic_plant', draw_plant_icon),
    ('ic_sensor', draw_sensor_icon),
    ('ic_chart', draw_chart_icon),
    ('ic_alert', draw_alert_icon),
]


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    print("=" * 50)
    print("生成蘑菇主题小图标（配合 ThemeFrosted 蘑菇棕系）")
    print("=" * 50)

    for name, fn in ICONS:
        for sz, suffix in [(256, ''), (128, '_128'), (64, '_64')]:
            img, draw = new_canvas(sz)
            fn(draw, sz)
            path = os.path.join(OUTPUT_DIR, f"{name}{suffix}.png")
            img.save(path, "PNG", optimize=True)
        print(f"  ✅ {name}.png (256/128/64)")

    print("\n配色：")
    print(f"  primary #C68642 / primaryDark #8B5A2B")
    print(f"  success #7A9E6E / warning #E6A23C / danger #E06C75")
    print(f"  bgPage #F7F3EC (奶油白)")
    print(f"\n输出目录：{OUTPUT_DIR}")
    print("可在页面中用 Image($r('app.media.ic_xxx')) 替换 emoji，进一步统一风格。")


if __name__ == "__main__":
    main()
