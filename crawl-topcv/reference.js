/**
 * Real reference data extracted from TopCV (categories, filters, cities,
 * salary ranges, experience levels, job levels, industries).
 *
 * This is STABLE reference data — crawled once (or hardcoded from a single
 * page inspection) and does not change often. It forms the realistic
 * "skeleton" that generate.js uses to synthesize job postings.
 *
 * Source: TopCV search page sidebar filters (verified 2026-07).
 */

// Real TopCV job categories: [slug, displayName]
// 50 diverse categories covering all major job families.
export const CATEGORIES = [
  ['nhan-vien-kinh-doanh', 'Nhân viên kinh doanh'],
  ['ke-toan', 'Kế toán'],
  ['marketing', 'Marketing'],
  ['hanh-chinh-nhan-su', 'Hành chính nhân sự'],
  ['nhan-vien-cham-soc-khach-hang', 'Chăm sóc khách hàng'],
  ['ngan-hang', 'Ngân hàng'],
  ['ky-su-xay-dung', 'Kỹ sư xây dựng'],
  ['thiet-ke-do-hoa-designer', 'Thiết kế đồ hoạ'],
  ['bat-dong-san', 'Bất động sản'],
  ['giao-duc', 'Giáo dục'],
  ['nhan-vien-telesales', 'Telesales'],
  ['cong-nghe-thong-tin-cr257', 'IT - Công nghệ thông tin'],
  ['tu-van-chuyen-mon-cr750', 'Tư vấn chuyên môn'],
  ['duoc-y-te-suc-khoe-cong-nghe-sinh-hoc-cr781', 'Dược / Y tế'],
  ['logistics-thu-mua-kho-van-tai-cr711', 'Logistics / Vận tải'],
  ['san-xuat-cr417', 'Sản xuất'],
  ['nha-hang-khach-san-du-lich-cr857', 'Nhà hàng / Khách sạn'],
  ['dien-dien-tu-vien-thong-cr644', 'Điện / Điện tử / Viễn thông'],
  ['tai-xe-cr1010', 'Tài xế'],
  ['luat-cr1014', 'Luật / Pháp chế'],
  ['nang-luong-moi-truong-nong-nghiep-cr883', 'Năng lượng / Môi trường'],
  ['ban-le-dich-vu-doi-song-cr544', 'Bán lẻ / Dịch vụ'],
  ['tuyen-dung-cr177cb178cl182', 'Tuyển dụng (HR)'],
  ['bien-phien-dich-cr1013', 'Biên phiên dịch'],
  ['thiet-ke-cr826', 'Thiết kế'],
  ['xay-dung-cr1080', 'Xây dựng'],
  ['phim-va-truyen-hinh-bao-chi-xuat-ban-cr612', 'Báo chí / Xuất bản'],
  ['nhom-nghe-khac-cr899', 'Nghề khác'],
  ['content-marketing', 'Content Marketing'],
  ['digital-marketing', 'Digital Marketing'],
  ['nhan-vien-sales', 'Nhân viên Sales'],
  ['lap-trinh-vien', 'Lập trình viên'],
  ['nhan-vien-ke-toan', 'Nhân viên Kế toán'],
  ['nhan-vien-marketing', 'Nhân viên Marketing'],
  ['kiem-toan', 'Kiểm toán'],
  ['giao-vien-tieng-anh', 'Giáo viên tiếng Anh'],
  ['ky-su-co-khi', 'Kỹ sư cơ khí'],
  ['thiet-ke-noi-that', 'Thiết kế nội thất'],
  ['kho-van', 'Kho vận'],
  ['cong-nhan-san-xuat', 'Công nhân sản xuất'],
  ['backend-developer', 'Backend Developer'],
  ['frontend-developer', 'Frontend Developer'],
  ['tester', 'Software Tester'],
  ['quan-ly-cua-hang', 'Quản lý cửa hàng'],
  ['ke-toan-tong-hop', 'Kế toán tổng hợp'],
  ['nhan-vien-hanh-chinh', 'Nhân viên Hành chính'],
  ['phuc-vu', 'Phục vụ'],
  ['tho-sua-chua', 'Thợ sửa chữa'],
  ['devops', 'DevOps Engineer'],
];

