# -*- coding: utf-8 -*-
"""Sinh toàn bộ asset thương hiệu JobHub từ assets/icons/logo_jobhub.svg (logo Canva).

Bước:
 1. Tách ảnh PNG màu nhúng trong SVG (biểu tượng chữ J, nền đen) → tạo bản RGBA
    (alpha suy từ độ sáng so với nền đen) → assets/images/logo_mark.png.
 2. Ghi lại SVG: thay cặp mask+filter (không tương thích flutter_svg, và mask gốc
    bị hỏng khi dán) bằng chính ảnh RGBA đó.
 3. Render SVG bằng Chrome headless (nền trong suốt) → cắt sát viền →
    assets/images/logo_jobhub.png (+ bản trắng logo_jobhub_white.png cho nền xanh).
 4. Icon launcher: nền trắng bo góc + biểu tượng J ở giữa → Android mipmap,
    web favicon/PWA icons (maskable), iOS AppIcon theo Contents.json.

Chạy:  python docs/gen_logo_assets.py   (từ thư mục project, cần Chrome + Pillow)
"""
import base64
import io
import json
import os
import re
import subprocess
import tempfile

from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SVG = os.path.join(ROOT, 'assets', 'icons', 'logo_jobhub.svg')
CHROME = r'C:\Program Files\Google\Chrome\Application\chrome.exe'
WHITE = (255, 255, 255, 255)


def rel(path):
    return os.path.join(ROOT, path.replace('/', os.sep))


def save(img, path):
    p = rel(path)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    img.save(p)
    print('wrote %-70s %s' % (path, img.size))


# ── 1. biểu tượng J (RGBA) ──────────────────────────────────────────────────
def extract_mark(svg_text):
    imgs = re.findall(r'data:image/png;base64,([A-Za-z0-9+/=]+)', svg_text)
    color_b64 = None
    for b in imgs:
        try:
            im = Image.open(io.BytesIO(base64.b64decode(b))).convert('RGB')
            im.load()
            color_b64 = b
            color = im
        except Exception:
            continue  # mask xám hỏng → bỏ qua
    if color_b64 is None:
        raise SystemExit('Không tìm thấy ảnh PNG hợp lệ trong SVG')
    w, h = color.size
    out = Image.new('RGBA', (w, h))
    src = color.load()
    dst = out.load()
    for y in range(h):
        for x in range(w):
            r, g, b = src[x, y]
            m = max(r, g, b)
            a = min(1.0, m / 40.0)          # nền đen → alpha 0; màu → đục
            if a <= 0:
                dst[x, y] = (0, 0, 0, 0)
                continue
            # un-premultiply (viền pha với nền đen) để không bị viền tối trên nền sáng
            k = 1.0 / a
            dst[x, y] = (min(255, int(r * k)), min(255, int(g * k)), min(255, int(b * k)), int(a * 255))
    return out


# ── 1b. làm sạch biểu tượng (ảnh gốc 113×188 bị nén: răng cưa + lốm đốm) ───
UP = 8  # hệ số phóng khi làm sạch


def _is_teal(rgb):
    r, g, b = rgb
    return g > 120 and (g + b) / 2.0 - r > 80


def clean_mark(mark):
    """Mịn hoá biểu tượng chữ J (ảnh gốc 113×188 bị nén cứng):

    - Giữ gradient tự nhiên 2 màu teal/navy thay vì ép ngưỡng cứng → biên dịu hơn.
    - Lọc nhiễu lốm đốm bằng median nhẹ.
    - Phóng to bằng LANCZOS + blur ~0.5 px nguồn để làm mịn răng cưa.
    - Giữ alpha gốc (không bo cứng) để chuyển tiếp mượt với nền.
    """
    w, h = mark.size
    big = (w * UP, h * UP)
    # Lọc nhiễu 1 px lốm đốm (ảnh nén lossy) trước khi phóng.
    cleaned = mark.filter(ImageFilter.MedianFilter(3))
    # Phóng to high-quality, giữ mọi kênh gradient tự nhiên.
    scaled = cleaned.resize(big, Image.LANCZOS)
    # Mịn hoá viền rất nhẹ (~0.4 px nguồn) để xoá răng cưa còn lại.
    scaled = scaled.filter(ImageFilter.GaussianBlur(UP * 0.4))
    print('mark size %sx%s → cleaned %sx%s' % (w, h, scaled.width, scaled.height))
    return scaled


