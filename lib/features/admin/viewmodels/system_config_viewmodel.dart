import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers.dart';
import '../../../core/services/ai/gemini_service.dart';
import '../../../core/services/system_config_repository.dart';
import '../../../core/utils/failure.dart';
import '../../../shared/models/catalog_models.dart';

/// Result of GeminiService.testKey().
class KeyTestResult {
  const KeyTestResult({required this.valid, required this.latencyMs, this.error, this.status});
  final bool valid;
  final int latencyMs;
  final String? error;
  final int? status;
}

enum KeyMessageType { success, error }

class KeyMessage {
  const KeyMessage(this.type, this.text);
  final KeyMessageType type;
  final String text;
}

/// Where the active Gemini key comes from (deepseekKeyStore parity):
/// env (--dart-define) > override (systemConfigurations) > none.
enum KeySource { env, override, none }

class SystemConfigState {
  const SystemConfigState({
    this.saving = false,
    this.seeding = false,
    this.error,
    this.message,
    this.keyTesting = false,
    this.keySaving = false,
    this.keyTestResult,
    this.keyMessage,
  });

  final bool saving;
  final bool seeding;
  final String? error;
  final String? message;
  final bool keyTesting;
  final bool keySaving;
  final KeyTestResult? keyTestResult;
  final KeyMessage? keyMessage;

  SystemConfigState copyWith({
    bool? saving,
    bool? seeding,
    String? error,
    bool clearError = false,
    String? message,
    bool clearMessage = false,
    bool? keyTesting,
    bool? keySaving,
    KeyTestResult? keyTestResult,
    bool clearKeyTestResult = false,
    KeyMessage? keyMessage,
    bool clearKeyMessage = false,
  }) =>
      SystemConfigState(
        saving: saving ?? this.saving,
        seeding: seeding ?? this.seeding,
        error: clearError ? null : (error ?? this.error),
        message: clearMessage ? null : (message ?? this.message),
        keyTesting: keyTesting ?? this.keyTesting,
        keySaving: keySaving ?? this.keySaving,
        keyTestResult: clearKeyTestResult ? null : (keyTestResult ?? this.keyTestResult),
        keyMessage: clearKeyMessage ? null : (keyMessage ?? this.keyMessage),
      );
}

/// Shared by AdminSystemConfigurationPage (form) and the GeminiKeyPanel on
/// AiStatsPage (key test / save / clear). autoDispose → every assignment
/// after an `await` goes through [_set] which checks [mounted].
class SystemConfigNotifier extends StateNotifier<SystemConfigState> {
  SystemConfigNotifier(this._ref) : super(const SystemConfigState());
  final Ref _ref;

  SystemConfigRepository get _repo => _ref.read(systemConfigRepositoryProvider);
  String? get _uid => _ref.read(firebaseAuthProvider).currentUser?.uid;

  /// Frontend DEFAULT_CONFIG fallbacks (10 / 30 / true).
  static const defaultMaxSkills = 10;
  static const defaultDeadlineDays = 30;
  static const defaultRequireApproval = true;

  /// handleSubmit — client-side integer ≥ 1 validation, then 3 parallel PATCHes.
  Future<bool> save({
    required String maxSkillsRaw,
    required String deadlineDaysRaw,
    required bool requireApproval,
  }) async {
    if (!mounted) return false;
    final maxSkills = int.tryParse(maxSkillsRaw.trim());
    if (maxSkills == null || maxSkills < 1) {
      state = state.copyWith(error: 'Số kỹ năng tối đa phải là số nguyên lớn hơn 0.', clearMessage: true);
      return false;
    }
    final deadline = int.tryParse(deadlineDaysRaw.trim());
    if (deadline == null || deadline < 1) {
      state = state.copyWith(error: 'Số ngày hạn tuyển dụng phải là số nguyên lớn hơn 0.', clearMessage: true);
      return false;
    }

    state = state.copyWith(saving: true, clearError: true, clearMessage: true);
    try {
      // PATCH 404s when a key was never seeded — make sure the rows exist.
      await _repo.ensureDefaults();
      await Future.wait([
        _repo.update(SystemConfig.keyMaxSkillsPerJob, '$maxSkills', updatedBy: _uid),
        _repo.update(SystemConfig.keyDefaultDeadlineDays, '$deadline', updatedBy: _uid),
        _repo.update(SystemConfig.keyRequireJobApproval, '$requireApproval', updatedBy: _uid),
      ]);
      _set(state.copyWith(saving: false, message: 'Cập nhật cấu hình hệ thống thành công.'));
      return true;
    } catch (e) {
      _set(state.copyWith(saving: false, error: _message(e, 'Không thể xử lý cấu hình hệ thống.')));
      return false;
    }
  }

