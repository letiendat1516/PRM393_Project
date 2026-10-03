import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers.dart';
import '../../../core/services/ai_session_store.dart';
import '../../../core/services/firestore_refs.dart';
import '../../../core/utils/failure.dart';
import '../../../shared/models/job_model.dart';
import '../../../shared/models/recommendation_models.dart';
import '../../../shared/models/resume_model.dart';

/// Data access for /de-xuat + the AI Matching sheet.
///
/// Sessions live in [AiSessionStore] (SharedPreferences — parity with the web
/// `localStorage['jobhub.aiSessions']`, newest first, capped at 20). When a
/// user is signed in every session is mirrored to `users/{uid}/aiSessions` so
/// the list follows the account across devices; remote sessions missing
/// locally are merged back into the local store by the viewmodel.
class RecommendationsRepository {
  RecommendationsRepository(this._store, this._refs);

  final AiSessionStore _store;
  final FirestoreRefs _refs;

  // ── Local sessions (utils/aiScores.js) ───────────────────────────────
  List<AiSession> loadLocalSessions() => _store.loadSessions();

  AiSession? getLocalSession(String id) => _store.getSession(id);

  /// Live mirror of the signed-in user's sessions (newest first, cap 20).
  /// A doc the converter cannot parse (e.g. `scoredAt` written as a
  /// Timestamp by another client) is skipped instead of killing the stream.
  Stream<List<AiSession>> watchRemoteSessions(String uid) => _refs
      .aiSessions(uid)
      .orderBy('scoredAt', descending: true)
      .limit(AppConfig.aiSessionCap)
      .snapshots()
      .map((s) {
        final out = <AiSession>[];
        for (final d in s.docs) {
          try {
            out.add(d.data());
          } catch (_) {
            // malformed remote session — ignore
          }
        }
        return out;
      });

  /// Persists a scoring session locally and (if [uid] given) to Firestore.
  Future<AiSession> saveSession({
    required String cvName,
    required String method,
    required Map<String, Map<String, JobScore>> scores,
    required List<JobModel> jobs,
    String? uid,
  }) async {
    try {
      final session = await _store.saveSession(
        cvName: cvName,
        method: method,
        scores: scores,
        jobs: jobs,
      );
      if (uid != null) {
        try {
          await _refs.aiSessions(uid).doc(session.id).set(session);
        } catch (_) {
          // The mirror is best-effort; the local copy is the source of truth.
        }
      }
      return session;
    } catch (e) {
      throw Failure.from(e);
    }
  }

  /// Writes sessions that exist remotely but not locally into the local
  /// store (cross-device sync). Returns the merged, newest-first list.
  Future<List<AiSession>> mergeRemoteIntoLocal(List<AiSession> remote) async {
    final local = _store.loadSessions();
    final localIds = local.map((s) => s.id).toSet();
    final missing = remote.where((s) => !localIds.contains(s.id)).toList();
    if (missing.isEmpty) return local;
    final merged = [...local, ...missing]
      ..sort((a, b) => b.scoredAt.compareTo(a.scoredAt));
    final capped = merged.take(AppConfig.aiSessionCap).toList();
    await _store.replaceAll(capped);
    return capped;
  }

  Future<void> deleteSession(String id, {String? uid}) async {
    try {
      await _store.deleteSession(id);
      if (uid != null) await _refs.aiSessions(uid).doc(id).delete();
    } catch (e) {
      throw Failure.from(e);
    }
  }

  /// clearSessions(): removes the local key and every mirrored doc.
  Future<void> clearSessions({String? uid}) async {
    try {
      await _store.clearSessions();
      if (uid != null) {
        final snap = await _refs.aiSessions(uid).get();
        if (snap.docs.isEmpty) return;
        final batch = _refs.db.batch();
        for (final d in snap.docs) {
          batch.delete(d.reference);
        }
        await batch.commit();
      }
    } catch (e) {
      throw Failure.from(e);
    }
  }

  // ── jobRecommendations/{seekerUid_jobId} (table job_recommendation) ──
  /// Upserts one recommendation per scored job for the signed-in seeker so
  /// the application detail page can show "Điểm phù hợp".
  Future<void> upsertRecommendations({
    required String seekerUid,
    required Map<String, Map<String, JobScore>> scores,
    required List<JobModel> jobs,
    String? resumeId,
  }) async {
    if (scores.isEmpty) return;
    try {
      final byId = {for (final j in jobs) j.jobId: j};
      final col = _refs.jobRecommendations();
      var batch = _refs.db.batch();
      var ops = 0;
      for (final entry in scores.entries) {
        final job = byId[entry.key];
        final best = entry.value['ai'] ?? entry.value['sql'];
        if (job == null || best == null) continue;
        final id = JobRecommendation.docIdFor(seekerUid, job.jobId);
        batch.set(
          col.doc(id),
          JobRecommendation(
            recommendationId: id,
            jobSeekerId: seekerUid,
            jobId: job.jobId,
            resumeId: resumeId,
            matchScore: best.matchScore.toDouble(),
            recommendationReason: best.recommendationReason,
            generatedAt: DateTime.now(),
            jobTitle: job.jobTitle,
            companyName: job.employerName,
            score: best,
          ),
          SetOptions(merge: true),
        );
        ops++;
        if (ops == 450) {
          await batch.commit();
          batch = _refs.db.batch();
          ops = 0;
        }
      }
      if (ops > 0) await batch.commit();
    } catch (e) {
      throw Failure.from(e);
    }
  }

  // ── Resumes with an AI analysis (AIScoreModal "CV đã trích xuất") ────
  Stream<List<ResumeModel>> watchAnalyzedResumes(String uid) => _refs
      .resumes()
      .where('jobSeekerId', isEqualTo: uid)
      .snapshots()
      .map((s) {
        final list = s.docs.map((d) => d.data()).where((r) => r.hasAnalysis).toList()
          ..sort((a, b) {
            if (a.isPrimary != b.isPrimary) return a.isPrimary ? -1 : 1;
            final ad = a.uploadDate ?? DateTime(0);
            final bd = b.uploadDate ?? DateTime(0);
            return bd.compareTo(ad);
          });
        return list;
      });
}

final recommendationsRepositoryProvider = Provider<RecommendationsRepository>(
  (ref) => RecommendationsRepository(
    ref.watch(aiSessionStoreProvider),
    ref.watch(firestoreRefsProvider),
  ),
);
