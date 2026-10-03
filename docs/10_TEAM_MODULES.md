# Phân chia module cho nhóm (5 thành viên)

Tài liệu này chia project JobHub thành **5 module độc lập**, mỗi module do 1
thành viên phụ trách. Mỗi module có:
- **File backend/frontend sở hữu** (chỉ người đó được sửa core logic)
- **Bảng DB sở hữu** (chỉ người đó được WRITE schema/migration)
- **Interface contract** với module khác (gọi chéo qua Service)

> Quy tắc vàng: **Module A được READ bất kỳ bảng nào, nhưng chỉ WRITE bảng
> mình sở hữu.** Gọi chéo qua Service layer, không gọi Repository của module
> khác trực tiếp.

---

## Tổng quan 5 module

| # | Module | Owner | Phase chính | Use Cases |
|---|--------|-------|-------------|-----------|
| 1 | **AI Resume & Matching** | **BẠN** | 9, 10 | 04, 10, 23 (3 UC) |
| 2 | Auth & User Management | TV2 | 3, 4 | 01, 02, 03, 25, 26, 27 (6 UC) |
| 3 | Job Management & Search | TV3 | 7 | 05, 06, 07, 12, 13 (5 UC) |
| 4 | Employer & Applications | TV4 | 5, 8 | 08, 09, 11, 14, 15, 16 (6 UC) |
| 5 | Admin & Frontend Homepage | TV5 | 2, 11 | 17, 18, 19, 20, 21, 22, 24 (7 UC) |

---

## Module 1 — AI Resume Analysis & Job Matching (BẠN)

**Trách nhiệm:**
- Upload CV (PDF), trích text
- AI extract kỹ năng, kinh nghiệm, học vấn (DeepSeek)
- Chấm điểm phù hợp giữa CV và Job
- Pipeline recommendation 2 phase (rule-based filter + AI match)
- **Ghi log AI** để cải thiện prompt (folder `ai-lab/`)

**Use cases sở hữu:**
- UC04 (Upload Resume)
- UC10 (View Recommended Jobs)
- UC23 (AI Resume Analysis) — USP của dự án

**Backend sở hữu:**
```
backend/src/ai/                              ← folder riêng của bạn
  ├── deepseekClient.js                      DeepSeek API wrapper
  ├── promptBuilder.js                       Build prompt extract + match
  └── aiLogger.js                            Log DB + file ai-lab/logs/
backend/src/services/ResumeService.js        (AI workflow)
backend/src/services/RecommendationService.js
backend/src/repositories/ResumeRepository.js
backend/src/repositories/RecommendationRepository.js
backend/src/controllers/ResumeController.js
backend/src/controllers/RecommendationController.js
backend/src/routes/resumeRoutes.js
backend/src/routes/recommendationRoutes.js
backend/src/validators/resumeValidator.js
```

**Folder riêng:** `ai-lab/` (xem `ai-lab/README.md`)

**DB sở hữu (WRITE):**
- `resume`, `ai_analysis`
- `work_experience`, `education`, `job_seeker_skill`
- `job_recommendation`, `ai_matching_log`
- `skill` (cùng sở hữu với Module 3 qua `job_skill`)

**READ từ module khác:**
- `job`, `job_skill` (Module 3) — qua `JobService`
- `job_seeker` (Module 2) — qua `JobSeekerService`

**Contract đầu ra (module khác cần biết):**
- `RecommendationService.getRecommendations(userId)` → `[{ job_id, match_score, reason }]`
- `ResumeService.getLatestAnalysis(resumeId)` → `{ skills, experience_years, education }`

---

## Module 2 — Authentication & User Management

**Trách nhiệm:**
- Đăng ký / đăng nhập / logout / refresh token
- JWT + bcrypt (đã làm xong)
- Profile ứng viên (Job Seeker)
- Đổi mật khẩu, quên mật khẩu
- Role-based access (RBAC middleware)

**Use cases sở hữu:**
- UC01 (Register Account)
- UC02 (Log In)
- UC03 (Manage Profile — Job Seeker)
- UC25 (Reset Password)
- UC26 (Change Password)
- UC27 (Log Out)

**Backend sở hữu:**
```
backend/src/services/AuthService.js
backend/src/services/JobSeekerService.js
backend/src/repositories/AuthRepository.js
backend/src/repositories/JobSeekerRepository.js
backend/src/controllers/AuthController.js
backend/src/routes/authRoutes.js
backend/src/middlewares/authMiddleware.js
backend/src/validators/authValidator.js
```

**DB sở hữu (WRITE):** `job_seeker`, `admin`

**READ:** `employer` (Module 4) cho login cross-table

**Contract đầu ra:**
- `AuthService.verifyAccessToken(token)` → `principal` (dùng bởi mọi middleware bảo vệ)
- `JobSeekerService.getProfile(userId)` → profile công khai