def set_svg_mark(svg_text, mark_rgba, clip_x=820.0):
    """Thay dữ liệu ảnh biểu tượng trong SVG + chỉnh clip gradient bắt đầu sau chữ b."""
    buf = io.BytesIO()
    mark_rgba.save(buf, format='PNG', optimize=True)
    b64 = base64.b64encode(buf.getvalue()).decode('ascii')
    svg_text, n = re.subn(
        r'(<image x="0" y="0" width="113" height="188" preserveAspectRatio="xMidYMid meet" xlink:href="data:image/png;base64,)[A-Za-z0-9+/=]+(")',
        lambda m: m.group(1) + b64 + m.group(2), svg_text)
    if n != 1:
        raise SystemExit('Không thay được ảnh biểu tượng trong SVG (%d khớp)' % n)
    # Canva xuất clip gradient từ x=790.44 — cắt ngang bụng chữ "b" của "Job" →
    # chữ b hai màu. "b" kết thúc ở ~817, "H" bắt đầu ở ~846 → dời mép về 820.
    svg_text = svg_text.replace(
        'd="M 790.4375 0 L 790.4375 1500 L 1500 1500 L 1500 0 Z M 790.4375 0 "',
        'd="M %(x)s 0 L %(x)s 1500 L 1500 1500 L 1500 0 Z M %(x)s 0 "' % {'x': clip_x})
    svg_text = svg_text.replace(
        'd="M 790.4375 0 L 790.4375 1500 L 1500 1500 L 1500 0 Z M 790.4375 0 " fill-rule="nonzero"',
        'd="M %(x)s 0 L %(x)s 1500 L 1500 1500 L 1500 0 Z M %(x)s 0 " fill-rule="nonzero"' % {'x': clip_x})
    return svg_text


# ── 2. SVG sạch (ảnh RGBA thay cho mask+filter) ─────────────────────────────
def rewrite_svg(svg_text, mark_rgba):
    buf = io.BytesIO()
    mark_rgba.save(buf, format='PNG')
    b64 = base64.b64encode(buf.getvalue()).decode('ascii')
    # bỏ mask xám + filter luminance của nó trong <defs>
    svg_text = re.sub(r'<mask id="05e543e479">.*?</mask>', '', svg_text, flags=re.S)
    svg_text = re.sub(r'<filter x="0%" y="0%" width="100%" height="100%" id="7eac1e5048">.*?</filter>', '', svg_text, flags=re.S)
    # nhóm ảnh có mask → ảnh RGBA trực tiếp (giữ nguyên transform đặt biểu tượng)
    m = re.search(r'<g mask="url\(#05e543e479\)"><g transform="([^"]+)"><image x="0" y="0" width="113" xlink:href="data:image/png;base64,[A-Za-z0-9+/=]+" height="188" preserveAspectRatio="xMidYMid meet"/></g></g>', svg_text)
    if not m:
        raise SystemExit('Không tìm thấy nhóm ảnh biểu tượng trong SVG')
    repl = ('<g transform="%s"><image x="0" y="0" width="113" height="188" '
            'preserveAspectRatio="xMidYMid meet" xlink:href="data:image/png;base64,%s"/></g>') % (m.group(1), b64)
    return svg_text[:m.start()] + repl + svg_text[m.end():]


# ── 3. render bằng Chrome ──────────────────────────────────────────────────
def render_svg(svg_path, size=4000):
    out = os.path.join(tempfile.gettempdir(), 'jobhub_logo_render.png')
    if os.path.exists(out):
        os.remove(out)
    url = 'file:///' + svg_path.replace('\\', '/')
    subprocess.run([
        CHROME, '--headless=new', '--disable-gpu', '--no-sandbox', '--hide-scrollbars',
        '--default-background-color=00000000', '--window-size=%d,%d' % (size, size),
        '--screenshot=' + out, url,
    ], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=120)
    return Image.open(out).convert('RGBA')


