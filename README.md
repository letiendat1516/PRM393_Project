# JobHub — AI-powered Recruitment Platform (PRM393)

`Build: passing · Tests: 404 passed · Rules: deployed · Platform: Android/Web`

Đồ án môn học **PRM393** — ứng dụng tuyển dụng thông minh, port 100% từ web app
JobHub (React + Node/Express + Postgres) sang **Flutter** (Mobile + Web), tích hợp
AI (Gemini) để phân tích CV, chấm điểm độ khớp và gợi ý việc làm.

## Tính năng nổi bật

- **Tìm việc & ứng tuyển**: tìm kiếm, bộ lọc (ngành, lương, địa điểm, kinh nghiệm),
  lưu việc, nộp đơn trực tuyến.
- **AI Matching / Phân tích CV**: chấm điểm độ khớp CV–job bằng Gemini
  (endpoint tương thích OpenAI) + fallback chấm điểm rule-based khi không có API key.
- **Nhà tuyển dụng**: quản lý hồ sơ công ty, đăng/tin tuyển dụng, duyệt hồ sơ ứng viên.
- **Admin**: quản lý users/NTD, duyệt tin, catalog (categories/skills),
  cấu hình hệ thống, thống kê AI, seed dữ liệu demo.
- **Thông báo realtime**: FCM push (Android) + local notifications, chat hai chiều.
- **Đa nền tảng**: Android (minSdk 23) + Web, dark/light theme, localize vi/en.

## Kiến trúc & yêu cầu học phần

| Yêu cầu | Hiện thực |
|---|---|
| Firebase đăng nhập | `firebase_auth` (Email/Password + Google Sign-In) — `lib/core/services/auth_service.dart` |
| Notification | FCM + `flutter_local_notifications` — `lib/core/services/fcm_service.dart`, `lib/features/notifications/` |
| MVVM | `lib/features/<feature>/{data,viewmodels,views,widgets}` |
| Riverpod | `flutter_riverpod` 2.x (StreamProvider / StateNotifier) |
| Firestore | 18 bảng SQL → collections (xem `lib/README_PORT.md`), rules + indexes trong repo |
| SharedPreferences | `lib/core/services/prefs_service.dart` (theme, ngôn ngữ, remember-me, onboarding, phiên AI…) |

## Cài đặt & chạy

Yêu cầu: Flutter SDK ≥ 3.12 (Dart ^3.12), Firebase project đã `flutterfire configure`.

```bash
flutter pub get
flutter run -d chrome          # web
flutter run                     # Android/iOS (minSdk 23)
```

Firebase project: `jobhub-prm393-g3` (đã cấu hình trong `lib/firebase_options.dart`).

```bash
firebase deploy --only firestore      # rules + indexes (firestore.rules / firestore.indexes.json)
```

Tuỳ chọn runtime (dart-define):

| Key | Ý nghĩa |
|---|---|
| `GEMINI_API_KEY` | AI phân tích CV / chấm điểm (hoặc admin nhập trong *Cấu hình hệ thống*) |
| `GEMINI_MODEL` | mặc định `gemini-2.5-flash` |
| `FCM_VAPID_KEY` | bật push trên web |
| `ADMIN_EMAILS` | email tự thành admin khi đăng ký (mặc định `admin@jobhub.vn`) |

## Tài khoản & dữ liệu demo

1. Đăng ký ứng viên tại `/dang-ky`, nhà tuyển dụng tại `/dang-ky-nha-tuyen-dung`.
2. **Admin**: đăng ký với email `admin@jobhub.vn` (xem `ADMIN_EMAILS`).
3. Admin → *Tổng quan* → **Seed dữ liệu demo**: tạo categories, skills, 18 hồ sơ
   nhà tuyển dụng + 18 tin mẫu và cấu hình hệ thống mặc định.
4. Admin → *Cấu hình hệ thống* → nhập `GEMINI_API_KEY` để bật AI Matching /
   phân tích CV (không có key vẫn dùng được chấm điểm rule-based).