  /// 'Khởi tạo cấu hình mặc định' → SystemConfigRepository.ensureDefaults().
  Future<void> seedDefaults() async {
    if (!mounted) return;
    state = state.copyWith(seeding: true, clearError: true, clearMessage: true);
    try {
      await _repo.ensureDefaults();
      _set(state.copyWith(seeding: false, message: 'Đã khởi tạo cấu hình mặc định.'));
    } catch (e) {
      _set(state.copyWith(
          seeding: false, error: _message(e, 'Không thể khởi tạo cấu hình mặc định.')));
    }
  }

  // ── Gemini API key panel (AiStatsPage) ────────────────────────────────

  static KeySource sourceOf(SystemConfig? stored) {
    if (AppConfig.geminiApiKey.isNotEmpty) return KeySource.env;
    if ((stored?.configValue ?? '').isNotEmpty) return KeySource.override;
    return KeySource.none;
  }

  /// POST /deepseek-key/test — tests the typed key when provided, otherwise the
  /// key currently resolved by the app (env or stored override).
  Future<void> testKey(String typed) async {
    if (!mounted) return;
    state = state.copyWith(keyTesting: true, clearKeyTestResult: true, clearKeyMessage: true);
    try {
      final k = typed.trim();
      final service = k.isEmpty
          ? _ref.read(geminiServiceProvider)
          : GeminiService(resolveApiKey: () async => k, logSink: (_) async {});
      final r = await service.testKey();
      _set(state.copyWith(
        keyTesting: false,
        keyTestResult: KeyTestResult(
          valid: r.valid,
          latencyMs: r.latencyMs,
          error: r.error,
          status: r.status,
        ),
      ));
    } catch (e) {
      _set(state.copyWith(
        keyTesting: false,
        keyTestResult: KeyTestResult(valid: false, latencyMs: 0, error: Failure.from(e).message),
      ));
    }
  }

  /// POST /deepseek-key { apiKey } (≥ 8 chars) → systemConfigurations/GEMINI_API_KEY.
  Future<bool> saveKey(String typed) async {
    if (!mounted) return false;
    final k = typed.trim();
    if (k.length < 8) {
      state = state.copyWith(
          keyMessage: const KeyMessage(KeyMessageType.error, 'API key phải có ít nhất 8 ký tự.'));
      return false;
    }
    state = state.copyWith(keySaving: true, clearKeyMessage: true);
    try {
      await _repo.ensureDefaults();
      await _repo.update(SystemConfig.keyGeminiApiKey, k, updatedBy: _uid);
      _set(state.copyWith(
        keySaving: false,
        keyMessage: const KeyMessage(
            KeyMessageType.success, 'Đã lưu key mới — các lời gọi AI tiếp theo sẽ dùng key này.'),
      ));
      return true;
    } catch (e) {
      _set(state.copyWith(
        keySaving: false,
        keyMessage: KeyMessage(KeyMessageType.error, _message(e, 'Lỗi khi lưu key')),
      ));
      return false;
    }
  }

  /// DELETE /deepseek-key → clears the stored override.
  Future<bool> clearKey() async {
    if (!mounted) return false;
    state = state.copyWith(keySaving: true, clearKeyMessage: true);
    try {
      await _repo.ensureDefaults();
      await _repo.update(SystemConfig.keyGeminiApiKey, '', updatedBy: _uid);
      _set(state.copyWith(
        keySaving: false,
        keyMessage: KeyMessage(
          KeyMessageType.success,
          AppConfig.geminiApiKey.isNotEmpty
              ? 'Đã revert về key trong .env.'
              : 'Đã xoá Gemini API key đã lưu.',
        ),
      ));
      return true;
    } catch (e) {
      _set(state.copyWith(
        keySaving: false,
        keyMessage: KeyMessage(KeyMessageType.error, _message(e, 'Lỗi khi xoá override')),
      ));
      return false;
    }
  }

  void dismissError() => _set(state.copyWith(clearError: true));
  void dismissMessage() => _set(state.copyWith(clearMessage: true));

  void _set(SystemConfigState next) {
    if (mounted) state = next;
  }

  static String _message(Object e, String fallback) {
    final f = Failure.from(e);
    return f.code == 'UNKNOWN' ? fallback : f.message;
  }
}

final systemConfigNotifierProvider =
    StateNotifierProvider.autoDispose<SystemConfigNotifier, SystemConfigState>(
        (ref) => SystemConfigNotifier(ref));