---

## Module 3 — Job Management & Search

**Trách nhiệm:**
- CRUD tin tuyển dụng (employer đăng/sửa/xoá)
- Search việc làm với filter (keyword, lương, địa điểm, kinh nghiệm, hình thức)
- Categories, skills gắn với job
- Saved jobs (ứng viên lưu)

**Use cases sở hữu:**
- UC05 (Search Jobs)
- UC06 (View Job Details)
- UC07 (Save Job)
- UC12 (Create Job Posting) — ⚠️ Employer UI do Module 4 làm
- UC13 (Manage Job Postings) — ⚠️ Employer UI do Module 4 làm

**Backend sở hữu:**
```
backend/src/services/JobService.js
backend/src/repositories/JobRepository.js
backend/src/controllers/JobController.js
backend/src/routes/jobRoutes.js
backend/src/validators/jobValidator.js
```

**DB sở hữu (WRITE):** `job`, `category`, `job_skill`, `saved_job`

**READ:** `employer` (Module 4), `skill` (cùng Module 1)

**Contract đầu ra:**
- `JobService.searchJobs(filters)` → danh sách job (Module 1 dùng để chấm điểm)
- `JobService.findJobById(id)` → chi tiết 1 job

---

## Module 4 — Employer Management & Applications

**Trách nhiệm:**
- Profile công ty (CRUD)
- Đăng tin tuyển dụng (gọi Module 3)
- Xem ứng viên ứng tuyển
- Flow application: nộp → duyệt → phỏng vấn → offer → chấp nhận/từ chối
- Tracking trạng thái application

**Use cases sở hữu:**
- UC08 (Apply for Job)
- UC09 (Track Application Status)
- UC11 (Manage Company Profile)
- UC14 (View Applications)
- UC15 (Review Application)
- UC16 (Update Application Status)

**Backend sở hữu:**
```
backend/src/services/EmployerService.js
backend/src/services/ApplicationService.js
backend/src/repositories/EmployerRepository.js
backend/src/repositories/ApplicationRepository.js
backend/src/controllers/EmployerController.js
backend/src/controllers/ApplicationController.js
backend/src/routes/employerRoutes.js
backend/src/routes/applicationRoutes.js
```

**DB sở hữu (WRITE):** `employer`, `application`

**READ:** `job` (Module 3), `resume` (Module 1) để xem CV ứng viên

**Contract đầu ra:**
- `EmployerService.getPublicProfile(employerId)` → profile công ty công khai
- `ApplicationService.findByJob(jobId)` → danh sách ứng viên cho 1 job

---

## Module 5 — Admin Dashboard & Frontend Homepage

**Trách nhiệm:**
- Admin dashboard (quản lý users, employers, jobs, approvals)
- Thống kê, báo cáo
- **Toàn bộ frontend homepage + shared UI** (Navbar, Footer, layouts)
- Hệ thống notification
- Routing config

**Use cases sở hữu:**
- UC17 (Manage Users)
- UC18 (Manage Employers)
- UC19 (Moderate Job Postings) — ⚠️ WRITE `job` qua JobService của Module 3
- UC20 (Manage Skills) — ⚠️ WRITE `skill` qua SkillService của Module 1
- UC21 (Manage Job Categories) — ⚠️ WRITE `category` qua JobService của Module 3
- UC22 (Manage System Configurations)
- UC24 (View Statistics & Reports)

**Backend sở hữu:**
```
backend/src/services/AdminService.js          (mới)
backend/src/controllers/AdminController.js    (mới)
backend/src/routes/adminRoutes.js             (mới)
```

**Frontend sở hữu:**
```
frontend/src/components/         (toàn bộ shared UI: navbar/, footer/, ui/, ...)
frontend/src/layouts/PublicLayout.jsx
frontend/src/pages/HomePage.jsx
frontend/src/pages/NotFoundPage.jsx
frontend/src/pages/PlaceholderPage.jsx
frontend/src/routes/AppRoutes.jsx
frontend/src/data/                (mock data)
```

**DB sở hữu (WRITE):** `notification`

**READ:** mọi bảng (chỉ đọc cho dashboard/reporting)

---

## Use case cross-module (UI và Data ownership khác module)

Một số use case có **UI thuộc module này nhưng thao tác WRITE data của module khác**.
Theo nguyên tắc "Module A chỉ WRITE bảng mình sở hữu", phải gọi qua Service layer
(chứ không gọi Repository trực tiếp).

