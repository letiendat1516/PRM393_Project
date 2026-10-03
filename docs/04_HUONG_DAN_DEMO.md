# 04. Hướng dẫn demo đồ án JobHub (10 phút)

Kịch bản bảo vệ chạy **song song 2 môi trường**: trình duyệt Chrome (bản web, làm luồng chính) và Android emulator (bản mobile, minh hoạ thêm). Toàn bộ nhãn nút/menu trong tài liệu được đối chiếu trực tiếp với chuỗi tiếng Việt trong code (`lib/`), nên bấm theo tài liệu sẽ khớp màn hình thật.

| Mục | Nội dung |
|---|---|
| Ứng dụng | JobHub — cổng việc làm ứng dụng AI (port từ web JobHub) |
| Công nghệ | Flutter (Mobile + Web), Firebase Auth + Firestore + FCM, Riverpod 2, MVVM, SharedPreferences |
| Thời lượng | 10 phút |
| Luồng demo | Ứng viên (tìm việc → CV → AI → ứng tuyển) → Nhà tuyển dụng (đăng tin, duyệt hồ sơ) → Admin (duyệt tin) → Thông báo FCM |

---

## 1. Chuẩn bị trước demo (checklist)

Làm tuần tự các bước sau, **không để bất kỳ bước nào chạy lần đầu trong lúc demo**:

- [ ] **1. Lấy dependencies**
  ```bash
  flutter pub get
  ```

- [ ] **2. Deploy Firestore rules + indexes** (theo `firebase.json`: `firestore.rules` và `firestore.indexes.json`)
  ```bash
  firebase deploy --only firestore
  ```
  Bỏ qua bước này sẽ gặp lỗi *“Truy vấn cần chỉ mục Firestore. Hãy deploy firestore.indexes.json.”* ở các trang danh sách (xem mục 4).

- [ ] **3. Chạy 2 môi trường**
  ```bash
  # Web (Chrome) — luồng demo chính
  flutter run -d chrome
  # Nếu muốn demo thông báo đẩy web, thêm VAPID key (Firebase Console → Project settings → Cloud Messaging → Web Push certificates):
  flutter run -d chrome --dart-define=FCM_VAPID_KEY=<vapid-key>

  # Android emulator (đã mở AVD trước) — dùng để quay sang phần mobile
  flutter run            # chọn emulator trong danh sách thiết bị, hoặc:
  flutter devices        # xem deviceId rồi flutter run -d <deviceId>
  ```

- [ ] **4. Tạo tài khoản admin** — đăng ký bình thường tại **/dang-ky** với email `admin@jobhub.vn`.
  Danh sách email admin mặc định là `ADMIN_EMAILS=admin@jobhub.vn` (`lib/core/config/app_config.dart`), nên tài khoản đăng ký bằng email này **tự động nhận vai trò admin** — không cần tạo tay trong Firestore.

- [ ] **5. Seed dữ liệu demo** — đăng nhập admin → menu **Tổng quan** (trang **/admin**, tiêu đề “Tổng quan quản trị”) → bấm nút **“Seed dữ liệu demo”** → xác nhận **“Seed dữ liệu”**.
  Thao tác ghi vào Firestore: **18 ngành nghề**, các kỹ năng phổ biến (trích từ tag của 18 tin), **18 hồ sơ nhà tuyển dụng demo** (12 công ty của bộ 12 tin chi tiết + 6 doanh nghiệp của 6 tin nổi bật) và **18 tin tuyển dụng đã duyệt** (12 tin mẫu `SYN-00001…00012` + 6 tin nổi bật `jb-001…006` từ `lib/core/data/demo_data.dart`), kèm cấu hình mặc định (`MAX_SKILLS_PER_JOB`, `DEFAULT_DEADLINE_DAYS`, `REQUIRE_JOB_APPROVAL`, `GEMINI_API_KEY`). Thao tác **idempotent** (ghi đè merge theo id), chạy lại bao nhiêu lần cũng an toàn. Thông báo hoàn tất có dạng: *“Đã seed dữ liệu demo: … ngành nghề, … kỹ năng, … nhà tuyển dụng, … tin tuyển dụng và cấu hình mặc định.”*
  Sau khi seed, trang chủ có “Việc làm nổi bật” và **/viec-lam** có dữ liệu tìm kiếm.

