# Dataset synthetic TopCV — `crawl-topcv/data/jobs-raw.json`

Sinh bởi `node generate.js --perCategory=200` (mulberry32 seed **20260708**, 49 danh mục × 200 job).
Thống kê dưới đây sinh bởi `node crawl-topcv/stats.js` → `crawl-topcv/data/stats.json` (script kèm repo, không dependency ngoài).

Ngày sinh file hiện tại: **2026-10-03** (`crawled_at` đầu/cuối: `2026-10-03T06:11:35.138Z` → `.196Z`).

## 1. Tổng quan

| Chỉ số | Giá trị |
|---|---|
| Tổng số jobs | **9.800** |
| Danh mục (`category_name`) | 49 bucket, **đều đúng 200 job/bucket** (by design) |
| Công ty duy nhất (dedupe `company_name` lower + bỏ dấu + strip) | **2.932** |
| UID employer duy nhất sau slug hoá (`crawl-<slug 40 ký tự>`, như `import-firestore.js`) | **2.456** |
| Collision do slug (tên khác nhau → cùng uid) | 476 (16,2% tên) |
| Dung lượng file | 23.934.548 bytes (~23,9 MB) |
| SHA256 (toàn file, xem §5) | `dee8c451c049e2cb76f3c84a72f9d7c0109977fd18e2f4d867b6c2adb804fc1e` |

> Số 2.456 khớp đúng số `employerProfiles` thực tế đã import vào Firestore project `jobhub-prm393-g3`
> (2.932 tên → gộp còn 2.456 vì slug cắt 40 ký tự + bỏ dấu khiến các tên dài/gần giống nhau chung uid —
> xem §6 Hạn chế).

## 2. Histogram danh mục (49 bucket, mỗi bucket 200)

Phân bố **đồng đều tuyệt đối** theo thiết kế (`--perCategory=200`), không phải phân bố thực tế Zipf.
Top 10 (đồng hạng 200, sắp theo tên):

`Backend Developer` · `Bán lẻ / Dịch vụ` · `Báo chí / Xuất bản` · `Bất động sản` · `Biên phiên dịch`
· `Chăm sóc khách hàng` · `Công nhân sản xuất` · `Content Marketing` · `DevOps Engineer`
· `Điện / Điện tử / Viễn thông`

Bottom 5 (cũng 200/job): `Thiết kế nội thất` · `Thợ sửa chữa` · `Tư vấn chuyên môn` · `Tuyển dụng (HR)` · `Xây dựng`.

Danh sách đủ 49 bucket: xem `crawl-topcv/categories.js` (nguồn) hoặc `data/stats.json → categories`.

## 3. Histogram địa điểm (`location_text`)

`location_text` = thành phố, 15% lượt thêm hậu tố ` & N nơi khác` (giữ nguyên khi import sang trường
`city`/`employerCity` của Firestore — field text tự do) → **483 chuỗi khác nhau**, gộp về **62 thành phố gốc**.

Top 10 chuỗi gốc:

| location_text | Số job |
|---|---|
| Hồ Chí Minh | 1.932 |
| Hà Nội | 1.654 |
| Bình Dương | 360 |
| Đà Nẵng | 245 |
| Đồng Nai | 232 |
| Bắc Ninh | 197 |
| Hải Phòng | 180 |
| Nghệ An | 130 |
| Thanh Hóa | 126 |
| Hải Dương | 121 |

Bottom 10 (mỗi chuỗi 1 job — các biến thể `& N nơi khác` hiếm):

`Vĩnh Long & 2 nơi khác` · `Vĩnh Long & 4 nơi khác` · `Vĩnh Phúc & 10 nơi khác` · `Vĩnh Phúc & 2 nơi khác`
· `Vĩnh Phúc & 3 nơi khác` · `Vĩnh Phúc & 5 nơi khác` · `Vĩnh Phúc & 6 nơi khác` · `Yên Bái & 10 nơi khác`
· `Yên Bái & 6 nơi khác` · `Yên Bái & 9 nơi khác`

