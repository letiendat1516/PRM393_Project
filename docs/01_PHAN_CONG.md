# PHÂN CÔNG CÔNG VIỆC — JobHub Flutter (PRM393)

Bảng phân công **5 thành viên × ≥3 màn hình mức medium trở lên** cho việc port web JobHub (React + Node + Postgres) sang Flutter (Firebase Auth + Firestore + FCM, Riverpod 2, MVVM, SharedPreferences). Phân theo nhóm chức năng của mục **"Màn hình (35 routes)"** trong `README.md` và định danh route trong router (`lib/core/router/`).

> **Tên thành viên điền sau**: Thành viên 1 (TV1), Thành viên 2 (TV2), Thành viên 3 (TV3), Thành viên 4 (TV4), Thành viên 5 (TV5).
>
> **Ghi chú về số route**: mục "Màn hình" trong `README.md` liệt kê 38 định danh route (11 public + 7 ứng viên + 8 nhà tuyển dụng + 8 admin + 4 chung), trong đó `/employer/jobs/create` và `/employer/jobs/:id/edit` dùng chung 1 file view; cộng 3 route hệ thống `/splash`, `/404` và `/403` router hiện có **41 route — bảng này gán đủ 41/41, không route nào bỏ sót**. Mọi đường dẫn view/viewmodel/repository dưới đây đã được Glob xác nhận tồn tại tại thời điểm viết.

---

## TV1 — Xác thực (Auth) + Hồ sơ ứng viên

Kèm 3 màn hệ thống: `/splash` (guard điều hướng), `/404` và `/403`.

| Tên màn hình | Route | File view | Viewmodel / Provider | Repository | Mức độ | Lý do |
|---|---|---|---|---|---|---|
| Đăng nhập | `/dang-nhap` | `lib/features/auth/views/login_page.dart` | `lib/features/auth/viewmodels/login_viewmodel.dart` (`LoginViewModel`) | `lib/features/auth/data/auth_repository.dart` | medium | Form email/mật khẩu + validate + Firebase Auth, đủ state loading/error, nhớ mật khẩu qua SharedPreferences. |
| Đăng ký ứng viên | `/dang-ky` | `lib/features/auth/views/register_page.dart` | `lib/features/auth/viewmodels/register_viewmodel.dart` (`RegisterViewModel.submitJobSeeker`) | `lib/features/auth/data/auth_repository.dart` | medium | Form nhiều trường + validate + tạo tài khoản role `job_seeker`. |
| Đăng ký nhà tuyển dụng | `/dang-ky-nha-tuyen-dung` | `lib/features/auth/views/register_employer_page.dart` | `lib/features/auth/viewmodels/register_viewmodel.dart` (`RegisterViewModel.submitEmployer`) | `lib/features/auth/data/auth_repository.dart` | hard | Gán phân quyền role `employer` và tạo thêm hồ sơ công ty ngay khi đăng ký. |
| Quên mật khẩu | `/quen-mat-khau` | `lib/features/auth/views/forgot_password_page.dart` | `lib/features/auth/viewmodels/forgot_password_viewmodel.dart` (`ForgotPasswordViewModel`) | `lib/features/auth/data/auth_repository.dart` | medium | Form email + gửi thư đặt lại mật khẩu, xử lý state thành công/lỗi. |
| Onboarding | `/onboarding` | `lib/features/auth/views/onboarding_page.dart` | `lib/core/providers.dart` (provider onboarding, không có viewmodel riêng trong feature) | — (dùng `lib/core/services/prefs_service.dart`) | medium | State Riverpod + lưu "đã xem onboarding" bằng SharedPreferences rồi điều hướng. |
| Hồ sơ & CV của tôi | `/ho-so` | `lib/features/profile/views/resume_profile_page.dart` | `lib/features/profile/viewmodels/profile_providers.dart` (`jobSeekerProfileProvider`, `myResumesProvider`, `resumeAnalysesProvider`) + `lib/features/profile/viewmodels/resumes_viewmodel.dart` (`ResumesViewModel`) | `lib/features/profile/data/profile_repository.dart` | hard | Nhiều StreamProvider realtime (hồ sơ, danh sách CV, phân tích CV) + upload CV + đặt CV chính. |
| Chỉnh sửa hồ sơ | `/ho-so/chinh-sua` | `lib/features/profile/views/edit_profile_page.dart` | `lib/features/profile/viewmodels/profile_viewmodel.dart` (`ProfileViewModel`) + `lib/features/profile/viewmodels/profile_providers.dart` | `lib/features/profile/data/profile_repository.dart` | medium | Form chỉnh sửa thông tin cá nhân + validate + ghi Firestore. |
| Splash (khởi động) | `/splash` | `lib/features/splash/views/splash_page.dart` | `lib/features/auth/viewmodels/current_user_provider.dart` | `lib/features/auth/data/auth_repository.dart` | medium | Lắng nghe auth state rồi điều hướng theo onboarding/vai trò (role guard đầu app). |
| Không tìm thấy trang | `/404` | `lib/features/home/views/not_found_page.dart` | — (UI tĩnh, không state) | — | — (màn phụ) | Trang báo lỗi điều hướng thuần UI. |
| Cấm truy cập (403) | `/403` | `lib/features/home/views/forbidden_page.dart` | — (UI tĩnh, không state) | — | — (màn phụ) | Trang "không có quyền truy cập" khi sai vai trò (role guard), thuần UI. |

