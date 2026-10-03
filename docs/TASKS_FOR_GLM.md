# Giao việc cho phiên GLM (chạy song song với phiên Claude chính)

Project: `C:\Users\dat\AndroidStudioProjects\jobhub_prm393` — Flutter port (Mobile + Web) của web app JobHub
(`C:\Users\dat\Desktop\New folder\jobhub`, React + Node/Express + Postgres) sang Firebase Auth + Firestore + FCM,
Riverpod 2, MVVM, SharedPreferences. Môn PRM393, nhóm 5 người, mỗi người ≥3 màn hình.

Đọc trước: `README.md` (tổng quan, 35 route, cách chạy) và `lib/README_PORT.md` (hợp đồng kiến trúc, model, provider,
widget dùng chung, đường dẫn spec).

## QUY TẮC PHỐI HỢP (bắt buộc)

Phiên Claude chính đang sửa code trong `lib/` bằng nhiều agent song song. Để không ghi đè lẫn nhau:

- **KHÔNG sửa bất kỳ file nào trong `lib/`**. Nếu phát hiện lỗi trong `lib/`, ghi vào `docs/GLM_REPORT.md`
  (file, dòng, mô tả, cách sửa đề xuất) — phiên chính sẽ áp dụng.
- **KHÔNG sửa `pubspec.yaml`**, không chạy `flutter pub add`, không `firebase deploy`, không sửa `firestore.rules`
  / `firestore.indexes.json`.
- Chỉ được tạo/sửa file trong: `docs/`, `test/`, `android/`, `ios/`, `web/`, `assets/` (và `README.md` nếu cần).
- Mỗi việc xong, ghi kết quả vào `docs/GLM_REPORT.md` (mục riêng cho từng việc, kèm lệnh đã chạy và output tóm tắt).
- Chạy lệnh từ thư mục project. `flutter analyze` / `flutter test` được phép; `flutter run` được phép trên
  Android (emulator/thiết bị). Web đang chạy ở cổng 5173 bởi phiên chính — đừng chạy web ở cổng đó.

## VIỆC 1 — Tài liệu nộp môn (`docs/`)

Tạo các file:

1. `docs/01_PHAN_CONG.md` — bảng phân công **5 thành viên × ≥3 màn hình** (mức medium trở lên). Dùng 35 route trong
   `README.md`; gợi ý nhóm: (a) auth + hồ sơ ứng viên, (b) tìm việc + chi tiết job + công ty + việc đã lưu,
   (c) CV/AI (upload, phân tích, AI matching, đề xuất) + ứng tuyển, (d) nhà tuyển dụng (dashboard, đăng/sửa tin,
   ứng viên, duyệt hồ sơ, hồ sơ công ty), (e) thông báo + chat + cài đặt + admin. Mỗi dòng: tên màn hình, route,
   file view/viewmodel/repository tương ứng (tra trong `lib/features/...`), mức độ (medium/hard) và lý do.
2. `docs/02_YEU_CAU_GIAO_VIEN.md` — bảng ánh xạ từng yêu cầu → hiện thực + file:
   Firebase đăng nhập (`lib/core/services/auth_service.dart`, `lib/features/auth/`), Notification
   (`lib/core/services/fcm_service.dart`, `lib/features/notifications/`, `web/firebase-messaging-sw.js`,
   `android/app/src/main/AndroidManifest.xml`), MVVM (cấu trúc `features/<f>/{data,viewmodels,views,widgets}`),
   Riverpod (`lib/core/providers.dart`, các `*_providers.dart`, `*_viewmodel.dart`), Firestore (18 bảng SQL →
   collections, `lib/core/services/firestore_refs.dart`, `firestore.rules`, `firestore.indexes.json`),
   SharedPreferences (`lib/core/services/prefs_service.dart`: theme, ngôn ngữ, remember-me, onboarding, phiên AI…).
3. `docs/03_KIEN_TRUC.md` — sơ đồ kiến trúc (Mermaid): View → ViewModel (Riverpod) → Repository → Firebase;
   luồng dữ liệu các nghiệp vụ chính (đăng ký/đăng nhập, đăng tin → admin duyệt → public, ứng tuyển → đổi trạng
   thái → thông báo, upload CV → AI phân tích → AI matching → lưu phiên). Lấy mapping bảng từ
   `C:\Users\dat\Desktop\New folder\jobhub\docs\*.md` (schema gốc) và `lib/shared/models/*.dart`.
4. `docs/04_HUONG_DAN_DEMO.md` — kịch bản demo 10 phút: đăng ký admin (`admin@jobhub.vn`), seed dữ liệu demo
   (Admin → Tổng quan → Seed dữ liệu demo), nhập GEMINI_API_KEY (Admin → Cấu hình hệ thống), đăng ký ứng viên →
   hoàn thiện hồ sơ → upload CV → AI matching → ứng tuyển; đăng ký NTD → đăng tin → admin duyệt → NTD đổi trạng
   thái hồ sơ → ứng viên nhận thông báo; mobile: onboarding, dark mode, cài đặt thông báo.
