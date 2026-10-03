import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/utils/enums.dart';

/// Per-criterion breakdown shared by the AI (`/score`) and rule-based
/// (`/score-sql`) scorers. Values never exceed the criterion weight.
class ScoreBreakdown {
  const ScoreBreakdown({
    this.skills = 0,
    this.experience = 0,
    this.education = 0,
    this.domain = 0,
    this.softSkills = 0,
    this.language = 0,
    this.careerFit = 0,
  });

  final num skills;
  final num experience;
  final num education;
  final num domain;
  final num softSkills;
  final num language;
  final num careerFit;

  /// Default weights from promptBuilder.js / scoreJobsSql.
  static const ScoreBreakdown defaultWeights = ScoreBreakdown(
    skills: 30,
    experience: 20,
    education: 10,
    domain: 15,
    softSkills: 10,
    language: 5,
    careerFit: 10,
  );

  /// JobListItem.jsx `criteria` labels (7 tiêu chí), in display order.
  static const labels = {
    'skills': 'Kỹ năng chuyên môn',
    'experience': 'Kinh nghiệm',
    'education': 'Học vấn & Chứng chỉ',
    'domain': 'Cùng ngành nghề',
    'soft_skills': 'Kỹ năng mềm & Thái độ',
    'language': 'Ngoại ngữ',
    'career_fit': 'Phù hợp định hướng',
  };

  Map<String, num> toMap() => {
        'skills': skills,
        'experience': experience,
        'education': education,
        'domain': domain,
        'soft_skills': softSkills,
        'language': language,
        'career_fit': careerFit,
      };

  factory ScoreBreakdown.fromMap(Map<String, dynamic>? m) {
    if (m == null) return const ScoreBreakdown();
    num n(String a, [String? b]) => ((m[a] ?? (b == null ? 0 : m[b]) ?? 0) as num);
    return ScoreBreakdown(
      skills: n('skills'),
      experience: n('experience'),
      education: n('education'),
      domain: n('domain'),
      softSkills: n('soft_skills', 'softSkills'),
      language: n('language'),
      careerFit: n('career_fit', 'careerFit'),
    );
  }
}

/// One scored job (AI or SQL). Normalises both backend shapes.
class JobScore {
  const JobScore({
    required this.jobId,
    required this.matchScore,
    this.breakdown = const ScoreBreakdown(),
    this.weights = ScoreBreakdown.defaultWeights,
    this.recommendationReason = '',
    this.missingSkills = const [],
    this.matchedSkills = const [],
    this.strengths = const [],
    this.source = 'sql',
  });

  final String jobId;
  final int matchScore; // 0..100
  final ScoreBreakdown breakdown;
  final ScoreBreakdown weights;
  final String recommendationReason;
  final List<String> missingSkills;
  final List<String> matchedSkills;
  final List<String> strengths;
  final String source; // 'ai' | 'sql'

  /// AIScoreModal ScoreBadge: /10 scale with colour bands.
  double get scoreOutOf10 => matchScore / 10;
  bool get isHighMatch => matchScore >= 70;

  factory JobScore.fromJson(Map<String, dynamic> j) {
    List<String> strs(Object? v) =>
        (v as List?)?.map((e) => e.toString()).toList() ?? const [];
    return JobScore(
      jobId: (j['job_id'] ?? j['jobId'] ?? '').toString(),
      matchScore: ((j['match_score'] ?? j['matchScore'] ?? 0) as num).round().clamp(0, 100),
      breakdown: ScoreBreakdown.fromMap(
          (j['score_breakdown'] ?? j['scoreBreakdown']) as Map<String, dynamic>?),
      weights: j['weights'] is Map
          ? ScoreBreakdown.fromMap((j['weights'] as Map).cast<String, dynamic>())
          : ScoreBreakdown.defaultWeights,
      recommendationReason:
          (j['recommendation_reason'] ?? j['recommendationReason'] ?? '') as String,
      missingSkills: strs(j['missing_skills'] ?? j['missingSkills']),
      matchedSkills: strs(j['matched_skills'] ?? j['matchedSkills']),
      strengths: strs(j['strengths']),
      source: (j['source'] ?? 'ai') as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'job_id': jobId,
        'match_score': matchScore,
        'score_breakdown': breakdown.toMap(),
        'weights': weights.toMap(),
        'recommendation_reason': recommendationReason,
        'missing_skills': missingSkills,
        'matched_skills': matchedSkills,
        'strengths': strengths,
        'source': source,
      };
}

/// jobRecommendations/{jobSeekerId_jobId} — table job_recommendation.
class JobRecommendation {
  const JobRecommendation({
    required this.recommendationId,
    required this.jobSeekerId,
    required this.jobId,
    required this.matchScore,
    this.resumeId,
    this.recommendationReason,
    this.status = RecommendationStatus.new_,
    this.generatedAt,
    this.jobTitle,
    this.companyName,
    this.score,
  });

