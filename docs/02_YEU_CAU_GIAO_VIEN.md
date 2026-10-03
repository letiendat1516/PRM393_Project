# 02 — YÊU CẦU GIÁO VIÊN → ÁNH XẠ HIỆN THỰC

Tài liệu đối chiếu từng yêu cầu bắt buộc của giáo viên với phần đã hiện thực trong project Flutter **JobHub PRM393** (port từ web JobHub sang Firebase Auth + Firestore + FCM, kiến trúc MVVM, quản lý state Riverpod 2.x, lưu cục bộ SharedPreferences).

Mọi đường dẫn bên dưới là đường dẫn thật trong project, tính từ thư mục gốc `C:/Users/dat/AndroidStudioProjects/jobhub_prm393/`.

## Bảng ánh xạ tổng quát

| # | Yêu cầu | Hiện thực | File / class cụ thể |
|---|----------|-----------|---------------------|
| 1 | **Firebase đăng nhập** | `firebase_auth` Email/Password; đăng nhập/đăng ký 2 vai trò, quên mật khẩu, đổi mật khẩu, ghi nhớ đăng nhập; guard phân vai trong router | `lib/core/services/auth_service.dart` (`AuthService`), `lib/features/auth/` (views + viewmodels + `data/auth_repository.dart`), `lib/core/providers.dart` (`authServiceProvider`, `authStateProvider`), `lib/core/router/app_router.dart` (`redirect` + `_requiredRoles`) |
| 2 | **Notification** | FCM (`firebase_messaging`) + `flutter_local_notifications`; channel `jobhub_default`; quyền `POST_NOTIFICATIONS`; service worker web; Trung tâm thông báo realtime | `lib/core/services/fcm_service.dart` (`FcmService.initialize`), `lib/features/notifications/` (repository + providers + views), `web/firebase-messaging-sw.js`, `android/app/src/main/AndroidManifest.xml` |
| 3 | **MVVM** | Mỗi feature tách `data/` (repository) — `viewmodels/` (Riverpod StateNotifier/provider) — `views/` (page) — `widgets/` | `lib/features/<feature>/{data,viewmodels,views,widgets}`; ví dụ `lib/features/applications/`, `lib/features/employer/` |
| 4 | **Riverpod** | `flutter_riverpod ^2.5.1`, khai báo provider thủ công (không codegen); đủ các loại `StreamProvider` / `StateNotifierProvider` / `FutureProvider` / `StateProvider` / `Provider` | `lib/core/providers.dart` + 32 file provider/viewmodel trong `lib/features/*/viewmodels/` |
| 5 | **Firestore** | 18 bảng SQL của JobHub chuyển thành typed collections + subcollections; bảo mật bằng `firestore.rules`; 36 composite index trong `firestore.indexes.json` | `lib/core/services/firestore_refs.dart` (`FirestoreRefs`), `firestore.rules`, `firestore.indexes.json`, models trong `lib/shared/models/` |
| 6 | **SharedPreferences** | Wrapper `PrefsService` đủ 12 key cục bộ gom thành 10 nhóm (theme, locale, remember, role, notification, onboarding, FCM token, từ khóa tìm kiếm, nháp tin, cache user); store phiên AI giới hạn 20 | `lib/core/services/prefs_service.dart` (`PrefsService`), `lib/core/services/ai_session_store.dart` (`AiSessionStore`, cap = `AppConfig.aiSessionCap = 20`) |

---

## 1. Firebase đăng nhập

### 1.1. Lớp service — `lib/core/services/auth_service.dart`

Class `AuthService` — wrapper mỏng trên `FirebaseAuth` + bootstrap document `users/{uid}` (tương đương `AuthService.js` của backend web). Các method thật trong file:

| Method (trích từ file) | Chức năng |
|---|---|
| `Future<UserCredential> signIn({required String email, required String password})` | Đăng nhập Email/Password; kiểm tra `users/{uid}.isActive == false` → `signOut()` + ném `Failure` mã `ACCOUNT_DISABLED` (403, tương đương web) |
| `Future<UserCredential> register({required String email, required String password, required String fullName, required String role, Map<String, dynamic> extra})` | `createUserWithEmailAndPassword` + ghi document `users/{uid}` (uid, email, fullName, role, isActive, isVerified, fcmTokens, createdAt, updatedAt); từ chối tự đăng ký `admin`; email trong whitelist `AppConfig.adminEmails` được nâng lên admin |
| `Future<void> sendPasswordReset(String email)` | Gửi email đặt lại mật khẩu (`sendPasswordResetEmail`) |
| `Future<void> changePassword({required String currentPassword, required String newPassword})` | UC26 — re-authenticate bằng `EmailAuthProvider.credential` rồi `updatePassword`; sai mật khẩu hiện tại → `Failure` mã `WRONG_PASSWORD` |
| `Future<void> setRememberMe(bool remember)` | "Ghi nhớ đăng nhập": `Persistence.LOCAL` vs `Persistence.SESSION` (web) |
| `Future<void> signOut()` | Gỡ FCM token của thiết bị khỏi `users/{uid}.fcmTokens` (qua `FcmService.instance.removeTokenForCurrentUser()`) rồi `signOut()` |
| `Stream<User?> authStateChanges()` / `User? get currentUser` | Theo dõi phiên đăng nhập |

### 1.2. Feature `lib/features/auth/` (đủ views + viewmodels + data)

| Lớp | File thật (Glob kiểm chứng) |
|---|---|
| View — đăng nhập | `lib/features/auth/views/login_page.dart` |
| View — đăng ký job seeker | `lib/features/auth/views/register_page.dart` |
| View — đăng ký nhà tuyển dụng | `lib/features/auth/views/register_employer_page.dart` |
| View — quên mật khẩu | `lib/features/auth/views/forgot_password_page.dart` |
| View — onboarding lần đầu | `lib/features/auth/views/onboarding_page.dart` |
| Viewmodel | `lib/features/auth/viewmodels/login_viewmodel.dart` (`LoginViewModel extends StateNotifier<LoginState>` + `loginViewModelProvider`), `register_viewmodel.dart` (`RegisterViewModel` + `registerViewModelProvider`), `forgot_password_viewmodel.dart` (`ForgotPasswordViewModel` + `forgotPasswordViewModelProvider`) |
| Data — repository | `lib/features/auth/data/auth_repository.dart` — **tồn tại** (đã Glob kiểm chứng). Class `AuthRepository` gồm: `login({email, password, rememberMe})`, `registerJobSeeker(...)`, `registerEmployer(...)` (ghi thêm `jobSeekerProfiles/{uid}` / `employerProfiles/{uid}`), `sendPasswordReset`, `changePassword`, `signOut`, `watchCurrentUser(uid)` / `watchPrincipal(uid)` (stream `users/{uid}` với `includeMetadataChanges`), `fetchUser(uid)`, `_rollbackRegistration` (xoá tài khoản Auth nếu ghi profile thất bại); kèm `authBootstrappingProvider` (StateProvider) và `authRepositoryProvider` |
| Principal sống | `lib/features/auth/viewmodels/current_user_provider.dart` — `currentUserProvider` (`StreamProvider<UserModel?>`, tương đương `AuthContext.jsx`, có offline fallback từ `PrefsService.cachedUser`) và `currentUidProvider` |

### 1.3. Provider tầng core — `lib/core/providers.dart`

- `final authServiceProvider = Provider<AuthService>(...)` — tạo `AuthService` từ `firebaseAuthProvider` + `firestoreProvider`.
- `final authStateProvider = StreamProvider<User?>((ref) => ref.watch(authServiceProvider).authStateChanges())` — trạng thái đăng nhập Firebase dạng stream.

### 1.4. Role guard — `lib/core/router/app_router.dart`

Cơ chế guard trong `routerProvider` (GoRouter, mirror `RoleGuard.jsx` + `utils/redirectByRole.js` của web):

