# 05 — Dàn ý slide bảo vệ JobHub (PRM393)

> 12–15 slide, mỗi slide ~40 giây (tổng ~10 phút trình bày + demo/Q&A).

---

## Slide 1 — Bìa

- JobHub — ứng dụng tuyển dụng AI (Mobile + Web)
- Học phần PRM393 — Lập trình di động
- Nhóm 5 thành viên
- Flutter · Firebase · Riverpod · Gemini

**Nói gì:** Chào giảng viên, giới thiệu tên đề tài JobHub — nền tảng tuyển dụng hai vai trò tích hợp AI, sản phẩm của nhóm 5, xây dựng bằng Flutter cho cả mobile và web.

**Minh hoạ:** Logo JobHub (`assets/icons/favicon.svg`), tên các thành viên + MSSV, ảnh chụp màn hình Home trên emulator Android.

---

## Slide 2 — Bài toán & mục tiêu

- Kết nối ứng viên ↔ nhà tuyển dụng, admin điều hành
- Hai vai trò chính + quản trị hệ thống
- AI phân tích CV, gợi ý việc làm phù hợp
- Thông báo realtime, chat hai chiều
- Mục tiêu: port 100% web app sang Flutter

**Nói gì:** Web JobHub gốc (React + Node + Postgres) đã có; bài toán là đem toàn bộ nghiệp vụ tuyển dụng đó lên mobile với Firebase thay backend riêng, thêm trải nghiệm mobile như push và dark mode.

**Minh hoạ:** Sơ đồ 3 vai trò (ứng viên — NTD — admin) với nghiệp vụ chính mỗi vai trò; tham chiếu mô tả hệ thống trong `README.md`.

---

## Slide 3 — Tổng quan tính năng (35 màn hình)

- 11 màn Public: việc làm, công ty, đề xuất, auth
- 7 màn Ứng viên: hồ sơ, CV, ứng tuyển, việc đã lưu
- 8 màn Nhà tuyển dụng: đăng tin, duyệt hồ sơ
- 8 màn Admin + 4 màn chung (chat, thông báo, cài đặt)

**Nói gì:** Ứng dụng gồm 35 route theo README (liệt kê đủ 38 định danh: 11 public, 7 ứng viên, 8 NTD, 8 admin, 4 chung — một số màn có thêm route chi tiết); mỗi nghiệp vụ đều có màn riêng, từ tìm việc, ứng tuyển đến quản trị duyệt tin và cấu hình AI.

**Minh hoạ:** Ảnh lưới (grid) screenshot 8–12 màn đại diện theo nhóm vai trò; danh sách đầy đủ 35 route trong `README.md` mục "Màn hình (35 routes)".

---

## Slide 4 — Công nghệ sử dụng

- Flutter (Mobile + Web), go_router + role guard
- Firebase Auth (Email/Password) phân vai trò
- Firestore: 18 bảng SQL → collections
- FCM + flutter_local_notifications
- Riverpod 2 (StreamProvider, StateNotifier), MVVM
- SharedPreferences, Gemini API

**Nói gì:** Đáp ứng đủ yêu cầu học phần: Firebase đăng nhập, notification, MVVM, Riverpod, Firestore, SharedPreferences; AI dùng Gemini với fallback chấm điểm rule-based.

**Minh hoạ:** Bảng công nghệ → yêu cầu môn học → file hiện thực (tham chiếu `docs/02_YEU_CAU_GIAO_VIEN.md` nếu đã có).

---

## Slide 5 — Kiến trúc tổng thể

- View → ViewModel (Riverpod) → Repository → Firebase
- `features/<tên>/{data,viewmodels,views,widgets}`
- `core/`: auth, fcm, prefs, firestore_refs, AI services
- `shared/`: 18 model + widget dùng chung
- Role guard điều hướng theo quyền người dùng

**Nói gì:** Kiến trúc MVVM strict: View không đụng Firebase, mọi dữ liệu qua ViewModel và Repository; core chứa service dùng chung, shared chứa model ánh xạ bảng dữ liệu.

**Minh hoạ:** Sơ đồ kiến trúc Mermaid trong `docs/03_KIEN_TRUC.md` (View → ViewModel → Repository → Firebase); sơ đồ thư mục `lib/` trong `README.md` mục "Cấu trúc".

