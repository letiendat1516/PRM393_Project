// Unit tests cho RuleBasedScorer.scoreJobs — Dart port của
// backend/src/controllers/RecommendationController.js#scoreJobsSql
// (POST /api/recommendations/score-sql).
//
// Trọng số backend (tổng 100):
//   skills 30 | experience 20 | education 10 | domain 15
//   | soft_skills 10 | language 5 | career_fit 10
//
// Fixture CV dùng đúng shape extract-cv mà lib đọc:
//   skills[], soft_skills[], experience_years (hoặc total_experience_years),
//   education_level, languages[], work_experience[] / summary.
import 'package:flutter_test/flutter_test.dart';

import 'package:jobhub_prm393/core/services/ai/rule_based_scorer.dart';
import 'package:jobhub_prm393/core/utils/enums.dart';
import 'package:jobhub_prm393/shared/models/job_model.dart';
import 'package:jobhub_prm393/shared/models/recommendation_models.dart';

void main() {
  // ────────────────────────────────────────────── fixtures (kiểu lib thật)
  JobModel makeJob(
    String id, {
    List<String> skills = const [],
    ExperienceLevel level = ExperienceLevel.mid,
    String? category,
  }) =>
      JobModel(
        jobId: id,
        employerId: 'emp-$id',
        employerName: 'JobHub Test Corp',
        jobTitle: 'Dev $id',
        categoryName: category,
        experienceLevel: level,
        requiredSkills: [for (final s in skills) JobSkillRef(skillName: s)],
        createdAt: DateTime.utc(2026, 1, 1),
      );

  /// CV "hoàn hảo" cho perfectJob: 3/3 kỹ năng, 3 năm (mid cần 3),
  /// master, 2 soft skills, 1 ngôn ngữ, work_experience chứa "software".
  const Map<String, dynamic> perfectCv = {
    'skills': ['flutter', 'dart', 'firebase'],
    'soft_skills': ['communication', 'teamwork'],
    'experience_years': 3,
    'education_level': 'master',
    'languages': ['english'],
    'work_experience': ['3 years as flutter developer in software industry'],
  };

  /// mid → minExperienceYears = 3, 3 kỹ năng, category "software".
  final JobModel perfectJob = makeJob(
    'j-perfect',
    skills: const ['flutter', 'dart', 'firebase'],
    level: ExperienceLevel.mid,
    category: 'software',
  );

  /// Không khớp gì với perfectCv: kỹ năng rời ngành, category khác.
  final JobModel zeroJob = makeJob(
    'j-zero',
    skills: const ['rust', 'go', 'kotlin'],
    level: ExperienceLevel.mid,
    category: 'hardware',
  );

  /// Job trung lập: không yêu cầu kỹ năng, intern (minExp = 0), không category.
  final JobModel neutralJob =
      makeJob('j-neutral', level: ExperienceLevel.intern);

  final JobModel noSkillJob =
      makeJob('j-noskill', level: ExperienceLevel.mid, category: 'software');

  final JobModel sevenSkillJob = makeJob(
    'j-seven',
    skills: const ['s1', 's2', 's3', 's4', 's5', 's6', 's7'],
    level: ExperienceLevel.mid,
  );

  final JobModel seniorJob =
      makeJob('j-senior', level: ExperienceLevel.senior); // minExp = 5

  JobScore scoreOne(Map<String, dynamic> cv, JobModel j) =>
      RuleBasedScorer.scoreJobs(cv, [j]).single;

  num breakdownSum(ScoreBreakdown b) =>
      b.skills +
      b.experience +
      b.education +
      b.domain +
      b.softSkills +
      b.language +
      b.careerFit;

  group('RuleBasedScorer.scoreJobs — đối chiếu RecommendationController.scoreJobsSql', () {
    group('trọng số 7 tiêu chí backend (30/20/10/15/10/5/10)', () {
      test('ScoreBreakdown.defaultWeights khớp trọng số backend, tổng 100', () {
        final w = ScoreBreakdown.defaultWeights;
        expect(w.skills, 30, reason: 'backend: Math.round(matched/total * 30)');
        expect(w.experience, 20,
            reason: 'backend: min(20, 18 + min(2, cvExp - minExp))');
        expect(w.education, 10, reason: 'backend: master+ (rank 3) → 10');
        expect(w.domain, 15,
            reason: 'backend: match ngành → 12, mặc định 5 (max weight 15)');
        expect(w.softSkills, 10, reason: 'backend: min(10, 5 + n)');
        expect(w.language, 5, reason: 'backend: min(5, 2 + n)');
        expect(w.careerFit, 10, reason: 'backend: 7 mặc định, phạt 5/4');
        expect(w.toMap().values.fold<num>(0, (a, b) => a + b), 100,
            reason: 'tổng 7 trọng số = 100 điểm');
      });

      test('JobScore.weights trả về đúng defaultWeights', () {
        final s = scoreOne(perfectCv, perfectJob);
        expect(
          s.weights.toMap(),
          {
            'skills': 30,
            'experience': 20,
            'education': 10,
            'domain': 15,
            'soft_skills': 10,
            'language': 5,
            'career_fit': 10,
          },
          reason: 'score-sql luôn trả kèm weights chuẩn của 7 tiêu chí',
        );
      });

      test('chốt điểm fixture khớp hoàn hảo: 30+18+10+12+7+3+7 = 87', () {
        final s = scoreOne(perfectCv, perfectJob);
        expect(s.jobId, 'j-perfect', reason: 'giữ nguyên jobId của job đầu vào');
        expect(s.matchScore, 87,
            reason: 'tổng 7 tiêu chí theo đúng công thức backend scoreJobsSql');
        expect(s.breakdown.skills, 30,
            reason: '3/3 kỹ năng khớp → round(3/3 * 30) = 30 (điểm tối đa)');
        expect(s.breakdown.experience, 18,
            reason: 'cvExp 3 >= minExp 3 → 18 + min(2, 0) = 18');
        expect(s.breakdown.education, 10,
            reason: "education_level 'master' (rank 3 ≥ 3) → 10");
        expect(s.breakdown.domain, 12,
            reason:
                "category 'software' (8 ký tự) xuất hiện trong work_experience → 12");
        expect(s.breakdown.softSkills, 7,
            reason: '2 soft skills → min(10, 5 + 2) = 7');
        expect(s.breakdown.language, 3,
            reason: '1 ngôn ngữ → min(5, 2 + 1) = 3');
        expect(s.breakdown.careerFit, 7,
            reason: 'không overqualified (3 ≤ 3+5), không gap (3 ≥ 3-2) → 7');
      });

      test('mọi field breakdown không vượt trọng số tương ứng', () {
        final jobs = [perfectJob, zeroJob, neutralJob, sevenSkillJob, seniorJob];
        final cvs = [
          perfectCv,
          const <String, dynamic>{}, // CV rỗng
          {...perfectCv, 'experience_years': 9},
          {...perfectCv, 'experience_years': 3.5},
          {...perfectCv, 'soft_skills': List<String>.generate(20, (i) => 's$i')},
        ];
        final max = ScoreBreakdown.defaultWeights.toMap();
        for (final cv in cvs) {
          for (final j in jobs) {
            final actual = scoreOne(cv, j).breakdown.toMap();
            for (final k in max.keys) {
              expect(actual[k], lessThanOrEqualTo(max[k]!),
                  reason:
                      '$k của job ${j.jobId} không được vượt trọng số ${max[k]}');
            }
          }
        }
      });
    });

    group('skills (0-30)', () {
      test('CV khớp đủ requiredSkills → điểm skill tối đa 30, missing rỗng', () {
        final s = scoreOne(perfectCv, perfectJob);
        expect(s.breakdown.skills, 30,
            reason: 'matched 3/3 → round((3/3) * 30) = 30');
        expect(s.missingSkills, isEmpty,
            reason: 'khớp đủ thì không còn kỹ năng thiếu');
        expect(s.matchedSkills, unorderedEquals(['flutter', 'dart', 'firebase']),
            reason: 'matched_skills liệt kê đúng tên (đã lowercase) các kỹ năng khớp');
      });

      test('khớp thiếu 1/3 → 10 điểm, missing đúng tên các kỹ năng còn lại', () {
        final cv = {...perfectCv, 'skills': ['flutter']};
        final s = scoreOne(cv, perfectJob);
        expect(s.breakdown.skills, 10,
            reason: 'round((1/3) * 30) = 10');
        expect(s.missingSkills, unorderedEquals(['dart', 'firebase']),
            reason: 'missing_skills phải đúng tên 2 kỹ năng chưa khớp');
        expect(s.matchedSkills, ['flutter'], reason: 'chỉ flutter khớp');
        expect(s.matchScore, 67,
            reason: '10+18+10+12+7+3+7 = 67 (chỉ thay đổi điểm skills)');
      });

      test('khớp 0 kỹ năng → 0 điểm skill, missing đầy đủ', () {
        final cv = {...perfectCv, 'skills': ['photoshop']};
        final s = scoreOne(cv, perfectJob);
        expect(s.breakdown.skills, 0,
            reason: 'matched 0/3 → round(0 * 30) = 0');
        expect(
            s.missingSkills, unorderedEquals(['flutter', 'dart', 'firebase']),
            reason: 'missing đủ 3 tên kỹ năng yêu cầu');
        expect(s.matchScore, 57, reason: '0+18+10+12+7+3+7 = 57');
      });

      test('job không có requiredSkills → 15 điểm trung tính (backend default)', () {
        final s = scoreOne(perfectCv, noSkillJob);
        expect(s.breakdown.skills, 15,
            reason: 'backend: không yêu cầu kỹ năng → skillsScore = 15');
        expect(s.matchedSkills, isEmpty, reason: 'không có gì để khớp');
        expect(s.missingSkills, isEmpty, reason: 'không có gì để thiếu');
        expect(s.matchScore, 72, reason: '15+18+10+12+7+3+7 = 72');
      });

      test('matching kiểu contains 2 chiều như backend (cs.includes(sk) || sk.includes(cs))', () {
        final j = makeJob('j-sub',
            skills: const ['python', 'node.js'], level: ExperienceLevel.intern);
        // 'pythonista' chứa 'python'; 'node' là con của 'node.js'.
        final s = scoreOne({'skills': ['pythonista', 'node']}, j);
        expect(s.breakdown.skills, 30,
            reason: '2/2 khớp qua quan hệ contains substring → 30 điểm tối đa');
        expect(s.matchedSkills, unorderedEquals(['python', 'node.js']),
            reason: 'cả hai kỹ năng job đều tính là khớp');
        expect(s.missingSkills, isEmpty, reason: 'không còn kỹ năng thiếu');
      });

      test('tên kỹ năng được normalize lowercase + trim trước khi so khớp', () {
        final j = makeJob('j-case',
            skills: const ['Flutter', '  DART  '],
            level: ExperienceLevel.intern);
        final s = scoreOne({'skills': ['flutter', 'dart']}, j);
        expect(s.breakdown.skills, 30,
            reason: "job 'Flutter'/'  DART  ' hạ chữ + trim ra khớp CV thường");
        expect(s.matchedSkills, unorderedEquals(['flutter', 'dart']),
            reason: 'matched_skills trả về dạng đã normalize');
      });

      test('missing_skills giới hạn 5 phần tử, reason liệt kê 3 phần tử đầu', () {
        final s = scoreOne({...perfectCv, 'skills': ['zebra']}, sevenSkillJob);
        expect(s.breakdown.skills, 0, reason: '0/7 khớp → 0 điểm');
        expect(s.missingSkills, ['s1', 's2', 's3', 's4', 's5'],
            reason: 'backend: missing.slice(0, 5)');
        expect(s.recommendationReason, contains('Thiếu: s1, s2, s3.'),
            reason: 'backend: reason chỉ liệt kê missing.slice(0, 3)');
        expect(s.recommendationReason, contains('0/7 kỹ năng khớp'),
            reason: 'reason ghi rõ tỉ lệ 0/7');
      });
    });

    group('experience (0-20)', () {
      test('CV thiếu kinh nghiệm → điểm tỉ lệ: 1/3 yêu cầu → 5', () {
        final cv = {...perfectCv, 'experience_years': 1};
        final s = scoreOne(cv, perfectJob);
        expect(s.breakdown.experience, 5,
            reason: 'backend: Math.round((1/3) * 15) = 5');
      });

      test('CV 0 năm vs yêu cầu 3 năm → 0 điểm experience', () {
        final cv = {...perfectCv, 'experience_years': 0};
        final s = scoreOne(cv, perfectJob);
        expect(s.breakdown.experience, 0,
            reason: 'Math.round((0/3) * 15) = 0');
      });

      test('CV vượt yêu cầu 3 năm → bonus đầy đủ, cap 20', () {
        final cv = {...perfectCv, 'experience_years': 6};
        final s = scoreOne(cv, perfectJob);
        expect(s.breakdown.experience, 20,
            reason: '18 + min(2, 6-3) = 20 → không vượt quá 20');
        expect(s.breakdown.careerFit, 7,
            reason: '6 ≤ minExp+5 = 8 nên chưa bị phạt overqualified');
      });

      test('CV vượt yêu cầu 0.5 năm → 18.5 (backend giữ giá trị lẻ)', () {
        final cv = {...perfectCv, 'experience_years': 3.5};
        final s = scoreOne(cv, perfectJob);
        expect(s.breakdown.experience, 18.5,
            reason: 'backend giữ nguyên 18 + min(2, 0.5) = 18.5 (không round)');
      });

      test('fallback total_experience_years khi thiếu experience_years', () {
        final cv = {
          ...perfectCv,
          'experience_years': null,
          'total_experience_years': 4,
        };
        final s = scoreOne(cv, perfectJob);
        expect(s.breakdown.experience, 19,
            reason: 'cvExp = 4 (fallback) → 18 + min(2, 4-3) = 19');
      });

      test('job intern (minExp = 0), CV 0 năm → nhánh đủ: 18', () {
        final s = scoreOne({...perfectCv, 'experience_years': 0}, neutralJob);
        expect(s.breakdown.experience, 18,
            reason: '0 >= 0 → 18 + min(2, 0) = 18 (không rơi nhánh 15)');
      });
    });

    group('education mapping theo EDU_RANK backend', () {
      // Backend: EDU_RANK = {high school:1, bachelor:2, master:3, phd:4, other:0}
      ScoreBreakdown edu(String level) => scoreOne(
        {'skills': <String>[], 'experience_years': 0, 'education_level': level},
        neutralJob,
      ).breakdown;

      test("master / phd (rank ≥ 3) → 10", () {
        expect(edu('master').education, 10, reason: "EDU_RANK['master'] = 3 → 10");
        expect(edu('phd').education, 10, reason: "EDU_RANK['phd'] = 4 → 10");
      });

      test("bachelor (rank 2) → 8", () {
        expect(edu('bachelor').education, 8,
            reason: "EDU_RANK['bachelor'] = 2 → đủ 8 điểm, chưa tối đa");
      });

      test("high school (rank 1) → trừ xuống 5", () {
        expect(edu('high school').education, 5,
            reason: 'rank 1 < 2 → giữ mức mặc định 5');
      });

      test("other / giá trị lạ / rỗng → 5", () {
        expect(edu('other').education, 5, reason: "EDU_RANK['other'] = 0 → 5");
        expect(edu('đại học').education, 5,
            reason: 'backend EDU_RANK chỉ nhận nhãn tiếng Anh; lạ → rank 0 → 5');
        expect(edu('').education, 5, reason: 'rỗng → rank 0 → 5');
      });

      test('nhãn học vấn được lowercase trước khi tra bảng', () {
        expect(edu('Bachelor').education, 8,
            reason: "'Bachelor'.toLowerCase() → 'bachelor' → 8");
        expect(edu('PHD').education, 10, reason: "'PHD'.toLowerCase() → 'phd' → 10");
      });
    });

    group('domain (0-15): category so với work_experience/summary', () {
      test('category xuất hiện trong work_experience → 12', () {
        final j = makeJob('j-acc',
            level: ExperienceLevel.intern, category: 'accounting');
        final s = scoreOne(
          {'work_experience': ['3 years at an accounting firm']},
          j,
        );
        expect(s.breakdown.domain, 12,
            reason:
                "prefix 8 ký tự 'accounti' của category nằm trong text KN → 12");
      });

      test('fallback summary khi không có work_experience', () {
        final j = makeJob('j-acc2',
            level: ExperienceLevel.intern, category: 'accounting');
        final s = scoreOne({'summary': 'worked in accounting department'}, j);
        expect(s.breakdown.domain, 12,
            reason: 'backend: JSON.stringify(cv.work_experience || cv.summary)');
      });

      test('job không có category → 5 (mặc định)', () {
        final s = scoreOne(perfectCv, neutralJob);
        expect(s.breakdown.domain, 5,
            reason: 'industry rỗng → luôn mặc định 5');
      });

      test('category không xuất hiện trong CV → 5', () {
        final j = makeJob('j-mkt',
            level: ExperienceLevel.intern, category: 'marketing');
        final s = scoreOne({'work_experience': ['chef for 3 years']}, j);
        expect(s.breakdown.domain, 5,
            reason: "prefix 'marketin' không có trong text KN → 5");
      });
    });

    group('soft skills (0-10) và language (0-5)', () {
      test('soft: [] → 5; n → min(10, 5+n), clamp tại 10', () {
        final cases = <int, int>{0: 5, 1: 6, 3: 8, 5: 10, 20: 10};
        cases.forEach((n, expected) {
          final cv = {
            'skills': <String>[],
            'experience_years': 0,
            'soft_skills': List<String>.generate(n, (i) => 'soft$i'),
          };
          final got = scoreOne(cv, neutralJob).breakdown.softSkills;
          expect(got, expected,
              reason: '$n soft skill → min(10, 5+$n) = $expected (backend)');
        });
      });

      test('language: [] → 3; n → min(5, 2+n), clamp tại 5', () {
        final cases = <int, int>{0: 3, 1: 3, 2: 4, 3: 5, 7: 5};
        cases.forEach((n, expected) {
          final cv = {
            'skills': <String>[],
            'experience_years': 0,
            'languages': List<String>.generate(n, (i) => 'lang$i'),
          };
          final got = scoreOne(cv, neutralJob).breakdown.language;
          expect(got, expected,
              reason: '$n ngôn ngữ → min(5, 2+$n) = $expected (backend)');
        });
      });
    });

    group('career fit (0-10): phạt overqualified và gap', () {
      test('overqualified: cvExp 9 > minExp 3 + 5 → 5', () {
        final cv = {...perfectCv, 'experience_years': 9};
        final s = scoreOne(cv, perfectJob);
        expect(s.breakdown.careerFit, 5,
            reason: 'backend: cvExpYears > minExp + 5 → fitScore = 5');
        expect(s.breakdown.experience, 20,
            reason: '18 + min(2, 6) = 20 vẫn đầy đủ');
      });

      test('gap lớn: cvExp 1 < minExp 5 - 2 → 4', () {
        final cv = {...perfectCv, 'experience_years': 1};
        final s = scoreOne(cv, seniorJob);
        expect(s.breakdown.careerFit, 4,
            reason: 'minExp 5 > 0 và 1 < 3 → fitScore = 4');
        expect(s.breakdown.experience, 3, reason: 'round((1/5) * 15) = 3');
      });

      test('trong vùng hợp lý → 7 (mặc định)', () {
        expect(scoreOne(perfectCv, perfectJob).breakdown.careerFit, 7,
            reason: '3 ≤ 3+5 và 3 ≥ 3-2 → không phạt');
        expect(
          scoreOne({...perfectCv, 'experience_years': 0}, neutralJob)
              .breakdown
              .careerFit,
          7,
          reason: 'minExp = 0 không rơi nhánh phạt gap',
        );
      });
    });

    group('so sánh tương đối và thứ tự', () {
      test('cùng 1 lần gọi: job khớp hoàn hảo (87) > job không khớp (50)', () {
        final results = RuleBasedScorer.scoreJobs(perfectCv, [zeroJob, perfectJob]);
        final byId = {for (final r in results) r.jobId: r};
        expect(byId['j-perfect']!.matchScore, 87, reason: 'khớp 3/3 + cùng ngành');
        expect(byId['j-zero']!.matchScore, 50,
            reason: '0+18+10+5+7+3+7 = 50 (0 kỹ năng, khác ngành)');
        expect(byId['j-perfect']!.matchScore,
            greaterThan(byId['j-zero']!.matchScore),
            reason: 'job khớp hoàn hảo bắt buộc điểm cao hơn job không khớp');
      });

      test('scoreJobs không sắp xếp — giữ nguyên thứ tự jobs đầu vào', () {
        final results = RuleBasedScorer.scoreJobs(perfectCv, [zeroJob, perfectJob]);
        expect(results.map((e) => e.jobId).toList(), ['j-zero', 'j-perfect'],
            reason: 'output map theo thứ tự input, việc sort thuộc về caller');
        expect(results, hasLength(2),
            reason: 'số kết quả bằng số job đầu vào');
      });

      test('sau khi sort giảm dần theo điểm, job khớp nhất đứng đầu', () {
        final results =
            RuleBasedScorer.scoreJobs(perfectCv, [zeroJob, sevenSkillJob, perfectJob]);
        final sorted =
            results.toList()..sort((a, b) => b.matchScore.compareTo(a.matchScore));
        expect(sorted.first.jobId, 'j-perfect',
            reason: 'job khớp hoàn hảo phải dẫn đầu sau sort giảm dần');
        for (var i = 0; i < sorted.length - 1; i++) {
          expect(sorted[i].matchScore,
              greaterThanOrEqualTo(sorted[i + 1].matchScore),
              reason: 'danh sách sau sort phải giảm dần (vị trí $i)');
        }
      });
    });

    group('bất biến tổng điểm và cấu trúc breakdown', () {
      test('matchScore luôn trong [0, 100] với mọi tổ hợp fixture', () {
        final jobs = [perfectJob, zeroJob, neutralJob, noSkillJob, sevenSkillJob, seniorJob];
        final cvs = [
          perfectCv,
          const <String, dynamic>{},
          {...perfectCv, 'experience_years': 9},
          {...perfectCv, 'experience_years': 3.5},
          {...perfectCv, 'skills': <String>[]},
          {...perfectCv, 'education_level': 'phd', 'languages': ['en', 'vi', 'fr']},
        ];
        for (final cv in cvs) {
          for (final j in jobs) {
            final score = scoreOne(cv, j).matchScore;
            expect(score, inInclusiveRange(0, 100),
                reason: 'điểm ${j.jobId} phải nằm trong [0, 100]');
          }
        }
      });

      test('7 field breakdown cộng lại đúng matchScore (các case điểm nguyên)', () {
        final fixtures = <MapEntry<Map<String, dynamic>, JobModel>>[
          MapEntry(perfectCv, perfectJob), // 87
          MapEntry({...perfectCv, 'skills': ['photoshop']}, perfectJob), // 57
          MapEntry({...perfectCv, 'skills': ['flutter']}, perfectJob), // 67
          MapEntry(perfectCv, noSkillJob), // 72
          MapEntry(perfectCv, zeroJob), // 50
          MapEntry(const <String, dynamic>{}, perfectJob), // 22
        ];
        const expected = [87, 57, 67, 72, 50, 22];
        for (var i = 0; i < fixtures.length; i++) {
          final s = scoreOne(fixtures[i].key, fixtures[i].value);
          expect(breakdownSum(s.breakdown), expected[i],
              reason: '${fixtures[i].value.jobId}: tổng các field = ${expected[i]}');
          expect(s.matchScore, expected[i],
              reason: '${fixtures[i].value.jobId}: matchScore = ${expected[i]}');
        }
      });

      test('case tổng lẻ (experience 18.5): backend trả 87.5, Dart round tổng thành int', () {
        final cv = {...perfectCv, 'experience_years': 3.5};
        final s = scoreOne(cv, perfectJob);
        expect(breakdownSum(s.breakdown), 87.5,
            reason: '30+18.5+10+12+7+3+7 = 87.5, đúng tổng lẻ của backend');
        expect(s.matchScore, 88,
            reason: 'JobScore.matchScore là int nên Dart round 87.5 → 88 '
                '(khác biệt đã ghi chú trong rule_based_scorer.dart; backend '
                'trả thẳng 87.5 — chấp nhận được vì model Flutter cố định int)');
        expect((breakdownSum(s.breakdown) - s.matchScore).abs(), lessThan(1),
            reason: 'sai số do làm tròn tổng không vượt 0.5');
      });

      test('ScoreBreakdown.toMap có đúng 7 nhóm tiêu chí theo key backend', () {
        final s = scoreOne(perfectCv, perfectJob);
        expect(
          s.breakdown.toMap().keys,
          unorderedEquals([
            'skills',
            'experience',
            'education',
            'domain',
            'soft_skills',
            'language',
            'career_fit',
          ]),
          reason: 'đủ 7 key snake_case đúng như score_breakdown backend',
        );
        expect(ScoreBreakdown.labels.length, 7,
            reason: 'ScoreBreakdown.labels hiển thị đủ 7 tiêu chí');
      });
    });

    group('strengths và recommendation_reason', () {
      test('strengths bật đủ 3 nhãn (skills 30, exp 18, domain 12); soft 7 chưa đạt', () {
        final s = scoreOne(perfectCv, perfectJob);
        expect(s.strengths, contains('Kỹ năng chuyên môn khớp cao'),
            reason: 'skillsScore 30 ≥ 20');
        expect(s.strengths, contains('Kinh nghiệm đáp ứng yêu cầu'),
            reason: 'expScore 18 ≥ 15');
        expect(s.strengths, contains('Kinh nghiệm cùng ngành'),
            reason: 'domainScore 12 ≥ 10');
        expect(s.strengths, isNot(contains('Soft skills tốt')),
            reason: 'softScore 7 < ngưỡng 8');
      });

      test('soft 3 kỹ năng (8 điểm) thêm nhãn "Soft skills tốt"', () {
        final cv = {...perfectCv, 'soft_skills': ['a', 'b', 'c']};
        expect(scoreOne(cv, perfectJob).strengths, contains('Soft skills tốt'),
            reason: 'min(10, 5+3) = 8 ≥ 8');
      });

      test('reason đúng format "SQL: x/y kỹ năng khớp, a/b năm KN." khi khớp đủ', () {
        expect(
          scoreOne(perfectCv, perfectJob).recommendationReason,
          'SQL: 3/3 kỹ năng khớp, 3/3 năm KN. Đủ kỹ năng.',
          reason: 'backend dựng reason từ tỉ lệ khớp và mốc kinh nghiệm',
        );
      });

      test('reason liệt kê kỹ năng thiếu; job không yêu cầu kỹ năng ghi "0/?"', () {
        expect(
          scoreOne({...perfectCv, 'skills': ['flutter']}, perfectJob)
              .recommendationReason,
          contains('Thiếu: dart, firebase.'),
          reason: 'reason liệt kê tối đa 3 kỹ năng thiếu',
        );
        expect(
          scoreOne(perfectCv, neutralJob).recommendationReason,
          contains('0/? kỹ năng khớp'),
          reason: 'job không có requiredSkills → mẫu số "?" như backend',
        );
      });

      test('source của kết quả rule-based là "sql"', () {
        expect(scoreOne(perfectCv, perfectJob).source, 'sql',
            reason: 'backend đánh dấu source: "sql" cho luồng score-sql');
      });
    });
  });
}