5. `docs/05_SLIDE_OUTLINE.md` — dàn ý 12–15 slide.

## VIỆC 2 — Kiểm thử Android

- `flutter devices`; nếu không có emulator: `flutter emulators` → `flutter emulators --launch <id>`.
- `flutter run -d <android-device>` (debug). Kiểm tra: build gradle OK (minSdk 23, multidex), app mở Splash →
  Onboarding → Home; đăng ký/đăng nhập; xin quyền POST_NOTIFICATIONS (Android 13+); kênh thông báo
  `jobhub_default`; mở `/viec-lam`, chi tiết job, lưu tin; đổi dark mode trong Cài đặt.
- Ghi lại mọi exception trong log (`flutter run` output) vào `docs/GLM_REPORT.md` kèm stack trace rút gọn.
- Chỉ được sửa trong `android/` (ví dụ thiếu quyền, cấu hình gradle). Lỗi Dart → chỉ báo cáo.

## VIỆC 3 — Unit test (`test/`)

Viết test cho logic thuần (không cần Firebase):

- `test/core/formatters_test.dart`: `Formatters.salary` ("25 - 40 triệu", "Thoả thuận"), `postedText`/`postedAgo`
  ("Đăng hôm nay" / "2 ngày trước"), `deadlineFull` ("dd/MM/yyyy (còn N ngày)" / "(hết hạn hôm nay)" /
  "(đã hết hạn)"), `localeDateTime`.
- `test/core/validators_test.dart`: email, password (8–128, thông báo verbatim), fullName/companyName
  ("… là bắt buộc."), salaryRange ("Lương tối thiểu phải nhỏ hơn hoặc bằng lương tối đa."), deadlineNotPast
  ("Hạn nộp hồ sơ phải là hôm nay hoặc trong tương lai.").
- `test/core/rule_based_scorer_test.dart`: `RuleBasedScorer.scoreJobs(cvPayload, jobs)` so với thuật toán backend
  `C:\Users\dat\Desktop\New folder\jobhub\backend\src\services\RecommendationService.js` (đường score-sql): tổng
  điểm ≤100, breakdown 7 tiêu chí, missing skills, kinh nghiệm thiếu/đủ, education mapping.
- `test/shared/application_model_test.dart`: `ApplicationModel.transitions` (SUBMITTED→UNDER_REVIEW|ACCEPTED|
  REJECTED; UNDER_REVIEW→ACCEPTED|REJECTED; terminal không chuyển), `docIdFor(seekerUid, jobId)`, `timeline`
  (node SUBMITTED tổng hợp).
- `test/shared/job_model_test.dart`: `JobModel.tokenize`/`stripDiacritics`, `isExpired`, `hot`, `isPublic`.
- `test/core/ai_session_store_test.dart`: dùng `SharedPreferences.setMockInitialValues({})`; lưu > 20 phiên thì
  cắt còn 20, mới nhất đứng đầu; migrate key cũ `jobhub.aiScores` → `jobhub.aiSessions`.

Chạy `flutter test` đến khi xanh. Nếu một API trong `lib/` khác với mô tả ở đây, test theo API thực tế và ghi chú.

## VIỆC 4 — Icon & splash

- Tạo icon launcher Android/iOS từ `assets/icons/favicon.svg` (có thể thêm `dev_dependency`? **KHÔNG** — không
  sửa pubspec; dùng công cụ ngoài hoặc tạo PNG các kích thước mipmap thủ công bằng script Python/ImageMagick nếu
  có, đặt vào `android/app/src/main/res/mipmap-*/ic_launcher.png`).
- Web: `web/icons/Icon-192.png`, `Icon-512.png`, maskable, `web/favicon.png`; cập nhật `web/manifest.json`
  (name "JobHub", theme_color `#0F4C81`, background `#F8FAFC`).
- Ghi lại các file đã tạo.

## BÁO CÁO

`docs/GLM_REPORT.md` theo mẫu:

```
## Việc N — <tên>
Trạng thái: xong / dở (lý do)
Files: ...
Lệnh & kết quả: ...
Lỗi phát hiện trong lib/ (chỉ báo cáo, không sửa): file:line — mô tả — đề xuất
```

---

# ĐỢT 2 — 2026-10-03 (sau khi V1–V4 xong)

**Bối cảnh cập nhật từ phiên Claude chính:**
- `flutter analyze` sạch, `flutter test` → `+253 All tests passed!`.
- Phiên chính đã sửa 6 lỗi P1 (4 trong `firestore.rules`, 2 trong `lib/`) và deploy rules. Chi tiết trong
  `C:/Users/dat/AppData/Local/Temp/audit.txt` (29KB — có thể đọc tham khảo, KHÔNG xoá).
- `isExpired` giờ so sánh theo **ngày** (day-truncated); `JobsRepository.watchPublicJobs(keyword: ...)` giờ chain
  `where('titleTokens', arrayContainsAny: tokens)` (≤10 token). `JobsSearchViewModel` resubscribe khi submit.
