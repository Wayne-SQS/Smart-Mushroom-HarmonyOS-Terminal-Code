"""
用用户提供的最新设计图替换应用图标（主体放大版）

处理：
- 原图 1254x1254 RGB
- Center crop 裁掉边缘 6%（每边 3%），让主体内容放大
- 缩放到鸿蒙标准 1024x1024
- 同步到 AppScope 和 entry 两处
"""

from PIL import Image
import os

SRC = r"d:\SoftwareAction\ChatGPT Image 2026年7月3日 20_09_33.png"
TARGET_SIZE = 1024
CROP_RATIO = 0.06  # 裁掉边缘 6%（每边 3%），主体放大约 6%

MEDIA_DIRS = [
    r"d:\SoftwareAction\entry\src\main\resources\base\media",
    r"d:\SoftwareAction\AppScope\resources\base\media",
]


def main():
    src_img = Image.open(SRC)
    print(f"原图: {src_img.size} {src_img.mode}")

    if src_img.mode != 'RGBA':
        src_img = src_img.convert('RGBA')

    w, h = src_img.size
    # Center crop：裁掉边缘，放大主体
    crop_w = int(w * CROP_RATIO)
    crop_h = int(h * CROP_RATIO)
    left = crop_w // 2
    top = crop_h // 2
    right = w - left
    bottom = h - top
    cropped = src_img.crop((left, top, right, bottom))
    print(f"裁剪后: {cropped.size} (裁掉边缘 {CROP_RATIO*100:.0f}%)")

    # 缩放到 1024x1024
    resized = cropped.resize((TARGET_SIZE, TARGET_SIZE), Image.LANCZOS)
    print(f"缩放后: {resized.size}")

    # 前景层（全透明）
    transparent = Image.new('RGBA', (TARGET_SIZE, TARGET_SIZE), (0, 0, 0, 0))

    for media_dir in MEDIA_DIRS:
        os.makedirs(media_dir, exist_ok=True)

        start_path = os.path.join(media_dir, "startIcon.png")
        resized.save(start_path, "PNG", optimize=True)
        print(f"  ✅ startIcon.png ({os.path.getsize(start_path):,} bytes)")

        bg_path = os.path.join(media_dir, "background.png")
        resized.save(bg_path, "PNG", optimize=True)
        print(f"  ✅ background.png ({os.path.getsize(bg_path):,} bytes)")

        fg_path = os.path.join(media_dir, "foreground.png")
        transparent.save(fg_path, "PNG", optimize=True)
        print(f"  ✅ foreground.png ({os.path.getsize(fg_path):,} bytes)")

        logo_path = os.path.join(media_dir, "logo.png")
        resized.save(logo_path, "PNG", optimize=True)
        logo_large_path = os.path.join(media_dir, "logo_large.png")
        resized.save(logo_large_path, "PNG", optimize=True)

        print(f"  --- {media_dir} 完成 ---\n")

    print("替换完成！主体已放大 6%。")


if __name__ == "__main__":
    main()
