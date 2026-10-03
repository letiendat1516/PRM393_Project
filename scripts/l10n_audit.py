# -*- coding: utf-8 -*-
"""
Audit chuỗi hardcoded tiếng Việt trong lib/ (chuẩn bị l10n — KHÔNG sửa lib/).

Quét mọi string literal trong lib/**/*.dart, lọc chuỗi có dấu tiếng Việt,
phân loại ngữ cảnh (label/button/dialog/...), đề xuất key snake_case nhóm
theo feature, xuất bảng markdown docs/09_LOCALIZATION_AUDIT.md.

Chạy:  python scripts/l10n_audit.py          (từ thư mục gốc project)
"""
import re
import sys
import unicodedata
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LIB = ROOT / "lib"
OUT = ROOT / "docs" / "09_LOCALIZATION_AUDIT.md"

# Ký tự dấu tiếng Việt (Latin Extended). [À-ỹ] bao gồm cả ă Â đ Đ ơ ư.
VIET_RE = re.compile(r"[À-ỹ]")
# Bỏ qua: nội dung demo (job mẫu) tách nhóm riêng để bảng UI không bị nhiễu.
DATA_FILES = {"lib/core/data/demo_data.dart"}

CONTEXT_RULES = [
    ("dialog", re.compile(r"AlertDialog|showDialog|dialogTitle|Dialog\(")),
    ("snackbar", re.compile(r"SnackBar|snack")),
    ("tooltip", re.compile(r"[Tt]ooltip")),
    ("button", re.compile(r"[Bb]utton|onPressed|TextButton|ElevatedButton|OutlinedButton|IconButton|ActionButton")),
    ("form hint/label", re.compile(r"hintText|labelText|helperText|errorText|InputDecoration")),
    ("label", re.compile(r"label\s*:")),
    ("title", re.compile(r"title\s*:|appBar|Tab\(")),
    ("text hiển thị", re.compile(r"Text\(|RichText|Span\(")),
    ("validation/lỗi", re.compile(r"[Ff]ailure|[Ee]xception|throw|error|Validators|message")),
    ("enum/option", re.compile(r"FilterOption|enum |=>|switch")),
]


def strip_diacritics(s: str) -> str:
    nfd = unicodedata.normalize("NFD", s)
    return "".join(c for c in nfd if not unicodedata.combining(c)).replace("đ", "d").replace("Đ", "D")


def slug(s: str, maxlen: int = 42) -> str:
    s = strip_diacritics(s).lower()
    s = re.sub(r"[^a-z0-9]+", "_", s).strip("_")
    s = re.sub(r"_+", "_", s)
    return s[:maxlen].rstrip("_") or "str"


def extract_string_literals(line: str):
    """Trả về list (col, literal) — state machine bỏ qua comment và escape."""
    out = []
    i, n = 0, len(line)
    in_str = None  # quote char đang mở
    buf = ""
    while i < n:
        c = line[i]
        if in_str:
            if c == "\\" and i + 1 < n:
                buf += c + line[i + 1]
                i += 2
                continue
            if c == in_str:
                out.append(buf)
                in_str = None
                buf = ""
            else:
                buf += c
        else:
            if c in ("'", '"'):
                in_str = c
                buf = ""
            elif c == "/" and i + 1 < n and line[i + 1] == "/":
                break  # phần còn lại của dòng là comment
        i += 1
    return out


def classify(line: str) -> str:
    for name, rx in CONTEXT_RULES:
        if rx.search(line):
            return name
    return "khác"


def feature_of(rel: str) -> str:
    parts = rel.split("/")
    if rel.startswith("lib/features/") and len(parts) >= 3:
        return f"features/{parts[2]}"
    if rel.startswith("lib/core/"):
        sub = parts[2] if len(parts) > 3 else parts[2].removesuffix(".dart")
        return f"core/{sub}"
    if rel.startswith("lib/shared/"):
        return "shared"
    if rel.startswith("lib/"):
        return "lib"  # file ở gốc lib/ (app.dart, router…)
    return "/".join(parts[:2])


def esc(s: str) -> str:
    return s.replace("|", "\\|").replace("\n", " ").replace("\r", "")


