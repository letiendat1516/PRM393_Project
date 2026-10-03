# JobHub Flutter port — implementation contract (READ FIRST)

Source web app: `C:\Users\dat\Desktop\New folder\jobhub` (React + Tailwind frontend, Node/Express backend, Postgres).
Target: this Flutter project (Firebase Auth + Firestore + FCM, Riverpod 2, MVVM, SharedPreferences). Mobile + Web.
Goal: **100% functional + visual parity with the web pages**, plus the mobile-only screens from
`docs/FLUTTER_REBUILD_PLAN.md` (onboarding, forgot password, edit profile, saved jobs, apply wizard, AI analysis
screen, employer dashboard, edit job, job applicants, chat, admin dashboard).

## Architecture (MVVM, strict)
```
lib/features/<feature>/
  data/          repositories (Firestore / services access only here)
  viewmodels/    Riverpod providers: StreamProvider / FutureProvider / StateNotifierProvider (Riverpod 2, no codegen)
  views/         pages (ConsumerWidget / ConsumerStatefulWidget) — UI only
  widgets/       feature-private widgets
```
- Views never touch Firestore directly. Repositories throw `Failure` (lib/core/utils/failure.dart); viewmodels catch
  with `Failure.from(e)`; views show `showFailure(context, e)` / `AlertError` / `RouteErrorView`.
- Every page has **loading, empty and error states** (`RouteLoader`, `EmptyState`, `RouteErrorView`).
- All user-facing text in **Vietnamese, verbatim from the web page spec** (diacritics preserved).
- Pages that are inside the web `PublicLayout` must be wrapped in `PublicLayout(child: ...)` (navbar + footer).
  Use `PublicLayout(scrollable: false, child: ...)` when the page manages its own scrolling. Auth pages use
  `AuthShell`. Dashboard-like pages may use `AppScaffold(title:, body:)` (navbar + title bar, no footer).
- Responsive: web layouts (two columns, sidebars, tables) at width ≥ 900/1024; stack on phones.
- Do NOT edit files outside your feature folder. If you need a shared change, write it in your final report
  under `sharedChangesNeeded` (file + exact change) — the orchestrator applies it.
- Finish with `flutter analyze lib/features/<your-folder>` and fix every error/warning in YOUR files.

## Shared code you must use (do not duplicate)
- Enums + Vietnamese labels: `lib/core/utils/enums.dart` (`enumToWire`, `parse*`, `.label`, `JobMapperLabels`).
- Models (mirror the 18 SQL tables): `lib/shared/models/*.dart`
  - `UserModel` (users/{uid}: role, fullName, email, isActive, isVerified, phone, photoUrl, fcmTokens)
  - `JobSeekerProfile` (jobSeekerProfiles/{uid}: fullName, headline, city, phone, address, profileSummary,
    isOpenToWork, skills[ProfileSkill], workExperiences[WorkExperience], educations[Education], primaryResumeId;
    `missingRequiredFields`, `isComplete`)
  - `EmployerProfile` (employerProfiles/{uid}: companyName, contactName, gender, phone, website,
    companyDescription, city, logoUrl, isVerified, isActive, openPositions)
  - `JobModel` + `JobDescription` + `JobSkillRef` (jobs/{jobId}: jobTitle, employerId, employerName,
    categoryId/categoryName, description{moTaCongViec,yeuCauUngVien,quyenLoi,thoiGianLamViec,
    yeuCauKinhNghiem,yeuCauBangCap}, salaryMin/Max/Currency/Period, isSalaryNegotiable, location, city,
    workMode, jobType, experienceLevel, positionsAvailable, applicationDeadline, status, isApproved,
    requiredSkills, titleTokens, applicationsCount; getters tags, hot, isPublic, isExpired, acceptsApplications,
    isPendingReview, isRejected, minExperienceYears; `JobModel.tokenize(title, company)` for search)
  - `ApplicationModel` + `ApplicationStatusHistoryItem` (applications/{seekerUid_jobId} +
    subcollection statusHistory; `ApplicationModel.docIdFor`, `transitions`, `allowedTransitions`, `timeline`)
  - `ResumeModel` + `AiAnalysis` (resumes/{id}, aiAnalysis embedded + aiAnalyses subcollection)
  - `NotificationModel` (notifications/{id}: recipientId, recipientRole, type, title, message, data, isRead)
  - `CategoryModel`, `SkillModel`, `SystemConfig` (lib/shared/models/catalog_models.dart)
  - `JobScore`, `ScoreBreakdown`, `JobRecommendation`, `AiMatchingLog`, `AiSession`
    (lib/shared/models/recommendation_models.dart)
  - `SavedJob`, `ChatThread`, `ChatMessage` (lib/shared/models/misc_models.dart)
