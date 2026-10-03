# -*- coding: utf-8 -*-
"""Trích ảnh PNG 1200×1200 chất lượng cao từ SVG người dùng gửi lần 2 và dùng
làm nguồn gốc cho tất cả logo. SVG được dán tạm vào biến RAW phía dưới (dạng
chuỗi Python) — chạy script xong có thể để nguyên hoặc xoá RAW để tiết kiệm chỗ.

Chạy: python docs/extract_user_svg.py
"""
import base64
import io
import os
import re

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RAW_PATH = os.path.join(ROOT, 'docs', 'user_logo_svg.txt')  # dán SVG vào file này


def rel(p):
    return os.path.join(ROOT, p.replace('/', os.sep))


def save(img, p):
    full = rel(p)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    img.save(full)
    print('wrote %-70s %s' % (p, img.size))


def extract_biggest_png(svg_text):
    """SVG mới của Canva nhúng 2 ảnh PNG base64 — chọn ảnh lớn nhất (render đầy đủ)."""
    best = None
    best_size = 0
    for b64 in re.findall(r'data:image/png;base64,([A-Za-z0-9+/=]+)', svg_text):
        try:
            raw = base64.b64decode(b64, validate=True)
            im = Image.open(io.BytesIO(raw))
            im.load()
            if im.width * im.height > best_size:
                best = im.convert('RGBA')
                best_size = im.width * im.height
        except Exception as e:
            print('skip broken PNG:', e)
    if best is None:
        raise SystemExit('Không tìm được PNG hợp lệ trong SVG')
    print('biggest png size:', best.size)
    return best


def crop_tight(img, pad=8):
    bbox = img.getbbox()
    if bbox is None:
        return img
    l, t, r, b = bbox
    return img.crop((max(0, l - pad), max(0, t - pad), min(img.width, r + pad), min(img.height, b + pad)))


def whiten(img):
    r, g, b, a = img.split()
    w = Image.new('L', img.size, 255)
    return Image.merge('RGBA', (w, w, w, a))


# Biểu tượng J bên trái của logo đầy đủ — cắt từ ảnh lớn.
def extract_mark_from_full(full):
    # Tìm vùng không trong suốt của phần J (bên trái 20% của ảnh)
    w, h = full.size
    left_region = full.crop((0, 0, int(w * 0.22), h))
    bbox = left_region.getbbox()
    if bbox is None:
        return None
    return left_region.crop(bbox)


def compose_icon(mark, size, fullbleed=False, content_scale=1.0, bg=(255, 255, 255, 255)):
    ss = 4
    s = size * ss
    img = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    if fullbleed:
        d.rectangle([0, 0, s - 1, s - 1], fill=bg)
    else:
        d.rounded_rectangle([0, 0, s - 1, s - 1], radius=s * 14 / 64.0, fill=bg)
    target_h = int(s * 0.62 * content_scale)
    ratio = target_h / mark.height
    m = mark.resize((max(1, int(mark.width * ratio)), target_h), Image.LANCZOS)
    img.alpha_composite(m, ((s - m.width) // 2, (s - m.height) // 2))
    return img.resize((size, size), Image.LANCZOS)


def main():
    svg = open(RAW_PATH, encoding='utf-8').read()
    full = extract_biggest_png(svg)
    # Crop tight để bỏ viền trong suốt lớn
    full_tight = crop_tight(full)
    save(full_tight, 'assets/images/logo_jobhub.png')
    save(whiten(full_tight), 'assets/images/logo_jobhub_white.png')

    mark = extract_mark_from_full(full_tight)
    if mark is None:
        raise SystemExit('Không cắt được biểu tượng J từ ảnh đầy đủ')
    save(mark, 'assets/images/logo_mark@4x.png')
    save(mark.resize((max(1, mark.width // 4), max(1, mark.height // 4)), Image.LANCZOS),
         'assets/images/logo_mark.png')

    import json
    for dpi, size in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96), ('xxhdpi', 144), ('xxxhdpi', 192)]:
        save(compose_icon(mark, size), 'android/app/src/main/res/mipmap-%s/ic_launcher.png' % dpi)
        fg_size = int(size * 108 / 48)
        fg = Image.new('RGBA', (fg_size, fg_size), (0, 0, 0, 0))
        target_h = int(fg_size * 66 / 108 * 0.78)
        m = mark.resize((max(1, int(mark.width * target_h / mark.height)), target_h), Image.LANCZOS)
        fg.alpha_composite(m, ((fg_size - m.width) // 2, (fg_size - m.height) // 2))
        save(fg, 'android/app/src/main/res/mipmap-%s/ic_launcher_foreground.png' % dpi)

    save(compose_icon(mark, 32), 'web/favicon.png')
    save(compose_icon(mark, 192), 'web/icons/Icon-192.png')
    save(compose_icon(mark, 512), 'web/icons/Icon-512.png')
    save(compose_icon(mark, 192, fullbleed=True, content_scale=0.8), 'web/icons/Icon-maskable-192.png')
    save(compose_icon(mark, 512, fullbleed=True, content_scale=0.8), 'web/icons/Icon-maskable-512.png')

    cj = rel('ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json')
    with open(cj, encoding='utf-8') as f:
        contents = json.load(f)
    for entry in contents['images']:
        base = float(entry['size'].split('x')[0])
        px = int(round(base * float(entry.get('scale', '1x')[:-1])))
        save(compose_icon(mark, px, fullbleed=True), 'ios/Runner/Assets.xcassets/AppIcon.appiconset/' + entry['filename'])
    print('done.')


if __name__ == '__main__':
    main()