- `redirect:` đọc `authStateProvider` (đăng nhập hay chưa) và `currentUserProvider` (role từ `users/{uid}`).
- Lần đầu mở app (`prefs.isFirstLaunch` && chưa đăng nhập && đang ở `/`) → chuyển `AppRoutes.onboarding`.
- Đã đăng nhập mà vào trang auth (`login` / `register` / `registerEmployer` / `forgotPassword`) → chuyển `NavItems.homeFor(role)` theo vai trò.
- Hàm `Set<UserRole>? _requiredRoles(String loc)` khai báo tập vai trò cho từng vùng route: `/admin...` → `{admin}`; `/employer/applications...` → `{employer, admin}`; `/employer...` → `{employer}`; hồ sơ/ứng tuyển/saved jobs → `{jobSeeker}`; notifications/chats/settings → cả 3 vai trò; còn lại public.
- Chưa đăng nhập → `AppRoutes.login`; sai vai trò → `AppRoutes.forbidden` (trang 403); `users/{uid}` lỗi/mất → coi như đã sign out.
- `_AuthRefresh` (ChangeNotifier) lắng nghe `authStateProvider` + `currentUserProvider` để GoRouter tự re-evaluate redirect khi phiên đổi. Route constants nằm ở `lib/core/router/routes.dart` (`AppRoutes`).

---

## 2. Notification (FCM + local notifications)

### 2.1. `lib/core/services/fcm_service.dart` — class `FcmService` (singleton `FcmService.instance`)

| Thành phần (trích từ file) | Chi tiết |
|---|---|
| `Future<void> initialize()` | Xin quyền `messaging.requestPermission(alert, badge, sound)`; khởi tạo `flutter_local_notifications` (Android `@mipmap/ic_launcher`, iOS Darwin); đăng ký `FirebaseMessaging.onMessage` → `_showForeground`, `onMessageOpenedApp` + `getInitialMessage()` → phát sự kiện tap; `onTokenRefresh` → `persistToken`. Được gọi tại `lib/core/config/firebase_bootstrap.dart` (`await FcmService.instance.initialize();`) |
| `static const channel = AndroidNotificationChannel('jobhub_default', 'JobHub notifications', ...)` | Kênh Android mặc định, `Importance.high`, mô tả tiếng Việt "Thông báo từ JobHub (hồ sơ ứng tuyển, tin tuyển dụng, hệ thống)." |
| `Future<void> refreshToken()` / `persistToken(String? token)` | Lấy token (web cần `vapidKey` từ `--dart-define=FCM_VAPID_KEY`), cache vào `PrefsService.setFcmToken` và ghi `FieldValue.arrayUnion([token])` vào `users/{uid}.fcmTokens`; tôn trọng ngưỡng `notificationsEnabled` trong Settings |
| `Future<void> removeTokenForCurrentUser()` | `arrayRemove` token khi đăng xuất |
| `Future<void> showLocal({required String title, required String body, Map<String, dynamic> data})` | Local notification cho sự kiện in-app (chỉ mobile) |
| `Stream<Map<String, dynamic>> get onNotificationTap` + `takePendingTap()` | Nguồn sự kiện tap duy nhất cho `NotificationNavigator` (`lib/features/notifications/widgets/notification_navigator.dart`) |

### 2.2. Feature `lib/features/notifications/`

| Lớp | File | Dẫn chứng |
|---|---|---|
| Data | `lib/features/notifications/data/notifications_repository.dart` | `NotificationsRepository.create({required String recipientId, required UserRole recipientRole, required NotificationType type, required String title, required String message, Map<String, dynamic> data})` — ghi document vào `_refs.notifications()`; ngoài ra `watchForUser(uid, {limit = 50})` (stream mới nhất trước), `markAsRead(notificationId)`, `markAllAsRead(uid)` (batch chunk 450 bản ghi/lô), `registerFcmToken(uid)`, `unregisterFcmToken(uid)`; provider `notificationsRepositoryProvider` |
| Viewmodels | `lib/features/notifications/viewmodels/notifications_providers.dart` | `notificationsStreamProvider = StreamProvider<List<NotificationModel>>` (stream live theo uid), `unreadCountProvider = Provider<int>` (đếm `!isRead` làm badge), `notificationFilterProvider` (StateProvider tab Tất cả/Chưa đọc), `filteredNotificationsProvider`, `fcmTokenRegistrationProvider` (tự đăng ký/gỡ token theo Settings), `NotificationsController extends StateNotifier<NotificationsActionState>` + `notificationsControllerProvider` |
| Views | `lib/features/notifications/views/notifications_page.dart` | Trung tâm thông báo — `ref.watch(notificationsStreamProvider)`, `ref.watch(filteredNotificationsProvider)`, `ref.watch(unreadCountProvider)`, `ref.watch(notificationsControllerProvider)` |
| Widgets | `lib/features/notifications/widgets/` | `notification_navigator.dart` (điều hướng deep-link khi tap notification), `notification_tile.dart`, `notification_type_meta.dart`, `notifications_summary_panel.dart` |