- Typed Firestore refs: `ref.read(firestoreRefsProvider)` → `FirestoreRefs` (lib/core/services/firestore_refs.dart):
  `users() jobSeekerProfiles() employerProfiles() categories() skills() jobs() applications()
   statusHistory(appId) resumes() aiAnalyses(resumeId) jobRecommendations() savedJobs() notifications()
   aiMatchingLogs() systemConfigurations() chats() messages(chatId) aiSessions(uid)` and `.db` for batches/transactions.
- Core providers (lib/core/providers.dart): `firebaseAuthProvider firestoreProvider storageProvider
  prefsServiceProvider aiSessionStoreProvider authServiceProvider firestoreRefsProvider storageServiceProvider
  systemConfigRepositoryProvider systemConfigsProvider aiLogSinkProvider geminiServiceProvider authStateProvider`.
- `currentUserProvider` (StreamProvider<UserModel?>) lives in
  `lib/features/auth/viewmodels/current_user_provider.dart` — import it; do not redefine.
- Services: `AuthService` (signIn/register/sendPasswordReset/changePassword/setRememberMe/signOut),
  `PrefsService` (themeMode, locale, rememberEmail, rememberMe, lastRole, notificationsEnabled,
  notificationTypes, onboardingDone/isFirstLaunch, fcmToken, lastSearchKeywords, jobDraft, cachedUser),
  `AiSessionStore` (loadSessions/getSession/saveSession/deleteSession/clearSessions, cap 20, `snapshot(job)`,
  `jobFromSnapshot(map)`), `SystemConfigRepository` (watchAll/get/getNumber/getBool/getString/update/
  ensureDefaults/masked; keys in `SystemConfig.key*`), `GeminiService` (extractResume(text) → AiAnalysis,
  scoreJobs(cvPayload, jobs ≤100) → List<JobScore>, testKey()), `RuleBasedScorer.scoreJobs(cvPayload, jobs)`,
  `StorageService` (uploadResume/uploadImage/delete — NOTE: Firebase Storage is NOT enabled (no Blaze plan);
  wrap uploads in try/catch and fall back to text-only resumes), `FcmService`.
- Formatting (lib/core/utils/formatters.dart): `Formatters.salary(min,max,currency,negotiable)` ("25 - 40 triệu",
  "Thoả thuận"), `salaryHome`, `postedText/postedAgo`, `deadlineFull`, `date/dateTime/relative/compact/number`,
  `CompanyDisplay.of(name)` (monogram + palette index). Validators: lib/core/utils/validators.dart (backend
  limits + messages). Config/options: lib/core/config/app_config.dart (`salaryBands`, `sortOptions`,
  `popularKeywords`, `homeCategoryChips`, section anchor ids, AI batch constants, defaults).