- README.md vẫn ghi sai "12 NTD + 18 việc" — thực tế `seedDemoData()` tạo **18 NTD + 18 việc** (xem Ghi chú 1 ở
  cuối phần V1 của phiên trước).

**Quy tắc phối hợp vẫn như cũ**: không đụng `lib/`, `pubspec.yaml`, `firestore.rules`, `firestore.indexes.json`;
không `firebase deploy`. Được phép: `docs/`, `test/`, `android/`, `ios/`, `web/`, `assets/`, `scripts/`,
`.github/`, `README.md`.

## VIỆC 5 — Mở rộng test suite + coverage report

Mục tiêu: nâng độ phủ test cho các thành phần thuần Dart chưa được test, cộng với contract test cho những thay
đổi mới ở V1 (isExpired day-truncated, titleTokens arrayContainsAny). KHÔNG dùng dependency mới (pubspec khoá);
`fake_cloud_firestore` KHÔNG có trong pubspec — nếu cần stub Firestore, dùng class giả tay (`class _FakeQuery
implements Query<JobModel> { ... }`).

Viết các file test (mỗi file xanh trước khi sang file khác, cuối cùng chạy full `flutter test`):

1. `test/core/prefs_service_test.dart` — `SharedPreferences.setMockInitialValues({})`, test toàn bộ ~12 key của
   `PrefsService` (lib/core/services/prefs_service.dart): get-trống → default, set→get round-trip, remember-me,
   push recent search (cap 10, dedupe case-insensitive giữ thứ tự mới nhất đầu), lastRole getter/setter, clear.
2. `test/core/failure_test.dart` — `Failure.from` mapping: `FirebaseException` code `permission-denied` → `FORBIDDEN`;
   `not-found` → `NOT_FOUND`; `failed-precondition` + message chứa "index" → `INDEX_MISSING`;
   `unavailable` → `NETWORK`; `TimeoutException` → `TIMEOUT`; mặc định → `UNKNOWN` giữ message gốc; `Failure.from(Failure)` idempotent.
3. `test/shared/notification_model_test.dart` — enum `type` whitelist round-trip (6 giá trị khớp rule mới
   trong `firestore.rules` line 149–157), `isRead` default false, `toJson/fromJson` round-trip, `createdAt`
   sentinel `FieldValue.serverTimestamp()` handling.
4. `test/features/jobs/jobs_search_tokens_contract_test.dart` — contract: với mỗi từ khoá (`k` ∈ {"flutter",
   "nodejs", "lập trình java", "C++", "React.js", "senior developer"}), tạo `JobModel` với title chứa `k`, lấy
   `job.titleTokens`, lấy `JobsRepository._searchTokens(k)` (expose qua `@visibleForTesting` ở test — hoặc viết
   lại 1-1 logic ở test rồi so sánh), KHẲNG ĐỊNH tập giao của 2 danh sách không rỗng → đảm bảo keyword `k` sẽ
   match tin đã index. (Nếu `_searchTokens` là private không export được, mô phỏng lại 2 dòng:
   `JobModel.tokenize(k).take(10)`.)
5. `test/core/demo_data_test.dart` — `DemoData.sampleEmployers()` ≥18 bản ghi, `DemoData.sampleJobs()` =18, mỗi
   job có `jobId` không rỗng + `employerId` khớp 1 employer trong set, không trùng `jobId`, mọi job
   `isApproved=true && status==OPEN` (vì mock dùng cho homepage). Nếu seed tạo 12 `sampleEmployers()`+6 từ
   featuredJobs → kiểm tra tổng 18 unique uid.

Sau khi 5 file test xanh, chạy:
```
flutter test --coverage
```
Nếu Windows không có `genhtml`/`lcov`, tự parse `coverage/lcov.info` bằng Python (có PIL rồi thì chắc chắn có
Python) sinh `docs/COVERAGE_SUMMARY.md`:
- Bảng theo module (`lib/core/`, `lib/features/<f>/`, `lib/shared/`): tổng dòng, dòng được chạm, %.
- Top 10 file % thấp nhất (ngoài file ít dòng <10).
- Ghi lệnh đã chạy + số test cuối (`+XXX All tests passed!`).

## VIỆC 6 — README cập nhật + rubric môn PRM393 + API surface

6a. **Sửa `README.md`** (được phép sửa):
- Thay "12 employer + 18 job" bằng con số thật khớp `demo_data.dart` (verify bằng cách chạy `grep -c 'uid:' lib/core/data/demo_data.dart` hoặc đếm manual rồi ghi vào docs/GLM_REPORT.md).
- Thêm section "Tình trạng port (2026-10-03)": `flutter analyze` sạch, `flutter test` 253 pass, `firebase deploy
  --only firestore:rules` thành công, Android build APK OK. Dẫn `docs/01_PHAN_CONG.md` và `docs/04_HUONG_DAN_DEMO.md`.
