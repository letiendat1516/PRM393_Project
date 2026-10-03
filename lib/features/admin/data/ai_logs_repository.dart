import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/services/firestore_refs.dart';
import '../../../shared/models/recommendation_models.dart';

/// GET /recommendations/logs?limit=N port — reads aiMatchingLogs newest first.
class AiLogsRepository {
  AiLogsRepository(this._refs);
  final FirestoreRefs _refs;

  Stream<List<AiMatchingLog>> watchRecent({int limit = 100}) => _refs
      .aiMatchingLogs()
      .orderBy('createdAt', descending: true)
      .limit(limit.clamp(1, 200))
      .snapshots()
      .map((s) => s.docs.map((d) => d.data()).toList());
}

final aiLogsRepositoryProvider =
    Provider<AiLogsRepository>((ref) => AiLogsRepository(ref.watch(firestoreRefsProvider)));