// Real TopCV salary filter ranges → [min, max] in VND/month.
// null means negotiable/open.
export const SALARY_RANGES = [
  { label: 'Dưới 10 triệu', min: 5000000, max: 10000000 },
  { label: '10 - 15 triệu', min: 10000000, max: 15000000 },
  { label: '15 - 20 triệu', min: 15000000, max: 20000000 },
  { label: '20 - 25 triệu', min: 20000000, max: 25000000 },
  { label: '25 - 30 triệu', min: 25000000, max: 30000000 },
  { label: '30 - 50 triệu', min: 30000000, max: 50000000 },
  { label: 'Trên 50 triệu', min: 50000000, max: 80000000 },
  { label: 'Thoả thuận', min: null, max: null }, // negotiable
  { label: 'Từ 15 triệu', min: 15000000, max: null }, // open-ended
];

// Real TopCV experience filter values → JobHub experience_level enum.
export const EXPERIENCE_LEVELS = [
  { label: 'Không yêu cầu', enum: 'INTERN' },
  { label: 'Dưới 1 năm', enum: 'FRESHER' },
  { label: '1 năm', enum: 'JUNIOR' },
  { label: '2 năm', enum: 'JUNIOR' },
  { label: '3 năm', enum: 'MID' },
  { label: '4 năm', enum: 'MID' },
  { label: '5 năm', enum: 'SENIOR' },
  { label: 'Trên 5 năm', enum: 'LEAD' },
];

// Real TopCV "cấp bậc" (job level) filter values.
export const JOB_LEVELS = [
  'Nhân viên',
  'Trưởng nhóm',
  'Trưởng/Phó phòng',
  'Quản lý / Giám sát',
  'Trưởng chi nhánh',
  'Phó giám đốc',
  'Giám đốc',
  'Thực tập sinh',
];

// Real TopCV job types.
export const JOB_TYPES = [
  { label: 'Toàn thời gian', enum: 'FULL_TIME' },
  { label: 'Bán thời gian', enum: 'PART_TIME' },
  { label: 'Thực tập', enum: 'INTERNSHIP' },
];

// Work modes.
export const WORK_MODES = [
  { label: 'Onsite', enum: 'ONSITE', weight: 80 },
  { label: 'Hybrid', enum: 'HYBRID', weight: 12 },
  { label: 'Remote', enum: 'REMOTE', weight: 8 },
];

// Real TopCV company industries (lĩnh vực công ty).
export const INDUSTRIES = [
  'IT - Phần mềm', 'Bán lẻ - Hàng tiêu dùng - FMCG', 'Marketing / Truyền thông',
  'Tài chính', 'Ngân hàng', 'Bảo hiểm', 'Sản xuất', 'Logistics - Vận tải',
  'Giáo dục / Đào tạo', 'Y tế / Dược phẩm', 'Bất động sản', 'Xây dựng',
  'Nhà hàng / Khách sạn', 'Du lịch', 'Thương mại điện tử', 'Thời trang',
  'Điện / Điện tử', 'Viễn thông', 'Nông nghiệp', 'Năng lượng',
  'Tư vấn', 'Luật', 'Cơ khí / Tự động hóa', 'Thiết kế / Kiến trúc',
  'Báo chí / Xuất bản', 'Bưu chính', 'Chứng khoán', 'Môi trường',
];

// 63 Vietnamese provinces/cities (real TopCV location filter values).
export const CITIES = [
  'Hà Nội', 'Hồ Chí Minh', 'Bình Dương', 'Bắc Ninh', 'Đồng Nai',
  'Hưng Yên', 'Hải Dương', 'Đà Nẵng', 'Hải Phòng', 'An Giang',
  'Bà Rịa - Vũng Tàu', 'Bắc Giang', 'Bạc Liêu', 'Bến Tre', 'Bình Định',
  'Bình Phước', 'Bình Thuận', 'Cà Mau', 'Cần Thơ', 'Cao Bằng',
  'Đắk Lắk', 'Đắc Nông', 'Điện Biên', 'Đồng Tháp', 'Gia Lai',
  'Hà Giang', 'Hà Nam', 'Hà Tĩnh', 'Hậu Giang', 'Hòa Bình',
  'Khánh Hòa', 'Kiên Giang', 'Kon Tum', 'Lai Châu', 'Lâm Đồng',
  'Lạng Sơn', 'Lào Cai', 'Long An', 'Nam Định', 'Nghệ An',
  'Ninh Bình', 'Ninh Thuận', 'Phú Thọ', 'Phú Yên', 'Quảng Bình',
  'Quảng Nam', 'Quảng Ngãi', 'Quảng Ninh', 'Quảng Trị', 'Sóc Trăng',
  'Sơn La', 'Tây Ninh', 'Thái Bình', 'Thái Nguyên', 'Thanh Hóa',
  'Thừa Thiên Huế', 'Tiền Giang', 'Trà Vinh', 'Tuyên Quang',
  'Vĩnh Long', 'Vĩnh Phúc', 'Yên Bái',
];
// Weighting: big cities appear more often (realistic distribution).
export const CITY_WEIGHTS = {
  'Hồ Chí Minh': 32, 'Hà Nội': 28, 'Bình Dương': 6, 'Đồng Nai': 4,
  'Đà Nẵng': 4, 'Hải Phòng': 3, 'Bắc Ninh': 3, 'Hưng Yên': 2,
  'Hải Dương': 2, 'Cần Thơ': 2, 'Nghệ An': 2, 'Thanh Hóa': 2,
};