---

## Slide 6 — Mô hình dữ liệu

- 18 bảng SQL → 14 collection + 4 subcollection
- users, jobSeekerProfiles, employerProfiles, jobs
- applications + subcollection statusHistory
- resumes + subcollection aiAnalyses
- categories, skills, savedJobs, notifications, chats
- DocId xác định → chống trùng lặp, dễ transaction

**Nói gì:** Từ schema Postgres gốc, nhóm ánh xạ sang Firestore: bảng chính thành collection, quan hệ 1-n thành subcollection; uniqueness dùng docId dựng sẵn như `ApplicationModel.docIdFor`.

**Minh hoạ:** Sơ đồ ER/collections trong `docs/03_KIEN_TRUC.md`; danh sách refs tại `lib/core/services/firestore_refs.dart`; `firestore.rules` + `firestore.indexes.json`.

---

## Slide 7 — Đăng ký / đăng nhập phân vai trò

- Hai form đăng ký riêng: ứng viên, NTD; admin tự gán qua ADMIN_EMAILS
- Firebase Auth Email/Password tạo UID
- Tạo document profile tương ứng UID
- Role guard chặn truy cập sai vai trò
- Remember-me lưu SharedPreferences

**Nói gì:** Sau khi Auth tạo tài khoản, ứng dụng ghi document users + profile theo vai trò; router dùng role guard đẩy người dùng đúng màn hình và chặn vào khu admin.

**Minh hoạ:** Screenshot `/dang-ky`, `/dang-ky-nha-tuyen-dung`; sơ đồ luồng đăng ký trong `docs/03_KIEN_TRUC.md`; luồng demo trong `docs/04_HUONG_DAN_DEMO.md`.

---

## Slide 8 — Đăng tin → Admin duyệt → Công khai

- NTD tạo tin: thông tin, lương, skills, hạn nộp
- Trạng thái chờ duyệt, chưa hiện công khai
- Admin xem pending-jobs, duyệt / từ chối
- Job public: `isApproved` + `status = OPEN`
- Tìm kiếm qua `titleTokens` không dấu

**Nói gì:** Tin mới phải qua duyệt của admin mới hiện ở khu công cộng; truy vấn public lọc theo cờ isApproved và status, tìm kiếm dùng token tiêu đề để không phân biệt dấu.

**Minh hoạ:** Screenshot `/employer/jobs/create` → `/admin/pending-jobs` → `/viec-lam`; sơ đồ luồng trong `docs/03_KIEN_TRUC.md`.

---

## Slide 9 — Ứng tuyển → Duyệt hồ sơ → Thông báo FCM

- Ứng viên nộp hồ sơ, trạng thái SUBMITTED
- NTD chuyển UNDER_REVIEW / ACCEPTED / REJECTED
- Timeline + statusHistory lưu lịch sử
- Ghi FCM token, đẩy thông báo realtime
- Icon badge số thông báo chưa đọc

**Nói gì:** Mỗi lần NTD đổi trạng thái, hệ thống ghi lịch sử và gửi push FCM tới ứng viên tức thì trên Android và web; máy offline vẫn thấy khi mở màn thông báo.

**Minh hoạ:** Screenshot `/applications/:id` (timeline), `/employer/applications/:id`, màn `/notifications` với push thực tế trên emulator; luồng Mermaid trong `docs/03_KIEN_TRUC.md`.

---

## Slide 10 — AI: phân tích CV + AI Matching

- Upload CV → extract text → Gemini phân tích
- AI Matching: chấm điểm AI + rule-based SQL
- Điểm ≤ 100, 7 tiêu chí: skills, kinh nghiệm, học vấn…
- Lưu tối đa 20 phiên AI gần nhất (SharedPreferences)
- Ghi aiMatchingLogs phục vụ thống kê admin

**Nói gì:** Có Gemini key thì CV được phân tích và chấm điểm bằng AI; không key vẫn chạy chấm điểm rule-based port từ backend gốc; mỗi phiên kết quả được lưu lại để xem lại, tối đa 20 phiên.

