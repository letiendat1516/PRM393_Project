# Prompt: Job Matching (CV vs Jobs) — v2

**Version**: v4 (2026-07-08)
**Task**: Chấm điểm phù hợp giữa 1 hồ sơ ứng viên và danh sách tin tuyển dụng
**Model**: deepseek-chat
**Temperature**: 0 (deterministic — cùng input luôn ra cùng kết quả)

## Cải tiến so với v3

- **Chuẩn hoá kỹ năng**: JS=JavaScript, Sale=Sales trước khi so sánh
- **Transferable skills**: nhận diện kỹ năng chuyển ngành (IT→Sales, Sales→Marketing)
- **Suy luận từ tiêu đề**: Network Engineer → TCP/IP, Kế toán → Excel/MISA
- **Few-shot examples**: 3 ví dụ anchor (IT→IT, IT→Sales, Sales→Marketing)
- **Phân tích job trước**: AI suy luận yêu cầu thực tế trước khi chấm

## Cải tiến so với v2

- **Chấm chính xác hơn**: "không yêu cầu" = điểm trung bình (50%), KHÔNG PHẢI tối đa
- **Lý do cụ thể**: phải đề cập skills/domain/kinh nghiệm thực tế, KHÔNG chung chung
- **Suy luận từ title**: nếu job không liệt kê skills, phân tích từ tiêu đề (Network Engineer → networking)
- **Giới hạn điểm**: job không yêu cầu cụ thể → tối đa 65-70 (không 100)

## Cải tiến so với v1

- **Nhất quán**: temperature=0, rubric có trọng số cụ thể
- **Sâu hơn**: chấm cả soft skills, domain match, career fit, ngôn ngữ, thái độ
- **Có breakdown**: 7 tiêu chí, mỗi tiêu chí có điểm riêng
- **Context đầy đủ**: gửi cả work experience descriptions, summary, job description

## Rubric chấm điểm (tổng 100)

| # | Tiêu chí | Trọng số | Mô tả |
|---|----------|----------|-------|
| 1 | Kỹ năng chuyên môn | 30đ | So khớp từng kỹ năng trong job với CV. Kỹ năng bắt buộc ×2. |
| 2 | Kinh nghiệm | 20đ | Số năm + cấp độ + domain-related |
| 3 | Học vấn & Chứng chỉ | 10đ | Bằng cấp, chứng chỉ, khóa học |
| 4 | Domain / Ngành | 15đ | Kinh nghiệm cùng ngành/lĩnh vực |
| 5 | Soft skills & Thái độ | 10đ | Teamwork, communication, problem-solving... |
| 6 | Ngôn ngữ | 5đ | Ngoại ngữ phù hợp |
| 7 | Career fit | 10đ | Tổng thể: vị trí, lương, career path |

## Prompt template (System)

```
RUBRIC CHẤM ĐIỂM (tổng 100, áp dụng NHẤT QUÁN cho mọi job):

1. KỸ NĂNG CHUYÊN MÔN (0-30đ):
   - So khớp từng kỹ năng trong job yêu cầu với skills của CV
   - Kỹ năng bắt buộc (is_required=true) nặng gấp 2 lần kỹ năng phụ

2. KINH NGHIỆM (0-20đ):
   - Đủ hoặc vượt → 15-20đ; thiếu 1-2 năm → 10-14đ; thiếu nhiều → 0-9đ
   - Cùng ngành/domain → cộng 3-5đ

3. HỌC VẤN & CHỨNG CHỈ (0-10đ):
   - Đúng ngành → 8-10đ; trái ngành → 3-5đ

4. DOMAIN / NGÀNH (0-15đ):
   - Cùng ngành → 10-15đ; gần → 5-9đ; khác → 0-4đ

5. SOFT SKILLS & THÁI ĐỘ (0-10đ):
   - Teamwork, communication, problem-solving, leadership...
   - Phân tích summary + work_experience để đánh giá

6. NGÔN NGỮ (0-5đ):
   - Job yêu cầu ngoại ngữ → so với languages

7. CAREER FIT (0-10đ):
   - Tổng thể vị trí, mức lương, career path
   - Overqualified → 5-7đ

NGUYÊN TẮC NHẤT QUÁN:
- CÙNG input → CÙNG output
- Nếu job không đề cập tiêu chí X → cho điểm tối đa tiêu chí X
- Làm tròn match_score về số nguyên
```

## Expected output

```json
[
  {
    "job_id": 123,
    "match_score": 72,
    "score_breakdown": {
      "skills": 20,
      "experience": 15,
      "education": 8,
      "domain": 9,
      "soft_skills": 7,
      "language": 5,
      "career_fit": 8
    },
    "recommendation_reason": "Good match. Candidate has most required skills and relevant domain experience. Missing Kubernetes which is a nice-to-have.",
    "missing_skills": ["Kubernetes", "Terraform"],
    "strengths": ["Strong JavaScript/Node.js background", "Agile/Scrum experience", "AWS certified"]
  }
]
```

## Version history

- **v4** (2026-07-08): Skill normalization, transferable skills, suy luận từ title, few-shot examples
- **v3** (2026-07-08): Sửa lỗi inflate điểm — "không yêu cầu" = trung bình (50%), lý do cụ thể
- **v2** (2026-07-08): Thêm rubric trọng số, soft skills, domain, career fit, temperature=0
- **v1** (2026-07-06): bản đầu — chấm cơ bản skill + kinh nghiệm + học vấn