def main():
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    rows = []  # (relpath, line_no, string, context, is_data)
    for f in sorted(LIB.rglob("*.dart")):
        if f.name.endswith(".g.dart") or f.name.endswith(".freezed.dart"):
            continue
        rel = f.relative_to(ROOT).as_posix()
        is_data = rel in DATA_FILES
        try:
            text = f.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        for no, line in enumerate(text.splitlines(), 1):
            stripped = line.strip()
            if stripped.startswith(("import ", "part ", "export ", "//", "*", "/*")):
                continue
            for lit in extract_string_literals(line):
                if not VIET_RE.search(lit):
                    continue
                if len(lit) > 160:  # block nội dung dài (mô tả job...) — vẫn thống kê
                    ctx = "nội dung dài"
                else:
                    ctx = classify(line)
                rows.append((rel, no, lit, ctx, is_data))

    # Chuỗi UI: ngoài file data demo và có khoảng trắng (theo đề bài).
    ui_rows = [r for r in rows if not r[4] and " " in r[2].strip()]
    data_rows = [r for r in rows if r[4]]

    # Đề xuất key: dedupe theo chuỗi (cùng chuỗi → cùng key), prefix theo feature.
    key_by_str = {}
    assigned = set()
    for rel, no, s, ctx, _ in ui_rows:
        if s in key_by_str:
            continue
        feat = feature_of(rel)
        prefix = feat.replace("features/", "").replace("core/", "c_").replace("shared", "s_").replace("lib", "app").replace("/", "_")
        base = f"{prefix}_{slug(s)}"
        key, k = base, 2
        while key in assigned:
            key = f"{base}_{k}"
            k += 1
        assigned.add(key)
        key_by_str[s] = key

    by_feat = defaultdict(list)
    for r in ui_rows:
        by_feat[feature_of(r[0])].append(r)

    top_files = Counter(r[0] for r in rows).most_common(10)

    lines = []
    w = lines.append
    w("# Audit chuỗi hardcoded tiếng Việt (`lib/`)")
    w("")
    w("Sinh tự động bởi `scripts/l10n_audit.py` (chỉ đọc `lib/`, không sửa gì). ")
    w("Mục đích: bảng tổng hợp để nhóm chuyển sang `AppLocalizations` (flutter gen-l10n) sau này.")
    w("")
    w("## Thống kê")
    w("")
    w(f"- Tổng occurrences chuỗi có dấu tiếng Việt trong `lib/`: **{len(rows)}**")
    w(f"- Chuỗi UI (có khoảng trắng, ngoài file data demo): **{len(ui_rows)}** — chuỗi duy nhất: **{len(key_by_str)}**")
    w(f"- Chuỗi nội dung demo (`lib/core/data/demo_data.dart`, không phải UI — sẽ đến từ backend khi có dữ liệu thật): **{len(data_rows)}**")
    w("- Số file có ít nhất 1 chuỗi: " + str(len({r[0] for r in rows})))
    w("")
    w("### Top 10 file nhiều chuỗi nhất")
    w("")
    w("| File | Số chuỗi |")
    w("|---|---|")
    for f, c in top_files:
        w(f"| `{f}` | {c} |")
    w("")
    w("### Nhóm theo feature")
    w("")
    w("| Feature | Số chuỗi UI |")
    w("|---|---|")
    for feat in sorted(by_feat, key=lambda x: -len(by_feat[x])):
        w(f"| `{feat}` | {len(by_feat[feat])} |")
    w("")
    w("## Bảng chi tiết (chuỗi UI, nhóm theo feature)")
    w("")
    w("Key đề xuất sinh tự động: `<feature>_<slug-chuỗi>` — chỉ là gợi ý, đặt tên lại theo ngữ nghĩa khi hiện thực.")
    w("")
    for feat in sorted(by_feat):
        w(f"### `{feat}` ({len(by_feat[feat])})")
        w("")
        w("| Vị trí | Chuỗi | Key đề xuất | Ngữ cảnh |")
        w("|---|---|---|---|")
        for rel, no, s, ctx, _ in by_feat[feat]:
            disp = esc(s if len(s) <= 70 else s[:67] + "…")
            w(f"| `{rel}:{no}` | {disp} | `{key_by_str[s]}` | {ctx} |")
        w("")
    w("## Phụ lục — scaffold `AppLocalizations` (gợi ý, chưa áp dụng)")
    w("")
    w("```yaml")
    w("# l10n.yaml")
    w("arb-dir: lib/l10n")
    w("template-arb-file: app_vi.arb")
    w("output-localization-file: app_localizations.dart")
    w("```")
    w("")
    w("```json")
    w("// lib/l10n/app_vi.arb (mẫu)")
    w('{')
    w('  "@@locale": "vi",')
    sample = list(key_by_str.items())[:5]
    for s, k in sample:
        w(f'  "{k}": "{esc(s)}",')
    w('  "c_common_thoa_thuan": "Thoả thuận"')
    w("}")
    w("```")
    w("")
    w("```dart")
    w("// MaterialApp:")
    w("//   localizationsDelegates: AppLocalizations.localizationsDelegates,")
    w("//   supportedLocales: AppLocalizations.supportedLocales,")
    w("// Dùng: Text(AppLocalizations.of(context)!.cCommonThoaThuan)")
    w("```")
    w("")
    w("## Ghi chú")
    w("- Chuỗi trong `demo_data.dart` là nội dung job mẫu (dữ liệu, không phải UI) — không cần l10n.")
    w("- Regex nhận diện: literal có ký tự `[À-ỹ]`; chuỗi UI yêu cầu thêm khoảng trắng (theo đề bài).")
    w("- Script bỏ qua dòng `import`/`part` và phần comment `//` cùng dòng.")
    w("")

    OUT.write_text("\n".join(lines), encoding="utf-8")
    print(f"OK: {OUT}")
    print(f"  tổng occurrences: {len(rows)} | UI: {len(ui_rows)} (unique {len(key_by_str)}) | data demo: {len(data_rows)}")


if __name__ == "__main__":
    sys.exit(main())