- [ ] **6. Cấu hình Gemini API key (nếu có)** — admin → menu **Cấu hình hệ thống** (trang **/admin/system-configurations**) → panel **“Gemini API key”** → dán key (`AIza...`) → **“Kiểm tra”** → **“Lưu & dùng”** (key lưu vào `systemConfigurations/GEMINI_API_KEY`, áp dụng ngay không cần chạy lại app).
  **Không có key vẫn demo được**: AI Matching chuyển sang chế độ **“Chấm điểm với SQL”** (bộ chấm điểm rule-based chạy ngay trên máy, không gọi AI); các tính năng AI khác (Trích xuất CV, Phân tích CV) sẽ báo *“Chưa cấu hình Gemini API key. Admin vào Cấu hình hệ thống → GEMINI_API_KEY.”*.

- [ ] **7. Lưu ý upload CV** — dự án **chưa bật Firebase Storage** (cần gói Blaze): tệp PDF không lưu được file nhị phân, app vẫn lưu metadata và hiện cảnh báo Storage. Khi demo hãy upload CV dạng **tệp `.txt`** hoặc bấm **“Dán nội dung CV”** để dán trực tiếp văn bản — cả hai đều đủ để AI phân tích và chấm điểm.

- [ ] **8. Chuẩn bị dữ liệu nhập sẵn** — soạn sẵn: 1 đoạn nội dung CV (dạng text, ≥ 20 ký tự), 1 tệp `cv-demo.txt` cho phần mobile, và 3 tài khoản demo ở mục 5.

- [ ] **9. Mobile: muốn demo onboarding lần đầu** — onboarding chỉ hiện ở lần khởi động đầu (`isFirstLaunch` lưu trong SharedPreferences). Gỡ cài đặt app trên emulator rồi chạy lại để nó xuất hiện; hoặc bỏ qua (nhãn: “Bỏ qua” / “Tiếp tục” / “Bắt đầu”).

---

## 2. Kịch bản demo theo mốc thời gian (10 phút)