## TV2 — Tìm việc (public)

| Tên màn hình | Route | File view | Viewmodel / Provider | Repository | Mức độ | Lý do |
|---|---|---|---|---|---|---|
| Trang chủ | `/` | `lib/features/home/views/home_page.dart` | `lib/features/home/viewmodels/home_providers.dart` (`featuredJobsProvider`, `topCompaniesProvider`) — dùng qua `lib/features/home/widgets/featured_jobs_section.dart`, `top_companies_section.dart` | `lib/features/home/data/home_repository.dart` | medium | Nhiều section tải StreamProvider Firestore với state loading/empty. |
| Tìm kiếm việc làm | `/viec-lam` | `lib/features/jobs/views/jobs_search_page.dart` | `lib/features/jobs/viewmodels/jobs_search_viewmodel.dart` (`JobsSearchViewModel`) + `lib/features/jobs/viewmodels/saved_jobs_provider.dart` | `lib/features/jobs/data/jobs_repository.dart` | hard | Tìm kiếm/phân trang + bộ lọc (danh mục, kỹ năng, lương…) + toggle lưu việc trên kết quả. |
| Chi tiết việc làm | `/viec-lam/:id` | `lib/features/jobs/views/job_detail_page.dart` | `lib/features/jobs/viewmodels/job_detail_providers.dart` (`jobDetailProvider`) + `lib/features/jobs/viewmodels/saved_jobs_provider.dart` | `lib/features/jobs/data/jobs_repository.dart` | medium | Tải chi tiết 1 job theo id + state loading/error + lưu/bỏ lưu việc. |
| Chi tiết công ty | `/cong-ty/:id` | `lib/features/jobs/views/company_detail_page.dart` | `lib/features/jobs/viewmodels/company_providers.dart` (`companyProfileProvider`, `companyJobsProvider`) | `lib/features/jobs/data/jobs_repository.dart` | medium | 2 StreamProvider (hồ sơ công ty + việc làm của công ty) kèm empty state. |
| Việc làm đã lưu | `/viec-da-luu` | `lib/features/jobs/views/saved_jobs_page.dart` | `lib/features/jobs/viewmodels/saved_jobs_provider.dart` | `lib/features/jobs/data/saved_jobs_repository.dart` | hard | Realtime stream danh sách việc đã lưu theo user + thao tác bỏ lưu đồng bộ Firestore. |

## TV3 — CV/AI + Ứng tuyển

