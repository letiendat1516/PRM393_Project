/**
 * TopCV category URLs + crawl budget config.
 *
 * Strategy note: TopCV is behind Cloudflare, which rate-limits after ~2 page
 * loads per browser session. To stay under the limit we crawl only
 * PAGES_PER_CATEGORY pages per category, each in its own fresh browser context
 * (= fresh Cloudflare session). Spread across many categories to reach the
 * total target.
 *
 *   categories × PAGES_PER_CATEGORY × 50 ≈ TOTAL_TARGET
 */

// [slug, displayName] — curated diverse job categories (real TopCV slugs).
export const CATEGORIES = [
  ["nhan-vien-kinh-doanh", "Nhân viên kinh doanh"],
  ["ke-toan", "Kế toán"],
  ["marketing", "Marketing"],
  ["hanh-chinh-nhan-su", "Hành chính nhân sự"],
  ["nhan-vien-cham-soc-khach-hang", "Chăm sóc khách hàng"],
  ["ngan-hang", "Ngân hàng"],
  ["ky-su-xay-dung", "Kỹ sư xây dựng"],
  ["thiet-ke-do-hoa-designer", "Thiết kế đồ hoạ"],
  ["bat-dong-san", "Bất động sản"],
  ["giao-duc", "Giáo dục"],
  ["nhan-vien-telesales", "Telesales"],
  ["cong-nghe-thong-tin-cr257", "IT - CNTT"],
  ["tu-van-chuyen-mon-cr750", "Tư vấn chuyên môn"],
  ["duoc-y-te-suc-khoe-cong-nghe-sinh-hoc-cr781", "Dược / Y tế"],
  ["logistics-thu-mua-kho-van-tai-cr711", "Logistics / Vận tải"],
  ["san-xuat-cr417", "Sản xuất"],
  ["nha-hang-khach-san-du-lich-cr857", "Nhà hàng / Khách sạn"],
  ["dien-dien-tu-vien-thong-cr644", "Điện / Điện tử / Viễn thông"],
  ["tai-xe-cr1010", "Tài xế"],
  ["luat-cr1014", "Luật / Pháp chế"],
  ["nang-luong-moi-truong-nong-nghiep-cr883", "Năng lượng / Môi trường"],
  ["ban-le-dich-vu-doi-song-cr544", "Bán lẻ / Dịch vụ"],
  ["tuyen-dung-cr177cb178cl182", "Tuyển dụng (HR)"],
  ["bien-phien-dich-cr1013", "Biên phiên dịch"],
  ["thiet-ke-cr826", "Thiết kế"],
  ["xay-dung-cr1080", "Xây dựng"],
  ["phim-va-truyen-hinh-bao-chi-xuat-ban-cr612", "Báo chí / Xuất bản"],
  ["nhom-nghe-khac-cr899", "Nghề khác"],
  ["content-marketing", "Content Marketing"],
  ["digital-marketing", "Digital Marketing"],
  ["nhan-vien-sales", "Nhân viên Sales"],
  ["lap-trinh-vien", "Lập trình viên"],
  ["nhan-vien-ke-toan", "Nhân viên Kế toán"],
  ["nhan-vien-marketing", "Nhân viên Marketing"],
  ["kiem-toan", "Kiểm toán"],
  ["giao-vien-tieng-anh", "Giáo viên tiếng Anh"],
  ["ky-su-co-khi", "Kỹ sư cơ khí"],
  ["thiet-ke-noi-that", "Thiết kế nội thất"],
  ["kho-van", "Kho vận"],
  ["cong-nhan-san-xuat", "Công nhân sản xuất"],
  ["kienv truc-su", "Kiến trúc sư"],
  ["backend-developer", "Backend Developer"],
  ["frontend-developer", "Frontend Developer"],
  ["tester", "Software Tester"],
  ["quan-ly-cua-hang", "Quản lý cửa hàng"],
  ["ke-toan-tong-hop", "Kế toán tổng hợp"],
  ["nhan-vien-hanh-chinh", "Nhân viên Hành chính"],
  ["phuc-vu", "Phục vụ"],
  ["tho-sua-chua", "Thợ sửa chữa"],
  ["devops", "DevOps Engineer"],
];

// Crawl budget. With manual CF-solving in headed mode you can crawl all
// pages. The crawler auto-detects total pages per category from the
// "Tìm thấy N tin đăng" counter, and stops at the last page.
// MAX_PAGES_PER_CATEGORY is just a safety cap (TopCV rarely exceeds 50).
export const PAGE_SIZE = 50;
export const MAX_PAGES_PER_CATEGORY = 50; // safety cap
export const PAGES_PER_CATEGORY = MAX_PAGES_PER_CATEGORY;

// Polite crawling
export const DELAY_BETWEEN_PAGES_MS = 3000; // 3s within a category
export const DELAY_BETWEEN_CATEGORIES_MS = 4000; // 4s between categories
export const MAX_RETRIES_PER_PAGE = 2;
export const NAV_TIMEOUT_MS = 60000;

export const BASE_URL = "https://www.topcv.vn";
