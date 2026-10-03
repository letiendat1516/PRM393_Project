# Audit chuỗi hardcoded tiếng Việt (`lib/`)

Sinh tự động bởi `scripts/l10n_audit.py` (chỉ đọc `lib/`, không sửa gì). 
Mục đích: bảng tổng hợp để nhóm chuyển sang `AppLocalizations` (flutter gen-l10n) sau này.

## Thống kê

- Tổng occurrences chuỗi có dấu tiếng Việt trong `lib/`: **2170**
- Chuỗi UI (có khoảng trắng, ngoài file data demo): **1743** — chuỗi duy nhất: **1254**
- Chuỗi nội dung demo (`lib/core/data/demo_data.dart`, không phải UI — sẽ đến từ backend khi có dữ liệu thật): **352**
- Số file có ít nhất 1 chuỗi: 158

### Top 10 file nhiều chuỗi nhất

| File | Số chuỗi |
|---|---|
| `lib/core/data/demo_data.dart` | 352 |
| `lib/features/settings/views/settings_page.dart` | 57 |
| `lib/features/employer/widgets/job_form_steps.dart` | 44 |
| `lib/core/utils/validators.dart` | 41 |
| `lib/features/admin/views/admin_dashboard_page.dart` | 41 |
| `lib/features/employer/views/employer_dashboard_page.dart` | 37 |
| `lib/features/employer/views/employer_company_profile_page.dart` | 36 |
| `lib/features/profile/views/ai_analysis_page.dart` | 36 |
| `lib/features/employer/data/job_form_input.dart` | 34 |
| `lib/features/recommendations/viewmodels/ai_matching_viewmodel.dart` | 34 |

### Nhóm theo feature

| Feature | Số chuỗi UI |
|---|---|
| `features/employer` | 316 |
| `features/admin` | 249 |
| `features/profile` | 195 |
| `shared` | 146 |
| `features/jobs` | 138 |
| `features/applications` | 134 |
| `core/utils` | 105 |
| `features/recommendations` | 103 |
| `features/auth` | 89 |
| `features/home` | 74 |
| `features/settings` | 60 |
| `features/chat` | 41 |
| `core/services` | 40 |
| `features/notifications` | 33 |
| `core/config` | 17 |
| `lib` | 2 |
| `features/splash` | 1 |

## Bảng chi tiết (chuỗi UI, nhóm theo feature)

Key đề xuất sinh tự động: `<feature>_<slug-chuỗi>` — chỉ là gợi ý, đặt tên lại theo ngữ nghĩa khi hiện thực.

### `core/config` (17)

| Vị trí | Chuỗi | Key đề xuất | Ngữ cảnh |
|---|---|---|---|
| `lib/core/config/app_config.dart:59` | Kế toán | `c_config_ke_toan` | khác |
| `lib/core/config/app_config.dart:63` | Dưới 10 triệu | `c_config_duoi_10_trieu` | khác |
| `lib/core/config/app_config.dart:64` | 10 - 15 triệu | `c_config_10_15_trieu` | khác |
| `lib/core/config/app_config.dart:65` | 15 - 20 triệu | `c_config_15_20_trieu` | khác |
| `lib/core/config/app_config.dart:66` | 20 - 30 triệu | `c_config_20_30_trieu` | khác |
| `lib/core/config/app_config.dart:67` | 30 - 50 triệu | `c_config_30_50_trieu` | khác |
| `lib/core/config/app_config.dart:68` | Trên 50 triệu | `c_config_tren_50_trieu` | khác |
| `lib/core/config/app_config.dart:69` | Thoả thuận | `c_config_thoa_thuan` | khác |
| `lib/core/config/app_config.dart:74` | Ngày đăng | `c_config_ngay_dang` | khác |
| `lib/core/config/app_config.dart:75` | Ngày cập nhật | `c_config_ngay_cap_nhat` | khác |
| `lib/core/config/app_config.dart:76` | Lương cao nhất | `c_config_luong_cao_nhat` | khác |
| `lib/core/config/app_config.dart:77` | Cần tuyển gấp | `c_config_can_tuyen_gap` | khác |
| `lib/core/config/app_config.dart:78` | Độ phù hợp AI (cao→thấp) | `c_config_do_phu_hop_ai_cao_thap` | khác |
| `lib/core/config/app_config.dart:83` | Tất cả | `c_config_tat_ca` | khác |
| `lib/core/config/app_config.dart:84` | Công nghệ thông tin | `c_config_cong_nghe_thong_tin` | khác |
| `lib/core/config/app_config.dart:87` | Tài chính – Kế toán | `c_config_tai_chinh_ke_toan` | khác |
| `lib/core/config/app_config.dart:88` | Nhân sự | `c_config_nhan_su` | khác |

### `core/services` (40)

