import 'package:flutter_test/flutter_test.dart';
import 'package:jobhub_prm393/core/utils/formatters.dart';

/// Formats [d] as dd/MM/yyyy the way the app displays dates.
String _dmy(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/'
    '${d.month.toString().padLeft(2, '0')}/${d.year}';

void main() {
  group('Formatters.salary', () {
    test('renders VND range in "trieu" units', () {
      expect(
        Formatters.salary(min: 25000000, max: 40000000),
        '25 - 40 triệu',
        reason: 'jobMapper.formatSalary: "25 - 40 triệu" cho min/max VND',
      );
    });

    test('negotiable => "Thỏa thuận"', () {
      expect(
        Formatters.salary(min: 25000000, max: 40000000, negotiable: true),
        'Thỏa thuận',
        reason: 'negotiable=true luôn bỏ qua min/max',
      );
    });

    test('both null => "Thỏa thuận"', () {
      expect(
        Formatters.salary(),
        'Thỏa thuận',
        reason: 'min==null && max==null => "Thỏa thuận"',
      );
    });

    test('min only => "Từ 25 triệu"', () {
      expect(
        Formatters.salary(min: 25000000),
        'Từ 25 triệu',
        reason: 'chỉ có min VND: "Từ N triệu"',
      );
    });

    test('max only => "Đến 40 triệu"', () {
      expect(
        Formatters.salary(max: 40000000),
        'Đến 40 triệu',
        reason: 'chỉ có max VND: "Đến N triệu"',
      );
    });

    test('non-VND currency keeps raw numbers with currency code', () {
      expect(
        Formatters.salary(min: 2500, max: 4000, currency: 'USD'),
        '2.500 - 4.000 USD',
        reason: 'currency != VND: số thô (nhóm nghìn vi_VN) + mã tiền tệ',
      );
      expect(
        Formatters.salary(min: 2500, currency: 'usd'),
        'Từ 2.500 usd',
        reason: 'so sánh currency sau toUpperCase, giữ mã gốc trong output',
      );
    });

    test('half-a-million values keep one decimal (vi separator ",")', () {
      expect(
        Formatters.salary(min: 25500000, max: 40500000),
        '25,5 - 40,5 triệu',
        reason: '_trieu làm tròn đến 1 chữ số thập phân, dấu phẩy vi_VN',
      );
    });
  });

  group('Formatters.salaryHome', () {
    test('renders en-dash range with currency suffix', () {
      expect(
        Formatters.salaryHome(min: 25000000, max: 40000000),
        '25 – 40 triệu VND',
        reason: 'format.js formatSalary dùng en-dash "–" và suffix "triệu VND"',
      );
    });

    test('both null => "Thỏa thuận" (khác chính tả với salary)', () {
      expect(
        Formatters.salaryHome(),
        'Thỏa thuận',
        reason: 'salaryHome dùng "Thỏa thuận", salary dùng "Thỏa thuận"',
      );
    });

    test('min only / max only variants', () {
      expect(Formatters.salaryHome(min: 25000000), 'Từ 25 triệu VND',
          reason: 'chỉ min: "Từ ..."');
      expect(Formatters.salaryHome(max: 40000000), 'Lên đến 40 triệu VND',
          reason: 'chỉ max: "Lên đến ..."');
    });

    test('rounds half units away from zero', () {
      expect(
        Formatters.salaryHome(min: 25500000, max: 40500000),
        '26 – 41 triệu VND',
        reason: 'tr() = (v/1e6).round(): 25.5→26, 40.5→41',
      );
    });
  });

  group('Formatters.postedText', () {
    final now = DateTime.now();

    test('posted today => "Đăng hôm nay"', () {
      expect(
        Formatters.postedText(now.subtract(const Duration(minutes: 30))),
        'Đăng hôm nay',
        reason: 'days <= 0 (cùng ngày) => "Đăng hôm nay"',
      );
    });

    test('createdAt in the future is still "Đăng hôm nay"', () {
      expect(
        Formatters.postedText(now.add(const Duration(hours: 3))),
        'Đăng hôm nay',
        reason: 'difference âm => inDays âm => days <= 0',
      );
    });

    test('null => "Đăng gần đây"', () {
      expect(Formatters.postedText(null), 'Đăng gần đây',
          reason: 'createdAt null => "Đăng gần đây"');
    });

    test('1 day ago => "Đăng 1 ngày trước"', () {
      expect(
        Formatters.postedText(now.subtract(const Duration(hours: 36))),
        'Đăng 1 ngày trước',
        reason: 'days == 1 có nhánh riêng (số 1 không có "s")',
      );
    });

    test('2 days ago => "Đăng 2 ngày trước"', () {
      expect(
        Formatters.postedText(now.subtract(const Duration(hours: 60))),
        'Đăng 2 ngày trước',
        reason: '1 < days < 7: "Đăng N ngày trước"',
      );
    });

    test('14 days ago => "Đăng 2 tuần trước"', () {
      expect(
        Formatters.postedText(now.subtract(const Duration(hours: 348))),
        'Đăng 2 tuần trước',
        reason: 'days >= 7 và weeks < 5: "Đăng N tuần trước"',
      );
    });

    test('45 days ago => "Đăng 1 tháng trước"', () {
      expect(
        Formatters.postedText(now.subtract(const Duration(hours: 1092))),
        'Đăng 1 tháng trước',
        reason: 'weeks >= 5: days ~/ 30 tháng',
      );
    });
  });

  group('Formatters.postedAgo', () {
    final now = DateTime.now();

    test('posted today => "hôm nay" (no prefix)', () {
      expect(
        Formatters.postedAgo(now.subtract(const Duration(minutes: 5))),
        'hôm nay',
        reason: 'postedAgo = postedText bỏ tiền tố "Đăng "',
      );
    });

    test('2 days ago => "2 ngày trước"', () {
      expect(
        Formatters.postedAgo(now.subtract(const Duration(hours: 60))),
        '2 ngày trước',
        reason: 'postedText "Đăng 2 ngày trước" bỏ prefix',
      );
    });

    test('null => "vừa đăng"', () {
      expect(Formatters.postedAgo(null), 'vừa đăng',
          reason:
              'null now short-circuits to a dedicated label rather than '
              'stripping to the bare "gần đây"');
    });
  });

  group('Formatters.deadlineFull', () {
    final now = DateTime.now();

    test('null => "Chưa cập nhật"', () {
      expect(Formatters.deadlineFull(null), 'Chưa cập nhật',
          reason: 'deadline null => "Chưa cập nhật"');
    });

    test('future deadline => "dd/MM/yyyy (còn N ngày)"', () {
      final dl = DateTime(now.year, now.month, now.day + 3);
      expect(
        Formatters.deadlineFull(dl),
        '${_dmy(dl)} (còn 3 ngày)',
        reason: 'hạn tương lai 3 ngày (so theo ngày local, bỏ phần giờ)',
      );
    });

    test('deadline today => "dd/MM/yyyy (hết hạn hôm nay)"', () {
      final dl = DateTime(now.year, now.month, now.day, 23, 59);
      expect(
        Formatters.deadlineFull(dl),
        '${_dmy(dl)} (hết hạn hôm nay)',
        reason: 'cùng ngày hiện tại => "(hết hạn hôm nay)" dù giờ còn lại',
      );
    });

    test('past deadline => "dd/MM/yyyy (đã hết hạn)"', () {
      final dl = DateTime(now.year, now.month, now.day - 1);
      expect(
        Formatters.deadlineFull(dl),
        '${_dmy(dl)} (đã hết hạn)',
        reason: 'hạn đã qua => "(đã hết hạn)"',
      );
    });

    test('time-of-day is ignored when counting days', () {
      final dl = DateTime(now.year, now.month, now.day + 2, 0, 1);
      expect(
        Formatters.deadlineFull(dl),
        '${_dmy(dl)} (còn 2 ngày)',
        reason: 'chỉ so ngày (year/month/day), không theo giờ tuyệt đối',
      );
    });
  });

  group('Formatters.daysUntil', () {
    final now = DateTime.now();

    test('null => null', () {
      expect(Formatters.daysUntil(null), isNull,
          reason: 'deadline null => trả null');
    });

    test('returns day difference for future/past dates', () {
      expect(
        Formatters.daysUntil(DateTime(now.year, now.month, now.day + 5)),
        5,
        reason: 'hạn sau 5 ngày => 5',
      );
      expect(
        Formatters.daysUntil(DateTime(now.year, now.month, now.day - 2)),
        -2,
        reason: 'hạn đã qua 2 ngày => -2',
      );
    });
  });

  group('Formatters.localeDateTime', () {
    test('contains dd/MM/yyyy date and HH:mm time', () {
      // Tháng/ngày 2 chữ số: format 'd/M/yyyy' trùng khớp dd/MM/yyyy.
      expect(
        Formatters.localeDateTime(DateTime.utc(2026, 12, 25, 14, 5, 9)),
        '14:05:09 25/12/2026',
        reason: 'format thật là HH:mm:ss d/M/yyyy (giờ:phút:giây trước ngày)',
      );
    });

    test('day/month are not zero-padded', () {
      expect(
        Formatters.localeDateTime(DateTime.utc(2026, 1, 5, 9, 30, 0)),
        '09:30:00 5/1/2026',
        reason: 'd/M/yyyy: 5/1 thay vì 05/01',
      );
    });
  });

  group('Formatters.date / dateTime / time', () {
    test('date formats as dd/MM/yyyy, null => "Chưa cập nhật"', () {
      expect(Formatters.date(DateTime.utc(2026, 1, 5)), '05/01/2026',
          reason: 'date() pad số 0 cho ngày/tháng (khác localeDateTime)');
      expect(Formatters.date(null), 'Chưa cập nhật',
          reason: 'date(null) => "Chưa cập nhật"');
    });

    test('dateTime formats as dd/MM/yyyy HH:mm, null => "-"', () {
      expect(Formatters.dateTime(DateTime.utc(2026, 1, 5, 9, 30)),
          '05/01/2026 09:30',
          reason: 'dateTime() = dd/MM/yyyy HH:mm');
      expect(Formatters.dateTime(null), '-', reason: 'dateTime(null) => "-"');
    });

    test('time formats as HH:mm, null => empty', () {
      expect(Formatters.time(DateTime.utc(2026, 1, 5, 9, 5)), '09:05',
          reason: 'time() = HH:mm');
      expect(Formatters.time(null), '', reason: 'time(null) => ""');
    });
  });

  group('Formatters.relative', () {
    final now = DateTime.now();

    test('null => "-"', () {
      expect(Formatters.relative(null), '-', reason: 'relative(null) => "-"');
    });

    test('just now => "vừa xong"', () {
      expect(Formatters.relative(now), 'vừa xong',
          reason: 'dưới 1 phút => "vừa xong"');
    });

    test('minutes/hours/days buckets', () {
      expect(Formatters.relative(now.subtract(const Duration(minutes: 5))),
          '5 phút trước',
          reason: '1-59 phút => "N phút trước"');
      expect(Formatters.relative(now.subtract(const Duration(hours: 3))),
          '3 giờ trước',
          reason: '1-23 giờ => "N giờ trước"');
      expect(Formatters.relative(now.subtract(const Duration(hours: 60))),
          '2 ngày trước',
          reason: '1-6 ngày => "N ngày trước"');
    });

    test('7+ days falls back to dd/MM/yyyy', () {
      final d = now.subtract(const Duration(days: 8, hours: 6));
      expect(Formatters.relative(d), _dmy(d),
          reason: 'từ 7 ngày hiển thị ngày tuyệt đối dd/MM/yyyy');
    });
  });

  group('Formatters.number / compact', () {
    test('number groups thousands with vi_VN dots', () {
      expect(Formatters.number(30000), '30.000',
          reason: 'NumberFormat vi_VN: chấm phân cách nghìn');
      expect(Formatters.number(1250000), '1.250.000',
          reason: '1.250.000 với nhóm nghìn');
    });

    test('compact appends suffix (default "+")', () {
      expect(Formatters.compact(30000), '30.000+',
          reason: 'format.js formatCompact: 30000 → "30.000+"');
      expect(Formatters.compact(30000, suffix: ''), '30.000',
          reason: 'suffix tuỳ chỉnh được');
    });
  });

  group('Formatters.bytes / duration / percent', () {
    test('bytes picks B/KB/MB', () {
      expect(Formatters.bytes(512), '512 B', reason: '< 1024 => "N B"');
      expect(Formatters.bytes(2048), '2.0 KB', reason: 'KB với 1 chữ số thập phân');
      expect(Formatters.bytes(2 * 1024 * 1024), '2.0 MB',
          reason: '>= 1MB => MB');
    });

    test('duration renders ms below 1s, seconds above', () {
      expect(Formatters.duration(500), '500 ms', reason: '< 1000 => "N ms"');
      expect(Formatters.duration(1500), '1.5 s', reason: '>= 1000 => "N.N s"');
    });

    test('percent with configurable digits', () {
      expect(Formatters.percent(25), '25%', reason: 'digits mặc định 0');
      expect(Formatters.percent(25.555, digits: 1), '25.6%',
          reason: 'digits=1 làm tròn 25.555 → 25.6');
    });
  });

  group('CompanyDisplay.of', () {
    test('builds initials from first letters of up to 3 words', () {
      expect(CompanyDisplay.of('FPT Software').initials, 'FS',
          reason: '2 từ → 2 ký tự đầu, viết hoa');
      expect(CompanyDisplay.of('Công ty Cổ phần VNG').initials, 'CTC',
          reason: 'chỉ lấy 3 từ đầu: Công ty Cổ → CTC');
      expect(CompanyDisplay.of('VNG').initials, 'V',
          reason: '1 từ → 1 ký tự');
    });

    test('null/blank name falls back to placeholder', () {
      final display = CompanyDisplay.of(null);
      expect(display.name, 'Công ty chưa cập nhật',
          reason: 'null => tên placeholder');
      expect(display.initials, 'CTC',
          reason: 'placeholder 5 từ → monogram 3 từ đầu: Công ty chưa → CTC');
      expect(CompanyDisplay.of('   ').name, 'Công ty chưa cập nhật',
          reason: 'chuỗi toàn khoảng trắng cũng fallback');
    });

    test('trims surrounding whitespace before deriving name/initials', () {
      final display = CompanyDisplay.of('  FPT  ');
      expect(display.name, 'FPT', reason: 'name đã trim');
      expect(display.initials, 'F', reason: 'initials từ tên đã trim');
    });

    test('paletteIndex is stable for the same input and within 0..9', () {
      final a = CompanyDisplay.of('FPT Software');
      final b = CompanyDisplay.of('FPT Software');
      expect(a.paletteIndex, b.paletteIndex,
          reason: 'cùng đầu vào → cùng paletteIndex (hash tất định)');
      expect(a.paletteIndex, inInclusiveRange(0, 9),
          reason: 'hash % 10 luôn nằm trong 0..9');
      expect(a.initials, b.initials,
          reason: 'monogram cũng ổn định cùng đầu vào');
    });

    test('paletteIndex differs for at least some different names', () {
      final indexes = {
        for (final n in [
          'FPT Software',
          'VNG Corporation',
          'Viettel',
          'Samsung Vietnam',
          'Google',
          'Meta',
          'Amazon',
          'Shopee',
          'Grab',
          'MoMo',
          'Zalopay',
          'Tiki'
        ])
          CompanyDisplay.of(n).paletteIndex,
      };
      expect(indexes.length, greaterThan(1),
          reason: '12 công ty khác nhau phải rải vào nhiều hơn 1 palette');
    });
  });
}
