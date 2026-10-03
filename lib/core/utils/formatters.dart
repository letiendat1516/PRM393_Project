import 'package:intl/intl.dart';

/// Display helpers ported from frontend/src/utils/format.js and
/// frontend/src/utils/jobMapper.js (both conventions kept, named explicitly).
class Formatters {
  const Formatters._();

  static final _viNumber = NumberFormat.decimalPattern('vi_VN');
  static final _dateFmt = DateFormat('dd/MM/yyyy');
  static final _dateTimeFmt = DateFormat('dd/MM/yyyy HH:mm');
  static final _timeFmt = DateFormat('HH:mm');

  static String number(num v) => _viNumber.format(v);

  /// format.js formatCompact: 30000 → "30.000+".
  static String compact(num v, {String suffix = '+'}) => '${_viNumber.format(v)}$suffix';

  static String _trieu(num v) {
    final m = v / 1000000;
    final rounded = (m * 10).round() / 10;
    return rounded == rounded.roundToDouble()
        ? _viNumber.format(rounded.round())
        : _viNumber.format(rounded);
  }

  /// jobMapper.formatSalary — used by job cards/list items:
  /// "25 - 40 triệu" | "Từ 25 triệu" | "Đến 40 triệu" | "Thoả thuận".
  static String salary({
    num? min,
    num? max,
    String currency = 'VND',
    bool negotiable = false,
  }) {
    if (negotiable || (min == null && max == null)) return 'Thỏa thuận';
    if (currency.toUpperCase() != 'VND') {
      if (min != null && max != null) return '${number(min)} - ${number(max)} $currency';
      if (min != null) return 'Từ ${number(min)} $currency';
      return 'Đến ${number(max!)} $currency';
    }
    if (min != null && max != null) return '${_trieu(min)} - ${_trieu(max)} triệu';
    if (min != null) return 'Từ ${_trieu(min)} triệu';
    return 'Đến ${_trieu(max!)} triệu';
  }

  /// format.js formatSalary — homepage variant:
  /// "25 – 40 triệu VND" | "Từ 25 triệu VND" | "Lên đến 40 triệu VND" | "Thỏa thuận".
  static String salaryHome({num? min, num? max, String currency = 'VND'}) {
    if (min == null && max == null) return 'Thỏa thuận';
    String tr(num v) => _viNumber.format((v / 1000000).round());
    if (min != null && max != null) return '${tr(min)} – ${tr(max)} triệu $currency';
    if (min != null) return 'Từ ${tr(min)} triệu $currency';
    return 'Lên đến ${tr(max!)} triệu $currency';
  }

  static String date(DateTime? d) => d == null ? 'Chưa cập nhật' : _dateFmt.format(d);
  static String dateTime(DateTime? d) => d == null ? '-' : _dateTimeFmt.format(d);
  static String time(DateTime? d) => d == null ? '' : _timeFmt.format(d);

  /// toLocaleString('vi-VN') equivalent used on RecommendedPage.
  static String localeDateTime(DateTime d) => DateFormat('HH:mm:ss d/M/yyyy').format(d);

  /// jobMapper.getPostedText (with "Đăng " prefix).
  static String postedText(DateTime? createdAt) {
    if (createdAt == null) return 'Đăng gần đây';
    final days = DateTime.now().difference(createdAt).inDays;
    if (days <= 0) return 'Đăng hôm nay';
    if (days == 1) return 'Đăng 1 ngày trước';
    if (days < 7) return 'Đăng $days ngày trước';
    final weeks = days ~/ 7;
    if (weeks < 5) return 'Đăng $weeks tuần trước';
    final months = days ~/ 30;
    return 'Đăng $months tháng trước';
  }

  /// postedText without the "Đăng " prefix ("2 ngày trước"). The strip was
  /// swallowing the "gần đây" fallback into just "gần đây", losing meaning
  /// at a glance — null now short-circuits to a dedicated label.
  static String postedAgo(DateTime? createdAt) {
    if (createdAt == null) return 'vừa đăng';
    return postedText(createdAt).replaceFirst(RegExp(r'^Đăng\s*'), '');
  }

  /// jobMapper.deadlineFullLabel: "dd/MM/yyyy (còn N ngày)" |
  /// "(hết hạn hôm nay)" | "(đã hết hạn)".
  static String deadlineFull(DateTime? deadline) {
    if (deadline == null) return 'Chưa cập nhật';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(deadline.year, deadline.month, deadline.day);
    final diff = target.difference(today).inDays;
    final base = _dateFmt.format(deadline);
    if (diff > 0) return '$base (còn $diff ngày)';
    if (diff == 0) return '$base (hết hạn hôm nay)';
    return '$base (đã hết hạn)';
  }

  static int? daysUntil(DateTime? deadline) {
    if (deadline == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return DateTime(deadline.year, deadline.month, deadline.day).difference(today).inDays;
  }

  static String relative(DateTime? d) {
    if (d == null) return '-';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return _dateFmt.format(d);
  }

  static String bytes(int b) {
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static String duration(int ms) {
    if (ms < 1000) return '$ms ms';
    return '${(ms / 1000).toStringAsFixed(1)} s';
  }

  static String percent(num v, {int digits = 0}) => '${v.toStringAsFixed(digits)}%';
}

/// jobMapper.createCompanyDisplay — monogram + deterministic brand palette.
class CompanyDisplay {
  const CompanyDisplay({required this.name, required this.initials, required this.paletteIndex});
  final String name;
  final String initials;
  final int paletteIndex; // 0..9 → CompanyPalette.colors

  factory CompanyDisplay.of(String? rawName) {
    final name = (rawName ?? '').trim().isEmpty ? 'Công ty chưa cập nhật' : rawName!.trim();
    final words = name.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).take(3);
    final initials = words.map((w) => w[0]).join().toUpperCase();
    // hash = (hash * 31 + charCode) >>> 0 — unsigned 32-bit like the JS source
    var hash = 0;
    for (final cu in name.codeUnits) {
      hash = ((hash * 31) + cu) & 0xFFFFFFFF;
    }
    // `name` is non-empty (fallback above) so the first-letter mapping always
    // produces at least one char.
    return CompanyDisplay(
      name: name,
      initials: initials,
      paletteIndex: hash % 10,
    );
  }
}
