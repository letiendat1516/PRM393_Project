import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences wrapper (teacher requirement). Keys mirror
/// FLUTTER_REBUILD_PLAN §4: darkMode/themeMode, locale, fcmToken,
/// isFirstLaunch, lastSearchKeywords, lastRole, rememberEmail, notification
/// toggles. AI scoring sessions use [AiSessionStore] on the same instance.
class PrefsService {
  PrefsService._(this.prefs);

  final SharedPreferences prefs;

  static PrefsService? _instance;
  static PrefsService get instance {
    final i = _instance;
    if (i == null) {
      throw StateError('PrefsService not initialized. Call PrefsService.init().');
    }
    return i;
  }

  static Future<PrefsService> init() async {
    final p = await SharedPreferences.getInstance();
    return _instance ??= PrefsService._(p);
  }

  static const _kThemeMode = 'theme_mode';
  static const _kLocale = 'locale';
  static const _kRememberEmail = 'remember_email';
  static const _kRememberMe = 'remember_me';
  static const _kLastRole = 'last_role';
  static const _kNotificationsEnabled = 'notifications_enabled';
  static const _kNotificationTypes = 'notification_types';
  static const _kOnboardingDone = 'onboarding_done';
  static const _kFcmToken = 'fcm_token';
  static const _kLastSearchKeywords = 'last_search_keywords';
  static const _kJobDraft = 'job_draft';
  static const _kCachedUser = 'cached_user';

  String? get themeMode => prefs.getString(_kThemeMode);
  Future<void> setThemeMode(String? v) =>
      v == null ? prefs.remove(_kThemeMode) : prefs.setString(_kThemeMode, v);

  String get locale => prefs.getString(_kLocale) ?? 'vi';
  Future<void> setLocale(String v) => prefs.setString(_kLocale, v);

  String? get rememberEmail => prefs.getString(_kRememberEmail);
  Future<void> setRememberEmail(String? v) => (v == null || v.isEmpty)
      ? prefs.remove(_kRememberEmail)
      : prefs.setString(_kRememberEmail, v);

  bool get rememberMe => prefs.getBool(_kRememberMe) ?? true;
  Future<void> setRememberMe(bool v) => prefs.setBool(_kRememberMe, v);

  String? get lastRole => prefs.getString(_kLastRole);
  Future<void> setLastRole(String? v) =>
      v == null ? prefs.remove(_kLastRole) : prefs.setString(_kLastRole, v);

  bool get notificationsEnabled => prefs.getBool(_kNotificationsEnabled) ?? true;
  Future<void> setNotificationsEnabled(bool v) => prefs.setBool(_kNotificationsEnabled, v);

  /// Per-type toggles (APPLICATION_STATUS, NEW_APPLICATION, JOB_APPROVED, SYSTEM…).
  Map<String, bool> get notificationTypes {
    final raw = prefs.getString(_kNotificationTypes);
    if (raw == null) return const {};
    try {
      return (jsonDecode(raw) as Map).map((k, v) => MapEntry(k.toString(), v == true));
    } catch (_) {
      return const {};
    }
  }

  Future<void> setNotificationType(String type, bool enabled) {
    final m = {...notificationTypes, type: enabled};
    return prefs.setString(_kNotificationTypes, jsonEncode(m));
  }

  bool isNotificationTypeEnabled(String type) => notificationTypes[type] ?? true;

  bool get onboardingDone => prefs.getBool(_kOnboardingDone) ?? false;
  bool get isFirstLaunch => !onboardingDone;
  Future<void> setOnboardingDone(bool v) => prefs.setBool(_kOnboardingDone, v);

  String? get fcmToken => prefs.getString(_kFcmToken);
  Future<void> setFcmToken(String? v) =>
      v == null ? prefs.remove(_kFcmToken) : prefs.setString(_kFcmToken, v);

  List<String> get lastSearchKeywords => prefs.getStringList(_kLastSearchKeywords) ?? const [];
  Future<void> pushSearchKeyword(String kw) {
    final k = kw.trim();
    if (k.isEmpty) return Future.value();
    final list = [k, ...lastSearchKeywords.where((e) => e.toLowerCase() != k.toLowerCase())]
        .take(8)
        .toList();
    return prefs.setStringList(_kLastSearchKeywords, list);
  }

  Future<void> clearSearchKeywords() => prefs.remove(_kLastSearchKeywords);

  /// Create-job form draft (FLUTTER_REBUILD_PLAN: "draft lưu local").
  Map<String, dynamic>? get jobDraft {
    final raw = prefs.getString(_kJobDraft);
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as Map).cast<String, dynamic>();
    } catch (_) {
      return null;
    }
  }

  Future<void> setJobDraft(Map<String, dynamic>? draft) =>
      draft == null ? prefs.remove(_kJobDraft) : prefs.setString(_kJobDraft, jsonEncode(draft));

  /// Offline start keeps the cached session (AuthContext retry semantics).
  Map<String, dynamic>? get cachedUser {
    final raw = prefs.getString(_kCachedUser);
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as Map).cast<String, dynamic>();
    } catch (_) {
      return null;
    }
  }

  Future<void> setCachedUser(Map<String, dynamic>? user) =>
      user == null ? prefs.remove(_kCachedUser) : prefs.setString(_kCachedUser, jsonEncode(user));
}