| Tên màn hình | Route | File view | Viewmodel / Provider | Repository | Mức độ | Lý do |
|---|---|---|---|---|---|---|
| Gợi ý việc làm (AI Matching) | `/de-xuat` | `lib/features/recommendations/views/recommended_page.dart` | `lib/features/recommendations/viewmodels/sessions_provider.dart` (`SessionsNotifier`) + `lib/features/recommendations/viewmodels/ai_matching_viewmodel.dart` (`AiMatchingViewModel`, dùng qua `widgets/ai_matching_sheet.dart`) | `lib/features/recommendations/data/recommendations_repository.dart` | hard | Chạy AI Matching (Gemini, fallback chấm điểm rule-based) tạo phiên gợi ý và lưu kết quả. |
| Chi tiết phiên gợi ý | `/de-xuat/:sessionId` | `lib/features/recommendations/views/session_detail_page.dart` | `lib/features/recommendations/viewmodels/sessions_provider.dart` + `lib/core/services/ai_session_store.dart` (kèm `lib/features/applications/viewmodels/applications_providers.dart`, `lib/features/jobs/viewmodels/saved_jobs_provider.dart`) | `lib/features/recommendations/data/recommendations_repository.dart` | hard | Tái hiện phiên AI theo sessionId + ứng tuyển/lưu việc trực tiếp từ kết quả gợi ý. |
| Phân tích CV bằng AI | `/ho-so/phan-tich/:resumeId` | `lib/features/profile/views/ai_analysis_page.dart` | `lib/features/profile/viewmodels/profile_providers.dart` (`resumeAnalysesProvider`) + `lib/features/profile/viewmodels/resumes_viewmodel.dart` | `lib/features/profile/data/profile_repository.dart` | hard | Gọi Gemini phân tích CV theo resumeId, hiển thị điểm/điểm mạnh/yếu và lưu lịch sử phân tích. |
| Ứng tuyển việc làm | `/viec-lam/:id/ung-tuyen` | `lib/features/applications/views/apply_job_page.dart` | `lib/features/applications/viewmodels/apply_viewmodel.dart` (`ApplyViewModel`) + `lib/features/applications/viewmodels/applications_providers.dart` | `lib/features/applications/data/applications_repository.dart` | hard | Tạo đơn ứng tuyển (chọn CV, thư xin việc) — ghi nhiều bản ghi liên quan trên Firestore và chặn trùng ứng tuyển. |
| Việc làm đã ứng tuyển | `/applications` | `lib/features/applications/views/my_applications_page.dart` | `lib/features/applications/viewmodels/applications_providers.dart` (`myApplicationsProvider`, `myApplicationsFilterProvider`) | `lib/features/applications/data/applications_repository.dart` | hard | Realtime stream đơn của ứng viên + bộ lọc trạng thái + rút đơn. |
| Chi tiết đơn ứng tuyển | `/applications/:id` | `lib/features/applications/views/application_detail_page.dart` | `lib/features/applications/viewmodels/applications_providers.dart` (`applicationDetailProvider`, `statusHistoryProvider`) + `lib/features/applications/viewmodels/review_viewmodel.dart` | `lib/features/applications/data/applications_repository.dart` | medium | Tải 1 đơn theo id (stream + state loading/error) + timeline lịch sử trạng thái; thao tác duy nhất là mở chat với NTD, không ghi phức tạp. |

## TV4 — Nhà tuyển dụng (Employer)

| Tên màn hình | Route | File view | Viewmodel / Provider | Repository | Mức độ | Lý do |
|---|---|---|---|---|---|---|
| Tổng quan NTD (Dashboard) | `/employer` | `lib/features/employer/views/employer_dashboard_page.dart` | `lib/features/employer/viewmodels/dashboard_viewmodel.dart` (`DashboardStats`) + `lib/features/employer/viewmodels/employer_providers.dart` (`employerJobsProvider`, `employerAllApplicationsProvider`) | `lib/features/employer/data/employer_repository.dart` | hard | Vùng phân quyền role employer + tổng hợp thống kê job/đơn ứng tuyển bằng StreamProvider. |
| Hồ sơ công ty | `/employer/company-profile` | `lib/features/employer/views/employer_company_profile_page.dart` | `lib/features/employer/viewmodels/company_profile_viewmodel.dart` (`CompanyProfileViewModel`) + `lib/features/employer/viewmodels/employer_providers.dart` (`employerProfileProvider`) | `lib/features/employer/data/employer_repository.dart` | medium | Form thông tin công ty + validate + cập nhật hồ sơ Firestore. |
| Quản lý tin tuyển dụng | `/employer/jobs` | `lib/features/employer/views/employer_jobs_page.dart` | `lib/features/employer/viewmodels/employer_providers.dart` (`employerJobsProvider`, `employerJobsFilterProvider`, `jobActionsProvider`/`JobActionsNotifier`) | `lib/features/employer/data/employer_repository.dart` | hard | Stream danh sách tin theo NTD + lọc trạng thái + ẩn/xóa tin (cập nhật trạng thái). |
| Đăng tin tuyển dụng | `/employer/jobs/create` | `lib/features/employer/views/create_job_page.dart` | `lib/features/employer/viewmodels/create_job_viewmodel.dart` (`CreateJobViewModel`) + `lib/features/employer/viewmodels/employer_providers.dart` | `lib/features/employer/data/employer_repository.dart` | hard | Form wizard nhiều bước (mô tả, danh mục, kỹ năng, lương…) + validate dày + chờ duyệt theo cấu hình. |
| Chỉnh sửa tin tuyển dụng | `/employer/jobs/:id/edit` | `lib/features/employer/views/create_job_page.dart` (tham số `editJobId`) | `lib/features/employer/viewmodels/create_job_viewmodel.dart` + `lib/features/employer/viewmodels/employer_providers.dart` (`employerJobProvider`) | `lib/features/employer/data/employer_repository.dart` | hard | Tái sử dụng wizard ở chế độ edit: tải tin hiện có, validate và cập nhật Firestore. |
| Ứng viên của tin | `/employer/jobs/:id/applicants` | `lib/features/employer/views/job_applicants_page.dart` | `lib/features/employer/viewmodels/employer_providers.dart` (`jobApplicantsProvider`) | `lib/features/employer/data/employer_repository.dart` | hard | Stream ứng viên theo job id + duyệt/loại ứng viên (cập nhật trạng thái đơn). |
| Đơn ứng tuyển nhận được | `/employer/applications` | `lib/features/applications/views/employer_applications_page.dart` | `lib/features/applications/viewmodels/applications_providers.dart` (`employerApplicationsProvider`, `employerApplicationsFilterProvider`) | `lib/features/applications/data/applications_repository.dart` | hard | Stream toàn bộ đơn vào công ty + tìm kiếm/lọc theo tin và trạng thái. |
| Xem xét đơn ứng tuyển | `/employer/applications/:id` | `lib/features/applications/views/employer_application_review_page.dart` | `lib/features/applications/viewmodels/review_viewmodel.dart` (`ReviewViewModel`) + `lib/features/applications/viewmodels/applications_providers.dart` | `lib/features/applications/data/applications_repository.dart` | hard | Xem CV + đổi trạng thái đơn (xét duyệt/gửi offer/từ chối) ghi kèm lịch sử trạng thái. |

