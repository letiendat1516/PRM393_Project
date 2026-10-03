# -*- coding: utf-8 -*-
"""Sinh icon launcher cho JobHub (Android mipmap, iOS AppIcon, web PWA).

Vẽ lại chính xác hình học của assets/icons/favicon.svg bằng PIL thuần (không cần
công cụ ngoài để rasterize SVG), supersample 4x rồi thu nhỏ bằng LANCZOS.

Hình học (viewBox 64x64):
  - nền vuông bo góc #0F4C81, bán kính 14
  - "thẻ" trắng bo góc x16..48, y22..44, bán kính 4
  - 2 gạch xanh #0F4C81: (22,28 w12 h3) và (22,34 w20 h2.5)
  - chấm tròn xanh lá #00A86B tâm (42, 29.5) r 2.6

Chạy:  python docs/gen_icons.py   (từ thư mục project)
"""
import json
import os

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

BLUE = (15, 76, 129, 255)    # #0F4C81
GREEN = (0, 168, 107, 255)   # #00A86B
WHITE = (255, 255, 255, 255)
SS = 4  # hệ số supersampling


def compose(size, fullbleed=False, content_scale=1.0):
    """Vẽ icon kích thước `size` px.

    fullbleed=False: nền vuông bo góc, 4 góc trong suốt (Android legacy, web).
    fullbleed=True : nền phủ kín cả canvas (iOS, web maskable) — nội dung thu
    theo content_scale vào vùng an toàn (maskable dùng ~0.66).
    """
    s = size * SS
    img = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    u = s / 64.0  # đơn vị viewBox -> pixel

    if fullbleed:
        d.rectangle([0, 0, s - 1, s - 1], fill=BLUE)
        k = content_scale
        off = (s - s * k) / 2.0
    else:
        k = 1.0
        off = 0.0
        d.rounded_rectangle([0, 0, s - 1, s - 1], radius=14 * u, fill=BLUE)

    cu = u * k

    def px(x):
        return off + x * cu

    # thẻ trắng
    d.rounded_rectangle([px(16), px(22), px(48), px(44)], radius=4 * cu, fill=WHITE)
    # 2 gạch xanh
    d.rectangle([px(22), px(28), px(34), px(31)], fill=BLUE)
    d.rectangle([px(22), px(34), px(42), px(36.5)], fill=BLUE)
    # chấm xanh lá
    cx, cy, r = px(42), px(29.5), 2.6 * cu
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=GREEN)

    return img.resize((size, size), Image.LANCZOS)


def save(img, rel):
    path = os.path.join(ROOT, rel.replace('/', os.sep))
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path)
    print('wrote %-70s %s' % (rel, img.size))


def main():
    # ---- Android mipmap (legacy launcher icon, bo góc trong suốt) ----
    for dpi, size in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96),
                      ('xxhdpi', 144), ('xxxhdpi', 192)]:
        save(compose(size),
             'android/app/src/main/res/mipmap-%s/ic_launcher.png' % dpi)

    # ---- Web: favicon + PWA icons (maskable thu nội dung vào vùng an toàn) ----
    save(compose(32), 'web/favicon.png')
    save(compose(192), 'web/icons/Icon-192.png')
    save(compose(512), 'web/icons/Icon-512.png')
    save(compose(192, fullbleed=True, content_scale=0.66), 'web/icons/Icon-maskable-192.png')
    save(compose(512, fullbleed=True, content_scale=0.66), 'web/icons/Icon-maskable-512.png')

    # ---- iOS: phủ kín cả ô (hệ thống tự bo góc), nội dung giữ vị trí gốc ----
    cj_path = os.path.join(ROOT, 'ios', 'Runner', 'Assets.xcassets',
                           'AppIcon.appiconset', 'Contents.json')
    with open(cj_path, encoding='utf-8') as f:
        contents = json.load(f)
    for entry in contents['images']:
        size_str, scale = entry['size'], entry.get('scale', '1x')
        base = float(size_str.split('x')[0])
        px_size = int(round(base * float(scale[:-1])))
        save(compose(px_size, fullbleed=True, content_scale=1.0),
             'ios/Runner/Assets.xcassets/AppIcon.appiconset/' + entry['filename'])

    print('done.')


if __name__ == '__main__':
    main()
