import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/services/ai_session_store.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/prefs_service.dart';
import '../../../core/utils/failure.dart';

/// Local-only preferences (FLUTTER_REBUILD_PLAN §4: settings live in
/// SharedPreferences, never in Firestore) + account/data actions.
class SettingsState {
  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.locale = 'vi',
    this.notificationsEnabled = true,
    this.notificationTypes = const {},
    this.savedSessions = 0,
    this.searchHistoryCount = 0,
    this.changingPassword = false,
    this.clearing = false,
  });

  final ThemeMode themeMode;
  final String locale;
  final bool notificationsEnabled;

  /// Per-type push toggles keyed by wire value (APPLICATION_STATUS, …).
  /// Missing keys mean "enabled" — see [isTypeEnabled].
  final Map<String, bool> notificationTypes;

  /// AI scoring sessions kept locally (AiSessionStore, cap 20).
  final int savedSessions;

  /// Recent search keywords (PrefsService.lastSearchKeywords, cap 8).
  final int searchHistoryCount;

  final bool changingPassword;
  final bool clearing;

  bool isTypeEnabled(String key) => notificationTypes[key] ?? true;

  SettingsState copyWith({
    ThemeMode? themeMode,
    String? locale,
    bool? notificationsEnabled,
    Map<String, bool>? notificationTypes,
    int? savedSessions,
    int? searchHistoryCount,
    bool? changingPassword,
    bool? clearing,
  }) =>
      SettingsState(
        themeMode: themeMode ?? this.themeMode,
        locale: locale ?? this.locale,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        notificationTypes: notificationTypes ?? this.notificationTypes,
        savedSessions: savedSessions ?? this.savedSessions,
        searchHistoryCount: searchHistoryCount ?? this.searchHistoryCount,
        changingPassword: changingPassword ?? this.changingPassword,
        clearing: clearing ?? this.clearing,
      );
}

class SettingsViewModel extends StateNotifier<SettingsState> {
  SettingsViewModel(this._prefs, this._auth, this._sessions) : super(const SettingsState()) {
    _hydrate();
  }

  final PrefsService _prefs;
  final AuthService _auth;
  final AiSessionStore _sessions;

  void _hydrate() {
    state = state.copyWith(
      themeMode: parseThemeMode(_prefs.themeMode),
      locale: _prefs.locale,
      notificationsEnabled: _prefs.notificationsEnabled,
      notificationTypes: _prefs.notificationTypes,
      savedSessions: _sessions.countSessions(),
      searchHistoryCount: _prefs.lastSearchKeywords.length,
    );
  }

  /// Re-reads counters that other screens change (sessions saved, searches).
  void refreshCounters() {
    state = state.copyWith(
      savedSessions: _sessions.countSessions(),
      searchHistoryCount: _prefs.lastSearchKeywords.length,
    );
  }

  // ── Giao diện / Ngôn ngữ ──────────────────────────────────────────────
  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setThemeMode(themeModeToString(mode));
  }

  Future<void> setLocale(String locale) async {
    state = state.copyWith(locale: locale);
    await _prefs.setLocale(locale);
  }

  // ── Thông báo ─────────────────────────────────────────────────────────
  Future<void> setNotifications(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    await _prefs.setNotificationsEnabled(enabled);
  }

  Future<void> setNotificationType(String type, bool enabled) =>
      setNotificationTypes([type], enabled);

  /// Switches every wire value governed by one Settings toggle at once
  /// (e.g. "Duyệt tin" → JOB_APPROVED + JOB_REJECTED) so the delivery side,
  /// which looks a payload up by its own `enumToWire(type)`, honours it.
  Future<void> setNotificationTypes(Iterable<String> wireTypes, bool enabled) async {
    final keys = wireTypes.where((k) => k.isNotEmpty).toSet();
    if (keys.isEmpty) return;
    state = state.copyWith(
      notificationTypes: {...state.notificationTypes, for (final k in keys) k: enabled},
    );
    for (final k in keys) {
      await _prefs.setNotificationType(k, enabled);
    }
  }

  // ── Tài khoản ─────────────────────────────────────────────────────────
  /// UC26: re-authenticate with [currentPassword] then update. Throws
  /// [Failure] ('Mật khẩu hiện tại không đúng.' / weak password / reauth).
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (state.changingPassword) return;
    state = state.copyWith(changingPassword: true);
    try {
      await _auth.changePassword(currentPassword: currentPassword, newPassword: newPassword);
    } catch (e) {
      throw Failure.from(e);
    } finally {
      state = state.copyWith(changingPassword: false);
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Failure.from(e);
    }
  }

  // ── Dữ liệu ───────────────────────────────────────────────────────────
  Future<void> clearAiSessions() async {
    state = state.copyWith(clearing: true);
    try {
      await _sessions.clearSessions();
      state = state.copyWith(savedSessions: 0);
    } finally {
      state = state.copyWith(clearing: false);
    }
  }

  Future<void> clearSearchHistory() async {
    state = state.copyWith(clearing: true);
    try {
      await _prefs.clearSearchKeywords();
      state = state.copyWith(searchHistoryCount: 0);
    } finally {
      state = state.copyWith(clearing: false);
    }
  }

  // ── helpers ───────────────────────────────────────────────────────────
  static ThemeMode parseThemeMode(String? s) => switch (s) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  /// null = follow system (key removed from prefs).
  static String? themeModeToString(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => null,
      };
}

final settingsProvider = StateNotifierProvider<SettingsViewModel, SettingsState>(
  (ref) => SettingsViewModel(
    ref.watch(prefsServiceProvider),
    ref.watch(authServiceProvider),
    ref.watch(aiSessionStoreProvider),
  ),
);
