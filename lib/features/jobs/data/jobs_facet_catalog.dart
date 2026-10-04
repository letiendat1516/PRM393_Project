/// Known facet values for the public jobs catalogue — used by
/// [JobsRepository.aggregateFacetCounts] to run a parallel `.count()` per
/// value so the sidebar can show real server-side totals ("DevOps Engineer
/// (200)") instead of only what the 30-doc loaded window happens to contain
/// ("DevOps Engineer (30)" — the complaint "9800 job nhưng filter tổng vào
/// mới được 36 jobs").
///
/// Values must exactly match the Firestore `categoryName` / `city` field —
/// mirrored from a live scan of the jobs collection so missing-tail
/// mismatches ("IT - CNTT" ≠ "IT - Công nghệ thông tin") don't silently
/// hide a bucket.
class JobsFacetCatalog {
  const JobsFacetCatalog._();

  /// 49 canonical category labels — scanned from the live jobs collection
  /// on 2026-10-04. Order mirrors the DESC count sort at scan time so the
  /// biggest buckets land first in the sidebar before the server counts
  /// arrive.
  static const List<String> categories = [
    'Nhân viên kinh doanh',
    'Kế toán',
    'Marketing',
    'Hành chính nhân sự',
    'Chăm sóc khách hàng',
    'Ngân hàng',
    'Kỹ sư xây dựng',
    'Thiết kế đồ hoạ',
    'Bất động sản',
    'Giáo dục',
    'Telesales',
    'IT - Công nghệ thông tin',
    'Tư vấn chuyên môn',
    'Dược / Y tế',
    'Logistics / Vận tải',
    'Sản xuất',
    'Nhà hàng / Khách sạn',
    'Điện / Điện tử / Viễn thông',
    'Tài xế',
    'Luật / Pháp chế',
    'Năng lượng / Môi trường',
    'Bán lẻ / Dịch vụ',
    'Tuyển dụng (HR)',
    'Biên phiên dịch',
    'Thiết kế',
    'Xây dựng',
    'Báo chí / Xuất bản',
    'Nghề khác',
    'Content Marketing',
    'Digital Marketing',
    'Nhân viên Sales',
    'Lập trình viên',
    'Nhân viên Kế toán',
    'Nhân viên Marketing',
    'Kiểm toán',
    'Giáo viên tiếng Anh',
    'Kỹ sư cơ khí',
    'Thiết kế nội thất',
    'Kho vận',
    'Công nhân sản xuất',
    'Backend Developer',
    'Frontend Developer',
    'Software Tester',
    'Quản lý cửa hàng',
    'Kế toán tổng hợp',
    'Nhân viên Hành chính',
    'Phục vụ',
    'Thợ sửa chữa',
    'DevOps Engineer',
  ];

  /// Top-20 cities by job count (crawl-topcv/data/stats.json `locations`
  /// aggregate). Only the biggest buckets are queried server-side; the long
  /// tail falls back to the loaded-window counts, which is accurate enough
  /// for cities with ≤ a handful of jobs.
  static const List<String> cities = [
    'Hồ Chí Minh',
    'Hà Nội',
    'Bình Dương',
    'Đà Nẵng',
    'Đồng Nai',
    'Bắc Ninh',
    'Hải Phòng',
    'Nghệ An',
    'Thanh Hóa',
    'Hải Dương',
    'Cần Thơ',
    'Hưng Yên',
    'Lào Cai',
    'Quảng Ninh',
    'Thái Nguyên',
    'Vĩnh Phúc',
    'Bắc Giang',
    'Khánh Hòa',
    'Long An',
    'Thừa Thiên Huế',
  ];
}