Theo **thành phố gốc** (bỏ hậu tố, dùng khi lọc/đếm theo thành phố): HCM 2.286 · Hà Nội 1.930 ·
Bình Dương 414 · Đà Nẵng 290 · Đồng Nai 262 · Bắc Ninh 233 · Hải Phòng 211 · Nghệ An 159 ·
Thanh Hóa 153 · Hải Dương 147 · Cần Thơ 140 · Hưng Yên 130 (còn lại < 130, tổng 62 thành phố).

## 4. Phân phối theo enum + lương

### `_experience_enum` (pick đều — không trọng số)

| Enum | Số job |
|---|---|
| JUNIOR | 2.463 |
| MID | 2.427 |
| INTERN | 1.244 |
| LEAD | 1.238 |
| FRESHER | 1.224 |
| SENIOR | 1.204 |

### `_work_mode` (trọng số `reference.js`)

| Enum | Số job |
|---|---|
| ONSITE | 7.881 (80,4%) |
| HYBRID | 1.125 (11,5%) |
| REMOTE | 794 (8,1%) |

### `_job_type` (trọng số FULL_TIME 80 / PART_TIME 12 / INTERNSHIP 8)

| Enum | Số job |
|---|---|
| FULL_TIME | 7.857 |
| PART_TIME | 1.175 |
| INTERNSHIP | 768 |

### Lương (VND/tháng)

- `_is_negotiable == true`: **2.347 job (23,95%)** — không có min/max ("Thoả thuận").
- Có `_salary_min`: 7.453 job · có `_salary_max`: 6.854 job (599 job "Từ X triệu" chỉ có min, max mở).

| Thống kê | `_salary_min` | `_salary_max` |
|---|---|---|
| n | 7.453 | 6.854 |
| min | 5.000.000 | 10.000.000 |
| p10 | 5.000.000 | 10.000.000 |
| p25 | 10.000.000 | 15.000.000 |
| **p50 (median)** | **20.000.000** | **25.000.000** |
| p75 | 30.000.000 | 50.000.000 |
| p90 | 50.000.000 | 80.000.000 |
| max | 50.000.000 | 80.000.000 |
| mean | 21.614.115 | 32.853.808 |

(Các mốc lương rời rạc theo `SALARY_RANGES` trong `reference.js`: 5–80 triệu.)

## 5. Tính reproducible (SHA256)

`generate.js` dùng RNG mulberry32 seed cố định **20260708** → nội dung deterministic. Tuy nhiên trường
`crawled_at` mỗi job ghi `new Date().toISOString()` (thời điểm chạy thật, `generate.js:257`) nên
**SHA256 toàn file sẽ khác nhau giữa 2 lần chạy**. Đo thực tế (rerun `--perCategory=200` cùng ngày):

| So sánh | SHA256 |
|---|---|
| File gốc (đã import Firestore) | `dee8c451c049e2cb76f3c84a72f9d7c0109977fd18e2f4d867b6c2adb804fc1e` |
| File chạy lại (full) | `73485ab02e744e27e13597f4e511445ae74439e693e920ea0e4dbfe723d6a5c5` — **khác** (chỉ lệch `crawled_at`) |
| File gốc — chuẩn hoá (`crawled_at=''`) | `a77e0104eeb6b6814fdb430b972fb7c9bac38b0a45606237a325d54661496f01` |
| File chạy lại — chuẩn hoá | `a77e0104eeb6b6814fdb430b972fb7c9bac38b0a45606237a325d54661496f01` — **trùng khớp từng byte** |

**Kết luận:** dataset reproducible 100% về nội dung (trừ timestamp chạy). Nếu cần hash byte-ổn định
để kiểm regression, đề xuất sửa `generate.js` suy `crawled_at` từ seed (ví dụ mốc cố định
`2026-07-08T00:00:00Z`) — hiện chưa sửa để giữ nguyên hash của file đã import.

