# AI Lab — Folder riêng của Module 1 (AI Resume & Matching)

Folder này dùng để **lưu trữ prompt, response và thời gian xử lý** của các lần
gọi AI (DeepSeek) nhằm:
- Phân tích chất lượng prompt qua từng version
- So sánh response tốt/xấu
- Cải thiện prompt dựa trên dữ liệu thực tế

## Cấu trúc

```
ai-lab/
├── README.md                ← file này
├── prompts/                 ← Prompt template (committed, version hoá)
│   ├── resume-extraction.md   Prompt trích CV → structured JSON
│   └── job-matching.md        Prompt chấm điểm CV vs danh sách job
├── examples/                ← Sample input/output tốt (committed)
│   └── README.md
├── logs/                    ← Runtime logs JSON (gitignored, tự động sinh)
│   └── .gitkeep
└── analysis/                ← Ghi chú cải thiện prompt (committed)
    └── README.md
```

## Cách log hoạt động

Khi backend gọi AI (qua `backend/src/ai/aiLogger.js`), mỗi lần gọi sẽ tạo 1 file
JSON trong `logs/` theo format:

```json
{
  "log_id": "ai_2026-07-06_03-45-12_a1b2c3",
  "timestamp": "2026-07-06T03:45:12.482Z",
  "task": "resume_extraction | job_matching",
  "model": "deepseek-chat",
  "prompt": "<toàn bộ prompt gửi đi>",
  "response": "<toàn bộ response>",
  "processing_time_ms": 4823,
  "tokens_in": 1240,
  "tokens_out": 380,
  "success": true,
  "error": null,
  "metadata": {
    "resume_id": 12,
    "user_id": 4,
    "total_jobs_sent": 10
  }
}
```

Đồng thời log cũng ghi vào bảng `ai_matching_log` trong DB (để query/tracking).

## Cải thiện prompt (workflow)

1. Chạy thử 1 CV / 1 cặp CV-Job → xem log trong `logs/`
2. Nếu response sai/thiếu → copy log đó vào `analysis/<ngày>-<vấn đề>.md`
3. Sửa prompt trong `prompts/*.md`, tăng version (vd `v1` → `v2`)
4. Chạy lại cùng input → so sánh response cũ vs mới
5. Khi ổn → copy prompt mới vào `backend/src/ai/promptBuilder.js`

## Tại sao logs gitignored

- File log tăng nhanh (mỗi lần gọi AI = 1 file), repo phình to
- Log chứa thông tin nhạy cảm (CV thật, email ứng viên)
- DB `ai_matching_log` đã lưu đầy đủ → log file chỉ phụ trợ cho offline analysis

Nếu muốn commit 1 log cụ thể làm ví dụ, copy vào `examples/` (đã mask thông tin
nhạy cảm).
