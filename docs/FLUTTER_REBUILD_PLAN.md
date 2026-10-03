# JOBHUB MOBILE — Kế hoạch xây dựng lại bằng Flutter

> Đề tài: **JobHub — Nền tảng tuyển dụng ứng dụng AI (Mobile App)**
> Yêu cầu học phần: nhóm 5 người, mỗi người ≥ 3 screens mức medium trở lên,
> Firebase (login + notification), MVVM, Riverpod, Firestore/SQLite,
> SharedPreferences.

---

## 1. Tổng quan & ý tưởng

Xào lại web JobHub (đã có: 9,800 jobs, AI chấm điểm CV) thành **app mobile
Flutter** cho 2 persona: **Ứng viên** (tìm việc, nộp CV, theo dõi hồ sơ) và
**Nhà tuyển dụng** (đăng tin, duyệt ứng viên).

Tính năng nổi bật (điểm cộng đồ án):
- 🔥 **AI Matching**: chấm điểm CV ↔ Job qua API (Gemini free tier) —亮点 khác biệt
- 🔔 **Push notification** realtime khi trạng thái hồ sơ thay đổi (FCM)
- 💬 **Chat** ứng viên ↔ nhà tuyển dụng (Firestore streams)

## 2. Tech Stack (mapping từ web cũ)

| Thành phần | Web cũ (React/Node) | Mobile mới (Flutter) |
|-----------|--------------------|---------------------|
| UI | React + Tailwind | **Flutter + Material 3** |
| State | React state | **Riverpod 2.x** (StateNotifier/AsyncNotifier) |
| Architecture | MVC layer | **MVVM** (View ← ViewModel ← Repository) |
| Login | JWT tự viết | **Firebase Auth** (Email/Password + Google) |
| Database | Supabase (Postgres) | **Cloud Firestore** (chính) |
| File CV | Multer + disk | **Firebase Storage** |
| Notification | — | **Firebase Messaging (FCM)** |
| Config lưu local | — | **SharedPreferences** (dark mode, ngôn ngữ, token…) |
| AI chấm điểm | DeepSeek | **Gemini API** (free tier, gọi từ app) |

## 3. Kiến trúc MVVM + Riverpod

```
┌─────────────────────────────────────────────┐
│ VIEW (Screens + Widgets)                    │  ← chỉ build UI, không logic
│   ConsumerWidget / ConsumerStatefulWidget   │
├─────────────────────────────────────────────┤
│ VIEWMODEL (Riverpod providers)              │  ← business logic, state
│   AsyncNotifier<X> / StateNotifier<X>       │
├─────────────────────────────────────────────┤
│ REPOSITORY (abstract + impl)                │  ← giao tiếp dữ liệu
├─────────────────────────────────────────────┤
│ SERVICES: FirebaseAuthService,              │
│   FirestoreService, StorageService,         │
│   NotificationService, PrefsService,        │
│   GeminiService (AI)                        │
└─────────────────────────────────────────────┘
```

Cấu trúc thư mục `lib/`:
```
lib/
├── main.dart
├── app.dart                      # MaterialApp + Router
├── core/
│   ├── constants/                # collections, enums
│   ├── theme/                    # light/dark theme
│   ├── router/                   # go_router + guards
│   └── utils/                    # validators, formatters
├── data/
│   ├── models/                   # User, Job, Resume, Application,
│   │                             #   NotificationItem, ChatMessage
│   ├── repositories/             # auth, job, resume, application,
│   │                             #   notification, chat, prefs
│   └── services/                 # firebase_*, gemini, fcm
├── viewmodels/
│   ├── auth_viewmodel.dart
│   ├── job_feed_viewmodel.dart
│   ├── job_search_viewmodel.dart
│   ├── resume_viewmodel.dart
│   ├── application_viewmodel.dart
│   ├── employer_jobs_viewmodel.dart
│   ├── applicants_viewmodel.dart
│   ├── chat_viewmodel.dart
│   ├── notification_viewmodel.dart
│   └── settings_viewmodel.dart
└── views/
    ├── auth/                     # TVV các screens của thành viên 1
    ├── seeker/                   # …
    ├── employer/
    ├── chat/
    └── settings/
```