- Thêm badge trạng thái (text, không dùng shields.io để tránh phụ thuộc mạng khi grader xem offline):
  `Build: passing · Tests: 253 passed · Rules: deployed · Platform: Android/Web`.

6b. **Tạo `docs/06_RUBRIC_PRM393.md`** — bảng rubric môn PRM393 (giảng viên chấm theo yêu cầu), đối chiếu từng
tiêu chí → trạng thái → bằng chứng (file:line):
- Firebase Auth (đăng ký/đăng nhập email+mật khẩu, logout, remember-me)
- Firebase Cloud Messaging (foreground/background, kênh `jobhub_default`, deep-link navigation)
- Cloud Firestore (14 collection + 4 subcollection, 36 index, 10 helper rule)
- MVVM (View ↔ ViewModel ↔ Repository ↔ Service; dẫn 3 ví dụ cụ thể từ features khác nhau)
- Riverpod (StateNotifier, StreamProvider, Provider, ref.watch/listen; dẫn 5 provider khác loại)
- SharedPreferences (12 key qua `PrefsService`, dẫn ví dụ dark mode persist)
- Multi-member (5 TV × ≥3 màn) — chỉ về `docs/01_PHAN_CONG.md`.
- Dark mode (`SettingsPage.themeMode`)
- Multi-language — nếu CHƯA làm, ghi "chưa" + nêu `l10n` setup trong `lib/main.dart`/`MaterialApp.supportedLocales`.
- Responsive (web ≥1024 vs mobile 320–480).
- Unit test ≥50 (hiện 253 — vượt yêu cầu).

6c. **Tạo `docs/07_API_SURFACE.md`** — tham chiếu nhanh cho người bảo trì:
- Danh sách tất cả method của `FirestoreRefs` (18 method theo V1), kèm `allow`/`deny` tương ứng trong
  `firestore.rules`.
- Bảng 14+4 collection: tên, khoá primary, index composite nếu có (parse `firestore.indexes.json`), rule tóm tắt.
- Luồng Create/Update/Delete chính (3–5 luồng — ví dụ: apply job, moderate job, send notification) với sequence
  diagram Mermaid (như 03_KIEN_TRUC.md nhưng ngắn gọn, tập trung API).

## VIỆC 7 — Audit chuỗi hardcoded tiếng Việt (chuẩn bị l10n sau này)

Mục tiêu: không chuyển i18n ngay (đụng `lib/`), chỉ **liệt kê** để nhóm có bảng tổng hợp.

Grep `lib/` tìm chuỗi hardcoded tiếng Việt (có dấu, có khoảng trắng, không phải key cấu hình). Có thể dùng
pattern Python:
```python
import re, pathlib
pat = re.compile(r"['\"]([^'\"]*[ăâđêôơư][^'\"]*)['\"]", re.IGNORECASE)
# hoặc regex đơn giản hơn: [À-ỹ]
```

Xuất `docs/09_LOCALIZATION_AUDIT.md`:
- Bảng: `file:line | chuỗi | key đề xuất (snake_case, nhóm theo feature) | ghi chú (nếu là label/button/dialog
  title)`.
- Thống kê: tổng số chuỗi, top 10 file nhiều chuỗi nhất, nhóm theo feature.
- Phụ lục: gợi ý `AppLocalizations` scaffold (code mẫu, không ghi vào lib).

## VIỆC 8 — CI workflow (GitHub Actions)

Tạo `.github/workflows/ci.yml` chạy khi push/PR:
```yaml
name: CI
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.44.6'
          channel: stable
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test --coverage
      - uses: actions/upload-artifact@v4
        with:
          name: coverage
          path: coverage/
      - run: flutter build web --release
      - run: flutter build apk --debug
```

**KHÔNG push lên remote** (không có git credential). Chỉ tạo file + verify YAML hợp lệ bằng Python
(`yaml.safe_load`). Ghi lại kết quả parse vào `docs/GLM_REPORT.md`.

Thêm vào `README.md` section "CI": mô tả workflow + nơi tải artifact coverage.

## VIỆC 9 — Chạy lại Android verify Home sau fix layout

Phiên chính đã sửa `home_layout_helpers.dart` (lỗi `RenderFlex unbounded height`). Việc này đã xong ở V2 bên
GLM nhưng xác minh home trước fix không chụp được. Lần này:
- Launch `emulator-5554` (hoặc emulator khác đang chạy).
- `flutter run -d emulator-5554` (debug). Chờ app vào Splash → Home.
- `flutter screenshot --out docs/screenshots/android_home_fixed.png`.
- Tap "Đăng nhập" bằng `adb shell input tap <x> <y>` (toạ độ nút lấy từ layout — xem shot trước đó). Screenshot
  `docs/screenshots/android_login_page.png`.
- Nếu adb bị từ chối quyền, ghi lại trong `docs/GLM_REPORT.md` và dừng ở phần screenshot flutter-only.
- Không bắt buộc test full flow — chỉ cần 2 ảnh để chứng minh fix layout đã hoạt động trên Android.

## BÁO CÁO ĐỢT 2