// Realistic Vietnamese company "core names" — combined with company-type
// prefix to form full names like "CÔNG TY CỔ PHẦN CÔNG NGHỆ VINATECH".
export const COMPANY_CORES = [
  'CÔNG NGHỆ', 'TƯ VẤN ĐẦU TƯ', 'TRUYỀN THÔNG', 'XÂY DỰNG', 'THƯƠNG MẠI',
  'DỊCH VỤ', 'PHÁT TRIỂN', 'DU LỊCH', 'GIÁO DỤC', 'LOGISTICS',
  'SẢN XUẤT', 'NÔNG NGHIỆP', 'THỰC PHẨM', 'DƯỢC PHẨM', 'Y TẾ',
  'THỜI TRANG', 'BÁN LẺ', 'TÀI CHÍNH', 'BẤT ĐỘNG SẢN', 'NĂNG LƯỢNG',
  'VINATECH', 'FPT', 'VIETTEL', 'MASAN', 'VINGROUP', 'SUN GROUP',
  'HÓA CHẤT', 'CƠ KHÍ', 'ĐIỆN TỬ', 'VIỄN THÔNG', 'MỸ PHẨM',
  'XUẤT NHẬP KHẨU', 'VẬN TẢI', 'KHÁCH SẠN', 'NHÀ HÀNG', 'QUẢNG CÁO',
  'PHÁT TRIỂN PHẦN MỀM', 'TỰ ĐỘNG HÓA', 'CHUYỂN GIAO CÔNG NGHỆ',
  'GIẢI PHÁP DOANH NGHIỆP', 'ĐẦU TƯ XÂY DỰNG', 'THƯƠNG MẠI DỊCH VỤ',
];
export const COMPANY_PREFIXES = [
  'CÔNG TY TNHH', 'CÔNG TY CỔ PHẦN', 'CÔNG TY TRÁCH NHIỆM HỮU HẠN',
];
// Optional geographic/brand suffixes for variety.
export const COMPANY_SUFFIXES = [
  'VIỆT NAM', 'INDOCHINA', 'ASIA', 'PACIFIC', 'MIỀN NAM', 'MIỀN BẮC',
  '', '', '', '', // mostly empty
];

/**
 * Per-category job title pools. Keyed by category slug (subset) or a
 * "family" key shared by related categories. These are realistic Vietnamese
 * job titles seen on TopCV.
 */