## TV5 — Thông báo + Chat + Cài đặt + Admin

| Tên màn hình | Route | File view | Viewmodel / Provider | Repository | Mức độ | Lý do |
|---|---|---|---|---|---|---|
| Thông báo | `/notifications` | `lib/features/notifications/views/notifications_page.dart` | `lib/features/notifications/viewmodels/notifications_providers.dart` (`notificationsStreamProvider`, `NotificationsController`, `fcmTokenRegistrationProvider`) | `lib/features/notifications/data/notifications_repository.dart` | hard | Realtime stream thông báo + đăng ký token FCM + đánh dấu đã đọc/xóa. |
| Danh sách hội thoại | `/tin-nhan` | `lib/features/chat/views/chats_page.dart` | `lib/features/chat/viewmodels/chat_providers.dart` (`chatThreadsProvider`, `unreadChatsCountProvider`) | `lib/features/chat/data/chat_repository.dart` | hard | Realtime stream danh sách thread chat + badge số tin chưa đọc. |
| Phòng chat | `/tin-nhan/:chatId` | `lib/features/chat/views/chat_room_page.dart` | `lib/features/chat/viewmodels/chat_providers.dart` (`chatMessagesProvider`, `ChatRoomController`) | `lib/features/chat/data/chat_repository.dart` | hard | Realtime stream tin nhắn 2 chiều trong phòng chat + gửi tin theo chatId. |
| Cài đặt tài khoản | `/settings` | `lib/features/settings/views/settings_page.dart` | `lib/features/settings/viewmodels/settings_viewmodel.dart` (`SettingsViewModel`) | — (dùng `lib/core/services/prefs_service.dart`, `lib/core/services/auth_service.dart`) | medium | Đổi mật khẩu, theme/ngôn ngữ, đăng xuất — state Riverpod + SharedPreferences. |
| Tổng quan admin | `/admin` | `lib/features/admin/views/admin_dashboard_page.dart` | `lib/features/admin/viewmodels/admin_dashboard_viewmodel.dart` (`SeedDemoNotifier`) + `lib/features/admin/viewmodels/admin_providers.dart` (`adminCountsProvider`) | `lib/features/admin/data/admin_repository.dart` | hard | Phân quyền role admin + seed dữ liệu demo (danh mục, employer, job) + thống kê. |
| Quản lý người dùng | `/admin/users` | `lib/features/admin/views/admin_users_page.dart` | `lib/features/admin/viewmodels/admin_users_viewmodel.dart` (`AdminUsersFilterNotifier`) + `lib/features/admin/viewmodels/admin_providers.dart` (`usersByRoleProvider`) + `lib/features/admin/viewmodels/admin_mutation_notifier.dart` | `lib/features/admin/data/admin_repository.dart` | hard | Phân quyền admin, stream người dùng + lọc vai trò + khóa/mở tài khoản. |
| Quản lý nhà tuyển dụng | `/admin/employers` | `lib/features/admin/views/admin_employers_page.dart` | `lib/features/admin/viewmodels/admin_employers_viewmodel.dart` (`AdminEmployersFilterNotifier`) + `lib/features/admin/viewmodels/admin_providers.dart` (`employerProfilesProvider`) + `lib/features/admin/viewmodels/admin_mutation_notifier.dart` | `lib/features/admin/data/admin_repository.dart` | hard | Stream hồ sơ NTD + lọc/tìm kiếm + kích hoạt/vô hiệu hóa công ty. |
| Duyệt tin tuyển dụng | `/admin/pending-jobs` | `lib/features/admin/views/admin_pending_jobs_page.dart` | `lib/features/admin/viewmodels/admin_providers.dart` (`pendingJobsProvider`) + `lib/features/admin/viewmodels/admin_mutation_notifier.dart` | `lib/features/admin/data/admin_repository.dart` | hard | Stream tin chờ duyệt + duyệt/từ chối (cập nhật trạng thái job). |
| Quản lý danh mục | `/admin/catalog` | `lib/features/admin/views/catalog_management_page.dart` | `lib/features/admin/viewmodels/catalog_viewmodel.dart` (`CatalogNotifier`) + `lib/features/admin/viewmodels/admin_providers.dart` (`adminCategoriesProvider`, `adminSkillsProvider`) | `lib/features/admin/data/admin_repository.dart` | medium | CRUD danh mục/kỹ năng với form validate và state Riverpod. |
| Cấu hình hệ thống | `/admin/system-configurations` | `lib/features/admin/views/admin_system_configuration_page.dart` | `lib/features/admin/viewmodels/system_config_viewmodel.dart` (`SystemConfigNotifier`) | `lib/core/services/system_config_repository.dart` (không có repository riêng trong feature) | hard | Nhập/kiểm tra `GEMINI_API_KEY` (bật AI) và các cấu hình hệ thống (giới hạn kỹ năng, duyệt tin…). |
| Nhật ký AI | `/ai-logs` | `lib/features/admin/views/ai_logs_page.dart` | `lib/features/admin/viewmodels/admin_providers.dart` (`aiLogsProvider`) | `lib/features/admin/data/ai_logs_repository.dart` | hard | Stream log các lần gọi AI + lọc theo loại/thời gian. |
| Thống kê AI | `/admin/ai-stats` | `lib/features/admin/views/ai_stats_page.dart` | `lib/features/admin/viewmodels/ai_stats_viewmodel.dart` (`AiStats`) + `lib/features/admin/viewmodels/admin_providers.dart` (`aiLogsProvider`) | `lib/features/admin/data/ai_logs_repository.dart` | hard | Tổng hợp log AI thành số liệu (lượt gọi, tỉ lệ lỗi, theo ngày) và biểu đồ. |