Cách tự verify (generate.js ghi đường dẫn cố định `./data/jobs-raw.json` — backup trước khi chạy lại):

```bash
cd crawl-topcv
cp data/jobs-raw.json data/jobs-raw.orig.json
node generate.js --perCategory=200
node stats.js                       # so sha256 với stats.json lần trước
mv -f data/jobs-raw.orig.json data/jobs-raw.json   # phục hồi file gốc
```

## 6. Hạn chế của dữ liệu synthetic (cần biết khi demo/đánh giá)

1. **Tiêu đề không khớp enum kinh nghiệm**: hậu tố title (`Junior/Senior/Fresher/Lead`, 15%) và
   `_experience_enum` là 2 lượt random độc lập → có job "… - Fresher" nhưng enum `SENIOR`
   (xem mẫu SYN-04900), "… - Senior" nhưng enum `JUNIOR` (SYN-09800).
2. **Bullet tiếng Anh trong nhóm IT**: các họ mô tả `dev`/`devops` lấy từ reference TopCV gốc có
   bullet tiếng Anh ("Write clean, maintainable…") — đúng nguồn gốc chứ không phải lỗi sinh.
3. **Slug employer cắt 40 ký tự** → 476 cặp tên dài/gần giống gộp chung 1 uid `crawl-…` (mất 16%
   danh nghĩa công ty, nhưng hợp lý về "chi nhánh cùng thương hiệu").
4. **Phân bố danh mục đồng đều** (200/.bucket) — khác thực tế (IT thường chiếm tỷ trọng lớn trên TopCV).
5. `posted_text` chỉ 3 dạng ("N ngày trước" 40%, "N tuần trước" 40%, "1 tháng trước" 20%).

## 7. Phụ lục — 3 job mẫu deterministic (index 0 / 4899 / 9799)

### jobs[0] — `SYN-00001`

```json
{
  "source_job_id": "SYN-00001",
  "job_title": "Chuyên Viên Kinh Doanh",
  "company_name": "CÔNG TY TNHH VINATECH VIETTEL VIỆT NAM",
  "category_name": "Nhân viên kinh doanh",
  "salary_text": "50 - 80 triệu",
  "location_text": "Hà Nội",
  "_salary_min": 50000000, "_salary_max": 80000000, "_is_negotiable": false,
  "_experience_enum": "MID", "_work_mode": "ONSITE", "_job_type": "FULL_TIME",
  "posted_text": "Đăng 1 ngày trước",
  "job_detail": {
    "mo_ta_cong_viec": ["Phối hợp với các phòng ban để đảm bảo trải nghiệm khách hàng tốt nhất.",
      "Cập nhật thông tin thị trường, đối thủ và xu hướng ngành.",
      "Thực hiện các công việc khác theo phân công của Quản lý trực tiếp.", "… (còn 3 mục)"],
    "yeu_cau_ung_vien": ["Có phương tiện đi lại (xe máy) cho vị trí sales thị trường.",
      "Sử dụng thành thạo Office (Word, Excel) và CRM là một lợi thế.",
      "Trung thực, nhiệt tình, chịu được áp lực cao về doanh số.", "… (còn 1 mục)"],
    "quyen_loi": ["Khám sức khỏe định kỳ hàng năm.",
      "Môi trường làm việc trẻ trung, năng động, cơ hội thăng tiến rõ ràng.",
      "Cân bằng công việc - cuộc sống, linh hoạt giờ giấc.", "… (còn 3 mục)"],
    "thoi_gian_lam_viec": "Thứ 2 - Thứ 6 (từ 09:00 đến 18:00), 1 ngày WFH/tuần",
    "yeu_cau_kinh_nghiem": "4 năm", "yeu_cau_bang_cap": "Đại học trở lên"
  }
}
```

### jobs[4899] — `SYN-04900`