Phần "ĐỢT 2" ở cuối `docs/GLM_REPORT.md`:
- Mỗi việc 1 mục con, trạng thái, danh sách file, lệnh & kết quả, errors nếu có.
- Nếu phát hiện thêm bug trong `lib/`, append vào mục "Lỗi phát hiện trong lib/" đã có.

---

# ĐỢT 3 — 2026-10-03 (crawl pipeline + Firestore import + lazy pagination)

**Bối cảnh cập nhật (2026-10-03 trưa):**
Phiên chính đã:
- Chạy `crawl-topcv/generate.js --perCategory=200` → `crawl-topcv/data/jobs-raw.json` (**9800 synthetic jobs,
  2932 công ty raw**, deterministic seed 20260708).
- Viết `crawl-topcv/import-firestore.js` + `clear-crawl.js` (firebase-admin, batched 500, dry-run OK).
- Clear + reimport Firestore: **9800 jobs + 2456 unique employerProfiles** (`source='crawl'`, isApproved+OPEN).
  SA key tại `crawl-topcv/jobhub-prm393-g3-firebase-adminsdk-fbsvc-759f69d63c.json` (gitignored).
- Sửa `lib/features/jobs/data/jobs_repository.dart` `mergeWithMocks` → drop 12 SYN- mocks khi
  `apiJobs.length >= 50`; thêm `countPublicJobs()` (Firestore `.count()` aggregation).
- Rewrite `lib/features/jobs/viewmodels/jobs_search_viewmodel.dart` sang **lazy pagination**:
  state giờ có `loadedLimit` (mặc định 30 = 3 trang × pageSize), `totalCount`, `isLoadingMore`.
  `setPage(p)` bump `loadedLimit` lên bội của 30 khi cần, resubscribe stream. Keyword đổi → reset
  `loadedLimit=30` + re-fetch count. Header `JobsSearchHeader` hiển thị `displayTotal` = `totalCount`
  khi không filter → user thấy "9.800 việc làm" dù mới load 30 doc.
- `flutter analyze` sạch, `flutter test` 253 pass.

**GLM phạm vi ĐỢT 3**: được phép đụng `crawl-topcv/` (vì đây là tooling Node, không phải `lib/`),
`docs/`, `test/`, `README.md`. Không chạy `node import-firestore.js` (cần SA key của user).

## VIỆC 10 — Thống kê & tài liệu dataset synthetic

Mục tiêu: giúp người đọc hiểu dataset trước khi import.

Đọc `crawl-topcv/data/jobs-raw.json` (9800 jobs) và sinh `docs/10_CRAWL_DATASET.md`:
- Tổng số jobs, công ty duy nhất (dedupe theo `company_name` lower+stripped).
- Histogram theo `category_name` (49 bucket) — bảng sắp xếp theo số lượng, in top 10 + bottom 5.
- Histogram theo `location_text` (city) — top 10 + bottom 10.
- Histogram theo `_experience_enum` (INTERN/FRESHER/JUNIOR/MID/SENIOR/LEAD) + `_work_mode` + `_job_type`.
- Phân phối salary: min, median, mean, max, p10/p25/p50/p75/p90 cho `_salary_min` và `_salary_max`; đếm
  `_is_negotiable == true`.
- SHA256 của `data/jobs-raw.json` để verify tính deterministic (rerun `generate.js --perCategory=100` lần 2
  phải cho SHA256 giống hệt — chạy 1 lần nữa ở `/tmp/jobs-raw-2.json` để verify).
- Phụ lục: 3 job mẫu deterministic — jobs[0], jobs[4899], jobs[9799].
- SHA256 reproducible: chạy lại `generate.js --perCategory=200` ở path khác, verify SHA256 trùng.

Dùng Python (fs/json/hashlib có sẵn) hoặc Node (readFileSync + JSON.parse). KHÔNG dùng pandas/numpy (không
cài). Script trung gian lưu tại `crawl-topcv/stats.js` hoặc `scripts/stats.py` tuỳ chọn.

## VIỆC 11 — Test cho mergeWithMocks threshold + lazy pagination

Viết `test/features/jobs/jobs_merge_mocks_test.dart`:
- Import: `package:jobhub_prm393/features/jobs/data/jobs_repository.dart`,
  `package:jobhub_prm393/core/data/demo_data.dart`.
- Group `JobsRepository.mergeWithMocks`:
  - `apiJobs rỗng → trả về 12 mock SYN-` (dùng `DemoData.sampleJobs().length` so sánh).
  - `apiJobs < 50 (ví dụ 10 job thật) → merge: 12 mock + 10 thật, dedupe theo jobId`.
  - `apiJobs >= 50 (ví dụ list 60 job thật) → bỏ hẳn mock, chỉ trả 60 thật`.
  - `apiJobs chứa cả public (isPublic=true) và pending (status=DRAFT) → chỉ public được qua filter`.
  - `apiJobs có job jobId rỗng → bỏ qua`.
  - `apiJobs 60 job nhưng 55 pending + 5 public → vẫn fallback mock (publicApi=5 < 50)`.
  - `apiJobs trùng jobId với 1 SYN mock → fallback branch: SYN giữ chỗ trước, apiJob bị bỏ qua
    (dedupe keep-first); non-fallback branch (>=50 public): SYN không xuất hiện`.