  final String recommendationId;
  final String jobSeekerId;
  final String jobId;
  final String? resumeId;
  final double matchScore;
  final String? recommendationReason;
  final RecommendationStatus status;
  final DateTime? generatedAt;
  final String? jobTitle;
  final String? companyName;
  final JobScore? score;

  static String docIdFor(String jobSeekerId, String jobId) => '${jobSeekerId}_$jobId';

  factory JobRecommendation.fromJson(Map<String, dynamic> j) => JobRecommendation(
        recommendationId: (j['recommendationId'] ?? j['id'] ?? '') as String,
        jobSeekerId: (j['jobSeekerId'] ?? '') as String,
        jobId: (j['jobId'] ?? '') as String,
        resumeId: j['resumeId'] as String?,
        matchScore: ((j['matchScore'] ?? 0) as num).toDouble(),
        recommendationReason: j['recommendationReason'] as String?,
        status: parseRecommendationStatus(j['status'] as String?),
        generatedAt: (j['generatedAt'] as Timestamp?)?.toDate(),
        jobTitle: j['jobTitle'] as String?,
        companyName: j['companyName'] as String?,
        score: j['score'] is Map
            ? JobScore.fromJson((j['score'] as Map).cast<String, dynamic>())
            : null,
      );

  Map<String, dynamic> toJson() => {
        'recommendationId': recommendationId,
        'jobSeekerId': jobSeekerId,
        'jobId': jobId,
        if (resumeId != null) 'resumeId': resumeId,
        'matchScore': matchScore,
        if (recommendationReason != null)
          'recommendationReason': recommendationReason,
        'status': enumToWire(status),
        'generatedAt': generatedAt != null
            ? Timestamp.fromDate(generatedAt!)
            : FieldValue.serverTimestamp(),
        if (jobTitle != null) 'jobTitle': jobTitle,
        if (companyName != null) 'companyName': companyName,
        if (score != null) 'score': score!.toJson(),
      };
}

/// aiMatchingLogs/{logId} — table ai_matching_log (+ aiLogger.js file shape).
class AiMatchingLog {
  const AiMatchingLog({
    required this.logId,
    required this.task,
    required this.promptText,
    required this.responseText,
    this.jobSeekerId,
    this.modelName,
    this.totalJobsSent,
    this.processingTimeMs = 0,
    this.tokensIn = 0,
    this.tokensOut = 0,
    this.success = true,
    this.error,
    this.metadata = const {},
    this.createdAt,
  });

  final String logId;
  final String? jobSeekerId;
  final String task; // resume_extraction | job_matching
  final String promptText;
  final String responseText;
  final String? modelName;
  final int? totalJobsSent;
  final int processingTimeMs;
  final int tokensIn;
  final int tokensOut;
  final bool success;
  final String? error;
  final Map<String, dynamic> metadata;
  final DateTime? createdAt;

