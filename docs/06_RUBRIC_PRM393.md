# 06 — RUBRIC TỰ ĐÁNH GIÁ PRM393 (JobHub Flutter)

Đối chiếu từng tiêu chí giảng viên → hiện thực trong code → trạng thái → bằng chứng `file:line`.
Mọi số liệu dưới đây đã được đếm/grep/read lại trực tiếp trên working tree **ngày 03/10/2026** trước khi ghi (không sao chép nguyên số liệu từ tài liệu cũ). Trạng thái: ✅ đạt — ⚠️ đạt một phần / có lưu ý — ❌ chưa đạt.

Chú thích cách đếm các số "khớp/không khớp dịp trước":
- `firestore.rules` thực tế có **11** helper function (đếm `function ...(`, dòng 6–16), không phải 10 như ghi chú dịp trước.
- Test suite đang được bổ sung song song trong ngày 03/10/2026: lúc bắt đầu buổi viết có 12 file test; lần chạy giữa buổi **+397 −7 (Some tests failed)** vì 2 file test mới vừa thêm; lần chạy chốt **`+404: All tests passed!`** với **14 file test**. Con số ghi trong bảng dưới là số của lần chạy chốt.

---

## 1. Firebase Auth — đăng nhập / đăng ký / logout / ghi nhớ đăng nhập

| Tiêu chí | Hiện thực | Trạng thái | Bằng chứng (file:line) |
|---|---|---|---|
| Đăng nhập Email/Password | `AuthService.signIn` — chuẩn hoá email, chặn tài khoản `isActive == false` (403 ACCOUNT_DISABLED) | ✅ | `lib/core/services/auth_service.dart:28-42` |
| Đăng ký (job_seeker / employer) | `AuthService.register` — cấm tự đăng ký admin, whitelist email thành admin, bootstrap doc `users/{uid}` đầy đủ trường | ✅ | `lib/core/services/auth_service.dart:44-78` |
| Đăng xuất | `signOut` gỡ FCM token của thiết bị khỏi `users/{uid}.fcmTokens` trước khi `signOut()` | ✅ | `lib/core/services/auth_service.dart:106-113`; `lib/core/services/fcm_service.dart:142-157` |
| Ghi nhớ đăng nhập (remember-me) | 2 lớp: (a) AuthRepository lưu `PrefsService.rememberEmail`/`rememberMe` + đặt persistence LOCAL/SESSION (web); (b) login page nạp email đã lưu và có checkbox | ✅ | `lib/features/auth/data/auth_repository.dart:66-76`; `lib/core/services/prefs_service.dart:48-54`; `lib/features/auth/views/login_page.dart:32,37,128-130` |
| Quên mật khẩu / đổi mật khẩu | `sendPasswordReset`, `changePassword` (re-authenticate rồi update) | ✅ | `lib/core/services/auth_service.dart:80-86,89-102` |
| Role guard router | Redirect theo `authStateProvider` + role từ `users/{uid}`; sai vai trò → `/403` | ✅ | `lib/core/router/app_router.dart` (redirect + `_requiredRoles`) |

Giải thích: lớp service mỏng bọc FirebaseAuth (tương đương `AuthService.js` của bản web), mọi luồng đăng nhập/đăng ký/quên-đổi mật khẩu/đăng xuất đều đi qua `AuthService` + `AuthRepository`; remember-me tôn trọng checkbox trên cả web (persistence) lẫn mobile (nhớ email qua SharedPreferences).

---

## 2. Notification (FCM + local notifications)

