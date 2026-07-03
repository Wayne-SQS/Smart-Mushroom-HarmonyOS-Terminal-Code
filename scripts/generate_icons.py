"""
生成鸿蒙应用图标 - 蘑菇大棚 IoT 管理系统
遵循 HarmonyOS 图标设计规范：圆角适配 + 安全区 + 分层结构

尺寸说明：
- 标准图标：1024x1024（系统自动适配各分辨率）
- 分层图标：background.png (背景) + foreground.png (前景内容)
- 启动图标：startIcon.png (完整合成图)
"""

from PIL import Image, ImageDraw, ImageFilter
import os
import math

OUTPUT_DIR = r"d:\SoftwareAction\entry\src\main\resources\base\media"
SIZE = 1024

# ==================== 颜色方案（来自设计方案 + ThemeTokens） ====================
# 柔和米色背景
BG_BEIGE_TOP = (255, 243, 224)      # 米色渐变上
BG_BEIGE_BOTTOM = (250, 232, 205)   # 米色渐变下

# 蘑菇配色（棕色系，像素感）
MUSHROOM_CAP_DARK = (139, 90, 43)
MUSHROOM_CAP = (176, 122, 62)
MUSHROOM_CAP_LIGHT = (205, 155, 95)
MUSHROOM_CAP_HIGHLIGHT = (230, 190, 140)
MUSHROOM_STEM = (245, 230, 205)
MUSHROOM_STEM_SHADOW = (220, 200, 170)
MUSHROOM_SPOT = (255, 245, 225)

# 大棚结构（玻璃温室）
GREENHOUSE_FRAME = (120, 140, 160)
GREENHOUSE_GLASS = (220, 235, 245)
GREENHOUSE_GLASS_LIGHT = (235, 245, 250)
GREENHOUSE_BASE = (100, 120, 140)

# 土壤与草地
SOIL_DARK = (90, 65, 40)
SOIL = (120, 88, 55)
GRASS_DARK = (80, 140, 70)
GRASS = (110, 175, 90)
GRASS_LIGHT = (145, 200, 115)

# 智能控制设备
DEVICE_BODY = (240, 240, 245)
DEVICE_SCREEN = (70, 140, 180)
DEVICE_SCREEN_LIGHT = (120, 190, 220)
WIFI_DARK = (60, 70, 80)
WIFI_GREEN = (90, 190, 110)

# 云朵
CLOUD = (255, 255, 255)
CLOUD_SHADOW = (230, 235, 240)

# 装饰星星
STAR = (255, 255, 200)
STAR_LIGHT = (255, 255, 230)


def draw_pixel_rect(draw, x, y, w, h, color):
    """绘制像素风格矩形"""
    if w <= 0 or h <= 0:
        return
    x0 = int(x)
    y0 = int(y)
    x1 = x0 + int(w) - 1
    y1 = y0 + int(h) - 1
    if x1 < x0:
        return
    draw.rectangle([x0, y0, x1, y1], fill=color)


def draw_pixel_circle(draw, cx, cy, r, color):
    """绘制像素风格圆（用近似方式）"""
    for angle in range(0, 360, 2):
        rad = math.radians(angle)
        x = int(cx + r * math.cos(rad))
        y = int(cy + r * math.sin(rad))
        draw.rectangle([x - 1, y - 1, x + 1, y + 1], fill=color)
    # 填充内部
    for dy in range(-r, r + 1, 2):
        dx = int(math.sqrt(max(0, r * r - dy * dy)))
        draw.rectangle([cx - dx, cy + dy, cx + dx, cy + dy + 1], fill=color)