| Use Case | UI (Module) | Data WRITE (Module) | Cách triển khai |
|----------|-------------|---------------------|-----------------|
| UC12 Create Job Posting | Module 4 (Employer UI) | Module 3 (`job`) | `EmployerController` → `JobService` |
| UC13 Manage Job Postings | Module 4 (Employer UI) | Module 3 (`job`) | `EmployerController` → `JobService` |
| UC19 Moderate Job Postings | Module 5 (Admin UI) | Module 3 (`job`) | `AdminService` → `JobService.updateStatus()` |
| UC20 Manage Skills | Module 5 (Admin UI) | Module 1 (`skill`) | `AdminService` → `SkillService` |
| UC21 Manage Job Categories | Module 5 (Admin UI) | Module 3 (`category`) | `AdminService` → `JobService.manageCategory()` |

> ⚠️ **Module 1 cần expose `SkillService`** cho Module 5 (UC20).
> ⚠️ **Module 3 cần expose `JobService` (CRUD + `manageCategory`)** cho Module 4 và Module 5.
> 💡 Các contract này cần được 2 bên khoá signature **trước khi code**.

---

## Phân biệt Use Case Diagram vs Use Case Specification

| | Use Case LIST (bảng spec) | Use Case DIAGRAM (vẽ) |
|---|-------------------------------|---------------------------|
| Mục đích | Requirements đầy đủ để code/test | Trực quan hóa business value cho stakeholder |
| Số lượng | Đầy đủ (27 UC) | Chọn lọc (~24 UC) |
| Đối tượng | Developer, QA | Khách hàng, giảng viên, team review |

### UC KHÔNG vẽ trong diagram

| ID | Use Case | Lý do |
|----|----------|-------|
| 27 | Log Out | Quá cơ bản, hiển nhiên — mọi hệ thống đều có |
| 26 | Change Password | Gộp vào UC03 Manage Profile (đã đăng nhập) |

### UC vẽ dạng `<<extend>>`

| ID | Use Case | Cách vẽ |
|----|----------|---------|
| 25 | Reset Password | `<<extend>>` từ UC02 Log In (chỉ trigger khi user quên pass) |

```
[Job Seeker] ──► (02 Log In) ◄────<<extend>>──── (25 Reset Password)
```

### Gợi ý dùng `<<include>>`

Thể hiện dependency nghiệp vụ mà không phải thêm UC mới:

- UC08 Apply for Job ──`<<include>>`──► UC04 Upload Resume
- UC15 Review Application ──`<<include>>`──► UC23 AI Resume Analysis

### Tổng kết Use Case Diagram

```
Module 1 (AI):    3 UC độc lập (04, 10, 23)
Module 2 (Auth):  3 UC độc lập (01, 02, 03) + UC25 dạng extend
Module 3 (Job):   5 UC (05, 06, 07, 12, 13)
Module 4 (Emp):   6 UC (08, 09, 11, 14, 15, 16)
Module 5 (Admin): 7 UC (17, 18, 19, 20, 21, 22, 24)
─────────────────────────────────────────────────────────
Tổng diagram: ~24 UC (loại UC26, UC27)
```

---

## Ma trận phụ thuộc (ai cần gì từ ai)

| Module ↓ cần \ Module → cung cấp | 1 AI | 2 Auth | 3 Job | 4 Employer | 5 Admin |
|----------------------------------|------|--------|-------|------------|---------|
| 1 AI | – | JobSeeker profile | searchJobs, findJobById | – | – |
| 2 Auth | – | – | – | findEmployerByEmail | – |
| 3 Job | – | – | – | employerId từ employer | – |
| 4 Employer | resume của ứng viên | userId từ auth | Job CRUD | – | – |
| 5 Admin | recommendation stats | user count | job count | employer count | – |

---

## File backend CHUNG (ai cũng sửa được, không thuộc module nào)

```
backend/src/app.js                  Pipeline Express
backend/src/server.js               Entry point
backend/src/config/                 Cấu hình (env, supabase)
backend/src/utils/                  ApiError, ApiResponse, logger, asyncHandler
backend/src/middlewares/errorHandler.js
backend/src/middlewares/notFoundHandler.js
backend/src/middlewares/validateRequest.js
package.json, eslint.config.js, .env.example
```

> Khi sửa file chung, comment rõ trong commit để cả team review.

---

## Quy trình làm việc nhóm

1. **Mỗi module làm trong phase riêng** (theo `docs/07_AI_AGENT_RULES.md §22`)
2. **Branch riêng theo module**: `feature/auth`, `feature/ai-resume`, ...
3. **Interface contract khoá trước**: 2 người phụ 2 đầu phải thống nhất
   function signature trước khi code (vd: `RecommendationService` cần biết
   chính xác `JobService.searchJobs` trả về shape gì)
4. **Conflict chỉ xảy ra ở file chung** → resolve bằng pair programming
5. **Migration DB**: mỗi module tự viết migration cho bảng mình sở hữu trong
   `docs/11_MIGRATIONS.md` (đánh số Migration 002, 003, ...)