- Dùng helper `JobModel _mk(String id, {bool approved=true, JobStatus status=JobStatus.open})` để sinh job
  tối giản — khoảng ~8 field required.
- Chạy `flutter test test/features/jobs/jobs_merge_mocks_test.dart` xanh.

Thêm `test/features/jobs/jobs_search_state_test.dart` cho state class mới:
- `totalPages` khi không filter + `totalCount=9800` + `loadedLimit=30` → **980** (chứ không phải 3).
- `totalPages` khi filter active + 30 doc loaded + filtered.length=5 → **1** (dựa trên filtered, bỏ qua totalCount).
- `displayTotal` không filter: trả `totalCount` khi có; else `sourceJobs.length`.
- `displayTotal` filter active: trả `filtered.length` kể cả khi totalCount được set.
- `currentPage` clamp vào `totalPages` khi page vượt range.
- `pageJobs` lấy đúng 10 item tại vị trí `(currentPage-1) * pageSize`.
- Nếu quá phức tạp để test `JobsSearchViewModel.setPage` bump logic mà không cần Firestore, bỏ qua phần đó —
  chỉ cần test derived properties của state.

## VIỆC 12 — Tài liệu pipeline crawl → Firestore + lazy pagination

Tạo `docs/11_CRAWL_IMPORT_PIPELINE.md`:
- Mermaid flowchart: `generate.js → data/jobs-raw.json → import-firestore.js → Firestore (jobs/ +
  employerProfiles/)`; nhánh song song `transform.js → data/seed.sql` (Supabase legacy, không dùng cho Flutter port).
- Mô tả 2 collection target + schema (dẫn `job_model.dart` + `employer_profile_model.dart`).
- Bảng mapping `raw field → Firestore field` (ví dụ `_salary_min` → `salaryMin`, `_experience_enum` →
  `experienceLevel`, `job_detail.mo_ta_cong_viec` → `description.moTaCongViec`).
- Reproducible checklist: cách sinh lại dataset, cách lấy SA key, cách chạy dry run, cách chạy import,
  cách rollback bằng `clear-crawl.js`, cách verify count qua Firebase Console.
- Troubleshooting: rules deny (dù SA bypass rules, phòng khi dùng client SDK), batch > 500 limit,
  Firestore 1 MiB document cap (job description quá dài), Chi phí ước tính writes ≈ $0.00018/1000 writes
  × 12256 = $0.002.
- Bổ sung section "Lazy pagination" — mô tả flow:
  - User mở `/viec-lam` → `JobsSearchViewModel` kick off `_resubscribe('', 30)` + `_fetchTotalCount('')`
    → **1 stream 30 doc + 1 count query** (~1 Firestore read cho count aggregation + 30 doc reads).
  - Payload lần đầu ~60KB thay vì ~20MB.
  - User click trang 5 (cần 50 doc) → `setPage(5)` bump `loadedLimit` → 60 → resubscribe → thêm 30 doc.
  - Keyword đổi → reset về 30 + fetch count mới.
  - Pagination widget vẫn thấy totalPages = 980 nhờ `totalCount` server-side.
  - Hạn chế: jump trực tiếp page 500 → bump `loadedLimit` lên 5010 ngay (~5s). Có thể cải tiến bằng
    cursor-based `startAfterDocument` nhưng chưa làm.

## BÁO CÁO ĐỢT 3

Phần "ĐỢT 3" ở cuối `docs/GLM_REPORT.md` — mẫu như trước. Nếu lúc GLM chạy, user đã drop SA JSON và phiên
chính đã chạy import, cập nhật V10 với count THẬT từ Firestore (`firebase firestore:... read` hoặc Console).

---

# ĐỢT 4 — 2026-10-03 (regression test cho 2 bug phiên chính vừa fix)

**Bối cảnh ĐỢT 4:**
Sau khi GLM báo cáo 9 lỗi lib mới ở ĐỢT 3 (mục 11–19 của `GLM_REPORT.md`), phiên chính đã fix **2 bug** sau:
1. **#11 keyword 1 ký tự rớt filter** (`lib/features/jobs/data/jobs_repository.dart`):
   - Thêm helper static `_isUnmatchableKeyword(keyword)` trả `true` khi `keyword.trim().isNotEmpty && tokens.isEmpty`.
   - `watchPublicJobs` và `countPublicJobs` early-return (`Stream.value([])` / `0`) khi unmatchable → user gõ "c" giờ thấy 0 kết quả thay vì 9800.
2. **#14 moderateJob không bọc transaction** (`lib/features/admin/data/admin_repository.dart`):
   - Chuyển sang `_refs.db.runTransaction` giống apply/updateStatus trong `ApplicationsRepository`.
   - Dùng `_refs.db.collection(FirestoreRefs.colNotifications).doc()` + `tx.set(notifRef, notif.toJson())` (NotificationModel inline, không qua `_notifications.create` nữa — field `_notifications` đã remove khỏi `AdminRepository`).
   - Nếu notification fail → job update rollback. Admin retry an toàn.