export const TITLE_FAMILIES = {
  // --- IT / Software ---
  'it': [
    'Backend Developer', 'Frontend Developer', 'Fullstack Developer',
    'Mobile Developer (React Native)', 'Mobile Developer (Flutter)',
    'DevOps Engineer', 'Software Engineer', 'Senior Software Engineer',
    'QA/QC Engineer', 'Software Tester (Manual & Automation)',
    'Data Analyst', 'Data Engineer', 'System Administrator',
    'IT Support', 'Network Engineer', 'Security Engineer',
    'AI Engineer', 'Embedded Engineer', 'Game Developer',
    'UI/UX Designer', 'Business Analyst', 'Product Owner',
    'Scrum Master', 'Technical Leader', 'Project Manager (IT)',
  ],
  'lap-trinh-vien': [
    'Lập trình viên NodeJS', 'Lập trình viên Java', 'Lập trình viên Python',
    'Lập trình viên PHP', 'Lập trình viên .NET', 'Lập trình viên Golang',
  ],
  'backend-developer': ['Backend Developer (NodeJS)', 'Backend Developer (Java)', 'Backend Developer (Python)', 'Backend Developer (Golang)'],
  'frontend-developer': ['Frontend Developer (ReactJS)', 'Frontend Developer (VueJS)', 'Frontend Developer (Angular)'],
  'devops': ['DevOps Engineer', 'Cloud Engineer', 'Site Reliability Engineer', 'System Engineer'],
  'tester': ['Software Tester (Manual)', 'Automation Tester', 'QA Engineer', 'QA/QC Engineer'],

  // --- Sales / Business ---
  'nhan-vien-kinh-doanh': [
    'Nhân Viên Kinh Doanh', 'Chuyên Viên Kinh Doanh', 'Nhân Viên Phát Triển Kinh Doanh',
    'Nhân Viên Kinh Doanh B2B', 'Nhân Viên Sales (Thị Trường)',
  ],
  'nhan-vien-sales': ['Nhân Viên Bán Hàng', 'Nhân Viên Sales', 'Sales Representative', 'Account Executive'],
  'nhan-vien-telesales': ['Nhân Viên Telesales', 'Chuyên Viên Telesales', 'Telesales Executive', 'Nhân Viên Chăm Sóc Khách Hàng Qua Điện Thoại'],

  // --- Marketing ---
  'marketing': ['Chuyên Viên Marketing', 'Marketing Executive', 'Marketing Manager', 'Trưởng Nhóm Marketing'],
  'nhan-vien-marketing': ['Nhân Viên Marketing', 'Marketing Specialist', 'Marketing Coordinator'],
  'content-marketing': ['Content Creator', 'Content Writer', 'Content Marketing Specialist', 'Copywriter'],
  'digital-marketing': ['Digital Marketing Specialist', 'Performance Marketing Executive', 'SEO Specialist', 'Social Media Manager'],

  // --- Accounting / Finance ---
  'ke-toan': ['Nhân Viên Kế Toán', 'Kế Toán Tổng Hợp', 'Kế Toán Thuế', 'Kế Toán Công Nợ'],
  'nhan-vien-ke-toan': ['Nhân Viên Kế Toán', 'Kế Toán Nội Bộ', 'Kế Toán Bán Hàng', 'Kế Toán Thanh Toán'],
  'ke-toan-tong-hop': ['Kế Toán Tổng Hợp', 'Kế Toán Trưởng', 'Phó Kế Toán Trưởng'],
  'kiem-toan': ['Nhân Viên Kiểm Toán', 'Kiểm Toán Viên', 'Kiểm Toán Nội Bộ'],
  'ngan-hang': ['Giao Dịch Viên', 'Chuyên Viên Khách Hàng Cá Nhân', 'Chuyên Viên Tín Dụng', 'Thẩm Định Tín Dụng'],

  // --- Admin / HR ---
  'hanh-chinh-nhan-su': ['Nhân Viên Hành Chính Nhân Sự', 'Chuyên Viên Nhân Sự', 'Nhân Viên Tuyển Dụng'],
  'nhan-vien-hanh-chinh': ['Nhân Viên Hành Chính', 'Nhân Viên Hành Chính Văn Phòng', 'Thư Lý / Thư Ký', 'Lễ Tân'],
  'tuyen-dung-cr177cb178cl182': ['Nhân Viên Tuyển Dụng', 'Chuyên Viên Tuyển Dụng', 'Trưởng Phòng Nhân Sự'],

  // --- Customer Service ---
  'nhan-vien-cham-soc-khach-hang': ['Nhân Viên Chăm Sóc Khách Hàng', 'Chuyên Viên CSKH', 'Nhân Viên Hỗ Trợ Khách Hàng', 'Call Center'],

  // --- Construction / Engineering ---
  'ky-su-xay-dung': ['Kỹ Sư Xây Dựng', 'Kỹ Sư Thủy Lợi', 'Giám Sát Công Trình', 'Chỉ Huy Trưởng', 'Kỹ Sư Hiện Trường'],
  'xay-dung-cr1080': ['Kỹ Sư Khai Thác', 'Kỹ Sư Dự Toán', 'Nhân Viên Hồ Sơ Xây Dựng', 'Kỹ Sư Quản Lý Chất Lượng'],
  'ky-su-co-khi': ['Kỹ Sư Cơ Khí', 'Kỹ Sư Thiết Kế Cơ Khí', 'Kỹ Sư Tự Động Hóa', 'Thợ Cơ Khí'],
  'thiet-ke-noi-that': ['Thiết Kế Nội Thất', 'Kỹ Sư Nội Thất', 'Kiến Trúc Sư Nội Thất'],

  // --- Design ---
  'thiet-ke-do-hoa-designer': ['Thiết Kế Đồ Hoạ', 'Graphic Designer', 'Senior Graphic Designer', 'Thiết Kế UI/UX'],
  'thiet-ke-cr826': ['Thiết Kế Đồ Hoạ', 'Thiết Kế Bao Bì', 'Thiết Kế 3D', 'Animation Designer'],

  // --- Real Estate ---
  'bat-dong-san': ['Nhân Viên Kinh Doanh Bất Động Sản', 'Môi Giới Bất Động Sản', 'Tư Vấn Bất Động Sản', 'Chuyên Viên Bất Động Sản'],

  // --- Education ---
  'giao-duc': ['Giáo Viên Tiếng Anh', 'Giáo Viên Tiếng Trung', 'Giáo Viên Toán', 'Giáo Viên Mầm Non', 'Trợ Giảng'],
  'giao-vien-tieng-anh': ['Giáo Viên Tiếng Anh', 'Trợ Giảng Tiếng Anh', 'Giáo Viên STEAM'],

  // --- Healthcare ---
  'duoc-y-te-suc-khoe-cong-nghe-sinh-hoc-cr781': ['Dược Sĩ', 'Trình Dược Viên', 'Y Tá / Điều Dưỡng', 'Bác Sĩ', 'Kỹ Thuật Viên Y Tế'],

  // --- Logistics ---
  'logistics-thu-mua-kho-van-tai-cr711': ['Nhân Viên Xuất Nhập Khẩu', 'Chứng Từ Xuất Nhập Khẩu', 'Khai Báo Hải Quan', 'Nhân Viên Kho Vận'],
  'kho-van': ['Nhân Viên Kho', 'Thủ Kho', 'Giám Sát Kho Vận', 'Điều Phối Giao Hàng'],

  // --- Production ---
  'san-xuat-cr417': ['Nhân Viên Sản Xuất', 'Công Nhân Vận Hành Máy', 'Kỹ Sư Quản Lý Sản Xuất', 'Quản Đốc Phân Xưởng'],
  'cong-nhan-san-xuat': ['Công Nhân Sản Xuất', 'Công Nhân Lắp Ráp', 'Công Nhân Đóng Gói', 'Lao Động Phổ Thông'],

  // --- Hospitality ---
  'nha-hang-khach-san-du-lich-cr857': ['Nhân Viên Phục Vụ', 'Đầu Bếp', 'Phụ Bếp', 'Thu Ngân', 'Nhân Viên Buồng Phòng', 'Quản Lý Nhà Hàng'],
  'phuc-vu': ['Nhân Viên Phục Vụ', 'Pha Chế (Barista)', 'Thu Ngân', 'Lễ Tân Khách Sạn'],

  // --- Electrical ---
  'dien-dien-tu-vien-thong-cr644': ['Kỹ Sư Điện', 'Kỹ Sư Điện Lạnh', 'Thợ Điện', 'Kỹ Sư Viễn Thông', 'Kỹ Thuật Viên Điện Tử'],

  // --- Transport ---
  'tai-xe-cr1010': ['Tài Xế Lái Xe', 'Tài Xế Xe Tải', 'Lái Xe Cho Sếp', 'Tài Xế Container', 'Phụ Xe'],

  // --- Law ---
  'luat-cr1014': ['Nhân Viên Pháp Chế', 'Chuyên Viên Pháp Lý', 'Luật Sư', 'Hợp Đồng'],

  // --- Retail ---
  'ban-le-dich-vu-doi-song-cr544': ['Nhân Viên Bán Hàng', 'Quản Lý Cửa Hàng', 'Thu Ngân', 'Nhân Viên Siêu Thị'],
  'quan-ly-cua-hang': ['Quản Lý Cửa Hàng', 'Cửa Hàng Trưởng', 'Trợ Lý Quản Lý'],

  // --- Energy / Environment ---
  'nang-luong-moi-truong-nong-nghiep-cr883': ['Kỹ Sư Môi Trường', 'Nhân Viên Môi Trường', 'Kỹ Thuật Viên Nông Nghiệp'],

  // --- Consulting ---
  'tu-van-chuyen-mon-cr750': ['Chuyên Viên Tư Vấn', 'Nhân Viên Tư Vấn', 'Tư Vấn Bảo Hiểm', 'Tư Vấn Tài Chính'],

  // --- Translation ---
  'bien-phien-dich-cr1013': ['Biên Phiên Dịch Tiếng Anh', 'Biên Phiên Dịch Tiếng Trung', 'Biên Phiên Dịch Tiếng Nhật', 'Biên Phiên Dịch Tiếng Hàn'],

  // --- Media ---
  'phim-va-truyen-hinh-bao-chi-xuat-ban-cr612': ['Biên Tập Viên', 'Phóng Viên', 'Photographer / Video Editor', 'Nhân Viên Truyền Thông'],

  // --- Repair ---
  'tho-sua-chua': ['Thợ Sửa Chữa Điện', 'Thợ Điện Lạnh', 'Thợ Máy', 'Thợ Hàn', 'Thợ Cơ Khí'],

  // --- Other ---
  'nhom-nghe-khac-cr899': ['Nhân Viên Văn Phòng', 'Trợ Lý Giám Đốc', 'Nhân Viên Hỗ Trợ', 'Chuyên Viên Tổng Hợp'],
};

