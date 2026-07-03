"""
用用户提供的完整设计图替换应用图标

处理策略：
- 原图是 RGB 完整不透明设计图（1254x1254）
- 缩放到鸿蒙标准 1024x1024
- startIcon.png = 完整图（启动页用）
- layered_image 分层图标：
    background.png = 完整图（作为背景层，桌面显示整张图）
    foreground.png = 1024x1024 全透明（前景层留空，不遮挡背景）
- 同步到 AppScope 和 entry 两处
"""

from PIL import Image
import shutil
import os

SRC = r"d:\SoftwareAction\ChatGPT Image 2026年7月3日 20_07_14.png"
TARGET_SIZE = 1024

# 需要同步的两个 media 目录
MEDIA_DIRS = [
    r"d:\SoftwareAction\entry\src\main\resources\base\media",
    r"d:\SoftwareAction\AppScope\resources\base\media",
]


def main():
    # 1. 读取原图并缩放到 1024x1024
    src_img = Image.open(SRC)
    print(f"原图: {src_img.size} {src_img.mode}")

    # 转为 RGBA，缩放
    if src_img.mode != 'RGBA':
        src_img = src_img.convert('RGBA')
    resized = src_img.resize((TARGET_SIZE, TARGET_SIZE), Image.LANCZOS)
    print(f"缩放后: {resized.size}")

    # 2. 生成前景层（全透明 1024x1024）
    transparent = Image.new('RGBA', (TARGET_SIZE, TARGET_SIZE), (0, 0, 0, 0))

    # 3. 写入两个目录
    for media_dir in MEDIA_DIRS:
        os.makedirs(media_dir, exist_ok=True)

        # startIcon.png = 完整图
        start_path = os.path.join(media_dir, "startIcon.png")
        resized.save(start_path, "PNG", optimize=True)
        print(f"  ✅ {start_path} ({os.path.getsize(start_path):,} bytes)")

        # background.png = 完整图（分层背景层）
        bg_path = os.path.join(media_dir, "background.png")
        resized.save(bg_path, "PNG", optimize=True)
        print(f"  ✅ {bg_path} ({os.path.getsize(bg_path):,} bytes)")

        # foreground.png = 全透明（前景层不遮挡背景）
        fg_path = os.path.join(media_dir, "foreground.png")
        transparent.save(fg_path, "PNG", optimize=True)
        print(f"  ✅ {fg_path} ({os.path.getsize(fg_path):,} bytes)")

        # logo / logo_large 备用也同步
        logo_path = os.path.join(media_dir, "logo.png")
        resized.save(logo_path, "PNG", optimize=True)
        logo_large_path = os.path.join(media_dir, "logo_large.png")
        resized.save(logo_large_path, "PNG", optimize=True)

        print(f"  --- {media_dir} 完成 ---\n")

    print("替换完成！桌面图标现在显示用户提供的完整设计图。")


if __name__ == "__main__":
    main()