  factory AiMatchingLog.fromJson(Map<String, dynamic> j) => AiMatchingLog(
        logId: (j['logId'] ?? j['id'] ?? '') as String,
        jobSeekerId: j['jobSeekerId'] as String?,
        task: (j['task'] ?? '') as String,
        promptText: (j['promptText'] ?? j['prompt'] ?? '') as String,
        responseText: (j['responseText'] ?? j['response'] ?? '') as String,
        modelName: (j['modelName'] ?? j['model']) as String?,
        totalJobsSent: (j['totalJobsSent'] as num?)?.toInt(),
        processingTimeMs: ((j['processingTimeMs'] ?? 0) as num).toInt(),
        tokensIn: ((j['tokensIn'] ?? 0) as num).toInt(),
        tokensOut: ((j['tokensOut'] ?? 0) as num).toInt(),
        success: (j['success'] ?? true) as bool,
        error: j['error'] as String?,
        metadata: ((j['metadata'] as Map?)?.cast<String, dynamic>()) ?? const {},
        createdAt: (j['createdAt'] as Timestamp?)?.toDate(),
      );

  Map<String, dynamic> toJson() => {
        'logId': logId,
        if (jobSeekerId != null) 'jobSeekerId': jobSeekerId,
        'task': task,
        // aiLogger.js truncates persisted text to 2000 chars
        'promptText': promptText.length > 2000 ? promptText.substring(0, 2000) : promptText,
        'responseText':
            responseText.length > 2000 ? responseText.substring(0, 2000) : responseText,
        if (modelName != null) 'modelName': modelName,
        if (totalJobsSent != null) 'totalJobsSent': totalJobsSent,
        'processingTimeMs': processingTimeMs,
        'tokensIn': tokensIn,
        'tokensOut': tokensOut,
        'success': success,
        if (error != null) 'error': error,
        'metadata': metadata,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };
}

/// utils/aiScores.js session (localStorage 'jobhub.aiSessions', max 20).
class AiSession {
  const AiSession({
    required this.id,
    required this.cvName,
    required this.method,
    required this.scoredAt,
    required this.jobCount,
    required this.scores,
    required this.jobs,
  });

  final String id; // 'session_<millis>'
  final String cvName;
  final String method; // ai | sql | both
  final DateTime scoredAt;
  final int jobCount;
  /// jobId -> {ai?: JobScore, sql?: JobScore}
  final Map<String, Map<String, JobScore>> scores;
  /// jobId -> trimmed job snapshot (JobModel.toJson subset)
  final Map<String, Map<String, dynamic>> jobs;

  int bestScore(String jobId) {
    final s = scores[jobId];
    if (s == null) return 0;
    return (s['ai'] ?? s['sql'])?.matchScore ?? 0;
  }

  double get avgScore {
    if (scores.isEmpty) return 0;
    final total = scores.keys.fold<int>(0, (a, id) => a + bestScore(id));
    return total / scores.length;
  }

  int get highMatchCount => scores.keys.where((id) => bestScore(id) >= 70).length;

  String get methodLabel => switch (method) {
        'sql' => 'SQL',
        'both' => 'AI + SQL',
        'ai' => 'AI',
        _ => method,
      };

  factory AiSession.fromJson(Map<String, dynamic> j) => AiSession(
        id: (j['id'] ?? '') as String,
        cvName: (j['cvName'] ?? 'Không rõ') as String,
        method: (j['method'] ?? 'ai') as String,
        // Local store writes ISO strings; a remote users/{uid}/aiSessions doc
        // written by another client may hold a Timestamp.
        scoredAt: switch (j['scoredAt']) {
          Timestamp t => t.toDate(),
          String s => DateTime.tryParse(s) ?? DateTime.now(),
          _ => DateTime.now(),
        },
        jobCount: ((j['jobCount'] ?? 0) as num).toInt(),
        scores: ((j['scores'] as Map?) ?? {}).map((k, v) => MapEntry(
              k.toString(),
              ((v as Map?) ?? {}).map((m, s) => MapEntry(
                    m.toString(),
                    JobScore.fromJson((s as Map).cast<String, dynamic>()),
                  )),
            )),
        jobs: ((j['jobs'] as Map?) ?? {}).map((k, v) =>
            MapEntry(k.toString(), (v as Map).cast<String, dynamic>())),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'cvName': cvName,
        'method': method,
        'scoredAt': scoredAt.toIso8601String(),
        'jobCount': jobCount,
        'scores': scores.map((k, v) => MapEntry(k, v.map((m, s) => MapEntry(m, s.toJson())))),
        'jobs': jobs,
      };
}