`flutter analyze` sạch, `flutter test` vẫn 404 pass (chưa thêm test regression). APK rebuild + reinstall đã làm.

## VIỆC 13 — Regression test cho 2 fix trên

Viết `test/features/jobs/jobs_repository_search_test.dart`:
- Test static method `JobsRepository._isUnmatchableKeyword` — nhưng vì nó private, dùng `@visibleForTesting` wrapper nếu cần. Hoặc test gián tiếp qua `_searchTokens` behavior (nếu đã expose).
- Thay vào đó dễ hơn: giả lập `JobModel.tokenize` để chứng minh keyword nào ra `[]`, rồi assert một helper copy-paste logic trong test.
- Minh hoạ các case keyword:
  - `''` → không unmatchable (empty intent, trả cả bộ)
  - `' '` → không unmatchable (sau trim rỗng)
  - `'c'` → **unmatchable** (1 ký tự lọc do `w.length >= 2`)
  - `'ab'` → không unmatchable (tokenize ra `['ab']`)
  - `'& #'` → unmatchable (toàn ký tự lọc bỏ)
  - `'flutter'` → không unmatchable (nhiều token)

Viết `test/features/admin/admin_moderate_job_test.dart`:
- KHÔNG cần Firestore mock (phức tạp). Chỉ cần kiểm tra bằng trace: hàm `moderateJob` phải gọi `runTransaction` 1 lần (không 2 call riêng rẽ update + notify).
- Nếu không mock được, bỏ qua và tạo doc test chi tiết trong `docs/GLM_REPORT.md` thay thế.

## VIỆC 14 — Cập nhật GLM_REPORT.md marking fixed

Trong `docs/GLM_REPORT.md`, phần "Lỗi phát hiện trong lib/":
- Append `**[FIXED 2026-10-03 by phiên chính]**` vào cuối mục 11 (keyword tokens empty) và 14 (moderateJob transaction).
- Thêm note tổng dưới cùng: `**Trạng thái cập nhật:** 2/9 lỗi mới đã fix (#11, #14). Các mục còn lại chờ quyết định user (cosmetic / behavior change).`

## BÁO CÁO ĐỢT 4

Append "ĐỢT 4" vào cuối `GLM_REPORT.md` theo mẫu cũ. Nếu test regression không viết được vì cần Firestore mock,
ghi rõ hạn chế và đề xuất pattern test cho tương lai (ví dụ `fake_cloud_firestore` cần `pubspec` — KHÔNG tự add).

---

# ĐỢT 5 — 2026-10-03 (server-side filter — scope exception)

**Bối cảnh:** Phiên chính đã thử bump `loadedLimit` lên `publicLimit=10000` khi filter active để facet/filter
chạy chuẩn trên 9800 docs → **crash OOM** (heap debug Android ~200MB, logcat
`Throwing OutOfMemoryError "...growth limit 201326592"`). Revert fix tạm, filter giờ chạy client-side trên
loaded chunk (chỉ 30-60 docs). User muốn filter chạy đúng trên toàn 9800 → đẩy filter về Firestore server-side.

## MỞ RỘNG SCOPE CHỈ CHO ĐỢT 5
Ngoài các path mặc định, BẠN ĐƯỢC PHÉP sửa thêm 3 file sau trong ĐỢT 5:
- `lib/features/jobs/data/jobs_repository.dart`
- `lib/features/jobs/viewmodels/jobs_search_viewmodel.dart`
- `firestore.indexes.json`

Và được chạy lệnh:
- `firebase deploy --only firestore:indexes` (sau khi edit indexes nếu cần)

**VẪN CẤM:** mọi file `lib/` khác, `pubspec.yaml`, `firestore.rules`, `firebase deploy --only firestore:rules`,
`flutter pub add`. Nếu phát hiện bug ngoài 3 file trên, chỉ append vào section "Lỗi phát hiện trong lib/" của
`GLM_REPORT.md`.

## VIỆC 15 — Repository: server-side single-facet filter

Trong `JobsRepository`:
1. Mở rộng `watchPublicJobs` + `countPublicJobs` để nhận thêm filter optional:
   ```dart
   Stream<List<JobModel>> watchPublicJobs({
     String keyword = '',
     String? city,
     WorkMode? workMode,
     JobType? jobType,
     int limit = publicLimit,
   })
   Future<int> countPublicJobs({
     String keyword = '',
     String? city,
     WorkMode? workMode,
     JobType? jobType,
   })
   ```
2. Logic chain `.where(...)`:
   - `city != null` → `.where('city', isEqualTo: city)` (field thật đã index — xem `firestore.indexes.json`)
   - `workMode != null` → `.where('workMode', isEqualTo: enumToWire(workMode))`
   - `jobType != null` → `.where('jobType', isEqualTo: enumToWire(jobType))`