| Tiêu chí | Hiện thực | Trạng thái | Bằng chứng (file:line) |
|---|---|---|---|
| Kênh Android mặc định | Channel id `jobhub_default`, Importance.high, mô tả tiếng Việt | ✅ | `lib/core/services/fcm_service.dart:53-58` |
| Meta-data channel trùng khớp | `com.google.firebase.messaging.default_notification_channel_id = jobhub_default` | ✅ | `android/app/src/main/AndroidManifest.xml:36-38` |
| Quyền thông báo Android 13+ | `uses-permission POST_NOTIFICATIONS` | ✅ | `android/app/src/main/AndroidManifest.xml:3` |
| Foreground (app đang mở) | `FirebaseMessaging.onMessage` → `_showForeground` hiển thị local notification, tôn trọng toggle Settings + toggle theo type | ✅ | `lib/core/services/fcm_service.dart:94,159-184` |
| Background/terminated (web) | Service worker `onBackgroundMessage` hiện thông báo; `notificationclick` mở deep-link theo `data` | ✅ | `web/firebase-messaging-sw.js:17-25,27-35` |
| Quản lý token | `refreshToken`/`persistToken` ghi `arrayUnion` vào `users/{uid}.fcmTokens`; `onTokenRefresh` tự đồng bộ; đăng xuất thì `arrayRemove` | ✅ | `lib/core/services/fcm_service.dart:103-104,121-140` |
| Đăng ký/gỡ token theo Settings | `fcmTokenRegistrationProvider` watch `notificationsEnabled` → register/unregister | ✅ | `lib/features/notifications/viewmodels/notifications_providers.dart:60-72` |
| Trung tâm thông báo realtime (MVVM đủ lớp) | Stream 50 thông báo mới nhất, badge chưa đọc, đánh dấu đọc/xóa, deep-link khi tap | ✅ | `lib/features/notifications/viewmodels/notifications_providers.dart:15-26,87-122`; `lib/features/notifications/views/notifications_page.dart`; `lib/features/notifications/widgets/notification_navigator.dart` |

Giải thích: đúng yêu cầu "Notification" — có channel riêng, đủ 3 nhánh foreground/background/cold-start (`getInitialMessage` + buffer `takePendingTap` tại `lib/core/services/fcm_service.dart:38-51,98-101`), và feature notifications là một MVVM module hoàn chỉnh.

---

## 3. Kiến trúc MVVM

| Tiêu chí | Hiện thực | Trạng thái | Bằng chứng (file:line) |
|---|---|---|---|
| Quy ước 4 lớp / feature | Mỗi feature gồm `data/` (repository) — `viewmodels/` (Riverpod) — `views/` (page) — `widgets/` | ✅ | Thư mục `lib/features/jobs/`, `lib/features/applications/`, `lib/features/notifications/`, `lib/features/employer/`, `lib/features/home/` (đã `ls` từng thư mục) |
| Ví dụ 1 — jobs | data: `jobs_repository.dart` (provider ở dòng 217); viewmodels: `jobs_search_viewmodel.dart` (StateNotifierProvider dòng 676); views: `jobs_search_page.dart` | ✅ | `lib/features/jobs/data/jobs_repository.dart:217`; `lib/features/jobs/viewmodels/jobs_search_viewmodel.dart:676`; `lib/features/jobs/views/jobs_search_page.dart` |
| Ví dụ 2 — applications | data: `applications_repository.dart` (provider dòng 409); viewmodels: `applications_providers.dart` (StreamProvider dòng 74) + `apply_viewmodel.dart` + `review_viewmodel.dart`; views: `my_applications_page.dart`, `apply_job_page.dart`… | ✅ | `lib/features/applications/data/applications_repository.dart:409`; `lib/features/applications/viewmodels/applications_providers.dart:74`; `lib/features/applications/views/` |
| Ví dụ 3 — notifications | data: `notifications_repository.dart` (provider dòng 141); viewmodels: `notifications_providers.dart` (StreamProvider dòng 15); views: `notifications_page.dart` | ✅ | `lib/features/notifications/data/notifications_repository.dart:141`; `lib/features/notifications/viewmodels/notifications_providers.dart:15`; `lib/features/notifications/views/notifications_page.dart:31` |

Giải thích: 12 feature (`admin, applications, auth, chat, employer, home, jobs, notifications, profile, recommendations, settings, splash`) đều theo đúng khung `data/viewmodels/views/widgets`; model dùng chung ở `lib/shared/models/`, widget dùng chung ở `lib/shared/widgets/`.

---

## 4. Riverpod (state management)