| Phút | Thao tác | Route | Điều cần nói |
|---|---|---|---|
| **0:00–1:00** | Giới thiệu đồ án + dạo trang chủ: hero “Nền tảng tuyển dụng ứng dụng AI”, dải thống kê (30.000+ việc làm đang tuyển, 10.000+ doanh nghiệp đối tác, 150.000+ ứng viên tin tưởng, 95% độ chính xác gợi ý), khối “Việc làm nổi bật” kèm chip ngành nghề, nút “Xem tất cả việc làm” | `/` | Kiến trúc: Flutter Mobile + Web chung 1 codebase; Firebase Auth (đăng ký/đăng nhập), Firestore (dữ liệu realtime), FCM (thông báo); Riverpod 2 quản lý trạng thái theo MVVM; dữ liệu vừa seed ở bước chuẩn bị. |
| **1:00–2:00** | Đăng ký ứng viên: trang “Tạo hồ sơ ứng viên miễn phí” → điền Họ và tên / Email / Mật khẩu / Nhập lại mật khẩu → nút **“Tạo tài khoản”**. Đăng nhập xong vào **Hồ sơ & CV** → **“Lưu thay đổi”** để hoàn thiện hồ sơ | `/dang-ky` → `/ho-so/chinh-sua` | Firebase Auth `createUserWithEmailAndPassword`; bản ghi `users/{uid}` kèm role (`job_seeker`); email nằm trong `ADMIN_EMAILS` sẽ nhận role admin (đã dùng ở bước chuẩn bị). Validate form chạy cả client lẫn Firestore rules. |
| **2:00–3:30** | Nhập CV: khối tải CV — điền “Tên CV”, bấm **“Chọn tệp”** chọn `cv-demo.txt` (PDF hoặc .txt, tối đa 5 MB) → **“Tải CV”**. Không có Storage thì dùng nút **“Dán nội dung CV”**. Sau đó bấm **“Trích xuất CV”** → đợi “AI đang đọc & phân tích CV — có thể mất 30–90 giây...”. Xong, mở trang phân tích: “Phân tích CV bằng AI”, đối chiếu “Thống kê trích xuất” (kỹ năng, kinh nghiệm, học vấn, ngôn ngữ, chứng chỉ) | `/ho-so` → `/ho-so/phan-tich/:resumeId` | CV text lưu tại `resumes/{id}.rawText`; Gemini trích xuất và cấu trúc hoá CV thành JSON; kết quả lưu Firestore, xem lại được (“Phân tích lại”). Không có key: dùng `.txt` + chấm điểm SQL ở bước sau, hoặc nhập key ở Admin → Cấu hình hệ thống. |
| **3:30–4:30** | Tìm việc: ô “Tìm kiếm theo:” gõ từ khoá (gợi ý “Vị trí, kỹ năng, công ty...”) + chọn tỉnh → **“Tìm kiếm”**; mở sidebar **“Bộ lọc”** (ngành nghề, mức lương, kinh nghiệm, hình thức làm việc). Vào chi tiết 1 tin → bấm **“Lưu tin”** (đổi thành “Đã lưu tin”) → mở trang **“Việc đã lưu”** | `/viec-lam` → `/viec-lam/:id` → `/viec-da-luu` | Truy vấn Firestore dùng composite index (đã deploy ở bước 2); tin chưa duyệt không bao giờ hiện ở đây (lọc theo `isApproved`); lưu tin ghi vào collection `savedJobs` theo `jobSeekerId`. |
| **4:30–6:00** | AI Matching: trên trang việc làm bấm nút **“AI Matching”** (chỉ bật khi có kết quả lọc, cần ≤ 100 tin). Trong sheet “AI Matching”: chọn tab **“CV CỦA TÔI (ĐÃ TRÍCH XUẤT)”** hoặc **“Tải lên CV mới”** → “Hoặc dán nội dung CV” dán text. Chọn phương pháp: **“Chấm điểm với AI”** / **“Chấm điểm với SQL”** / **“Chấm điểm với AI + SQL”**. Xem tiến độ “Đang chấm điểm — đang xử lý X/Y việc làm...”, kết quả “Kết quả chấm điểm (scored/total việc làm)” xếp hạng theo điểm, mỗi tin có huy hiệu “Điểm AI” / “Điểm SQL”. Bấm **“Lưu kết quả”** → “Đã lưu phiên chấm điểm.” → **“Xem phiên”**; quay lại **/de-xuat** thấy danh sách phiên, mở 1 phiên | `/viec-lam` → sheet → `/de-xuat` → `/de-xuat/:sessionId` | AI gọi Gemini theo batch 10 tin, chạy 2 luồng song song, có retry/backoff; SQL là bộ chấm điểm rule-based (kỹ năng khớp, mức lương, địa điểm...) chạy tức thì, không cần key. Mỗi lượt gọi AI được ghi log (prompt/response/thời gian) vào trang AI Logs (`/ai-logs`) —admin xem được. |
| **6:00–7:00** | Ứng tuyển: từ chi tiết tin bấm **“Ứng tuyển ngay”**; wizard 3 bước — bước 1 “Chọn CV sẽ gửi cho nhà tuyển dụng” → **“Tiếp tục”** (soạn thư giới thiệu) → **“Xác nhận ứng tuyển”**. Mở trang **“Hồ sơ đã ứng tuyển”** xem trạng thái “Đã nộp” | `/viec-lam/:id/ung-tuyen` → `/applications` | Mỗi hồ sơ ứng tuyển có id deterministic `{jobSeekerId}_{jobId}` → không ứng tuyển trùng; trạng thái và lịch sử lưu realtime; NTD nhận thông báo “Có ứng viên mới”. |
| **7:00–8:30** | Nhà tuyển dụng: mở tab ẩn/dọn bật (hoặc đăng xuất) → trang “Đăng ký tài khoản Nhà tuyển dụng” → **“Đăng ký tài khoản”**. Vào **Tổng quan** NTD → **“Đăng tin mới”** → form “Tạo tin tuyển dụng mới” (điền tên tin, ngành, lương, kỹ năng, mô tả...) → **“Tạo tin tuyển dụng”**. App báo *“Đã tạo tin tuyển dụng. Tin đang chờ quản trị viên duyệt.”*; trong “Tin tuyển dụng” tin mới mang chip **“Chờ duyệt”** | `/dang-ky-nha-tuyen-dung` → `/employer` → `/employer/jobs/create` → `/employer/jobs` | Luồng duyệt 2 cấp theo cấu hình `REQUIRE_JOB_APPROVAL`: tin mới luôn `isApproved = false`; chỉ NTD sở hữu mới sửa được tin của mình (Firestore rules). |
| **8:30–9:15** | Admin duyệt tin: đăng nhập `admin@jobhub.vn` → **/admin** “Tổng quan quản trị” → quick link **“Duyệt tin tuyển dụng”** → trang “Danh sách tin chờ duyệt” → xem trước tin vừa đăng → bấm **“Duyệt”** (hoặc “Từ chối” kèm lý do). Quay lại **/viec-lam** (tab ứng viên) — tin đã lên danh sách public, trạng thái “Đang tuyển” | `/admin` → `/admin/pending-jobs` → `/viec-lam` | Chỉ role `admin` duyệt được (rules chặn phía server); sau duyệt tin hiện ngay bên ứng viên nhờ stream Firestore. |
| **9:15–10:00** | NTD duyệt hồ sơ + thông báo: quay về tab NTD → **“Hồ sơ ứng tuyển”** → mở chi tiết hồ sơ (nút “← Danh sách hồ sơ”, “Nhắn tin cho ứng viên”) → khối **“Cập nhật trạng thái”**: chọn “Đang xem xét” → **“Cập nhật”**, rồi chọn “Được nhận” → **“Cập nhật”** (timeline “Lịch sử trạng thái” ghi lại từng bước). Quay sang tab ứng viên: **/notifications** (“Thông báo”) xuất hiện realtime *“Hồ sơ ứng tuyển được cập nhật”*; bấm **“Đọc tất cả”**. Trên **emulator**: nhận banner thông báo (kênh `jobhub_default`). Kết thúc: tóm tắt lại kiến trúc + cảm ơn | `/employer/applications` → `/employer/applications/:id` → `/notifications` | Chuyển trạng thái bị khoá theo máy trạng thái (Đã nộp → Đang xem xét → Được nhận/Từ chối), sai chuyển sẽ bị từ chối; mỗi lần cập nhật ghi thêm document `notifications` cho ứng viên — danh sách cập nhật realtime bằng Firestore snapshot, thiết bị mobile nhận push qua FCM (token lưu tại `users/{uid}.fcmTokens`). |

