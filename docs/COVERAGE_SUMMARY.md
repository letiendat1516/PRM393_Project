# Coverage summary — `flutter test --coverage`

Sinh bởi `scripts/coverage_summary.py` (parse `coverage/lcov.info`, không cần `genhtml`/`lcov`).

- Lệnh: `flutter test --coverage` → `+404: All tests passed!`.
- Tổng: **965/2286 dòng (42.2%)** trên 28 file `lib/` được nạp khi test.
- Lưu ý: Flutter chỉ ghi vào lcov những file thực sự được load bởi suite — các file UI/view (page, widget) chưa có widget test sẽ không xuất hiện (0 dòng ≠ 0% của toàn repo).
- Các file 0% là file bị náp transitively (chuỗi import từ viewmodel/service) chứ không có test chạy trực tiếp — tính 'được chạm' của chúng phản ánh mức load, không phải test thất bại. Suite test V5 (chưa có test viewmodel) cho 13 file/80,5%; sau khi thêm test JobsSearchState (V11) chuỗi import rộng hơn nên lcov gồm 28 file.

## Theo module

| Module | Dòng | Được chạm | % |
|---|---|---|---|
| `lib/core` | 1001 | 467 | 46.7% |
| `lib/shared` | 919 | 390 | 42.4% |
| `lib/features/jobs` | 366 | 108 | 29.5% |
| **Tổng** | **2286** | **965** | **42.2%** |

## Top 10 file coverage thấp nhất (≥10 dòng)

| File | Dòng | Được chạm | % |
|---|---|---|---|
| `lib/core/services/ai/gemini_service.dart` | 149 | 0 | 0.0% |
| `lib/shared/models/jobseeker_profile_model.dart` | 114 | 0 | 0.0% |
| `lib/shared/models/resume_model.dart` | 89 | 0 | 0.0% |
| `lib/core/services/fcm_service.dart` | 79 | 0 | 0.0% |
| `lib/core/services/firestore_refs.dart` | 66 | 0 | 0.0% |
| `lib/shared/models/employer_profile_model.dart` | 59 | 0 | 0.0% |
| `lib/shared/models/user_model.dart` | 59 | 0 | 0.0% |
| `lib/shared/models/misc_models.dart` | 57 | 0 | 0.0% |
| `lib/core/services/auth_service.dart` | 50 | 0 | 0.0% |
| `lib/core/services/system_config_repository.dart` | 48 | 0 | 0.0% |

## File được chạm 100%

- `lib/core/utils/failure.dart` (46 dòng)
- `lib/shared/models/notification_model.dart` (23 dòng)