| Tiêu chí | Hiện thực | Trạng thái | Bằng chứng (file:line) |
|---|---|---|---|
| Dependency | `flutter_riverpod: ^2.5.1`, khai báo provider thủ công (không codegen) | ✅ | `pubspec.yaml:15` |
| `StateNotifierProvider` | `settingsProvider = StateNotifierProvider<SettingsViewModel, SettingsState>` | ✅ | `lib/features/settings/viewmodels/settings_viewmodel.dart:189` |
| `StreamProvider` | `notificationsStreamProvider = StreamProvider<List<NotificationModel>>` | ✅ | `lib/features/notifications/viewmodels/notifications_providers.dart:15` |
| `Provider` | `firebaseAuthProvider = Provider<FirebaseAuth>` | ✅ | `lib/core/providers.dart:18` |
| `FutureProvider` | `applyJobProvider = FutureProvider.autoDispose.family<JobModel?, String>`; `maxSkillsPerJobProvider = FutureProvider.autoDispose<int>` | ✅ | `lib/features/applications/viewmodels/applications_providers.dart:186`; `lib/features/employer/viewmodels/employer_providers.dart:58` |
| `StateProvider` | `notificationFilterProvider = StateProvider.autoDispose<NotificationFilter>` | ✅ | `lib/features/notifications/viewmodels/notifications_providers.dart:39` |
| Modifier `autoDispose` / `family` | Dùng rộng rãi (chat, jobs, profile, employer…) | ✅ | `lib/features/chat/viewmodels/chat_providers.dart:28` (`.autoDispose.family`), `:97`; `lib/features/jobs/viewmodels/job_detail_providers.dart:8` |

Giải thích: đủ 5 loại provider yêu cầu (StateNotifierProvider, StreamProvider, Provider, FutureProvider, StateProvider) kèm modifier autoDispose/family; tổng cộng 32+ file provider/viewmodel trên 11 feature (chi tiết danh sách ở `docs/02_YEU_CAU_GIAO_VIEN.md` §4.2).

---

## 5. Firestore

| Tiêu chí | Hiện thực | Trạng thái | Bằng chứng (file:line) |
|---|---|---|---|
| Typed collection references | `FirestoreRefs` có **18 method** trả về `CollectionReference<T>` với `withConverter`: **14 collection** (users, jobSeekerProfiles, employerProfiles, categories, skills, jobs, applications, resumes, jobRecommendations, savedJobs, notifications, aiMatchingLogs, systemConfigurations, chats) + **4 subcollection** (statusHistory, aiAnalyses, messages, aiSessions) | ✅ | `lib/core/services/firestore_refs.dart:52-130` (sub: `:73,87,114,123`) |
| Security rules | `firestore.rules` phân quyền theo role đọc từ `users/{uid}.role` + `isActive`; **11 helper function** (`signedIn, uid, userDoc, userExists, role, active, isAdmin, isEmployer, isSeeker, isOwner, onlyKeys` — grep `function \w+\(`); statusHistory & messages append-only; employer không tự duyệt tin | ✅ | `firestore.rules:6-16` (helpers), `:62-83` (jobs), `:103-114` (statusHistory), `:187-194` (messages) |
| Composite indexes | `firestore.indexes.json` có **36 index trên 13 collection group** (đếm trực tiếp: jobs 10, applications 9, statusHistory 1, notifications 2, resumes 2, aiAnalyses 1, savedJobs 1, jobRecommendations 2, aiMatchingLogs 2, chats 1, users 2, employerProfiles 2, aiSessions 1) | ✅ | `firestore.indexes.json:3-140` |
| Mapping 18 bảng SQL → Firestore | 18 bảng của schema web ánh xạ sang collection/subcollection/mảng nhúng | ✅ | Bảng chi tiết `docs/02_YEU_CAU_GIAO_VIEN.md` §5.4; hằng số collection `lib/core/services/firestore_refs.dart:23-40` |
| Dữ liệu thật trong project | Đã import **9.800 jobs** + **2.456 employerProfiles** (`source='crawl'`, isApproved + OPEN) vào project `jobhub-prm393-g3` | ✅ (theo tài liệu import; không truy vấn lại Firestore từ máy này) | `docs/10_CRAWL_DATASET.md:12,15,20-21`; `docs/TASKS_FOR_GLM.md:263` |

Giải thích: 3 trụ cột Firestore (refs typed + rules + indexes) khớp nhau — tên collection trong `FirestoreRefs` là nguồn chân lý duy nhất cho rules/indexes. Số liệu import lấy từ tài liệu đợt crawl (cùng ghi chú 2.932 tên công ty dedupe còn 2.456 uid sau slug 40 ký tự).