---

## Thống kê

| Thành viên | Nhóm | Số màn | medium | hard | Phụ/không xếp mức |
|---|---|---|---|---|---|
| TV1 | Auth + hồ sơ ứng viên (+ splash, 404, 403) | 10 | 6 | 2 | 2 (`/404`, `/403`) |
| TV2 | Tìm việc (public) | 5 | 3 | 2 | 0 |
| TV3 | CV/AI + ứng tuyển | 6 | 1 | 5 | 0 |
| TV4 | Nhà tuyển dụng | 8 | 1 | 7 | 0 |
| TV5 | Thông báo + chat + cài đặt + admin | 12 | 2 | 10 | 0 |
| **Tổng** | **41 route router (38 route README + `/splash` + `/404` + `/403`)** | **41** | **13** | **26** | **2** |

Mọi thành viên đều nhận ≥3 màn mức medium trở lên; không route nào của router bị bỏ sót.

## Tiêu chí phân mức

- **medium**: màn có form/validate và quản lý state bằng Riverpod (StateNotifier/StreamProvider), xử lý đủ 3 trạng thái loading — empty — error.
- **hard**: màn sử dụng ít nhất một trong: realtime stream (Firestore snapshots), transaction/ghi nhiều bản ghi liên quan, FCM push hoặc Gemini AI (kèm fallback rule-based), phân quyền theo role (job_seeker / employer / admin), pagination/tìm kiếm + bộ lọc.
- Màn **phụ** (như `/404`) là UI tĩnh, không state — không tính vào chỉ tiêu medium/hard.