```json
{
  "source_job_id": "SYN-04900",
  "job_title": "Thiết Kế Đồ Hoạ - Fresher",
  "company_name": "CÔNG TY TNHH TRUYỀN THÔNG DƯỢC PHẨM",
  "category_name": "Thiết kế",
  "salary_text": "30 - 50 triệu",
  "location_text": "Long An",
  "_salary_min": 30000000, "_salary_max": 50000000, "_is_negotiable": false,
  "_experience_enum": "SENIOR", "_work_mode": "ONSITE", "_job_type": "PART_TIME",
  "posted_text": "Đăng 1 tuần trước",
  "job_detail": {
    "mo_ta_cong_viec": ["Lên ý tưởng visual cho các chiến dịch marketing.",
      "Làm việc với printer/production để đảm bảo chất lượng in ấn.",
      "Quản lý asset thiết kế và brand guideline.", "… (còn 4 mục)"],
    "yeu_cau_ung_vien": ["Tốt nghiệp Cao đẳng/Đại học chuyên ngành Thiết kế đồ họa, Mỹ thuật.",
      "Tiếng Anh đọc hiểu để tham khảo tài liệu.",
      "Có portfolio rõ ràng, tư duy thẩm mỹ tốt.", "… (còn 3 mục)"],
    "quyen_loi": ["Cân bằng công việc - cuộc sống, linh hoạt giờ giấc.",
      "Khám sức khỏe định kỳ hàng năm.",
      "Đóng BHXH, BHYT đầy đủ theo quy định pháp luật.", "… (còn 2 mục)"],
    "thoi_gian_lam_viec": "Thứ 2 - Thứ 6 (từ 08:00 đến 17:30), Thứ 7 sáng (từ 08:00 đến 12:00)",
    "yeu_cau_kinh_nghiem": "5 năm", "yeu_cau_bang_cap": "Đại học trở lên"
  }
}
```

> Job này minh hoạ hạn chế §6.1: title "Fresher" nhưng enum `SENIOR` + "5 năm" kinh nghiệm.

### jobs[9799] — `SYN-09800`

```json
{
  "source_job_id": "SYN-09800",
  "job_title": "Site Reliability Engineer - Senior",
  "company_name": "CÔNG TY TRÁCH NHIỆM HỮU HẠN XUẤT NHẬP KHẨU PHÁT TRIỂN PHẦN MỀM MIỀN BẮC",
  "category_name": "DevOps Engineer",
  "salary_text": "Từ 15 triệu",
  "location_text": "Hà Nội",
  "_salary_min": 15000000, "_salary_max": null, "_is_negotiable": false,
  "_experience_enum": "JUNIOR", "_work_mode": "ONSITE", "_job_type": "INTERNSHIP",
  "posted_text": "Đăng 5 ngày trước",
  "job_detail": {
    "mo_ta_cong_viec": ["Write clean, maintainable, and well-tested code following best practices.",
      "Implement CI/CD pipelines and automated testing.",
      "Apply test-driven development and ensure appropriate test coverage.", "… (còn 7 mục)"],
    "yeu_cau_ung_vien": ["Good English reading and writing skills for technical documentation.",
      "Bachelor's Degree in IT, Computer Science, Software Engineering, or related field.",
      "Experience with RESTful API design and microservices architecture.", "… (còn 2 mục)"],
    "quyen_loi": ["14+ annual leaves per year.",
      "Cân bằng công việc - cuộc sống, linh hoạt giờ giấc.",
      "Competitive salary (13th-month salary + performance bonus).", "… (còn 3 mục)"],
    "thoi_gian_lam_viec": "Thứ 2 - Thứ 6 (từ 08:00 đến 17:30), Thứ 7 sáng (từ 08:00 đến 12:00)",
    "yeu_cau_kinh_nghiem": "2 năm", "yeu_cau_bang_cap": "Tốt nghiệp Cao đẳng trở lên"
  }
}
```

> Minh hoạ §6.2 (bullet tiếng Anh cho họ DevOps) và tên công ty 76 ký tự → uid slug cắt còn 40.