---

## 6. SharedPreferences

| Tiêu chí | Hiện thực | Trạng thái | Bằng chứng (file:line) |
|---|---|---|---|
| Wrapper riêng | `PrefsService` singleton, `init()` ở bootstrap với retry + fallback in-memory | ✅ | `lib/core/services/prefs_service.dart:9-26`; `lib/main.dart:30-46` |
| Đủ 12 key cục bộ | `theme_mode, locale, remember_email, remember_me, last_role, notifications_enabled, notification_types, onboarding_done, fcm_token, last_search_keywords, job_draft, cached_user` (đếm trực tiếp 12 hằng số `_k...`) | ✅ | `lib/core/services/prefs_service.dart:28-39` |
| Store phiên AI riêng | `AiSessionStore` cap 20 phiên (`AppConfig.aiSessionCap`) | ✅ | `lib/core/services/ai_session_store.dart`; `lib/core/config/app_config.dart` |

Giải thích: 12 key gom thành 10 nhóm chức năng (theme, locale, remember, role, notification ×2, onboarding, FCM token, từ khóa tìm kiếm, nháp tin, cache user offline).

---

## 7. Dark mode

| Tiêu chí | Hiện thực | Trạng thái | Bằng chứng (file:line) |
|---|---|---|---|
| Chuyển theme trong Settings | RadioGroup 3 chế độ: Theo hệ thống / Sáng / Tối | ✅ | `lib/features/settings/views/settings_page.dart:51-78` |
| Áp dụng toàn app | `MaterialApp.router` nhận `themeMode: settings.themeMode` + `theme`/`darkTheme` | ✅ | `lib/app.dart:76-78` |
| Persist qua SharedPreferences | `setThemeMode` ghi chuỗi `light/dark/null` vào key `theme_mode`; khởi động đọc lại | ✅ | `lib/features/settings/viewmodels/settings_viewmodel.dart:94-96,175-185`; `lib/core/services/prefs_service.dart:41-43` |

Giải thích: dark mode đầy đủ chu trình UI → state → persist → áp dụng lại khi khởi động.

---

## 8. Multi-language (đa ngôn ngữ)

| Tiêu chí | Hiện thực | Trạng thái | Bằng chứng (file:line) |
|---|---|---|---|
| Hạ tầng framework l10n | `localizationsDelegates` (Global Material/Widgets/Cupertino), `supportedLocales` vi/en, `locale` từ Settings | ✅ | `lib/app.dart:79-85`; `lib/core/config/app_config.dart:10` (`['vi','en']`); `pubspec.yaml:52,58` (`intl`, `flutter_localizations`) |
| Toggle ngôn ngữ trong Settings | Radio Tiếng Việt / English, persist key `locale` | ✅ | `lib/features/settings/views/settings_page.dart:82-115`; `lib/core/services/prefs_service.dart:45-46` |
| Chuỗi UI đa ngôn ngữ (gen-l10n/arb) | **Chưa làm**: không có `l10n.yaml`, không có `lib/l10n/`, không bật `generate: true`; toàn bộ copy app hard-code tiếng Việt (UI tự ghi chú trung thực điều này ngay trong Settings) | ❌ | Đã kiểm tra: `l10n.yaml` + `lib/l10n/` không tồn tại; `pubspec.yaml` không có mục `generate:`; chú thích tại `lib/features/settings/views/settings_page.dart:107-113` |

Giải thích: phần đã có là "khung" (locale switching ảnh hưởng tới lịch, hộp thoại, định dạng ngày/số của Material). Phần còn thiếu là bản dịch nội dung app. Cách bổ sung: tạo `l10n.yaml` + `lib/l10n/app_vi.arb` / `app_en.arb`, chạy `flutter gen-l10n`, thay dần chuỗi hard-code — danh sách chờ đã có sẵn trong `docs/09_LOCALIZATION_AUDIT.md` (**1.254 chuỗi UI duy nhất**, 1.743 lượt xuất hiện; số liệu tại `docs/09_LOCALIZATION_AUDIT.md:9`).

---

