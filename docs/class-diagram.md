# JobHub — Class Diagram

Tài liệu giải thích class diagram của dự án JobHub.

- **Sơ đồ ảnh (PNG):** [`diagrams/class-diagram.png`](./diagrams/class-diagram.png)
- **Mã nguồn (để sửa):** [`diagrams/class-diagram.mmd`](./diagrams/class-diagram.mmd)

> Mở file PNG để xem sơ đồ ở kích thước đầy đủ (render 2400px, phóng to vẫn rõ).

---

## 1. Cấu trúc một Class

Mỗi class trong sơ đồ được vẽ thành 3 ô (chuẩn UML):

```
┌─────────────────────────┐
│          Job             │   ← (1) TÊN CLASS
├─────────────────────────┤
│ - UUID job_id            │   ← (2) ATTRIBUTE (field / property)
│ - String job_title       │
│ - Decimal salary_min     │
├─────────────────────────┤
│ + publish() void         │   ← (3) OPERATION (method / function)
│ + close() void           │
│ + isExpired() Boolean    │
└─────────────────────────┘
```

**Ký hiệu visibility (phạm vi truy cập) trước mỗi dòng:**

| Ký hiệu | Ý nghĩa | Ví dụ |
|---------|---------|-------|
| `-` | **Private** (riêng) — các field dữ liệu | `- UUID job_id` |
| `+` | **Public** (công khai) — các method | `+ publish() void` |
| `#` | Protected (bảo vệ) — *không dùng trong sơ đồ này* | |
| `~` | Package — *không dùng trong sơ đồ này* | |

**Cú pháp viết Attribute:** `kiểu_dữ liệu tên_field`
- Ví dụ: `- String job_title`, `- Decimal salary_min`, `- Enum work_mode`

**Cú pháp viết Operation:** `+ tên_method(tham_số) kiểu_trả_về`
- Ví dụ: `+ applyToJob(jobId, resumeId) Application`

---

## 2. Các nhóm Class trong sơ đồ

Sơ đồ chia làm 3 nhóm:

### Nhóm 1 — Domain Entities (thực thể nghiệp vụ)
Đại diện cho các đối tượng cốt lõi của hệ thống, lưu trong cơ sở dữ liệu. Có đầy đủ cả attribute và operation.

| Class | Vai trò |
|-------|---------|
| `JobSeeker` | Người tìm việc |
| `Employer` | Nhà tuyển dụng |
| `Job` | Tin tuyển dụng |
| `Application` | Đơn ứng tuyển |
| `Resume` | CV / hồ sơ ứng viên |
| `AiAnalysis` | Kết quả AI phân tích CV |
| `JobRecommendation` | Gợi ý việc làm (AI matching) |
| `Skill` | Kỹ năng |
| `Category` | Ngành nghề phân loại |

### Nhóm 2 — Service Layer (tầng xử lý)
Chứa logic nghiệp vụ, **manage / produce** các entity. Chủ yếu chỉ có operation, ít field.

`AuthService`, `JobService`, `ApplicationService`, `ResumeService`, `RecommendationService`

### Nhóm 3 — Utilities (tiện ích)
`ApiError` (xử lý lỗi thống nhất), `ApiResponse` (đóng gói response API).

---

## 3. Quan hệ giữa các Class

### 3.1. Ký hiệu loại quan hệ

| Ký hiệu | Tên | Ý nghĩa | Ví dụ trong sơ đồ |
|---------|-----|---------|-------------------|
| `*--` | **Composition** (kết hợp toàn phần) | A "sở hữu" B; B **không tồn tại độc lập** — A mất thì B cũng mất | `Resume *-- AiAnalysis` (xoá CV → phân tích cũng mất) |
| `o--` | **Aggregation** (kết hợp một phần) | A "có" B; B **vẫn tồn tại độc lập** | `Employer o-- Job` (Employer có nhiều Job) |
| `..` | **Association** (kết hợp) | Liên kết qua bảng trung gian, nhiều–nhiều | `JobSeeker .. Skill` |
| `..>` | **Dependency** (phụ thuộc) | A **dùng** B (không sở hữu) | `AuthService ..> JobSeeker` |
| `<\|--` | **Generalization / Inheritance** (kế thừa) | A là con của B | *(không dùng trong sơ đồ này)* |

### 3.2. Bội số (multiplicity)