## 4. Data Model — Firestore Collections

```
users/{uid}                    # role: seeker|employer, name, avatar, headline, city
jobs/{jobId}                   # title, employerId, salary range, city, type,
  └─ (sub) skills[]            #   status, isApproved, deadline, description
resumes/{resumeId}             # ownerId, fileUrl, fileName, isPrimary,
                               #   aiAnalysis (skills[], summary, score)
applications/{appId}           # jobId, seekerId, resumeId, coverLetter,
                               #   status: submitted→reviewing→accepted|rejected,
                               #   statusHistory[{from,to,at,by}]
notifications/{notifId}        # userId, type, title, body, isRead, createdAt
chats/{chatId}                 # participants[uid], lastMessage, updatedAt
  └─ messages/{msgId}          # senderId, content, createdAt
settings                       # → SharedPreferences (local, không lên Firestore)
```

**SharedPreferences lưu:** darkMode, locale (vi/en), fcmToken, isFirstLaunch,
lastSearchKeywords, role mặc định khi mở app, cache session.

## 5. PHÂN CÔNG 5 THÀNH VIÊN (15 screens, mỗi người 3)

### 👤 Thành viên 1 — Auth & Hồ sơ cá nhân (4 screens)
| # | Screen | Độ khó | Điểm kỹ thuật |
|---|--------|--------|---------------|
| 1 | **Login** (email/pass + Google Sign-In, validate, error state) | Medium | Firebase Auth, Riverpod auth state |
| 2 | **Register** (chọn role seeker/employer, form nhiều trường, upload avatar) | Medium+ | Auth + Storage + role routing |
| 3 | **Edit Profile** (avatar, headline, city, kỹ năng dạng chips) | Medium | Firestore update + image picker |
| 4 | **Onboarding + Forgot Password** (3 slide intro, gửi email reset) | Medium | SharedPreferences lưu isFirstLaunch |
| | *Phụ trách chung: setup Firebase project, Auth guards, go_router* | | |

### 🔍 Thành viên 2 — Tìm việc & Khám phá (4 screens)
| # | Screen | Độ khó | Điểm kỹ thuật |
|---|--------|--------|---------------|
| 1 | **Home/Job Feed** (bottom nav, danh sách job mới, gợi ý AI, pull-refresh) | High | Firestore query + pagination (infinite scroll) |
| 2 | **Search + Filters** (từ khoá debounce, filter city/lương/loại/kinh nghiệm, bottom sheet) | High |复合 filter + debounce + stream |
| 3 | **Job Detail** (mô tả theo section, lương, deadline, nút Apply/Save/Share) | Medium | StreamBuilder realtime + deep link |
| 4 | **Saved Jobs** (danh sách đã lưu, swipe để xoá, trống-state) | Medium | Firestore + Dismissible widget |

### 📄 Thành viên 3 — CV & Ứng tuyển (4 screens)
| # | Screen | Độ khó | Điểm kỹ thuật |
|---|--------|--------|---------------|
| 1 | **My CVs** (danh sách, upload PDF, đặt CV chính, xoá) | Medium+ | File picker + Firebase Storage + progress |
| 2 | **AI CV Analysis** (hiển thị kỹ năng, số năm KN, radar/bar chart, điểm phù hợp) | High | Gemini API + chart package + parse JSON |
| 3 | **Apply Flow** (chọn CV, viết thư giới thiệu, xác nhận — 2-3 step wizard) | Medium+ | Stepper + validation + Firestore transaction |
| 4 | **Application Tracking** (tab theo trạng thái, timeline lịch sử, chi tiết) | High | Stream + status timeline UI |