## 9. Responsive (web ≥1024 / tablet / mobile)

| Tiêu chí | Hiện thực | Trạng thái | Bằng chứng (file:line) |
|---|---|---|---|
| Breakpoint chuẩn 1024 | `kBpLg = 1024` dùng chung cho layout applications; navbar/footer/section đổi theo `width >= 1024` | ✅ | `lib/features/applications/widgets/applications_common.dart:9,310`; `lib/shared/widgets/web_footer.dart:48`; `lib/shared/widgets/section.dart:15`; `lib/shared/widgets/web_navbar.dart:32` |
| Grid responsive theo constraints | `ResponsiveGrid` (LayoutBuilder + số cột theo `maxWidth`: 900→3, 600→2, còn lại 1), mỗi row `IntrinsicHeight` | ✅ | `lib/features/home/widgets/home_layout_helpers.dart:11,20-65` |
| Master-detail / 2 cột theo màn | Chat: `isWide = MediaQuery.sizeOf(context).width >= 1024` → khung master-detail; trang settings/notifications tương tự | ✅ | `lib/features/chat/views/chat_room_page.dart:22`; `lib/features/chat/widgets/chat_thread_list.dart:79`; `lib/features/settings/views/settings_page.dart:44`; `lib/features/notifications/views/notifications_page.dart:31` |
| Breakpoint trung gian | 640 (padding section, cột lưới), 768 (AI matching sheet), 480 (recommendations) | ✅ | `lib/features/home/widgets/home_layout_helpers.dart:7-8`; `lib/features/recommendations/widgets/ai_matching_sheet.dart:33`; `lib/features/recommendations/widgets/recommendations_shell.dart:47` |
| Auth shell / public layout 2 cột | `isWide = width >= 1024` rồi `LayoutBuilder` chia cột | ✅ | `lib/shared/widgets/auth_shell.dart:33,46`; `lib/shared/widgets/public_layout.dart:60-66` |

Giải thích: hệ breakpoint nhất quán mirror bản web Tailwind (`sm:640`, `lg:1024`); grep `1024|LayoutBuilder|MediaQuery` trên `lib/` cho 50+ vị trí sử dụng thật.

---

## 10. Unit test (đề yêu cầu ≥ 50)

| Tiêu chí | Hiện thực | Trạng thái | Bằng chứng |
|---|---|---|---|
| Số lượng test | **404 test, tất cả pass** (`flutter test` → `00:04 +404: All tests passed!`, verify lần chốt 03/10/2026) — gấp ~8 lần yêu cầu ≥50 | ✅ | Output `flutter test` trên máy |
| Số file test | **14 file** (đang được bổ sung song song trong ngày; ghi số lúc chốt) | ✅ | `find test -name "*_test.dart" \| wc -l` → 14 |
| Phủ dụng cụ | Validators, formatters, model JSON round-trip, PrefsService, AiSessionStore, RuleBasedScorer (AI fallback), Failure mapping, contract search tokens, repository merge-mock, widget smoke | ✅ | Danh sách dưới |

Danh sách 14 file test:
1. `test/widget_test.dart`
2. `test/core/ai_session_store_test.dart`
3. `test/core/demo_data_test.dart`
4. `test/core/failure_test.dart`
5. `test/core/formatters_test.dart`
6. `test/core/prefs_service_test.dart`
7. `test/core/rule_based_scorer_test.dart`
8. `test/core/validators_test.dart`
9. `test/features/jobs/jobs_merge_mocks_test.dart`
10. `test/features/jobs/jobs_search_state_test.dart`
11. `test/features/jobs/jobs_search_tokens_contract_test.dart`
12. `test/shared/application_model_test.dart`
13. `test/shared/job_model_test.dart`
14. `test/shared/notification_model_test.dart`

Giải thích: chủ yếu là unit test tầng core/model + vài test logic viewmodel (search state) và repository (merge mocks); chưa có integration test chạy app thật với Firebase emulator — ghi nhận ở mục ⚠️.

---

## 11. Đa thành viên (5 TV × ≥3 màn hình medium trở lên)