> Firebase Storage chưa bật (cần Blaze). Upload CV PDF sẽ lưu metadata + nội dung
> text (dán/tệp .txt); AI phân tích chạy trên text đó.

Firestore đang chứa **9.800 việc làm + 2.456 hồ sơ NTD** (dataset synthetic TopCV —
xem `crawl-topcv/` và `docs/10_CRAWL_DATASET.md`, `docs/11_CRAWL_IMPORT_PIPELINE.md`).

## Màn hình (35 routes)

- **Public**: `/` `/viec-lam` `/viec-lam/:id` `/cong-ty/:id` `/de-xuat` `/de-xuat/:sessionId`
  `/dang-nhap` `/dang-ky` `/dang-ky-nha-tuyen-dung` `/quen-mat-khau` `/onboarding`
- **Ứng viên**: `/ho-so` `/ho-so/chinh-sua` `/ho-so/phan-tich/:resumeId` `/viec-lam/:id/ung-tuyen`
  `/applications` `/applications/:id` `/viec-da-luu`
- **Nhà tuyển dụng**: `/employer` `/employer/company-profile` `/employer/jobs` `/employer/jobs/create`
  `/employer/jobs/:id/edit` `/employer/jobs/:id/applicants` `/employer/applications` `/employer/applications/:id`
- **Admin**: `/admin` `/admin/users` `/admin/employers` `/admin/pending-jobs` `/admin/catalog`
  `/admin/system-configurations` `/ai-logs` `/admin/ai-stats`
- **Chung**: `/notifications` `/tin-nhan` `/tin-nhan/:chatId` `/settings`

## CI (GitHub Actions)

`.github/workflows/ci.yml` chạy khi push/PR: checkout → Flutter (subosito/flutter-action@v2) →
`flutter pub get` → `flutter analyze` → `flutter test --coverage` → upload artifact `coverage`
(lcov.info — xem mẫu `docs/COVERAGE_SUMMARY.md`) → `flutter build web --release` →
`flutter build apk --debug`.

Trạng thái hiện tại (2026-10-03):

- `flutter analyze` sạch; `flutter test` → **404 test pass** (14 file).
- `firebase deploy --only firestore:rules` thành công.
- Android: build APK debug OK (minSdk 23, multidex, desugaring), đã xác minh trên
  emulator (ảnh trong `docs/screenshots/`).
- Phân công 5 thành viên × ≥3 màn: `docs/01_PHAN_CONG.md` · kịch bản demo 10 phút:
  `docs/04_HUONG_DAN_DEMO.md` · rubric đối chiếu yêu cầu môn: `docs/06_RUBRIC_PRM393.md`.

## Cấu trúc thư mục

```
lib/
  main.dart, app.dart, firebase_options.dart
  core/     config, router (go_router + role guard), theme (Tailwind tokens), services
            (auth, fcm, prefs, firestore_refs, system_config, ai/gemini, ai/rule_based_scorer,
            ai_session_store), utils (enums, failure, validators, formatters), data/demo_data.dart
  shared/   models (18 bảng), widgets (navbar, footer, layout, job cards, badges, timeline…)
  features/ auth, home, jobs, applications, profile, employer, admin, recommendations,
            notifications, chat, settings, splash
  README_PORT.md   hợp đồng kiến trúc + mapping route → file → class
crawl-topcv/       pipeline crawl + sinh dữ liệu synthetic TopCV → import Firestore
ai-lab/            prompt/thử nghiệm AI (phân tích CV, matching)
docs/              phân công, hướng dẫn demo, rubric, coverage, dataset
```

## Logo & icon

Logo thương hiệu: `assets/icons/logo_jobhub.svg` (Canva). Chạy `python docs/gen_logo_assets.py`
để sinh lại `assets/images/logo_jobhub*.png`, `logo_mark*.png` và toàn bộ icon launcher
Android / iOS / web (cần Chrome + Pillow).
