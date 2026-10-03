# Analysis — Ghi chú cải thiện prompt

Mỗi lần phát hiện prompt chưa tốt, tạo 1 file markdown ở đây theo format:

`<ngày>-<vấn đề>.md` (vd `2026-07-06-skill-normalization.md`)

## Template

```markdown
# <Vấn đề>

**Ngày**: YYYY-MM-DD
**Task**: resume_extraction | job_matching
**Prompt version**: v1

## Mô tả vấn đề

(Ví dụ: AI trả "java" thay vì "Java", hoặc bỏ sót kỹ năng từ CV)

## Log liên quan

`logs/ai_2026-07-06_xxx.json`

## Đề xuất sửa prompt

(...)

## Kết quả sau khi sửa (version v2)

(So sánh trước/sau)
```

Việc này giúp **trace được lý do** mỗi lần sửa prompt, tránh rollback nhầm.
