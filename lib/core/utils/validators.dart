/// Form validators mirroring backend/src/validators/*.js limits and
/// Vietnamese messages (Zod schemas).
class Validators {
  const Validators._();

  static final _emailRe = RegExp(r'^[^\s@]+@[^\s@]+\.[a-zA-Z]{2,}$');
  static final _phoneRe = RegExp(r'^\+?[0-9\s().-]{8,20}$');
  static final _urlRe = RegExp(r'^(https?://)?[\w.-]+\.[a-z]{2,}(/\S*)?$', caseSensitive: false);

  static String? required(String? v, {String label = 'Trường này'}) {
    if (v == null || v.trim().isEmpty) return '$label là bắt buộc.';
    return null;
  }

  // authValidator: email trim+lowercase, max 254
  static String? email(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Email là bắt buộc.';
    if (s.length > 254 || !_emailRe.hasMatch(s)) return 'Email không hợp lệ.';
    return null;
  }

  // authValidator: password 8-128, must contain a letter AND a digit so
  // "        " (8 spaces) or "aaaaaaaa" can't pass.
  static String? password(String? v) {
    final s = v ?? '';
    if (s.isEmpty) return 'Mật khẩu là bắt buộc.';
    if (s.length < 8) return 'Mật khẩu phải có ít nhất 8 ký tự.';
    if (s.length > 128) return 'Mật khẩu không được vượt quá 128 ký tự.';
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(s);
    final hasDigit = RegExp(r'[0-9]').hasMatch(s);
    if (!hasLetter || !hasDigit) {
      return 'Mật khẩu phải có cả chữ và số.';
    }
    return null;
  }

  static String? confirmPassword(String? v, String password) {
    if (v == null || v.isEmpty) return 'Vui lòng xác nhận mật khẩu.';
    if (v != password) return 'Mật khẩu xác nhận không khớp.';
    return null;
  }

  // fullName / contactName 2-100 (authValidator: min(2) → '… là bắt buộc.')
  static String? fullName(String? v, {String label = 'Họ tên'}) {
    final s = (v ?? '').trim();
    if (s.length < 2) return '$label là bắt buộc.';
    if (s.length > 100) return '$label tối đa 100 ký tự.';
    return null;
  }

  // companyName 2-255 (authValidator: min(2) → 'Tên công ty là bắt buộc.')
  static String? companyName(String? v) {
    final s = (v ?? '').trim();
    if (s.length < 2) return 'Tên công ty là bắt buộc.';
    if (s.length > 255) return 'Tên công ty tối đa 255 ký tự.';
    return null;
  }

  // phone 8-20
  static String? phone(String? v, {bool isRequired = true}) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return isRequired ? 'Số điện thoại là bắt buộc.' : null;
    if (!_phoneRe.hasMatch(s)) return 'Số điện thoại không hợp lệ.';
    return null;
  }

  // city 2-100
  static String? city(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Vui lòng chọn tỉnh/thành phố.';
    if (s.length < 2 || s.length > 100) return 'Tỉnh/thành phố không hợp lệ.';
    return null;
  }

  static String? gender(String? v) =>
      (v == null || v.isEmpty) ? 'Vui lòng chọn giới tính.' : null;

  static String? website(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return null;
    if (!_urlRe.hasMatch(s)) return 'Website không hợp lệ.';
    return null;
  }

  static String? maxLength(String? v, int max, {String label = 'Trường này'}) {
    if (v != null && v.length > max) return '$label tối đa $max ký tự.';
    return null;
  }

  static String? lengthBetween(String? v, int min, int max, {String label = 'Trường này'}) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return '$label là bắt buộc.';
    if (s.length < min) return '$label phải có ít nhất $min ký tự.';
    if (s.length > max) return '$label tối đa $max ký tự.';
    return null;
  }

  // jobValidator: title 3-150, description 10-10000
  static String? jobTitle(String? v) =>
      lengthBetween(v, 3, 150, label: 'Tiêu đề');
  static String? jobDescription(String? v) =>
      lengthBetween(v, 10, 10000, label: 'Mô tả công việc');
  static String? jobLocation(String? v) =>
      lengthBetween(v, 1, 150, label: 'Địa điểm làm việc');

  static String? nonNegativeInt(String? v, {String label = 'Giá trị', bool isRequired = false}) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return isRequired ? '$label là bắt buộc.' : null;
    final n = int.tryParse(s.replaceAll('.', '').replaceAll(',', ''));
    if (n == null || n < 0) return '$label phải là số không âm.';
    return null;
  }

  static String? positiveInt(String? v, {String label = 'Giá trị'}) {
    final n = int.tryParse((v ?? '').trim());
    if (n == null || n < 1) return '$label phải là số nguyên ≥ 1.';
    return null;
  }

  static String? salaryRange(num? min, num? max) {
    if (min != null && max != null && min > max) {
      return 'Lương tối thiểu phải nhỏ hơn hoặc bằng lương tối đa.';
    }
    return null;
  }

  static String? deadlineNotPast(DateTime? d) {
    if (d == null) return null;
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    if (d.isBefore(start)) return 'Hạn nộp hồ sơ phải là hôm nay hoặc trong tương lai.';
    return null;
  }

  // applicationValidator: cover letter ≤ 5000
  static String? coverLetter(String? v) =>
      maxLength(v, 5000, label: 'Thư giới thiệu');

  // resumeValidator / extract-cv: text ≥ 20 chars
  static String? resumeText(String? v) {
    final s = (v ?? '').trim();
    if (s.length < 20) return 'Nội dung CV phải có ít nhất 20 ký tự.';
    return null;
  }

  // systemConfigurationService
  static String? configNumber(String? v) {
    final n = num.tryParse((v ?? '').trim());
    if (n == null || !n.isFinite || n < 0) return 'Giá trị cấu hình phải là số không âm.';
    return null;
  }

  static String? configBoolean(String? v) {
    final s = (v ?? '').trim().toLowerCase();
    if (s != 'true' && s != 'false') return 'Giá trị cấu hình phải là true hoặc false.';
    return null;
  }

  static String? configString(String? v) =>
      (v ?? '').trim().isEmpty ? 'Giá trị cấu hình không được để trống.' : null;
}
