import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../shared/models/job_model.dart';
import '../../shared/models/recommendation_models.dart';
import '../config/app_config.dart';
import '../utils/enums.dart';

/// Port of frontend/src/utils/aiScores.js: scoring sessions live in local
/// storage (SharedPreferences here), newest first, capped at 20, with
/// migration from the legacy 'jobhub.aiScores' key.
class AiSessionStore {
  AiSessionStore(this._prefs);
  final SharedPreferences _prefs;

  static const key = 'jobhub.aiSessions';
  static const legacyKey = 'jobhub.aiScores';

  List<AiSession> loadSessions() {
    _migrateLegacy();
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map>()
          .map((m) => AiSession.fromJson(m.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  AiSession? getSession(String id) {
    for (final s in loadSessions()) {
      if (s.id == id) return s;
    }
    return null;
  }

  int countSessions() => loadSessions().length;

  /// Builds + persists a session. `scores` maps jobId → {ai?, sql?}.
  Future<AiSession> saveSession({
    required String cvName,
    required String method,
    required Map<String, Map<String, JobScore>> scores,
    required List<JobModel> jobs,
  }) async {
    final now = DateTime.now();
    // UUID (not millis) so two saves within the same tick don't collide and
    // `deleteSession` can't accidentally wipe both.
    final session = AiSession(
      id: 'session_${const Uuid().v4()}',
      cvName: cvName.trim().isEmpty ? 'Không rõ' : cvName.trim(),
      method: method,
      scoredAt: now,
      jobCount: scores.length,
      scores: scores,
      jobs: {for (final j in jobs) if (scores.containsKey(j.jobId)) j.jobId: snapshot(j)},
    );
    final all = [session, ...loadSessions()].take(AppConfig.aiSessionCap).toList();
    await _write(all);
    return session;
  }

  Future<void> deleteSession(String id) async {
    await _write(loadSessions().where((s) => s.id != id).toList());
  }

  Future<void> clearSessions() async {
    await _prefs.remove(key);
  }

  /// Bulk replace (used when merging remote users/{uid}/aiSessions).
  Future<void> replaceAll(List<AiSession> sessions) =>
      _write(sessions.take(AppConfig.aiSessionCap).toList());

  /// Trimmed job snapshot kept inside the session (aiScores.js trimJob).
  static Map<String, dynamic> snapshot(JobModel j) => {
        'id': j.jobId,
        'jobId': j.jobId,
        'title': j.jobTitle,
        'jobTitle': j.jobTitle,
        'employerId': j.employerId,
        'employerName': j.employerName,
        'employerLogoUrl': j.employerLogoUrl,
        'salaryMin': j.salaryMin,
        'salaryMax': j.salaryMax,
        'isSalaryNegotiable': j.isSalaryNegotiable,
        'city': j.city,
        'location': j.location,
        // Same UPPER_SNAKE wire format as JobModel.toJson (FULL_TIME, not FULLTIME).
        'experienceLevel': enumToWire(j.experienceLevel),
        'workMode': enumToWire(j.workMode),
        'jobType': enumToWire(j.jobType),
        'requiredSkills': j.requiredSkills.map((s) => s.toJson()).toList(),
        'categoryName': j.categoryName,
        'status': 'OPEN',
        'isApproved': true,
        'createdAt': j.createdAt?.toIso8601String(),
      };

  static JobModel jobFromSnapshot(Map<String, dynamic> m) => JobModel.fromJson({
        ...m,
        'experienceLevel': m['experienceLevel'],
        'workMode': m['workMode'],
        'jobType': m['jobType'],
      });

  Future<void> _write(List<AiSession> sessions) async {
    await _prefs.setString(key, jsonEncode(sessions.map((s) => s.toJson()).toList()));
  }

  void _migrateLegacy() {
    final legacy = _prefs.getString(legacyKey);
    if (legacy == null) return;
    if (_prefs.getString(key) == null) {
      try {
        final scores = (jsonDecode(legacy) as Map).cast<String, dynamic>();
        final session = AiSession(
          id: 'session_legacy',
          cvName: 'Không rõ',
          method: 'ai',
          scoredAt: DateTime.now(),
          jobCount: scores.length,
          scores: scores.map((k, v) => MapEntry(
                k,
                {'ai': JobScore.fromJson({...(v as Map).cast<String, dynamic>(), 'job_id': k})},
              )),
          jobs: const {},
        );
        _prefs.setString(key, jsonEncode([session.toJson()]));
      } catch (_) {}
    }
    _prefs.remove(legacyKey);
  }
}