3. **KHÔNG được chain nhiều facet cùng lúc** trừ khi index composite tồn tại. Để an toàn: nếu caller truyền
   nhiều hơn 1 facet, chỉ áp dụng facet đầu tiên theo thứ tự `city > workMode > jobType > keyword` và ghi
   `assert()` để caller tránh gọi sai.
4. Keyword + 1 facet: cần index `(titleTokens arrayContains, isApproved, status, <facet>, createdAt DESC)`.
   Check `firestore.indexes.json` xem có không. Nếu không — V17 sẽ thêm.
5. Giữ `_isUnmatchableKeyword` guard early-return cho cả 2 method.

## VIỆC 16 — ViewModel: hoist 1 facet lên Firestore khi khả thi

Trong `JobsSearchViewModel`:
1. Thêm helper `_serverFilter()` trả về `({String? city, WorkMode? workMode, JobType? jobType})`:
   - Nếu `state.filters.cities.length == 1 && filters.workMode.isEmpty && filters.jobType.isEmpty` →
     `(city: state.filters.cities.first, workMode: null, jobType: null)`.
   - Nếu `state.filters.workMode.length == 1 && cities.isEmpty && jobType.isEmpty` → tương tự.
   - Nếu `jobType.length == 1 && cities.isEmpty && workMode.isEmpty` → tương tự.
   - Mọi trường hợp khác (0 facet / multi-facet / salary/category/experience/jobLevel được chọn song song) →
     return `(null, null, null)`.
2. Track `_subscribedFilter` tương tự `_subscribedKeyword`/`_subscribedLimit`. Khi `_serverFilter()` thay đổi
   → resubscribe + refetchCount.
3. `_resubscribe`: nhận thêm `({String? city, WorkMode? workMode, JobType? jobType})` và pass qua repo.
4. `_fetchTotalCount`: tương tự, truyền filter để count match.
5. Khi filter server-side active, `displayTotal` getter vẫn OK vì sourceJobs = subset Firestore trả về
   (ví dụ 2800 Hà Nội), filtered.length == sourceJobs.length (filter khác đã trống).
6. `_desiredLimit()` giữ nguyên (preload 2 pages) — không ép publicLimit nữa.
7. `_reconcileSubscription`: so sánh keyword/limit/serverFilter — resubscribe nếu bất kỳ cái nào thay đổi.

## VIỆC 17 — Firestore indexes

1. Đọc `firestore.indexes.json`. Xác nhận các index sau tồn tại:
   - `(isApproved ASC, status ASC, city ASC, createdAt DESC)` ✓
   - `(isApproved ASC, status ASC, workMode ASC, createdAt DESC)` ✓
   - `(isApproved ASC, status ASC, jobType ASC, createdAt DESC)` ✓
   - `(titleTokens CONTAINS, isApproved ASC, status ASC, createdAt DESC)` ✓
2. Thêm 3 index MỚI nếu chưa có (cho keyword + 1 facet đồng thời):
   - `(titleTokens CONTAINS, isApproved ASC, status ASC, city ASC, createdAt DESC)`
   - `(titleTokens CONTAINS, isApproved ASC, status ASC, workMode ASC, createdAt DESC)`
   - `(titleTokens CONTAINS, isApproved ASC, status ASC, jobType ASC, createdAt DESC)`
3. Chạy `firebase deploy --only firestore:indexes --project jobhub-prm393-g3`. Chờ build xong (~2-5 phút cho
   mỗi index trên 9800 docs).
4. Nếu deploy fail hoặc timeout, báo cáo vào GLM_REPORT.md và dừng (phiên chính can thiệp).

## VIỆC 18 — Verify

1. `flutter analyze` → No issues found.
2. `flutter test` → ≥ 433 pass. Nếu tests cũ fail do signature change, bắt buộc hiểu lý do rồi cập nhật test
   (không bỏ `expect`).
3. Thêm 1 test file mới `test/features/jobs/jobs_server_filter_test.dart` kiểm tra contract (regex scan source
   như V13):
   - `watchPublicJobs` chain `.where('city', ...)` khi `city != null`.
   - Priority order khi caller truyền nhiều facet.
   - `_isUnmatchableKeyword` guard vẫn chạy trước filter chain.
   - `_serverFilter()` trả `(city, null, null)` chỉ khi cities có đúng 1 element VÀ workMode/jobType rỗng.
4. Build APK: `flutter build apk --debug` → không được fail.
5. **KHÔNG chạy emulator / install APK** — phiên chính sẽ làm step này. GLM dừng ở build thành công.

## BÁO CÁO ĐỢT 5

Append "ĐỢT 5" vào `GLM_REPORT.md`:
- Trạng thái từng V15–V18.
- Lệnh `firebase deploy` output (nếu chạy).
- Diff tóm tắt của repo + viewmodel.
- Nếu không thể hoàn thành (ví dụ Firebase CLI chưa login, index deploy fail), ghi rõ và cho phương án fallback.
