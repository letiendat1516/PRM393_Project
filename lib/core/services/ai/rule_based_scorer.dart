import 'dart:convert';
import 'dart:math' as math;

import '../../../shared/models/job_model.dart';
import '../../../shared/models/recommendation_models.dart';

/// Exact Dart port of RecommendationController.scoreJobsSql (POST
/// /api/recommendations/score-sql). Deterministic, no network.
///
/// `cv` is the extract-cv payload shape: skills[], soft_skills[],
/// experience_years, education_level, languages[], work_experience[], summary.
class RuleBasedScorer {
  const RuleBasedScorer._();

  static const Map<String, int> _eduRank = {
    'high school': 1,
    'bachelor': 2,
    'master': 3,
    'phd': 4,
    'other': 0,
  };

  static List<String> _lowerList(Object? v) =>
      (v as List?)?.map((e) => e.toString().toLowerCase().trim()).where((s) => s.isNotEmpty).toList() ??
      const [];

  static List<JobScore> scoreJobs(Map<String, dynamic> cv, List<JobModel> jobs) {
    final cvSkills = _lowerList(cv['skills']);
    final cvSoft = _lowerList(cv['soft_skills']);
    final cvExp = ((cv['experience_years'] ?? cv['total_experience_years'] ?? 0) as num).toDouble();
    final cvEdu = (cv['education_level'] ?? '').toString().toLowerCase();
    final cvLangs = _lowerList(cv['languages']);
    final cvExpText = jsonEncode(cv['work_experience'] ?? cv['summary'] ?? '').toLowerCase();

    return [for (final job in jobs) scoreJob(job, cvSkills, cvSoft, cvExp, cvEdu, cvLangs, cvExpText)];
  }

  static JobScore scoreJob(
    JobModel job,
    List<String> cvSkills,
    List<String> cvSoft,
    double cvExp,
    String cvEdu,
    List<String> cvLangs,
    String cvExpText,
  ) {
    final jobSkills = job.requiredSkills
        .map((s) => s.skillName.toLowerCase().trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final minExp = job.minExperienceYears;

    bool matchesSkill(String sk) => cvSkills.any((cs) => cs.contains(sk) || sk.contains(cs));

    // 1) SKILLS (0-30)
    int skillsScore;
    List<String> missing;
    List<String> matched;
    if (jobSkills.isNotEmpty) {
      matched = jobSkills.where(matchesSkill).toList();
      skillsScore = ((matched.length / jobSkills.length) * 30).round();
      missing = jobSkills.where((s) => !matched.contains(s)).toList();
    } else {
      skillsScore = 15;
      matched = const [];
      missing = const [];
    }

    // 2) EXPERIENCE (0-20) — backend keeps the fractional value in the
    // "enough experience" branch (`18 + Math.min(2, cvExpYears - minExp)`,
    // e.g. 18.5) and only rounds the ratio branch.
    num expScore;
    if (cvExp >= minExp) {
      expScore = 18 + math.min(2, cvExp - minExp);
    } else if (minExp > 0) {
      expScore = ((cvExp / minExp) * 15).round();
    } else {
      expScore = 15;
    }
    final num experienceScore = math.min(20, expScore);

    // 3) EDUCATION (0-10)
    var eduScore = 5;
    final cvEduRank = _eduRank[cvEdu] ?? 0;
    if (cvEduRank >= 2) eduScore = 8;
    if (cvEduRank >= 3) eduScore = 10;

    // 4) DOMAIN (0-15): 5 or 12
    var domainScore = 5;
    final industry = (job.categoryName ?? '').toLowerCase();
    if (industry.isNotEmpty &&
        cvExpText.contains(industry.substring(0, industry.length < 8 ? industry.length : 8))) {
      domainScore = 12;
    }

    // 5) SOFT SKILLS (0-10)
    var softScore = 5;
    if (cvSoft.isNotEmpty) softScore = (5 + cvSoft.length).clamp(0, 10);

    // 6) LANGUAGE (0-5)
    var langScore = 3;
    if (cvLangs.isNotEmpty) langScore = (2 + cvLangs.length).clamp(0, 5);

    // 7) CAREER FIT (0-10)
    var fitScore = 7;
    if (cvExp > minExp + 5) fitScore = 5;
    if (minExp > 0 && cvExp < minExp - 2) fitScore = 4;

    // match_score = Math.min(100, sum) — may be fractional on the backend;
    // JobScore.matchScore is an int so only the total is rounded here.
    final num total = math.min(
      100,
      skillsScore + experienceScore + eduScore + domainScore + softScore + langScore + fitScore,
    );

    final strengths = <String>[
      if (skillsScore >= 20) 'Kỹ năng chuyên môn khớp cao',
      if (experienceScore >= 15) 'Kinh nghiệm đáp ứng yêu cầu',
      if (domainScore >= 10) 'Kinh nghiệm cùng ngành',
      if (softScore >= 8) 'Soft skills tốt',
    ];

    final expStr = cvExp == cvExp.roundToDouble() ? cvExp.toInt().toString() : cvExp.toString();
    final minStr = minExp == minExp.roundToDouble() ? minExp.toInt().toString() : minExp.toString();
    final reason = 'SQL: ${matched.length}/${jobSkills.isEmpty ? '?' : jobSkills.length} kỹ năng khớp, '
        '$expStr/$minStr năm KN. '
        '${missing.isNotEmpty ? 'Thiếu: ${missing.take(3).join(', ')}.' : 'Đủ kỹ năng.'}';

    return JobScore(
      jobId: job.jobId,
      matchScore: total.round().clamp(0, 100),
      breakdown: ScoreBreakdown(
        skills: skillsScore,
        experience: experienceScore,
        education: eduScore,
        domain: domainScore,
        softSkills: softScore,
        language: langScore,
        careerFit: fitScore,
      ),
      weights: ScoreBreakdown.defaultWeights,
      recommendationReason: reason,
      missingSkills: missing.take(5).toList(),
      matchedSkills: matched,
      strengths: strengths,
      source: 'sql',
    );
  }
}