---

## 3. Mobile demo thêm (quay sang emulator ~1 phút, có thể lồng vào các mốc trên)

- **Onboarding lần đầu**: lần khởi động đầu tiên app tự chuyển sang `/onboarding` — 3 slide “Tìm việc bằng AI”, “Theo dõi hồ sơ realtime”, “Nhà tuyển dụng duyệt nhanh”; điều hướng bằng **“Tiếp tục”**, bỏ qua bằng **“Bỏ qua”**, slide cuối bấm **“Bắt đầu”**. Cờ `isFirstLaunch` lưu trong SharedPreferences — muốn xem lại thì gỡ cài đặt app (hoặc xoá dữ liệu app) rồi mở lại.
- **Xin quyền POST_NOTIFICATIONS (Android 13+)**: lần đầu khởi động, `FcmService.initialize()` gọi `requestPermission` (alert/badge/sound) → hệ thống hiện hộp thoại xin phép thông báo; chọn **Cho phép**. Thông báo hiển thị trên kênh Android **`jobhub_default`** (“JobHub notifications”, importance high).
- **Dark mode**: vào **Cài đặt** (`/settings`) → mục **“Giao diện”** → chọn **“Tối”** (hoặc “Theo hệ thống” / “Sáng”) — theme đổi tức thì và được ghi nhớ qua SharedPreferences.
- **Cài đặt thông báo**: cùng trang, mục “Thông báo” → công tắc **“Nhận thông báo đẩy”** (tắt sẽ gỡ token FCM khỏi `users/{uid}`), kèm bật/tắt từng loại thông báo.
- **Remember me**: màn **Đăng nhập** có ô **“Ghi nhớ đăng nhập (giữ phiên 7 ngày, không bị out khi reload)”** — bật thì email được điền sẵn lần sau và phiên được giữ (persistence LOCAL 7 ngày; tắt thì chỉ phiên ngắn).

---

## 4. Sự cố thường gặp & cách xử lý