def draw_mushroom(draw, cx, base_y, scale=1.0):
    """绘制像素风格蘑菇（一个大蘑菇 + 阴影）"""
    s = int(scale)
    cap_w = int(160 * scale)
    cap_h = int(90 * scale)
    stem_w = int(70 * scale)
    stem_h = int(100 * scale)

    # 阴影
    shadow_y = base_y + 4
    draw.ellipse([cx - cap_w // 2 + 10, shadow_y,
                  cx + cap_w // 2 - 10, shadow_y + int(18 * scale)],
                 fill=(0, 0, 0, 40))

    # 茎
    stem_top = base_y - stem_h
    stem_left = cx - stem_w // 2
    stem_right = cx + stem_w // 2

    # 茎主体
    draw_pixel_rect(draw, stem_left, stem_top, stem_w, stem_h, MUSHROOM_STEM)
    # 茎左侧阴影
    draw_pixel_rect(draw, stem_left, stem_top, int(10 * scale), stem_h, MUSHROOM_STEM_SHADOW)
    # 茎右侧高光
    draw_pixel_rect(draw, stem_right - int(12 * scale), stem_top + int(10 * scale),
                    int(8 * scale), stem_h - int(20 * scale), (252, 242, 222))

    # 菌盖（半圆形，像素化）
    cap_top = stem_top - cap_h + int(25 * scale)
    cap_bottom = stem_top + int(20 * scale)

    # 主菌盖颜色
    r_horizontal = cap_w // 2
    r_vertical = cap_h
    for dy in range(0, cap_h):
        ratio = 1.0 - (dy / cap_h)
        if ratio < 0:
            ratio = 0
        cur_w = int(r_horizontal * math.sqrt(ratio))
        y = cap_top + dy
        left = cx - cur_w
        right = cx + cur_w
        # 颜色层次
        if dy < int(cap_h * 0.25):
            c = MUSHROOM_CAP_HIGHLIGHT
        elif dy < int(cap_h * 0.55):
            c = MUSHROOM_CAP_LIGHT
        elif dy < int(cap_h * 0.8):
            c = MUSHROOM_CAP
        else:
            c = MUSHROOM_CAP_DARK
        draw_pixel_rect(draw, left, y, right - left, 2, c)

    # 菌盖底部深色边
    draw_pixel_rect(draw, cx - cap_w // 2 + int(10 * scale), cap_bottom - int(4 * scale),
                    cap_w - int(20 * scale), int(8 * scale), MUSHROOM_CAP_DARK)

    # 菌盖斑点（白色方块）
    spots = [
        (-int(40 * scale), -int(10 * scale), int(16 * scale)),
        (int(30 * scale), -int(20 * scale), int(14 * scale)),
        (-int(10 * scale), -int(40 * scale), int(12 * scale)),
        (int(50 * scale), int(5 * scale), int(10 * scale)),
    ]
    for sx, sy, sw in spots:
        px = cx + sx
        py = cap_top + cap_h // 2 + sy
        draw_pixel_rect(draw, px, py, sw, int(sw * 0.7), MUSHROOM_SPOT)
        # 斑点高光
        draw_pixel_rect(draw, px, py, int(sw * 0.4), int(sw * 0.3), (255, 255, 245))


def draw_small_mushroom(draw, cx, base_y, scale=0.5):
    """绘制小蘑菇"""
    draw_mushroom(draw, cx, base_y, scale)


def draw_greenhouse(draw, cx, cy, w, h):
    """绘制温室大棚（拱形玻璃结构）"""
    # 大棚底部基座
    base_h = int(h * 0.15)
    draw_pixel_rect(draw, cx - w // 2, cy + h // 2 - base_h, w, base_h, GREENHOUSE_BASE)

    # 拱形顶部（半圆形框架）
    arch_r = w // 2
    arch_top = cy - h // 2 + base_h

    # 填充玻璃（渐变浅色）
    steps = 40
    for i in range(steps):
        ratio = i / steps
        angle = math.pi * ratio  # 0 to PI (上半圆)
        cur_w_left = int(arch_r * math.cos(angle))
        x1 = cx - cur_w_left
        x2 = cx + cur_w_left
        y = int(arch_top + arch_r - arch_r * math.sin(angle))
        if i < steps - 1:
            ratio_next = (i + 1) / steps
            angle_next = math.pi * ratio_next
            y_next = int(arch_top + arch_r - arch_r * math.sin(angle_next))
            h_rect = max(2, y_next - y)
        else:
            h_rect = 2
        w_rect = x2 - x1
        # 玻璃颜色渐变：上浅下深
        t = ratio
        if t < 0.4:
            glass = GREENHOUSE_GLASS_LIGHT
        elif t < 0.75:
            glass = GREENHOUSE_GLASS
        else:
            glass = (205, 222, 235)
        draw_pixel_rect(draw, x1, y, w_rect, h_rect, glass)

    # 竖向框架线条
    frame_count = 5
    for i in range(frame_count + 1):
        t = i / frame_count
        angle = math.pi * t
        fx = int(cx - arch_r * math.cos(angle))
        fy_start = int(arch_top + arch_r - arch_r * math.sin(angle))
        fy_end = cy + h // 2 - base_h
        # 竖线
        px = 3 if i == 0 or i == frame_count else 2
        draw_pixel_rect(draw, fx - px // 2, fy_start, px, fy_end - fy_start, GREENHOUSE_FRAME)

    # 横向拱形框架（3道）
    for arch_idx in range(3):
        t_arch = 0.2 + arch_idx * 0.3
        r_cur = int(arch_r * (1 - t_arch * 0.2))
        y_arch = int(arch_top + arch_r - r_cur * 0.0)
        for a in range(0, 181, 2):
            rad = math.radians(a)
            x = int(cx - r_cur * math.cos(rad))
            y = int(arch_top + arch_r - r_cur * math.sin(rad))
            if y >= fy_start and y <= fy_end:
                draw_pixel_rect(draw, x - 1, y - 1, 3, 3, GREENHOUSE_FRAME)

    # 侧面墙体（左侧）
    wall_left_x = cx - w // 2
    wall_right_x = cx - w // 2 + int(w * 0.12)
    wall_top_y = arch_top + int(arch_r * 0.3)
    wall_bottom_y = cy + h // 2 - base_h
    # 左墙玻璃
    draw_pixel_rect(draw, wall_left_x + 3, wall_top_y,
                    wall_right_x - wall_left_x - 3, wall_bottom_y - wall_top_y,
                    GREENHOUSE_GLASS)
    # 左墙网格线
    grid_rows = 4
    grid_cols = 2
    for gr in range(grid_rows + 1):
        gy = wall_top_y + int((wall_bottom_y - wall_top_y) * gr / grid_rows)
        draw_pixel_rect(draw, wall_left_x + 3, gy - 1,
                        wall_right_x - wall_left_x - 3, 2, GREENHOUSE_FRAME)
    for gc in range(grid_cols + 1):
        gx = wall_left_x + 3 + int((wall_right_x - wall_left_x - 3) * gc / grid_cols)
        draw_pixel_rect(draw, gx - 1, wall_top_y,
                        2, wall_bottom_y - wall_top_y, GREENHOUSE_FRAME)

    # 顶部智能控制盒（WiFi设备）
    box_w = int(w * 0.22)
    box_h = int(h * 0.14)
    box_x = cx - box_w // 2
    box_y = arch_top - int(h * 0.02)
    # 盒子主体
    draw_pixel_rect(draw, box_x, box_y, box_w, box_h, DEVICE_BODY)
    # 盒子边框
    draw_pixel_rect(draw, box_x, box_y, box_w, 3, GREENHOUSE_FRAME)
    draw_pixel_rect(draw, box_x, box_y + box_h - 3, box_w, 3, GREENHOUSE_FRAME)
    draw_pixel_rect(draw, box_x, box_y, 3, box_h, GREENHOUSE_FRAME)
    draw_pixel_rect(draw, box_x + box_w - 3, box_y, 3, box_h, GREENHOUSE_FRAME)
    # WiFi 标志（弧形线）
    wifi_cx = cx
    wifi_cy = box_y + box_h // 2 - int(box_h * 0.05)
    wifi_colors = [WIFI_DARK, WIFI_DARK, WIFI_DARK, WIFI_GREEN]
    for wi, radius in enumerate([int(box_h * 0.15), int(box_h * 0.28), int(box_h * 0.4), int(box_h * 0.52)]):
        for a in range(210, 331, 3):
            rad = math.radians(a)
            x = int(wifi_cx + radius * math.cos(rad))
            y = int(wifi_cy + radius * math.sin(rad))
            col = wifi_colors[wi]
            draw_pixel_rect(draw, x - 1, y - 1, 3, 3, col)
    # WiFi 中心圆点（绿色状态灯）
    draw_pixel_circle(draw, wifi_cx, wifi_cy + 2, 3, WIFI_GREEN)


def draw_controller_device(draw, x, y, w, h):
    """绘制右侧智能控制终端"""
    # 设备主体
    draw_pixel_rect(draw, x, y, w, h, DEVICE_BODY)
    # 设备边框
    border_c = (180, 190, 200)
    draw_pixel_rect(draw, x, y, w, 4, border_c)
    draw_pixel_rect(draw, x, y + h - 4, w, 4, border_c)
    draw_pixel_rect(draw, x, y, 4, h, border_c)
    draw_pixel_rect(draw, x + w - 4, y, 4, h, border_c)

    # 屏幕区域
    screen_pad_x = int(w * 0.15)
    screen_pad_y = int(h * 0.18)
    screen_w = w - screen_pad_x * 2
    screen_h = int(h * 0.4)
    # 屏幕背景
    draw_pixel_rect(draw, x + screen_pad_x, y + screen_pad_y, screen_w, screen_h, DEVICE_SCREEN)
    # 屏幕边框
    draw_pixel_rect(draw, x + screen_pad_x - 2, y + screen_pad_y - 2,
                    screen_w + 4, screen_h + 4, (50, 60, 70))
    # 屏幕内容（模拟数据条）
    bar_count = 3
    bar_gap = int(screen_w * 0.12)
    bar_w = int((screen_w - bar_gap * (bar_count + 1)) / bar_count)
    for bi in range(bar_count):
        bx = x + screen_pad_x + bar_gap + bi * (bar_w + bar_gap)
        bh_max = int(screen_h * 0.7)
        bh = int(bh_max * (0.5 + 0.25 * bi))
        by = y + screen_pad_y + screen_h - bh - int(screen_h * 0.1)
        draw_pixel_rect(draw, bx, by, bar_w, bh, DEVICE_SCREEN_LIGHT)
    # 屏幕顶部数据标签
    draw_pixel_rect(draw, x + screen_pad_x + int(screen_w * 0.1),
                    y + screen_pad_y + int(screen_h * 0.08),
                    int(screen_w * 0.35), int(screen_h * 0.08), (255, 255, 255))

    # 按钮区
    btn_y = y + screen_pad_y + screen_h + int(h * 0.12)
    btn_h = int(h * 0.12)
    # 绿色确认按钮
    btn_green_x = x + int(w * 0.2)
    btn_w = int(w * 0.28)
    draw_pixel_rect(draw, btn_green_x, btn_y, btn_w, btn_h, (90, 180, 110))
    draw_pixel_rect(draw, btn_green_x, btn_y, btn_w, 3, (60, 150, 80))
    # 红色取消按钮
    btn_red_x = x + w - int(w * 0.2) - btn_w
    draw_pixel_rect(draw, btn_red_x, btn_y, btn_w, btn_h, (220, 120, 120))
    draw_pixel_rect(draw, btn_red_x, btn_y, btn_w, 3, (190, 90, 90))


def draw_cloud(draw, cx, cy, scale=1.0):
    """绘制像素风格云朵"""
    parts = [
        (-int(50 * scale), int(8 * scale), int(40 * scale)),
        (-int(20 * scale), -int(8 * scale), int(48 * scale)),
        (int(18 * scale), int(2 * scale), int(44 * scale)),
        (int(45 * scale), int(12 * scale), int(30 * scale)),
    ]
    # 阴影
    for dx, dy, r in parts:
        draw_pixel_circle(draw, cx + dx + 3, cy + dy + r - 2, int(r * 0.3), CLOUD_SHADOW)
    # 主体
    for dx, dy, r in parts:
        draw_pixel_circle(draw, cx + dx, cy + dy, r, CLOUD)


def draw_star(draw, cx, cy, size=8):
    """绘制像素星星（十字闪光）"""
    half = size // 2
    # 横
    draw_pixel_rect(draw, cx - half, cy - 1, size, 3, STAR)
    # 竖
    draw_pixel_rect(draw, cx - 1, cy - half, 3, size, STAR)
    # 中心高光
    draw_pixel_rect(draw, cx - 2, cy - 2, 5, 5, STAR_LIGHT)
    # 斜角点
    draw_pixel_rect(draw, cx - half + 1, cy - half + 1, 2, 2, STAR)
    draw_pixel_rect(draw, cx + half - 3, cy - half + 1, 2, 2, STAR)
    draw_pixel_rect(draw, cx - half + 1, cy + half - 3, 2, 2, STAR)
    draw_pixel_rect(draw, cx + half - 3, cy + half - 3, 2, 2, STAR)


def draw_grass_patch(draw, cx, cy, w, scale=1.0):
    """绘制像素草地簇"""
    blades = [
        (-int(10 * scale), -int(15 * scale), int(6 * scale), int(20 * scale)),
        (0, -int(22 * scale), int(7 * scale), int(28 * scale)),
        (int(10 * scale), -int(12 * scale), int(6 * scale), int(17 * scale)),
        (-int(4 * scale), -int(18 * scale), int(5 * scale), int(23 * scale)),
        (int(5 * scale), -int(20 * scale), int(5 * scale), int(25 * scale)),
    ]
    for bx, by, bw, bh in blades:
        # 深色底
        draw_pixel_rect(draw, cx + bx, cy + by, bw, bh, GRASS_DARK)
        # 浅色高光
        draw_pixel_rect(draw, cx + bx + 1, cy + by + 2, 1, bh - 4, GRASS_LIGHT)
        # 中层色
        draw_pixel_rect(draw, cx + bx + 2, cy + by + 1, bw - 3, bh - 2, GRASS)


def draw_soil_layer(draw, width, height, soil_top_y):
    """绘制土壤层（分层像素）"""
    # 主土层
    draw_pixel_rect(draw, 0, soil_top_y, width, height - soil_top_y, SOIL)
    # 顶部深色线
    draw_pixel_rect(draw, 0, soil_top_y, width, 6, SOIL_DARK)
    # 土粒纹理（随机像素点）
    particles = [
        (0.08, 0.05, 4), (0.15, 0.12, 3), (0.22, 0.08, 5),
        (0.30, 0.18, 3), (0.38, 0.03, 4), (0.45, 0.22, 3),
        (0.52, 0.10, 5), (0.60, 0.15, 3), (0.68, 0.06, 4),
        (0.75, 0.20, 3), (0.82, 0.11, 4), (0.90, 0.04, 3),
        (0.95, 0.17, 4),
    ]
    for px, py, ps in particles:
        x = int(width * px)
        y = soil_top_y + int((height - soil_top_y) * py)
        draw_pixel_rect(draw, x, y, ps, ps, SOIL_DARK)
        # 浅色亮粒
        draw_pixel_rect(draw, x + ps, y + 1, 2, 2, (150, 115, 80))


def generate_beige_gradient_bg(size):
    """生成柔和米色渐变背景（用于background层）"""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 垂直渐变米色
    for y in range(size):
        t = y / size
        r = int(BG_BEIGE_TOP[0] * (1 - t) + BG_BEIGE_BOTTOM[0] * t)
        g = int(BG_BEIGE_TOP[1] * (1 - t) + BG_BEIGE_BOTTOM[1] * t)
        b = int(BG_BEIGE_TOP[2] * (1 - t) + BG_BEIGE_BOTTOM[2] * t)
        draw.line([(0, y), (size, y)], fill=(r, g, b, 255))

    return img


def generate_foreground(size):
    """生成前景层 - 核心内容（蘑菇 + 大棚 + 智能设备）"""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    cx = size // 2
    cy = size // 2

    # 安全区内边距（鸿蒙规范：外边距约10%，安全区核心约90%）
    margin = int(size * 0.08)
    content_w = size - margin * 2
    content_h = size - margin * 2

    # ---------- 云朵（装饰，顶部两侧） ----------
    draw_cloud(draw, cx - int(content_w * 0.32), cy - int(content_h * 0.38), scale=size / 1800)
    draw_cloud(draw, cx + int(content_w * 0.30), cy - int(content_h * 0.34), scale=size / 2200)
    draw_cloud(draw, cx - int(content_w * 0.02), cy - int(content_h * 0.42), scale=size / 2500)

    # ---------- 星星闪光装饰 ----------
    stars_pos = [
        (0.18, 0.22), (0.80, 0.18), (0.42, 0.15),
        (0.10, 0.55), (0.88, 0.48), (0.25, 0.38),
    ]
    for sx, sy in stars_pos:
        draw_star(draw, int(size * sx), int(size * sy), size=max(6, int(size * 0.012)))

    # ---------- 温室大棚 ----------
    gh_w = int(content_w * 0.92)
    gh_h = int(content_h * 0.62)
    gh_cx = cx
    gh_cy = cy + int(content_h * 0.04)
    draw_greenhouse(draw, gh_cx, gh_cy, gh_w, gh_h)

    # ---------- 土壤层 ----------
    soil_top_y = gh_cy + gh_h // 2 - int(size * 0.03)
    draw_soil_layer(draw, size, size, soil_top_y)

    # ---------- 智能控制终端（大棚右侧） ----------
    ctrl_w = int(content_w * 0.11)
    ctrl_h = int(content_h * 0.28)
    ctrl_x = gh_cx + gh_w // 2 - int(ctrl_w * 0.55)
    ctrl_y = soil_top_y - ctrl_h - int(size * 0.01)
    draw_controller_device(draw, ctrl_x, ctrl_y, ctrl_w, ctrl_h)
    # 设备支架
    stand_w = int(ctrl_w * 0.18)
    draw_pixel_rect(draw, ctrl_x + ctrl_w // 2 - stand_w // 2, ctrl_y + ctrl_h,
                    stand_w, soil_top_y - (ctrl_y + ctrl_h), GREENHOUSE_FRAME)

    # ---------- 蘑菇群（大棚内部中央） ----------
    mush_base_y = soil_top_y - int(size * 0.01)
    # 大蘑菇（中心）
    draw_mushroom(draw, cx, mush_base_y, scale=size / 820)
    # 左中蘑菇
    draw_small_mushroom(draw, cx - int(size * 0.14), mush_base_y - int(size * 0.01), scale=size / 1500)
    # 右中蘑菇
    draw_small_mushroom(draw, cx + int(size * 0.13), mush_base_y - int(size * 0.005), scale=size / 1600)
    # 最小的前景蘑菇（左前）
    draw_small_mushroom(draw, cx - int(size * 0.05), mush_base_y + int(size * 0.005), scale=size / 2800)
    # 最小的前景蘑菇（右前）
    draw_small_mushroom(draw, cx + int(size * 0.08), mush_base_y + int(size * 0.008), scale=size / 3000)

    # ---------- 草地簇（土壤层边缘装饰） ----------
    grass_spots = [
        (0.12, 0.02, 1.0),
        (0.20, 0.01, 0.8),
        (0.80, 0.015, 0.9),
        (0.88, 0.025, 1.1),
    ]
    for gx, gy, gs in grass_spots:
        draw_grass_patch(draw, int(size * gx), soil_top_y + int(size * gy),
                         int(size * 0.05), scale=size / 1400 * gs)

    return img


def generate_start_icon(size):
    """生成启动页完整图标（背景 + 前景合成）"""
    bg = generate_beige_gradient_bg(size)
    fg = generate_foreground(size)
    result = Image.alpha_composite(bg, fg)

    # 添加整体柔和像素化效果（不做过度模糊，保持像素风）
    # 先稍作锐化保持边缘清晰
    from PIL import ImageFilter
    result = result.filter(ImageFilter.SMOOTH)

    return result


def save_all_sizes(base_img, output_dir, name_base):
    """保存多尺寸版本"""
    # 鸿蒙标准尺寸列表
    sizes = [
        (1024, ""),       # 标准
        (512, "_512"),
        (256, "_256"),
        (192, "_192"),
        (128, "_128"),
        (96, "_96"),
        (72, "_72"),
        (64, "_64"),
        (48, "_48"),
    ]
    paths = []
    for sz, suffix in sizes:
        resized = base_img.resize((sz, sz), Image.LANCZOS)
        path = os.path.join(output_dir, f"{name_base}{suffix}.png")
        resized.save(path, "PNG", optimize=True)
        paths.append(path)
        print(f"  已生成: {sz}x{sz} -> {os.path.basename(path)}")
    return paths


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    print("=" * 60)
    print("生成鸿蒙应用图标 - 蘑菇大棚 IoT 管理系统")
    print("=" * 60)

    # 1. 生成背景层 (background.png) - 1024x1024
    print("\n[1/4] 生成背景层 background.png (柔和米色渐变)...")
    bg_img = generate_beige_gradient_bg(SIZE)
    bg_path = os.path.join(OUTPUT_DIR, "background.png")
    bg_img.save(bg_path, "PNG", optimize=True)
    print(f"  已保存: {bg_path}")
    save_all_sizes(bg_img, OUTPUT_DIR, "background_extra")

    # 2. 生成前景层 (foreground.png) - 1024x1024
    print("\n[2/4] 生成前景层 foreground.png (核心内容像素绘制)...")
    fg_img = generate_foreground(SIZE)
    fg_path = os.path.join(OUTPUT_DIR, "foreground.png")
    fg_img.save(fg_path, "PNG", optimize=True)
    print(f"  已保存: {fg_path}")
    save_all_sizes(fg_img, OUTPUT_DIR, "foreground_extra")

    # 3. 生成启动页图标 (startIcon.png) - 1024x1024
    print("\n[3/4] 生成启动页图标 startIcon.png (完整合成)...")
    start_img = generate_start_icon(SIZE)
    start_path = os.path.join(OUTPUT_DIR, "startIcon.png")
    start_img.save(start_path, "PNG", optimize=True)
    print(f"  已保存: {start_path}")
    save_all_sizes(start_img, OUTPUT_DIR, "startIcon_extra")

    # 4. 同时生成 logo_large 备用（如果 module.json5 引用）
    print("\n[4/4] 生成兼容备用图标 logo.png / logo_large.png...")
    logo_path = os.path.join(OUTPUT_DIR, "logo.png")
    logo_large_path = os.path.join(OUTPUT_DIR, "logo_large.png")
    start_img_512 = start_img.resize((512, 512), Image.LANCZOS)
    start_img.save(logo_large_path, "PNG", optimize=True)
    start_img_512.save(logo_path, "PNG", optimize=True)
    print(f"  已保存: {logo_large_path}")
    print(f"  已保存: {logo_path}")

    print("\n" + "=" * 60)
    print("图标生成完成！所有资源已保存到:")
    print(f"  {OUTPUT_DIR}")
    print("=" * 60)

    # 验证生成的文件
    print("\n验证生成的核心文件:")
    required = ["background.png", "foreground.png", "startIcon.png",
                "layered_image.json"]
    for f in required:
        fp = os.path.join(OUTPUT_DIR, f)
        exists = os.path.exists(fp)
        sz = os.path.getsize(fp) if exists else 0
        status = "✅" if exists else "❌"
        print(f"  {status} {f}: {sz:,} bytes")


if __name__ == "__main__":
    main()
