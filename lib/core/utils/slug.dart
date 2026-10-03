import '../../shared/models/job_model.dart';

/// Deterministic Firestore doc id for catalogue rows created by name
/// (categories / skills), so seeker-, employer- and admin-created entries for
/// the same name converge on ONE document — mirrors the SQL UNIQUE(name)
/// constraint + `findOrCreateByName` in the backend services.
///
/// `slugId('skill', 'Kỹ năng mềm')` → `skill_ky-nang-mem`.
String slugId(String prefix, String name) {
  final s = JobModel.stripDiacritics(name.trim().toLowerCase())
      .replaceAll(RegExp(r'[^a-z0-9+#]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return '${prefix}_${s.isEmpty ? name.hashCode.toRadixString(16) : s}';
}