| # | Tình huống | Hiện tượng | Cách xử lý tại chỗ |
|---|---|---|---|
| 1 | Không có / hết hạn `GEMINI_API_KEY` | Trích xuất & phân tích CV báo *“Chưa cấu hình Gemini API key. Admin vào Cấu hình hệ thống → GEMINI_API_KEY.”*; chấm điểm AI thất bại | Nói rõ: hệ thống vẫn chấm điểm được bằng **“Chấm điểm với SQL”** (rule-based, không cần key). Có key thì vào Admin → **Cấu hình hệ thống** → panel “Gemini API key” → **“Lưu & dùng”** (áp dụng ngay, không restart). |
| 2 | Storage chưa bật (không có gói Blaze) | Upload PDF bị cảnh báo “Tệp chưa được lưu trữ...”; AI không đọc được nội dung PDF | Dùng **tệp `.txt`** hoặc bấm **“Dán nội dung CV”** — text lưu vào `rawText` và đủ cho toàn bộ luồng phân tích + matching. Nói đây là giới hạn của gói miễn phí, thiết kế đã có phương án dự phòng. |
| 3 | Thiếu Firestore composite index | Lỗi đỏ: *“Truy vấn cần chỉ mục Firestore. Hãy deploy firestore.indexes.json.”* (thường gặp ở Việc đã lưu, Hồ sơ đã ứng tuyển, Thông báo) | Chạy `firebase deploy --only firestore`; hoặc mở link tạo index mà Firebase Console cung cấp trong thông báo lỗi, rồi tải lại trang. |
| 4 | Web không nhận push | Không thấy thông báo bật lên trên Chrome | Web push bắt buộc VAPID key: chạy lại `flutter run -d chrome --dart-define=FCM_VAPID_KEY=<key>` **và** cấp quyền thông báo cho site (icon khoá/chuông trên thanh địa chỉ). Không có key thì vẫn demo được: trang `/notifications` cập nhật realtime bằng Firestore. |
| 5 | Tài khoản bị khoá (`isActive = false`) | Đăng nhập bị từ chối: *“Tài khoản đã bị vô hiệu hóa.”* (mã `ACCOUNT_DISABLED`) | Đây là tính năng admin khoá/mở tài khoản, không phải lỗi — nói rõ cơ chế; để mở lại, admin set `isActive = true` trên `users/{uid}` rồi đăng nhập lại. |
| 6 | Nút “AI Matching” bị mờ, kèm nhãn “cần ≤100” | Kết quả tìm kiếm nhiều hơn 100 tin | Tiện thể giới hạn tối đa 100 tin/lượt chấm — thêm bộ lọc (ngành, địa điểm, lương) rồi nút tự bật. |
| 7 | Đăng ký tin NTD xong không thấy trên /viec-lam | Tin mang chip “Chờ duyệt” ở `/employer/jobs` | Đúng thiết kế: chờ admin duyệt ở `/admin/pending-jobs` (mốc 8:30–9:15). |

---

## 5. Tài khoản demo gợi ý

Tạo sẵn cả 3 tài khoản **trước** buổi demo (mật khẩu ví dụ `JobHub@2026` — đúng ràng buộc tối thiểu 8 ký tự):

| Vai trò | Đăng ký tại | Email | Mật khẩu | Ghi chú |
|---|---|---|---|---|
| Ứng viên (job_seeker) | `/dang-ky` | `minh@jobhub.vn` | `JobHub@2026` | Tài khoản luồng chính: CV, AI Matching, ứng tuyển, nhận thông báo. |
| Nhà tuyển dụng (employer) | `/dang-ky-nha-tuyen-dung` | `hr@jobhub.vn` | `JobHub@2026` | Đăng tin, duyệt hồ sơ, nhắn tin ứng viên. |
| Quản trị viên (admin) | `/dang-ky` | `admin@jobhub.vn` | `JobHub@2026` | Nằm trong `ADMIN_EMAILS` mặc định → tự nhận role admin khi đăng ký; dùng để seed dữ liệu, cấu hình Gemini key, duyệt tin. |

> Mẹo trình diễn: mở Chrome với 3 hồ sơ/cửa sổ riêng (hoặc 1 Chrome + 1 emulator) cho 3 vai trò để không phải đăng xuất/đăng nhập lại giữa chừng — mỗi mốc thời gian chỉ cần đổi cửa sổ.
