"""
把 entry 下生成的图标同步复制到 AppScope 全局资源目录
鸿蒙桌面图标从 AppScope/resources/base/media 读取
"""
import shutil
import os

ENTRY_MEDIA = r"d:\SoftwareAction\entry\src\main\resources\base\media"
APPSCOPE_MEDIA = r"d:\SoftwareAction\AppScope\resources\base\media"

os.makedirs(APPSCOPE_MEDIA, exist_ok=True)

files_to_sync = ["background.png", "foreground.png", "startIcon.png",
                 "logo.png", "logo_large.png", "layered_image.json"]

print("同步图标资源到 AppScope 全局目录:")
for f in files_to_sync:
    src = os.path.join(ENTRY_MEDIA, f)
    dst = os.path.join(APPSCOPE_MEDIA, f)
    if os.path.exists(src):
        shutil.copy2(src, dst)
        sz = os.path.getsize(dst)
        print(f"  ✅ {f}: {sz:,} bytes")
    else:
        print(f"  ⚠️ {f}: 源文件不存在，跳过")

print("\n同步完成！")