def crop_tight(img, pad=8):
    bbox = img.getbbox()
    l, t, r, b = bbox
    return img.crop((max(0, l - pad), max(0, t - pad), min(img.width, r + pad), min(img.height, b + pad)))


def whiten(img):
    r, g, b, a = img.split()
    white = Image.new('L', img.size, 255)
    return Image.merge('RGBA', (white, white, white, a))


# ── 4. icon launcher ─────────────────────────────────────────────────────────
def compose_icon(mark, size, fullbleed=False, content_scale=1.0, bg=WHITE):
    ss = 4
    s = size * ss
    img = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    if fullbleed:
        d.rectangle([0, 0, s - 1, s - 1], fill=bg)
    else:
        d.rounded_rectangle([0, 0, s - 1, s - 1], radius=s * 14 / 64.0, fill=bg)
    # biểu tượng cao ~62% ô (nhân content_scale cho maskable)
    target_h = int(s * 0.62 * content_scale)
    ratio = target_h / mark.height
    m = mark.resize((max(1, int(mark.width * ratio)), target_h), Image.LANCZOS)
    img.alpha_composite(m, ((s - m.width) // 2, (s - m.height) // 2))
    return img.resize((size, size), Image.LANCZOS)


def main():
    svg_text = open(SVG, encoding='utf-8').read()
    raw_mark_path = rel('assets/images/logo_mark_raw.png')
    if os.path.exists(raw_mark_path):
        raw = Image.open(raw_mark_path).convert('RGBA')   # đã tách từ lần chạy trước
    else:
        raw = extract_mark(svg_text)
        save(raw, 'assets/images/logo_mark_raw.png')
    mark = clean_mark(raw)                                  # 904×1504, 2 màu, viền mượt
    save(mark.resize((raw.width * 4, raw.height * 4), Image.LANCZOS), 'assets/images/logo_mark@4x.png')
    save(mark.resize((raw.width, raw.height), Image.LANCZOS), 'assets/images/logo_mark.png')

    if 'mask="url(#05e543e479)"' in svg_text:
        svg_text = rewrite_svg(svg_text, raw)
    svg_text = set_svg_mark(svg_text, mark.resize((raw.width * 4, raw.height * 4), Image.LANCZOS))
    open(SVG, 'w', encoding='utf-8').write(svg_text)
    print('rewrote', os.path.relpath(SVG, ROOT))

    full = crop_tight(render_svg(SVG))
    save(full, 'assets/images/logo_jobhub.png')
    save(whiten(full), 'assets/images/logo_jobhub_white.png')

    for dpi, size in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96), ('xxhdpi', 144), ('xxxhdpi', 192)]:
        save(compose_icon(mark, size), 'android/app/src/main/res/mipmap-%s/ic_launcher.png' % dpi)
        # adaptive icon (Android 8+): lớp foreground 108dp, nội dung trong vùng an toàn 66dp
        fg_size = int(size * 108 / 48)
        fg = Image.new('RGBA', (fg_size, fg_size), (0, 0, 0, 0))
        target_h = int(fg_size * 66 / 108 * 0.78)
        m = mark.resize((max(1, int(mark.width * target_h / mark.height)), target_h), Image.LANCZOS)
        fg.alpha_composite(m, ((fg_size - m.width) // 2, (fg_size - m.height) // 2))
        save(fg, 'android/app/src/main/res/mipmap-%s/ic_launcher_foreground.png' % dpi)
    adaptive = rel('android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml')
    os.makedirs(os.path.dirname(adaptive), exist_ok=True)
    with open(adaptive, 'w', encoding='utf-8') as f:
        f.write('<?xml version="1.0" encoding="utf-8"?>\n'
                '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
                '    <background android:drawable="@color/ic_launcher_background"/>\n'
                '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
                '</adaptive-icon>\n')
    print('wrote android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml')
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