// Map each category slug → title family (which pool to draw from).
export const CATEGORY_FAMILY = {
  'nhan-vien-kinh-doanh': 'nhan-vien-kinh-doanh',
  'nhan-vien-sales': 'nhan-vien-sales',
  'nhan-vien-telesales': 'nhan-vien-telesales',
  'ke-toan': 'ke-toan', 'nhan-vien-ke-toan': 'nhan-vien-ke-toan',
  'ke-toan-tong-hop': 'ke-toan-tong-hop', 'kiem-toan': 'kiem-toan',
  'ngan-hang': 'ngan-hang',
  'marketing': 'marketing', 'nhan-vien-marketing': 'nhan-vien-marketing',
  'content-marketing': 'content-marketing', 'digital-marketing': 'digital-marketing',
  'hanh-chinh-nhan-su': 'hanh-chinh-nhan-su', 'nhan-vien-hanh-chinh': 'nhan-vien-hanh-chinh',
  'tuyen-dung-cr177cb178cl182': 'tuyen-dung-cr177cb178cl182',
  'nhan-vien-cham-soc-khach-hang': 'nhan-vien-cham-soc-khach-hang',
  'ky-su-xay-dung': 'ky-su-xay-dung', 'xay-dung-cr1080': 'xay-dung-cr1080',
  'ky-su-co-khi': 'ky-su-co-khi', 'thiet-ke-noi-that': 'thiet-ke-noi-that',
  'thiet-ke-do-hoa-designer': 'thiet-ke-do-hoa-designer', 'thiet-ke-cr826': 'thiet-ke-cr826',
  'bat-dong-san': 'bat-dong-san',
  'giao-duc': 'giao-duc', 'giao-vien-tieng-anh': 'giao-vien-tieng-anh',
  'duoc-y-te-suc-khoe-cong-nghe-sinh-hoc-cr781': 'duoc-y-te-suc-khoe-cong-nghe-sinh-hoc-cr781',
  'logistics-thu-mua-kho-van-tai-cr711': 'logistics-thu-mua-kho-van-tai-cr711', 'kho-van': 'kho-van',
  'san-xuat-cr417': 'san-xuat-cr417', 'cong-nhan-san-xuat': 'cong-nhan-san-xuat',
  'nha-hang-khach-san-du-lich-cr857': 'nha-hang-khach-san-du-lich-cr857', 'phuc-vu': 'phuc-vu',
  'dien-dien-tu-vien-thong-cr644': 'dien-dien-tu-vien-thong-cr644',
  'tai-xe-cr1010': 'tai-xe-cr1010',
  'luat-cr1014': 'luat-cr1014',
  'ban-le-dich-vu-doi-song-cr544': 'ban-le-dich-vu-doi-song-cr544', 'quan-ly-cua-hang': 'quan-ly-cua-hang',
  'nang-luong-moi-truong-nong-nghiep-cr883': 'nang-luong-moi-truong-nong-nghiep-cr883',
  'tu-van-chuyen-mon-cr750': 'tu-van-chuyen-mon-cr750',
  'bien-phien-dich-cr1013': 'bien-phien-dich-cr1013',
  'phim-va-truyen-hinh-bao-chi-xuat-ban-cr612': 'phim-va-truyen-hinh-bao-chi-xuat-ban-cr612',
  'tho-sua-chua': 'tho-sua-chua',
  'nhom-nghe-khac-cr899': 'nhom-nghe-khac-cr899',
  'lap-trinh-vien': 'lap-trinh-vien',
  'backend-developer': 'backend-developer',
  'frontend-developer': 'frontend-developer',
  'devops': 'devops',
  'tester': 'tester',
  // IT umbrella categories
  'cong-nghe-thong-tin-cr257': 'it',
};
