import 'package:flutter_test/flutter_test.dart';
import 'package:jobhub_prm393/core/utils/validators.dart';

/// Tests cho lib/core/utils/validators.dart — message strings lấy verbatim từ lib.
void main() {
  group('Validators.email', () {
    test('email hợp lệ → null', () {
      expect(Validators.email('dat.nguyen@gmail.com'), isNull,
          reason: 'Email chuẩn phải hợp lệ.');
    });

    test('email hợp lệ có dấu chấm, plus-tag và TLD nhiều cấp → null', () {
      expect(Validators.email('user.name+tag@company.co.vn'), isNull,
          reason: 'Email chuẩn với plus-tag phải hợp lệ.');
    });

    test('email có khoảng trắng bao quanh được trim → null', () {
      expect(Validators.email('  dat@gmail.com  '), isNull,
          reason: 'Lib trim trước khi kiểm tra nên vẫn hợp lệ.');
    });

    test('email thiếu @ → "Email không hợp lệ."', () {
      expect(Validators.email('usergmail.com'), 'Email không hợp lệ.',
          reason: 'Thiếu @ phải bị từ chối.');
    });

    test('email chứa khoảng trắng trong local part → "Email không hợp lệ."', () {
      expect(Validators.email('user name@gmail.com'), 'Email không hợp lệ.',
          reason: 'Khoảng trắng trong email phải bị từ chối.');
    });

    test('email chứa khoảng trắng trong domain → "Email không hợp lệ."', () {
      expect(Validators.email('user@mai l.com'), 'Email không hợp lệ.',
          reason: 'Khoảng trắng trong domain phải bị từ chối.');
    });

    test('email thiếu TLD (không có dấu chấm) → "Email không hợp lệ."', () {
      expect(Validators.email('user@gmail'), 'Email không hợp lệ.',
          reason: 'Domain không có dấu chấm (thiếu TLD) phải bị từ chối.');
    });

    test('TLD 1 ký tự bị từ chối (regex yêu cầu [a-zA-Z]{2,})', () {
      expect(Validators.email('a@b.c'), 'Email không hợp lệ.',
          reason: 'TLD 1 ký tự ("c") không thoả quy tắc ≥2 chữ cái.');
    });

    test('TLD 2 ký tự hợp lệ ("a@b.co" → null)', () {
      expect(Validators.email('a@b.co'), isNull);
    });

    test('email rỗng → "Email là bắt buộc."', () {
      expect(Validators.email(''), 'Email là bắt buộc.',
          reason: 'Chuỗi rỗng phải trả về message bắt buộc.');
    });

    test('email chỉ chứa whitespace → "Email là bắt buộc."', () {
      expect(Validators.email('   '), 'Email là bắt buộc.',
          reason: 'Whitespace sau khi trim là rỗng → message bắt buộc.');
    });

    test('email null → "Email là bắt buộc."', () {
      expect(Validators.email(null), 'Email là bắt buộc.',
          reason: 'Null phải trả về message bắt buộc.');
    });

    test('email dài hơn 254 ký tự → "Email không hợp lệ."', () {
      final long = '${'a' * 250}@x.io'; // 255 ký tự
      expect(long.length, 254 + 1, reason: 'Đảm bảo dữ liệu đầu vào dài 255 ký tự.');
      expect(Validators.email(long), 'Email không hợp lệ.',
          reason: 'Lib giới hạn email tối đa 254 ký tự.');
    });
  });

  group('Validators.password', () {
    test('mật khẩu hợp lệ "Abcdef12" → null', () {
      expect(Validators.password('Abcdef12'), isNull,
          reason: 'Mật khẩu 8 ký tự hợp lệ.');
    });

    test('đúng 8 ký tự số không chữ → "Mật khẩu phải có cả chữ và số."', () {
      expect(Validators.password('12345678'), 'Mật khẩu phải có cả chữ và số.',
          reason: '8 số thuần không có chữ bị từ chối theo quy tắc strength.');
    });

    test('8 ký tự có chữ+số ("Abcdef12") → null', () {
      expect(Validators.password('Abcdef12'), isNull);
    });

    test('128 ký tự thuần "a" (không chữ số) → "Mật khẩu phải có cả chữ và số."', () {
      expect(Validators.password('a' * 128), 'Mật khẩu phải có cả chữ và số.',
          reason: 'Dài 128 nhưng thiếu chữ số → bị từ chối.');
    });

    test('128 ký tự có chữ+số ("a" * 127 + "1") → null', () {
      expect(Validators.password('${'a' * 127}1'), isNull);
    });

    test('8 khoảng trắng bị từ chối (strength check)', () {
      expect(Validators.password('        '),
          'Mật khẩu phải có cả chữ và số.');
    });

    test('7 ký tự → "Mật khẩu phải có ít nhất 8 ký tự."', () {
      expect(Validators.password('Abcdef1'), 'Mật khẩu phải có ít nhất 8 ký tự.',
          reason: 'Ngắn hơn 8 ký tự phải bị từ chối.');
    });

    test('129 ký tự → "Mật khẩu không được vượt quá 128 ký tự."', () {
      // Length check runs before strength check, so 129-char all-letters
      // still trips the length rule first.
      expect(Validators.password('a' * 129),
          'Mật khẩu không được vượt quá 128 ký tự.',
          reason: 'Dài hơn 128 ký tự phải bị từ chối.');
    });

    test('rỗng → "Mật khẩu là bắt buộc."', () {
      expect(Validators.password(''), 'Mật khẩu là bắt buộc.',
          reason: 'Chuỗi rỗng phải trả về message bắt buộc.');
    });

    test('null → "Mật khẩu là bắt buộc."', () {
      expect(Validators.password(null), 'Mật khẩu là bắt buộc.',
          reason: 'Null phải trả về message bắt buộc.');
    });
  });

  group('Validators.fullName', () {
    test('hợp lệ → null', () {
      expect(Validators.fullName('Nguyễn Văn A'), isNull,
          reason: 'Tên đầy đủ hợp lệ.');
    });

    test('tên có whitespace bao quanh được trim → null', () {
      expect(Validators.fullName('  Dat Tran  '), isNull,
          reason: 'Lib trim trước khi đo độ dài.');
    });

    test('rỗng → "Họ tên là bắt buộc." (label mặc định của lib)', () {
      expect(Validators.fullName(''), 'Họ tên là bắt buộc.',
          reason: 'Label mặc định trong lib là "Họ tên" (không phải "Họ và tên").');
    });

    test('null → "Họ tên là bắt buộc."', () {
      expect(Validators.fullName(null), 'Họ tên là bắt buộc.',
          reason: 'Null → label mặc định + " là bắt buộc.".');
    });

    test('chỉ whitespace → "Họ tên là bắt buộc."', () {
      expect(Validators.fullName('   '), 'Họ tên là bắt buộc.',
          reason: 'Whitespace sau trim rỗng, độ dài < 2 → bắt buộc.');
    });

    test('1 ký tự (sau trim < 2) → "Họ tên là bắt buộc."', () {
      expect(Validators.fullName('D'), 'Họ tên là bắt buộc.',
          reason: 'Lib coi độ dài sau trim < 2 là "bắt buộc" (min(2) kiểu Zod).');
    });

    test('vượt 100 ký tự → "Họ tên tối đa 100 ký tự."', () {
      expect(Validators.fullName('a' * 101), 'Họ tên tối đa 100 ký tự.',
          reason: 'Giới hạn 100 ký tự.');
    });

    test('label tùy chỉnh được nối vào message: "Họ và tên là bắt buộc."', () {
      expect(Validators.fullName('', label: 'Họ và tên'), 'Họ và tên là bắt buộc.',
          reason: 'Label param cho phép đổi chuỗi thông báo.');
    });
  });

  group('Validators.companyName', () {
    test('hợp lệ → null', () {
      expect(Validators.companyName('FPT Software'), isNull,
          reason: 'Tên công ty hợp lệ.');
    });

    test('rỗng → "Tên công ty là bắt buộc."', () {
      expect(Validators.companyName(''), 'Tên công ty là bắt buộc.',
          reason: 'Chuỗi rỗng phải trả về message bắt buộc.');
    });

    test('null → "Tên công ty là bắt buộc."', () {
      expect(Validators.companyName(null), 'Tên công ty là bắt buộc.',
          reason: 'Null phải trả về message bắt buộc.');
    });

    test('chỉ whitespace → "Tên công ty là bắt buộc."', () {
      expect(Validators.companyName('   '), 'Tên công ty là bắt buộc.',
          reason: 'Whitespace sau trim rỗng, độ dài < 2 → bắt buộc.');
    });

    test('vượt 255 ký tự → "Tên công ty tối đa 255 ký tự."', () {
      expect(Validators.companyName('a' * 256), 'Tên công ty tối đa 255 ký tự.',
          reason: 'Giới hạn 255 ký tự.');
    });

    test('đúng 255 ký tự (boundary) → null', () {
      expect(Validators.companyName('a' * 255), isNull,
          reason: 'Độ dài 255 là hợp lệ theo lib.');
    });
  });

  group('Validators.salaryRange', () {
    test('min > max → "Lương tối thiểu phải nhỏ hơn hoặc bằng lương tối đa."', () {
      expect(Validators.salaryRange(1000, 500),
          'Lương tối thiểu phải nhỏ hơn hoặc bằng lương tối đa.',
          reason: 'min > max phải bị từ chối.');
    });

    test('min < max → null', () {
      expect(Validators.salaryRange(500, 1000), isNull,
          reason: 'min < max là hợp lệ.');
    });

    test('min == max → null', () {
      expect(Validators.salaryRange(1000, 1000), isNull,
          reason: 'Lib cho phép min == max ("nhỏ hơn hoặc bằng").');
    });

    test('min null, max có giá trị → null', () {
      expect(Validators.salaryRange(null, 1000), isNull,
          reason: 'Lib chỉ kiểm tra khi cả hai đều khác null.');
    });

    test('min có giá trị, max null → null', () {
      expect(Validators.salaryRange(1000, null), isNull,
          reason: 'Lib chỉ kiểm tra khi cả hai đều khác null.');
    });

    test('cả hai null → null', () {
      expect(Validators.salaryRange(null, null), isNull,
          reason: 'Null inputs được lib bỏ qua.');
    });
  });

  group('Validators.deadlineNotPast', () {
    // Lib so với 00:00 (midnight) giờ LOCAL của máy chạy test, nên boundary
    // "hôm nay" phải dựng theo local; các mốc xa thì dùng DateTime.utc.
    final now = DateTime.now();
    final todayLocal = DateTime(now.year, now.month, now.day);

    test('ngày trong quá khứ → "Hạn nộp hồ sơ phải là hôm nay hoặc trong tương lai."', () {
      expect(Validators.deadlineNotPast(DateTime.utc(2020, 1, 1)),
          'Hạn nộp hồ sơ phải là hôm nay hoặc trong tương lai.',
          reason: 'Ngày trước hôm nay phải bị từ chối.');
    });

    test('hôm qua (local) → message lỗi', () {
      final yesterday = todayLocal.subtract(const Duration(days: 1));
      expect(Validators.deadlineNotPast(yesterday),
          'Hạn nộp hồ sơ phải là hôm nay hoặc trong tương lai.',
          reason: 'Hôm qua là quá khứ so với đầu ngày hôm nay.');
    });

    test('đúng đầu ngày hôm nay (local) → null', () {
      expect(Validators.deadlineNotPast(todayLocal), isNull,
          reason: 'Hôm nay (tính từ 00:00) là hợp lệ theo lib.');
    });

    test('ngày mai (local) → null', () {
      final tomorrow = todayLocal.add(const Duration(days: 1));
      expect(Validators.deadlineNotPast(tomorrow), isNull,
          reason: 'Ngày tương lai là hợp lệ.');
    });

    test('ngày xa trong tương lai (DateTime.utc) → null', () {
      expect(Validators.deadlineNotPast(DateTime.utc(2999, 12, 31)), isNull,
          reason: 'Ngày tương lai xa là hợp lệ.');
    });

    test('null → null (không bắt buộc)', () {
      expect(Validators.deadlineNotPast(null), isNull,
          reason: 'Lib bỏ qua giá trị null.');
    });
  });

  group('Validators.phone', () {
    test('số điện thoại hợp lệ → null', () {
      expect(Validators.phone('0901234567'), isNull,
          reason: 'Số VN 10 chữ số hợp lệ.');
    });

    test('số có mã quốc gia và khoảng trắng → null', () {
      expect(Validators.phone('+84 901 234 567'), isNull,
          reason: 'Regex cho phép +, space, ().- và 8-20 ký tự.');
    });

    test('rỗng (mặc định isRequired) → "Số điện thoại là bắt buộc."', () {
      expect(Validators.phone(''), 'Số điện thoại là bắt buộc.',
          reason: 'Mặc định isRequired = true.');
    });

    test('null (isRequired: false) → null', () {
      expect(Validators.phone(null, isRequired: false), isNull,
          reason: 'Không bắt buộc thì empty/null được bỏ qua.');
    });

    test('chứa chữ cái → "Số điện thoại không hợp lệ."', () {
      expect(Validators.phone('abc12345'), 'Số điện thoại không hợp lệ.',
          reason: 'Chỉ được chứa số và +, space, ().-');
    });

    test('quá ngắn (dưới 8 ký tự) → "Số điện thoại không hợp lệ."', () {
      expect(Validators.phone('123'), 'Số điện thoại không hợp lệ.',
          reason: 'Regex yêu cầu tối thiểu 8 ký tự.');
    });
  });

  group('Validators.required', () {
    test('null → "Trường này là bắt buộc."', () {
      expect(Validators.required(null), 'Trường này là bắt buộc.',
          reason: 'Label mặc định là "Trường này".');
    });

    test('whitespace → "Trường này là bắt buộc."', () {
      expect(Validators.required('   '), 'Trường này là bắt buộc.',
          reason: 'Lib trim trước khi kiểm tra rỗng.');
    });

    test('có giá trị với label tùy chỉnh → null', () {
      expect(Validators.required('Hà Nội', label: 'Tỉnh/thành phố'), isNull,
          reason: 'Có giá trị không trắng thì hợp lệ.');
    });
  });

  group('Validators.website', () {
    test('rỗng → null (không bắt buộc)', () {
      expect(Validators.website(''), isNull,
          reason: 'Website là trường tùy chọn trong lib.');
    });

    test('URL hợp lệ → null', () {
      expect(Validators.website('https://jobhub.vn'), isNull,
          reason: 'URL chuẩn hợp lệ.');
    });

    test('không phải URL → "Website không hợp lệ."', () {
      expect(Validators.website('not a url'), 'Website không hợp lệ.',
          reason: 'Không khớp regex URL (thiếu domain.TLD).');
    });
  });
}