| Vị trí | Chuỗi | Key đề xuất | Ngữ cảnh |
|---|---|---|---|
| `lib/core/services/ai/gemini_service.dart:44` | Chưa cấu hình Gemini API key. Admin vào Cấu hình hệ thống → GEMINI_… | `c_services_chua_cau_hinh_gemini_api_key_admin_vao_cau` | khác |
| `lib/core/services/ai/gemini_service.dart:118` | danh sách kỹ năng chuyên môn | `c_services_danh_sach_ky_nang_chuyen_mon` | khác |
| `lib/core/services/ai/gemini_service.dart:122` | tên ngôn ngữ | `c_services_ten_ngon_ngu` | khác |
| `lib/core/services/ai/gemini_service.dart:123` | tên chứng chỉ | `c_services_ten_chung_chi` | khác |
| `lib/core/services/ai/gemini_service.dart:125` | vị trí | `c_services_vi_tri` | khác |
| `lib/core/services/ai/gemini_service.dart:125` | mô tả ngắn | `c_services_mo_ta_ngan` | khác |
| `lib/core/services/ai/gemini_service.dart:127` | Tóm tắt 2-3 câu về ứng viên: điểm mạnh, định hướng nghề nghiệp, pho… | `c_services_tom_tat_2_3_cau_ve_ung_vien_diem_manh_dinh` | khác |
| `lib/core/services/ai/gemini_service.dart:149` | Không yêu cầu | `c_services_khong_yeu_cau` | khác |
| `lib/core/services/ai/gemini_service.dart:153` | dễ vào | `c_services_de_vao` | khác |
| `lib/core/services/ai/gemini_service.dart:160` | phù hợp hoàn hảo | `c_services_phu_hop_hoan_hao` | khác |
| `lib/core/services/ai/gemini_service.dart:193` | Trả JSON: [{"job_id","match_score":0-100,"weights":{skills,experien… | `c_services_tra_json_job_id_match_score_0_100_weights` | nội dung dài |
| `lib/core/services/ai/gemini_service.dart:194` | (Bọc mảng trong JSON object: {"scores": [...]}) | `c_services_boc_mang_trong_json_object_scores` | khác |
| `lib/core/services/ai/gemini_service.dart:211` | Mô tả: ${moTa.join( | `c_services_mo_ta_mota_join` | khác |
| `lib/core/services/ai/gemini_service.dart:211` | )} \| Yêu cầu: ${yeuCau.join( | `c_services_yeu_cau_yeucau_join` | khác |
| `lib/core/services/ai/gemini_service.dart:211` | )} \| Quyền lợi: ${quyenLoi.join( | `c_services_quyen_loi_quyenloi_join` | khác |
| `lib/core/services/ai/gemini_service.dart:283` | Tối đa 100 việc làm mỗi lần chấm điểm. | `c_services_toi_da_100_viec_lam_moi_lan_cham_diem` | validation/lỗi |
| `lib/core/services/ai/gemini_service.dart:322` | AI trả về JSON không hợp lệ. ${Failure.from(lastError!).message} | `c_services_ai_tra_ve_json_khong_hop_le_failure_from_l` | validation/lỗi |
| `lib/core/services/ai/gemini_service.dart:342` | AI trả về JSON không hợp lệ. | `c_services_ai_tra_ve_json_khong_hop_le` | validation/lỗi |
| `lib/core/services/ai/gemini_service.dart:350` | AI trả về JSON không hợp lệ. | `c_services_ai_tra_ve_json_khong_hop_le` | validation/lỗi |
| `lib/core/services/ai/gemini_service.dart:354` | AI trả về JSON không hợp lệ. | `c_services_ai_tra_ve_json_khong_hop_le` | validation/lỗi |
| `lib/core/services/ai/rule_based_scorer.dart:117` | Kỹ năng chuyên môn khớp cao | `c_services_ky_nang_chuyen_mon_khop_cao` | khác |
| `lib/core/services/ai/rule_based_scorer.dart:118` | Kinh nghiệm đáp ứng yêu cầu | `c_services_kinh_nghiem_dap_ung_yeu_cau` | khác |
| `lib/core/services/ai/rule_based_scorer.dart:119` | Kinh nghiệm cùng ngành | `c_services_kinh_nghiem_cung_nganh` | khác |
| `lib/core/services/ai/rule_based_scorer.dart:120` | Soft skills tốt | `c_services_soft_skills_tot` | khác |
| `lib/core/services/ai/rule_based_scorer.dart:125` |  : jobSkills.length} kỹ năng khớp,  | `c_services_jobskills_length_ky_nang_khop` | khác |
| `lib/core/services/ai/rule_based_scorer.dart:126` | $expStr/$minStr năm KN.  | `c_services_expstr_minstr_nam_kn` | khác |
| `lib/core/services/ai_session_store.dart:54` | Không rõ | `c_services_khong_ro` | khác |
| `lib/core/services/ai_session_store.dart:122` | Không rõ | `c_services_khong_ro` | khác |
| `lib/core/services/auth_service.dart:36` | Tài khoản đã bị vô hiệu hóa. | `app_tai_khoan_da_bi_vo_hieu_hoa` | validation/lỗi |
| `lib/core/services/auth_service.dart:52` | Không thể tự đăng ký tài khoản quản trị. | `c_services_khong_the_tu_dang_ky_tai_khoan_quan_tri` | validation/lỗi |
| `lib/core/services/auth_service.dart:98` | Mật khẩu hiện tại không đúng. | `c_services_mat_khau_hien_tai_khong_dung` | validation/lỗi |
| `lib/core/services/fcm_service.dart:56` | Thông báo từ JobHub (hồ sơ ứng tuyển, tin tuyển dụng, hệ thống). | `c_services_thong_bao_tu_jobhub_ho_so_ung_tuyen_tin_tu` | khác |
| `lib/core/services/system_config_repository.dart:18` | Số kỹ năng tối đa cho một tin tuyển dụng. | `c_services_so_ky_nang_toi_da_cho_mot_tin_tuyen_dung` | khác |
| `lib/core/services/system_config_repository.dart:24` | Số ngày mặc định cho hạn nộp hồ sơ khi nhà tuyển dụng không chọn. | `c_services_so_ngay_mac_dinh_cho_han_nop_ho_so_khi_nha` | khác |
| `lib/core/services/system_config_repository.dart:30` | Tin tuyển dụng mới cần admin duyệt trước khi hiển thị. | `c_services_tin_tuyen_dung_moi_can_admin_duyet_truoc_k` | khác |
| `lib/core/services/system_config_repository.dart:36` | API key Gemini dùng cho AI phân tích CV / chấm điểm (chỉ admin thấy). | `c_services_api_key_gemini_dung_cho_ai_phan_tich_cv_ch` | khác |
| `lib/core/services/system_config_repository.dart:80` | Không tìm thấy cấu hình hệ thống. | `c_services_khong_tim_thay_cau_hinh_he_thong` | validation/lỗi |
| `lib/core/services/system_config_repository.dart:86` | Giá trị cấu hình phải là số không âm. | `c_services_gia_tri_cau_hinh_phai_la_so_khong_am` | validation/lỗi |
| `lib/core/services/system_config_repository.dart:91` | Giá trị cấu hình phải là true hoặc false. | `c_services_gia_tri_cau_hinh_phai_la_true_hoac_false` | validation/lỗi |
| `lib/core/services/system_config_repository.dart:96` | Giá trị cấu hình không được để trống. | `c_services_gia_tri_cau_hinh_khong_duoc_de_trong` | validation/lỗi |

### `core/utils` (105)

| Vị trí | Chuỗi | Key đề xuất | Ngữ cảnh |
|---|---|---|---|
| `lib/core/utils/enums.dart:108` | Tại văn phòng | `c_utils_tai_van_phong` | enum/option |
| `lib/core/utils/enums.dart:109` | Từ xa | `c_utils_tu_xa` | enum/option |
| `lib/core/utils/enums.dart:110` | Kết hợp | `c_utils_ket_hop` | enum/option |
| `lib/core/utils/enums.dart:116` | Toàn thời gian | `c_utils_toan_thoi_gian` | enum/option |
| `lib/core/utils/enums.dart:117` | Bán thời gian | `c_utils_ban_thoi_gian` | enum/option |
| `lib/core/utils/enums.dart:118` | Thực tập | `c_utils_thuc_tap` | enum/option |
| `lib/core/utils/enums.dart:119` | Hợp đồng | `c_utils_hop_dong` | enum/option |
| `lib/core/utils/enums.dart:125` | Thực tập sinh | `c_utils_thuc_tap_sinh` | enum/option |
| `lib/core/utils/enums.dart:130` | Lead / Quản lý | `c_utils_lead_quan_ly` | enum/option |
| `lib/core/utils/enums.dart:137` | Đang tuyển | `c_utils_dang_tuyen` | enum/option |
| `lib/core/utils/enums.dart:138` | Tạm dừng | `c_utils_tam_dung` | enum/option |
| `lib/core/utils/enums.dart:139` | Đã đóng | `c_utils_da_dong` | enum/option |
| `lib/core/utils/enums.dart:140` | Hết hạn | `c_utils_het_han` | enum/option |
| `lib/core/utils/enums.dart:146` | Đã nộp | `c_utils_da_nop` | enum/option |
| `lib/core/utils/enums.dart:147` | Đang xem xét | `c_utils_dang_xem_xet` | enum/option |
| `lib/core/utils/enums.dart:148` | Phỏng vấn | `c_utils_phong_van` | enum/option |
| `lib/core/utils/enums.dart:149` | Đã có offer | `c_utils_da_co_offer` | enum/option |
| `lib/core/utils/enums.dart:150` | Được nhận | `c_utils_duoc_nhan` | enum/option |
| `lib/core/utils/enums.dart:151` | Từ chối | `c_utils_tu_choi` | enum/option |
| `lib/core/utils/enums.dart:152` | Đã rút | `c_utils_da_rut` | enum/option |
| `lib/core/utils/failure.dart:21` | Đã có lỗi xảy ra. Vui lòng thử lại. | `c_utils_da_co_loi_xay_ra_vui_long_thu_lai` | khác |
| `lib/core/utils/failure.dart:22` | Không kết nối được máy chủ. Vui lòng kiểm tra mạng. | `c_utils_khong_ket_noi_duoc_may_chu_vui_long_kiem_t` | khác |
| `lib/core/utils/failure.dart:23` | Lỗi hệ thống. Vui lòng thử lại sau. | `c_utils_loi_he_thong_vui_long_thu_lai_sau` | khác |
| `lib/core/utils/failure.dart:25` | Vui lòng đăng nhập để tiếp tục. | `c_utils_vui_long_dang_nhap_de_tiep_tuc` | validation/lỗi |
| `lib/core/utils/failure.dart:27` | Bạn không có quyền thực hiện thao tác này. | `c_utils_ban_khong_co_quyen_thuc_hien_thao_tac_nay` | validation/lỗi |
| `lib/core/utils/failure.dart:29` | Không tìm thấy dữ liệu. | `c_utils_khong_tim_thay_du_lieu` | validation/lỗi |
| `lib/core/utils/failure.dart:48` | Dữ liệu trả về không hợp lệ. | `c_utils_du_lieu_tra_ve_khong_hop_le` | validation/lỗi |
| `lib/core/utils/failure.dart:63` | Email hoặc mật khẩu không đúng. | `c_utils_email_hoac_mat_khau_khong_dung` | validation/lỗi |
| `lib/core/utils/failure.dart:65` | Tài khoản đã bị vô hiệu hóa. | `app_tai_khoan_da_bi_vo_hieu_hoa` | validation/lỗi |
| `lib/core/utils/failure.dart:67` | Email đã được sử dụng. | `c_utils_email_da_duoc_su_dung` | validation/lỗi |
| `lib/core/utils/failure.dart:69` | Mật khẩu phải có ít nhất 8 ký tự. | `c_utils_mat_khau_phai_co_it_nhat_8_ky_tu` | validation/lỗi |
| `lib/core/utils/failure.dart:71` | Quá nhiều yêu cầu. Vui lòng thử lại sau. | `c_utils_qua_nhieu_yeu_cau_vui_long_thu_lai_sau` | validation/lỗi |
| `lib/core/utils/failure.dart:75` | Vui lòng đăng nhập lại để thực hiện thao tác này. | `c_utils_vui_long_dang_nhap_lai_de_thuc_hien_thao_t` | validation/lỗi |
| `lib/core/utils/failure.dart:84` | Bạn không có quyền thực hiện thao tác này. | `c_utils_ban_khong_co_quyen_thuc_hien_thao_tac_nay` | validation/lỗi |
| `lib/core/utils/failure.dart:86` | Không tìm thấy dữ liệu. | `c_utils_khong_tim_thay_du_lieu` | validation/lỗi |
| `lib/core/utils/failure.dart:88` | Dữ liệu đã tồn tại. | `c_utils_du_lieu_da_ton_tai` | validation/lỗi |
| `lib/core/utils/failure.dart:93` | Truy vấn cần chỉ mục Firestore. Hãy deploy firestore.indexes.json. … | `c_utils_truy_van_can_chi_muc_firestore_hay_deploy` | validation/lỗi |
| `lib/core/utils/failure.dart:98` | Đã vượt hạn mức Firebase. Vui lòng thử lại sau. | `c_utils_da_vuot_han_muc_firebase_vui_long_thu_lai` | validation/lỗi |
| `lib/core/utils/formatters.dart:34` | Thoả thuận | `c_config_thoa_thuan` | khác |
| `lib/core/utils/formatters.dart:37` | Từ ${number(min)} $currency | `c_utils_tu_number_min_currency` | khác |
| `lib/core/utils/formatters.dart:38` | Đến ${number(max!)} $currency | `c_utils_den_number_max_currency` | khác |
| `lib/core/utils/formatters.dart:40` | ${_trieu(min)} - ${_trieu(max)} triệu | `c_utils_trieu_min_trieu_max_trieu` | khác |
| `lib/core/utils/formatters.dart:41` | Từ ${_trieu(min)} triệu | `c_utils_tu_trieu_min_trieu` | khác |
| `lib/core/utils/formatters.dart:42` | Đến ${_trieu(max!)} triệu | `c_utils_den_trieu_max_trieu` | khác |
| `lib/core/utils/formatters.dart:48` | Thỏa thuận | `c_utils_thoa_thuan` | khác |
| `lib/core/utils/formatters.dart:50` | ${tr(min)} – ${tr(max)} triệu $currency | `c_utils_tr_min_tr_max_trieu_currency` | khác |
| `lib/core/utils/formatters.dart:51` | Từ ${tr(min)} triệu $currency | `c_utils_tu_tr_min_trieu_currency` | khác |
| `lib/core/utils/formatters.dart:52` | Lên đến ${tr(max!)} triệu $currency | `c_utils_len_den_tr_max_trieu_currency` | khác |
| `lib/core/utils/formatters.dart:55` | Chưa cập nhật | `c_utils_chua_cap_nhat` | enum/option |
| `lib/core/utils/formatters.dart:64` | Đăng gần đây | `c_utils_dang_gan_day` | khác |
| `lib/core/utils/formatters.dart:66` | Đăng hôm nay | `c_utils_dang_hom_nay` | khác |
| `lib/core/utils/formatters.dart:67` | Đăng 1 ngày trước | `c_utils_dang_1_ngay_truoc` | khác |
| `lib/core/utils/formatters.dart:68` | Đăng $days ngày trước | `c_utils_dang_days_ngay_truoc` | khác |
| `lib/core/utils/formatters.dart:70` | Đăng $weeks tuần trước | `c_utils_dang_weeks_tuan_truoc` | khác |
| `lib/core/utils/formatters.dart:72` | Đăng $months tháng trước | `c_utils_dang_months_thang_truoc` | khác |
| `lib/core/utils/formatters.dart:82` | Chưa cập nhật | `c_utils_chua_cap_nhat` | khác |
| `lib/core/utils/formatters.dart:88` | $base (còn $diff ngày) | `c_utils_base_con_diff_ngay` | khác |
| `lib/core/utils/formatters.dart:89` | $base (hết hạn hôm nay) | `c_utils_base_het_han_hom_nay` | khác |
| `lib/core/utils/formatters.dart:90` | $base (đã hết hạn) | `c_utils_base_da_het_han` | khác |
| `lib/core/utils/formatters.dart:103` | vừa xong | `c_utils_vua_xong` | khác |
| `lib/core/utils/formatters.dart:104` | ${diff.inMinutes} phút trước | `c_utils_diff_inminutes_phut_truoc` | khác |
| `lib/core/utils/formatters.dart:105` | ${diff.inHours} giờ trước | `c_utils_diff_inhours_gio_truoc` | khác |
| `lib/core/utils/formatters.dart:106` | ${diff.inDays} ngày trước | `c_utils_diff_indays_ngay_truoc` | khác |
| `lib/core/utils/formatters.dart:132` | Công ty chưa cập nhật | `c_utils_cong_ty_chua_cap_nhat` | khác |
| `lib/core/utils/validators.dart:10` | Trường này | `c_utils_truong_nay` | khác |
| `lib/core/utils/validators.dart:11` | $label là bắt buộc. | `c_utils_label_la_bat_buoc` | khác |
| `lib/core/utils/validators.dart:18` | Email là bắt buộc. | `c_utils_email_la_bat_buoc` | khác |
| `lib/core/utils/validators.dart:19` | Email không hợp lệ. | `c_utils_email_khong_hop_le` | khác |
| `lib/core/utils/validators.dart:25` | Mật khẩu là bắt buộc. | `c_utils_mat_khau_la_bat_buoc` | khác |
| `lib/core/utils/validators.dart:26` | Mật khẩu phải có ít nhất 8 ký tự. | `c_utils_mat_khau_phai_co_it_nhat_8_ky_tu` | khác |
| `lib/core/utils/validators.dart:27` | Mật khẩu không được vượt quá 128 ký tự. | `c_utils_mat_khau_khong_duoc_vuot_qua_128_ky_tu` | khác |
| `lib/core/utils/validators.dart:32` | Vui lòng xác nhận mật khẩu. | `c_utils_vui_long_xac_nhan_mat_khau` | khác |
| `lib/core/utils/validators.dart:33` | Mật khẩu xác nhận không khớp. | `c_utils_mat_khau_xac_nhan_khong_khop` | khác |
| `lib/core/utils/validators.dart:38` | Họ tên | `c_utils_ho_ten` | khác |
| `lib/core/utils/validators.dart:40` | $label là bắt buộc. | `c_utils_label_la_bat_buoc` | khác |
| `lib/core/utils/validators.dart:41` | $label tối đa 100 ký tự. | `c_utils_label_toi_da_100_ky_tu` | khác |
| `lib/core/utils/validators.dart:48` | Tên công ty là bắt buộc. | `c_utils_ten_cong_ty_la_bat_buoc` | khác |
| `lib/core/utils/validators.dart:49` | Tên công ty tối đa 255 ký tự. | `c_utils_ten_cong_ty_toi_da_255_ky_tu` | khác |
| `lib/core/utils/validators.dart:56` | Số điện thoại là bắt buộc. | `c_utils_so_dien_thoai_la_bat_buoc` | khác |
| `lib/core/utils/validators.dart:57` | Số điện thoại không hợp lệ. | `c_utils_so_dien_thoai_khong_hop_le` | khác |
| `lib/core/utils/validators.dart:64` | Vui lòng chọn tỉnh/thành phố. | `c_utils_vui_long_chon_tinh_thanh_pho` | khác |
| `lib/core/utils/validators.dart:65` | Tỉnh/thành phố không hợp lệ. | `c_utils_tinh_thanh_pho_khong_hop_le` | khác |
| `lib/core/utils/validators.dart:70` | Vui lòng chọn giới tính. | `c_utils_vui_long_chon_gioi_tinh` | khác |
| `lib/core/utils/validators.dart:75` | Website không hợp lệ. | `c_utils_website_khong_hop_le` | khác |
| `lib/core/utils/validators.dart:79` | Trường này | `c_utils_truong_nay` | khác |
| `lib/core/utils/validators.dart:80` | $label tối đa $max ký tự. | `c_utils_label_toi_da_max_ky_tu` | khác |
| `lib/core/utils/validators.dart:84` | Trường này | `c_utils_truong_nay` | khác |
| `lib/core/utils/validators.dart:86` | $label là bắt buộc. | `c_utils_label_la_bat_buoc` | khác |
| `lib/core/utils/validators.dart:87` | $label phải có ít nhất $min ký tự. | `c_utils_label_phai_co_it_nhat_min_ky_tu` | khác |
| `lib/core/utils/validators.dart:88` | $label tối đa $max ký tự. | `c_utils_label_toi_da_max_ky_tu` | khác |
| `lib/core/utils/validators.dart:94` | Tiêu đề | `c_utils_tieu_de` | label |
| `lib/core/utils/validators.dart:96` | Mô tả công việc | `c_utils_mo_ta_cong_viec` | label |
| `lib/core/utils/validators.dart:98` | Địa điểm làm việc | `c_utils_dia_diem_lam_viec` | label |
| `lib/core/utils/validators.dart:100` | Giá trị | `c_utils_gia_tri` | khác |
| `lib/core/utils/validators.dart:102` | $label là bắt buộc. | `c_utils_label_la_bat_buoc` | khác |
| `lib/core/utils/validators.dart:104` | $label phải là số không âm. | `c_utils_label_phai_la_so_khong_am` | khác |
| `lib/core/utils/validators.dart:108` | Giá trị | `c_utils_gia_tri` | khác |
| `lib/core/utils/validators.dart:110` | $label phải là số nguyên ≥ 1. | `c_utils_label_phai_la_so_nguyen_1` | khác |
| `lib/core/utils/validators.dart:116` | Lương tối thiểu phải nhỏ hơn hoặc bằng lương tối đa. | `c_utils_luong_toi_thieu_phai_nho_hon_hoac_bang_luo` | khác |
| `lib/core/utils/validators.dart:125` | Hạn nộp hồ sơ phải là hôm nay hoặc trong tương lai. | `c_utils_han_nop_ho_so_phai_la_hom_nay_hoac_trong_t` | khác |
| `lib/core/utils/validators.dart:131` | Thư giới thiệu | `c_utils_thu_gioi_thieu` | label |
| `lib/core/utils/validators.dart:136` | Nội dung CV phải có ít nhất 20 ký tự. | `c_utils_noi_dung_cv_phai_co_it_nhat_20_ky_tu` | khác |
| `lib/core/utils/validators.dart:143` | Giá trị cấu hình phải là số không âm. | `c_services_gia_tri_cau_hinh_phai_la_so_khong_am` | khác |
| `lib/core/utils/validators.dart:149` | Giá trị cấu hình phải là true hoặc false. | `c_services_gia_tri_cau_hinh_phai_la_true_hoac_false` | khác |
| `lib/core/utils/validators.dart:154` | Giá trị cấu hình không được để trống. | `c_services_gia_tri_cau_hinh_khong_duoc_de_trong` | khác |

### `features/admin` (249)

| Vị trí | Chuỗi | Key đề xuất | Ngữ cảnh |
|---|---|---|---|
| `lib/features/admin/data/admin_repository.dart:73` | Không tìm thấy tài khoản. | `admin_khong_tim_thay_tai_khoan` | validation/lỗi |
| `lib/features/admin/data/admin_repository.dart:112` | Không tìm thấy nhà tuyển dụng. | `admin_khong_tim_thay_nha_tuyen_dung` | validation/lỗi |
| `lib/features/admin/data/admin_repository.dart:148` | Không tìm thấy tin tuyển dụng. | `admin_khong_tim_thay_tin_tuyen_dung` | validation/lỗi |
| `lib/features/admin/data/admin_repository.dart:162` | Tin tuyển dụng đã được duyệt | `admin_tin_tuyen_dung_da_duoc_duyet` | title |
| `lib/features/admin/data/admin_repository.dart:162` | Tin tuyển dụng bị từ chối | `admin_tin_tuyen_dung_bi_tu_choi` | title |
| `lib/features/admin/data/admin_repository.dart:164` | Tin tuyển dụng "${job.jobTitle}" đã được duyệt và hiển thị công khai. | `admin_tin_tuyen_dung_job_jobtitle_da_duoc_duyet` | khác |
| `lib/features/admin/data/admin_repository.dart:165` | Tin tuyển dụng "${job.jobTitle}" đã bị từ chối. | `admin_tin_tuyen_dung_job_jobtitle_da_bi_tu_choi` | khác |
| `lib/features/admin/data/admin_repository.dart:180` | Vui lòng nhập tên ngành nghề. | `admin_vui_long_nhap_ten_nganh_nghe` | khác |
| `lib/features/admin/data/admin_repository.dart:188` | Không xác định được mã ngành nghề cần xoá. | `admin_khong_xac_dinh_duoc_ma_nganh_nghe_can_xoa` | validation/lỗi |
| `lib/features/admin/data/admin_repository.dart:200` | Ngành nghề "$name" đã tồn tại. | `admin_nganh_nghe_name_da_ton_tai` | validation/lỗi |
| `lib/features/admin/data/admin_repository.dart:213` | Vui lòng nhập tên kỹ năng. | `admin_vui_long_nhap_ten_ky_nang` | khác |
| `lib/features/admin/data/admin_repository.dart:221` | Không xác định được mã kỹ năng cần xoá. | `admin_khong_xac_dinh_duoc_ma_ky_nang_can_xoa` | validation/lỗi |
| `lib/features/admin/data/admin_repository.dart:233` | Kỹ năng "$name" đã tồn tại. | `admin_ky_nang_name_da_ton_tai` | validation/lỗi |
| `lib/features/admin/data/admin_repository.dart:408` | Tên không được vượt quá 100 ký tự. | `admin_ten_khong_duoc_vuot_qua_100_ky_tu` | validation/lỗi |
| `lib/features/admin/viewmodels/admin_dashboard_viewmodel.dart:25` | Đã seed dữ liệu demo: ${s.categories} ngành nghề, ${s.skills} kỹ nă… | `admin_da_seed_du_lieu_demo_s_categories_nganh_ng` | khác |
| `lib/features/admin/viewmodels/admin_employers_viewmodel.dart:14` | Tất cả xác minh | `admin_tat_ca_xac_minh` | enum/option |
| `lib/features/admin/viewmodels/admin_employers_viewmodel.dart:15` | Đã xác minh | `admin_da_xac_minh` | enum/option |
| `lib/features/admin/viewmodels/admin_employers_viewmodel.dart:16` | Chờ xác minh | `admin_cho_xac_minh` | enum/option |
| `lib/features/admin/viewmodels/admin_employers_viewmodel.dart:29` | Tất cả tài khoản | `admin_tat_ca_tai_khoan` | khác |
| `lib/features/admin/viewmodels/admin_users_viewmodel.dart:13` | Tất cả trạng thái | `admin_tat_ca_trang_thai` | enum/option |
| `lib/features/admin/viewmodels/admin_users_viewmodel.dart:14` | Đang hoạt động | `admin_dang_hoat_dong` | enum/option |
| `lib/features/admin/viewmodels/admin_users_viewmodel.dart:15` | Đã khóa | `admin_da_khoa` | enum/option |
| `lib/features/admin/viewmodels/catalog_viewmodel.dart:35` | Vui lòng nhập tên ngành nghề. | `admin_vui_long_nhap_ten_nganh_nghe` | khác |
| `lib/features/admin/viewmodels/catalog_viewmodel.dart:36` | Không thể thêm ngành nghề. | `admin_khong_the_them_nganh_nghe` | khác |
| `lib/features/admin/viewmodels/catalog_viewmodel.dart:37` | Đã thêm ngành nghề "$n". | `admin_da_them_nganh_nghe_n` | enum/option |
| `lib/features/admin/viewmodels/catalog_viewmodel.dart:44` | Vui lòng nhập tên kỹ năng. | `admin_vui_long_nhap_ten_ky_nang` | khác |
| `lib/features/admin/viewmodels/catalog_viewmodel.dart:45` | Không thể thêm kỹ năng. | `admin_khong_the_them_ky_nang` | khác |
| `lib/features/admin/viewmodels/catalog_viewmodel.dart:46` | Đã thêm kỹ năng "$n". | `admin_da_them_ky_nang_n` | enum/option |
| `lib/features/admin/viewmodels/catalog_viewmodel.dart:53` | Không xác định được mã ngành nghề cần xoá. | `admin_khong_xac_dinh_duoc_ma_nganh_nghe_can_xoa` | khác |
| `lib/features/admin/viewmodels/catalog_viewmodel.dart:54` | Không thể xoá ngành nghề. | `admin_khong_the_xoa_nganh_nghe` | khác |
| `lib/features/admin/viewmodels/catalog_viewmodel.dart:55` | Đã xoá ngành nghề "$name". | `admin_da_xoa_nganh_nghe_name` | khác |
| `lib/features/admin/viewmodels/catalog_viewmodel.dart:62` | Không xác định được mã kỹ năng cần xoá. | `admin_khong_xac_dinh_duoc_ma_ky_nang_can_xoa` | khác |
| `lib/features/admin/viewmodels/catalog_viewmodel.dart:63` | Không thể xoá kỹ năng. | `admin_khong_the_xoa_ky_nang` | khác |
| `lib/features/admin/viewmodels/catalog_viewmodel.dart:64` | Đã xoá kỹ năng "$name". | `admin_da_xoa_ky_nang_name` | khác |
| `lib/features/admin/viewmodels/system_config_viewmodel.dart:102` | Số kỹ năng tối đa phải là số nguyên lớn hơn 0. | `admin_so_ky_nang_toi_da_phai_la_so_nguyen_lon_ho` | validation/lỗi |
| `lib/features/admin/viewmodels/system_config_viewmodel.dart:107` | Số ngày hạn tuyển dụng phải là số nguyên lớn hơn 0. | `admin_so_ngay_han_tuyen_dung_phai_la_so_nguyen_l` | validation/lỗi |
| `lib/features/admin/viewmodels/system_config_viewmodel.dart:120` | Cập nhật cấu hình hệ thống thành công. | `admin_cap_nhat_cau_hinh_he_thong_thanh_cong` | validation/lỗi |
| `lib/features/admin/viewmodels/system_config_viewmodel.dart:123` | Không thể xử lý cấu hình hệ thống. | `admin_khong_the_xu_ly_cau_hinh_he_thong` | validation/lỗi |
| `lib/features/admin/viewmodels/system_config_viewmodel.dart:134` | Đã khởi tạo cấu hình mặc định. | `admin_da_khoi_tao_cau_hinh_mac_dinh` | validation/lỗi |
| `lib/features/admin/viewmodels/system_config_viewmodel.dart:137` | Không thể khởi tạo cấu hình mặc định. | `admin_khong_the_khoi_tao_cau_hinh_mac_dinh` | validation/lỗi |
| `lib/features/admin/viewmodels/system_config_viewmodel.dart:183` | API key phải có ít nhất 8 ký tự. | `admin_api_key_phai_co_it_nhat_8_ky_tu` | validation/lỗi |
| `lib/features/admin/viewmodels/system_config_viewmodel.dart:193` | Đã lưu key mới — các lời gọi AI tiếp theo sẽ dùng key này. | `admin_da_luu_key_moi_cac_loi_goi_ai_tiep_theo_se` | khác |
| `lib/features/admin/viewmodels/system_config_viewmodel.dart:199` | Lỗi khi lưu key | `admin_loi_khi_luu_key` | validation/lỗi |
| `lib/features/admin/viewmodels/system_config_viewmodel.dart:217` | Đã revert về key trong .env. | `admin_da_revert_ve_key_trong_env` | khác |
| `lib/features/admin/viewmodels/system_config_viewmodel.dart:218` | Đã xoá Gemini API key đã lưu. | `admin_da_xoa_gemini_api_key_da_luu` | khác |
| `lib/features/admin/viewmodels/system_config_viewmodel.dart:225` | Lỗi khi xoá override | `admin_loi_khi_xoa_override` | validation/lỗi |
| `lib/features/admin/views/admin_dashboard_page.dart:22` | Quản lý người dùng | `admin_quan_ly_nguoi_dung` | khác |
| `lib/features/admin/views/admin_dashboard_page.dart:22` | Khóa / kích hoạt tài khoản ứng viên và nhà tuyển dụng. | `admin_khoa_kich_hoat_tai_khoan_ung_vien_va_nha_t` | khác |
| `lib/features/admin/views/admin_dashboard_page.dart:24` | Quản lý nhà tuyển dụng | `admin_quan_ly_nha_tuyen_dung` | khác |
| `lib/features/admin/views/admin_dashboard_page.dart:24` | Xác minh thông tin doanh nghiệp. | `admin_xac_minh_thong_tin_doanh_nghiep` | khác |
| `lib/features/admin/views/admin_dashboard_page.dart:26` | Duyệt tin tuyển dụng | `admin_duyet_tin_tuyen_dung` | khác |
| `lib/features/admin/views/admin_dashboard_page.dart:26` | Duyệt hoặc từ chối tin đang chờ. | `admin_duyet_hoac_tu_choi_tin_dang_cho` | khác |
| `lib/features/admin/views/admin_dashboard_page.dart:28` | Quản lý ngành nghề và kỹ năng | `admin_quan_ly_nganh_nghe_va_ky_nang` | khác |
| `lib/features/admin/views/admin_dashboard_page.dart:28` | Thêm hoặc xoá ngành nghề, kỹ năng. | `admin_them_hoac_xoa_nganh_nghe_ky_nang` | khác |
| `lib/features/admin/views/admin_dashboard_page.dart:30` | Cấu hình hệ thống | `admin_cau_hinh_he_thong` | khác |
| `lib/features/admin/views/admin_dashboard_page.dart:30` | Quy tắc dùng chung của hệ thống JobHub. | `admin_quy_tac_dung_chung_cua_he_thong_jobhub` | khác |
| `lib/features/admin/views/admin_dashboard_page.dart:32` | Thống kê AI Logs | `admin_thong_ke_ai_logs` | khác |
| `lib/features/admin/views/admin_dashboard_page.dart:32` | Hiệu năng, token, xu hướng 7 ngày, Gemini API key. | `admin_hieu_nang_token_xu_huong_7_ngay_gemini_api` | khác |
| `lib/features/admin/views/admin_dashboard_page.dart:34` | Prompt / response từng lượt gọi AI. | `admin_prompt_response_tung_luot_goi_ai` | khác |
| `lib/features/admin/views/admin_dashboard_page.dart:36` | Hồ sơ ứng tuyển | `admin_ho_so_ung_tuyen` | khác |
| `lib/features/admin/views/admin_dashboard_page.dart:36` | Toàn bộ hồ sơ ứng tuyển trên hệ thống. | `admin_toan_bo_ho_so_ung_tuyen_tren_he_thong` | khác |
| `lib/features/admin/views/admin_dashboard_page.dart:43` | Seed dữ liệu demo | `admin_seed_du_lieu_demo` | title |
| `lib/features/admin/views/admin_dashboard_page.dart:45` | Thao tác này sẽ ghi dữ liệu demo (ngành nghề, kỹ năng, nhà tuyển dụ… | `admin_thao_tac_nay_se_ghi_du_lieu_demo_nganh_ngh` | nội dung dài |
| `lib/features/admin/views/admin_dashboard_page.dart:46` | Seed dữ liệu | `admin_seed_du_lieu` | khác |
| `lib/features/admin/views/admin_dashboard_page.dart:53` | Đã seed dữ liệu demo thành công. | `admin_da_seed_du_lieu_demo_thanh_cong` | khác |
| `lib/features/admin/views/admin_dashboard_page.dart:69` | Quản trị hệ thống | `admin_quan_tri_he_thong` | khác |
| `lib/features/admin/views/admin_dashboard_page.dart:70` | Tổng quan quản trị | `admin_tong_quan_quan_tri` | title |
| `lib/features/admin/views/admin_dashboard_page.dart:72` | Theo dõi số liệu hệ thống và truy cập nhanh các chức năng quản trị. | `admin_theo_doi_so_lieu_he_thong_va_truy_cap_nhan` | khác |
| `lib/features/admin/views/admin_dashboard_page.dart:73` | Xin chào ${user.fullName}. Theo dõi số liệu hệ thống và truy cập nh… | `admin_xin_chao_user_fullname_theo_doi_so_lieu_he` | khác |
| `lib/features/admin/views/admin_dashboard_page.dart:77` | Làm mới | `admin_lam_moi` | label |
| `lib/features/admin/views/admin_dashboard_page.dart:86` | Đang tải số liệu hệ thống... | `admin_dang_tai_so_lieu_he_thong` | enum/option |
| `lib/features/admin/views/admin_dashboard_page.dart:102` | Người dùng | `admin_nguoi_dung` | khác |
| `lib/features/admin/views/admin_dashboard_page.dart:108` | Tổng tài khoản | `admin_tong_tai_khoan` | label |
| `lib/features/admin/views/admin_dashboard_page.dart:113` | Ứng viên | `admin_ung_vien` | label |
| `lib/features/admin/views/admin_dashboard_page.dart:118` | Nhà tuyển dụng | `admin_nha_tuyen_dung` | label |
| `lib/features/admin/views/admin_dashboard_page.dart:124` | Quản trị viên | `admin_quan_tri_vien` | label |
| `lib/features/admin/views/admin_dashboard_page.dart:131` | Tin tuyển dụng & hồ sơ | `admin_tin_tuyen_dung_ho_so` | khác |
| `lib/features/admin/views/admin_dashboard_page.dart:137` | Tổng tin tuyển dụng | `admin_tong_tin_tuyen_dung` | label |
| `lib/features/admin/views/admin_dashboard_page.dart:141` | Tin đang tuyển | `admin_tin_dang_tuyen` | label |
| `lib/features/admin/views/admin_dashboard_page.dart:146` | Tin chờ duyệt | `admin_tin_cho_duyet` | label |
| `lib/features/admin/views/admin_dashboard_page.dart:152` | Hồ sơ ứng tuyển | `admin_ho_so_ung_tuyen` | label |
| `lib/features/admin/views/admin_dashboard_page.dart:164` | Chức năng quản trị | `admin_chuc_nang_quan_tri` | khác |
| `lib/features/admin/views/admin_dashboard_page.dart:210` | Dữ liệu demo | `admin_du_lieu_demo` | khác |
| `lib/features/admin/views/admin_dashboard_page.dart:229` | Ghi bộ dữ liệu mẫu của trang web (18 ngành nghề, kỹ năng phổ biến, … | `admin_ghi_bo_du_lieu_mau_cua_trang_web_18_nganh` | nội dung dài |
| `lib/features/admin/views/admin_dashboard_page.dart:244` | Đang seed... | `admin_dang_seed` | label |
| `lib/features/admin/views/admin_dashboard_page.dart:244` | Seed dữ liệu demo | `admin_seed_du_lieu_demo` | label |
| `lib/features/admin/views/admin_dashboard_page.dart:302` | Tin tuyển dụng theo trạng thái | `admin_tin_tuyen_dung_theo_trang_thai` | text hiển thị |
| `lib/features/admin/views/admin_employers_page.dart:35` | xác minh | `admin_xac_minh` | khác |
| `lib/features/admin/views/admin_employers_page.dart:35` | hủy xác minh | `admin_huy_xac_minh` | khác |
| `lib/features/admin/views/admin_employers_page.dart:38` | Bạn có chắc muốn $label nhà tuyển dụng này? | `admin_ban_co_chac_muon_label_nha_tuyen_dung_nay` | validation/lỗi |
| `lib/features/admin/views/admin_employers_page.dart:39` | Xác minh | `admin_xac_minh_2` | khác |
| `lib/features/admin/views/admin_employers_page.dart:39` | Hủy xác minh | `admin_huy_xac_minh_2` | khác |
| `lib/features/admin/views/admin_employers_page.dart:48` | Không thể $label nhà tuyển dụng. | `admin_khong_the_label_nha_tuyen_dung` | khác |
| `lib/features/admin/views/admin_employers_page.dart:69` | Tìm công ty hoặc email | `admin_tim_cong_ty_hoac_email` | form hint/label |
| `lib/features/admin/views/admin_employers_page.dart:95` | Tìm kiếm | `admin_tim_kiem` | button |
| `lib/features/admin/views/admin_employers_page.dart:102` | Quản lý nhà tuyển dụng | `admin_quan_ly_nha_tuyen_dung` | title |
| `lib/features/admin/views/admin_employers_page.dart:104` | Xác minh thông tin doanh nghiệp. Trạng thái đăng nhập được quản lý … | `admin_xac_minh_thong_tin_doanh_nghiep_trang_thai` | khác |
| `lib/features/admin/views/admin_employers_page.dart:162` | Đang tải danh sách... | `admin_dang_tai_danh_sach` | khác |
| `lib/features/admin/views/admin_employers_page.dart:164` | Không tìm thấy nhà tuyển dụng phù hợp. | `admin_khong_tim_thay_nha_tuyen_dung_phu_hop` | khác |
| `lib/features/admin/views/admin_employers_page.dart:168` | nhà tuyển dụng | `admin_nha_tuyen_dung_2` | khác |
| `lib/features/admin/views/admin_employers_page.dart:205` | Công ty chưa cập nhật | `c_utils_cong_ty_chua_cap_nhat` | khác |
| `lib/features/admin/views/admin_employers_page.dart:210` | Đã xác minh | `admin_da_xac_minh` | khác |
| `lib/features/admin/views/admin_employers_page.dart:211` | Chờ xác minh | `admin_cho_xac_minh` | khác |
| `lib/features/admin/views/admin_employers_page.dart:217` | Tài khoản hoạt động | `admin_tai_khoan_hoat_dong` | khác |
| `lib/features/admin/views/admin_employers_page.dart:218` | Tài khoản đã khóa | `admin_tai_khoan_da_khoa` | khác |
| `lib/features/admin/views/admin_employers_page.dart:229` | Người liên hệ: ${(e.contactName ??  | `admin_nguoi_lien_he_e_contactname` | khác |
| `lib/features/admin/views/admin_employers_page.dart:237` | Đang xử lý... | `admin_dang_xu_ly` | khác |
| `lib/features/admin/views/admin_employers_page.dart:237` | Hủy xác minh | `admin_huy_xac_minh_2` | khác |
| `lib/features/admin/views/admin_employers_page.dart:237` | Xác minh doanh nghiệp | `admin_xac_minh_doanh_nghiep` | khác |
| `lib/features/admin/views/admin_pending_jobs_page.dart:20` | từ chối | `admin_tu_choi` | khác |
| `lib/features/admin/views/admin_pending_jobs_page.dart:23` | Bạn có chắc muốn $label tin tuyển dụng này không? | `admin_ban_co_chac_muon_label_tin_tuyen_dung_nay` | validation/lỗi |
| `lib/features/admin/views/admin_pending_jobs_page.dart:24` | Từ chối | `c_utils_tu_choi` | khác |
| `lib/features/admin/views/admin_pending_jobs_page.dart:33` | Không thể xử lý tin tuyển dụng. | `admin_khong_the_xu_ly_tin_tuyen_dung` | khác |
| `lib/features/admin/views/admin_pending_jobs_page.dart:59` | Duyệt tin tuyển dụng | `admin_duyet_tin_tuyen_dung` | khác |
| `lib/features/admin/views/admin_pending_jobs_page.dart:60` | Danh sách tin chờ duyệt | `admin_danh_sach_tin_cho_duyet` | title |
| `lib/features/admin/views/admin_pending_jobs_page.dart:62` | Quản trị viên có thể duyệt hoặc từ chối các tin tuyển dụng do nhà t… | `admin_quan_tri_vien_co_the_duyet_hoac_tu_choi_ca` | khác |
| `lib/features/admin/views/admin_pending_jobs_page.dart:68` | Đang tải danh sách tin chờ duyệt... | `admin_dang_tai_danh_sach_tin_cho_duyet` | khác |
| `lib/features/admin/views/admin_pending_jobs_page.dart:84` | Không thể tải danh sách tin chờ duyệt. | `admin_khong_the_tai_danh_sach_tin_cho_duyet` | khác |
| `lib/features/admin/views/admin_pending_jobs_page.dart:94` | Tải lại | `admin_tai_lai` | label |
| `lib/features/admin/views/admin_pending_jobs_page.dart:99` | Không có tin tuyển dụng nào đang chờ duyệt. | `admin_khong_co_tin_tuyen_dung_nao_dang_cho_duyet` | khác |
| `lib/features/admin/views/admin_pending_jobs_page.dart:137` | Tin tuyển dụng chưa có tiêu đề | `admin_tin_tuyen_dung_chua_co_tieu_de` | khác |
| `lib/features/admin/views/admin_pending_jobs_page.dart:138` | Chưa rõ công ty | `admin_chua_ro_cong_ty` | khác |
| `lib/features/admin/views/admin_pending_jobs_page.dart:140` | Chưa cập nhật địa điểm | `admin_chua_cap_nhat_dia_diem` | khác |
| `lib/features/admin/views/admin_pending_jobs_page.dart:161` | Trạng thái:  | `admin_trang_thai` | text hiển thị |
| `lib/features/admin/views/admin_pending_jobs_page.dart:163` | Đang xử lý... | `admin_dang_xu_ly` | khác |
| `lib/features/admin/views/admin_pending_jobs_page.dart:163` | Chờ duyệt | `admin_cho_duyet` | khác |
| `lib/features/admin/views/admin_pending_jobs_page.dart:171` | Chưa có mô tả công việc. | `admin_chua_co_mo_ta_cong_viec` | khác |
| `lib/features/admin/views/admin_pending_jobs_page.dart:191` | Từ chối | `c_utils_tu_choi` | text hiển thị |
| `lib/features/admin/views/admin_system_configuration_page.dart:106` | Quản trị hệ thống | `admin_quan_tri_he_thong` | khác |
| `lib/features/admin/views/admin_system_configuration_page.dart:107` | Cấu hình hệ thống | `admin_cau_hinh_he_thong` | title |
| `lib/features/admin/views/admin_system_configuration_page.dart:108` | Quản lý các quy tắc dùng chung của hệ thống JobHub. | `admin_quan_ly_cac_quy_tac_dung_chung_cua_he_thon` | title |
| `lib/features/admin/views/admin_system_configuration_page.dart:112` | Lỗi hệ thống | `admin_loi_he_thong` | title |
| `lib/features/admin/views/admin_system_configuration_page.dart:121` | Đang tải cấu hình hệ thống... | `admin_dang_tai_cau_hinh_he_thong` | khác |
| `lib/features/admin/views/admin_system_configuration_page.dart:128` | Lỗi hệ thống | `admin_loi_he_thong` | title |
| `lib/features/admin/views/admin_system_configuration_page.dart:130` | Không thể xử lý cấu hình hệ thống. | `admin_khong_the_xu_ly_cau_hinh_he_thong` | khác |
| `lib/features/admin/views/admin_system_configuration_page.dart:183` | Số kỹ năng tối đa trong một tin | `admin_so_ky_nang_toi_da_trong_mot_tin` | label |
| `lib/features/admin/views/admin_system_configuration_page.dart:184` | Giới hạn số kỹ năng Employer được chọn khi tạo tin tuyển dụng. | `admin_gioi_han_so_ky_nang_employer_duoc_chon_khi` | khác |
| `lib/features/admin/views/admin_system_configuration_page.dart:185` | kỹ năng | `admin_ky_nang` | khác |
| `lib/features/admin/views/admin_system_configuration_page.dart:191` | Hạn tuyển dụng mặc định | `admin_han_tuyen_dung_mac_dinh` | label |
| `lib/features/admin/views/admin_system_configuration_page.dart:192` | Số ngày mặc định trước khi một tin tuyển dụng hết hạn. | `admin_so_ngay_mac_dinh_truoc_khi_mot_tin_tuyen_d` | khác |
| `lib/features/admin/views/admin_system_configuration_page.dart:203` | Bắt buộc Admin duyệt tin | `admin_bat_buoc_admin_duyet_tin` | label |
| `lib/features/admin/views/admin_system_configuration_page.dart:204` | Khi bật, tin mới phải được Admin duyệt trước khi hiển thị. | `admin_khi_bat_tin_moi_phai_duoc_admin_duyet_truo` | khác |
| `lib/features/admin/views/admin_system_configuration_page.dart:223` | Trạng thái:  | `admin_trang_thai` | text hiển thị |
| `lib/features/admin/views/admin_system_configuration_page.dart:225` | Đang bật | `admin_dang_bat` | khác |
| `lib/features/admin/views/admin_system_configuration_page.dart:225` | Đang tắt | `admin_dang_tat` | khác |
| `lib/features/admin/views/admin_system_configuration_page.dart:242` | Đang lưu... | `admin_dang_luu` | text hiển thị |
| `lib/features/admin/views/admin_system_configuration_page.dart:242` | Lưu cấu hình | `admin_luu_cau_hinh` | text hiển thị |
| `lib/features/admin/views/admin_system_configuration_page.dart:335` | Thiếu khoá cấu hình mặc định | `admin_thieu_khoa_cau_hinh_mac_dinh` | khác |
| `lib/features/admin/views/admin_system_configuration_page.dart:340` | Tạo các khoá MAX_SKILLS_PER_JOB, DEFAULT_DEADLINE_DAYS, REQUIRE_JOB… | `admin_tao_cac_khoa_max_skills_per_job_default_de` | khác |
| `lib/features/admin/views/admin_system_configuration_page.dart:350` | Đang khởi tạo... | `admin_dang_khoi_tao` | label |
| `lib/features/admin/views/admin_system_configuration_page.dart:350` | Khởi tạo cấu hình mặc định | `admin_khoi_tao_cau_hinh_mac_dinh` | label |
| `lib/features/admin/views/admin_users_page.dart:25` | Ứng viên | `admin_ung_vien` | khác |
| `lib/features/admin/views/admin_users_page.dart:26` | Nhà tuyển dụng | `admin_nha_tuyen_dung` | khác |
| `lib/features/admin/views/admin_users_page.dart:39` | kích hoạt | `admin_kich_hoat` | khác |
| `lib/features/admin/views/admin_users_page.dart:42` | Bạn có chắc muốn $label tài khoản này? | `admin_ban_co_chac_muon_label_tai_khoan_nay` | validation/lỗi |
| `lib/features/admin/views/admin_users_page.dart:43` | Kích hoạt | `admin_kich_hoat_2` | khác |
| `lib/features/admin/views/admin_users_page.dart:52` | Không thể $label tài khoản. | `admin_khong_the_label_tai_khoan` | khác |
| `lib/features/admin/views/admin_users_page.dart:74` | Quản lý người dùng | `admin_quan_ly_nguoi_dung` | title |
| `lib/features/admin/views/admin_users_page.dart:76` | Theo dõi và khóa hoặc kích hoạt tài khoản. Việc xác minh nhà tuyển … | `admin_theo_doi_va_khoa_hoac_kich_hoat_tai_khoan` | khác |
| `lib/features/admin/views/admin_users_page.dart:80` | Loại tài khoản | `admin_loai_tai_khoan` | label |
| `lib/features/admin/views/admin_users_page.dart:103` | Tìm theo tên hoặc email | `admin_tim_theo_ten_hoac_email` | form hint/label |
| `lib/features/admin/views/admin_users_page.dart:119` | Tìm kiếm | `admin_tim_kiem` | button |
| `lib/features/admin/views/admin_users_page.dart:140` | tài khoản | `admin_tai_khoan` | khác |
| `lib/features/admin/views/admin_users_page.dart:229` | Đang tải danh sách... | `admin_dang_tai_danh_sach` | text hiển thị |
| `lib/features/admin/views/admin_users_page.dart:234` | Không tìm thấy tài khoản phù hợp. | `admin_khong_tim_thay_tai_khoan_phu_hop` | text hiển thị |
| `lib/features/admin/views/admin_users_page.dart:259` | Tài khoản | `admin_tai_khoan_2` | text hiển thị |
| `lib/features/admin/views/admin_users_page.dart:260` | Liên hệ | `admin_lien_he` | text hiển thị |
| `lib/features/admin/views/admin_users_page.dart:261` | Trạng thái | `admin_trang_thai_2` | text hiển thị |
| `lib/features/admin/views/admin_users_page.dart:264` | Thao tác | `admin_thao_tac` | text hiển thị |
| `lib/features/admin/views/admin_users_page.dart:354` | Chưa cập nhật tên | `admin_chua_cap_nhat_ten` | text hiển thị |
| `lib/features/admin/views/admin_users_page.dart:379` | Chưa cập nhật địa điểm | `admin_chua_cap_nhat_dia_diem` | khác |
| `lib/features/admin/views/admin_users_page.dart:392` | Đang hoạt động | `admin_dang_hoat_dong` | khác |
| `lib/features/admin/views/admin_users_page.dart:392` | Đã khóa | `admin_da_khoa` | khác |
| `lib/features/admin/views/admin_users_page.dart:411` | Đang xử lý... | `admin_dang_xu_ly` | khác |
| `lib/features/admin/views/admin_users_page.dart:411` | Khóa tài khoản | `admin_khoa_tai_khoan` | khác |
| `lib/features/admin/views/admin_users_page.dart:411` | Kích hoạt | `admin_kich_hoat_2` | khác |
| `lib/features/admin/views/ai_logs_page.dart:54` | Trang chủ | `admin_trang_chu` | enum/option |
| `lib/features/admin/views/ai_logs_page.dart:62` | Nhật ký gọi Gemini AI — ghi prompt, response, thời gian xử lý để th… | `admin_nhat_ky_goi_gemini_ai_ghi_prompt_response` | khác |
| `lib/features/admin/views/ai_logs_page.dart:68` | Tổng lượt gọi | `admin_tong_luot_goi` | label |
| `lib/features/admin/views/ai_logs_page.dart:70` | Thành công | `admin_thanh_cong` | label |
| `lib/features/admin/views/ai_logs_page.dart:75` | TB thời gian | `admin_tb_thoi_gian` | label |
| `lib/features/admin/views/ai_logs_page.dart:76` | Tổng tokens | `admin_tong_tokens` | label |
| `lib/features/admin/views/ai_logs_page.dart:85` | Lọc theo task: | `admin_loc_theo_task` | text hiển thị |
| `lib/features/admin/views/ai_logs_page.dart:88` | Tất cả | `c_config_tat_ca` | label |
| `lib/features/admin/views/ai_logs_page.dart:104` | Đang tải logs... | `admin_dang_tai_logs` | text hiển thị |
| `lib/features/admin/views/ai_logs_page.dart:122` | Không tải được logs | `admin_khong_tai_duoc_logs` | text hiển thị |
| `lib/features/admin/views/ai_logs_page.dart:135` | Đảm bảo tài khoản admin có quyền đọc bộ sưu tập aiMatchingLogs trên… | `admin_dam_bao_tai_khoan_admin_co_quyen_doc_bo_su` | khác |
| `lib/features/admin/views/ai_logs_page.dart:143` | Thử lại | `admin_thu_lai` | label |
| `lib/features/admin/views/ai_logs_page.dart:203` | Chưa có log nào | `admin_chua_co_log_nao` | text hiển thị |
| `lib/features/admin/views/ai_logs_page.dart:212` | Hãy dùng tính năng  | `admin_hay_dung_tinh_nang` | text hiển thị |
| `lib/features/admin/views/ai_logs_page.dart:214` |  trên trang  | `admin_tren_trang` | text hiển thị |
| `lib/features/admin/views/ai_logs_page.dart:216` | Việc làm | `admin_viec_lam` | khác |
| `lib/features/admin/views/ai_logs_page.dart:221` |  để tạo log. | `admin_de_tao_log` | text hiển thị |
| `lib/features/admin/views/ai_stats_page.dart:45` | Trang chủ | `admin_trang_chu` | enum/option |
| `lib/features/admin/views/ai_stats_page.dart:51` | Thống kê AI Logs | `admin_thong_ke_ai_logs` | title |
| `lib/features/admin/views/ai_stats_page.dart:53` | Phân tích hiệu năng Gemini AI — tổng quan, xu hướng, tối ưu prompt. | `admin_phan_tich_hieu_nang_gemini_ai_tong_quan_xu` | title |
| `lib/features/admin/views/ai_stats_page.dart:57` | Xem logs chi tiết | `admin_xem_logs_chi_tiet` | label |
| `lib/features/admin/views/ai_stats_page.dart:77` | Đang tải... | `admin_dang_tai` | text hiển thị |
| `lib/features/admin/views/ai_stats_page.dart:89` | Không tải được logs | `admin_khong_tai_duoc_logs` | text hiển thị |
| `lib/features/admin/views/ai_stats_page.dart:99` | Thử lại | `admin_thu_lai` | label |
| `lib/features/admin/views/ai_stats_page.dart:113` | Chưa có dữ liệu | `admin_chua_co_du_lieu` | text hiển thị |
| `lib/features/admin/views/ai_stats_page.dart:117` | Hãy dùng AI Matching để tạo logs trước. | `admin_hay_dung_ai_matching_de_tao_logs_truoc` | text hiển thị |
| `lib/features/admin/views/ai_stats_page.dart:128` | Tổng lượt gọi | `admin_tong_luot_goi` | label |
| `lib/features/admin/views/ai_stats_page.dart:184` | Phân tích theo task | `admin_phan_tich_theo_task` | title |
| `lib/features/admin/views/ai_stats_page.dart:192` | Lượt gọi 7 ngày gần nhất | `admin_luot_goi_7_ngay_gan_nhat` | title |
| `lib/features/admin/views/ai_stats_page.dart:196` | Top 5 chậm nhất (cần tối ưu prompt) | `admin_top_5_cham_nhat_can_toi_uu_prompt` | title |
| `lib/features/admin/views/catalog_management_page.dart:20` | Không thể tải danh mục ngành nghề và kỹ năng. | `admin_khong_the_tai_danh_muc_nganh_nghe_va_ky_na` | validation/lỗi |
| `lib/features/admin/views/catalog_management_page.dart:32` | Ngành nghề | `admin_nganh_nghe` | title |
| `lib/features/admin/views/catalog_management_page.dart:33` | ${categories.valueOrNull?.length ?? 0} ngành | `admin_categories_valueornull_length_0_nganh` | khác |
| `lib/features/admin/views/catalog_management_page.dart:34` | Nhập ngành nghề mới | `admin_nhap_nganh_nghe_moi` | khác |
| `lib/features/admin/views/catalog_management_page.dart:40` | Đang tải ngành nghề... | `admin_dang_tai_nganh_nghe` | khác |
| `lib/features/admin/views/catalog_management_page.dart:41` | Chưa có ngành nghề nào. | `admin_chua_co_nganh_nghe_nao` | khác |
| `lib/features/admin/views/catalog_management_page.dart:48` | Bạn có chắc muốn xoá ngành nghề "${it.name}" không? | `admin_ban_co_chac_muon_xoa_nganh_nghe_it_name_kh` | validation/lỗi |
| `lib/features/admin/views/catalog_management_page.dart:57` | Kỹ năng | `admin_ky_nang_2` | title |
| `lib/features/admin/views/catalog_management_page.dart:58` | ${skills.valueOrNull?.length ?? 0} kỹ năng | `admin_skills_valueornull_length_0_ky_nang` | khác |
| `lib/features/admin/views/catalog_management_page.dart:59` | Nhập kỹ năng mới | `admin_nhap_ky_nang_moi` | khác |
| `lib/features/admin/views/catalog_management_page.dart:65` | Đang tải kỹ năng... | `admin_dang_tai_ky_nang` | khác |
| `lib/features/admin/views/catalog_management_page.dart:66` | Chưa có kỹ năng nào. | `admin_chua_co_ky_nang_nao` | khác |
| `lib/features/admin/views/catalog_management_page.dart:73` | Bạn có chắc muốn xoá kỹ năng "${it.name}" không? | `admin_ban_co_chac_muon_xoa_ky_nang_it_name_khong` | validation/lỗi |
| `lib/features/admin/views/catalog_management_page.dart:86` | Quản lý danh mục | `admin_quan_ly_danh_muc` | khác |
| `lib/features/admin/views/catalog_management_page.dart:87` | Quản lý ngành nghề và kỹ năng | `admin_quan_ly_nganh_nghe_va_ky_nang` | title |
| `lib/features/admin/views/catalog_management_page.dart:89` | Quản trị viên có thể thêm hoặc xoá ngành nghề, kỹ năng dùng trong t… | `admin_quan_tri_vien_co_the_them_hoac_xoa_nganh_n` | khác |
| `lib/features/admin/views/catalog_management_page.dart:94` | Lỗi hệ thống | `admin_loi_he_thong` | title |
| `lib/features/admin/widgets/ai_log_tile.dart:160` | Lỗi: ${log.error} | `admin_loi_log_error` | text hiển thị |
| `lib/features/admin/widgets/ai_log_tile.dart:169` | Đã sao chép prompt | `admin_da_sao_chep_prompt` | khác |
| `lib/features/admin/widgets/ai_log_tile.dart:177` | Đã sao chép response | `admin_da_sao_chep_response` | khác |
| `lib/features/admin/widgets/ai_log_tile.dart:249` | Sao chép | `admin_sao_chep` | label |
| `lib/features/admin/widgets/ai_stats_cards.dart:63` | ${byTask[i].count} lượt · ${byTask[i].avgTimeMs}ms · ${Formatters.n… | `admin_bytask_i_count_luot_bytask_i_avgtimems_ms` | khác |
| `lib/features/admin/widgets/ai_stats_cards.dart:135` | Chưa có dữ liệu. | `admin_chua_co_du_lieu_2` | text hiển thị |
| `lib/features/admin/widgets/calls_per_day_chart.dart:75` | ${d.isoDate}: ${d.count} lượt | `admin_d_isodate_d_count_luot` | khác |
| `lib/features/admin/widgets/catalog_card.dart:106` | Đang thêm... | `admin_dang_them` | text hiển thị |
| `lib/features/admin/widgets/catalog_card.dart:157` | Đang xoá... | `admin_dang_xoa` | text hiển thị |
| `lib/features/admin/widgets/gemini_key_panel.dart:54` | (chưa set) | `admin_chua_set` | enum/option |
| `lib/features/admin/widgets/gemini_key_panel.dart:63` | Đang kiểm tra... | `admin_dang_kiem_tra` | text hiển thị |
| `lib/features/admin/widgets/gemini_key_panel.dart:63` | Kiểm tra | `admin_kiem_tra` | text hiển thị |
| `lib/features/admin/widgets/gemini_key_panel.dart:68` | Đang lưu... | `admin_dang_luu` | text hiển thị |
| `lib/features/admin/widgets/gemini_key_panel.dart:68` | Lưu & dùng | `admin_luu_dung` | text hiển thị |
| `lib/features/admin/widgets/gemini_key_panel.dart:74` | Dùng .env | `admin_dung_env` | text hiển thị |
| `lib/features/admin/widgets/gemini_key_panel.dart:74` | Xoá key | `admin_xoa_key` | text hiển thị |
| `lib/features/admin/widgets/gemini_key_panel.dart:85` | Dán Gemini API key mới (AIza...) | `admin_dan_gemini_api_key_moi_aiza` | form hint/label |
| `lib/features/admin/widgets/gemini_key_panel.dart:133` | Đổi key khi hết hạn — áp dụng ngay, không cần sửa code hay restart … | `admin_doi_key_khi_het_han_ap_dung_ngay_khong_can` | khác |
| `lib/features/admin/widgets/gemini_key_panel.dart:155` | Key hiện tại:  | `admin_key_hien_tai` | text hiển thị |
| `lib/features/admin/widgets/gemini_key_panel.dart:166` |   · cập nhật ${Formatters.localeDateTime(widget.stored!.updatedAt!)} | `admin_cap_nhat_formatters_localedatetime_widget` | khác |
| `lib/features/admin/widgets/gemini_key_panel.dart:192` | Key hợp lệ ✓ (${state.keyTestResult!.latencyMs}ms) | `admin_key_hop_le_state_keytestresult_latencyms_m` | khác |
| `lib/features/admin/widgets/gemini_key_panel.dart:193` | Key KHÔNG hợp lệ — ${state.keyTestResult!.error ??  | `admin_key_khong_hop_le_state_keytestresult_error` | validation/lỗi |
| `lib/features/admin/widgets/gemini_key_panel.dart:223` | Xoá override, dùng lại key trong .env? | `admin_xoa_override_dung_lai_key_trong_env` | khác |
| `lib/features/admin/widgets/gemini_key_panel.dart:224` | Xoá Gemini API key đã lưu? Các tính năng AI sẽ ngừng hoạt động cho … | `admin_xoa_gemini_api_key_da_luu_cac_tinh_nang_ai` | khác |
| `lib/features/admin/widgets/gemini_key_panel.dart:241` | Từ .env | `admin_tu_env` | enum/option |
| `lib/features/admin/widgets/gemini_key_panel.dart:242` | Chưa set | `admin_chua_set_2` | enum/option |

### `features/applications` (134)

| Vị trí | Chuỗi | Key đề xuất | Ngữ cảnh |
|---|---|---|---|
| `lib/features/applications/data/applications_repository.dart:52` | họ tên | `applications_ho_ten` | khác |
| `lib/features/applications/data/applications_repository.dart:53` | chức danh | `applications_chuc_danh` | khác |
| `lib/features/applications/data/applications_repository.dart:54` | thành phố | `applications_thanh_pho` | khác |
| `lib/features/applications/data/applications_repository.dart:64` | Không tìm thấy hồ sơ ứng tuyển. | `applications_khong_tim_thay_ho_so_ung_tuyen` | khác |
| `lib/features/applications/data/applications_repository.dart:65` | Không tìm thấy công việc. | `applications_khong_tim_thay_cong_viec` | khác |
| `lib/features/applications/data/applications_repository.dart:130` | Không tìm thấy hồ sơ ứng viên. | `applications_khong_tim_thay_ho_so_ung_vien` | validation/lỗi |
| `lib/features/applications/data/applications_repository.dart:220` | Chỉ tài khoản ứng viên mới có thể ứng tuyển. | `applications_chi_tai_khoan_ung_vien_moi_co_the_ung_tuye` | validation/lỗi |
| `lib/features/applications/data/applications_repository.dart:223` | Tài khoản đã bị vô hiệu hóa. | `app_tai_khoan_da_bi_vo_hieu_hoa` | validation/lỗi |
| `lib/features/applications/data/applications_repository.dart:228` | Hồ sơ chưa đầy đủ: ${missing.join( | `applications_ho_so_chua_day_du_missing_join` | validation/lỗi |
| `lib/features/applications/data/applications_repository.dart:232` | Thư giới thiệu tối đa 5000 ký tự. | `applications_thu_gioi_thieu_toi_da_5000_ky_tu` | validation/lỗi |
| `lib/features/applications/data/applications_repository.dart:255` | Công việc không còn nhận hồ sơ. | `applications_cong_viec_khong_con_nhan_ho_so` | validation/lỗi |
| `lib/features/applications/data/applications_repository.dart:258` | Công việc đã hết hạn ứng tuyển. | `applications_cong_viec_da_het_han_ung_tuyen` | validation/lỗi |
| `lib/features/applications/data/applications_repository.dart:262` | Bạn đã ứng tuyển công việc này. | `applications_ban_da_ung_tuyen_cong_viec_nay` | validation/lỗi |
| `lib/features/applications/data/applications_repository.dart:311` | Có ứng viên mới | `applications_co_ung_vien_moi` | title |
| `lib/features/applications/data/applications_repository.dart:312` | $candidateName đã ứng tuyển "${freshJob.jobTitle}". | `applications_candidatename_da_ung_tuyen_freshjob_jobtit` | validation/lỗi |
| `lib/features/applications/data/applications_repository.dart:338` | Bạn không có quyền cập nhật hồ sơ này. | `applications_ban_khong_co_quyen_cap_nhat_ho_so_nay` | validation/lỗi |
| `lib/features/applications/data/applications_repository.dart:351` | Bạn không có quyền cập nhật hồ sơ này. | `applications_ban_khong_co_quyen_cap_nhat_ho_so_nay` | validation/lỗi |
| `lib/features/applications/data/applications_repository.dart:355` | Hồ sơ đã được cập nhật. Vui lòng tải lại. | `applications_ho_so_da_duoc_cap_nhat_vui_long_tai_lai` | khác |
| `lib/features/applications/data/applications_repository.dart:359` | Chuyển trạng thái không hợp lệ. | `applications_chuyen_trang_thai_khong_hop_le` | validation/lỗi |
| `lib/features/applications/data/applications_repository.dart:387` | Hồ sơ ứng tuyển được cập nhật | `applications_ho_so_ung_tuyen_duoc_cap_nhat` | title |
| `lib/features/applications/data/applications_repository.dart:389` | Hồ sơ ứng tuyển "${app.jobTitle}" đã chuyển sang trạng thái ${newSt… | `applications_ho_so_ung_tuyen_app_jobtitle_da_chuyen_san` | khác |
| `lib/features/applications/viewmodels/applications_providers.dart:19` | Mới nhất | `applications_moi_nhat` | enum/option |
| `lib/features/applications/viewmodels/applications_providers.dart:20` | Cũ nhất | `applications_cu_nhat` | enum/option |
| `lib/features/applications/viewmodels/apply_viewmodel.dart:35` | Vui lòng đăng nhập để ứng tuyển. | `applications_vui_long_dang_nhap_de_ung_tuyen` | khác |
| `lib/features/applications/viewmodels/apply_viewmodel.dart:36` | Chỉ tài khoản ứng viên mới có thể ứng tuyển. | `applications_chi_tai_khoan_ung_vien_moi_co_the_ung_tuye` | khác |
| `lib/features/applications/viewmodels/apply_viewmodel.dart:37` | Bạn chưa có CV chính. Hãy tải CV trong hồ sơ cá nhân. | `applications_ban_chua_co_cv_chinh_hay_tai_cv_trong_ho_s` | khác |
| `lib/features/applications/viewmodels/apply_viewmodel.dart:38` | Bạn đã ứng tuyển công việc này. | `applications_ban_da_ung_tuyen_cong_viec_nay` | khác |
| `lib/features/applications/viewmodels/apply_viewmodel.dart:154` | Tài khoản đã bị vô hiệu hóa. | `app_tai_khoan_da_bi_vo_hieu_hoa` | validation/lỗi |
| `lib/features/applications/viewmodels/review_viewmodel.dart:99` | Ứng viên | `admin_ung_vien` | khác |
| `lib/features/applications/viewmodels/review_viewmodel.dart:127` | Nhà tuyển dụng | `admin_nha_tuyen_dung` | khác |
| `lib/features/applications/views/application_detail_page.dart:62` | Đang tải... | `admin_dang_tai` | text hiển thị |
| `lib/features/applications/views/application_detail_page.dart:84` | ← Hồ sơ đã ứng tuyển | `applications_ho_so_da_ung_tuyen` | label |
| `lib/features/applications/views/application_detail_page.dart:93` | ← Hồ sơ đã ứng tuyển | `applications_ho_so_da_ung_tuyen` | label |
| `lib/features/applications/views/application_detail_page.dart:106` | Lịch sử trạng thái | `applications_lich_su_trang_thai` | khác |
| `lib/features/applications/views/application_detail_page.dart:132` | Không còn khả dụng | `applications_khong_con_kha_dung` | khác |
| `lib/features/applications/views/application_detail_page.dart:167` | Ngày ứng tuyển | `applications_ngay_ung_tuyen` | khác |
| `lib/features/applications/views/application_detail_page.dart:168` | CV đã dùng | `applications_cv_da_dung` | khác |
| `lib/features/applications/views/application_detail_page.dart:171` | Thư giới thiệu | `c_utils_thu_gioi_thieu` | khác |
| `lib/features/applications/views/application_detail_page.dart:174` | Không có thư giới thiệu. | `applications_khong_co_thu_gioi_thieu` | khác |
| `lib/features/applications/views/application_detail_page.dart:185` | Xem tin tuyển dụng | `applications_xem_tin_tuyen_dung` | label |
| `lib/features/applications/views/application_detail_page.dart:193` | Nhắn tin cho nhà tuyển dụng | `applications_nhan_tin_cho_nha_tuyen_dung` | label |
| `lib/features/applications/views/apply_job_page.dart:32` | Chọn CV | `applications_chon_cv` | khác |
| `lib/features/applications/views/apply_job_page.dart:32` | Thư giới thiệu | `c_utils_thu_gioi_thieu` | khác |
| `lib/features/applications/views/apply_job_page.dart:32` | Xác nhận | `applications_xac_nhan` | khác |
| `lib/features/applications/views/apply_job_page.dart:66` | ← Quay lại tin tuyển dụng | `applications_quay_lai_tin_tuyen_dung` | label |
| `lib/features/applications/views/apply_job_page.dart:89` | Theo dõi hồ sơ ứng tuyển | `applications_theo_doi_ho_so_ung_tuyen` | text hiển thị |
| `lib/features/applications/views/apply_job_page.dart:93` | Khám phá việc làm | `applications_kham_pha_viec_lam` | text hiển thị |
| `lib/features/applications/views/apply_job_page.dart:103` | Đang kiểm tra hồ sơ và CV... | `applications_dang_kiem_tra_ho_so_va_cv` | label |
| `lib/features/applications/views/apply_job_page.dart:113` | Thử lại | `admin_thu_lai` | button |
| `lib/features/applications/views/apply_job_page.dart:144` | Tiếp tục | `applications_tiep_tuc` | khác |
| `lib/features/applications/views/apply_job_page.dart:146` | Đang gửi... | `applications_dang_gui` | khác |
| `lib/features/applications/views/apply_job_page.dart:147` | Xác nhận ứng tuyển | `applications_xac_nhan_ung_tuyen` | khác |
| `lib/features/applications/views/apply_job_page.dart:153` | Quay lại | `applications_quay_lai` | text hiển thị |
| `lib/features/applications/views/apply_job_page.dart:163` | Chọn CV sẽ gửi cho nhà tuyển dụng | `applications_chon_cv_se_gui_cho_nha_tuyen_dung` | khác |
| `lib/features/applications/views/apply_job_page.dart:176` | Không bắt buộc | `applications_khong_bat_buoc` | khác |
| `lib/features/applications/views/apply_job_page.dart:177` | ${state.coverLetter.length}/${ApplyState.coverLetterMax} ký tự | `applications_state_coverletter_length_applystate_coverl` | khác |
| `lib/features/applications/views/apply_job_page.dart:189` | Kiểm tra lại thông tin trước khi gửi | `applications_kiem_tra_lai_thong_tin_truoc_khi_gui` | title |
| `lib/features/applications/views/apply_job_page.dart:216` | Ứng tuyển | `applications_ung_tuyen` | title |
| `lib/features/applications/views/apply_job_page.dart:216` | Ứng tuyển công việc | `applications_ung_tuyen_cong_viec` | title |
| `lib/features/applications/views/apply_job_page.dart:219` | Đang tải tin tuyển dụng... | `applications_dang_tai_tin_tuyen_dung` | text hiển thị |
| `lib/features/applications/views/apply_job_page.dart:222` | Không tìm thấy công việc. | `applications_khong_tim_thay_cong_viec` | validation/lỗi |
| `lib/features/applications/views/apply_job_page.dart:244` | Hạn nộp: ${Formatters.deadlineFull(j.applicationDeadline)} | `applications_han_nop_formatters_deadlinefull_j_applicat` | khác |
| `lib/features/applications/views/apply_job_page.dart:274` | CV sẽ được gửi | `applications_cv_se_duoc_gui` | label |
| `lib/features/applications/views/apply_job_page.dart:277` | CV sẽ được gửi | `applications_cv_se_duoc_gui` | label |
| `lib/features/applications/views/apply_job_page.dart:324` | CV chính | `applications_cv_chinh` | text hiển thị |
| `lib/features/applications/views/apply_job_page.dart:334` | Tải lên ${Formatters.date(resume.uploadDate)} | `applications_tai_len_formatters_date_resume_uploaddate` | khác |
| `lib/features/applications/views/apply_job_page.dart:335` | Đã phân tích AI | `applications_da_phan_tich_ai` | khác |
| `lib/features/applications/views/apply_job_page.dart:358` | Vị trí ứng tuyển | `applications_vi_tri_ung_tuyen` | label |
| `lib/features/applications/views/apply_job_page.dart:369` | Thư giới thiệu | `c_utils_thu_gioi_thieu` | label |
| `lib/features/applications/views/apply_job_page.dart:371` | Không có thư giới thiệu. | `applications_khong_co_thu_gioi_thieu` | khác |
| `lib/features/applications/views/employer_application_review_page.dart:27` | Bạn không có quyền xem hồ sơ này. | `applications_ban_khong_co_quyen_xem_ho_so_nay` | khác |
| `lib/features/applications/views/employer_application_review_page.dart:63` | Đang tải... | `admin_dang_tai` | text hiển thị |
| `lib/features/applications/views/employer_application_review_page.dart:89` | ← Danh sách hồ sơ | `applications_danh_sach_ho_so` | label |
| `lib/features/applications/views/employer_application_review_page.dart:103` | ← Danh sách hồ sơ | `applications_danh_sach_ho_so` | label |
| `lib/features/applications/views/employer_application_review_page.dart:139` | Lịch sử trạng thái | `applications_lich_su_trang_thai` | khác |
| `lib/features/applications/views/employer_applications_page.dart:47` | Nộp từ ngày | `applications_nop_tu_ngay` | khác |
| `lib/features/applications/views/employer_applications_page.dart:47` | Nộp đến ngày | `applications_nop_den_ngay` | khác |
| `lib/features/applications/views/employer_applications_page.dart:72` | Nhà tuyển dụng | `admin_nha_tuyen_dung` | khác |
| `lib/features/applications/views/employer_applications_page.dart:73` | Hồ sơ ứng tuyển | `admin_ho_so_ung_tuyen` | title |
| `lib/features/applications/views/employer_applications_page.dart:74` | $total hồ sơ đã nhận | `applications_total_ho_so_da_nhan` | title |
| `lib/features/applications/views/employer_applications_page.dart:82` | Tên ứng viên | `applications_ten_ung_vien` | form hint/label |
| `lib/features/applications/views/employer_applications_page.dart:90` | Tất cả trạng thái | `admin_tat_ca_trang_thai` | khác |
| `lib/features/applications/views/employer_applications_page.dart:105` | Tất cả tin tuyển dụng | `applications_tat_ca_tin_tuyen_dung` | khác |
| `lib/features/applications/views/employer_applications_page.dart:112` | Nộp từ ngày | `applications_nop_tu_ngay` | label |
| `lib/features/applications/views/employer_applications_page.dart:118` | Nộp đến ngày | `applications_nop_den_ngay` | label |
| `lib/features/applications/views/employer_applications_page.dart:127` | Đang tải... | `admin_dang_tai` | enum/option |
| `lib/features/applications/views/employer_applications_page.dart:132` | Chưa nhận được hồ sơ ứng tuyển nào. | `applications_chua_nhan_duoc_ho_so_ung_tuyen_nao` | khác |
| `lib/features/applications/views/employer_applications_page.dart:140` | Xóa bộ lọc | `applications_xoa_bo_loc` | text hiển thị |
| `lib/features/applications/views/my_applications_page.dart:50` | Ứng viên | `admin_ung_vien` | khác |
| `lib/features/applications/views/my_applications_page.dart:51` | Hồ sơ đã ứng tuyển | `applications_ho_so_da_ung_tuyen_2` | title |
| `lib/features/applications/views/my_applications_page.dart:52` | $total hồ sơ | `applications_total_ho_so` | title |
| `lib/features/applications/views/my_applications_page.dart:60` | Tên công việc hoặc công ty | `applications_ten_cong_viec_hoac_cong_ty` | form hint/label |
| `lib/features/applications/views/my_applications_page.dart:68` | Tất cả trạng thái | `admin_tat_ca_trang_thai` | khác |
| `lib/features/applications/views/my_applications_page.dart:87` | Đang tải hồ sơ... | `applications_dang_tai_ho_so` | text hiển thị |
| `lib/features/applications/views/my_applications_page.dart:135` | Bạn chưa có hồ sơ phù hợp bộ lọc. | `applications_ban_chua_co_ho_so_phu_hop_bo_loc` | khác |
| `lib/features/applications/views/my_applications_page.dart:142` | Khám phá việc làm | `applications_kham_pha_viec_lam` | text hiển thị |
| `lib/features/applications/widgets/application_list_card.dart:25` | Không còn khả dụng | `applications_khong_con_kha_dung` | khác |
| `lib/features/applications/widgets/application_list_card.dart:56` | Tin tuyển dụng | `applications_tin_tuyen_dung` | khác |
| `lib/features/applications/widgets/application_list_card.dart:71` | Nộp ngày ${Formatters.date(a.applicationDate)} · CV: $cv | `applications_nop_ngay_formatters_date_a_applicationdate` | khác |
| `lib/features/applications/widgets/apply_context_sections.dart:56` | Hồ sơ ứng viên | `applications_ho_so_ung_vien` | label |
| `lib/features/applications/widgets/apply_context_sections.dart:61` | Chưa cập nhật họ tên | `applications_chua_cap_nhat_ho_ten` | khác |
| `lib/features/applications/widgets/apply_context_sections.dart:88` | CV sẽ được gửi | `applications_cv_se_duoc_gui` | label |
| `lib/features/applications/widgets/apply_context_sections.dart:133` | Tải CV ngay | `applications_tai_cv_ngay` | khác |
| `lib/features/applications/widgets/apply_context_sections.dart:159` | Hồ sơ còn thiếu: ${missing.join( | `applications_ho_so_con_thieu_missing_join` | text hiển thị |
| `lib/features/applications/widgets/apply_context_sections.dart:215` | Thư giới thiệu (không bắt buộc) | `applications_thu_gioi_thieu_khong_bat_buoc` | khác |
| `lib/features/applications/widgets/apply_context_sections.dart:250` | Ứng tuyển thành công. | `applications_ung_tuyen_thanh_cong` | khác |
| `lib/features/applications/widgets/apply_context_sections.dart:261` | Theo dõi hồ sơ ứng tuyển | `applications_theo_doi_ho_so_ung_tuyen` | khác |
| `lib/features/applications/widgets/apply_context_sections.dart:289` | Vui lòng  | `applications_vui_long` | text hiển thị |
| `lib/features/applications/widgets/apply_context_sections.dart:297` | đăng nhập | `applications_dang_nhap` | khác |
| `lib/features/applications/widgets/apply_context_sections.dart:301` |  để ứng tuyển. | `applications_de_ung_tuyen` | text hiển thị |
| `lib/features/applications/widgets/apply_modal.dart:65` | Đang gửi... | `applications_dang_gui` | khác |
| `lib/features/applications/widgets/apply_modal.dart:65` | Xác nhận ứng tuyển | `applications_xac_nhan_ung_tuyen` | khác |
| `lib/features/applications/widgets/apply_modal.dart:88` | Đang kiểm tra hồ sơ và CV... | `applications_dang_kiem_tra_ho_so_va_cv` | khác |
| `lib/features/applications/widgets/apply_modal.dart:108` | Thử lại | `admin_thu_lai` | button |
| `lib/features/applications/widgets/apply_modal.dart:164` | Ứng tuyển công việc | `applications_ung_tuyen_cong_viec` | khác |
| `lib/features/applications/widgets/employer_application_row.dart:33` | Ứng viên | `admin_ung_vien` | khác |
| `lib/features/applications/widgets/employer_application_row.dart:38` | Chưa có tiêu đề | `applications_chua_co_tieu_de` | khác |
| `lib/features/applications/widgets/review_cards.dart:48` | Ứng viên | `admin_ung_vien` | khác |
| `lib/features/applications/widgets/review_cards.dart:69` | Vị trí | `applications_vi_tri` | khác |
| `lib/features/applications/widgets/review_cards.dart:70` | Địa điểm | `applications_dia_diem` | khác |
| `lib/features/applications/widgets/review_cards.dart:70` | Chưa cập nhật | `c_utils_chua_cap_nhat` | khác |
| `lib/features/applications/widgets/review_cards.dart:87` | Không còn khả dụng | `applications_khong_con_kha_dung` | khác |
| `lib/features/applications/widgets/review_cards.dart:92` | Ngày nộp | `applications_ngay_nop` | khác |
| `lib/features/applications/widgets/review_cards.dart:99` | Đã sao chép email | `applications_da_sao_chep_email` | validation/lỗi |
| `lib/features/applications/widgets/review_cards.dart:108` | Thư giới thiệu | `c_utils_thu_gioi_thieu` | khác |
| `lib/features/applications/widgets/review_cards.dart:111` | Không có. | `applications_khong_co` | khác |
| `lib/features/applications/widgets/review_cards.dart:123` | Nhắn tin cho ứng viên | `applications_nhan_tin_cho_ung_vien` | label |
| `lib/features/applications/widgets/review_cards.dart:145` | Thông tin phù hợp | `applications_thong_tin_phu_hop` | khác |
| `lib/features/applications/widgets/review_cards.dart:148` | Đang tải... | `admin_dang_tai` | text hiển thị |
| `lib/features/applications/widgets/review_cards.dart:164` | Thông tin phù hợp hiện chưa có. | `applications_thong_tin_phu_hop_hien_chua_co` | khác |
| `lib/features/applications/widgets/review_cards.dart:222` | Cập nhật trạng thái | `applications_cap_nhat_trang_thai` | khác |
| `lib/features/applications/widgets/review_cards.dart:226` | Trạng thái này là trạng thái cuối. | `applications_trang_thai_nay_la_trang_thai_cuoi` | khác |
| `lib/features/applications/widgets/review_cards.dart:234` | Chọn trạng thái | `applications_chon_trang_thai` | khác |
| `lib/features/applications/widgets/review_cards.dart:244` | Cập nhật | `applications_cap_nhat` | text hiển thị |

### `features/auth` (89)

| Vị trí | Chuỗi | Key đề xuất | Ngữ cảnh |
|---|---|---|---|
| `lib/features/auth/data/auth_repository.dart:260` | Tài khoản không còn tồn tại. | `app_tai_khoan_khong_con_ton_tai` | validation/lỗi |
| `lib/features/auth/data/auth_repository.dart:265` | Tài khoản đã bị vô hiệu hóa. | `app_tai_khoan_da_bi_vo_hieu_hoa` | khác |
| `lib/features/auth/viewmodels/forgot_password_viewmodel.dart:46` | Không thể gửi email đặt lại mật khẩu. Vui lòng kiểm tra lại địa chỉ… | `auth_khong_the_gui_email_dat_lai_mat_khau_vui_l` | khác |
| `lib/features/auth/views/forgot_password_page.dart:46` | Quên mật khẩu? | `auth_quen_mat_khau` | title |
| `lib/features/auth/views/forgot_password_page.dart:47` | Nhập email đã đăng ký, chúng tôi sẽ gửi liên kết đặt lại mật khẩu c… | `auth_nhap_email_da_dang_ky_chung_toi_se_gui_lie` | title |
| `lib/features/auth/views/forgot_password_page.dart:49` | Nhớ mật khẩu rồi? | `auth_nho_mat_khau_roi` | khác |
| `lib/features/auth/views/forgot_password_page.dart:50` | Đăng nhập | `auth_dang_nhap` | khác |
| `lib/features/auth/views/forgot_password_page.dart:90` | Gửi email đặt lại mật khẩu | `auth_gui_email_dat_lai_mat_khau` | label |
| `lib/features/auth/views/forgot_password_page.dart:91` | Đang gửi... | `applications_dang_gui` | khác |
| `lib/features/auth/views/forgot_password_page.dart:98` | Liên kết đặt lại mật khẩu có hiệu lực trong thời gian ngắn.  | `auth_lien_ket_dat_lai_mat_khau_co_hieu_luc_tron` | khác |
| `lib/features/auth/views/forgot_password_page.dart:99` | Nếu không thấy email, hãy kiểm tra mục Spam. | `auth_neu_khong_thay_email_hay_kiem_tra_muc_spam` | khác |
| `lib/features/auth/views/forgot_password_page.dart:148` | Đã gửi email đặt lại mật khẩu | `auth_da_gui_email_dat_lai_mat_khau` | khác |
| `lib/features/auth/views/forgot_password_page.dart:159` | Đã gửi email đặt lại mật khẩu đến  | `auth_da_gui_email_dat_lai_mat_khau_den` | khác |
| `lib/features/auth/views/forgot_password_page.dart:166` | . Vui lòng kiểm tra hộp thư (kể cả mục Spam) và làm theo hướng dẫn … | `auth_vui_long_kiem_tra_hop_thu_ke_ca_muc_spam_v` | khác |
| `lib/features/auth/views/forgot_password_page.dart:182` | Quay lại đăng nhập | `auth_quay_lai_dang_nhap` | label |
| `lib/features/auth/views/forgot_password_page.dart:188` | Chưa nhận được email? Gửi lại | `auth_chua_nhan_duoc_email_gui_lai` | text hiển thị |
| `lib/features/auth/views/login_page.dart:70` | Đăng nhập | `auth_dang_nhap` | title |
| `lib/features/auth/views/login_page.dart:71` | Chào mừng bạn quay lại JobHub. | `auth_chao_mung_ban_quay_lai_jobhub` | title |
| `lib/features/auth/views/login_page.dart:73` | Chưa có tài khoản? | `auth_chua_co_tai_khoan` | khác |
| `lib/features/auth/views/login_page.dart:74` | Đăng ký miễn phí | `auth_dang_ky_mien_phi` | khác |
| `lib/features/auth/views/login_page.dart:107` | Mật khẩu | `auth_mat_khau` | label |
| `lib/features/auth/views/login_page.dart:117` | Vui lòng nhập mật khẩu. | `auth_vui_long_nhap_mat_khau` | khác |
| `lib/features/auth/views/login_page.dart:132` | Ghi nhớ đăng nhập (giữ phiên 7 ngày, không bị out khi reload) | `auth_ghi_nho_dang_nhap_giu_phien_7_ngay_khong_b` | khác |
| `lib/features/auth/views/login_page.dart:141` | Quên mật khẩu? | `auth_quen_mat_khau` | khác |
| `lib/features/auth/views/login_page.dart:149` | Đăng nhập | `auth_dang_nhap` | label |
| `lib/features/auth/views/login_page.dart:150` | Đang đăng nhập... | `auth_dang_dang_nhap` | khác |
| `lib/features/auth/views/onboarding_page.dart:27` | Ứng viên | `admin_ung_vien` | khác |
| `lib/features/auth/views/onboarding_page.dart:28` | Tìm việc bằng AI | `auth_tim_viec_bang_ai` | title |
| `lib/features/auth/views/onboarding_page.dart:30` | Tải CV lên, JobHub đọc hiểu kỹ năng và kinh nghiệm thực tế của bạn … | `auth_tai_cv_len_jobhub_doc_hieu_ky_nang_va_kinh` | khác |
| `lib/features/auth/views/onboarding_page.dart:31` | mức độ phù hợp với từng tin tuyển dụng — thay vì chỉ tìm theo từ khoá. | `auth_muc_do_phu_hop_voi_tung_tin_tuyen_dung_tha` | khác |
| `lib/features/auth/views/onboarding_page.dart:36` | Theo dõi | `auth_theo_doi` | khác |
| `lib/features/auth/views/onboarding_page.dart:37` | Theo dõi hồ sơ realtime | `auth_theo_doi_ho_so_realtime` | title |
| `lib/features/auth/views/onboarding_page.dart:39` | Biết ngay khi nhà tuyển dụng xem hồ sơ, mời phỏng vấn hay gửi offer.  | `auth_biet_ngay_khi_nha_tuyen_dung_xem_ho_so_moi` | khác |
| `lib/features/auth/views/onboarding_page.dart:40` | Mọi thay đổi trạng thái được cập nhật tức thì kèm thông báo đẩy. | `auth_moi_thay_doi_trang_thai_duoc_cap_nhat_tuc` | khác |
| `lib/features/auth/views/onboarding_page.dart:45` | Nhà tuyển dụng | `admin_nha_tuyen_dung` | khác |
| `lib/features/auth/views/onboarding_page.dart:46` | Nhà tuyển dụng duyệt nhanh | `auth_nha_tuyen_dung_duyet_nhanh` | title |
| `lib/features/auth/views/onboarding_page.dart:48` | Đăng tin trong vài phút, nhận ứng viên đã được AI xếp hạng và duyệt… | `auth_dang_tin_trong_vai_phut_nhan_ung_vien_da_d` | khác |
| `lib/features/auth/views/onboarding_page.dart:49` | theo từng vòng — trao đổi trực tiếp với ứng viên tiềm năng. | `auth_theo_tung_vong_trao_doi_truc_tiep_voi_ung` | khác |
| `lib/features/auth/views/onboarding_page.dart:111` | Bỏ qua | `auth_bo_qua` | text hiển thị |
| `lib/features/auth/views/onboarding_page.dart:201` | Bắt đầu | `auth_bat_dau` | text hiển thị |
| `lib/features/auth/views/onboarding_page.dart:201` | Tiếp tục | `applications_tiep_tuc` | text hiển thị |
| `lib/features/auth/views/register_employer_page.dart:29` | Bạn cần đồng ý với Điều khoản dịch vụ và Chính sách quyền riêng tư. | `auth_ban_can_dong_y_voi_dieu_khoan_dich_vu_va_c` | khác |
| `lib/features/auth/views/register_employer_page.dart:58` | Mật khẩu nhập lại không khớp. | `auth_mat_khau_nhap_lai_khong_khop` | khác |
| `lib/features/auth/views/register_employer_page.dart:104` | Đăng ký tài khoản Nhà tuyển dụng | `auth_dang_ky_tai_khoan_nha_tuyen_dung` | title |
| `lib/features/auth/views/register_employer_page.dart:105` | Đăng tin tuyển dụng và tiếp cận ứng viên phù hợp nhờ gợi ý từ hệ th… | `auth_dang_tin_tuyen_dung_va_tiep_can_ung_vien_p` | title |
| `lib/features/auth/views/register_employer_page.dart:107` | Đã có tài khoản? | `auth_da_co_tai_khoan` | khác |
| `lib/features/auth/views/register_employer_page.dart:108` | Đăng nhập ngay | `auth_dang_nhap_ngay` | khác |
| `lib/features/auth/views/register_employer_page.dart:124` | Tài khoản | `admin_tai_khoan_2` | khác |
| `lib/features/auth/views/register_employer_page.dart:127` | Email đăng nhập | `auth_email_dang_nhap` | label |
| `lib/features/auth/views/register_employer_page.dart:146` | Mật khẩu | `auth_mat_khau` | label |
| `lib/features/auth/views/register_employer_page.dart:150` | Tối thiểu 8 ký tự | `auth_toi_thieu_8_ky_tu` | khác |
| `lib/features/auth/views/register_employer_page.dart:160` | Nhập lại mật khẩu | `auth_nhap_lai_mat_khau` | label |
| `lib/features/auth/views/register_employer_page.dart:164` | Nhập lại mật khẩu | `auth_nhap_lai_mat_khau` | khác |
| `lib/features/auth/views/register_employer_page.dart:175` | Thông tin nhà tuyển dụng | `auth_thong_tin_nha_tuyen_dung` | khác |
| `lib/features/auth/views/register_employer_page.dart:178` | Họ và tên | `auth_ho_va_ten` | label |
| `lib/features/auth/views/register_employer_page.dart:186` | Nguyễn Văn A | `auth_nguyen_van_a` | form hint/label |
| `lib/features/auth/views/register_employer_page.dart:191` | Họ và tên | `auth_ho_va_ten` | label |
| `lib/features/auth/views/register_employer_page.dart:210` | Số điện thoại cá nhân | `auth_so_dien_thoai_ca_nhan` | label |
| `lib/features/auth/views/register_employer_page.dart:228` | Công ty | `auth_cong_ty` | label |
| `lib/features/auth/views/register_employer_page.dart:235` | Công ty Cổ phần ABC | `auth_cong_ty_co_phan_abc` | form hint/label |
| `lib/features/auth/views/register_employer_page.dart:246` | Địa điểm làm việc | `c_utils_dia_diem_lam_viec` | label |
| `lib/features/auth/views/register_employer_page.dart:258` | Chọn tỉnh/thành phố | `auth_chon_tinh_thanh_pho` | khác |
| `lib/features/auth/views/register_employer_page.dart:285` | Tôi đã đọc và đồng ý với  | `auth_toi_da_doc_va_dong_y_voi` | khác |
| `lib/features/auth/views/register_employer_page.dart:288` | Điều khoản dịch vụ | `auth_dieu_khoan_dich_vu` | khác |
| `lib/features/auth/views/register_employer_page.dart:293` | Chính sách quyền riêng tư | `auth_chinh_sach_quyen_rieng_tu` | khác |
| `lib/features/auth/views/register_employer_page.dart:296` |  của JobHub.  | `auth_cua_jobhub` | text hiển thị |
| `lib/features/auth/views/register_employer_page.dart:300` | Chúng tôi không thể cung cấp dịch vụ nếu không nhận được sự đồng ý … | `auth_chung_toi_khong_the_cung_cap_dich_vu_neu_k` | khác |
| `lib/features/auth/views/register_employer_page.dart:309` | Tôi đồng ý nhận thông tin tư vấn để được hỗ trợ đăng tin nhanh và c… | `auth_toi_dong_y_nhan_thong_tin_tu_van_de_duoc_h` | khác |
| `lib/features/auth/views/register_employer_page.dart:312` | Khuyên dùng: Nếu không có sự đồng ý, chuyên viên sẽ không thể liên … | `auth_khuyen_dung_neu_khong_co_su_dong_y_chuyen` | khác |
| `lib/features/auth/views/register_employer_page.dart:317` | Đăng ký tài khoản | `auth_dang_ky_tai_khoan` | label |
| `lib/features/auth/views/register_employer_page.dart:318` | Đang tạo tài khoản... | `auth_dang_tao_tai_khoan` | khác |
| `lib/features/auth/views/register_page.dart:42` | Mật khẩu nhập lại không khớp. | `auth_mat_khau_nhap_lai_khong_khop` | khác |
| `lib/features/auth/views/register_page.dart:71` | Tạo hồ sơ ứng viên miễn phí | `auth_tao_ho_so_ung_vien_mien_phi` | title |
| `lib/features/auth/views/register_page.dart:72` | Chỉ mất 1 phút để bắt đầu tìm việc. | `auth_chi_mat_1_phut_de_bat_dau_tim_viec` | title |
| `lib/features/auth/views/register_page.dart:74` | Đã có tài khoản? | `auth_da_co_tai_khoan` | khác |
| `lib/features/auth/views/register_page.dart:75` | Đăng nhập | `auth_dang_nhap` | khác |
| `lib/features/auth/views/register_page.dart:90` | Họ và tên | `auth_ho_va_ten` | label |
| `lib/features/auth/views/register_page.dart:98` | Nguyễn Văn A | `auth_nguyen_van_a` | form hint/label |
| `lib/features/auth/views/register_page.dart:103` | Họ tên | `c_utils_ho_ten` | label |
| `lib/features/auth/views/register_page.dart:128` | Mật khẩu | `auth_mat_khau` | label |
| `lib/features/auth/views/register_page.dart:132` | Tối thiểu 8 ký tự | `auth_toi_thieu_8_ky_tu` | khác |
| `lib/features/auth/views/register_page.dart:142` | Nhập lại mật khẩu | `auth_nhap_lai_mat_khau` | label |
| `lib/features/auth/views/register_page.dart:146` | Nhập lại mật khẩu | `auth_nhap_lai_mat_khau` | khác |
| `lib/features/auth/views/register_page.dart:157` | Tạo tài khoản | `auth_tao_tai_khoan` | label |
| `lib/features/auth/views/register_page.dart:158` | Đang tạo tài khoản... | `auth_dang_tao_tai_khoan` | khác |
| `lib/features/auth/widgets/auth_form_widgets.dart:140` | Giới tính | `auth_gioi_tinh` | khác |
| `lib/features/auth/widgets/auth_form_widgets.dart:327` | Bạn là  | `auth_ban_la` | khác |
| `lib/features/auth/widgets/auth_form_widgets.dart:331` | nhà tuyển dụng | `admin_nha_tuyen_dung_2` | khác |
| `lib/features/auth/widgets/auth_form_widgets.dart:338` | Đăng ký tại đây | `auth_dang_ky_tai_day` | khác |

### `features/chat` (41)

| Vị trí | Chuỗi | Key đề xuất | Ngữ cảnh |
|---|---|---|---|
| `lib/features/chat/data/chat_repository.dart:32` | 📷 Ảnh | `chat_anh` | khác |
| `lib/features/chat/data/chat_repository.dart:36` | Tính năng gửi ảnh chưa khả dụng. | `chat_tinh_nang_gui_anh_chua_kha_dung` | khác |
| `lib/features/chat/data/chat_repository.dart:57` | Thiếu người nhận tin nhắn. | `chat_thieu_nguoi_nhan_tin_nhan` | validation/lỗi |
| `lib/features/chat/data/chat_repository.dart:60` | Không thể trò chuyện với chính mình. | `chat_khong_the_tro_chuyen_voi_chinh_minh` | validation/lỗi |
| `lib/features/chat/data/chat_repository.dart:65` | Người dùng | `admin_nguoi_dung` | khác |
| `lib/features/chat/data/chat_repository.dart:149` | Tin nhắn tối đa 2000 ký tự. | `chat_tin_nhan_toi_da_2000_ky_tu` | validation/lỗi |
| `lib/features/chat/data/chat_repository.dart:158` | Không tìm thấy cuộc trò chuyện. | `chat_khong_tim_thay_cuoc_tro_chuyen` | validation/lỗi |
| `lib/features/chat/data/chat_repository.dart:212` | Không đọc được tệp ảnh. | `chat_khong_doc_duoc_tep_anh` | validation/lỗi |
| `lib/features/chat/data/chat_repository.dart:215` | Ảnh tối đa 5MB. | `chat_anh_toi_da_5mb` | validation/lỗi |
| `lib/features/chat/data/chat_repository.dart:218` | Tin nhắn tối đa 2000 ký tự. | `chat_tin_nhan_toi_da_2000_ky_tu` | validation/lỗi |
| `lib/features/chat/data/chat_repository.dart:266` | Người dùng | `admin_nguoi_dung` | khác |
| `lib/features/chat/views/chat_room_page.dart:25` | Tin nhắn | `chat_tin_nhan` | khác |
| `lib/features/chat/views/chat_room_page.dart:29` | Tin nhắn | `chat_tin_nhan` | title |
| `lib/features/chat/views/chats_page.dart:34` | Tin nhắn | `chat_tin_nhan` | title |
| `lib/features/chat/views/chats_page.dart:44` | $unread chưa đọc | `chat_unread_chua_doc` | khác |
| `lib/features/chat/views/chats_page.dart:76` | Chọn một cuộc trò chuyện | `chat_chon_mot_cuoc_tro_chuyen` | text hiển thị |
| `lib/features/chat/views/chats_page.dart:80` | Tin nhắn giữa bạn và đối phương sẽ hiển thị tại đây. | `chat_tin_nhan_giua_ban_va_doi_phuong_se_hien_th` | khác |
| `lib/features/chat/widgets/chat_room_view.dart:96` | Chọn ảnh để gửi | `chat_chon_anh_de_gui` | dialog |
| `lib/features/chat/widgets/chat_room_view.dart:100` | Không mở được thư viện ảnh. | `chat_khong_mo_duoc_thu_vien_anh` | validation/lỗi |
| `lib/features/chat/widgets/chat_room_view.dart:111` | Không đọc được tệp ảnh. | `chat_khong_doc_duoc_tep_anh` | validation/lỗi |
| `lib/features/chat/widgets/chat_room_view.dart:163` | Đang mở cuộc trò chuyện… | `chat_dang_mo_cuoc_tro_chuyen` | label |
| `lib/features/chat/widgets/chat_room_view.dart:173` | Không tìm thấy cuộc trò chuyện | `chat_khong_tim_thay_cuoc_tro_chuyen_2` | title |
| `lib/features/chat/widgets/chat_room_view.dart:174` | Cuộc trò chuyện này không tồn tại hoặc bạn không có quyền truy cập. | `chat_cuoc_tro_chuyen_nay_khong_ton_tai_hoac_ban` | title |
| `lib/features/chat/widgets/chat_room_view.dart:177` | Về danh sách tin nhắn | `chat_ve_danh_sach_tin_nhan` | text hiển thị |
| `lib/features/chat/widgets/chat_room_view.dart:184` | Bạn không có quyền xem cuộc trò chuyện này | `chat_ban_khong_co_quyen_xem_cuoc_tro_chuyen_nay` | title |
| `lib/features/chat/widgets/chat_room_view.dart:203` | Chưa có tin nhắn | `chat_chua_co_tin_nhan` | title |
| `lib/features/chat/widgets/chat_room_view.dart:204` | Hãy gửi lời chào để bắt đầu cuộc trò chuyện. | `chat_hay_gui_loi_chao_de_bat_dau_cuoc_tro_chuye` | title |
| `lib/features/chat/widgets/chat_room_view.dart:241` | Quay lại | `applications_quay_lai` | tooltip |
| `lib/features/chat/widgets/chat_room_view.dart:363` | Gửi ảnh | `chat_gui_anh` | tooltip |
| `lib/features/chat/widgets/chat_room_view.dart:380` | Nhập tin nhắn… | `chat_nhap_tin_nhan` | form hint/label |
| `lib/features/chat/widgets/chat_thread_list.dart:28` | Vui lòng đăng nhập để xem tin nhắn | `chat_vui_long_dang_nhap_de_xem_tin_nhan` | title |
| `lib/features/chat/widgets/chat_thread_list.dart:31` | Đăng nhập | `auth_dang_nhap` | text hiển thị |
| `lib/features/chat/widgets/chat_thread_list.dart:37` | Đang tải tin nhắn… | `chat_dang_tai_tin_nhan` | label |
| `lib/features/chat/widgets/chat_thread_list.dart:47` | Chưa có cuộc trò chuyện nào | `chat_chua_co_cuoc_tro_chuyen_nao` | title |
| `lib/features/chat/widgets/chat_thread_list.dart:49` | Nhà tuyển dụng và ứng viên có thể bắt đầu trò chuyện từ trang hồ sơ… | `chat_nha_tuyen_dung_va_ung_vien_co_the_bat_dau` | khác |
| `lib/features/chat/widgets/chat_thread_tile.dart:94` | Chưa có tin nhắn | `chat_chua_co_tin_nhan` | khác |
| `lib/features/chat/widgets/chat_thread_tile.dart:94` | Bạn: $last | `chat_ban_last` | khác |
| `lib/features/chat/widgets/message_bubble.dart:78` | Đang gửi… | `chat_dang_gui` | validation/lỗi |
| `lib/features/chat/widgets/message_bubble.dart:126` | Không tải được ảnh | `chat_khong_tai_duoc_anh` | text hiển thị |
| `lib/features/chat/widgets/message_bubble.dart:145` | Hôm nay | `chat_hom_nay` | khác |
| `lib/features/chat/widgets/message_bubble.dart:146` | Hôm qua | `chat_hom_qua` | khác |

### `features/employer` (316)

| Vị trí | Chuỗi | Key đề xuất | Ngữ cảnh |
|---|---|---|---|
| `lib/features/employer/data/employer_repository.dart:29` | Bạn chỉ được quản lý tin tuyển dụng của công ty mình. | `employer_ban_chi_duoc_quan_ly_tin_tuyen_dung_cua_co` | khác |
| `lib/features/employer/data/employer_repository.dart:30` | Không tìm thấy tin tuyển dụng. | `admin_khong_tim_thay_tin_tuyen_dung` | khác |
| `lib/features/employer/data/employer_repository.dart:31` | Không tìm thấy hồ sơ công ty. | `employer_khong_tim_thay_ho_so_cong_ty` | khác |
| `lib/features/employer/data/employer_repository.dart:32` | Tin tuyển dụng này đã bị từ chối, không thể mở lại. | `employer_tin_tuyen_dung_nay_da_bi_tu_choi_khong_the` | khác |
| `lib/features/employer/data/employer_repository.dart:55` | Tên công ty phải từ 2 đến 255 ký tự. | `employer_ten_cong_ty_phai_tu_2_den_255_ky_tu` | validation/lỗi |
| `lib/features/employer/data/employer_repository.dart:57` | Số điện thoại tối đa 20 ký tự. | `employer_so_dien_thoai_toi_da_20_ky_tu` | validation/lỗi |
| `lib/features/employer/data/employer_repository.dart:58` | Website tối đa 255 ký tự. | `employer_website_toi_da_255_ky_tu` | validation/lỗi |
| `lib/features/employer/data/employer_repository.dart:60` | Giới thiệu công ty tối đa 5000 ký tự. | `employer_gioi_thieu_cong_ty_toi_da_5000_ky_tu` | validation/lỗi |
| `lib/features/employer/data/employer_repository.dart:62` | Thành phố tối đa 100 ký tự. | `employer_thanh_pho_toi_da_100_ky_tu` | validation/lỗi |
| `lib/features/employer/data/employer_repository.dart:64` | Người liên hệ tối đa 255 ký tự. | `employer_nguoi_lien_he_toi_da_255_ky_tu` | validation/lỗi |
| `lib/features/employer/data/employer_repository.dart:201` | Không thể tạo tin tuyển dụng. Vui lòng kiểm tra và sửa các nội dung… | `employer_khong_the_tao_tin_tuyen_dung_vui_long_kiem` | khác |
| `lib/features/employer/data/employer_repository.dart:208` | Công ty chưa cập nhật | `c_utils_cong_ty_chua_cap_nhat` | khác |
| `lib/features/employer/data/employer_repository.dart:269` | Không thể cập nhật tin tuyển dụng. Vui lòng kiểm tra và sửa các nội… | `employer_khong_the_cap_nhat_tin_tuyen_dung_vui_long` | khác |
| `lib/features/employer/data/job_form_input.dart:18` | Không yêu cầu | `c_services_khong_yeu_cau` | khác |
| `lib/features/employer/data/job_form_input.dart:57` | Không yêu cầu | `c_services_khong_yeu_cau` | khác |
| `lib/features/employer/data/job_form_input.dart:58` | Trung cấp | `employer_trung_cap` | khác |
| `lib/features/employer/data/job_form_input.dart:59` | Cao đẳng | `employer_cao_dang` | khác |
| `lib/features/employer/data/job_form_input.dart:60` | Đại học | `employer_dai_hoc` | khác |
| `lib/features/employer/data/job_form_input.dart:61` | Sau đại học | `employer_sau_dai_hoc` | khác |
| `lib/features/employer/data/job_form_input.dart:149` | Tin tuyển dụng chưa có tiêu đề | `admin_tin_tuyen_dung_chua_co_tieu_de` | khác |
| `lib/features/employer/data/job_form_input.dart:230` | Không yêu cầu | `c_services_khong_yeu_cau` | khác |
| `lib/features/employer/data/job_form_input.dart:251` | Tên vị trí tuyển dụng | `employer_ten_vi_tri_tuyen_dung` | khác |
| `lib/features/employer/data/job_form_input.dart:252` | Mô tả công việc | `c_utils_mo_ta_cong_viec` | khác |
| `lib/features/employer/data/job_form_input.dart:253` | Lương tối thiểu | `employer_luong_toi_thieu` | khác |
| `lib/features/employer/data/job_form_input.dart:254` | Lương tối đa | `employer_luong_toi_da` | khác |
| `lib/features/employer/data/job_form_input.dart:255` | Đơn vị tiền tệ | `employer_don_vi_tien_te` | khác |
| `lib/features/employer/data/job_form_input.dart:256` | Địa điểm làm việc | `c_utils_dia_diem_lam_viec` | khác |
| `lib/features/employer/data/job_form_input.dart:257` | Thành phố | `employer_thanh_pho` | khác |
| `lib/features/employer/data/job_form_input.dart:258` | Kinh nghiệm | `employer_kinh_nghiem` | khác |
| `lib/features/employer/data/job_form_input.dart:259` | Ngành nghề | `admin_nganh_nghe` | khác |
| `lib/features/employer/data/job_form_input.dart:260` | Ngành nghề | `admin_nganh_nghe` | khác |
| `lib/features/employer/data/job_form_input.dart:261` | Hình thức làm việc | `employer_hinh_thuc_lam_viec` | khác |
| `lib/features/employer/data/job_form_input.dart:262` | Loại hình công việc | `employer_loai_hinh_cong_viec` | khác |
| `lib/features/employer/data/job_form_input.dart:263` | Kỹ năng yêu cầu | `employer_ky_nang_yeu_cau` | khác |
| `lib/features/employer/data/job_form_input.dart:264` | Số lượng tuyển | `employer_so_luong_tuyen` | khác |
| `lib/features/employer/data/job_form_input.dart:265` | Hạn nộp hồ sơ | `employer_han_nop_ho_so` | khác |
| `lib/features/employer/data/job_form_input.dart:276` | Vui lòng chọn hoặc nhập ngành nghề. | `employer_vui_long_chon_hoac_nhap_nganh_nghe` | validation/lỗi |
| `lib/features/employer/data/job_form_input.dart:278` | Ngành nghề tối đa 100 ký tự. | `employer_nganh_nghe_toi_da_100_ky_tu` | validation/lỗi |
| `lib/features/employer/data/job_form_input.dart:288` | Lương tối thiểu phải là số không âm. | `employer_luong_toi_thieu_phai_la_so_khong_am` | validation/lỗi |
| `lib/features/employer/data/job_form_input.dart:291` | Lương tối đa phải là số không âm. | `employer_luong_toi_da_phai_la_so_khong_am` | validation/lỗi |
| `lib/features/employer/data/job_form_input.dart:298` | Đơn vị tiền tệ phải gồm đúng 3 chữ cái (ví dụ VND). | `employer_don_vi_tien_te_phai_gom_dung_3_chu_cai_vi` | validation/lỗi |
| `lib/features/employer/data/job_form_input.dart:304` | Thành phố là bắt buộc. | `employer_thanh_pho_la_bat_buoc` | validation/lỗi |
| `lib/features/employer/data/job_form_input.dart:306` | Thành phố tối đa 100 ký tự. | `employer_thanh_pho_toi_da_100_ky_tu` | validation/lỗi |
| `lib/features/employer/data/job_form_input.dart:308` | Số lượng tuyển | `employer_so_luong_tuyen` | label |
| `lib/features/employer/data/job_form_input.dart:312` | Hạn nộp hồ sơ là bắt buộc. | `employer_han_nop_ho_so_la_bat_buoc` | validation/lỗi |
| `lib/features/employer/data/job_form_input.dart:325` | Một tin tuyển dụng không được có quá $maxSkills kỹ năng. | `employer_mot_tin_tuyen_dung_khong_duoc_co_qua_maxsk` | validation/lỗi |
| `lib/features/employer/data/job_form_input.dart:329` | Tên kỹ năng tối đa 80 ký tự. | `employer_ten_ky_nang_toi_da_80_ky_tu` | validation/lỗi |
| `lib/features/employer/viewmodels/company_profile_viewmodel.dart:59` | Bạn không có quyền thực hiện thao tác này. | `c_utils_ban_khong_co_quyen_thuc_hien_thao_tac_nay` | validation/lỗi |
| `lib/features/employer/viewmodels/company_profile_viewmodel.dart:75` | Cập nhật hồ sơ công ty thành công. | `employer_cap_nhat_ho_so_cong_ty_thanh_cong` | validation/lỗi |
| `lib/features/employer/viewmodels/company_profile_viewmodel.dart:83` | Không thể cập nhật hồ sơ công ty. | `employer_khong_the_cap_nhat_ho_so_cong_ty` | validation/lỗi |
| `lib/features/employer/viewmodels/company_profile_viewmodel.dart:98` | Đã cập nhật logo công ty. | `employer_da_cap_nhat_logo_cong_ty` | validation/lỗi |
| `lib/features/employer/viewmodels/company_profile_viewmodel.dart:103` | Không thể tải logo lên lúc này (Firebase Storage chưa được bật). Cá… | `employer_khong_the_tai_logo_len_luc_nay_firebase_st` | validation/lỗi |
| `lib/features/employer/viewmodels/create_job_viewmodel.dart:15` | Lỗi hệ thống | `admin_loi_he_thong` | khác |
| `lib/features/employer/viewmodels/create_job_viewmodel.dart:30` | Không thể cập nhật tin tuyển dụng. | `employer_khong_the_cap_nhat_tin_tuyen_dung` | khác |
| `lib/features/employer/viewmodels/create_job_viewmodel.dart:30` | Không thể tạo tin tuyển dụng. | `employer_khong_the_tao_tin_tuyen_dung` | khác |
| `lib/features/employer/viewmodels/create_job_viewmodel.dart:74` | Thông tin | `employer_thong_tin` | khác |
| `lib/features/employer/viewmodels/create_job_viewmodel.dart:74` | Lương & địa điểm | `employer_luong_dia_diem` | khác |
| `lib/features/employer/viewmodels/create_job_viewmodel.dart:74` | Kỹ năng & xem trước | `employer_ky_nang_xem_truoc` | khác |
| `lib/features/employer/viewmodels/create_job_viewmodel.dart:229` | Không thể chọn thêm kỹ năng. | `employer_khong_the_chon_them_ky_nang` | validation/lỗi |
| `lib/features/employer/viewmodels/create_job_viewmodel.dart:230` | Một tin tuyển dụng không được có quá ${state.maxSkills} kỹ năng. | `employer_mot_tin_tuyen_dung_khong_duoc_co_qua_state` | khác |
| `lib/features/employer/viewmodels/create_job_viewmodel.dart:311` | Không thể cập nhật tin tuyển dụng. Vui lòng kiểm tra và sửa các nội… | `employer_khong_the_cap_nhat_tin_tuyen_dung_vui_long` | khác |
| `lib/features/employer/viewmodels/create_job_viewmodel.dart:312` | Không thể tạo tin tuyển dụng. Vui lòng kiểm tra và sửa các nội dung… | `employer_khong_the_tao_tin_tuyen_dung_vui_long_kiem` | khác |
| `lib/features/employer/viewmodels/employer_providers.dart:70` | Tất cả | `c_config_tat_ca` | enum/option |
| `lib/features/employer/viewmodels/employer_providers.dart:71` | Đang hiển thị | `employer_dang_hien_thi` | enum/option |
| `lib/features/employer/viewmodels/employer_providers.dart:72` | Chờ duyệt | `admin_cho_duyet` | enum/option |
| `lib/features/employer/viewmodels/employer_providers.dart:73` | Đã đóng | `c_utils_da_dong` | enum/option |
| `lib/features/employer/viewmodels/employer_providers.dart:74` | Bị từ chối | `employer_bi_tu_choi` | enum/option |
| `lib/features/employer/views/create_job_page.dart:71` | Đã lưu thay đổi tin tuyển dụng. | `employer_da_luu_thay_doi_tin_tuyen_dung` | khác |
| `lib/features/employer/views/create_job_page.dart:73` | Đã tạo tin tuyển dụng. Tin đang chờ quản trị viên duyệt. | `employer_da_tao_tin_tuyen_dung_tin_dang_cho_quan_tr` | khác |
| `lib/features/employer/views/create_job_page.dart:74` | Đã đăng tin tuyển dụng. | `employer_da_dang_tin_tuyen_dung` | khác |
| `lib/features/employer/views/create_job_page.dart:84` | Bạn không thể chỉnh sửa tin tuyển dụng | `employer_ban_khong_the_chinh_sua_tin_tuyen_dung` | khác |
| `lib/features/employer/views/create_job_page.dart:85` | Bạn không thể đăng tin tuyển dụng | `employer_ban_khong_the_dang_tin_tuyen_dung` | khác |
| `lib/features/employer/views/create_job_page.dart:114` | Đang tải tin tuyển dụng... | `applications_dang_tai_tin_tuyen_dung` | khác |
| `lib/features/employer/views/create_job_page.dart:120` | Về danh sách tin | `employer_ve_danh_sach_tin` | text hiển thị |
| `lib/features/employer/views/create_job_page.dart:162` | Chỉnh sửa tin tuyển dụng | `employer_chinh_sua_tin_tuyen_dung` | khác |
| `lib/features/employer/views/create_job_page.dart:162` | Đăng tin tuyển dụng | `employer_dang_tin_tuyen_dung` | khác |
| `lib/features/employer/views/create_job_page.dart:164` | Chỉnh sửa tin tuyển dụng | `employer_chinh_sua_tin_tuyen_dung` | khác |
| `lib/features/employer/views/create_job_page.dart:165` | Tạo tin tuyển dụng mới | `employer_tao_tin_tuyen_dung_moi` | khác |
| `lib/features/employer/views/create_job_page.dart:167` | Cập nhật nội dung tin. Trạng thái duyệt của tin được giữ nguyên. | `employer_cap_nhat_noi_dung_tin_trang_thai_duyet_cua` | khác |
| `lib/features/employer/views/create_job_page.dart:169` | Tin tuyển dụng mới sẽ ở trạng thái chờ duyệt trước khi được hiển th… | `employer_tin_tuyen_dung_moi_se_o_trang_thai_cho_duy` | khác |
| `lib/features/employer/views/create_job_page.dart:170` | Tin tuyển dụng sẽ được hiển thị công khai ngay sau khi đăng. | `employer_tin_tuyen_dung_se_duoc_hien_thi_cong_khai` | khác |
| `lib/features/employer/views/create_job_page.dart:174` | Danh sách tin | `employer_danh_sach_tin` | label |
| `lib/features/employer/views/create_job_page.dart:220` | Bạn có một bản nháp tin tuyển dụng chưa đăng. | `employer_ban_co_mot_ban_nhap_tin_tuyen_dung_chua_da` | khác |
| `lib/features/employer/views/create_job_page.dart:221` | Bạn có một bản nháp chưa đăng (lưu lúc ${Formatters.dateTime(savedA… | `employer_ban_co_mot_ban_nhap_chua_dang_luu_luc_form` | khác |
| `lib/features/employer/views/create_job_page.dart:229` | Khôi phục bản nháp | `employer_khoi_phuc_ban_nhap` | text hiển thị |
| `lib/features/employer/views/create_job_page.dart:231` | Bỏ bản nháp | `employer_bo_ban_nhap` | button |
| `lib/features/employer/views/create_job_page.dart:248` | Đang lưu... | `admin_dang_luu` | khác |
| `lib/features/employer/views/create_job_page.dart:248` | Đang tạo tin... | `employer_dang_tao_tin` | khác |
| `lib/features/employer/views/create_job_page.dart:249` | Lưu thay đổi | `employer_luu_thay_doi` | khác |
| `lib/features/employer/views/create_job_page.dart:249` | Tạo tin tuyển dụng | `employer_tao_tin_tuyen_dung` | khác |
| `lib/features/employer/views/create_job_page.dart:256` | Quay lại | `applications_quay_lai` | label |
| `lib/features/employer/views/create_job_page.dart:263` | Đã lưu nháp ${Formatters.time(state.draftSavedAt)} | `employer_da_luu_nhap_formatters_time_state_draftsav` | khác |
| `lib/features/employer/views/create_job_page.dart:271` | Tiếp tục | `applications_tiep_tuc` | label |
| `lib/features/employer/views/employer_company_profile_page.dart:97` | Tên công ty phải từ 2 đến 255 ký tự. | `employer_ten_cong_ty_phai_tu_2_den_255_ky_tu` | khác |
| `lib/features/employer/views/employer_company_profile_page.dart:112` | Bạn không thể truy cập trang hồ sơ công ty | `employer_ban_khong_the_truy_cap_trang_ho_so_cong_ty` | khác |
| `lib/features/employer/views/employer_company_profile_page.dart:125` | Hồ sơ công ty | `employer_ho_so_cong_ty` | khác |
| `lib/features/employer/views/employer_company_profile_page.dart:126` | Quản lý hồ sơ công ty | `employer_quan_ly_ho_so_cong_ty` | title |
| `lib/features/employer/views/employer_company_profile_page.dart:127` | Cập nhật thông tin công ty để hiển thị cùng các tin tuyển dụng. | `employer_cap_nhat_thong_tin_cong_ty_de_hien_thi_cun` | title |
| `lib/features/employer/views/employer_company_profile_page.dart:131` | Đang tải hồ sơ công ty... | `employer_dang_tai_ho_so_cong_ty` | khác |
| `lib/features/employer/views/employer_company_profile_page.dart:182` | Tên công ty | `employer_ten_cong_ty` | label |
| `lib/features/employer/views/employer_company_profile_page.dart:188` | Tên công ty | `employer_ten_cong_ty` | form hint/label |
| `lib/features/employer/views/employer_company_profile_page.dart:193` | Số điện thoại | `employer_so_dien_thoai` | label |
| `lib/features/employer/views/employer_company_profile_page.dart:198` | Số điện thoại | `employer_so_dien_thoai` | label |
| `lib/features/employer/views/employer_company_profile_page.dart:200` | Số điện thoại liên hệ | `employer_so_dien_thoai_lien_he` | form hint/label |
| `lib/features/employer/views/employer_company_profile_page.dart:218` | Thành phố | `employer_thanh_pho` | label |
| `lib/features/employer/views/employer_company_profile_page.dart:223` | Thành phố | `employer_thanh_pho` | label |
| `lib/features/employer/views/employer_company_profile_page.dart:225` | Hà Nội | `employer_ha_noi` | form hint/label |
| `lib/features/employer/views/employer_company_profile_page.dart:229` | Người liên hệ | `employer_nguoi_lien_he` | label |
| `lib/features/employer/views/employer_company_profile_page.dart:233` | Người liên hệ | `employer_nguoi_lien_he` | label |
| `lib/features/employer/views/employer_company_profile_page.dart:235` | Tên người phụ trách tuyển dụng | `employer_ten_nguoi_phu_trach_tuyen_dung` | form hint/label |
| `lib/features/employer/views/employer_company_profile_page.dart:240` | Giới tính người liên hệ | `employer_gioi_tinh_nguoi_lien_he` | label |
| `lib/features/employer/views/employer_company_profile_page.dart:265` | Giới thiệu công ty | `employer_gioi_thieu_cong_ty` | label |
| `lib/features/employer/views/employer_company_profile_page.dart:272` | Giới thiệu công ty | `employer_gioi_thieu_cong_ty` | label |
| `lib/features/employer/views/employer_company_profile_page.dart:274` | Mô tả ngắn gọn về công ty, lĩnh vực hoạt động và môi trường làm việc. | `employer_mo_ta_ngan_gon_ve_cong_ty_linh_vuc_hoat_do` | form hint/label |
| `lib/features/employer/views/employer_company_profile_page.dart:283` | Đang lưu... | `admin_dang_luu` | text hiển thị |
| `lib/features/employer/views/employer_company_profile_page.dart:283` | Lưu hồ sơ công ty | `employer_luu_ho_so_cong_ty` | text hiển thị |
| `lib/features/employer/views/employer_company_profile_page.dart:300` | Công ty chưa cập nhật | `c_utils_cong_ty_chua_cap_nhat` | khác |
| `lib/features/employer/views/employer_company_profile_page.dart:319` | Đã xác thực | `employer_da_xac_thuc` | khác |
| `lib/features/employer/views/employer_company_profile_page.dart:320` | Chờ xác thực | `employer_cho_xac_thuc` | khác |
| `lib/features/employer/views/employer_company_profile_page.dart:325` | Đang hoạt động | `admin_dang_hoat_dong` | khác |
| `lib/features/employer/views/employer_company_profile_page.dart:325` | Đã bị khoá | `employer_da_bi_khoa` | khác |
| `lib/features/employer/views/employer_company_profile_page.dart:338` | Đang tải logo... | `employer_dang_tai_logo` | label |
| `lib/features/employer/views/employer_company_profile_page.dart:338` | Tải logo lên | `employer_tai_logo_len` | label |
| `lib/features/employer/views/employer_company_profile_page.dart:342` | Tuỳ chọn. PNG/JPG, tối đa 512px. Nếu Firebase Storage chưa bật, log… | `employer_tuy_chon_png_jpg_toi_da_512px_neu_firebase` | khác |
| `lib/features/employer/views/employer_company_profile_page.dart:346` | Chưa cập nhật email | `employer_chua_cap_nhat_email` | khác |
| `lib/features/employer/views/employer_company_profile_page.dart:347` | ${profile.openPositions} vị trí đang tuyển | `employer_profile_openpositions_vi_tri_dang_tuyen` | khác |
| `lib/features/employer/views/employer_company_profile_page.dart:350` | Công ty đã được quản trị viên xác thực. | `employer_cong_ty_da_duoc_quan_tri_vien_xac_thuc` | khác |
| `lib/features/employer/views/employer_company_profile_page.dart:351` | Hồ sơ đang chờ quản trị viên xác thực. Tin tuyển dụng vẫn có thể đư… | `employer_ho_so_dang_cho_quan_tri_vien_xac_thuc_tin` | khác |
| `lib/features/employer/views/employer_company_profile_page.dart:354` | Cập nhật ${Formatters.relative(profile.updatedAt)} | `employer_cap_nhat_formatters_relative_profile_updat` | khác |
| `lib/features/employer/views/employer_dashboard_page.dart:29` | Bạn không thể truy cập trang tổng quan nhà tuyển dụng | `employer_ban_khong_the_truy_cap_trang_tong_quan_nha` | khác |
| `lib/features/employer/views/employer_dashboard_page.dart:42` | Nhà tuyển dụng | `admin_nha_tuyen_dung` | khác |
| `lib/features/employer/views/employer_dashboard_page.dart:43` | Tổng quan | `employer_tong_quan` | title |
| `lib/features/employer/views/employer_dashboard_page.dart:44` | Theo dõi tin tuyển dụng và hồ sơ ứng tuyển của công ty bạn. | `employer_theo_doi_tin_tuyen_dung_va_ho_so_ung_tuyen` | title |
| `lib/features/employer/views/employer_dashboard_page.dart:48` | Đăng tin mới | `employer_dang_tin_moi` | label |
| `lib/features/employer/views/employer_dashboard_page.dart:59` | Đang tải dữ liệu tổng quan... | `employer_dang_tai_du_lieu_tong_quan` | enum/option |
| `lib/features/employer/views/employer_dashboard_page.dart:68` | Thử lại | `admin_thu_lai` | label |
| `lib/features/employer/views/employer_dashboard_page.dart:109` | Công ty chưa cập nhật | `c_utils_cong_ty_chua_cap_nhat` | khác |
| `lib/features/employer/views/employer_dashboard_page.dart:129` | Đã xác thực | `employer_da_xac_thuc` | khác |
| `lib/features/employer/views/employer_dashboard_page.dart:130` | Chờ xác thực | `employer_cho_xac_thuc` | khác |
| `lib/features/employer/views/employer_dashboard_page.dart:140` | Liên hệ: ${profile.contactName} | `employer_lien_he_profile_contactname` | khác |
| `lib/features/employer/views/employer_dashboard_page.dart:152` | Hồ sơ công ty | `employer_ho_so_cong_ty` | text hiển thị |
| `lib/features/employer/views/employer_dashboard_page.dart:177` | Quản lý tin tuyển dụng | `employer_quan_ly_tin_tuyen_dung` | khác |
| `lib/features/employer/views/employer_dashboard_page.dart:178` | Hồ sơ ứng tuyển | `admin_ho_so_ung_tuyen` | khác |
| `lib/features/employer/views/employer_dashboard_page.dart:179` | Hồ sơ công ty | `employer_ho_so_cong_ty` | khác |
| `lib/features/employer/views/employer_dashboard_page.dart:180` | Tin nhắn | `chat_tin_nhan` | khác |
| `lib/features/employer/views/employer_dashboard_page.dart:181` | Thông báo | `employer_thong_bao` | khác |
| `lib/features/employer/views/employer_dashboard_page.dart:195` | TIN ĐANG MỞ | `employer_tin_dang_mo` | label |
| `lib/features/employer/views/employer_dashboard_page.dart:197` | ${stats.pendingJobs} tin chờ duyệt | `employer_stats_pendingjobs_tin_cho_duyet` | khác |
| `lib/features/employer/views/employer_dashboard_page.dart:197` | ${stats.jobs.length} tin tổng cộng | `employer_stats_jobs_length_tin_tong_cong` | khác |
| `lib/features/employer/views/employer_dashboard_page.dart:202` | TỔNG HỒ SƠ | `employer_tong_ho_so` | label |
| `lib/features/employer/views/employer_dashboard_page.dart:204` | Trên tất cả tin tuyển dụng | `employer_tren_tat_ca_tin_tuyen_dung` | khác |
| `lib/features/employer/views/employer_dashboard_page.dart:211` | HỒ SƠ MỚI 7 NGÀY | `employer_ho_so_moi_7_ngay` | label |
| `lib/features/employer/views/employer_dashboard_page.dart:213` | Nộp trong tuần qua | `employer_nop_trong_tuan_qua` | khác |
| `lib/features/employer/views/employer_dashboard_page.dart:219` | TỈ LỆ CHẤP NHẬN | `employer_ti_le_chap_nhan` | label |
| `lib/features/employer/views/employer_dashboard_page.dart:222` | Chưa có hồ sơ được xử lý | `employer_chua_co_ho_so_duoc_xu_ly` | khác |
| `lib/features/employer/views/employer_dashboard_page.dart:223` | ${stats.byStatus[ApplicationStatus.accepted]} được nhận / ${stats.b… | `employer_stats_bystatus_applicationstatus_accepted` | khác |
| `lib/features/employer/views/employer_dashboard_page.dart:254` | Hồ sơ theo trạng thái | `employer_ho_so_theo_trang_thai` | text hiển thị |
| `lib/features/employer/views/employer_dashboard_page.dart:257` | ${stats.totalApplications} hồ sơ ứng tuyển | `employer_stats_totalapplications_ho_so_ung_tuyen` | text hiển thị |
| `lib/features/employer/views/employer_dashboard_page.dart:280` | Hồ sơ mới nhất | `employer_ho_so_moi_nhat` | text hiển thị |
| `lib/features/employer/views/employer_dashboard_page.dart:285` | Xem tất cả | `employer_xem_tat_ca` | text hiển thị |
| `lib/features/employer/views/employer_dashboard_page.dart:294` | Chưa có hồ sơ ứng tuyển nào. | `employer_chua_co_ho_so_ung_tuyen_nao` | text hiển thị |
| `lib/features/employer/views/employer_dashboard_page.dart:329` | Tin nhận nhiều hồ sơ nhất | `employer_tin_nhan_nhieu_ho_so_nhat` | text hiển thị |
| `lib/features/employer/views/employer_dashboard_page.dart:334` | Quản lý tin | `employer_quan_ly_tin` | text hiển thị |
| `lib/features/employer/views/employer_dashboard_page.dart:345` | Bạn chưa đăng tin tuyển dụng nào. | `employer_ban_chua_dang_tin_tuyen_dung_nao` | text hiển thị |
| `lib/features/employer/views/employer_dashboard_page.dart:351` | Đăng tin mới | `employer_dang_tin_moi` | label |
| `lib/features/employer/views/employer_dashboard_page.dart:385` | hồ sơ | `employer_ho_so` | text hiển thị |
| `lib/features/employer/views/employer_jobs_page.dart:23` | Bạn không thể truy cập trang quản lý tin tuyển dụng | `employer_ban_khong_the_truy_cap_trang_quan_ly_tin_t` | khác |
| `lib/features/employer/views/employer_jobs_page.dart:35` | Quản lý tin tuyển dụng | `employer_quan_ly_tin_tuyen_dung` | khác |
| `lib/features/employer/views/employer_jobs_page.dart:36` | Tin tuyển dụng của tôi | `employer_tin_tuyen_dung_cua_toi` | title |
| `lib/features/employer/views/employer_jobs_page.dart:37` | Xem, đóng hoặc xoá các tin tuyển dụng do công ty của bạn đăng. | `employer_xem_dong_hoac_xoa_cac_tin_tuyen_dung_do_co` | title |
| `lib/features/employer/views/employer_jobs_page.dart:41` | Đăng tin tuyển dụng | `employer_dang_tin_tuyen_dung` | label |
| `lib/features/employer/views/employer_jobs_page.dart:51` | Đang tải danh sách tin tuyển dụng... | `employer_dang_tai_danh_sach_tin_tuyen_dung` | khác |
| `lib/features/employer/views/employer_jobs_page.dart:59` | Thử lại | `admin_thu_lai` | label |
| `lib/features/employer/views/employer_jobs_page.dart:65` | Công ty của bạn chưa có tin tuyển dụng nào. | `employer_cong_ty_cua_ban_chua_co_tin_tuyen_dung_nao` | khác |
| `lib/features/employer/views/employer_jobs_page.dart:70` | Đăng tin mới | `employer_dang_tin_moi` | label |
| `lib/features/employer/views/employer_jobs_page.dart:77` | Không có tin tuyển dụng nào ở mục "${filter.label}". | `employer_khong_co_tin_tuyen_dung_nao_o_muc_filter_l` | khác |
| `lib/features/employer/views/employer_jobs_page.dart:94` | Bạn có chắc muốn đóng tin tuyển dụng này không? | `employer_ban_co_chac_muon_dong_tin_tuyen_dung_nay_k` | validation/lỗi |
| `lib/features/employer/views/employer_jobs_page.dart:95` | Đóng tin | `employer_dong_tin` | khác |
| `lib/features/employer/views/employer_jobs_page.dart:96` | Đã đóng tin tuyển dụng. | `employer_da_dong_tin_tuyen_dung` | khác |
| `lib/features/employer/views/employer_jobs_page.dart:102` | Mở lại tin tuyển dụng này để ứng viên có thể thấy & ứng tuyển? | `employer_mo_lai_tin_tuyen_dung_nay_de_ung_vien_co_t` | validation/lỗi |
| `lib/features/employer/views/employer_jobs_page.dart:103` | Mở tin | `employer_mo_tin` | khác |
| `lib/features/employer/views/employer_jobs_page.dart:104` | Đã mở lại tin tuyển dụng. | `employer_da_mo_lai_tin_tuyen_dung` | khác |
| `lib/features/employer/views/employer_jobs_page.dart:110` | Bạn có chắc muốn xoá tin tuyển dụng này không? | `employer_ban_co_chac_muon_xoa_tin_tuyen_dung_nay_kh` | validation/lỗi |
| `lib/features/employer/views/employer_jobs_page.dart:113` | Đã xoá tin tuyển dụng. | `employer_da_xoa_tin_tuyen_dung` | khác |
| `lib/features/employer/views/employer_jobs_page.dart:142` | Xác nhận | `applications_xac_nhan` | title |
| `lib/features/employer/views/job_applicants_page.dart:32` | Bạn không thể xem danh sách ứng viên | `employer_ban_khong_the_xem_danh_sach_ung_vien` | khác |
| `lib/features/employer/views/job_applicants_page.dart:37` | Đang tải tin tuyển dụng... | `applications_dang_tai_tin_tuyen_dung` | khác |
| `lib/features/employer/views/job_applicants_page.dart:49` | Về danh sách tin | `employer_ve_danh_sach_tin` | text hiển thị |
| `lib/features/employer/views/job_applicants_page.dart:58` | Không có quyền truy cập | `employer_khong_co_quyen_truy_cap` | khác |
| `lib/features/employer/views/job_applicants_page.dart:60` | Bạn không thể xem ứng viên của tin này | `employer_ban_khong_the_xem_ung_vien_cua_tin_nay` | title |
| `lib/features/employer/views/job_applicants_page.dart:139` | Đang tải danh sách ứng viên... | `employer_dang_tai_danh_sach_ung_vien` | enum/option |
| `lib/features/employer/views/job_applicants_page.dart:145` | Thử lại | `admin_thu_lai` | label |
| `lib/features/employer/views/job_applicants_page.dart:151` | Chưa có ứng viên nào ứng tuyển vào tin này. | `employer_chua_co_ung_vien_nao_ung_tuyen_vao_tin_nay` | khác |
| `lib/features/employer/views/job_applicants_page.dart:157` | Xem tin công khai | `employer_xem_tin_cong_khai` | label |
| `lib/features/employer/views/job_applicants_page.dart:166` | Không tìm thấy ứng viên phù hợp với từ khoá. | `employer_khong_tim_thay_ung_vien_phu_hop_voi_tu_kho` | khác |
| `lib/features/employer/views/job_applicants_page.dart:167` | Không có hồ sơ nào ở trạng thái này. | `employer_khong_co_ho_so_nao_o_trang_thai_nay` | khác |
| `lib/features/employer/views/job_applicants_page.dart:181` | Hiển thị ${start + 1}–$end trên ${filtered.length} hồ sơ | `employer_hien_thi_start_1_end_tren_filtered_length` | khác |
| `lib/features/employer/views/job_applicants_page.dart:214` | Ứng viên | `admin_ung_vien` | khác |
| `lib/features/employer/views/job_applicants_page.dart:216` | Danh sách hồ sơ đã ứng tuyển vào tin tuyển dụng này. | `employer_danh_sach_ho_so_da_ung_tuyen_vao_tin_tuyen` | title |
| `lib/features/employer/views/job_applicants_page.dart:223` | Danh sách tin | `employer_danh_sach_tin` | label |
| `lib/features/employer/views/job_applicants_page.dart:228` | Sửa tin | `employer_sua_tin` | label |
| `lib/features/employer/views/job_applicants_page.dart:273` | Tìm theo tên hoặc email ứng viên | `employer_tim_theo_ten_hoac_email_ung_vien` | form hint/label |
| `lib/features/employer/views/job_applicants_page.dart:278` | Xoá tìm kiếm | `employer_xoa_tim_kiem` | tooltip |
| `lib/features/employer/views/job_applicants_page.dart:323` | Mức lương: ${EmployerJobLabels.salary(job)} | `employer_muc_luong_employerjoblabels_salary_job` | khác |
| `lib/features/employer/views/job_applicants_page.dart:324` | ${job.applicationsCount} hồ sơ · ${job.positionsAvailable} vị trí | `employer_job_applicationscount_ho_so_job_positionsa` | khác |
| `lib/features/employer/views/job_applicants_page.dart:325` | Hạn nộp: ${Formatters.deadlineFull(job.applicationDeadline)} | `employer_han_nop_formatters_deadlinefull_job_applic` | khác |
| `lib/features/employer/views/job_applicants_page.dart:342` | Xem tin công khai | `employer_xem_tin_cong_khai` | label |
| `lib/features/employer/views/job_applicants_page.dart:416` | Tất cả (${apps.length}) | `employer_tat_ca_apps_length` | khác |
| `lib/features/employer/widgets/applicant_card.dart:26` | Ứng viên | `admin_ung_vien` | khác |
| `lib/features/employer/widgets/applicant_card.dart:83` | Ứng tuyển: ${a.jobTitle} | `employer_ung_tuyen_a_jobtitle` | text hiển thị |
| `lib/features/employer/widgets/applicant_card.dart:94` | Nộp ${Formatters.relative(a.applicationDate)} | `employer_nop_formatters_relative_a_applicationdate` | khác |
| `lib/features/employer/widgets/applicant_card.dart:101` | Có đính kèm CV | `employer_co_dinh_kem_cv` | khác |
| `lib/features/employer/widgets/applicant_card.dart:104` | Phù hợp ${a.matchScore!.round()}/100 | `employer_phu_hop_a_matchscore_round_100` | khác |
| `lib/features/employer/widgets/applications_status_chart.dart:36` | Chưa có hồ sơ ứng tuyển nào để thống kê. | `employer_chua_co_ho_so_ung_tuyen_nao_de_thong_ke` | text hiển thị |
| `lib/features/employer/widgets/applications_status_chart.dart:105` | ${rod.toY.toInt()} hồ sơ | `employer_rod_toy_toint_ho_so` | khác |
| `lib/features/employer/widgets/category_field.dart:54` | Đang tải ngành nghề... | `admin_dang_tai_nganh_nghe` | form hint/label |
| `lib/features/employer/widgets/category_field.dart:54` | Chọn ngành nghề | `employer_chon_nganh_nghe` | form hint/label |
| `lib/features/employer/widgets/category_field.dart:105` | Chưa có ngành nghề trong hệ thống. Quản trị viên cần thêm ngành ngh… | `employer_chua_co_nganh_nghe_trong_he_thong_quan_tri` | khác |
| `lib/features/employer/widgets/category_field.dart:110` | Bạn vẫn có thể gõ tên ngành nghề mới — hệ thống sẽ tự tạo khi đăng … | `employer_ban_van_co_the_go_ten_nganh_nghe_moi_he_th` | khác |
| `lib/features/employer/widgets/category_field.dart:117` | Ngành nghề "${controller.text.trim()}" chưa có — sẽ được tạo mới kh… | `employer_nganh_nghe_controller_text_trim_chua_co_se` | khác |
| `lib/features/employer/widgets/category_field.dart:122` | Chọn từ danh sách hoặc gõ tên ngành nghề mới. | `employer_chon_tu_danh_sach_hoac_go_ten_nganh_nghe_m` | khác |
| `lib/features/employer/widgets/employer_guard.dart:37` | Đang kiểm tra phiên đăng nhập... | `employer_dang_kiem_tra_phien_dang_nhap` | khác |
| `lib/features/employer/widgets/employer_guard.dart:41` | Không thể kiểm tra phiên đăng nhập. Vui lòng thử lại. | `employer_khong_the_kiem_tra_phien_dang_nhap_vui_lon` | validation/lỗi |
| `lib/features/employer/widgets/employer_guard.dart:50` | Đang chuyển đến trang đăng nhập... | `employer_dang_chuyen_den_trang_dang_nhap` | khác |
| `lib/features/employer/widgets/employer_guard.dart:57` | Không có quyền truy cập | `employer_khong_co_quyen_truy_cap` | khác |
| `lib/features/employer/widgets/employer_guard.dart:60` | Chức năng này chỉ dành cho tài khoản nhà tuyển dụng. | `employer_chuc_nang_nay_chi_danh_cho_tai_khoan_nha_t` | title |
| `lib/features/employer/widgets/employer_job_card.dart:14` | Làm tại văn phòng | `employer_lam_tai_van_phong` | enum/option |
| `lib/features/employer/widgets/employer_job_card.dart:15` | Làm từ xa | `employer_lam_tu_xa` | enum/option |
| `lib/features/employer/widgets/employer_job_card.dart:16` | Kết hợp | `c_utils_ket_hop` | enum/option |
| `lib/features/employer/widgets/employer_job_card.dart:20` | Toàn thời gian | `c_utils_toan_thoi_gian` | enum/option |
| `lib/features/employer/widgets/employer_job_card.dart:21` | Bán thời gian | `c_utils_ban_thoi_gian` | enum/option |
| `lib/features/employer/widgets/employer_job_card.dart:22` | Hợp đồng | `c_utils_hop_dong` | enum/option |
| `lib/features/employer/widgets/employer_job_card.dart:23` | Thực tập | `c_utils_thuc_tap` | enum/option |
| `lib/features/employer/widgets/employer_job_card.dart:27` | Chờ duyệt | `admin_cho_duyet` | khác |
| `lib/features/employer/widgets/employer_job_card.dart:28` | Đang hiển thị | `employer_dang_hien_thi` | khác |
| `lib/features/employer/widgets/employer_job_card.dart:29` | Bị từ chối | `employer_bi_tu_choi` | khác |
| `lib/features/employer/widgets/employer_job_card.dart:30` | Đã đóng | `c_utils_da_dong` | khác |
| `lib/features/employer/widgets/employer_job_card.dart:35` | Đã duyệt | `employer_da_duyet` | khác |
| `lib/features/employer/widgets/employer_job_card.dart:36` | Không được duyệt | `employer_khong_duoc_duyet` | khác |
| `lib/features/employer/widgets/employer_job_card.dart:37` | Chờ duyệt | `admin_cho_duyet` | khác |
| `lib/features/employer/widgets/employer_job_card.dart:50` | Thỏa thuận | `c_utils_thoa_thuan` | khác |
| `lib/features/employer/widgets/employer_job_card.dart:135` | Trạng thái:  | `admin_trang_thai` | text hiển thị |
| `lib/features/employer/widgets/employer_job_card.dart:140` |  \| Duyệt:  | `employer_duyet` | text hiển thị |
| `lib/features/employer/widgets/employer_job_card.dart:149` | Mức lương: ${EmployerJobLabels.salary(job)} | `employer_muc_luong_employerjoblabels_salary_job` | text hiển thị |
| `lib/features/employer/widgets/employer_job_card.dart:155` | ${job.applicationsCount} hồ sơ ứng tuyển | `employer_job_applicationscount_ho_so_ung_tuyen` | khác |
| `lib/features/employer/widgets/employer_job_card.dart:156` | Hạn nộp: ${Formatters.deadlineFull(job.applicationDeadline)} | `employer_han_nop_formatters_deadlinefull_job_applic` | khác |
| `lib/features/employer/widgets/employer_job_card.dart:195` | Xem ứng viên | `employer_xem_ung_vien` | label |
| `lib/features/employer/widgets/employer_job_card.dart:207` | Đóng tin | `employer_dong_tin` | text hiển thị |
| `lib/features/employer/widgets/employer_job_card.dart:217` | Mở tin | `employer_mo_tin` | text hiển thị |
| `lib/features/employer/widgets/form_step_header.dart:27` | Bước ${current + 1}/${titles.length} | `employer_buoc_current_1_titles_length` | text hiển thị |
| `lib/features/employer/widgets/job_form_steps.dart:80` | Tên vị trí tuyển dụng | `employer_ten_vi_tri_tuyen_dung` | label |
| `lib/features/employer/widgets/job_form_steps.dart:83` | Từ 3 đến 150 ký tự. | `employer_tu_3_den_150_ky_tu` | khác |
| `lib/features/employer/widgets/job_form_steps.dart:90` | Ví dụ: Lập trình viên Frontend | `employer_vi_du_lap_trinh_vien_frontend` | form hint/label |
| `lib/features/employer/widgets/job_form_steps.dart:96` | Ngành nghề | `admin_nganh_nghe` | label |
| `lib/features/employer/widgets/job_form_steps.dart:107` | Mô tả công việc | `c_utils_mo_ta_cong_viec` | label |
| `lib/features/employer/widgets/job_form_steps.dart:110` | Tối thiểu 10 ký tự. Mỗi dòng là một ý — sẽ hiển thị dạng gạch đầu d… | `employer_toi_thieu_10_ky_tu_moi_dong_la_mot_y_se_hi` | khác |
| `lib/features/employer/widgets/job_form_steps.dart:118` | Mô tả nhiệm vụ, trách nhiệm và yêu cầu chính của công việc. | `employer_mo_ta_nhiem_vu_trach_nhiem_va_yeu_cau_chin` | form hint/label |
| `lib/features/employer/widgets/job_form_steps.dart:125` | Yêu cầu ứng viên | `employer_yeu_cau_ung_vien` | label |
| `lib/features/employer/widgets/job_form_steps.dart:126` | Mỗi dòng một yêu cầu (tuỳ chọn). | `employer_moi_dong_mot_yeu_cau_tuy_chon` | khác |
| `lib/features/employer/widgets/job_form_steps.dart:133` | Ví dụ: Tối thiểu 2 năm kinh nghiệm ReactJS\nTiếng Anh đọc hiểu tài … | `employer_vi_du_toi_thieu_2_nam_kinh_nghiem_reactjs` | form hint/label |
| `lib/features/employer/widgets/job_form_steps.dart:138` | Quyền lợi | `employer_quyen_loi` | label |
| `lib/features/employer/widgets/job_form_steps.dart:139` | Mỗi dòng một quyền lợi (tuỳ chọn). | `employer_moi_dong_mot_quyen_loi_tuy_chon` | khác |
| `lib/features/employer/widgets/job_form_steps.dart:146` | Ví dụ: Thưởng tháng 13\nBảo hiểm sức khoẻ cao cấp | `employer_vi_du_thuong_thang_13_nbao_hiem_suc_khoe_c` | form hint/label |
| `lib/features/employer/widgets/job_form_steps.dart:152` | Thời gian làm việc | `employer_thoi_gian_lam_viec` | label |
| `lib/features/employer/widgets/job_form_steps.dart:156` | Ví dụ: Thứ 2 - Thứ 6, 9:00 - 18:00 | `employer_vi_du_thu_2_thu_6_9_00_18_00` | form hint/label |
| `lib/features/employer/widgets/job_form_steps.dart:160` | Yêu cầu bằng cấp | `employer_yeu_cau_bang_cap` | label |
| `lib/features/employer/widgets/job_form_steps.dart:196` | Mức lương thoả thuận | `employer_muc_luong_thoa_thuan` | title |
| `lib/features/employer/widgets/job_form_steps.dart:198` | Ẩn khoảng lương, hiển thị "Thoả thuận" trên tin. | `employer_an_khoang_luong_hien_thi_thoa_thuan_tren_t` | title |
| `lib/features/employer/widgets/job_form_steps.dart:203` | Lương tối thiểu | `employer_luong_toi_thieu` | label |
| `lib/features/employer/widgets/job_form_steps.dart:218` | Lương tối đa | `employer_luong_toi_da` | label |
| `lib/features/employer/widgets/job_form_steps.dart:235` | Đơn vị tiền tệ | `employer_don_vi_tien_te` | label |
| `lib/features/employer/widgets/job_form_steps.dart:237` | Mã 3 chữ cái, mặc định VND. | `employer_ma_3_chu_cai_mac_dinh_vnd` | khác |
| `lib/features/employer/widgets/job_form_steps.dart:251` | Kỳ trả lương | `employer_ky_tra_luong` | label |
| `lib/features/employer/widgets/job_form_steps.dart:256` | Theo giờ | `employer_theo_gio` | enum/option |
| `lib/features/employer/widgets/job_form_steps.dart:257` | Theo tháng | `employer_theo_thang` | enum/option |
| `lib/features/employer/widgets/job_form_steps.dart:258` | Theo năm | `employer_theo_nam` | enum/option |
| `lib/features/employer/widgets/job_form_steps.dart:266` | Địa điểm làm việc | `c_utils_dia_diem_lam_viec` | label |
| `lib/features/employer/widgets/job_form_steps.dart:273` | Ví dụ: 120 Yên Lãng | `employer_vi_du_120_yen_lang` | form hint/label |
| `lib/features/employer/widgets/job_form_steps.dart:277` | Thành phố | `employer_thanh_pho` | label |
| `lib/features/employer/widgets/job_form_steps.dart:289` | Hình thức làm việc | `employer_hinh_thuc_lam_viec` | label |
| `lib/features/employer/widgets/job_form_steps.dart:294` | Làm tại văn phòng | `employer_lam_tai_van_phong` | enum/option |
| `lib/features/employer/widgets/job_form_steps.dart:295` | Làm từ xa | `employer_lam_tu_xa` | enum/option |
| `lib/features/employer/widgets/job_form_steps.dart:296` | Kết hợp | `c_utils_ket_hop` | enum/option |
| `lib/features/employer/widgets/job_form_steps.dart:302` | Loại hình công việc | `employer_loai_hinh_cong_viec` | label |
| `lib/features/employer/widgets/job_form_steps.dart:313` | Kinh nghiệm | `employer_kinh_nghiem` | label |
| `lib/features/employer/widgets/job_form_steps.dart:322` | Số lượng tuyển | `employer_so_luong_tuyen` | label |
| `lib/features/employer/widgets/job_form_steps.dart:336` | Hạn nộp hồ sơ | `employer_han_nop_ho_so` | label |
| `lib/features/employer/widgets/job_form_steps.dart:385` | Hà Nội | `employer_ha_noi` | form hint/label |
| `lib/features/employer/widgets/job_form_steps.dart:441` | Chọn hạn nộp hồ sơ | `employer_chon_han_nop_ho_so` | khác |
| `lib/features/employer/widgets/job_form_steps.dart:453` | Bỏ chọn | `employer_bo_chon` | tooltip |
| `lib/features/employer/widgets/job_form_steps.dart:459` | Chọn ngày | `employer_chon_ngay` | khác |
| `lib/features/employer/widgets/job_form_steps.dart:483` | Kỹ năng yêu cầu | `employer_ky_nang_yeu_cau` | label |
| `lib/features/employer/widgets/job_preview_panel.dart:34` | Xem trước | `employer_xem_truoc` | text hiển thị |
| `lib/features/employer/widgets/job_preview_panel.dart:43` | Thay đổi sẽ áp dụng ngay cho tin hiện tại; trạng thái duyệt được gi… | `employer_thay_doi_se_ap_dung_ngay_cho_tin_hien_tai` | khác |
| `lib/features/employer/widgets/job_preview_panel.dart:45` | Tin tuyển dụng mới sẽ ở trạng thái chờ duyệt trước khi được hiển th… | `employer_tin_tuyen_dung_moi_se_o_trang_thai_cho_duy` | khác |
| `lib/features/employer/widgets/job_preview_panel.dart:46` | Tin tuyển dụng sẽ được hiển thị công khai ngay sau khi đăng. | `employer_tin_tuyen_dung_se_duoc_hien_thi_cong_khai` | khác |
| `lib/features/employer/widgets/job_preview_panel.dart:57` | Ngành nghề | `admin_nganh_nghe` | khác |
| `lib/features/employer/widgets/job_preview_panel.dart:57` | Chưa chọn | `employer_chua_chon` | khác |
| `lib/features/employer/widgets/job_preview_panel.dart:58` | Hình thức | `employer_hinh_thuc` | khác |
| `lib/features/employer/widgets/job_preview_panel.dart:59` | Kinh nghiệm | `employer_kinh_nghiem` | khác |
| `lib/features/employer/widgets/job_preview_panel.dart:60` | Số lượng tuyển | `employer_so_luong_tuyen` | khác |
| `lib/features/employer/widgets/job_preview_panel.dart:61` | Hạn nộp hồ sơ | `employer_han_nop_ho_so` | khác |
| `lib/features/employer/widgets/job_preview_panel.dart:62` | Mặc định theo hệ thống | `employer_mac_dinh_theo_he_thong` | khác |
| `lib/features/employer/widgets/job_preview_panel.dart:63` | Kỹ năng | `admin_ky_nang_2` | khác |
| `lib/features/employer/widgets/job_preview_panel.dart:63` | Chưa có | `employer_chua_co` | khác |
| `lib/features/employer/widgets/job_preview_panel.dart:64` | Thời gian làm việc | `employer_thoi_gian_lam_viec` | khác |
| `lib/features/employer/widgets/job_preview_panel.dart:65` | Bằng cấp | `employer_bang_cap` | khác |
| `lib/features/employer/widgets/job_preview_panel.dart:66` | Mô tả | `employer_mo_ta` | khác |
| `lib/features/employer/widgets/job_preview_panel.dart:66` | ${desc.moTaCongViec.length} ý · Yêu cầu ${desc.yeuCauUngVien.length… | `employer_desc_motacongviec_length_y_yeu_cau_desc_ye` | khác |
| `lib/features/employer/widgets/skills_input.dart:112` | Bỏ kỹ năng $s | `employer_bo_ky_nang_s` | validation/lỗi |
| `lib/features/employer/widgets/skills_input.dart:142` | Tìm kỹ năng, hoặc gõ kỹ năng mới rồi Enter để thêm | `employer_tim_ky_nang_hoac_go_ky_nang_moi_roi_enter` | form hint/label |
| `lib/features/employer/widgets/skills_input.dart:167` | Đang tải kỹ năng... | `admin_dang_tai_ky_nang` | text hiển thị |
| `lib/features/employer/widgets/skills_input.dart:201` |  (kỹ năng khác) | `employer_ky_nang_khac` | text hiển thị |
| `lib/features/employer/widgets/skills_input.dart:213` | Không tìm thấy kỹ năng phù hợp. | `employer_khong_tim_thay_ky_nang_phu_hop` | text hiển thị |
| `lib/features/employer/widgets/skills_input.dart:248` | Đã chọn ${widget.selected.length}/${widget.maxSkills} kỹ năng. Nếu … | `employer_da_chon_widget_selected_length_widget_maxs` | khác |
| `lib/features/employer/widgets/skills_input.dart:249` | gõ tên rồi Enter (hoặc bấm "Thêm") để tự tạo tag khác. | `employer_go_ten_roi_enter_hoac_bam_them_de_tu_tao_t` | khác |

### `features/home` (74)

| Vị trí | Chuỗi | Key đề xuất | Ngữ cảnh |
|---|---|---|---|
| `lib/features/home/data/home_repository.dart:69` | Doanh nghiệp đã xác thực | `home_doanh_nghiep_da_xac_thuc` | khác |
| `lib/features/home/data/home_repository.dart:70` | Việt Nam | `home_viet_nam` | khác |
| `lib/features/home/data/home_repository.dart:72` | Đang cập nhật quy mô | `home_dang_cap_nhat_quy_mo` | khác |
| `lib/features/home/viewmodels/home_providers.dart:34` | Công nghệ thông tin | `c_config_cong_nghe_thong_tin` | khác |
| `lib/features/home/viewmodels/home_providers.dart:34` | công nghệ | `home_cong_nghe` | khác |
| `lib/features/home/viewmodels/home_providers.dart:34` | phần mềm | `home_phan_mem` | khác |
| `lib/features/home/viewmodels/home_providers.dart:34` | lập trình | `home_lap_trinh` | khác |
| `lib/features/home/viewmodels/home_providers.dart:34` | kỹ sư | `home_ky_su` | khác |
| `lib/features/home/viewmodels/home_providers.dart:37` | Tài chính – Kế toán | `c_config_tai_chinh_ke_toan` | khác |
| `lib/features/home/viewmodels/home_providers.dart:37` | kế toán | `home_ke_toan` | khác |
| `lib/features/home/viewmodels/home_providers.dart:37` | tài chính | `home_tai_chinh` | khác |
| `lib/features/home/viewmodels/home_providers.dart:37` | ngân hàng | `home_ngan_hang` | khác |
| `lib/features/home/viewmodels/home_providers.dart:37` | tín dụng | `home_tin_dung` | khác |
| `lib/features/home/viewmodels/home_providers.dart:38` | Nhân sự | `c_config_nhan_su` | khác |
| `lib/features/home/viewmodels/home_providers.dart:38` | nhân sự | `home_nhan_su` | khác |
| `lib/features/home/viewmodels/home_providers.dart:47` | Công nghệ thông tin | `c_config_cong_nghe_thong_tin` | khác |
| `lib/features/home/views/forbidden_page.dart:25` | KHÔNG CÓ QUYỀN TRUY CẬP | `home_khong_co_quyen_truy_cap` | khác |
| `lib/features/home/views/forbidden_page.dart:35` | Bạn không thể truy cập trang này | `home_ban_khong_the_truy_cap_trang_nay` | khác |
| `lib/features/home/views/forbidden_page.dart:45` | Chức năng này chỉ dành cho tài khoản có quyền phù hợp. | `home_chuc_nang_nay_chi_danh_cho_tai_khoan_co_qu` | khác |
| `lib/features/home/views/not_found_page.dart:33` | Không tìm thấy trang | `home_khong_tim_thay_trang` | khác |
| `lib/features/home/views/not_found_page.dart:45` | Trang bạn đang tìm có thể đã bị di chuyển hoặc không còn tồn tại. | `home_trang_ban_dang_tim_co_the_da_bi_di_chuyen` | khác |
| `lib/features/home/views/not_found_page.dart:52` | Về trang chủ | `home_ve_trang_chu` | text hiển thị |
| `lib/features/home/widgets/career_resources_section.dart:26` | Cẩm nang nghề nghiệp | `home_cam_nang_nghe_nghiep` | khác |
| `lib/features/home/widgets/career_resources_section.dart:27` | Kiến thức giúp bạn phát triển sự nghiệp | `home_kien_thuc_giup_ban_phat_trien_su_nghiep` | title |
| `lib/features/home/widgets/career_resources_section.dart:29` | Những bài viết và hướng dẫn thực tế về viết CV, phỏng vấn và phát t… | `home_nhung_bai_viet_va_huong_dan_thuc_te_ve_vie` | khác |
| `lib/features/home/widgets/career_resources_section.dart:30` | Xem tất cả bài viết | `home_xem_tat_ca_bai_viet` | khác |
| `lib/features/home/widgets/company_logo_grid.dart:31` | Được tin dùng bởi các doanh nghiệp hàng đầu tại Việt Nam | `home_duoc_tin_dung_boi_cac_doanh_nghiep_hang_da` | khác |
| `lib/features/home/widgets/cta_band.dart:50` | Sẵn sàng tìm kiếm cơ hội nghề nghiệp tiếp theo? | `home_san_sang_tim_kiem_co_hoi_nghe_nghiep_tiep` | khác |
| `lib/features/home/widgets/cta_band.dart:62` | Tải CV lên hôm nay để AI phân tích hồ sơ và gợi ý những việc làm ph… | `home_tai_cv_len_hom_nay_de_ai_phan_tich_ho_so_v` | khác |
| `lib/features/home/widgets/cta_band.dart:85` | Tải CV miễn phí | `home_tai_cv_mien_phi` | label |
| `lib/features/home/widgets/cta_band.dart:97` | Đăng tuyển dụng | `home_dang_tuyen_dung` | text hiển thị |
| `lib/features/home/widgets/featured_jobs_section.dart:41` | Việc làm nổi bật | `home_viec_lam_noi_bat` | khác |
| `lib/features/home/widgets/featured_jobs_section.dart:42` | Cơ hội việc làm hàng đầu dành cho bạn | `home_co_hoi_viec_lam_hang_dau_danh_cho_ban` | title |
| `lib/features/home/widgets/featured_jobs_section.dart:44` | Những vị trí đang được tuyển dụng gấp, được AI đánh giá phù hợp với… | `home_nhung_vi_tri_dang_duoc_tuyen_dung_gap_duoc` | khác |
| `lib/features/home/widgets/featured_jobs_section.dart:45` | Xem tất cả việc làm | `home_xem_tat_ca_viec_lam` | khác |
| `lib/features/home/widgets/featured_jobs_section.dart:70` | Đang tải việc làm nổi bật... | `home_dang_tai_viec_lam_noi_bat` | label |
| `lib/features/home/widgets/featured_jobs_section.dart:90` | Chưa có việc làm nào được đăng. | `home_chua_co_viec_lam_nao_duoc_dang` | title |
| `lib/features/home/widgets/featured_jobs_section.dart:90` | Chưa có việc làm phù hợp trong nhóm này. | `home_chua_co_viec_lam_phu_hop_trong_nhom_nay` | title |
| `lib/features/home/widgets/featured_jobs_section.dart:91` | Thử chọn một nhóm ngành khác hoặc xem tất cả việc làm. | `home_thu_chon_mot_nhom_nganh_khac_hoac_xem_tat` | title |
| `lib/features/home/widgets/featured_jobs_section.dart:95` | Xem tất cả việc làm | `home_xem_tat_ca_viec_lam` | text hiển thị |
| `lib/features/home/widgets/featured_jobs_section.dart:100` | Tất cả | `c_config_tat_ca` | text hiển thị |
| `lib/features/home/widgets/featured_jobs_section.dart:144` | Chỉ tài khoản ứng viên mới có thể lưu việc làm. | `home_chi_tai_khoan_ung_vien_moi_co_the_luu_viec` | validation/lỗi |
| `lib/features/home/widgets/hero_search_bar.dart:64` | Phổ biến: | `home_pho_bien` | text hiển thị |
| `lib/features/home/widgets/hero_search_bar.dart:97` | Tìm kiếm | `admin_tim_kiem` | text hiển thị |
| `lib/features/home/widgets/hero_search_bar.dart:114` | Tìm kiếm | `admin_tim_kiem` | label |
| `lib/features/home/widgets/hero_search_bar.dart:138` | Tìm theo vị trí, kỹ năng hoặc tên công ty... | `home_tim_theo_vi_tri_ky_nang_hoac_ten_cong_ty` | form hint/label |
| `lib/features/home/widgets/hero_search_bar.dart:162` | Tất cả địa điểm | `home_tat_ca_dia_diem` | text hiển thị |
| `lib/features/home/widgets/hero_section.dart:92` | Nền tảng tuyển dụng ứng dụng AI | `home_nen_tang_tuyen_dung_ung_dung_ai` | label |
| `lib/features/home/widgets/hero_section.dart:98` | đúng công việc | `home_dung_cong_viec` | text hiển thị |
| `lib/features/home/widgets/hero_section.dart:99` |  phù hợp với năng lực của bạn. | `home_phu_hop_voi_nang_luc_cua_ban` | text hiển thị |
| `lib/features/home/widgets/hero_section.dart:114` | JobHub ứng dụng trí tuệ nhân tạo để phân tích CV, hiểu rõ điểm mạnh… | `home_jobhub_ung_dung_tri_tue_nhan_tao_de_phan_t` | khác |
| `lib/features/home/widgets/hero_section.dart:115` | những cơ hội nghề nghiệp phù hợp nhất — giúp bạn ứng tuyển nhanh và… | `home_nhung_co_hoi_nghe_nghiep_phu_hop_nhat_giup` | khác |
| `lib/features/home/widgets/hero_section.dart:134` | Tải CV của bạn | `home_tai_cv_cua_ban` | label |
| `lib/features/home/widgets/hero_section.dart:141` | Khám phá việc làm | `applications_kham_pha_viec_lam` | text hiển thị |
| `lib/features/home/widgets/hero_section.dart:216` |  ứng viên tin tưởng | `home_ung_vien_tin_tuong` | text hiển thị |
| `lib/features/home/widgets/hero_section.dart:267` | độ chính xác gợi ý | `home_do_chinh_xac_goi_y` | label |
| `lib/features/home/widgets/hero_section.dart:279` | doanh nghiệp đối tác | `home_doanh_nghiep_doi_tac` | label |
| `lib/features/home/widgets/testimonials_section.dart:24` | Câu chuyện thành công | `home_cau_chuyen_thanh_cong` | khác |
| `lib/features/home/widgets/testimonials_section.dart:25` | Ứng viên nói gì về JobHub | `home_ung_vien_noi_gi_ve_jobhub` | title |
| `lib/features/home/widgets/testimonials_section.dart:27` | Hàng trăm nghìn ứng viên đã tìm được công việc phù hợp nhờ JobHub. … | `home_hang_tram_nghin_ung_vien_da_tim_duoc_cong` | khác |
| `lib/features/home/widgets/testimonials_section.dart:67` | Đánh giá ${t.rating} trên 5 sao | `home_danh_gia_t_rating_tren_5_sao` | label |
| `lib/features/home/widgets/top_companies_section.dart:31` | Doanh nghiệp hàng đầu | `home_doanh_nghiep_hang_dau` | khác |
| `lib/features/home/widgets/top_companies_section.dart:32` | Làm việc tại những công ty tốt nhất | `home_lam_viec_tai_nhung_cong_ty_tot_nhat` | title |
| `lib/features/home/widgets/top_companies_section.dart:34` | Khám phá các doanh nghiệp uy tín đang mở rộng đội ngũ và tìm môi tr… | `home_kham_pha_cac_doanh_nghiep_uy_tin_dang_mo_r` | khác |
| `lib/features/home/widgets/top_companies_section.dart:42` | Đang tải doanh nghiệp... | `home_dang_tai_doanh_nghiep` | label |
| `lib/features/home/widgets/top_companies_section.dart:201` |  việc làm đang tuyển | `home_viec_lam_dang_tuyen` | text hiển thị |
| `lib/features/home/widgets/top_companies_section.dart:215` | Xem hồ sơ công ty | `home_xem_ho_so_cong_ty` | text hiển thị |
| `lib/features/home/widgets/why_jobhub_section.dart:25` | Vì sao chọn JobHub | `home_vi_sao_chon_jobhub` | khác |
| `lib/features/home/widgets/why_jobhub_section.dart:26` | Mọi thứ bạn cần cho một hành trình nghề nghiệp thành công | `home_moi_thu_ban_can_cho_mot_hanh_trinh_nghe_ng` | title |
| `lib/features/home/widgets/why_jobhub_section.dart:28` | JobHub kết hợp công nghệ AI và mạng lưới doanh nghiệp rộng lớn để m… | `home_jobhub_ket_hop_cong_nghe_ai_va_mang_luoi_d` | khác |
| `lib/features/home/widgets/workflow_section.dart:104` | CV của bạn đã được phân tích | `home_cv_cua_ban_da_duoc_phan_tich` | khác |
| `lib/features/home/widgets/workflow_section.dart:109` | Kỹ năng & kinh nghiệm được trích xuất tự động | `home_ky_nang_kinh_nghiem_duoc_trich_xuat_tu_don` | khác |
| `lib/features/home/widgets/workflow_section.dart:138` | Hành trình từ CV đến cơ hội việc làm | `home_hanh_trinh_tu_cv_den_co_hoi_viec_lam` | title |
| `lib/features/home/widgets/workflow_section.dart:140` | Chỉ với một lần tải CV, JobHub tự động phân tích, trích xuất thông … | `home_chi_voi_mot_lan_tai_cv_jobhub_tu_dong_phan` | khác |

### `features/jobs` (138)

| Vị trí | Chuỗi | Key đề xuất | Ngữ cảnh |
|---|---|---|---|
| `lib/features/jobs/data/saved_jobs_repository.dart:83` | Công ty chưa cập nhật | `c_utils_cong_ty_chua_cap_nhat` | khác |
| `lib/features/jobs/data/saved_jobs_repository.dart:84` | Tin tuyển dụng chưa có tiêu đề | `admin_tin_tuyen_dung_chua_co_tieu_de` | khác |
| `lib/features/jobs/viewmodels/jobs_search_viewmodel.dart:20` | Cả hai | `jobs_ca_hai` | khác |
| `lib/features/jobs/viewmodels/jobs_search_viewmodel.dart:21` | Tên việc làm | `jobs_ten_viec_lam` | khác |
| `lib/features/jobs/viewmodels/jobs_search_viewmodel.dart:22` | Tên công ty | `employer_ten_cong_ty` | khác |
| `lib/features/jobs/viewmodels/jobs_search_viewmodel.dart:48` | Không yêu cầu | `c_services_khong_yeu_cau` | enum/option |
| `lib/features/jobs/viewmodels/jobs_search_viewmodel.dart:49` | Dưới 1 năm | `jobs_duoi_1_nam` | enum/option |
| `lib/features/jobs/viewmodels/jobs_search_viewmodel.dart:50` | 1 - 2 năm | `jobs_1_2_nam` | enum/option |
| `lib/features/jobs/viewmodels/jobs_search_viewmodel.dart:51` | 2 - 4 năm | `jobs_2_4_nam` | enum/option |
| `lib/features/jobs/viewmodels/jobs_search_viewmodel.dart:52` | 5 năm | `jobs_5_nam` | enum/option |
| `lib/features/jobs/viewmodels/jobs_search_viewmodel.dart:53` | Trên 5 năm | `jobs_tren_5_nam` | enum/option |
| `lib/features/jobs/viewmodels/jobs_search_viewmodel.dart:57` | Tại văn phòng | `c_utils_tai_van_phong` | enum/option |
| `lib/features/jobs/viewmodels/jobs_search_viewmodel.dart:59` | Từ xa (Remote) | `jobs_tu_xa_remote` | enum/option |
| `lib/features/jobs/viewmodels/jobs_search_viewmodel.dart:64` | Toàn thời gian | `c_utils_toan_thoi_gian` | enum/option |
| `lib/features/jobs/viewmodels/jobs_search_viewmodel.dart:65` | Bán thời gian | `c_utils_ban_thoi_gian` | enum/option |
| `lib/features/jobs/viewmodels/jobs_search_viewmodel.dart:66` | Thực tập | `c_utils_thuc_tap` | enum/option |
| `lib/features/jobs/viewmodels/jobs_search_viewmodel.dart:70` | Nhân viên | `jobs_nhan_vien` | enum/option |
| `lib/features/jobs/viewmodels/jobs_search_viewmodel.dart:70` | Nhân viên | `jobs_nhan_vien` | enum/option |
| `lib/features/jobs/viewmodels/jobs_search_viewmodel.dart:71` | Trưởng nhóm | `jobs_truong_nhom` | enum/option |
| `lib/features/jobs/viewmodels/jobs_search_viewmodel.dart:71` | Trưởng nhóm | `jobs_truong_nhom` | enum/option |
| `lib/features/jobs/viewmodels/jobs_search_viewmodel.dart:72` | Trưởng phòng | `jobs_truong_phong` | enum/option |
| `lib/features/jobs/viewmodels/jobs_search_viewmodel.dart:72` | Trưởng / Phó phòng | `jobs_truong_pho_phong` | enum/option |
| `lib/features/jobs/viewmodels/jobs_search_viewmodel.dart:73` | Quản lý | `jobs_quan_ly` | enum/option |
| `lib/features/jobs/viewmodels/jobs_search_viewmodel.dart:73` | Quản lý / Giám sát | `jobs_quan_ly_giam_sat` | enum/option |
| `lib/features/jobs/viewmodels/jobs_search_viewmodel.dart:74` | Giám đốc | `jobs_giam_doc` | enum/option |
| `lib/features/jobs/viewmodels/jobs_search_viewmodel.dart:74` | Giám đốc / Phó giám đốc | `jobs_giam_doc_pho_giam_doc` | enum/option |
| `lib/features/jobs/viewmodels/jobs_search_viewmodel.dart:75` | Thực tập sinh | `c_utils_thuc_tap_sinh` | enum/option |
| `lib/features/jobs/viewmodels/jobs_search_viewmodel.dart:75` | Thực tập sinh | `c_utils_thuc_tap_sinh` | enum/option |
| `lib/features/jobs/viewmodels/jobs_search_viewmodel.dart:301` | Chưa cập nhật | `c_utils_chua_cap_nhat` | khác |
| `lib/features/jobs/viewmodels/jobs_search_viewmodel.dart:306` | Ngành nghề khác | `jobs_nganh_nghe_khac` | khác |
| `lib/features/jobs/viewmodels/saved_jobs_provider.dart:42` | Vui lòng đăng nhập để lưu tin. | `jobs_vui_long_dang_nhap_de_luu_tin` | validation/lỗi |
| `lib/features/jobs/viewmodels/saved_jobs_provider.dart:45` | Chỉ tài khoản ứng viên mới có thể lưu tin. | `jobs_chi_tai_khoan_ung_vien_moi_co_the_luu_tin` | validation/lỗi |
| `lib/features/jobs/viewmodels/saved_jobs_provider.dart:61` | Vui lòng đăng nhập để lưu tin. | `jobs_vui_long_dang_nhap_de_luu_tin` | validation/lỗi |
| `lib/features/jobs/views/company_detail_page.dart:40` | Đang tải thông tin công ty... | `jobs_dang_tai_thong_tin_cong_ty` | khác |
| `lib/features/jobs/views/company_detail_page.dart:52` | Không tìm thấy công ty. | `jobs_khong_tim_thay_cong_ty` | validation/lỗi |
| `lib/features/jobs/views/company_detail_page.dart:82` | Lỗi hệ thống | `admin_loi_he_thong` | khác |
| `lib/features/jobs/views/company_detail_page.dart:98` | Thử lại | `admin_thu_lai` | label |
| `lib/features/jobs/views/company_detail_page.dart:143` | HỒ SƠ CÔNG TY | `jobs_ho_so_cong_ty` | khác |
| `lib/features/jobs/views/company_detail_page.dart:164` | Chưa cập nhật địa điểm | `admin_chua_cap_nhat_dia_diem` | khác |
| `lib/features/jobs/views/company_detail_page.dart:189` | Số điện thoại | `employer_so_dien_thoai` | label |
| `lib/features/jobs/views/company_detail_page.dart:191` | Chưa cập nhật | `c_utils_chua_cap_nhat` | khác |
| `lib/features/jobs/views/company_detail_page.dart:199` | Chưa cập nhật | `c_utils_chua_cap_nhat` | khác |
| `lib/features/jobs/views/company_detail_page.dart:208` | Người liên hệ | `employer_nguoi_lien_he` | label |
| `lib/features/jobs/views/company_detail_page.dart:210` | Chưa cập nhật | `c_utils_chua_cap_nhat` | khác |
| `lib/features/jobs/views/company_detail_page.dart:217` | Trạng thái | `admin_trang_thai_2` | label |
| `lib/features/jobs/views/company_detail_page.dart:219` | Đã xác minh | `admin_da_xac_minh` | khác |
| `lib/features/jobs/views/company_detail_page.dart:220` | Chưa xác minh | `jobs_chua_xac_minh` | khác |
| `lib/features/jobs/views/company_detail_page.dart:238` | Giới thiệu công ty | `employer_gioi_thieu_cong_ty` | khác |
| `lib/features/jobs/views/company_detail_page.dart:249` | Công ty chưa cập nhật phần giới thiệu. | `jobs_cong_ty_chua_cap_nhat_phan_gioi_thieu` | khác |
| `lib/features/jobs/views/company_detail_page.dart:271` | Việc làm đang tuyển | `jobs_viec_lam_dang_tuyen` | khác |
| `lib/features/jobs/views/company_detail_page.dart:291` | Công ty hiện chưa có tin tuyển dụng đang mở. | `jobs_cong_ty_hien_chua_co_tin_tuyen_dung_dang_m` | khác |
| `lib/features/jobs/views/company_detail_page.dart:380` | Chưa cập nhật địa điểm | `admin_chua_cap_nhat_dia_diem` | khác |
| `lib/features/jobs/views/job_detail_page.dart:85` | Thử lại | `admin_thu_lai` | label |
| `lib/features/jobs/views/job_detail_page.dart:111` | Không tìm thấy việc làm | `jobs_khong_tim_thay_viec_lam` | khác |
| `lib/features/jobs/views/job_detail_page.dart:121` | Việc làm bạn tìm không tồn tại hoặc đã bị đóng. | `jobs_viec_lam_ban_tim_khong_ton_tai_hoac_da_bi` | khác |
| `lib/features/jobs/views/job_detail_page.dart:150` | Trang chủ | `admin_trang_chu` | enum/option |
| `lib/features/jobs/views/job_detail_page.dart:151` | Việc làm | `admin_viec_lam` | enum/option |
| `lib/features/jobs/views/job_detail_page.dart:242` | Đang tải chi tiết tin tuyển dụng... | `jobs_dang_tai_chi_tiet_tin_tuyen_dung` | khác |
| `lib/features/jobs/views/job_detail_page.dart:260` | Quay lại danh sách | `jobs_quay_lai_danh_sach` | label |
| `lib/features/jobs/views/jobs_search_page.dart:155` | Đang tải thêm các tin tuyển dụng đã được quản trị viên duyệt... | `jobs_dang_tai_them_cac_tin_tuyen_dung_da_duoc_q` | khác |
| `lib/features/jobs/views/jobs_search_page.dart:160` | ${state.error} Trang hiện vẫn đang hiển thị dữ liệu mẫu. | `jobs_state_error_trang_hien_van_dang_hien_thi_d` | validation/lỗi |
| `lib/features/jobs/views/jobs_search_page.dart:270` | Không tìm thấy việc làm phù hợp | `jobs_khong_tim_thay_viec_lam_phu_hop` | khác |
| `lib/features/jobs/views/jobs_search_page.dart:282` | Thử thay đổi từ khoá hoặc bỏ bớt bộ lọc để mở rộng kết quả tìm kiếm. | `jobs_thu_thay_doi_tu_khoa_hoac_bo_bot_bo_loc_de` | khác |
| `lib/features/jobs/views/jobs_search_page.dart:292` | Xoá bộ lọc | `jobs_xoa_bo_loc` | button |
| `lib/features/jobs/views/saved_jobs_page.dart:28` | Việc đã lưu | `jobs_viec_da_luu` | title |
| `lib/features/jobs/views/saved_jobs_page.dart:30` | Đang tải việc làm đã lưu... | `jobs_dang_tai_viec_lam_da_luu` | label |
| `lib/features/jobs/views/saved_jobs_page.dart:39` | Chưa có việc làm nào được lưu | `jobs_chua_co_viec_lam_nao_duoc_luu` | title |
| `lib/features/jobs/views/saved_jobs_page.dart:41` | Nhấn biểu tượng đánh dấu trên tin tuyển dụng để lưu lại và xem sau. | `jobs_nhan_bieu_tuong_danh_dau_tren_tin_tuyen_du` | khác |
| `lib/features/jobs/views/saved_jobs_page.dart:45` | Tìm việc làm | `jobs_tim_viec_lam` | label |
| `lib/features/jobs/views/saved_jobs_page.dart:83` | Đã bỏ lưu tin tuyển dụng. | `jobs_da_bo_luu_tin_tuyen_dung` | khác |
| `lib/features/jobs/views/saved_jobs_page.dart:96` | Đã bỏ lưu tin tuyển dụng. | `jobs_da_bo_luu_tin_tuyen_dung` | khác |
| `lib/features/jobs/views/saved_jobs_page.dart:119` | ${visible.length} việc làm đã lưu · vuốt sang trái để bỏ lưu | `jobs_visible_length_viec_lam_da_luu_vuot_sang_t` | khác |
| `lib/features/jobs/views/saved_jobs_page.dart:148` | Bỏ lưu | `jobs_bo_luu` | khác |
| `lib/features/jobs/widgets/job_detail_sections.dart:39` | Không thể mở liên kết website. | `jobs_khong_the_mo_lien_ket_website` | validation/lỗi |
| `lib/features/jobs/widgets/job_detail_sections.dart:114` | Nổi bật | `jobs_noi_bat` | label |
| `lib/features/jobs/widgets/job_detail_sections.dart:141` | Mức lương | `jobs_muc_luong` | khác |
| `lib/features/jobs/widgets/job_detail_sections.dart:147` | Địa điểm | `applications_dia_diem` | khác |
| `lib/features/jobs/widgets/job_detail_sections.dart:152` | Kinh nghiệm | `employer_kinh_nghiem` | khác |
| `lib/features/jobs/widgets/job_detail_sections.dart:157` | Hạn nộp | `jobs_han_nop` | khác |
| `lib/features/jobs/widgets/job_detail_sections.dart:243` | Kỹ năng / Chuyên môn | `jobs_ky_nang_chuyen_mon` | khác |
| `lib/features/jobs/widgets/job_detail_sections.dart:277` | Chi tiết công việc đang được cập nhật. | `jobs_chi_tiet_cong_viec_dang_duoc_cap_nhat` | khác |
| `lib/features/jobs/widgets/job_detail_sections.dart:287` | Mô tả công việc | `c_utils_mo_ta_cong_viec` | title |
| `lib/features/jobs/widgets/job_detail_sections.dart:293` | Yêu cầu ứng viên | `employer_yeu_cau_ung_vien` | title |
| `lib/features/jobs/widgets/job_detail_sections.dart:299` | Quyền lợi | `employer_quyen_loi` | title |
| `lib/features/jobs/widgets/job_detail_sections.dart:308` | Thời gian làm việc | `employer_thoi_gian_lam_viec` | title |
| `lib/features/jobs/widgets/job_detail_sections.dart:313` | Cách thức ứng tuyển | `jobs_cach_thuc_ung_tuyen` | title |
| `lib/features/jobs/widgets/job_detail_sections.dart:314` | Ứng viên nộp hồ sơ trực tuyến bằng cách bấm  | `jobs_ung_vien_nop_ho_so_truc_tuyen_bang_cach_ba` | khác |
| `lib/features/jobs/widgets/job_detail_sections.dart:315` | Ứng tuyển ngay | `jobs_ung_tuyen_ngay` | khác |
| `lib/features/jobs/widgets/job_detail_sections.dart:316` |  dưới đây. | `jobs_duoi_day` | khác |
| `lib/features/jobs/widgets/job_filter_sidebar.dart:47` | $resultCount việc làm phù hợp | `jobs_resultcount_viec_lam_phu_hop` | khác |
| `lib/features/jobs/widgets/job_filter_sidebar.dart:77` | Bộ lọc | `jobs_bo_loc` | khác |
| `lib/features/jobs/widgets/job_filter_sidebar.dart:90` | Xoá lọc | `jobs_xoa_loc` | khác |
| `lib/features/jobs/widgets/job_filter_sidebar.dart:106` | Ngành nghề | `admin_nganh_nghe` | title |
| `lib/features/jobs/widgets/job_filter_sidebar.dart:119` | Địa điểm | `applications_dia_diem` | title |
| `lib/features/jobs/widgets/job_filter_sidebar.dart:132` | Mức lương | `jobs_muc_luong` | title |
| `lib/features/jobs/widgets/job_filter_sidebar.dart:143` | Kinh nghiệm | `employer_kinh_nghiem` | title |
| `lib/features/jobs/widgets/job_filter_sidebar.dart:155` | Cấp bậc | `jobs_cap_bac` | title |
| `lib/features/jobs/widgets/job_filter_sidebar.dart:166` | Hình thức làm việc | `employer_hinh_thuc_lam_viec` | title |
| `lib/features/jobs/widgets/job_filter_sidebar.dart:177` | Loại hình công việc | `employer_loai_hinh_cong_viec` | title |
| `lib/features/jobs/widgets/job_filter_sidebar.dart:236` | Bộ lọc | `jobs_bo_loc` | khác |
| `lib/features/jobs/widgets/job_filter_sidebar.dart:266` | ${widget.resultCount} việc làm phù hợp | `jobs_widget_resultcount_viec_lam_phu_hop` | khác |
| `lib/features/jobs/widgets/job_filter_sidebar.dart:324` | Chưa có dữ liệu | `admin_chua_co_du_lieu` | khác |
| `lib/features/jobs/widgets/job_summary_card.dart:36` | Mức lương | `jobs_muc_luong` | khác |
| `lib/features/jobs/widgets/job_summary_card.dart:42` | Địa điểm | `applications_dia_diem` | khác |
| `lib/features/jobs/widgets/job_summary_card.dart:47` | Kinh nghiệm | `employer_kinh_nghiem` | khác |
| `lib/features/jobs/widgets/job_summary_card.dart:54` | Bằng cấp | `employer_bang_cap` | khác |
| `lib/features/jobs/widgets/job_summary_card.dart:55` | Không yêu cầu | `c_services_khong_yeu_cau` | khác |
| `lib/features/jobs/widgets/job_summary_card.dart:59` | Hình thức | `employer_hinh_thuc` | khác |
| `lib/features/jobs/widgets/job_summary_card.dart:64` | Hạn nộp | `jobs_han_nop` | khác |
| `lib/features/jobs/widgets/job_summary_card.dart:67` | Đã ứng tuyển | `jobs_da_ung_tuyen` | khác |
| `lib/features/jobs/widgets/job_summary_card.dart:96` | Tóm tắt tin tuyển dụng | `jobs_tom_tat_tin_tuyen_dung` | khác |
| `lib/features/jobs/widgets/job_summary_card.dart:123` | Đã ứng tuyển | `jobs_da_ung_tuyen` | label |
| `lib/features/jobs/widgets/job_summary_card.dart:123` | Ứng tuyển ngay | `jobs_ung_tuyen_ngay` | label |
| `lib/features/jobs/widgets/job_summary_card.dart:137` | Đã lưu tin | `jobs_da_luu_tin` | label |
| `lib/features/jobs/widgets/job_summary_card.dart:137` | Lưu tin | `jobs_luu_tin` | label |
| `lib/features/jobs/widgets/job_summary_card.dart:151` | Đăng ${Formatters.postedAgo(job.createdAt)} | `jobs_dang_formatters_postedago_job_createdat` | khác |
| `lib/features/jobs/widgets/job_summary_card.dart:170` | Quay lại danh sách | `jobs_quay_lai_danh_sach` | khác |
| `lib/features/jobs/widgets/jobs_pagination.dart:99` | Trang trước | `jobs_trang_truoc` | tooltip |
| `lib/features/jobs/widgets/jobs_pagination.dart:114` | Nhảy tới trang… | `jobs_nhay_toi_trang` | tooltip |
| `lib/features/jobs/widgets/jobs_results_toolbar.dart:31` | Lọc xuống ≤100 việc làm (hiện $filtered) để bật AI Matching | `jobs_loc_xuong_100_viec_lam_hien_filtered_de_ba` | khác |
| `lib/features/jobs/widgets/jobs_results_toolbar.dart:32` | Chấm điểm CV với AI DeepSeek | `jobs_cham_diem_cv_voi_ai_deepseek` | khác |
| `lib/features/jobs/widgets/jobs_results_toolbar.dart:42` | Hiển thị  | `jobs_hien_thi` | khác |
| `lib/features/jobs/widgets/jobs_results_toolbar.dart:52` |  / $total việc làm | `jobs_total_viec_lam` | text hiển thị |
| `lib/features/jobs/widgets/jobs_results_toolbar.dart:73` | Sắp xếp: | `jobs_sap_xep` | khác |
| `lib/features/jobs/widgets/jobs_results_toolbar.dart:137` | cần ≤100 | `jobs_can_100` | label |
| `lib/features/jobs/widgets/jobs_results_toolbar.dart:256` | Xoá tất cả | `jobs_xoa_tat_ca` | khác |
| `lib/features/jobs/widgets/jobs_search_header.dart:47` | Trang chủ | `admin_trang_chu` | khác |
| `lib/features/jobs/widgets/jobs_search_header.dart:47` | Việc làm | `admin_viec_lam` | khác |
| `lib/features/jobs/widgets/jobs_search_header.dart:51` | Tìm việc làm | `jobs_tim_viec_lam` | khác |
| `lib/features/jobs/widgets/jobs_search_header.dart:60` |   ${Formatters.number(state.displayTotal)} việc làm | `jobs_formatters_number_state_displaytotal_viec` | khác |
| `lib/features/jobs/widgets/jobs_search_header.dart:81` | Tìm kiếm theo: | `jobs_tim_kiem_theo` | khác |
| `lib/features/jobs/widgets/jobs_search_header.dart:171` | Vị trí, kỹ năng, công ty... | `jobs_vi_tri_ky_nang_cong_ty` | form hint/label |
| `lib/features/jobs/widgets/jobs_search_header.dart:199` | Tất cả địa điểm | `home_tat_ca_dia_diem` | text hiển thị |
| `lib/features/jobs/widgets/jobs_search_header.dart:211` | Tìm kiếm | `admin_tim_kiem` | label |
| `lib/features/jobs/widgets/save_job_helper.dart:27` | Vui lòng đăng nhập để lưu tin. | `jobs_vui_long_dang_nhap_de_luu_tin` | text hiển thị |
| `lib/features/jobs/widgets/save_job_helper.dart:30` | Đăng nhập | `auth_dang_nhap` | label |
| `lib/features/jobs/widgets/save_job_helper.dart:45` | Đã bỏ lưu tin tuyển dụng. | `jobs_da_bo_luu_tin_tuyen_dung` | khác |
| `lib/features/jobs/widgets/save_job_helper.dart:45` | Đã lưu tin tuyển dụng. | `jobs_da_luu_tin_tuyen_dung` | khác |

### `features/notifications` (33)

| Vị trí | Chuỗi | Key đề xuất | Ngữ cảnh |
|---|---|---|---|
| `lib/features/notifications/data/notifications_repository.dart:42` | Thiếu người nhận thông báo. | `notifications_thieu_nguoi_nhan_thong_bao` | validation/lỗi |
| `lib/features/notifications/viewmodels/notifications_providers.dart:33` | Tất cả | `c_config_tat_ca` | enum/option |
| `lib/features/notifications/viewmodels/notifications_providers.dart:34` | Chưa đọc | `notifications_chua_doc` | enum/option |
| `lib/features/notifications/views/notifications_page.dart:45` | Không có thông báo chưa đọc. | `notifications_khong_co_thong_bao_chua_doc` | khác |
| `lib/features/notifications/views/notifications_page.dart:45` | Đã đánh dấu $n thông báo là đã đọc. | `notifications_da_danh_dau_n_thong_bao_la_da_doc` | khác |
| `lib/features/notifications/views/notifications_page.dart:61` | Đang tải thông báo… | `notifications_dang_tai_thong_bao` | label |
| `lib/features/notifications/views/notifications_page.dart:71` | Bạn đã đọc hết thông báo | `notifications_ban_da_doc_het_thong_bao` | title |
| `lib/features/notifications/views/notifications_page.dart:71` | Chưa có thông báo | `notifications_chua_co_thong_bao` | title |
| `lib/features/notifications/views/notifications_page.dart:73` | Không còn thông báo chưa đọc. | `notifications_khong_con_thong_bao_chua_doc` | khác |
| `lib/features/notifications/views/notifications_page.dart:74` | Thông báo về hồ sơ ứng tuyển, tin tuyển dụng và hệ thống sẽ hiển th… | `notifications_thong_bao_ve_ho_so_ung_tuyen_tin_tuyen_dun` | khác |
| `lib/features/notifications/views/notifications_page.dart:114` | Thông báo | `employer_thong_bao` | title |
| `lib/features/notifications/views/notifications_page.dart:123` | Đọc tất cả | `notifications_doc_tat_ca` | label |
| `lib/features/notifications/widgets/notification_type_meta.dart:11` | Trạng thái hồ sơ | `notifications_trang_thai_ho_so` | enum/option |
| `lib/features/notifications/widgets/notification_type_meta.dart:12` | Ứng viên mới | `notifications_ung_vien_moi` | enum/option |
| `lib/features/notifications/widgets/notification_type_meta.dart:13` | Duyệt tin | `notifications_duyet_tin` | enum/option |
| `lib/features/notifications/widgets/notification_type_meta.dart:14` | Tin bị từ chối | `notifications_tin_bi_tu_choi` | enum/option |
| `lib/features/notifications/widgets/notification_type_meta.dart:15` | Xác minh nhà tuyển dụng | `notifications_xac_minh_nha_tuyen_dung` | enum/option |
| `lib/features/notifications/widgets/notification_type_meta.dart:16` | Hệ thống | `notifications_he_thong` | enum/option |
| `lib/features/notifications/widgets/notification_type_meta.dart:98` | Trạng thái hồ sơ | `notifications_trang_thai_ho_so` | khác |
| `lib/features/notifications/widgets/notification_type_meta.dart:99` | Khi hồ sơ ứng tuyển của bạn được cập nhật trạng thái. | `notifications_khi_ho_so_ung_tuyen_cua_ban_duoc_cap_nhat` | khác |
| `lib/features/notifications/widgets/notification_type_meta.dart:104` | Ứng viên mới | `notifications_ung_vien_moi` | khác |
| `lib/features/notifications/widgets/notification_type_meta.dart:105` | Khi có ứng viên nộp hồ sơ vào tin tuyển dụng của bạn. | `notifications_khi_co_ung_vien_nop_ho_so_vao_tin_tuyen_du` | khác |
| `lib/features/notifications/widgets/notification_type_meta.dart:110` | Duyệt tin | `notifications_duyet_tin` | khác |
| `lib/features/notifications/widgets/notification_type_meta.dart:111` | Khi tin tuyển dụng được duyệt hoặc bị từ chối. | `notifications_khi_tin_tuyen_dung_duoc_duyet_hoac_bi_tu_c` | khác |
| `lib/features/notifications/widgets/notification_type_meta.dart:116` | Hệ thống | `notifications_he_thong` | khác |
| `lib/features/notifications/widgets/notification_type_meta.dart:117` | Thông báo chung từ JobHub và xác minh nhà tuyển dụng. | `notifications_thong_bao_chung_tu_jobhub_va_xac_minh_nha` | khác |
| `lib/features/notifications/widgets/notifications_summary_panel.dart:39` | Tổng quan | `employer_tong_quan` | text hiển thị |
| `lib/features/notifications/widgets/notifications_summary_panel.dart:43` | Tất cả | `c_config_tat_ca` | label |
| `lib/features/notifications/widgets/notifications_summary_panel.dart:46` | Chưa đọc | `notifications_chua_doc` | label |
| `lib/features/notifications/widgets/notifications_summary_panel.dart:52` | Theo loại | `notifications_theo_loai` | text hiển thị |
| `lib/features/notifications/widgets/notifications_summary_panel.dart:71` | Cài đặt thông báo | `notifications_cai_dat_thong_bao` | text hiển thị |
| `lib/features/notifications/widgets/notifications_summary_panel.dart:74` | Bật/tắt thông báo đẩy và chọn loại thông báo bạn muốn nhận. | `notifications_bat_tat_thong_bao_day_va_chon_loai_thong_b` | khác |
| `lib/features/notifications/widgets/notifications_summary_panel.dart:81` | Mở cài đặt | `notifications_mo_cai_dat` | label |

### `features/profile` (195)

| Vị trí | Chuỗi | Key đề xuất | Ngữ cảnh |
|---|---|---|---|
| `lib/features/profile/data/profile_repository.dart:38` | Không tìm thấy hồ sơ ứng viên. | `applications_khong_tim_thay_ho_so_ung_vien` | khác |
| `lib/features/profile/data/profile_repository.dart:39` | Không tìm thấy CV. | `profile_khong_tim_thay_cv` | khác |
| `lib/features/profile/data/profile_repository.dart:40` | Không đọc được nội dung từ tệp CV. | `profile_khong_doc_duoc_noi_dung_tu_tep_cv` | khác |
| `lib/features/profile/data/profile_repository.dart:41` | CV chưa được phân tích. | `profile_cv_chua_duoc_phan_tich` | khác |
| `lib/features/profile/data/profile_repository.dart:428` | Không thể phân tích CV bằng AI. Vui lòng thử lại sau. | `profile_khong_the_phan_tich_cv_bang_ai_vui_long_th` | khác |
| `lib/features/profile/viewmodels/profile_viewmodel.dart:42` | Đã cập nhật hồ sơ. | `profile_da_cap_nhat_ho_so` | khác |
| `lib/features/profile/viewmodels/profile_viewmodel.dart:43` | Không thể cập nhật hồ sơ. | `profile_khong_the_cap_nhat_ho_so` | khác |
| `lib/features/profile/viewmodels/profile_viewmodel.dart:46` | Tiêu đề hồ sơ quá dài. | `profile_tieu_de_ho_so_qua_dai` | khác |
| `lib/features/profile/viewmodels/profile_viewmodel.dart:47` | Tên thành phố quá dài. | `profile_ten_thanh_pho_qua_dai` | khác |
| `lib/features/profile/viewmodels/profile_viewmodel.dart:48` | Số điện thoại quá dài. | `profile_so_dien_thoai_qua_dai` | khác |
| `lib/features/profile/viewmodels/profile_viewmodel.dart:49` | Địa chỉ quá dài. | `profile_dia_chi_qua_dai` | khác |
| `lib/features/profile/viewmodels/profile_viewmodel.dart:50` | Giới thiệu bản thân quá dài. | `profile_gioi_thieu_ban_than_qua_dai` | khác |
| `lib/features/profile/viewmodels/profile_viewmodel.dart:65` | Họ tên | `c_utils_ho_ten` | label |
| `lib/features/profile/viewmodels/resumes_viewmodel.dart:87` | Tải CV thành công. | `profile_tai_cv_thanh_cong` | khác |
| `lib/features/profile/viewmodels/resumes_viewmodel.dart:88` | Vui lòng chọn tệp PDF. | `profile_vui_long_chon_tep_pdf` | khác |
| `lib/features/profile/viewmodels/resumes_viewmodel.dart:89` | Chỉ chấp nhận tệp PDF hoặc .txt. | `profile_chi_chap_nhan_tep_pdf_hoac_txt` | khác |
| `lib/features/profile/viewmodels/resumes_viewmodel.dart:90` | Tệp CV tối đa 5 MB. | `profile_tep_cv_toi_da_5_mb` | khác |
| `lib/features/profile/viewmodels/resumes_viewmodel.dart:91` | Không thể trích xuất CV | `profile_khong_the_trich_xuat_cv` | khác |
| `lib/features/profile/viewmodels/resumes_viewmodel.dart:93` | Không thể lưu trữ tệp PDF (Firebase Storage chưa được bật). CV đã đ… | `profile_khong_the_luu_tru_tep_pdf_firebase_storage` | khác |
| `lib/features/profile/viewmodels/resumes_viewmodel.dart:94` | lưu ở dạng thông tin — hãy dùng "Dán nội dung CV" để AI có thể phân… | `profile_luu_o_dang_thong_tin_hay_dung_dan_noi_dung` | khác |
| `lib/features/profile/views/ai_analysis_page.dart:53` | Không tìm thấy CV. | `profile_khong_tim_thay_cv` | title |
| `lib/features/profile/views/ai_analysis_page.dart:54` | CV có thể đã bị xóa hoặc không thuộc tài khoản của bạn. | `profile_cv_co_the_da_bi_xoa_hoac_khong_thuoc_tai_k` | title |
| `lib/features/profile/views/ai_analysis_page.dart:57` | Về Hồ sơ & CV | `profile_ve_ho_so_cv` | text hiển thị |
| `lib/features/profile/views/ai_analysis_page.dart:116` | Hồ sơ & CV | `profile_ho_so_cv` | enum/option |
| `lib/features/profile/views/ai_analysis_page.dart:117` | Phân tích AI | `profile_phan_tich_ai` | khác |
| `lib/features/profile/views/ai_analysis_page.dart:120` | Phân tích CV bằng AI | `profile_phan_tich_cv_bang_ai` | label |
| `lib/features/profile/views/ai_analysis_page.dart:135` | CV chính | `applications_cv_chinh` | label |
| `lib/features/profile/views/ai_analysis_page.dart:154` | AI đang đọc & phân tích CV — có thể mất 30–90 giây... | `profile_ai_dang_doc_phan_tich_cv_co_the_mat_30_90` | text hiển thị |
| `lib/features/profile/views/ai_analysis_page.dart:184` | CV chưa được phân tích. | `profile_cv_chua_duoc_phan_tich` | title |
| `lib/features/profile/views/ai_analysis_page.dart:186` | AI sẽ trích xuất kỹ năng, kinh nghiệm, học vấn, ngôn ngữ và chứng c… | `profile_ai_se_trich_xuat_ky_nang_kinh_nghiem_hoc_v` | khác |
| `lib/features/profile/views/ai_analysis_page.dart:187` | Tệp chưa được lưu trữ nên AI chưa đọc được nội dung. Bạn sẽ được yê… | `profile_tep_chua_duoc_luu_tru_nen_ai_chua_doc_duoc` | khác |
| `lib/features/profile/views/ai_analysis_page.dart:191` | Phân tích CV bằng AI | `profile_phan_tich_cv_bang_ai` | label |
| `lib/features/profile/views/ai_analysis_page.dart:225` | Thống kê trích xuất | `profile_thong_ke_trich_xuat` | title |
| `lib/features/profile/views/ai_analysis_page.dart:226` | Số lượng mục AI nhận diện được theo từng nhóm. | `profile_so_luong_muc_ai_nhan_dien_duoc_theo_tung_n` | title |
| `lib/features/profile/views/ai_analysis_page.dart:324` | KẾT QUẢ TRÍCH XUẤT BẰNG AI | `profile_ket_qua_trich_xuat_bang_ai` | text hiển thị |
| `lib/features/profile/views/ai_analysis_page.dart:332` | Lần phân tích thứ $historyCount | `profile_lan_phan_tich_thu_historycount` | text hiển thị |
| `lib/features/profile/views/ai_analysis_page.dart:350` | độ hoàn thiện hồ sơ | `profile_do_hoan_thien_ho_so` | text hiển thị |
| `lib/features/profile/views/ai_analysis_page.dart:370` | năm kinh nghiệm | `profile_nam_kinh_nghiem` | label |
| `lib/features/profile/views/ai_analysis_page.dart:371` | trình độ học vấn | `profile_trinh_do_hoc_van` | label |
| `lib/features/profile/views/ai_analysis_page.dart:372` | kỹ năng | `admin_ky_nang` | label |
| `lib/features/profile/views/ai_analysis_page.dart:379` | Phân tích lúc ${Formatters.localeDateTime(analysis.analyzedAt!)} | `profile_phan_tich_luc_formatters_localedatetime_an` | khác |
| `lib/features/profile/views/ai_analysis_page.dart:396` | Dùng CV này để AI Matching | `profile_dung_cv_nay_de_ai_matching` | label |
| `lib/features/profile/views/ai_analysis_page.dart:405` | Phân tích lại | `profile_phan_tich_lai` | label |
| `lib/features/profile/views/ai_analysis_page.dart:446` | Tóm tắt | `profile_tom_tat` | title |
| `lib/features/profile/views/ai_analysis_page.dart:453` | Kỹ năng | `admin_ky_nang_2` | title |
| `lib/features/profile/views/ai_analysis_page.dart:454` | ${analysis.skills.length} kỹ năng chuyên môn · ${analysis.softSkill… | `profile_analysis_skills_length_ky_nang_chuyen_mon` | title |
| `lib/features/profile/views/ai_analysis_page.dart:458` | Kỹ năng | `admin_ky_nang_2` | khác |
| `lib/features/profile/views/ai_analysis_page.dart:460` | Kỹ năng mềm | `profile_ky_nang_mem` | khác |
| `lib/features/profile/views/ai_analysis_page.dart:462` | Ngôn ngữ | `profile_ngon_ngu` | khác |
| `lib/features/profile/views/ai_analysis_page.dart:464` | Chứng chỉ | `profile_chung_chi` | khác |
| `lib/features/profile/views/ai_analysis_page.dart:470` | Kinh nghiệm làm việc | `profile_kinh_nghiem_lam_viec` | title |
| `lib/features/profile/views/ai_analysis_page.dart:473` | ${analysis.workExperience.length} vị trí được AI nhận diện | `profile_analysis_workexperience_length_vi_tri_duoc` | khác |
| `lib/features/profile/views/ai_analysis_page.dart:475` | AI không tìm thấy mục kinh nghiệm làm việc trong CV. | `profile_ai_khong_tim_thay_muc_kinh_nghiem_lam_viec` | text hiển thị |
| `lib/features/profile/views/ai_analysis_page.dart:509` | Không có | `profile_khong_co` | text hiển thị |
| `lib/features/profile/views/ai_analysis_page.dart:538` | Hiện tại | `profile_hien_tai` | khác |
| `lib/features/profile/views/ai_analysis_page.dart:560` | Vị trí chưa rõ | `profile_vi_tri_chua_ro` | text hiển thị |
| `lib/features/profile/views/edit_profile_page.dart:82` | Vui lòng kiểm tra lại các trường được đánh dấu. | `profile_vui_long_kiem_tra_lai_cac_truong_duoc_danh` | validation/lỗi |
| `lib/features/profile/views/edit_profile_page.dart:130` | Đang tải hồ sơ... | `applications_dang_tai_ho_so` | label |
| `lib/features/profile/views/edit_profile_page.dart:164` | Ứng viên | `admin_ung_vien` | label |
| `lib/features/profile/views/edit_profile_page.dart:166` | Chỉnh sửa hồ sơ | `profile_chinh_sua_ho_so` | text hiển thị |
| `lib/features/profile/views/edit_profile_page.dart:175` | Hoàn thiện thông tin liên hệ, kỹ năng, kinh nghiệm và học vấn để nh… | `profile_hoan_thien_thong_tin_lien_he_ky_nang_kinh` | khác |
| `lib/features/profile/views/edit_profile_page.dart:187` | Quay lại Hồ sơ & CV | `profile_quay_lai_ho_so_cv` | label |
| `lib/features/profile/views/edit_profile_page.dart:204` | Kỹ năng | `admin_ky_nang_2` | title |
| `lib/features/profile/views/edit_profile_page.dart:205` | Kỹ năng chuyên môn kèm số năm kinh nghiệm (nguồn: tự khai). | `profile_ky_nang_chuyen_mon_kem_so_nam_kinh_nghiem` | title |
| `lib/features/profile/views/edit_profile_page.dart:216` | Kinh nghiệm làm việc | `profile_kinh_nghiem_lam_viec` | title |
| `lib/features/profile/views/edit_profile_page.dart:217` | Sắp xếp theo ngày bắt đầu mới nhất. | `profile_sap_xep_theo_ngay_bat_dau_moi_nhat` | title |
| `lib/features/profile/views/edit_profile_page.dart:228` | Học vấn | `profile_hoc_van` | title |
| `lib/features/profile/views/edit_profile_page.dart:229` | Trường, bằng cấp, chuyên ngành và thời gian học. | `profile_truong_bang_cap_chuyen_nganh_va_thoi_gian` | title |
| `lib/features/profile/views/edit_profile_page.dart:267` | Bạn có thay đổi chưa lưu. | `profile_ban_co_thay_doi_chua_luu` | khác |
| `lib/features/profile/views/edit_profile_page.dart:268` | Mọi thay đổi sẽ thay thế toàn bộ danh sách kỹ năng, kinh nghiệm và … | `profile_moi_thay_doi_se_thay_the_toan_bo_danh_sach` | khác |
| `lib/features/profile/views/edit_profile_page.dart:287` | Đang lưu... | `admin_dang_luu` | label |
| `lib/features/profile/views/edit_profile_page.dart:287` | Lưu thay đổi | `employer_luu_thay_doi` | label |
| `lib/features/profile/views/edit_profile_page.dart:320` | Thông tin cơ bản | `profile_thong_tin_co_ban` | title |
| `lib/features/profile/views/edit_profile_page.dart:321` | Những thông tin này sẽ hiển thị khi nhà tuyển dụng xem hồ sơ của bạn. | `profile_nhung_thong_tin_nay_se_hien_thi_khi_nha_tu` | title |
| `lib/features/profile/views/edit_profile_page.dart:325` | Họ và tên | `auth_ho_va_ten` | label |
| `lib/features/profile/views/edit_profile_page.dart:332` | Họ tên | `c_utils_ho_ten` | label |
| `lib/features/profile/views/edit_profile_page.dart:334` | Nguyễn Văn A | `auth_nguyen_van_a` | form hint/label |
| `lib/features/profile/views/edit_profile_page.dart:339` | Tiêu đề hồ sơ | `profile_tieu_de_ho_so` | label |
| `lib/features/profile/views/edit_profile_page.dart:352` | Địa điểm | `applications_dia_diem` | label |
| `lib/features/profile/views/edit_profile_page.dart:364` | Số điện thoại | `employer_so_dien_thoai` | label |
| `lib/features/profile/views/edit_profile_page.dart:380` | Địa chỉ | `profile_dia_chi` | label |
| `lib/features/profile/views/edit_profile_page.dart:387` | Số nhà, đường, quận/huyện | `profile_so_nha_duong_quan_huyen` | form hint/label |
| `lib/features/profile/views/edit_profile_page.dart:392` | Giới thiệu bản thân | `profile_gioi_thieu_ban_than` | label |
| `lib/features/profile/views/edit_profile_page.dart:393` | Tối đa 5000 ký tự. | `profile_toi_da_5000_ky_tu` | khác |
| `lib/features/profile/views/edit_profile_page.dart:402` | Mục tiêu nghề nghiệp, điểm mạnh, lĩnh vực quan tâm... | `profile_muc_tieu_nghe_nghiep_diem_manh_linh_vuc_qu` | form hint/label |
| `lib/features/profile/views/edit_profile_page.dart:416` | Sẵn sàng nhận việc | `profile_san_sang_nhan_viec` | title |
| `lib/features/profile/views/edit_profile_page.dart:419` | Cho phép nhà tuyển dụng biết bạn đang mở với cơ hội mới. | `profile_cho_phep_nha_tuyen_dung_biet_ban_dang_mo_v` | khác |
| `lib/features/profile/views/resume_profile_page.dart:40` | Ứng viên | `admin_ung_vien` | label |
| `lib/features/profile/views/resume_profile_page.dart:42` | Hồ sơ & CV | `profile_ho_so_cv` | text hiển thị |
| `lib/features/profile/views/resume_profile_page.dart:50` | Quản lý thông tin cá nhân và CV PDF dùng để ứng tuyển. | `profile_quan_ly_thong_tin_ca_nhan_va_cv_pdf_dung_d` | text hiển thị |
| `lib/features/profile/views/resume_profile_page.dart:74` | CV của tôi | `profile_cv_cua_toi` | text hiển thị |
| `lib/features/profile/views/resume_profile_page.dart:97` | Không thể tải danh sách CV. ${Failure.from(e).message} | `profile_khong_the_tai_danh_sach_cv_failure_from_e` | validation/lỗi |
| `lib/features/profile/views/resume_profile_page.dart:102` | Thử lại | `admin_thu_lai` | text hiển thị |
| `lib/features/profile/views/resume_profile_page.dart:111` | Bạn chưa tải CV nào. | `profile_ban_chua_tai_cv_nao` | text hiển thị |
| `lib/features/profile/views/resume_profile_page.dart:150` | Không thể mở tệp CV. | `profile_khong_the_mo_tep_cv` | validation/lỗi |
| `lib/features/profile/views/resume_profile_page.dart:152` | Không thể mở tệp CV. | `profile_khong_the_mo_tep_cv` | validation/lỗi |
| `lib/features/profile/views/resume_profile_page.dart:158` | Không thể mở tệp CV. | `profile_khong_the_mo_tep_cv` | validation/lỗi |
| `lib/features/profile/views/resume_profile_page.dart:199` | Đã lưu nội dung CV. | `profile_da_luu_noi_dung_cv` | khác |
| `lib/features/profile/views/resume_profile_page.dart:218` | Xóa CV này? | `profile_xoa_cv_nay` | title |
| `lib/features/profile/views/resume_profile_page.dart:220` | CV "${r.title.isNotEmpty ? r.title : r.fileName}" và kết quả phân t… | `profile_cv_r_title_isnotempty_r_title_r_filename_v` | title |
| `lib/features/profile/widgets/analysis_chart.dart:16` | Kỹ năng | `admin_ky_nang_2` | khác |
| `lib/features/profile/widgets/analysis_chart.dart:17` | Kỹ năng mềm | `profile_ky_nang_mem` | khác |
| `lib/features/profile/widgets/analysis_chart.dart:18` | Ngôn ngữ | `profile_ngon_ngu` | khác |
| `lib/features/profile/widgets/analysis_chart.dart:19` | Chứng chỉ | `profile_chung_chi` | khác |
| `lib/features/profile/widgets/analysis_panel.dart:39` | Kết quả trích xuất bằng AI | `profile_ket_qua_trich_xuat_bang_ai_2` | text hiển thị |
| `lib/features/profile/widgets/analysis_panel.dart:52` | Xem chi tiết → | `profile_xem_chi_tiet` | text hiển thị |
| `lib/features/profile/widgets/analysis_panel.dart:69` | Kỹ năng | `admin_ky_nang_2` | khác |
| `lib/features/profile/widgets/analysis_panel.dart:76` | Kỹ năng mềm | `profile_ky_nang_mem` | khác |
| `lib/features/profile/widgets/analysis_panel.dart:92` |  năm kinh nghiệm | `profile_nam_kinh_nghiem_2` | khác |
| `lib/features/profile/widgets/analysis_panel.dart:108` | Ngôn ngữ: ${data.languages.join( | `profile_ngon_ngu_data_languages_join` | text hiển thị |
| `lib/features/profile/widgets/analysis_panel.dart:112` | Chứng chỉ: ${data.certifications.join( | `profile_chung_chi_data_certifications_join` | text hiển thị |
| `lib/features/profile/widgets/city_field.dart:27` | VD: Hồ Chí Minh | `profile_vd_ho_chi_minh` | khác |
| `lib/features/profile/widgets/education_editor.dart:39` | Chưa có thông tin học vấn. | `profile_chua_co_thong_tin_hoc_van` | text hiển thị |
| `lib/features/profile/widgets/education_editor.dart:56` | Thêm học vấn | `profile_them_hoc_van` | label |
| `lib/features/profile/widgets/education_editor.dart:159` | Năm phải từ 1900 đến 9999. | `profile_nam_phai_tu_1900_den_9999` | khác |
| `lib/features/profile/widgets/education_editor.dart:175` | Năm kết thúc phải sau năm bắt đầu. | `profile_nam_ket_thuc_phai_sau_nam_bat_dau` | snackbar |
| `lib/features/profile/widgets/education_editor.dart:202` | Thêm học vấn | `profile_them_hoc_van` | title |
| `lib/features/profile/widgets/education_editor.dart:202` | Sửa học vấn | `profile_sua_hoc_van` | title |
| `lib/features/profile/widgets/education_editor.dart:218` | Tên trường | `profile_ten_truong` | label |
| `lib/features/profile/widgets/education_editor.dart:219` | VD: Đại học FPT | `profile_vd_dai_hoc_fpt` | form hint/label |
| `lib/features/profile/widgets/education_editor.dart:224` | Bằng cấp | `employer_bang_cap` | label |
| `lib/features/profile/widgets/education_editor.dart:228` | Bằng cấp | `employer_bang_cap` | enum/option |
| `lib/features/profile/widgets/education_editor.dart:229` | VD: Cử nhân, Kỹ sư, Thạc sĩ | `profile_vd_cu_nhan_ky_su_thac_si` | form hint/label |
| `lib/features/profile/widgets/education_editor.dart:234` | Chuyên ngành | `profile_chuyen_nganh` | label |
| `lib/features/profile/widgets/education_editor.dart:238` | Chuyên ngành | `profile_chuyen_nganh` | enum/option |
| `lib/features/profile/widgets/education_editor.dart:239` | VD: Kỹ thuật phần mềm | `profile_vd_ky_thuat_phan_mem` | form hint/label |
| `lib/features/profile/widgets/education_editor.dart:247` | Năm bắt đầu | `profile_nam_bat_dau` | label |
| `lib/features/profile/widgets/education_editor.dart:260` | Năm kết thúc | `profile_nam_ket_thuc` | label |
| `lib/features/profile/widgets/paste_resume_text_dialog.dart:52` | Dán nội dung CV | `profile_dan_noi_dung_cv` | title |
| `lib/features/profile/widgets/paste_resume_text_dialog.dart:60` | Tệp "${widget.resume.fileName}" chưa được lưu trữ nên AI không đọc … | `profile_tep_widget_resume_filename_chua_duoc_luu_t` | khác |
| `lib/features/profile/widgets/paste_resume_text_dialog.dart:61` | nội dung. Hãy mở CV, sao chép toàn bộ văn bản và dán vào đây. | `profile_noi_dung_hay_mo_cv_sao_chep_toan_bo_van_ba` | khác |
| `lib/features/profile/widgets/paste_resume_text_dialog.dart:74` | Nội dung CV (kinh nghiệm, kỹ năng, học vấn...) | `profile_noi_dung_cv_kinh_nghiem_ky_nang_hoc_van` | form hint/label |
| `lib/features/profile/widgets/paste_resume_text_dialog.dart:87` | Lưu nội dung | `profile_luu_noi_dung` | button |
| `lib/features/profile/widgets/profile_basics_card.dart:53` | Tiêu đề hồ sơ | `profile_tieu_de_ho_so` | khác |
| `lib/features/profile/widgets/profile_basics_card.dart:54` | Địa điểm | `applications_dia_diem` | khác |
| `lib/features/profile/widgets/profile_basics_card.dart:76` | Thông tin hồ sơ | `profile_thong_tin_ho_so` | title |
| `lib/features/profile/widgets/profile_basics_card.dart:78` | Những thông tin này sẽ hiển thị khi nhà tuyển dụng xem hồ sơ của bạn. | `profile_nhung_thong_tin_nay_se_hien_thi_khi_nha_tu` | khác |
| `lib/features/profile/widgets/profile_basics_card.dart:82` | Chỉnh sửa đầy đủ | `profile_chinh_sua_day_du` | label |
| `lib/features/profile/widgets/profile_basics_card.dart:95` | Cần bổ sung để ứng tuyển: | `profile_can_bo_sung_de_ung_tuyen` | khác |
| `lib/features/profile/widgets/profile_basics_card.dart:113` | Đang tải hồ sơ... | `applications_dang_tai_ho_so` | text hiển thị |
| `lib/features/profile/widgets/profile_basics_card.dart:131` | Họ và tên | `auth_ho_va_ten` | label |
| `lib/features/profile/widgets/profile_basics_card.dart:135` | Nguyễn Văn A | `auth_nguyen_van_a` | form hint/label |
| `lib/features/profile/widgets/profile_basics_card.dart:139` | Tiêu đề hồ sơ | `profile_tieu_de_ho_so` | label |
| `lib/features/profile/widgets/profile_basics_card.dart:148` | Địa điểm | `applications_dia_diem` | label |
| `lib/features/profile/widgets/profile_basics_card.dart:172` | Đang lưu... | `admin_dang_luu` | text hiển thị |
| `lib/features/profile/widgets/profile_basics_card.dart:172` | Lưu thông tin | `profile_luu_thong_tin` | text hiển thị |
| `lib/features/profile/widgets/resume_card.dart:101` | Tệp chưa được lưu trữ. Dán nội dung CV để AI có thể phân tích. | `profile_tep_chua_duoc_luu_tru_dan_noi_dung_cv_de_a` | khác |
| `lib/features/profile/widgets/resume_card.dart:114` | Dán nội dung CV | `profile_dan_noi_dung_cv` | text hiển thị |
| `lib/features/profile/widgets/resume_card.dart:134` | AI đang đọc & phân tích CV — có thể mất 30–90 giây... | `profile_ai_dang_doc_phan_tich_cv_co_the_mat_30_90` | khác |
| `lib/features/profile/widgets/resume_card.dart:183` | CV chính | `applications_cv_chinh` | label |
| `lib/features/profile/widgets/resume_card.dart:186` | Đã trích xuất | `profile_da_trich_xuat` | label |
| `lib/features/profile/widgets/resume_card.dart:231` | Tải xuống | `profile_tai_xuong` | label |
| `lib/features/profile/widgets/resume_card.dart:233` | Tệp chưa được lưu trữ | `profile_tep_chua_duoc_luu_tru` | tooltip |
| `lib/features/profile/widgets/resume_card.dart:237` | Đang trích xuất... | `profile_dang_trich_xuat` | khác |
| `lib/features/profile/widgets/resume_card.dart:238` | Trích xuất lại | `profile_trich_xuat_lai` | khác |
| `lib/features/profile/widgets/resume_card.dart:238` | Trích xuất CV | `profile_trich_xuat_cv` | khác |
| `lib/features/profile/widgets/resume_card.dart:247` | Dán nội dung CV | `profile_dan_noi_dung_cv` | label |
| `lib/features/profile/widgets/resume_card.dart:252` | Đặt làm CV chính | `profile_dat_lam_cv_chinh` | button |
| `lib/features/profile/widgets/resume_upload_card.dart:45` | Không đọc được tệp đã chọn. | `profile_khong_doc_duoc_tep_da_chon` | enum/option |
| `lib/features/profile/widgets/resume_upload_card.dart:83` | Tên CV | `profile_ten_cv` | label |
| `lib/features/profile/widgets/resume_upload_card.dart:90` | Tệp PDF | `profile_tep_pdf` | label |
| `lib/features/profile/widgets/resume_upload_card.dart:91` | PDF hoặc .txt, tối đa 5 MB | `profile_pdf_hoac_txt_toi_da_5_mb` | khác |
| `lib/features/profile/widgets/resume_upload_card.dart:102` | Đang tải... | `admin_dang_tai` | label |
| `lib/features/profile/widgets/resume_upload_card.dart:102` | Tải CV | `profile_tai_cv` | label |
| `lib/features/profile/widgets/resume_upload_card.dart:201` | Chọn tệp | `profile_chon_tep` | text hiển thị |
| `lib/features/profile/widgets/resume_upload_card.dart:211` | Chưa chọn tệp nào | `profile_chua_chon_tep_nao` | khác |
| `lib/features/profile/widgets/skills_editor.dart:39` | Tên kỹ năng là bắt buộc. | `profile_ten_ky_nang_la_bat_buoc` | validation/lỗi |
| `lib/features/profile/widgets/skills_editor.dart:43` | Tên kỹ năng tối đa 100 ký tự. | `profile_ten_ky_nang_toi_da_100_ky_tu` | validation/lỗi |
| `lib/features/profile/widgets/skills_editor.dart:49` | Số năm kinh nghiệm phải từ 0 đến 50. | `profile_so_nam_kinh_nghiem_phai_tu_0_den_50` | validation/lỗi |
| `lib/features/profile/widgets/skills_editor.dart:56` | Kỹ năng này đã có trong danh sách. | `profile_ky_nang_nay_da_co_trong_danh_sach` | validation/lỗi |
| `lib/features/profile/widgets/skills_editor.dart:85` | Chưa có kỹ năng nào. Thêm kỹ năng để tăng độ phù hợp khi AI chấm điểm. | `profile_chua_co_ky_nang_nao_them_ky_nang_de_tang_d` | text hiển thị |
| `lib/features/profile/widgets/skills_editor.dart:114` | Tên kỹ năng | `profile_ten_ky_nang` | label |
| `lib/features/profile/widgets/skills_editor.dart:127` | Số năm kinh nghiệm | `profile_so_nam_kinh_nghiem` | label |
| `lib/features/profile/widgets/skills_editor.dart:139` | Thêm kỹ năng | `profile_them_ky_nang` | label |
| `lib/features/profile/widgets/skills_editor.dart:177` | ${s.skillName} · $yt năm | `profile_s_skillname_yt_nam` | khác |
| `lib/features/profile/widgets/work_experience_editor.dart:47` | Chưa có kinh nghiệm làm việc. | `profile_chua_co_kinh_nghiem_lam_viec` | text hiển thị |
| `lib/features/profile/widgets/work_experience_editor.dart:64` | Thêm kinh nghiệm | `profile_them_kinh_nghiem` | label |
| `lib/features/profile/widgets/work_experience_editor.dart:82` | Hiện tại | `profile_hien_tai` | khác |
| `lib/features/profile/widgets/work_experience_editor.dart:172` | Ngày bắt đầu | `profile_ngay_bat_dau` | khác |
| `lib/features/profile/widgets/work_experience_editor.dart:172` | Ngày kết thúc | `profile_ngay_ket_thuc` | khác |
| `lib/features/profile/widgets/work_experience_editor.dart:188` | Ngày kết thúc phải sau ngày bắt đầu. | `profile_ngay_ket_thuc_phai_sau_ngay_bat_dau` | snackbar |
| `lib/features/profile/widgets/work_experience_editor.dart:207` | Thêm kinh nghiệm | `profile_them_kinh_nghiem` | title |
| `lib/features/profile/widgets/work_experience_editor.dart:207` | Sửa kinh nghiệm | `profile_sua_kinh_nghiem` | title |
| `lib/features/profile/widgets/work_experience_editor.dart:218` | Công ty | `auth_cong_ty` | label |
| `lib/features/profile/widgets/work_experience_editor.dart:223` | Tên công ty | `employer_ten_cong_ty` | label |
| `lib/features/profile/widgets/work_experience_editor.dart:229` | Vị trí | `applications_vi_tri` | label |
| `lib/features/profile/widgets/work_experience_editor.dart:234` | Vị trí | `applications_vi_tri` | label |
| `lib/features/profile/widgets/work_experience_editor.dart:243` | Ngày bắt đầu | `profile_ngay_bat_dau` | label |
| `lib/features/profile/widgets/work_experience_editor.dart:250` | Ngày kết thúc | `profile_ngay_ket_thuc` | label |
| `lib/features/profile/widgets/work_experience_editor.dart:253` | Hiện tại | `profile_hien_tai` | khác |
| `lib/features/profile/widgets/work_experience_editor.dart:266` | Đang làm việc tại đây | `profile_dang_lam_viec_tai_day` | title |
| `lib/features/profile/widgets/work_experience_editor.dart:269` | Mô tả công việc | `c_utils_mo_ta_cong_viec` | label |
| `lib/features/profile/widgets/work_experience_editor.dart:274` | Mô tả | `employer_mo_ta` | label |
| `lib/features/profile/widgets/work_experience_editor.dart:276` | Trách nhiệm chính, thành tựu, công nghệ sử dụng... | `profile_trach_nhiem_chinh_thanh_tuu_cong_nghe_su_d` | form hint/label |
| `lib/features/profile/widgets/work_experience_editor.dart:302` | Chọn ngày | `employer_chon_ngay` | khác |

### `features/recommendations` (103)

| Vị trí | Chuỗi | Key đề xuất | Ngữ cảnh |
|---|---|---|---|
| `lib/features/recommendations/viewmodels/ai_matching_viewmodel.dart:24` | Cả hai | `jobs_ca_hai` | khác |
| `lib/features/recommendations/viewmodels/ai_matching_viewmodel.dart:35` | Chấm điểm với AI | `recommendations_cham_diem_voi_ai` | enum/option |
| `lib/features/recommendations/viewmodels/ai_matching_viewmodel.dart:36` | Chấm điểm với SQL | `recommendations_cham_diem_voi_sql` | enum/option |
| `lib/features/recommendations/viewmodels/ai_matching_viewmodel.dart:37` | Chấm điểm với AI + SQL | `recommendations_cham_diem_voi_ai_sql` | enum/option |
| `lib/features/recommendations/viewmodels/ai_matching_viewmodel.dart:162` | Quá thời gian chờ. AI đang xử lý quá nhiều — thử lại với ít jobs hơ… | `recommendations_qua_thoi_gian_cho_ai_dang_xu_ly_qua_nhieu` | khác |
| `lib/features/recommendations/viewmodels/ai_matching_viewmodel.dart:164` | Không kết nối được máy chủ AI. Vui lòng kiểm tra kết nối mạng và th… | `recommendations_khong_ket_noi_duoc_may_chu_ai_vui_long_kie` | khác |
| `lib/features/recommendations/viewmodels/ai_matching_viewmodel.dart:166` | Tất cả batch đều thất bại. Kiểm tra cấu hình GEMINI_API_KEY trong C… | `recommendations_tat_ca_batch_deu_that_bai_kiem_tra_cau_hin` | khác |
| `lib/features/recommendations/viewmodels/ai_matching_viewmodel.dart:170` | Vui lòng đăng nhập để chấm điểm bằng AI. | `recommendations_vui_long_dang_nhap_de_cham_diem_bang_ai` | khác |
| `lib/features/recommendations/viewmodels/ai_matching_viewmodel.dart:228` | Danh sách jobs không được rỗng | `recommendations_danh_sach_jobs_khong_duoc_rong` | validation/lỗi |
| `lib/features/recommendations/viewmodels/ai_matching_viewmodel.dart:231` | Giới hạn ${AppConfig.aiMaxJobsPerScoring} jobs/lần gọi (nhận ${jobs… | `recommendations_gioi_han_appconfig_aimaxjobsperscoring_job` | khác |
| `lib/features/recommendations/viewmodels/ai_matching_viewmodel.dart:297` | $batchErrors batch thất bại, đã chấm được $aiCount/${jobs.length} v… | `recommendations_batcherrors_batch_that_bai_da_cham_duoc_ai` | khác |
| `lib/features/recommendations/viewmodels/ai_matching_viewmodel.dart:304` | AI không trả về kết quả — chỉ hiển thị điểm SQL. | `recommendations_ai_khong_tra_ve_ket_qua_chi_hien_thi_diem` | khác |
| `lib/features/recommendations/viewmodels/ai_matching_viewmodel.dart:329` | Vui lòng chọn CV | `recommendations_vui_long_chon_cv` | validation/lỗi |
| `lib/features/recommendations/viewmodels/ai_matching_viewmodel.dart:337` | Vui lòng tải lên CV | `recommendations_vui_long_tai_len_cv` | validation/lỗi |
| `lib/features/recommendations/viewmodels/ai_matching_viewmodel.dart:338` | resumeText quá ngắn hoặc thiếu | `recommendations_resumetext_qua_ngan_hoac_thieu` | validation/lỗi |
| `lib/features/recommendations/viewmodels/ai_matching_viewmodel.dart:350` | Không trích xuất được CV bằng AI — dùng trích xuất từ khoá cơ bản c… | `recommendations_khong_trich_xuat_duoc_cv_bang_ai_dung_tric` | khác |
| `lib/features/recommendations/viewmodels/ai_matching_viewmodel.dart:368` | Phiên chấm điểm | `recommendations_phien_cham_diem` | khác |
| `lib/features/recommendations/viewmodels/ai_matching_viewmodel.dart:454` | Lỗi khi chấm điểm | `recommendations_loi_khi_cham_diem` | validation/lỗi |
| `lib/features/recommendations/viewmodels/ai_matching_viewmodel.dart:474` | tiến sĩ | `recommendations_tien_si` | khác |
| `lib/features/recommendations/viewmodels/ai_matching_viewmodel.dart:476` | thạc sĩ | `recommendations_thac_si` | khác |
| `lib/features/recommendations/viewmodels/ai_matching_viewmodel.dart:478` | cử nhân | `recommendations_cu_nhan` | khác |
| `lib/features/recommendations/viewmodels/ai_matching_viewmodel.dart:480` | đại học | `recommendations_dai_hoc` | khác |
| `lib/features/recommendations/viewmodels/ai_matching_viewmodel.dart:485` | tiếng anh | `recommendations_tieng_anh` | khác |
| `lib/features/recommendations/viewmodels/ai_matching_viewmodel.dart:486` | tiếng nhật | `recommendations_tieng_nhat` | khác |
| `lib/features/recommendations/viewmodels/ai_matching_viewmodel.dart:487` | tiếng hàn | `recommendations_tieng_han` | khác |
| `lib/features/recommendations/viewmodels/ai_matching_viewmodel.dart:487` | tiếng trung | `recommendations_tieng_trung` | khác |
| `lib/features/recommendations/viewmodels/ai_matching_viewmodel.dart:488` | tiếng pháp | `recommendations_tieng_phap` | khác |
| `lib/features/recommendations/viewmodels/ai_matching_viewmodel.dart:488` | tiếng đức | `recommendations_tieng_duc` | khác |
| `lib/features/recommendations/viewmodels/ai_matching_viewmodel.dart:492` | làm việc nhóm | `recommendations_lam_viec_nhom` | khác |
| `lib/features/recommendations/viewmodels/ai_matching_viewmodel.dart:493` | giao tiếp | `recommendations_giao_tiep` | khác |
| `lib/features/recommendations/viewmodels/ai_matching_viewmodel.dart:493` | lãnh đạo | `recommendations_lanh_dao` | khác |
| `lib/features/recommendations/viewmodels/ai_matching_viewmodel.dart:494` | giải quyết vấn đề | `recommendations_giai_quyet_van_de` | khác |
| `lib/features/recommendations/viewmodels/ai_matching_viewmodel.dart:495` | quản lý thời gian | `recommendations_quan_ly_thoi_gian` | khác |
| `lib/features/recommendations/views/recommended_page.dart:26` | Trang chủ | `admin_trang_chu` | enum/option |
| `lib/features/recommendations/views/recommended_page.dart:27` | Đề xuất việc làm | `recommendations_de_xuat_viec_lam` | khác |
| `lib/features/recommendations/views/recommended_page.dart:64` | Xoá toàn bộ phiên chấm điểm? | `recommendations_xoa_toan_bo_phien_cham_diem` | title |
| `lib/features/recommendations/views/recommended_page.dart:65` | Tất cả phiên chấm điểm đã lưu trên thiết bị này sẽ bị xoá. | `recommendations_tat_ca_phien_cham_diem_da_luu_tren_thiet_b` | text hiển thị |
| `lib/features/recommendations/views/recommended_page.dart:71` | Xoá tất cả | `jobs_xoa_tat_ca` | text hiển thị |
| `lib/features/recommendations/views/recommended_page.dart:79` | Đã xoá toàn bộ phiên chấm điểm. | `recommendations_da_xoa_toan_bo_phien_cham_diem` | khác |
| `lib/features/recommendations/views/recommended_page.dart:108` | Đề xuất việc làm | `recommendations_de_xuat_viec_lam` | khác |
| `lib/features/recommendations/views/recommended_page.dart:122` | $count phiên chấm điểm. Bấm vào phiên để xem chi tiết. | `recommendations_count_phien_cham_diem_bam_vao_phien_de_xem` | khác |
| `lib/features/recommendations/views/recommended_page.dart:123` | Các phiên chấm điểm AI/SQL sẽ xuất hiện ở đây. | `recommendations_cac_phien_cham_diem_ai_sql_se_xuat_hien_o` | khác |
| `lib/features/recommendations/views/recommended_page.dart:138` | Xoá tất cả | `jobs_xoa_tat_ca` | label |
| `lib/features/recommendations/views/recommended_page.dart:164` | Chưa có phiên chấm điểm nào | `recommendations_chua_co_phien_cham_diem_nao` | khác |
| `lib/features/recommendations/views/recommended_page.dart:173` | Truy cập trang việc làm, filter xuống ≤100 jobs, rồi bấm  | `recommendations_truy_cap_trang_viec_lam_filter_xuong_100_j` | text hiển thị |
| `lib/features/recommendations/views/recommended_page.dart:178` |  để AI chấm điểm phù hợp. Mỗi lần chấm sẽ tạo 1 phiên lưu ở đây. | `recommendations_de_ai_cham_diem_phu_hop_moi_lan_cham_se_ta` | text hiển thị |
| `lib/features/recommendations/views/recommended_page.dart:188` | Đi tới việc làm | `recommendations_di_toi_viec_lam` | label |
| `lib/features/recommendations/views/session_detail_page.dart:62` | Không tìm thấy phiên | `recommendations_khong_tim_thay_phien` | text hiển thị |
| `lib/features/recommendations/views/session_detail_page.dart:68` | Quay lại danh sách | `jobs_quay_lai_danh_sach` | text hiển thị |
| `lib/features/recommendations/views/session_detail_page.dart:109` | Trang chủ | `admin_trang_chu` | enum/option |
| `lib/features/recommendations/views/session_detail_page.dart:110` | Đề xuất | `recommendations_de_xuat` | enum/option |
| `lib/features/recommendations/views/session_detail_page.dart:125` | Tất cả phiên | `recommendations_tat_ca_phien` | text hiển thị |
| `lib/features/recommendations/views/session_detail_page.dart:160` | Việc làm | `admin_viec_lam` | khác |
| `lib/features/recommendations/views/session_detail_page.dart:166` | Điểm TB | `recommendations_diem_tb` | khác |
| `lib/features/recommendations/views/session_detail_page.dart:174` | Phù hợp cao (≥70) | `recommendations_phu_hop_cao_70` | khác |
| `lib/features/recommendations/views/session_detail_page.dart:186` | Xếp hạng theo độ phù hợp (cao → thấp) | `recommendations_xep_hang_theo_do_phu_hop_cao_thap` | text hiển thị |
| `lib/features/recommendations/views/session_detail_page.dart:196` | Phiên này không còn dữ liệu việc làm để hiển thị. | `recommendations_phien_nay_khong_con_du_lieu_viec_lam_de_hi` | khác |
| `lib/features/recommendations/widgets/ai_matching_sheet.dart:140` | Chấm điểm $n việc làm với CV bằng Gemini AI | `recommendations_cham_diem_n_viec_lam_voi_cv_bang_gemini_ai` | text hiển thị |
| `lib/features/recommendations/widgets/ai_matching_sheet.dart:205` | Đang chấm điểm — đang xử lý ${state.progressCurrent}/${state.progre… | `recommendations_dang_cham_diem_dang_xu_ly_state_progresscu` | khác |
| `lib/features/recommendations/widgets/ai_matching_sheet.dart:206` | Đang chấm điểm... | `recommendations_dang_cham_diem` | khác |
| `lib/features/recommendations/widgets/ai_matching_sheet.dart:256` | Sẽ chấm $n việc làm | `recommendations_se_cham_n_viec_lam` | text hiển thị |
| `lib/features/recommendations/widgets/ai_matching_sheet.dart:266` | Mỗi lần chấm điểm được ghi log (prompt, response, thời gian) vào tr… | `recommendations_moi_lan_cham_diem_duoc_ghi_log_prompt_resp` | khác |
| `lib/features/recommendations/widgets/ai_matching_sheet.dart:268` |  để theo dõi và cải thiện prompt. | `recommendations_de_theo_doi_va_cai_thien_prompt` | text hiển thị |
| `lib/features/recommendations/widgets/cv_picker.dart:79` | Không đọc được dữ liệu file | `recommendations_khong_doc_duoc_du_lieu_file` | validation/lỗi |
| `lib/features/recommendations/widgets/cv_picker.dart:89` | Không thể trích xuất text từ file. Hãy thử file khác (.pdf, .txt). | `recommendations_khong_the_trich_xuat_text_tu_file_hay_thu` | khác |
| `lib/features/recommendations/widgets/cv_picker.dart:103` | Lỗi đọc file: $msg. Hãy thử file PDF hoặc TXT khác. | `recommendations_loi_doc_file_msg_hay_thu_file_pdf_hoac_txt` | khác |
| `lib/features/recommendations/widgets/cv_picker.dart:118` | CV đã trích xuất | `recommendations_cv_da_trich_xuat` | label |
| `lib/features/recommendations/widgets/cv_picker.dart:126` | Tải lên CV mới | `recommendations_tai_len_cv_moi` | label |
| `lib/features/recommendations/widgets/cv_picker.dart:146` | Vui lòng đăng nhập để dùng CV đã trích xuất. | `recommendations_vui_long_dang_nhap_de_dung_cv_da_trich_xua` | title |
| `lib/features/recommendations/widgets/cv_picker.dart:148` | Bạn có thể  | `recommendations_ban_co_the` | text hiển thị |
| `lib/features/recommendations/widgets/cv_picker.dart:149` | đăng nhập | `applications_dang_nhap` | enum/option |
| `lib/features/recommendations/widgets/cv_picker.dart:150` |  hoặc chọn  | `recommendations_hoac_chon` | text hiển thị |
| `lib/features/recommendations/widgets/cv_picker.dart:151` | Tải lên CV mới | `recommendations_tai_len_cv_moi` | text hiển thị |
| `lib/features/recommendations/widgets/cv_picker.dart:152` |  để dán nội dung CV và chấm điểm bằng SQL. | `recommendations_de_dan_noi_dung_cv_va_cham_diem_bang_sql` | text hiển thị |
| `lib/features/recommendations/widgets/cv_picker.dart:158` | Chỉ tài khoản ứng viên mới có CV đã trích xuất. | `recommendations_chi_tai_khoan_ung_vien_moi_co_cv_da_trich` | title |
| `lib/features/recommendations/widgets/cv_picker.dart:159` | Chọn "Tải lên CV mới" để dán nội dung CV cần chấm điểm. | `recommendations_chon_tai_len_cv_moi_de_dan_noi_dung_cv_can` | text hiển thị |
| `lib/features/recommendations/widgets/cv_picker.dart:170` | Đang tải CV đã trích xuất... | `recommendations_dang_tai_cv_da_trich_xuat` | text hiển thị |
| `lib/features/recommendations/widgets/cv_picker.dart:176` | Không tải được danh sách CV. | `recommendations_khong_tai_duoc_danh_sach_cv` | title |
| `lib/features/recommendations/widgets/cv_picker.dart:182` | Bạn chưa trích xuất CV nào. | `recommendations_ban_chua_trich_xuat_cv_nao` | title |
| `lib/features/recommendations/widgets/cv_picker.dart:185` | Hồ sơ & CV | `profile_ho_so_cv` | enum/option |
| `lib/features/recommendations/widgets/cv_picker.dart:186` |  → bấm  | `recommendations_bam` | text hiển thị |
| `lib/features/recommendations/widgets/cv_picker.dart:187` | ✦ Trích xuất CV | `recommendations_trich_xuat_cv` | text hiển thị |
| `lib/features/recommendations/widgets/cv_picker.dart:188` |  để AI phân tích CV của bạn. | `recommendations_de_ai_phan_tich_cv_cua_ban` | text hiển thị |
| `lib/features/recommendations/widgets/cv_picker.dart:196` | CV CỦA TÔI (ĐÃ TRÍCH XUẤT) | `recommendations_cv_cua_toi_da_trich_xuat` | khác |
| `lib/features/recommendations/widgets/cv_picker.dart:251` | ${state.uploadedText.length} ký tự | `recommendations_state_uploadedtext_length_ky_tu` | text hiển thị |
| `lib/features/recommendations/widgets/cv_picker.dart:257` | Tải lên CV (.txt, .pdf) | `recommendations_tai_len_cv_txt_pdf` | text hiển thị |
| `lib/features/recommendations/widgets/cv_picker.dart:261` | CV sẽ được AI trích xuất tự động trước khi chấm điểm | `recommendations_cv_se_duoc_ai_trich_xuat_tu_dong_truoc_khi` | text hiển thị |
| `lib/features/recommendations/widgets/cv_picker.dart:269` | Hoặc dán nội dung CV | `recommendations_hoac_dan_noi_dung_cv` | text hiển thị |
| `lib/features/recommendations/widgets/cv_picker.dart:281` | Dán nội dung CV của bạn vào đây (tối đa 8000 ký tự)... | `recommendations_dan_noi_dung_cv_cua_ban_vao_day_toi_da_800` | form hint/label |
| `lib/features/recommendations/widgets/cv_picker.dart:295` | PHƯƠNG THỨC CHẤM ĐIỂM | `recommendations_phuong_thuc_cham_diem` | khác |
| `lib/features/recommendations/widgets/cv_picker.dart:312` | Miễn phí, tức thì | `recommendations_mien_phi_tuc_thi` | enum/option |
| `lib/features/recommendations/widgets/cv_picker.dart:455` | Của tôi | `recommendations_cua_toi` | text hiển thị |
| `lib/features/recommendations/widgets/cv_picker.dart:465` |  : shown}$extra · $yearsLabel năm KN | `recommendations_shown_extra_yearslabel_nam_kn` | khác |
| `lib/features/recommendations/widgets/recommendations_shell.dart:50` | ${Formatters.localeDateTime(session.scoredAt)} · ${session.jobCount… | `recommendations_formatters_localedatetime_session_scoredat` | khác |
| `lib/features/recommendations/widgets/recommendations_shell.dart:100` | Xem chi tiết | `recommendations_xem_chi_tiet` | text hiển thị |
| `lib/features/recommendations/widgets/scoring_results.dart:47` | Kết quả chấm điểm ($scored/$total việc làm) | `recommendations_ket_qua_cham_diem_scored_total_viec_lam` | khác |
| `lib/features/recommendations/widgets/scoring_results.dart:63` | Lưu kết quả | `recommendations_luu_ket_qua` | label |
| `lib/features/recommendations/widgets/scoring_results.dart:70` | ⚠ Chấm được $scored/$total — một số batch bị lỗi, thử lại sau nếu c… | `recommendations_cham_duoc_scored_total_mot_so_batch_bi_loi` | khác |
| `lib/features/recommendations/widgets/scoring_results.dart:90` | Đã lưu phiên chấm điểm. | `recommendations_da_luu_phien_cham_diem` | text hiển thị |
| `lib/features/recommendations/widgets/scoring_results.dart:102` | Xem phiên | `recommendations_xem_phien` | khác |
| `lib/features/recommendations/widgets/scoring_results.dart:125` | Không có việc làm nào được chấm điểm. | `recommendations_khong_co_viec_lam_nao_duoc_cham_diem` | text hiển thị |
| `lib/features/recommendations/widgets/scoring_results.dart:171` | Điểm SQL | `recommendations_diem_sql` | khác |
| `lib/features/recommendations/widgets/scoring_results.dart:171` | Điểm AI | `recommendations_diem_ai` | khác |

### `features/settings` (60)

| Vị trí | Chuỗi | Key đề xuất | Ngữ cảnh |
|---|---|---|---|
| `lib/features/settings/views/settings_page.dart:48` | Giao diện | `settings_giao_dien` | title |
| `lib/features/settings/views/settings_page.dart:49` | Chế độ hiển thị của ứng dụng. | `settings_che_do_hien_thi_cua_ung_dung` | title |
| `lib/features/settings/views/settings_page.dart:60` | Theo hệ thống | `settings_theo_he_thong` | title |
| `lib/features/settings/views/settings_page.dart:84` | Ngôn ngữ | `profile_ngon_ngu` | title |
| `lib/features/settings/views/settings_page.dart:85` | Ngôn ngữ hiển thị. | `settings_ngon_ngu_hien_thi` | title |
| `lib/features/settings/views/settings_page.dart:96` | Tiếng Việt | `settings_tieng_viet` | title |
| `lib/features/settings/views/settings_page.dart:111` | Nội dung ứng dụng hiện chỉ hiển thị bằng tiếng Việt. Lựa chọn này á… | `settings_noi_dung_ung_dung_hien_chi_hien_thi_bang_t` | khác |
| `lib/features/settings/views/settings_page.dart:112` | thành phần hệ thống (lịch, hộp thoại, định dạng ngày và số). | `settings_thanh_phan_he_thong_lich_hop_thoai_dinh_da` | khác |
| `lib/features/settings/views/settings_page.dart:119` | Thông báo | `employer_thong_bao` | title |
| `lib/features/settings/views/settings_page.dart:120` | Thông báo đẩy (FCM) trên thiết bị này. | `settings_thong_bao_day_fcm_tren_thiet_bi_nay` | title |
| `lib/features/settings/views/settings_page.dart:125` | Nhận thông báo đẩy | `settings_nhan_thong_bao_day` | title |
| `lib/features/settings/views/settings_page.dart:126` | Bật/tắt toàn bộ thông báo đẩy. | `settings_bat_tat_toan_bo_thong_bao_day` | title |
| `lib/features/settings/views/settings_page.dart:132` | Loại thông báo | `settings_loai_thong_bao` | text hiển thị |
| `lib/features/settings/views/settings_page.dart:157` | Tài khoản | `admin_tai_khoan_2` | title |
| `lib/features/settings/views/settings_page.dart:167` | Không tải được thông tin tài khoản. | `settings_khong_tai_duoc_thong_tin_tai_khoan` | validation/lỗi |
| `lib/features/settings/views/settings_page.dart:177` | Bạn chưa đăng nhập. | `settings_ban_chua_dang_nhap` | text hiển thị |
| `lib/features/settings/views/settings_page.dart:182` | Đăng nhập | `auth_dang_nhap` | text hiển thị |
| `lib/features/settings/views/settings_page.dart:194` | Dữ liệu | `settings_du_lieu` | title |
| `lib/features/settings/views/settings_page.dart:195` | Dữ liệu lưu cục bộ trên thiết bị này. | `settings_du_lieu_luu_cuc_bo_tren_thiet_bi_nay` | title |
| `lib/features/settings/views/settings_page.dart:200` | Phiên chấm điểm đã lưu | `settings_phien_cham_diem_da_luu` | title |
| `lib/features/settings/views/settings_page.dart:203` | Chưa có phiên chấm điểm nào. | `settings_chua_co_phien_cham_diem_nao` | khác |
| `lib/features/settings/views/settings_page.dart:204` | ${s.savedSessions} phiên (tối đa 20). | `settings_s_savedsessions_phien_toi_da_20` | khác |
| `lib/features/settings/views/settings_page.dart:211` | Xoá phiên chấm điểm | `settings_xoa_phien_cham_diem` | title |
| `lib/features/settings/views/settings_page.dart:213` | Xoá toàn bộ ${s.savedSessions} phiên chấm điểm AI đã lưu trên thiết… | `settings_xoa_toan_bo_s_savedsessions_phien_cham_die` | khác |
| `lib/features/settings/views/settings_page.dart:215` | Đã xoá phiên chấm điểm. | `settings_da_xoa_phien_cham_diem` | khác |
| `lib/features/settings/views/settings_page.dart:218` | Xoá phiên chấm điểm | `settings_xoa_phien_cham_diem` | text hiển thị |
| `lib/features/settings/views/settings_page.dart:225` | Lịch sử tìm kiếm | `settings_lich_su_tim_kiem` | title |
| `lib/features/settings/views/settings_page.dart:228` | Chưa có từ khoá nào. | `settings_chua_co_tu_khoa_nao` | khác |
| `lib/features/settings/views/settings_page.dart:229` | ${s.searchHistoryCount} từ khoá gần đây. | `settings_s_searchhistorycount_tu_khoa_gan_day` | khác |
| `lib/features/settings/views/settings_page.dart:236` | Xoá lịch sử tìm kiếm | `settings_xoa_lich_su_tim_kiem` | title |
| `lib/features/settings/views/settings_page.dart:237` | Xoá các từ khoá tìm kiếm gần đây trên thiết bị? | `settings_xoa_cac_tu_khoa_tim_kiem_gan_day_tren_thie` | validation/lỗi |
| `lib/features/settings/views/settings_page.dart:239` | Đã xoá lịch sử tìm kiếm. | `settings_da_xoa_lich_su_tim_kiem` | khác |
| `lib/features/settings/views/settings_page.dart:242` | Xoá lịch sử tìm kiếm | `settings_xoa_lich_su_tim_kiem` | text hiển thị |
| `lib/features/settings/views/settings_page.dart:250` | Giới thiệu | `settings_gioi_thieu` | title |
| `lib/features/settings/views/settings_page.dart:257` | Nền tảng tuyển dụng Flutter — đồ án PRM393 | `settings_nen_tang_tuyen_dung_flutter_do_an_prm393` | khác |
| `lib/features/settings/views/settings_page.dart:260` | Nền tảng tuyển dụng Flutter — đồ án PRM393 | `settings_nen_tang_tuyen_dung_flutter_do_an_prm393` | text hiển thị |
| `lib/features/settings/views/settings_page.dart:263` | Về JobHub | `settings_ve_jobhub` | text hiển thị |
| `lib/features/settings/views/settings_page.dart:268` | Phiên bản | `settings_phien_ban` | title |
| `lib/features/settings/views/settings_page.dart:320` | Cài đặt | `settings_cai_dat` | title |
| `lib/features/settings/views/settings_page.dart:367` | Ứng viên | `admin_ung_vien` | enum/option |
| `lib/features/settings/views/settings_page.dart:368` | Nhà tuyển dụng | `admin_nha_tuyen_dung` | enum/option |
| `lib/features/settings/views/settings_page.dart:369` | Quản trị viên | `admin_quan_tri_vien` | enum/option |
| `lib/features/settings/views/settings_page.dart:396` | Người dùng | `admin_nguoi_dung` | text hiển thị |
| `lib/features/settings/views/settings_page.dart:420` | Vai trò | `settings_vai_tro` | label |
| `lib/features/settings/views/settings_page.dart:422` | Xác minh | `admin_xac_minh_2` | label |
| `lib/features/settings/views/settings_page.dart:422` | Đã xác minh | `admin_da_xac_minh` | label |
| `lib/features/settings/views/settings_page.dart:433` | Đổi mật khẩu thành công. | `settings_doi_mat_khau_thanh_cong` | khác |
| `lib/features/settings/views/settings_page.dart:437` | Đổi mật khẩu | `settings_doi_mat_khau` | label |
| `lib/features/settings/views/settings_page.dart:446` | Đăng xuất | `settings_dang_xuat` | label |
| `lib/features/settings/views/settings_page.dart:460` | Đăng xuất | `settings_dang_xuat` | title |
| `lib/features/settings/views/settings_page.dart:461` | Bạn có chắc muốn đăng xuất khỏi JobHub? | `settings_ban_co_chac_muon_dang_xuat_khoi_jobhub` | text hiển thị |
| `lib/features/settings/views/settings_page.dart:468` | Đăng xuất | `settings_dang_xuat` | text hiển thị |
| `lib/features/settings/widgets/change_password_dialog.dart:48` | Mật khẩu mới phải khác mật khẩu hiện tại. | `settings_mat_khau_moi_phai_khac_mat_khau_hien_tai` | validation/lỗi |
| `lib/features/settings/widgets/change_password_dialog.dart:68` | Đổi mật khẩu | `settings_doi_mat_khau` | title |
| `lib/features/settings/widgets/change_password_dialog.dart:78` | Nhập mật khẩu hiện tại để xác thực, sau đó đặt mật khẩu mới (8–128 … | `settings_nhap_mat_khau_hien_tai_de_xac_thuc_sau_do` | khác |
| `lib/features/settings/widgets/change_password_dialog.dart:88` | Mật khẩu hiện tại | `settings_mat_khau_hien_tai` | label |
| `lib/features/settings/widgets/change_password_dialog.dart:96` | Mật khẩu mới | `settings_mat_khau_moi` | label |
| `lib/features/settings/widgets/change_password_dialog.dart:97` | Tối thiểu 8 ký tự | `auth_toi_thieu_8_ky_tu` | khác |
| `lib/features/settings/widgets/change_password_dialog.dart:105` | Xác nhận mật khẩu mới | `settings_xac_nhan_mat_khau_moi` | label |
| `lib/features/settings/widgets/change_password_dialog.dart:128` | Cập nhật mật khẩu | `settings_cap_nhat_mat_khau` | text hiển thị |

### `features/splash` (1)

| Vị trí | Chuỗi | Key đề xuất | Ngữ cảnh |
|---|---|---|---|
| `lib/features/splash/views/splash_page.dart:107` | Nền tảng tuyển dụng thông minh | `splash_nen_tang_tuyen_dung_thong_minh` | khác |

### `lib` (2)

| Vị trí | Chuỗi | Key đề xuất | Ngữ cảnh |
|---|---|---|---|
| `lib/app.dart:46` | Tài khoản không còn tồn tại. | `app_tai_khoan_khong_con_ton_tai` | snackbar |
| `lib/app.dart:55` | Tài khoản đã bị vô hiệu hóa. | `app_tai_khoan_da_bi_vo_hieu_hoa` | snackbar |

### `shared` (146)

| Vị trí | Chuỗi | Key đề xuất | Ngữ cảnh |
|---|---|---|---|
| `lib/shared/models/application_model.dart:29` | Ứng viên | `admin_ung_vien` | enum/option |
| `lib/shared/models/application_model.dart:30` | Nhà tuyển dụng | `admin_nha_tuyen_dung` | enum/option |
| `lib/shared/models/application_model.dart:31` | Quản trị viên | `admin_quan_tri_vien` | enum/option |
| `lib/shared/models/employer_profile_model.dart:45` | Đã xác thực | `employer_da_xac_thuc` | enum/option |
| `lib/shared/models/employer_profile_model.dart:45` | Chờ xác thực | `employer_cho_xac_thuc` | enum/option |
| `lib/shared/models/job_model.dart:50` | Không yêu cầu | `c_services_khong_yeu_cau` | khác |
| `lib/shared/models/job_model.dart:85` | Không yêu cầu | `c_services_khong_yeu_cau` | khác |
| `lib/shared/models/job_model.dart:117` | Yêu cầu: ${yeuCauUngVien.join( | `s__yeu_cau_yeucauungvien_join` | khác |
| `lib/shared/models/job_model.dart:118` | Quyền lợi: ${quyenLoi.join( | `s__quyen_loi_quyenloi_join` | khác |
| `lib/shared/models/job_model.dart:230` | $applicationsCount người | `s__applicationscount_nguoi` | enum/option |
| `lib/shared/models/job_model.dart:237` | Công ty chưa cập nhật | `c_utils_cong_ty_chua_cap_nhat` | khác |
| `lib/shared/models/job_model.dart:243` | Tin tuyển dụng chưa có tiêu đề | `admin_tin_tuyen_dung_chua_co_tieu_de` | khác |
| `lib/shared/models/job_model.dart:422` | Không yêu cầu | `c_services_khong_yeu_cau` | enum/option |
| `lib/shared/models/job_model.dart:423` | Dưới 1 năm | `jobs_duoi_1_nam` | enum/option |
| `lib/shared/models/job_model.dart:424` | 1 - 2 năm | `jobs_1_2_nam` | enum/option |
| `lib/shared/models/job_model.dart:425` | 2 - 4 năm | `jobs_2_4_nam` | enum/option |
| `lib/shared/models/job_model.dart:426` | 5 năm | `jobs_5_nam` | enum/option |
| `lib/shared/models/job_model.dart:427` | Trên 5 năm | `jobs_tren_5_nam` | enum/option |
| `lib/shared/models/job_model.dart:433` | Tại văn phòng | `c_utils_tai_van_phong` | enum/option |
| `lib/shared/models/jobseeker_profile_model.dart:158` | họ tên | `applications_ho_ten` | khác |
| `lib/shared/models/jobseeker_profile_model.dart:159` | chức danh | `applications_chuc_danh` | khác |
| `lib/shared/models/jobseeker_profile_model.dart:160` | thành phố | `applications_thanh_pho` | khác |
| `lib/shared/models/misc_models.dart:68` | Người dùng | `admin_nguoi_dung` | enum/option |
| `lib/shared/models/recommendation_models.dart:39` | Kỹ năng chuyên môn | `s__ky_nang_chuyen_mon` | khác |
| `lib/shared/models/recommendation_models.dart:40` | Kinh nghiệm | `employer_kinh_nghiem` | khác |
| `lib/shared/models/recommendation_models.dart:41` | Học vấn & Chứng chỉ | `s__hoc_van_chung_chi` | khác |
| `lib/shared/models/recommendation_models.dart:42` | Cùng ngành nghề | `s__cung_nganh_nghe` | khác |
| `lib/shared/models/recommendation_models.dart:43` | Kỹ năng mềm & Thái độ | `s__ky_nang_mem_thai_do` | khác |
| `lib/shared/models/recommendation_models.dart:44` | Ngoại ngữ | `s__ngoai_ngu` | khác |
| `lib/shared/models/recommendation_models.dart:45` | Phù hợp định hướng | `s__phu_hop_dinh_huong` | khác |
| `lib/shared/models/recommendation_models.dart:316` | Không rõ | `c_services_khong_ro` | khác |
| `lib/shared/models/user_model.dart:46` | Ứng viên | `admin_ung_vien` | enum/option |
| `lib/shared/widgets/application_status_badge.dart:14` | Đã nộp | `c_utils_da_nop` | enum/option |
| `lib/shared/widgets/application_status_badge.dart:15` | Đang xem xét | `c_utils_dang_xem_xet` | enum/option |
| `lib/shared/widgets/application_status_badge.dart:16` | Đã chấp nhận | `s__da_chap_nhan` | enum/option |
| `lib/shared/widgets/application_status_badge.dart:17` | Đã từ chối | `s__da_tu_choi` | enum/option |
| `lib/shared/widgets/application_status_badge.dart:18` | Phỏng vấn | `c_utils_phong_van` | enum/option |
| `lib/shared/widgets/application_status_badge.dart:19` | Đã có offer | `c_utils_da_co_offer` | enum/option |
| `lib/shared/widgets/application_status_badge.dart:20` | Đã rút | `c_utils_da_rut` | enum/option |
| `lib/shared/widgets/application_status_badge.dart:59` | Chờ duyệt | `admin_cho_duyet` | khác |
| `lib/shared/widgets/application_status_badge.dart:62` | Bị từ chối | `employer_bi_tu_choi` | khác |
| `lib/shared/widgets/application_status_badge.dart:65` | Đang tuyển | `c_utils_dang_tuyen` | enum/option |
| `lib/shared/widgets/application_status_badge.dart:66` | Đã đóng | `c_utils_da_dong` | enum/option |
| `lib/shared/widgets/application_status_badge.dart:67` | Tạm dừng | `c_utils_tam_dung` | enum/option |
| `lib/shared/widgets/application_status_badge.dart:69` | Hết hạn | `c_utils_het_han` | enum/option |
| `lib/shared/widgets/auth_shell.dart:123` | Hiểu đúng hồ sơ của bạn | `s__hieu_dung_ho_so_cua_ban` | khác |
| `lib/shared/widgets/auth_shell.dart:124` | Đọc CV và nhận diện kỹ năng, kinh nghiệm thực tế thay vì chỉ tìm th… | `s__doc_cv_va_nhan_dien_ky_nang_kinh_nghiem_th` | khác |
| `lib/shared/widgets/auth_shell.dart:128` | An toàn cho dữ liệu cá nhân | `s__an_toan_cho_du_lieu_ca_nhan` | khác |
| `lib/shared/widgets/auth_shell.dart:129` | Thông tin được mã hoá và bảo vệ theo tiêu chuẩn phổ biến của các dị… | `s__thong_tin_duoc_ma_hoa_va_bao_ve_theo_tieu` | khác |
| `lib/shared/widgets/auth_shell.dart:133` | Gợi ý việc làm sát với bạn | `s__goi_y_viec_lam_sat_voi_ban` | khác |
| `lib/shared/widgets/auth_shell.dart:134` | Ưu tiên các tin tuyển dụng phù hợp kinh nghiệm và định hướng nghề n… | `s__uu_tien_cac_tin_tuyen_dung_phu_hop_kinh_ng` | khác |
| `lib/shared/widgets/auth_shell.dart:199` | Tìm việc đúng người, đúng việc | `s__tim_viec_dung_nguoi_dung_viec` | khác |
| `lib/shared/widgets/auth_shell.dart:213` | JobHub giúp ứng viên tiếp cận các tin tuyển dụng phù hợp và để nhà … | `s__jobhub_giup_ung_vien_tiep_can_cac_tin_tuye` | khác |
| `lib/shared/widgets/auth_shell.dart:226` | © ${DateTime.now().year} JobHub. Mọi quyền được bảo lưu. | `s__datetime_now_year_jobhub_moi_quyen_duoc_ba` | khác |
| `lib/shared/widgets/job_list_item.dart:114` | Nổi bật | `jobs_noi_bat` | label |
| `lib/shared/widgets/job_list_item.dart:187` | Đã ứng tuyển | `jobs_da_ung_tuyen` | text hiển thị |
| `lib/shared/widgets/job_list_item.dart:187` | Ứng tuyển | `applications_ung_tuyen` | text hiển thị |
| `lib/shared/widgets/job_list_item.dart:206` | Bỏ lưu | `jobs_bo_luu` | validation/lỗi |
| `lib/shared/widgets/job_list_item.dart:206` | Lưu tin | `jobs_luu_tin` | validation/lỗi |
| `lib/shared/widgets/job_list_item.dart:265` | Thiếu: ${missing.take(3).join( | `s__thieu_missing_take_3_join` | khác |
| `lib/shared/widgets/job_list_item.dart:288` | Thu gọn đánh giá | `s__thu_gon_danh_gia` | khác |
| `lib/shared/widgets/job_list_item.dart:288` | Xem đánh giá chi tiết từ AI | `s__xem_danh_gia_chi_tiet_tu_ai` | khác |
| `lib/shared/widgets/job_list_item.dart:375` | ĐIỂM AI | `s__diem_ai` | text hiển thị |
| `lib/shared/widgets/job_list_item.dart:392` | PHÂN TÍCH 7 TIÊU CHÍ | `s__phan_tich_7_tieu_chi` | khác |
| `lib/shared/widgets/job_list_item.dart:396` |   (trọng số thay đổi theo job) | `s__trong_so_thay_doi_theo_job` | khác |
| `lib/shared/widgets/job_list_item.dart:414` |  (trọng số: ${w[key]}đ) | `s__trong_so_w_key_d` | khác |
| `lib/shared/widgets/job_list_item.dart:449` | ĐÁNH GIÁ TỔNG QUAN | `s__danh_gia_tong_quan` | text hiển thị |
| `lib/shared/widgets/job_list_item.dart:459` | ⚠ KỸ NĂNG THIẾU | `s__ky_nang_thieu` | text hiển thị |
| `lib/shared/widgets/job_list_item.dart:466` | ✓ ĐIỂM MẠNH | `s__diem_manh` | text hiển thị |
| `lib/shared/widgets/job_list_item.dart:545` | Nổi bật | `jobs_noi_bat` | label |
| `lib/shared/widgets/job_list_item.dart:594` | Ứng tuyển | `applications_ung_tuyen` | text hiển thị |
| `lib/shared/widgets/nav_items.dart:22` | Việc làm | `admin_viec_lam` | khác |
| `lib/shared/widgets/nav_items.dart:23` | Đề xuất | `recommendations_de_xuat` | khác |
| `lib/shared/widgets/nav_items.dart:24` | Công ty | `auth_cong_ty` | khác |
| `lib/shared/widgets/nav_items.dart:25` | Hồ sơ & AI | `s__ho_so_ai` | khác |
| `lib/shared/widgets/nav_items.dart:26` | Cẩm nang nghề nghiệp | `home_cam_nang_nghe_nghiep` | khác |
| `lib/shared/widgets/nav_items.dart:32` | Hồ sơ cá nhân | `s__ho_so_ca_nhan` | khác |
| `lib/shared/widgets/nav_items.dart:33` | Hồ sơ đã ứng tuyển | `applications_ho_so_da_ung_tuyen_2` | khác |
| `lib/shared/widgets/nav_items.dart:34` | Kết quả chấm điểm đã lưu | `s__ket_qua_cham_diem_da_luu` | khác |
| `lib/shared/widgets/nav_items.dart:35` | Việc đã lưu | `jobs_viec_da_luu` | khác |
| `lib/shared/widgets/nav_items.dart:36` | Tin nhắn | `chat_tin_nhan` | khác |
| `lib/shared/widgets/nav_items.dart:37` | Thông báo | `employer_thong_bao` | khác |
| `lib/shared/widgets/nav_items.dart:38` | Cài đặt | `settings_cai_dat` | khác |
| `lib/shared/widgets/nav_items.dart:41` | Tổng quan | `employer_tong_quan` | khác |
| `lib/shared/widgets/nav_items.dart:42` | Hồ sơ công ty | `employer_ho_so_cong_ty` | khác |
| `lib/shared/widgets/nav_items.dart:43` | Quản lý tin tuyển dụng | `employer_quan_ly_tin_tuyen_dung` | khác |
| `lib/shared/widgets/nav_items.dart:44` | Đăng tin tuyển dụng | `employer_dang_tin_tuyen_dung` | khác |
| `lib/shared/widgets/nav_items.dart:45` | Hồ sơ ứng tuyển | `admin_ho_so_ung_tuyen` | khác |
| `lib/shared/widgets/nav_items.dart:46` | Tin nhắn | `chat_tin_nhan` | khác |
| `lib/shared/widgets/nav_items.dart:47` | Thông báo | `employer_thong_bao` | khác |
| `lib/shared/widgets/nav_items.dart:48` | Cài đặt | `settings_cai_dat` | khác |
| `lib/shared/widgets/nav_items.dart:51` | Tổng quan | `employer_tong_quan` | khác |
| `lib/shared/widgets/nav_items.dart:52` | Quản lý người dùng | `admin_quan_ly_nguoi_dung` | khác |
| `lib/shared/widgets/nav_items.dart:53` | Quản lý nhà tuyển dụng | `admin_quan_ly_nha_tuyen_dung` | khác |
| `lib/shared/widgets/nav_items.dart:54` | Duyệt tin tuyển dụng | `admin_duyet_tin_tuyen_dung` | khác |
| `lib/shared/widgets/nav_items.dart:55` | Quản lý ngành nghề và kỹ năng | `admin_quan_ly_nganh_nghe_va_ky_nang` | khác |
| `lib/shared/widgets/nav_items.dart:56` | Thống kê AI Logs | `admin_thong_ke_ai_logs` | khác |
| `lib/shared/widgets/nav_items.dart:58` | Hồ sơ ứng tuyển | `admin_ho_so_ung_tuyen` | khác |
| `lib/shared/widgets/nav_items.dart:59` | Cấu hình hệ thống | `admin_cau_hinh_he_thong` | khác |
| `lib/shared/widgets/nav_items.dart:60` | Thông báo | `employer_thong_bao` | khác |
| `lib/shared/widgets/public_layout.dart:142` | Trang chủ | `admin_trang_chu` | khác |
| `lib/shared/widgets/public_layout.dart:152` | Đăng xuất | `settings_dang_xuat` | title |
| `lib/shared/widgets/public_layout.dart:160` | Đăng nhập | `auth_dang_nhap` | khác |
| `lib/shared/widgets/public_layout.dart:161` | Đăng ký miễn phí | `auth_dang_ky_mien_phi` | khác |
| `lib/shared/widgets/public_layout.dart:162` | Dành cho nhà tuyển dụng → | `s__danh_cho_nha_tuyen_dung` | khác |
| `lib/shared/widgets/status_history_timeline.dart:18` | Chưa có lịch sử trạng thái. | `s__chua_co_lich_su_trang_thai` | text hiển thị |
| `lib/shared/widgets/status_history_timeline.dart:63` | từ ${ApplicationStatusBadge.styleOf(items[i].oldStatus!).$3} | `s__tu_applicationstatusbadge_styleof_items_i` | khác |
| `lib/shared/widgets/ui_primitives.dart:154` | Điểm phù hợp ${score.matchScore}/100 (${score.source.toUpperCase()}) | `s__diem_phu_hop_score_matchscore_100_score_so` | validation/lỗi |
| `lib/shared/widgets/ui_primitives.dart:181` | Mật khẩu | `auth_mat_khau` | khác |
| `lib/shared/widgets/ui_primitives.dart:234` | Hiện mật khẩu | `s__hien_mat_khau` | tooltip |
| `lib/shared/widgets/ui_primitives.dart:234` | Ẩn mật khẩu | `s__an_mat_khau` | tooltip |
| `lib/shared/widgets/ui_primitives.dart:266` | Thử lại | `admin_thu_lai` | button |
| `lib/shared/widgets/ui_primitives.dart:334` | ĐÃ XẢY RA LỖI | `s__da_xay_ra_loi` | text hiển thị |
| `lib/shared/widgets/ui_primitives.dart:342` | Trang này gặp sự cố | `s__trang_nay_gap_su_co` | text hiển thị |
| `lib/shared/widgets/ui_primitives.dart:347` | Vui lòng tải lại trang hoặc quay lại sau. | `s__vui_long_tai_lai_trang_hoac_quay_lai_sau` | validation/lỗi |
| `lib/shared/widgets/ui_primitives.dart:356` | Tải lại trang | `s__tai_lai_trang` | label |
| `lib/shared/widgets/ui_primitives.dart:481` | Đã sao chép | `s__da_sao_chep` | validation/lỗi |
| `lib/shared/widgets/web_footer.dart:20` | Công ty | `auth_cong_ty` | khác |
| `lib/shared/widgets/web_footer.dart:21` | Giới thiệu JobHub | `s__gioi_thieu_jobhub` | khác |
| `lib/shared/widgets/web_footer.dart:22` | Tuyển dụng | `s__tuyen_dung` | khác |
| `lib/shared/widgets/web_footer.dart:23` | Tin tức | `s__tin_tuc` | khác |
| `lib/shared/widgets/web_footer.dart:24` | Liên hệ | `admin_lien_he` | khác |
| `lib/shared/widgets/web_footer.dart:26` | Sản phẩm | `s__san_pham` | khác |
| `lib/shared/widgets/web_footer.dart:27` | Tìm việc làm | `jobs_tim_viec_lam` | khác |
| `lib/shared/widgets/web_footer.dart:28` | Hồ sơ & CV | `profile_ho_so_cv` | khác |
| `lib/shared/widgets/web_footer.dart:29` | Dành cho doanh nghiệp | `s__danh_cho_doanh_nghiep` | khác |
| `lib/shared/widgets/web_footer.dart:30` | Gợi ý việc làm AI | `s__goi_y_viec_lam_ai` | khác |
| `lib/shared/widgets/web_footer.dart:32` | Hỗ trợ | `s__ho_tro` | khác |
| `lib/shared/widgets/web_footer.dart:33` | Trung tâm trợ giúp | `s__trung_tam_tro_giup` | khác |
| `lib/shared/widgets/web_footer.dart:34` | Câu hỏi thường gặp | `s__cau_hoi_thuong_gap` | khác |
| `lib/shared/widgets/web_footer.dart:35` | Hướng dẫn sử dụng | `s__huong_dan_su_dung` | khác |
| `lib/shared/widgets/web_footer.dart:36` | Báo cáo vấn đề | `s__bao_cao_van_de` | khác |
| `lib/shared/widgets/web_footer.dart:38` | Pháp lý | `s__phap_ly` | khác |
| `lib/shared/widgets/web_footer.dart:39` | Điều khoản dịch vụ | `auth_dieu_khoan_dich_vu` | khác |
| `lib/shared/widgets/web_footer.dart:40` | Chính sách bảo mật | `s__chinh_sach_bao_mat` | khác |
| `lib/shared/widgets/web_footer.dart:41` | Chính sách cookie | `s__chinh_sach_cookie` | khác |
| `lib/shared/widgets/web_footer.dart:82` | JobHub — nền tảng tuyển dụng thông minh ứng dụng AI, kết nối ứng vi… | `s__jobhub_nen_tang_tuyen_dung_thong_minh_ung` | khác |
| `lib/shared/widgets/web_footer.dart:112` | © $year JobHub. Mọi quyền được bảo lưu. | `s__year_jobhub_moi_quyen_duoc_bao_luu` | text hiển thị |
| `lib/shared/widgets/web_footer.dart:134` | JobHub trên $label | `s__jobhub_tren_label` | validation/lỗi |
| `lib/shared/widgets/web_navbar.dart:105` | Đăng nhập | `auth_dang_nhap` | text hiển thị |
| `lib/shared/widgets/web_navbar.dart:114` | Đăng nhập | `auth_dang_nhap` | text hiển thị |
| `lib/shared/widgets/web_navbar.dart:121` | Đăng ký | `s__dang_ky` | text hiển thị |
| `lib/shared/widgets/web_navbar.dart:126` | Dành cho NTD | `s__danh_cho_ntd` | text hiển thị |
| `lib/shared/widgets/web_navbar.dart:177` | Thông báo | `employer_thong_bao` | tooltip |
| `lib/shared/widgets/web_navbar.dart:187` | Tài khoản | `admin_tai_khoan_2` | tooltip |
| `lib/shared/widgets/web_navbar.dart:231` | Đăng xuất | `settings_dang_xuat` | text hiển thị |

## Phụ lục — scaffold `AppLocalizations` (gợi ý, chưa áp dụng)

```yaml
# l10n.yaml
arb-dir: lib/l10n
template-arb-file: app_vi.arb
output-localization-file: app_localizations.dart
```

```json
// lib/l10n/app_vi.arb (mẫu)
{
  "@@locale": "vi",
  "app_tai_khoan_khong_con_ton_tai": "Tài khoản không còn tồn tại.",
  "app_tai_khoan_da_bi_vo_hieu_hoa": "Tài khoản đã bị vô hiệu hóa.",
  "c_config_ke_toan": "Kế toán",
  "c_config_duoi_10_trieu": "Dưới 10 triệu",
  "c_config_10_15_trieu": "10 - 15 triệu",
  "c_common_thoa_thuan": "Thoả thuận"
}
```

```dart
// MaterialApp:
//   localizationsDelegates: AppLocalizations.localizationsDelegates,
//   supportedLocales: AppLocalizations.supportedLocales,
// Dùng: Text(AppLocalizations.of(context)!.cCommonThoaThuan)
```

## Ghi chú
- Chuỗi trong `demo_data.dart` là nội dung job mẫu (dữ liệu, không phải UI) — không cần l10n.
- Regex nhận diện: literal có ký tự `[À-ỹ]`; chuỗi UI yêu cầu thêm khoảng trắng (theo đề bài).
- Script bỏ qua dòng `import`/`part` và phần comment `//` cùng dòng.
