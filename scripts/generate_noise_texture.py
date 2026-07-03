"""
生成 Header 噪点纹理 PNG - 用于鸿蒙 App 深棕色 Header 叠加磨砂质感

设计：
  - 尺寸 720 x 360 px（覆盖手机 Header 区域，宽屏可拉伸）
  - 完全透明背景 (0,0,0,0)
  - 随机分布的 1px 白色噪点 (255,255,255)，密度约 8%
  - 每个白点 alpha 随机在 10-40 之间（极淡，避免过亮）
  - 纯随机白点，无描边、无其他颜色

可重复执行：固定 random seed，每次生成结果一致
"""

import os
import random
from PIL import Image

OUTPUT_DIR = r"d:\SoftwareAction\entry\src\main\resources\base\media"
OUTPUT_FILE = os.path.join(OUTPUT_DIR, "noise_header_texture.png")

# ==================== 噪点参数 ====================
WIDTH = 720
HEIGHT = 360
NOISE_DENSITY = 0.08          # 8% 像素为白点
ALPHA_MIN = 10                # 白点 alpha 下限（极淡）
ALPHA_MAX = 40                # 白点 alpha 上限
WHITE_RGB = (255, 255, 255)
TRANSPARENT = (0, 0, 0, 0)
SEED = 20260703               # 固定种子，保证可重复执行


def generate_noise_texture():
    """生成 720x360 透明背景 + 8% 极淡白点噪点纹理"""
    random.seed(SEED)

    # 用 bytearray 直接构造 RGBA 像素数据，比 putpixel 快得多
    total_pixels = WIDTH * HEIGHT
    buf = bytearray(total_pixels * 4)

    # 默认全透明 (0,0,0,0)，bytearray 初始即为全 0，无需额外填充

    # 对每个像素按 8% 概率置为白点，alpha 随机 10-40
    for i in range(total_pixels):
        if random.random() < NOISE_DENSITY:
            alpha = random.randint(ALPHA_MIN, ALPHA_MAX)
            offset = i * 4
            buf[offset] = WHITE_RGB[0]      # R
            buf[offset + 1] = WHITE_RGB[1]  # G
            buf[offset + 2] = WHITE_RGB[2]  # B
            buf[offset + 3] = alpha          # A

    img = Image.frombytes('RGBA', (WIDTH, HEIGHT), bytes(buf))
    return img


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    print("=" * 60)
    print("生成 Header 噪点纹理（磨砂质感叠加层）")
    print("=" * 60)

    img = generate_noise_texture()
    img.save(OUTPUT_FILE, "PNG", optimize=True)

    # 统计实际白点数（验证密度）
    px = img.load()
    white_count = 0
    alpha_sum = 0
    for y in range(HEIGHT):
        for x in range(WIDTH):
            r, g, b, a = px[x, y]
            if r == 255 and g == 255 and b == 255 and a > 0:
                white_count += 1
                alpha_sum += a
    total = WIDTH * HEIGHT
    density = white_count / total * 100
    avg_alpha = alpha_sum / white_count if white_count else 0

    print(f"\n✅ 已生成：{OUTPUT_FILE}")
    print(f"   尺寸       : {WIDTH} x {HEIGHT} px")
    print(f"   总像素     : {total}")
    print(f"   白点数     : {white_count}")
    print(f"   实际密度   : {density:.2f}%（目标 8%）")
    print(f"   平均 alpha : {avg_alpha:.2f}（范围 {ALPHA_MIN}-{ALPHA_MAX}）")
    print(f"   背景       : 完全透明 (0,0,0,0)")
    print(f"   种子       : {SEED}（可重复执行结果一致）")


if __name__ == "__main__":
    main()
