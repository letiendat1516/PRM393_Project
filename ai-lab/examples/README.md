# Examples

Thư mục chứa **ví dụ curated** (input + output tốt) dùng để:
- Few-shot prompting (đưa vào prompt làm ví dụ cho AI)
- Regression test (chạy lại prompt mới, kiểm tra output vẫn đúng)
- Benchmark so sánh các version prompt

## Quy ước đặt tên

`<task>-<mô-tả>-<số>.json`

Ví dụ:
- `resume-extraction-junior-dev-01.json`
- `job-matching-backend-senior-01.json`

## Format file

```json
{
  "task": "resume_extraction",
  "prompt_version": "v1",
  "input": { "resume_text": "..." },
  "expected_output": { "skills": [...], "experience_years": 2.5, ... },
  "notes": "Ứng viên junior, có gap year, AI cần nhận diện đúng"
}
```

> Khi commit ví dụ, MASK thông tin nhạy cảm (email, SĐT thật, tên công ty
> cụ thể) trước khi đưa vào repo.