Số lượng ở mỗi đầu mũi tên:

| Ký hiệu | Ý nghĩa |
|---------|---------|
| `1` | đúng 1 |
| `*` | nhiều (0 hoặc nhiều) |
| `0..1` | 0 hoặc 1 |
| `1..*` | 1 hoặc nhiều |

---

## 4. Nhãn quan hệ (Label) — cái bạn hỏi

Chữ in nghiêng nằm **trên mũi tên** gọi là **label (nhãn quan hệ)**. Nó diễn tả **ý nghĩa nghiệp vụ** của quan hệ đó — cho biết hai class liên quan với nhau *bằng cách nào*, chứ không chỉ "có liên quan".

### 4.1. Cách đọc một mũi tên đầy đủ

```
JobSeeker   "1"   o--   "*"    Application
                       submits
```

| Thành phần | Giá trị | Ý nghĩa |
|-----------|---------|---------|
| Bội số trái | `1` | 1 JobSeeker |
| Loại quan hệ | `o--` | aggregation |
| Bội số phải | `*` | nhiều Application |
| **Nhãn** | `submits` | **JobSeeker *nộp* Application** |

→ Đọc cả câu: **"Mỗi JobSeeker nộp (submits) nhiều Application."**

### 4.2. Bảng chú thích tất cả nhãn

**Giữa các Domain Entity** (nét liền `o--` / `*--`):

| Nhãn | Đọc là | Quan hệ | Nghĩa nghiệp vụ |
|------|--------|---------|-----------------|
| `owns` | sở hữu | JobSeeker → Resume | Ứng viên có nhiều CV |
| `submits` | nộp | JobSeeker → Application | Ứng viên nộp đơn ứng tuyển |
| `receives` | nhận | JobSeeker → JobRecommendation | Ứng viên nhận gợi ý việc làm |
| `posts` | đăng | Employer → Job | Nhà tuyển dụng đăng tin |
| `receives` | nhận | Job → Application | Một việc làm có nhiều đơn ứng tuyển |
| `matched-in` | được ghép trong | Job → JobRecommendation | Job được đưa vào danh sách gợi ý |
| `analyzed-by` | được phân tích bởi | Resume → AiAnalysis | CV được AI phân tích (mỗi CV có 1 bản phân tích) |
| `attached` | đính kèm | Resume → Application | CV đính kèm theo đơn ứng tuyển |
| `basis-of` | là cơ sở của | Resume → JobRecommendation | CV làm cơ sở để AI gợi ý |
| `classifies` | phân loại | Category → Job | Ngành nghề phân loại việc làm |

**Service → Entity** (nét đứt `..>`, quan hệ phụ thuộc):

| Nhãn | Đọc là | Ý nghĩa |
|------|--------|---------|
| `manages` | quản lý | Service đó **thao tác CRUD** với entity (tạo / đọc / sửa / xoá). VD: `AuthService manages JobSeeker` = AuthService tạo & tìm JobSeeker |
| `produces` | tạo ra | Service **sinh ra** entity đó. VD: `RecommendationService produces JobRecommendation` = nó tạo ra bản gợi ý |

### 4.3. Tóm tắt cách phân biệt nhanh

- Nhãn có chữ **"manages / produces"** → quan hệ **Service dùng Entity** (nét đứt `..>`).
- Nhãn có chữ **"owns / submits / posts / receives..."** → quan hệ **cấu trúc giữa 2 Entity** (nét liền `o--`).

---

## 5. Sửa & render lại sơ đồ

Sơ đồ được viết bằng cú pháp **Mermaid** trong file `diagrams/class-diagram.mmd`. Khi cần chỉnh sửa:

1. Sửa nội dung trong `diagrams/class-diagram.mmd`.
2. Render lại thành PNG (đã cài `mermaid-cli` trong `docs/node_modules`):

   ```bash
   cd docs/diagrams
   ../node_modules/.bin/mmdc -i class-diagram.mmd -o class-diagram.png \
     -b white -w 2400 --puppeteerConfigFile puppeteer-config.json
   ```

**Lưu ý khi sửa file `.mmd`:**
- Tránh dùng `{}` hoặc `[]` trong cú pháp operation (gây lỗi render).
- Mỗi class cần có đủ 3 ô (nếu không có attribute/operation thì để ô trống).
