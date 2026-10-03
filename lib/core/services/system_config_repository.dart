import 'package:cloud_firestore/cloud_firestore.dart';

import '../../shared/models/catalog_models.dart';
import '../config/app_config.dart';
import '../utils/failure.dart';
import 'firestore_refs.dart';

/// systemConfigurationService/Repository port — systemConfigurations/{key}.
class SystemConfigRepository {
  SystemConfigRepository(this._refs);
  final FirestoreRefs _refs;

  static final defaults = <SystemConfig>[
    SystemConfig(
      configKey: SystemConfig.keyMaxSkillsPerJob,
      configValue: '${AppConfig.defaultMaxSkillsPerJob}',
      valueType: 'NUMBER',
      description: 'Số kỹ năng tối đa cho một tin tuyển dụng.',
    ),
    SystemConfig(
      configKey: SystemConfig.keyDefaultDeadlineDays,
      configValue: '${AppConfig.defaultDeadlineDays}',
      valueType: 'NUMBER',
      description: 'Số ngày mặc định cho hạn nộp hồ sơ khi nhà tuyển dụng không chọn.',
    ),
    SystemConfig(
      configKey: SystemConfig.keyRequireJobApproval,
      configValue: '${AppConfig.defaultRequireJobApproval}',
      valueType: 'BOOLEAN',
      description: 'Tin tuyển dụng mới cần admin duyệt trước khi hiển thị.',
    ),
    const SystemConfig(
      configKey: SystemConfig.keyGeminiApiKey,
      configValue: '',
      valueType: 'STRING',
      description: 'API key Gemini dùng cho AI phân tích CV / chấm điểm (chỉ admin thấy).',
    ),
  ];

  Stream<List<SystemConfig>> watchAll() =>
      _refs.systemConfigurations().snapshots().map((s) => s.docs.map((d) => d.data()).toList());

  Future<List<SystemConfig>> getAll() async =>
      (await _refs.systemConfigurations().get()).docs.map((d) => d.data()).toList();

  Future<SystemConfig?> get(String key) async =>
      (await _refs.systemConfigurations().doc(key).get()).data();

  Future<num> getNumber(String key, num fallback) async {
    try {
      final c = await get(key);
      final v = c?.asNumber ?? fallback;
      return v <= 0 ? fallback : v; // JobService coerces <= 0 back to fallback
    } catch (_) {
      return fallback;
    }
  }

  Future<bool> getBool(String key, bool fallback) async {
    try {
      final c = await get(key);
      return c == null ? fallback : c.asBool;
    } catch (_) {
      return fallback;
    }
  }

  Future<String?> getString(String key) async {
    try {
      final v = (await get(key))?.configValue;
      return (v == null || v.isEmpty) ? null : v;
    } catch (_) {
      return null;
    }
  }

  /// PATCH /system-configurations/:key (admin). Validates per valueType.
  Future<void> update(String key, String value, {String? updatedBy}) async {
    final existing = await get(key);
    if (existing == null) throw const Failure.notFound('Không tìm thấy cấu hình hệ thống.');
    final v = value.trim();
    switch (existing.valueType) {
      case 'NUMBER':
        final n = num.tryParse(v);
        if (n == null || !n.isFinite || n < 0) {
          throw const Failure.validation('Giá trị cấu hình phải là số không âm.');
        }
        break;
      case 'BOOLEAN':
        if (v.toLowerCase() != 'true' && v.toLowerCase() != 'false') {
          throw const Failure.validation('Giá trị cấu hình phải là true hoặc false.');
        }
        break;
      default:
        if (key != SystemConfig.keyGeminiApiKey && v.isEmpty) {
          throw const Failure.validation('Giá trị cấu hình không được để trống.');
        }
    }
    await _refs.systemConfigurations().doc(key).set(
      SystemConfig(
        configKey: key,
        configValue: existing.valueType == 'BOOLEAN' ? v.toLowerCase() : v,
        valueType: existing.valueType,
        description: existing.description,
        updatedBy: updatedBy,
      ),
    );
  }

  /// Seeds the 3 backend keys (+ GEMINI_API_KEY) if missing.
  Future<void> ensureDefaults() async {
    final batch = _refs.db.batch();
    final existing = (await _refs.systemConfigurations().get()).docs.map((d) => d.id).toSet();
    for (final c in defaults) {
      if (!existing.contains(c.configKey)) {
        batch.set(_refs.systemConfigurations().doc(c.configKey), c);
      }
    }
    await batch.commit();
  }

  static String masked(String key) {
    if (key.isEmpty) return '—';
    final tail = key.length >= 4 ? key.substring(key.length - 4) : key;
    return 'sk-••••$tail';
  }

  FirebaseFirestore get db => _refs.db;
}
