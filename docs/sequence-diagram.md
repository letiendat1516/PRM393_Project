# JobHub — Sequence Diagrams (Module 1: AI Resume & Matching)

Tài liệu giải thích **sequence diagram** của **Module 1 — AI Resume Analysis &
Job Matching** (module bạn làm). Viết bằng **PlantUML** (khác với class diagram
dùng Mermaid).

## Danh sách sơ đồ

| File | Use Case | Mô tả |
|------|----------|-------|
| [`diagrams/sequence-ai-matching.puml`](./diagrams/sequence-ai-matching.puml) | **UC10 + UC23** (USP) | AI Matching — DeepSeek chấm điểm CV vs danh sách jobs, theo batch + retry + concurrency. Đây là sơ đồ **chính**, gộp cả nhánh CV preset lẫn CV upload. |
| [`diagrams/sequence-extract-cv.puml`](./diagrams/sequence-extract-cv.puml) | **UC04 + UC23** | Upload CV → trích text → DeepSeek trả structured JSON (skills, kinh nghiệm, học vấn…). |
| [`diagrams/sequence-sql-scoring.puml`](./diagrams/sequence-sql-scoring.puml) | (đường nhanh của UC10) | Rule-based scoring — chấm điểm deterministic, **không gọi AI**, miễn phí, tức thì. |
| [`diagrams/sequence-ai-logs.puml`](./diagrams/sequence-ai-logs.puml) | (cross-cutting) | AI Logging: **ghi** mọi lời gọi DeepSeek vào DB + file, và **đọc** lại ở trang `/ai-logs` để cải thiện prompt. |

> File `.puml` ở `docs/diagrams/`. Tài liệu giải thích này ở `docs/sequence-diagram.md`.

---

## Cách đọc các participant (lifeline)

| Participant | Vai trò trong code |
|-------------|--------------------|
| **Ứng viên** (`actor`) | Người dùng thao tác trên UI |
| `AIScoreModal` / `AiLogsPage` | Component React ở frontend (`frontend/src/components/job/`, `frontend/src/pages/`) |
| `recommendationService` | API client frontend (`frontend/src/services/recommendationService.js`) |
| `RecommendationController` | HTTP entry point backend (`backend/src/controllers/RecommendationController.js`) |
| `promptBuilder` | Build prompt gửi DeepSeek (`backend/src/ai/promptBuilder.js`) |
| `deepseekClient` | Wrapper duy nhất gọi DeepSeek (`backend/src/ai/deepseekClient.js`) |
| `DeepSeek API` (`<<external>>`) | API ngoài hệ thống (chat/completions) |
| `aiLogger` | Ghi log mỗi lần gọi AI (`backend/src/ai/aiLogger.js`) |
| `Supabase DB` | Bảng `ai_matching_log` (và tương lai là `job_recommendation`) |
| `ai-lab/logs/*.json` | File log offline để phân tích prompt (folder `ai-lab/`) |

---

## Render (xem ảnh)

Chưa có sẵn file PNG vì máy chưa cài Java. Chọn 1 trong các cách:

**1. VS Code — PlantUML extension** *(nhanh nhất)*
- Cài extension *PlantUML* (`jebbs.plantuml`).
- Mở file `.puml` → `Alt+D` để preview. Trong cài đặt extension, đặt
  `plantuml.render: "PlantUMLServer"` trỏ tới `https://www.plantuml.com/plantuml`
  để không cần Java.

**2. IntelliJ IDEA / Rider** *(đang có sẵn trên máy)*
- Cài plugin **PlantUML Integration** → mở `.puml`, sẽ render ngay.

**3. Online** *(không cần cài gì)*
- Dán nội dung `.puml` vào <https://www.plantuml.com/plantuml/uml/>.

**4. CLI (nếu cài Java + plantuml.jar)**
```bash
java -jar plantuml.jar docs/diagrams/sequence-ai-matching.puml -tpng
```

---

## Logic chính tóm tắt (tham khảo khi đọc sơ đồ)

- **Batch scoring** (`AIScoreModal.jsx`): jobs được chia theo `BATCH_SIZE = 10`,
  chạy tối đa `MAX_CONCURRENCY = 2` batch song song, mỗi batch `MAX_RETRIES = 2`.
- **Retry JSON parse** (`RecommendationController.scoreJobs`): nếu DeepSeek trả
  JSON sai format, gọi lại tối đa 2 lần.
- **AI logging** (`deepseekClient.js` → `aiLogger.js`): chạy trong khối `finally`,
  **luôn** ghi bất kể thành công/thất bại → 2 nơi (DB `ai_matching_log` + file
  `ai-lab/logs/*.json`).
- **Lưu phiên** (`utils/aiScores.js`): kết quả chấm điểm lưu vào `localStorage`
  theo từng *session*, xem lại tại route `/de-xuat`. `POST /recommendations/save`
  hiện là placeholder chờ khi có `job_seeker_id` từ auth.
