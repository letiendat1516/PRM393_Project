# Database Migrations

Các script migration chạy **sau** khi đã chạy schema gốc ở `08_DATABASE.md`.
Chạy từng migration trong **Supabase SQL Editor** theo thứ tự.

---

## Migration 001 — Employer registration fields

**Ngày**: 2026-07-06
**Lý do**: Trang đăng ký nhà tuyển dụng chi tiết cần lưu tên + giới tính của
người liên hệ (HR/recruiter đại diện công ty), tách biệt với `company_name`.

```sql
ALTER TABLE employer
  ADD COLUMN IF NOT EXISTS contact_name VARCHAR(255),
  ADD COLUMN IF NOT EXISTS gender VARCHAR(10);

COMMENT ON COLUMN employer.contact_name IS 'Tên người liên hệ đại diện công ty';
COMMENT ON COLUMN employer.gender IS 'Giới tính người liên hệ: male / female';
```

**Rollback** (nếu cần):
```sql
ALTER TABLE employer
  DROP COLUMN IF EXISTS contact_name,
  DROP COLUMN IF EXISTS gender;
```

---

## Migration 002 — Allow anonymous AI matching logs

**Ngày**: 2026-07-08
**Lý do**: Bảng `ai_matching_log` có `job_seeker_id BIGINT NOT NULL`, nhưng
 tính năng AI Matching trên trang `/viec-lam` có thể được dùng **không cần đăng
 nhập** (ung viên ẩn danh upload CV để xem điểm phù hợp). Khi `job_seeker_id`
 là NULL, insert thất bại silently và logs không ghi được vào DB.

```sql
-- Cho phép job_seeker_id = NULL (AI matching ẩn danh)
ALTER TABLE ai_matching_log
  ALTER COLUMN job_seeker_id DROP NOT NULL;

-- Thêm cột task + tokens để lưu thông tin hữu ích hơn
ALTER TABLE ai_matching_log
  ADD COLUMN IF NOT EXISTS task VARCHAR(50),
  ADD COLUMN IF NOT EXISTS tokens_in INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS tokens_out INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS success BOOLEAN DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS error TEXT;

COMMENT ON COLUMN ai_matching_log.task IS 'resume_extraction | job_matching';
COMMENT ON COLUMN ai_matching_log.success IS 'TRUE nếu AI call thành công';
```

**Rollback** (nếu cần):
```sql
ALTER TABLE ai_matching_log
  ALTER COLUMN job_seeker_id SET NOT NULL;

ALTER TABLE ai_matching_log
  DROP COLUMN IF EXISTS task,
  DROP COLUMN IF EXISTS tokens_in,
  DROP COLUMN IF EXISTS tokens_out,
  DROP COLUMN IF EXISTS success,
  DROP COLUMN IF EXISTS error;
```