- Demo content (verbatim port of frontend/src/data/*.js): lib/core/data/demo_data.dart (`DemoData.provinces,
  trustedCompanies, topCompanies, features, workflowSteps, statistics, testimonials, blogPosts, categories,
  heroImage, workflowImage, heroAvatars, featuredJobs(), sampleJobs(), sampleEmployers()`). Images are in
  `assets/images/` (hero-office, company-office, team-meeting, team-collab, workspace, career-growth,
  job-interview, resume-candidate, portrait-anh/minh/linh/tuan). Icon name map: `AppIcons.of('sparkles')`.
- Theme: `AppColors` (primary #0F4C81 + 50..900, secondary #00A86B, canvas, surface, ink/inkSoft/inkMuted,
  border/borderMuted, blue/amber/emerald/red/teal/violet tints), `CompanyPalette`, `AppShadows.soft/card/
  elevated`, `AppRadius.xl(14 buttons/inputs) x2l(16 cards) pill`. Buttons: `ElevatedButton` = `.btn-primary`,
  `OutlinedButton` = `.btn-secondary`, `TextButton` = `.btn-ghost`. Font: Plus Jakarta Sans (theme).
- Shared widgets (lib/shared/widgets): `PublicLayout`, `AppScaffold`, `AuthShell(title, subtitle, child, footer)`,
  `WebNavbar`, `WebFooter`, `MobileDrawer`, `NavItems`, `BrandLogo`, `Section`, `PageContainer`, `Eyebrow`,
  `SectionHeading`, `AppChip(variant: neutral|primary|secondary|outline)`, `AppCard`, `CompanyLogoTile`,
  `ScoreBadge`, `PasswordField`, `AlertError`, `InfoBanner(tone)`, `RouteErrorView`, `RouteLoader`,
  `Breadcrumb`, `Pagination`, `EmptyState`, `JobListItem(job, score, saved, onToggleSave, onApply, applied)`,
  `JobCard`, `ApplicationStatusBadge`, `JobStatusBadge`, `BoolBadge`, `StatusHistoryTimeline(items)`,
  helpers `showFailure(context, e)`, `showSuccess(context, msg)`, `copyToClipboard`.

## Cross-feature contracts (exact names; other agents import these)
- `features/auth/viewmodels/current_user_provider.dart`: `currentUserProvider`, and
  `features/auth/data/auth_repository.dart`: `authRepositoryProvider`.
- `features/applications/widgets/apply_modal.dart`:
  `Future<void> showApplyModal(BuildContext context, JobModel job)` (ApplyModal.jsx behaviour).
- `features/applications/viewmodels/applications_providers.dart`:
  `appliedJobIdsProvider` (StreamProvider<Set<String>> of the current seeker's applied jobIds).
- `features/jobs/viewmodels/saved_jobs_provider.dart`: `savedJobIdsProvider` (StreamProvider<Set<String>>),
  `toggleSavedJob(WidgetRef ref, JobModel job)` top-level function.
- `features/recommendations/widgets/ai_matching_sheet.dart`:
  `Future<Map<String, Map<String, JobScore>>?> showAiMatchingSheet(BuildContext context, {required List<JobModel> jobs})`
  — resolves with the scoring results (`jobId → {'ai': JobScore?, 'sql': JobScore?}`) as soon as the sheet closes
  if a scoring run completed in it (even if the user closed without 'Lưu kết quả'), else `null`. Mirrors
  AIScoreModal.jsx `onScored(scoreMap, cvName)`; the session is auto-saved to AiSessionStore when scoring completes.
  Consumers (`JobsSearchViewModel.applyScores`) adopt `ai ?? sql` per job, switch sort to `aiScore`, page 1.
- `features/notifications/viewmodels/notifications_providers.dart`: `notificationsStreamProvider`,
  `unreadCountProvider` (Provider<int>), and `features/notifications/data/notifications_repository.dart`:
  `NotificationsRepository.create(...)` used by applications/admin/employer to write notification docs
  (signature: `Future<void> create({required String recipientId, required UserRole recipientRole,
  required NotificationType type, required String title, required String message, Map<String,dynamic> data})`
  via `notificationsRepositoryProvider`).
- `features/chat/data/chat_repository.dart`: `chatRepositoryProvider` with
  `Future<String> openChatWith({required String otherUid, required String otherName, String? jobId, String? jobTitle})`
  returning the chatId (used by employer review page / application detail to start a conversation).

## Routes & page constructors (lib/core/router/routes.dart + app_router.dart — already wired; create these exact classes)
| Route | File | Class / ctor |
|---|---|---|
| /splash | features/splash/views/splash_page.dart | `SplashPage()` |
| /onboarding | features/auth/views/onboarding_page.dart | `OnboardingPage()` |
| / (?section=) | features/home/views/home_page.dart | `HomePage({String? section})` |
| /dang-nhap, /dang-ky, /dang-ky-nha-tuyen-dung | features/auth/views/login_page.dart, register_page.dart, register_employer_page.dart | `LoginPage()`, `RegisterPage()`, `RegisterEmployerPage()` |
| /quen-mat-khau | features/auth/views/forgot_password_page.dart | `ForgotPasswordPage()` |
| /viec-lam (?q&location) | features/jobs/views/jobs_search_page.dart | `JobsSearchPage({String? initialKeyword, String? initialLocation})` |
| /viec-lam/:id | features/jobs/views/job_detail_page.dart | `JobDetailPage({required String jobId})` |
| /viec-lam/:id/ung-tuyen | features/applications/views/apply_job_page.dart | `ApplyJobPage({required String jobId})` |
| /cong-ty/:id | features/jobs/views/company_detail_page.dart | `CompanyDetailPage({required String employerUid})` |
| /viec-da-luu | features/jobs/views/saved_jobs_page.dart | `SavedJobsPage()` |
| /ho-so | features/profile/views/resume_profile_page.dart | `ResumeProfilePage()` |
| /ho-so/chinh-sua | features/profile/views/edit_profile_page.dart | `EditProfilePage()` |
| /ho-so/phan-tich/:resumeId | features/profile/views/ai_analysis_page.dart | `AiAnalysisPage({required String resumeId})` |
| /applications | features/applications/views/my_applications_page.dart | `MyApplicationsPage()` |
| /applications/:id | features/applications/views/application_detail_page.dart | `ApplicationDetailPage({required String applicationId})` |
| /de-xuat | features/recommendations/views/recommended_page.dart | `RecommendedPage()` |
| /de-xuat/:sessionId | features/recommendations/views/session_detail_page.dart | `SessionDetailPage({required String sessionId})` |
| /employer | features/employer/views/employer_dashboard_page.dart | `EmployerDashboardPage()` |
| /employer/company-profile | features/employer/views/employer_company_profile_page.dart | `EmployerCompanyProfilePage()` |
| /employer/jobs | features/employer/views/employer_jobs_page.dart | `EmployerJobsPage()` |
| /employer/jobs/create, /employer/jobs/:id/edit | features/employer/views/create_job_page.dart | `CreateJobPage({String? editJobId})` |
| /employer/jobs/:id/applicants | features/employer/views/job_applicants_page.dart | `JobApplicantsPage({required String jobId})` |
| /employer/applications | features/applications/views/employer_applications_page.dart | `EmployerApplicationsPage()` |
| /employer/applications/:id | features/applications/views/employer_application_review_page.dart | `EmployerApplicationReviewPage({required String applicationId})` |
| /admin | features/admin/views/admin_dashboard_page.dart | `AdminDashboardPage()` |
| /admin/users, /admin/employers, /admin/pending-jobs, /admin/catalog, /admin/system-configurations, /ai-logs, /admin/ai-stats | features/admin/views/admin_users_page.dart, admin_employers_page.dart, admin_pending_jobs_page.dart, catalog_management_page.dart, admin_system_configuration_page.dart, ai_logs_page.dart, ai_stats_page.dart | `AdminUsersPage()`, `AdminEmployersPage()`, `AdminPendingJobsPage()`, `CatalogManagementPage()`, `AdminSystemConfigurationPage()`, `AiLogsPage()`, `AiStatsPage()` |
| /notifications | features/notifications/views/notifications_page.dart | `NotificationsPage()` |
| /tin-nhan, /tin-nhan/:chatId | features/chat/views/chats_page.dart, chat_room_page.dart | `ChatsPage()`, `ChatRoomPage({required String chatId})` |
| /settings | features/settings/views/settings_page.dart | `SettingsPage()` |
| /404 + errorBuilder | features/home/views/not_found_page.dart | `NotFoundPage({String? path})` |
Navigate with `context.go(AppRoutes.x)` / `context.push(AppRoutes.jobDetailOf(id))`.

## Specs (read the exact line ranges — they contain layout, logic and verbatim Vietnamese strings)
- Design tokens + layouts (HomePage, JobsPage, JobDetail, CompanyDetail, Login, Register, RegisterEmployer,
  ResumePage, MyApplications, EmployerJobs, CreateJob, EmployerApplications+Review, EmployerCompanyProfile):
  `C:\Users\dat\AppData\Local\Temp\claude\C--Users-dat-AndroidStudioProjects-jobhub-prm393\3e5658a4-0958-48fc-a71a-08c21b52f57f\tasks\w55xq0lxm.output`
  pageName lines: Home 110, Jobs 201, JobDetail 267, CompanyDetail 313, Login 329, Register 370,
  RegisterEmployer 421, Resume 472, MyApplications 493, EmployerJobs 534, CreateJob 610,
  EmployerApplications+Review 626, EmployerCompanyProfile 667 (each block ends where the next begins).
- Remaining pages + schema + backend logic + mock data + critic:
  `C:\Users\dat\AppData\Local\Temp\claude\C--Users-dat-AndroidStudioProjects-jobhub-prm393\3e5658a4-0958-48fc-a71a-08c21b52f57f\tasks\wg31jo74t.output`
  pages: Recommended+SessionDetail 8, AdminUsers 158, AdminEmployers 246, AdminPendingJobs 331,
  Catalog 397, SystemConfig 497, AiLogs 591, AiStats 671, EmployerApplicationReview 790, NotFound 889,
  JobDetail(deep) 954, Resume(deep) 1084. Schema: statusTransitions 2287, functionsAndTriggers 2288,
  firestoreMapping 2289. Backend logic modules: Auth 2294, JobSeeker 2349, Job 2399, Employer 2486,
  Application 2531, Resume 2598, Recommendation 2663, Admin 2729, SystemConfiguration 2785;
  systemConfigKeys 2828, ruleBasedScoring 2848, aiPrompts 2849. Mock data 2851–2989. Critic checklist 2991–3202
  (P0 items describe ApplyModal, AIScoreModal, JobsPage data engine, AuthContext, redirectByRole, Navbar/Footer,
  job creation/moderation rules, search semantics, application workflow, resume rules, admin rules, register
  payloads).
- Original sources if needed: `C:\Users\dat\Desktop\New folder\jobhub\frontend\src\**`,
  `C:\Users\dat\Desktop\New folder\jobhub\backend\src\**`, `C:\Users\dat\Desktop\New folder\jobhub\docs\**`.

## Firestore conventions
- Field names camelCase; enum values UPPER_SNAKE (use `enumToWire`). Timestamps via `Timestamp` /
  `FieldValue.serverTimestamp()` (models already do this in `toJson`).
- Public job queries: `where('isApproved', isEqualTo: true).where('status', isEqualTo: 'OPEN')`
  (+ optional equality filters on city/workMode/jobType/categoryId) ordered by `createdAt desc`;
  keyword search via `where('titleTokens', arrayContainsAny: tokens)` (max 10 tokens) + client-side filtering.
- Uniqueness via deterministic doc ids (`ApplicationModel.docIdFor`, `SavedJob.docIdFor`,
  `JobRecommendation.docIdFor`, `ChatThread.docIdFor`). Multi-doc writes in `db.runTransaction` / `batch`.
- Status transitions: `ApplicationModel.transitions`; write status + statusHistory doc in ONE transaction and
  check `expectedCurrentStatus` (409 'Hồ sơ đã được cập nhật. Vui lòng tải lại.'; 400 'Chuyển trạng thái không hợp lệ.').
- Composite indexes will be added by the orchestrator — report any new compound query you rely on in your final
  report under `indexesNeeded` (collection + fields + order).