| Tiêu chí | Hiện thực | Trạng thái | Bằng chứng |
|---|---|---|---|
| 5 thành viên, mỗi người ≥3 màn medium+ | Bảng phân công 41/41 route: TV1 10 màn (6 medium, 2 hard), TV2 5 (3 medium, 2 hard), TV3 6 (1 medium, 5 hard), TV4 8 (1 medium, 7 hard), TV5 12 (2 medium, 10 hard) | ✅ | `docs/01_PHAN_CONG.md:83-92` (bảng thống kê), bảng chi tiết từng TV `:11-77` |

Giải thích: mọi route của router đều được gán; mỗi TV đều ≥3 màn mức medium trở lên (tối thiểu là TV2 với 5 màn).

---

## BẢNG TỔNG HỢP TỰ ĐÁNH GIÁ

| # | Tiêu chí | Trạng thái | Ghi chú |
|---|---|---|---|
| 1 | Firebase Auth (đăng nhập/đăng ký/logout/remember-me/guard) | ✅ | Đủ luồng, có chặn tài khoản bị vô hiệu |
| 2 | Notification (FCM channel/foreground/background/token) | ✅ | Channel `jobhub_default` khớp manifest ↔ service |
| 3 | MVVM (data/viewmodels/views/widgets) | ✅ | 12 feature đồng bộ khung |
| 4 | Riverpod (5 loại provider) | ✅ | SN + Stream + Provider + Future + State (+ autoDispose/family) |
| 5 | Firestore (18 refs / rules / 36 indexes) | ✅ | Rules 11 helper; dữ liệu thật 9.800 jobs + 2.456 employers |
| 6 | SharedPreferences (12 key) | ✅ | + AiSessionStore cap 20 |
| 7 | Dark mode | ✅ | Persist qua `theme_mode` |
| 8 | Multi-language | ⚠️/❌ | Khung locale có; **chuỗi UI chưa chuyển arb** (1.254 chuỗi chờ) |
| 9 | Responsive | ✅ | Breakpoint 1024/768/640/480 nhất quán |
| 10 | Unit test ≥50 | ✅ | 404/404 pass, 14 file |
| 11 | Đa thành viên 5 TV × ≥3 màn | ✅ | 41/41 route được gán |

Tự đánh giá tổng quan: 10/11 tiêu chí ✅; 1 tiêu chí chưa hoàn chỉnh (multi-language — ❌ ở phần chuỗi UI, hạ tầng ✅).

---

## DANH SÁCH MỤC ⚠️ / ❌ (trung thực, không tô hồng)

1. **❌ Multi-language — chuỗi UI chưa đa ngôn ngữ.** Có locale switch + delegates + persist, nhưng không có `l10n.yaml`/arb/`gen-l10n`; app copy chỉ tiếng Việt. UI đã tự ghi chú điều này cho người dùng (`lib/features/settings/views/settings_page.dart:110-113`). Việc cần làm: `flutter gen-l10n` + 2 file arb + thay 1.254 chuỗi (theo `docs/09_LOCALIZATION_AUDIT.md:9`).
2. **⚠️ Kiểm thử còn tập trung unit/model.** 404 test pass nhưng chưa có integration test (Firebase emulator) và rất ít widget test (1 smoke); các view/page chủ yếu chưa có test riêng.
3. **⚠️ Số liệu test thay đổi trong ngày 03/10/2026** do bổ sung test song song: 12 file → 14 file; một lần chạy giữa buổi từng **+397 −7** (2 file test mới), lần chốt đã **+404 all passed**. Nếu nộp bài, chạy lại `flutter test` ngay trước khi chốt để lấy số cuối.
4. **⚠️ Số liệu dữ liệu Firestore (9.800 jobs / 2.456 employerProfiles) trích từ tài liệu import** (`docs/10_CRAWL_DATASET.md`), không truy vấn lại trực tiếp từ Firestore khi viết rubric này.
5. **⚠️ Ghi nhận sai lệch số liệu dịp trước:** `firestore.rules` thực tế **11** helper function (không phải 10). Các số khác (18 method FirestoreRefs, 36 index/13 collection, 12 key PrefsService) đếm lại đúng như dịp trước.

---

*Rubric sinh bằng cách đọc trực tiếp working tree ngày 03/10/2026 — mọi đường dẫn `file:line` đã được mở/grep xác nhận tại thời điểm viết.*