### 🏢 Thành viên 4 — Nhà tuyển dụng (4 screens)
| # | Screen | Độ khó | Điểm kỹ thuật |
|---|--------|--------|---------------|
| 1 | **Employer Dashboard** (thống kê: tin đang mở, tổng hồ sơ, tỉ lệ chấp nhận — charts) | Medium | Aggregation + charts |
| 2 | **Create/Edit Job** (multi-step form: thông tin, lương, kỹ năng chips, preview — validation đầy đủ) | High | Form phức tạp + draft lưu local |
| 3 | **Applicants List** (filter theo tin/trạng thái, search tên, phân trang) | Medium | Firestore composite query |
| 4 | **Applicant Detail + Review** (xem CV PDF, điểm AI matching, đổi trạng thái accept/reject kèm reason) | High | PDF viewer + trigger FCM gửi cho ứng viên |

### 🔔 Thành viên 5 — Notification, Chat & Settings (4 screens)
| # | Screen | Độ khó | Điểm kỹ thuật |
|---|--------|--------|---------------|
| 1 | **Notification Center** (realtime qua FCM + Firestore, read/unread, đánh dấu tất cả, điều hướng theo type) | High | FCM foreground/background + stream |
| 2 | **Chat** (danh sách hội thoại + phòng chat bubbles realtime, gửi ảnh) | High | Firestore snapshots + image upload |
| 3 | **Settings** (dark mode live, ngôn ngữ vi/en, bật/tắt loại thông báo) | Medium | SharedPreferences + Riverpod persist |
| 4 | **Admin Moderation** (hàng chờ duyệt tin, approve/reject) | Medium | Firestore security rules theo role |
| | *Phụ trách chung: FCM setup, notification channel Android/iOS* | | |

> Mỗi screen đều tối thiểu: loading state, error state, empty state — tiêu chí
> "medium trở lên".

## 6. Timeline 8 tuần

| Tuần | Công việc |
|------|-----------|
| 1 | Setup Firebase (Auth/Firestore/Storage/FCM), init Flutter project, theme, router, models. Seed ~500 jobs vào Firestore (script port từ web) |
| 2 | TVV1 xong Auth flows · TVV2 Home + Job Detail cơ bản · остальные setup base viewmodels |
| 3 | TVV3 CV upload + Storage · TVV4 Create Job form · TVV5 Settings + Prefs |
| 4 | **Milestone 1**: chạy được flow Login → Xem job → Apply (bản nháp) |
| 5 | AI Analysis (Gemini) · Applicants list · Search filters |
| 6 | **Milestone 2**: Employer duyệt ứng viên → push FCM cho ứng viên |
| 7 | Chat realtime · Admin moderation · Application tracking timeline |
| 8 | Polish UI, empty/error states, dark mode, viết báo cáo + demo video |

## 7. Firebase Setup Checklist

- [ ] Tạo project Firebase, thêm Android app (`com.jobhub.app`) + iOS
- [ ] Auth: bật Email/Password + Google Sign-In
- [ ] Firestore: tạo collections theo §4 + **security rules** (seeker chỉ đọc
      jobs approved; employer chỉ sửa jobs của mình; chat chỉ participants)
- [ ] Storage: rules cho `resumes/{uid}/{file}` và avatars
- [ ] FCM: cấu hình channel Android, test push từ console
- [ ] Indexes Firestore cho query phức tạp (jobs filter + sort, messages theo time)
- [ ] Script seed jobs (Node, dùng `firebase-admin`): port từ 9,800 jobs web,
      mỗi ngành lấy ~10 → ~500 jobs là đủ demo mượt

## 8. Điểm cộng khi bảo vệ (gợi ý demo)

1. Đăng nhập Google → tìm "Backend Developer" tại HCM → xem chi tiết
2. Upload CV → AI phân tích (Gemini) → hiện chart kỹ năng + gợi ý job phù hợp
3. Apply → **điện thoại nhà tuyển dụng nhận push FCM ngay lập tức**
4. NTD bấm Accept → ứng viên nhận notification → mở app thấy timeline đổi màu
5. Chat 2 thiết bị realtime
6. Bật dark mode → quit app → mở lại vẫn nhớ (SharedPreferences)