**Minh hoạ:** Screenshot `/ho-so/phan-tich/:resumeId` (kết quả phân tích), `/de-xuat` (danh sách điểm matching), `/ai-logs` + `/admin/ai-stats`; cấu hình `GEMINI_API_KEY` / `GEMINI_MODEL`.

---

## Slide 11 — Trải nghiệm mobile

- Onboarding 3 bước lần đầu mở app
- Dark mode theo hệ thống, đổi trong Cài đặt
- Push notification + kênh `jobhub_default`
- Responsive: web 2 cột, mobile 1 cột
- SharedPreferences: theme, ngôn ngữ, onboarding

**Nói gì:** Ngoài nghiệp vụ, nhóm đầu tư trải nghiệm mobile: onboarding giới thiệu app, dark mode, xin quyền thông báo Android 13+ và layout thích ứng khi chạy web.

**Minh hoạ:** Screenshot `/onboarding`, `/settings` light/dark, ảnh push notification thật trên emulator Android; kịch bản trong `docs/04_HUONG_DAN_DEMO.md`.

---

## Slide 12 — Phân công 5 thành viên

- (a) Auth + hồ sơ ứng viên (kèm splash, 404)
- (b) Tìm việc: trang chủ, chi tiết, công ty, việc đã lưu
- (c) CV/AI + ứng tuyển: upload, phân tích, matching, đề xuất
- (d) Nhà tuyển dụng: đăng tin, duyệt, hồ sơ công ty
- (e) Thông báo + chat + cài đặt + admin
- Mỗi người ≥ 3 màn hình mức medium trở lên

**Nói gì:** Chia việc theo trục tính năng, mỗi thành viên phụ trách trọn stack view–viewmodel–repository của mảng mình; bảng chi tiết kèm route, file và mức độ.

**Minh hoạ:** Bảng phân công trong `docs/01_PHAN_CONG.md` (tên màn — route — file — mức độ — người phụ trách).

---

## Slide 13 — Khó khăn & giải pháp

- Port 100% UI 35 màn: dùng lại token, widget chung
- Firebase Storage chưa bật (cần Blaze)
- → CV lưu metadata + nội dung text
- Race condition đổi trạng thái hồ sơ
- → Transaction + kiểm tra trạng thái cũ
- Thi key Gemini: fallback chấm điểm SQL

**Nói gì:** Ba khó khăn tiêu biểu: khối lượng UI lớn được giải bằng widget dùng chung; chưa có Storage nên CV lưu text để AI vẫn chạy; đổi trạng thái đụng nhau được xử lý bằng transaction kiểm tra expectedCurrentStatus.

**Minh hoạ:** Đối chiếu lỗi "Hồ sơ đã được cập nhật" (409) tại `ApplicationModel.transitions`; ghi chú Storage trong `README.md`.

---

## Slide 14 — Kết luận & hướng phát triển

- Đáp ứng đủ 6 yêu cầu học phần
- 35 màn hình, 3 vai trò, AI matching hoàn chỉnh
- Cải thiện: bật Storage, upload CV PDF thật
- Chat realtime với presence, thanh toán, thống kê sâu
- Đăng lên CH Play / App Store

**Nói gì:** Sản phẩm hoàn thành port toàn bộ web app với đầy đủ yêu cầu công nghệ của môn; hướng đi tiếp theo là lưu trữ file thật, chat phong phú hơn và phát hành chính thức.

**Minh hoạ:** Bảng yêu cầu → kết quả (tick); bảng "hiện tại vs tương lai".

---

## Slide 15 — Demo + Q&A

- Chạy app Android (emulator) + web Chrome
- Kịch bản: seed → ứng tuyển → duyệt → nhận push
- Nhóm demo theo vai, ~5 phút
- Xin cảm ơn, mời đặt câu hỏi

**Nói gì:** Nhóm chuẩn bị demo trực tiếp theo kịch bản 10 phút trong docs/04; sẵn sàng chạy lại bất kỳ luồng nào theo yêu cầu của giảng viên.

**Minh hoạ:** Theo sát `docs/04_HUONG_DAN_DEMO.md`; mở sẵn 2 thiết bị (emulator ứng viên + web NTD) để thấy thông báo realtime.