### 2.3. Web service worker — `web/firebase-messaging-sw.js`

Import `firebase-app-compat.js` + `firebase-messaging-compat.js` (10.12.0), khởi tạo app Firebase (project `jobhub-prm393-g3`, cấu hình khớp `lib/firebase_options.dart`), rồi: `messaging.onBackgroundMessage` hiển thị thông báo nền (`showNotification` với icon `/icons/Icon-192.png`); listener `notificationclick` mở deep-link theo `data`: `type === 'APPLICATION_STATUS'` → `/applications/{applicationId}`, applicationId của employer → `/employer/applications/{applicationId}`, `JOB_APPROVED`/`JOB_REJECTED` → `/employer/jobs`.

### 2.4. `android/app/src/main/AndroidManifest.xml`

Trích đúng trong file:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
...
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="jobhub_default" />
```

Meta-data channel khớp đúng channel id `jobhub_default` của `FcmService.channel`. Không khai báo service FCM riêng — plugin `firebase_messaging` tự đăng ký qua `GeneratedPluginRegistrant` (manifest chỉ giữ meta-data `flutterEmbedding`).

---

## 3. Kiến trúc MVVM

Quy ước chung: mỗi feature `lib/features/<feature>/` gồm 4 lớp thư mục:

- `data/` — repository + input payload (thao tác Firestore/Firebase, không biết UI),
- `viewmodels/` — `StateNotifier` và các provider Riverpod (state + business logic),
- `views/` — các page (ConsumerWidget, chỉ render + gọi viewmodel),
- `widgets/` — UI component tái sử dụng của feature.

### 3.1. Ví dụ 1 — `lib/features/applications/` (liệt kê file thật từng lớp, đã Glob)

| Lớp | File |
|---|---|
| data | `lib/features/applications/data/applications_repository.dart` |
| viewmodels | `applications_providers.dart`, `apply_viewmodel.dart`, `review_viewmodel.dart` (trong `lib/features/applications/viewmodels/`) |
| views | `apply_job_page.dart`, `my_applications_page.dart`, `application_detail_page.dart`, `employer_applications_page.dart`, `employer_application_review_page.dart` (trong `lib/features/applications/views/`) |
| widgets | `apply_modal.dart`, `application_list_card.dart`, `employer_application_row.dart`, `apply_context_sections.dart`, `review_cards.dart`, `applications_common.dart` (trong `lib/features/applications/widgets/`) |

### 3.2. Ví dụ 2 — `lib/features/employer/` (liệt kê file thật từng lớp, đã Glob)

| Lớp | File |
|---|---|
| data | `lib/features/employer/data/employer_repository.dart`, `lib/features/employer/data/job_form_input.dart` |
| viewmodels | `employer_providers.dart`, `dashboard_viewmodel.dart`, `create_job_viewmodel.dart`, `company_profile_viewmodel.dart` (trong `lib/features/employer/viewmodels/`) |
| views | `employer_dashboard_page.dart`, `employer_jobs_page.dart`, `create_job_page.dart`, `employer_company_profile_page.dart`, `job_applicants_page.dart`, `employer_applications_page.dart`, `employer_application_review_page.dart` (trong `lib/features/employer/views/`) |
| widgets | `employer_guard.dart`, `employer_job_card.dart`, `applicant_card.dart`, `job_form_steps.dart`, `form_step_header.dart`, `form_helpers.dart`, `skills_input.dart`, `category_field.dart`, `job_preview_panel.dart`, `employer_page_header.dart`, `employer_state_banners.dart`, `stat_tile.dart`, `applications_status_chart.dart` (trong `lib/features/employer/widgets/`) |

Model dùng chung nằm ở `lib/shared/models/` (xem mục 5), còn widget dùng chung ở `lib/shared/widgets/`.

---

## 4. Riverpod

- `pubspec.yaml`: `flutter_riverpod: ^2.5.1` (kèm `riverpod_annotation`/`riverpod_generator` trong deps, nhưng **không dùng codegen**: grep toàn bộ `lib/` không có annotation `@riverpod` hay `part '*.g.dart'` — mọi provider khai báo thủ công bằng `final xxxProvider = ...`).

### 4.1. Provider thật trong `lib/core/providers.dart`

`firebaseAuthProvider` (Provider<FirebaseAuth>), `firestoreProvider` (Provider<FirebaseFirestore>), `storageProvider` (Provider<FirebaseStorage>), `prefsServiceProvider` (Provider<PrefsService>), `aiSessionStoreProvider` (Provider<AiSessionStore>), `authServiceProvider` (Provider<AuthService>), `firestoreRefsProvider` (Provider<FirestoreRefs>), `storageServiceProvider` (Provider<StorageService>), `systemConfigRepositoryProvider`, `systemConfigsProvider` (**StreamProvider**<List<SystemConfig>>), `aiLogSinkProvider` (Provider<AiLogSink>), `geminiServiceProvider`, `authStateProvider` (**StreamProvider**<User?>).

### 4.2. Các file provider/viewmodel trong features (32 file thật, trải trên 11 feature)

`applications_providers.dart`, `apply_viewmodel.dart`, `review_viewmodel.dart` (applications); `employer_providers.dart`, `dashboard_viewmodel.dart`, `create_job_viewmodel.dart`, `company_profile_viewmodel.dart` (employer); `notifications_providers.dart` (notifications); `job_detail_providers.dart`, `jobs_search_viewmodel.dart`, `company_providers.dart`, `saved_jobs_provider.dart` (jobs); `home_providers.dart` (home); `profile_providers.dart`, `profile_viewmodel.dart`, `resumes_viewmodel.dart` (profile); `admin_providers.dart`, `admin_users_viewmodel.dart`, `admin_employers_viewmodel.dart`, `admin_dashboard_viewmodel.dart`, `admin_mutation_notifier.dart`, `catalog_viewmodel.dart`, `system_config_viewmodel.dart`, `ai_stats_viewmodel.dart` (admin); `chat_providers.dart` (chat); `sessions_provider.dart`, `ai_matching_viewmodel.dart` (recommendations); `login_viewmodel.dart`, `register_viewmodel.dart`, `forgot_password_viewmodel.dart`, `current_user_provider.dart` (auth); `settings_viewmodel.dart` (settings) — tất cả trong `lib/features/<feature>/viewmodels/`.

### 4.3. Dẫn chứng cụ thể theo loại provider

| Loại | Tên provider (khai báo thật) | File |
|---|---|---|
| `StreamProvider` | `authStateProvider = StreamProvider<User?>` | `lib/core/providers.dart` |
| `StreamProvider` | `currentUserProvider = StreamProvider<UserModel?>` | `lib/features/auth/viewmodels/current_user_provider.dart` |
| `StreamProvider` | `notificationsStreamProvider = StreamProvider<List<NotificationModel>>` | `lib/features/notifications/viewmodels/notifications_providers.dart` |
| `StreamProvider` (family, autoDispose) | `jobDetailProvider = StreamProvider.autoDispose.family<JobModel?, String>` | `lib/features/jobs/viewmodels/job_detail_providers.dart` |
| `StreamProvider` | `savedJobsStreamProvider = StreamProvider<List<SavedJob>>`, `statusHistoryProvider = StreamProvider.autoDispose...`, `employerJobsProvider = StreamProvider.autoDispose<List<JobModel>>`, `featuredJobsProvider`, `chatThreadsProvider`, `systemConfigsProvider` | `lib/features/jobs/viewmodels/saved_jobs_provider.dart`, `lib/features/applications/viewmodels/applications_providers.dart`, `lib/features/employer/viewmodels/employer_providers.dart`, `lib/features/home/viewmodels/home_providers.dart`, `lib/features/chat/viewmodels/chat_providers.dart`, `lib/core/providers.dart` |
| `StateNotifierProvider` | `loginViewModelProvider` (`LoginViewModel extends StateNotifier<LoginState>`), `registerViewModelProvider`, `forgotPasswordViewModelProvider` | `lib/features/auth/viewmodels/login_viewmodel.dart`, `register_viewmodel.dart`, `forgot_password_viewmodel.dart` |
| `StateNotifierProvider` | `jobsSearchProvider = StateNotifierProvider.autoDispose<JobsSearchViewModel, JobsSearchState>` | `lib/features/jobs/viewmodels/jobs_search_viewmodel.dart` |
| `StateNotifierProvider` | `settingsProvider = StateNotifierProvider<SettingsViewModel, SettingsState>`, `notificationsControllerProvider`, `jobActionsProvider = StateNotifierProvider.autoDispose<JobActionsNotifier, Set<String>>`, `chatRoomControllerProvider` | `lib/features/settings/viewmodels/settings_viewmodel.dart`, `lib/features/notifications/viewmodels/notifications_providers.dart`, `lib/features/employer/viewmodels/employer_providers.dart`, `lib/features/chat/viewmodels/chat_providers.dart` |
| `FutureProvider` | `applyJobProvider = FutureProvider.autoDispose.family<JobModel?, String>`, `latestRecommendationProvider = FutureProvider.autoDispose...`, `maxSkillsPerJobProvider = FutureProvider.autoDispose<int>`, `requireJobApprovalProvider = FutureProvider.autoDispose<bool>` | `lib/features/applications/viewmodels/applications_providers.dart`, `lib/features/employer/viewmodels/employer_providers.dart` |
| `StateProvider` | `notificationFilterProvider = StateProvider.autoDispose<NotificationFilter>`, `authBootstrappingProvider = StateProvider<String?>` | `lib/features/notifications/viewmodels/notifications_providers.dart`, `lib/features/auth/data/auth_repository.dart` |
| `Provider` | `unreadCountProvider = Provider<int>`, `fcmTokenRegistrationProvider = Provider<void>`, `filteredNotificationsProvider` | `lib/features/notifications/viewmodels/notifications_providers.dart` |

---

## 5. Firestore

### 5.1. Typed references — `lib/core/services/firestore_refs.dart`

Class `FirestoreRefs` (một collection cho mỗi bảng của `docs/full_database_schema.sql` + các collection mở rộng cho mobile). Hằng số collection: `colUsers`, `colJobSeekerProfiles`, `colEmployerProfiles`, `colCategories`, `colSkills`, `colJobs`, `colApplications`, `subStatusHistory`, `colResumes`, `subAiAnalyses`, `colJobRecommendations`, `colSavedJobs`, `colNotifications`, `colAiMatchingLogs`, `colSystemConfigurations`, `colChats`, `subMessages`, `subAiSessions`.

Đầy đủ các method (trích nguyên tên từ file, tất cả trả về `CollectionReference<T>` có `withConverter`):

`users()`, `jobSeekerProfiles()`, `employerProfiles()`, `categories()`, `skills()`, `jobs()`, `applications()`, `statusHistory(String applicationId)`, `resumes()`, `aiAnalyses(String resumeId)`, `jobRecommendations()`, `savedJobs()`, `notifications()`, `aiMatchingLogs()`, `systemConfigurations()`, `chats()`, `messages(String chatId)`, `aiSessions(String uid)`.

### 5.2. `firestore.rules` (tóm tắt)

`rules_version = '2'`; các helper `signedIn()`, `uid()`, `userDoc()`, `role()`, `active()`, `isAdmin()`, `isEmployer()`, `isSeeker()`, `isOwner(id)`, `onlyKeys(keys)` — phân quyền theo role đọc từ `users/{uid}.role` + trạng thái `isActive`. Điểm chính: employer chỉ đụng job của mình và không tự duyệt tin (`isApproved` bất biến khi employer update); seeker chỉ tạo application với `status == 'SUBMITTED'`; `statusHistory` và `messages` là append-only (`allow update, delete: if false`); `aiMatchingLogs` chỉ admin được đọc; `employerProfiles` đọc public cho trang công ty; `users/{uid}/aiSessions` chỉ chủ sở hữu.

### 5.3. `firestore.indexes.json` (tóm tắt)

36 composite index trên 13 collection group: `jobs` (10 — lọc isApproved/status/city/workMode/jobType/categoryId/employerId/titleTokens array-contains + createdAt DESC), `applications` (9 — theo jobSeekerId/employerId/jobId + status + applicationDate), `statusHistory` (collection group, applicationId + changedAt), `notifications` (recipientId + createdAt / recipientId + isRead + createdAt), `resumes` (2), `aiAnalyses`, `savedJobs`, `jobRecommendations` (2), `aiMatchingLogs` (2), `chats` (participants array-contains + updatedAt), `users` (2), `employerProfiles` (2), `aiSessions` (scoredAt + id).

### 5.4. Mapping 18 bảng SQL → Firestore collection → model

Nguồn 18 bảng: lược đồ Supabase/PostgreSQL của project web tại `C:/Users/dat/Desktop/New folder/jobhub/docs/full_database_schema.sql` (bản hợp nhất schema gốc `08_DATABASE.md` + migration 001–005, đánh số bảng 1–18).

| # | Bảng SQL | Firestore collection | Model (`lib/shared/models/`) |
|---|---|---|---|
| 1 | `job_seeker` | `users` (role `job_seeker`) + `jobSeekerProfiles/{uid}` | `user_model.dart` (`UserModel`), `jobseeker_profile_model.dart` (`JobSeekerProfile`) |
| 2 | `employer` | `users` (role `employer`) + `employerProfiles/{uid}` | `user_model.dart` (`UserModel`), `employer_profile_model.dart` (`EmployerProfile`) |
| 3 | `category` | `categories` | `catalog_models.dart` (`CategoryModel`) |
| 4 | `skill` | `skills` | `catalog_models.dart` (`SkillModel`) |
| 5 | `resume` | `resumes` | `resume_model.dart` (`ResumeModel`) |
| 6 | `ai_analysis` | subcollection `resumes/{resumeId}/aiAnalyses` | `resume_model.dart` (`AiAnalysis`) |
| 7 | `work_experience` | nhúng mảng `workExperiences` trong `jobSeekerProfiles/{uid}` | `jobseeker_profile_model.dart` (`WorkExperience`) |
| 8 | `education` | nhúng mảng `educations` trong `jobSeekerProfiles/{uid}` | `jobseeker_profile_model.dart` (`Education`) |
| 9 | `job_seeker_skill` | nhúng mảng `skills` trong `jobSeekerProfiles/{uid}` | `jobseeker_profile_model.dart` (`ProfileSkill`) |
| 10 | `job` | `jobs` | `job_model.dart` (`JobModel`) |
| 11 | `job_skill` | nhúng mảng `requiredSkills` trong `jobs` | `job_model.dart` (`JobSkillRef`) |
| 12 | `application` | `applications` | `application_model.dart` (`ApplicationModel`) |
| 13 | `application_status_history` | subcollection `applications/{applicationId}/statusHistory` | `application_model.dart` (`ApplicationStatusHistoryItem`) |
| 14 | `job_recommendation` | `jobRecommendations` | `recommendation_models.dart` (`JobRecommendation`) |
| 15 | `saved_job` | `savedJobs` | `misc_models.dart` (`SavedJob`) |
| 16 | `notification` | `notifications` (gộp `job_seeker_id`/`employer_id` thành `recipientId` + `recipientRole`) | `notification_model.dart` (`NotificationModel`) |
| 17 | `admin` | `users` (role `admin`) | `user_model.dart` (`UserModel`) |
| 18 | `ai_matching_log` | `aiMatchingLogs` | `recommendation_models.dart` (`AiMatchingLog`) |

Ghi chú: 7 bảng SQL được "gộp/hạ cấp" khi chuyển sang Firestore — `admin`/`job_seeker`/`employer` gộp vào collection `users` phân biệt bằng trường `role` (đúng model phân vai 3 role của app), còn 4 bảng quan hệ chi tiết (`work_experience`, `education`, `job_seeker_skill`, `job_skill`) trở thành mảng nhúng trong document cha theo kiểu NoSQL.

Ngoài 18 bảng SQL, app còn có 4 collection mở rộng (không có trong SQL): `systemConfigurations` (`SystemConfig`, `catalog_models.dart`), `chats` (`ChatThread`, `misc_models.dart`), `chats/{chatId}/messages` (`ChatMessage`, `misc_models.dart`) và `users/{uid}/aiSessions` (`AiSession`, `recommendation_models.dart`) — chat là tính năng mobile-only, `systemConfigurations` thay cho cấu hình hệ thống của admin.

---

## 6. SharedPreferences

### 6.1. `lib/core/services/prefs_service.dart` — class `PrefsService` (singleton, `PrefsService.init()` trong bootstrap)

Nhóm key/method thật trong file:

| Nhóm | Key (hằng số thật) | Getter / Setter |
|---|---|---|
| Theme | `_kThemeMode = 'theme_mode'` | `themeMode` / `setThemeMode(String?)` |
| Ngôn ngữ | `_kLocale = 'locale'` | `locale` (mặc định `'vi'`) / `setLocale(String)` |
| Ghi nhớ đăng nhập | `_kRememberEmail = 'remember_email'`, `_kRememberMe = 'remember_me'` | `rememberEmail` / `setRememberEmail`, `rememberMe` / `setRememberMe(bool)` |
| Vai trò gần nhất | `_kLastRole = 'last_role'` | `lastRole` / `setLastRole` |
| Bật/tắt thông báo | `_kNotificationsEnabled = 'notifications_enabled'`, `_kNotificationTypes = 'notification_types'` (JSON map) | `notificationsEnabled` / `setNotificationsEnabled`, `notificationTypes` / `setNotificationType(type, enabled)`, `isNotificationTypeEnabled(type)` |
| Onboarding | `_kOnboardingDone = 'onboarding_done'` | `onboardingDone` / `setOnboardingDone(bool)`, `isFirstLaunch` (getter = `!onboardingDone`) |
| FCM token | `_kFcmToken = 'fcm_token'` | `fcmToken` / `setFcmToken` |
| Từ khóa tìm kiếm | `_kLastSearchKeywords = 'last_search_keywords'` | `lastSearchKeywords` / `pushSearchKeyword(kw)` (giữ tối đa 8 từ, không trùng) / `clearSearchKeywords()` |
| Nháp tin đăng tuyển | `_kJobDraft = 'job_draft'` (JSON) | `jobDraft` / `setJobDraft(Map<String, dynamic>?)` |
| Cache user offline | `_kCachedUser = 'cached_user'` (JSON) | `cachedUser` / `setCachedUser` — giữ phiên khi khởi động offline (semantics giống AuthContext retry của web) |

### 6.2. `lib/core/services/ai_session_store.dart` — class `AiSessionStore` (phiên chấm điểm AI, port `frontend/src/utils/aiScores.js`)

- Lưu tại key `jobhub.aiSessions` (cũ: `jobhub.aiScores`, tự migrate qua `_migrateLegacy()`).
- Giới hạn **20 phiên mới nhất** — `saveSession(...)` và `replaceAll(...)` đều `.take(AppConfig.aiSessionCap)` với `static const int aiSessionCap = 20` trong `lib/core/config/app_config.dart`.
- Method thật: `loadSessions()`, `getSession(String id)`, `countSessions()`, `saveSession({required String cvName, required String method, required Map<String, Map<String, JobScore>> scores, required List<JobModel> jobs})`, `deleteSession(String id)`, `clearSessions()`, `replaceAll(List<AiSession>)`, `snapshot(JobModel)`, `jobFromSnapshot(...)`.
- Provider: `aiSessionStoreProvider` (Provider<AiSessionStore>) trong `lib/core/providers.dart`.
