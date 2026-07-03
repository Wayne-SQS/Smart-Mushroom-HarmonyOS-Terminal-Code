"""读取用户提供的图标设计图信息"""
from PIL import Image

src = r"d:\SoftwareAction\ChatGPT Image 2026年7月3日 20_07_14.png"
img = Image.open(src)
print(f"尺寸: {img.size}")
print(f"模式: {img.mode}")  # RGBA=有透明通道, RGB=无
print(f"格式: {img.format}")

if img.mode == 'RGBA':
    # 检查四个角的透明度，判断是否有透明背景
    w, h = img.size
    corners = [
        img.getpixel((0, 0)),
        img.getpixel((w - 1, 0)),
        img.getpixel((0, h - 1)),
        img.getpixel((w - 1, h - 1)),
    ]
    print(f"四角像素 (RGBA): {corners}")
    transparent_corners = sum(1 for c in corners if len(c) == 4 and c[3] < 128)
    print(f"透明角数: {transparent_corners}/4")
else:
    print("无透明通道（RGB 模式，完整不透明图）")
