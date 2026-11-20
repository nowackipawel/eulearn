"""Generates the launcher icons from design/icon/. Run from the repo root:
    python3 tool/build_icons.py
Needs ImageMagick (`magick`). Sources: a-ribbon.png (full icon, 1024 px) and
icon-foreground.png (mark only, for Android adaptive icons)."""
import json, os, subprocess

SRC, FG, BG = 'design/icon/a-ribbon.png', 'design/icon/icon-foreground.png', '#8CC6EC'

def resize(src, px, dst, flatten=False):
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    cmd = ['magick', src, '-resize', f'{px}x{px}']
    if flatten:  # iOS rejects icons with an alpha channel
        cmd += ['-background', BG, '-alpha', 'remove', '-alpha', 'off']
    subprocess.run(cmd + [dst], check=True)

ios = 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
for img in json.load(open(f'{ios}/Contents.json'))['images']:
    px = round(float(img['size'].split('x')[0]) * int(img['scale'][0]))
    resize(SRC, px, f"{ios}/{img['filename']}", flatten=True)

res = 'android/app/src/main/res'
for name, scale in {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}.items():
    resize(SRC, round(48 * scale), f'{res}/mipmap-{name}/ic_launcher.png')
    resize(FG, round(108 * scale), f'{res}/mipmap-{name}/ic_launcher_foreground.png')
os.makedirs(f'{res}/mipmap-anydpi-v26', exist_ok=True)
open(f'{res}/mipmap-anydpi-v26/ic_launcher.xml', 'w').write(
    '<?xml version="1.0" encoding="utf-8"?>\n'
    '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
    '    <background android:drawable="@color/ic_launcher_background"/>\n'
    '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
    '</adaptive-icon>\n')
open(f'{res}/values/ic_launcher_background.xml', 'w').write(
    '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n'
    f'    <color name="ic_launcher_background">{BG}</color>\n</resources>\n')
print('icons written')
