# Prompt: Resume Extraction

**Version**: v1
**Task**: Trích xuất thông tin có cấu trúc từ text CV ứng viên
**Model**: deepseek-chat

## Mục tiêu

Nhận vào text CV (đã trích từ PDF), trả về JSON có cấu trúc gồm:
- `skills`: danh sách kỹ năng
- `total_experience_years`: số năm kinh nghiệm (ước lượng)
- `education_level`: trình độ học vấn cao nhất
- `work_experience`: các chỗ làm việc
- `summary`: tóm tắt 1-2 câu về ứng viên

## Prompt template

```
Bạn là trợ lý phân tích CV chuyên nghiệp. Hãy đọc CV dưới đây và trích xuất
thông tin theo ĐÚNG định dạng JSON yêu cầu. KHÔNG được bịa ra thông tin — nếu
trường nào không có trong CV, để null hoặc mảng rỗng.

=== CV TEXT ===
{{resume_text}}
=== HẾT CV ===

Trả về JSON duy nhất theo schema sau (không kèm giải thích, không markdown):

{
  "skills": ["Java", "Spring Boot", "MySQL", ...],
  "total_experience_years": 3.5,
  "education_level": "Bachelor | Master | PhD | Other",
  "work_experience": [
    {
      "company": "Tên công ty",
      "position": "Vị trí",
      "start_date": "YYYY-MM hoặc null",
      "end_date": "YYYY-MM hoặc null",
      "description": "Mô tả ngắn"
    }
  ],
  "summary": "Tóm tắt 1-2 câu về định hướng và điểm mạnh của ứng viên."
}
```

## Lưu ý

- Kỹ năng nên được chuẩn hoá (vd "java" → "Java", "spring boot" → "Spring Boot")
- `total_experience_years`: tính theo số năm từ earliest work_experience đến nay
  (hoặc end_date gần nhất). Nếu không có → null.
- Nếu CV tiếng Anh vẫn trả schema JSON như trên, nhưng giữ giá trị gốc.

## Version history

- **v1** (2026-07-06): bản đầu
