import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jobhub_prm393/core/services/prefs_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Unit tests cho [PrefsService] (SharedPreferences wrapper):
/// giá trị mặc định, set/get từng preference, remove khi set null,
/// merge notification types + JSON hỏng, push/clear từ khoá tìm kiếm
/// (cap 8 — đề bài gốc ghi 10 nhưng code thật là .take(8), test theo code),
/// round-trip jobDraft/cachedUser qua JSON và contract 12 key thô.
///
/// Lưu ý: [PrefsService.init] là singleton tĩnh nên cả file chỉ init đúng
/// 1 lần trong setUpAll; các test dùng chung store và chạy theo thứ tự khai
/// báo (nhóm "giá trị mặc định" phải đứng trước các nhóm set dữ liệu).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PrefsService svc;

  setUpAll(() async {
    // Duy nhất 1 lần setMockInitialValues + init: mọi test phía sau chia sẻ
    // cùng một store mock của singleton (viết kiểu tích luỹ trạng thái).
    SharedPreferences.setMockInitialValues(<String, Object>{});
    svc = await PrefsService.init();
  });

  group('PrefsService — giá trị mặc định (store trống)', () {
    test('các getter chuỗi trả null khi chưa set', () {
      expect(svc.themeMode, isNull, reason: 'theme_mode chưa được set');
      expect(svc.rememberEmail, isNull, reason: 'remember_email chưa được set');
      expect(svc.lastRole, isNull, reason: 'last_role chưa được set');
      expect(svc.fcmToken, isNull, reason: 'fcm_token chưa được set');
    });

    test('locale mặc định là "vi"', () {
      expect(
        svc.locale,
        'vi',
        reason: 'getter locale phải fallback về "vi" khi key vắng',
      );
    });

    test('bool mặc định: rememberMe/notificationsEnabled bật, onboarding tắt',
        () {
      expect(svc.rememberMe, isTrue, reason: 'remember_me mặc định true');
      expect(
        svc.notificationsEnabled,
        isTrue,
        reason: 'notifications_enabled mặc định true',
      );
      expect(
        svc.onboardingDone,
        isFalse,
        reason: 'onboarding_done mặc định false',
      );
      expect(
        svc.isFirstLaunch,
        isTrue,
        reason: 'chưa qua onboarding → isFirstLaunch true',
      );
    });

    test('list/map/object mặc định: rỗng hoặc null, type vắng coi như bật',
        () {
      expect(
        svc.lastSearchKeywords,
        isEmpty,
        reason: 'last_search_keywords mặc định []',
      );
      expect(
        svc.notificationTypes,
        isEmpty,
        reason: 'notification_types mặc định {} (không có key)',
      );
      expect(
        svc.isNotificationTypeEnabled('APPLICATION_STATUS'),
        isTrue,
        reason: 'type chưa từng set → isNotificationTypeEnabled mặc định true',
      );
      expect(svc.jobDraft, isNull, reason: 'job_draft mặc định null');
      expect(svc.cachedUser, isNull, reason: 'cached_user mặc định null');
    });
  });

  group('PrefsService — init singleton', () {
    test('init() lần 2 và instance trả về đúng một đối tượng', () async {
      final second = await PrefsService.init();
      expect(
        identical(second, svc),
        isTrue,
        reason: 'init() dùng _instance ??= → lần 2 trả lại instance cũ',
      );
      expect(
        identical(PrefsService.instance, svc),
        isTrue,
        reason: 'getter instance phải trả đúng instance đã init',
      );
    });
  });

  group('PrefsService — themeMode', () {
    test('setThemeMode("dark") lưu chuỗi thô dưới key "theme_mode"', () async {
      await svc.setThemeMode('dark');
      expect(svc.themeMode, 'dark', reason: 'getter đọc lại giá trị vừa set');
      expect(
        svc.prefs.getString('theme_mode'),
        'dark',
        reason: 'Giá trị thô nằm dưới key "theme_mode"',
      );
    });

    test('setThemeMode(null) remove key → getter về null', () async {
      await svc.setThemeMode('light');
      expect(
        svc.themeMode,
        'light',
        reason: 'Tiền điều kiện: key đang có giá trị',
      );
      await svc.setThemeMode(null);
      expect(svc.themeMode, isNull, reason: 'set null → về default null');
      expect(
        svc.prefs.getString('theme_mode'),
        isNull,
        reason: 'setThemeMode(null) phải remove key "theme_mode"',
      );
    });
  });

  group('PrefsService — locale', () {
    test('setLocale("en") lưu và đọc lại dưới key "locale"', () async {
      await svc.setLocale('en');
      expect(svc.locale, 'en', reason: 'getter locale đọc lại "en"');
      expect(
        svc.prefs.getString('locale'),
        'en',
        reason: 'Giá trị thô nằm dưới key "locale"',
      );
    });
  });

  group('PrefsService — rememberEmail', () {
    test('set → get; set null → remove key', () async {
      await svc.setRememberEmail('nguoidung@jobhub.vn');
      expect(
        svc.rememberEmail,
        'nguoidung@jobhub.vn',
        reason: 'Getter đọc lại email vừa lưu',
      );
      expect(
        svc.prefs.getString('remember_email'),
        'nguoidung@jobhub.vn',
        reason: 'Giá trị thô nằm dưới key "remember_email"',
      );

      await svc.setRememberEmail(null);
      expect(
        svc.rememberEmail,
        isNull,
        reason: 'set null phải remove key → getter về default',
      );
      expect(
        svc.prefs.getString('remember_email'),
        isNull,
        reason: 'Key "remember_email" phải bị remove khỏi store',
      );
    });

    test('set chuỗi rỗng "" cũng remove key (coi như không nhớ email)',
        () async {
      await svc.setRememberEmail('tam_thoi@jobhub.vn');
      expect(
        svc.rememberEmail,
        'tam_thoi@jobhub.vn',
        reason: 'Tiền điều kiện: key đang có email',
      );

      await svc.setRememberEmail('');
      expect(
        svc.rememberEmail,
        isNull,
        reason: 'Chuỗi rỗng phải được xử lý như null (remove key)',
      );
      expect(
        svc.prefs.getString('remember_email'),
        isNull,
        reason: 'Key "remember_email" phải bị remove khi set ""',
      );
    });
  });

  group('PrefsService — rememberMe / lastRole', () {
    test('setRememberMe(false) tắt và ghi bool thô', () async {
      await svc.setRememberMe(false);
      expect(svc.rememberMe, isFalse, reason: 'Getter đọc lại false');
      expect(
        svc.prefs.getBool('remember_me'),
        isFalse,
        reason: 'Giá trị thô nằm dưới key "remember_me"',
      );
    });

    test('setLastRole set/xoá role gần nhất', () async {
      await svc.setLastRole('employer');
      expect(svc.lastRole, 'employer', reason: 'Getter đọc lại role vừa lưu');
      expect(
        svc.prefs.getString('last_role'),
        'employer',
        reason: 'Giá trị thô nằm dưới key "last_role"',
      );

      await svc.setLastRole(null);
      expect(svc.lastRole, isNull, reason: 'set null → remove key');
      expect(
        svc.prefs.getString('last_role'),
        isNull,
        reason: 'Key "last_role" phải bị remove khỏi store',
      );
    });
  });

  group('PrefsService — notification toggles', () {
    test('setNotificationsEnabled(false) tắt công tắc chung', () async {
      await svc.setNotificationsEnabled(false);
      expect(
        svc.notificationsEnabled,
        isFalse,
        reason: 'Getter đọc lại false',
      );
      expect(
        svc.prefs.getBool('notifications_enabled'),
        isFalse,
        reason: 'Giá trị thô nằm dưới key "notifications_enabled"',
      );
    });

    test('setNotificationType ghi JSON dưới key "notification_types" và merge',
        () async {
      await svc.setNotificationType('APPLICATION_STATUS', false);
      expect(
        svc.notificationTypes,
        {'APPLICATION_STATUS': false},
        reason: 'Type đầu tiên được lưu thành map 1 phần tử',
      );
      final raw1 = svc.prefs.getString('notification_types');
      expect(raw1, isNotNull, reason: 'Dữ liệu thô phải là chuỗi JSON');
      expect(
        jsonDecode(raw1!) as Map<String, dynamic>,
        {'APPLICATION_STATUS': false},
        reason: 'JSON thô dưới key "notification_types" khớp map đã set',
      );

      await svc.setNotificationType('NEW_APPLICATION', true);
      expect(
        svc.notificationTypes,
        {'APPLICATION_STATUS': false, 'NEW_APPLICATION': true},
        reason: 'Set type mới phải merge, không mất type đã có',
      );
    });

    test('isNotificationTypeEnabled: type đã tắt → false, type vắng → true',
        () {
      // Tiền điều kiện (từ test liền trước):
      // APPLICATION_STATUS=false, NEW_APPLICATION=true.
      expect(
        svc.isNotificationTypeEnabled('APPLICATION_STATUS'),
        isFalse,
        reason: 'Type đã được tắt rõ ràng phải trả false',
      );
      expect(
        svc.isNotificationTypeEnabled('NEW_APPLICATION'),
        isTrue,
        reason: 'Type đã được bật rõ ràng phải trả true',
      );
      expect(
        svc.isNotificationTypeEnabled('SYSTEM'),
        isTrue,
        reason: 'Type chưa từng set → fallback mặc định true',
      );
    });

    test('JSON hỏng dưới "notification_types" → map rỗng, mọi type coi như bật',
        () async {
      // Bơm trực tiếp chuỗi không phải JSON vào store (giả lập dữ liệu hỏng).
      await svc.prefs.setString('notification_types', 'not-json');
      expect(
        svc.notificationTypes,
        isEmpty,
        reason: 'JSON hỏng phải được nuốt lặng (try/catch) → const {}',
      );
      expect(
        svc.isNotificationTypeEnabled('APPLICATION_STATUS'),
        isTrue,
        reason: 'Map rỗng → type vắng → mặc định true',
      );
    });

    test('giá trị non-bool trong JSON bị ép thành false (v == true)', () async {
      // jsonDecode cho String/int; chỉ bool true mới giữ true.
      await svc.prefs.setString(
        'notification_types',
        jsonEncode(<String, dynamic>{
          'APPLICATION_STATUS': 'yes',
          'NEW_APPLICATION': 1,
        }),
      );
      expect(
        svc.notificationTypes,
        {'APPLICATION_STATUS': false, 'NEW_APPLICATION': false},
        reason: 'Không phải bool true (chuỗi "yes", số 1) đều thành false',
      );
    });
  });

  group('PrefsService — onboarding / isFirstLaunch', () {
    test('setOnboardingDone(true) → done true, isFirstLaunch false', () async {
      await svc.setOnboardingDone(true);
      expect(svc.onboardingDone, isTrue, reason: 'onboarding_done được ghi');
      expect(
        svc.prefs.getBool('onboarding_done'),
        isTrue,
        reason: 'Giá trị thô nằm dưới key "onboarding_done"',
      );
      expect(
        svc.isFirstLaunch,
        isFalse,
        reason: 'Đã qua onboarding → không còn là lần đầu mở app',
      );

      // Đặt lại false để xác nhận semantics đảo chiều.
      await svc.setOnboardingDone(false);
      expect(svc.onboardingDone, isFalse, reason: 'Ghi lại false');
      expect(
        svc.isFirstLaunch,
        isTrue,
        reason: 'onboardingDone false → isFirstLaunch true',
      );
    });
  });

  group('PrefsService — fcmToken', () {
    test('set → get; set null → remove key', () async {
      await svc.setFcmToken('fcm-token-123');
      expect(svc.fcmToken, 'fcm-token-123', reason: 'Getter đọc lại token');
      expect(
        svc.prefs.getString('fcm_token'),
        'fcm-token-123',
        reason: 'Giá trị thô nằm dưới key "fcm_token"',
      );

      await svc.setFcmToken(null);
      expect(svc.fcmToken, isNull, reason: 'set null → remove key');
      expect(
        svc.prefs.getString('fcm_token'),
        isNull,
        reason: 'Key "fcm_token" phải bị remove (đăng xuất/xoá device)',
      );
    });
  });

  group('PrefsService — lastSearchKeywords', () {
    test('pushSearchKeyword trim khoảng trắng và đặt mới nhất lên đầu',
        () async {
      await svc.clearSearchKeywords();
      await svc.pushSearchKeyword('flutter');
      await svc.pushSearchKeyword('  react native  ');
      expect(
        svc.lastSearchKeywords,
        ['react native', 'flutter'],
        reason: 'Từ khoá phải được trim và từ mới nhất đứng đầu danh sách',
      );
    });

    test('push từ khoá rỗng/toàn khoảng trắng → no-op', () async {
      await svc.clearSearchKeywords();
      await svc.pushSearchKeyword('dart');
      await svc.pushSearchKeyword('   ');
      await svc.pushSearchKeyword('');
      expect(
        svc.lastSearchKeywords,
        ['dart'],
        reason: 'Từ khoá rỗng sau trim phải bị bỏ qua, không đổi danh sách',
      );
    });

    test('trùng không phân biệt hoa thường → giữ bản push mới nhất ở đầu',
        () async {
      await svc.clearSearchKeywords();
      await svc.pushSearchKeyword('react');
      await svc.pushSearchKeyword('Flutter');
      await svc.pushSearchKeyword('FLUTTER');
      expect(
        svc.lastSearchKeywords,
        ['FLUTTER', 'react'],
        reason: 'Dedupe case-insensitive: bản mới nhất (FLUTTER) thay thế bản'
            ' cũ (Flutter) và đứng đầu, không nhân bản phần tử',
      );
    });

    test('push 10 từ khoá khác nhau → chỉ giữ 8 từ mới nhất', () async {
      // GHI CHÚ: đề bài gốc ghi cap 10 nhưng code thật là .take(8)
      // → test theo hành vi thật của code (8).
      await svc.clearSearchKeywords();
      for (var i = 1; i <= 10; i++) {
        await svc.pushSearchKeyword('tu-khoa-$i');
      }
      final kws = svc.lastSearchKeywords;
      expect(
        kws,
        hasLength(8),
        reason: 'Cap là 8: push 10 từ phải cắt 2 từ cũ nhất',
      );
      expect(kws.first, 'tu-khoa-10', reason: 'Từ push cuối cùng đứng đầu');
      expect(kws.last, 'tu-khoa-3', reason: 'Từ cũ nhất còn lại là từ thứ 3');
      expect(
        kws,
        isNot(contains('tu-khoa-1')),
        reason: 'Từ cũ nhất (tu-khoa-1) phải bị cắt',
      );
      expect(
        kws,
        isNot(contains('tu-khoa-2')),
        reason: 'Từ cũ thứ nhì (tu-khoa-2) phải bị cắt',
      );
    });

    test('clearSearchKeywords xoá hẳn key trong SharedPreferences', () async {
      expect(
        svc.lastSearchKeywords,
        isNotEmpty,
        reason: 'Tiền điều kiện: đang còn từ khoá từ test trước',
      );
      await svc.clearSearchKeywords();
      expect(
        svc.lastSearchKeywords,
        isEmpty,
        reason: 'Danh sách về rỗng sau khi clear',
      );
      expect(
        svc.prefs.getStringList('last_search_keywords'),
        isNull,
        reason: 'clearSearchKeywords phải remove key "last_search_keywords"',
      );
    });
  });

  group('PrefsService — jobDraft', () {
    test('set map → get lại map bằng nhau (round-trip qua JSON)', () async {
      final draft = <String, dynamic>{
        'jobTitle': 'Senior Flutter Developer',
        'salaryMin': 15000000,
        'skills': ['Flutter', 'Dart'],
        'location': {'city': 'Ha Noi', 'district': 'Cau Giay'},
      };
      await svc.setJobDraft(draft);
      expect(
        svc.jobDraft,
        equals(draft),
        reason: 'Map (kể cả field lồng nhau) phải round-trip nguyên vẹn',
      );
      expect(
        jsonDecode(svc.prefs.getString('job_draft')!),
        equals(draft),
        reason: 'Giá trị thô dưới key "job_draft" là JSON của draft',
      );
    });

    test('set null → remove key', () async {
      expect(svc.jobDraft, isNotNull, reason: 'Tiền điều kiện: draft đang có');
      await svc.setJobDraft(null);
      expect(svc.jobDraft, isNull, reason: 'set null → getter về default');
      expect(
        svc.prefs.getString('job_draft'),
        isNull,
        reason: 'Key "job_draft" phải bị remove (huỷ bản nháp)',
      );
    });

    test('JSON hỏng dưới "job_draft" → getter null, không ném exception',
        () async {
      await svc.prefs.setString('job_draft', '{khong-phai-json');
      expect(
        svc.jobDraft,
        isNull,
        reason: 'Dữ liệu hỏng phải được nuốt lặng (try/catch) → null',
      );
    });
  });

  group('PrefsService — cachedUser', () {
    test('set map → get lại map bằng nhau (round-trip qua JSON)', () async {
      final user = <String, dynamic>{
        'user_id': 'u_1',
        'email': 'nguoidung@jobhub.vn',
        'role': 'JOB_SEEKER',
      };
      await svc.setCachedUser(user);
      expect(
        svc.cachedUser,
        equals(user),
        reason: 'Phiên đăng nhập cache phải round-trip nguyên vẹn',
      );
      expect(
        jsonDecode(svc.prefs.getString('cached_user')!),
        equals(user),
        reason: 'Giá trị thô dưới key "cached_user" là JSON của user',
      );
    });

    test('set null → remove key', () async {
      expect(svc.cachedUser, isNotNull, reason: 'Tiền điều kiện: user đang có');
      await svc.setCachedUser(null);
      expect(svc.cachedUser, isNull, reason: 'set null → getter về default');
      expect(
        svc.prefs.getString('cached_user'),
        isNull,
        reason: 'Key "cached_user" phải bị remove (đăng xuất)',
      );
    });

    test('JSON hỏng dưới "cached_user" → getter null, không ném exception',
        () async {
      await svc.prefs.setString('cached_user', ']]khong-hop-le[[');
      expect(
        svc.cachedUser,
        isNull,
        reason: 'Dữ liệu hỏng phải được nuốt lặng (try/catch) → null',
      );
    });
  });

  group('PrefsService — contract 12 key thô', () {
    test('service chỉ dùng đúng 12 key với tên như thiết kế', () async {
      // Set toàn bộ 12 preference để mọi key đều xuất hiện trong store.
      await svc.setThemeMode('dark');
      await svc.setLocale('en');
      await svc.setRememberEmail('hopdong@jobhub.vn');
      await svc.setRememberMe(false);
      await svc.setLastRole('employer');
      await svc.setNotificationsEnabled(false);
      await svc.setNotificationType('SYSTEM', false);
      await svc.setOnboardingDone(true);
      await svc.setFcmToken('token-contract');
      await svc.clearSearchKeywords();
      await svc.pushSearchKeyword('flutter');
      await svc.setJobDraft(<String, dynamic>{'jobTitle': 'Draft'});
      await svc.setCachedUser(<String, dynamic>{'user_id': 'u_9'});

      expect(
        svc.prefs.getKeys(),
        unorderedEquals(const [
          'theme_mode',
          'locale',
          'remember_email',
          'remember_me',
          'last_role',
          'notifications_enabled',
          'notification_types',
          'onboarding_done',
          'fcm_token',
          'last_search_keywords',
          'job_draft',
          'cached_user',
        ]),
        reason: 'Service phải ghi đúng 12 key theo FLUTTER_REBUILD_PLAN §4,'
            ' không key thừa hay sai tên',
      );
    });
  });
}
