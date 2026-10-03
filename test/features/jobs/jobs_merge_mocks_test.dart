import 'package:flutter_test/flutter_test.dart';
import 'package:jobhub_prm393/core/data/demo_data.dart';
import 'package:jobhub_prm393/core/utils/enums.dart';
import 'package:jobhub_prm393/features/jobs/data/jobs_repository.dart';
import 'package:jobhub_prm393/shared/models/job_model.dart';

/// JobsRepository.mergeWithMocks — jobMapper.mergeJobs parity:
/// mock SYN- trước, job database public phía sau, dedupe theo jobId;
/// ≥ [JobsRepository.mockFallbackThreshold] job public thì bỏ mock.
void main() {
  // Job tối giản: chỉ các field bắt buộc + trạng thái duyệt/mở.
  JobModel mk(
    String id, {
    bool approved = true,
    JobStatus status = JobStatus.open,
    String title = 'Developer',
  }) =>
      JobModel(
        jobId: id,
        employerId: 'emp-$id',
        employerName: 'Công ty $id',
        jobTitle: title,
        isApproved: approved,
        status: status,
        source: 'database',
      );

  List<JobModel> mkMany(int n, {String prefix = 'real'}) => [
        for (var i = 1; i <= n; i++) mk('$prefix-$i'),
      ];

  group('JobsRepository.mergeWithMocks', () {
    test('apiJobs rỗng → trả đúng 12 mock SYN- (DemoData.sampleJobs)', () {
      final out = JobsRepository.mergeWithMocks(const []);
      expect(out.length, DemoData.sampleJobs().length, reason: 'fallback đầy đủ mock');
      expect(out.length, 12);
      expect(out.every((j) => j.jobId.startsWith('SYN-')), isTrue);
    });

    test('apiJobs < 50 (10 job thật) → merge 12 mock + 10 thật = 22, dedupe theo jobId', () {
      final out = JobsRepository.mergeWithMocks(mkMany(10));
      expect(out.length, 22, reason: '12 mock + 10 real, id không trùng nhau');
      // Mock đứng trước (jobMapper parity: sample data trước database).
      expect(out.take(12).every((j) => j.jobId.startsWith('SYN-')), isTrue);
      expect(out.skip(12).every((j) => j.jobId.startsWith('real-')), isTrue);
      // Không trùng jobId.
      expect(out.map((j) => j.jobId).toSet().length, 22);
    });

    test('apiJobs >= 50 (60 job thật) → bỏ hẳn mock, trả đúng 60 thật', () {
      final out = JobsRepository.mergeWithMocks(mkMany(60));
      expect(out.length, 60);
      expect(out.any((j) => j.jobId.startsWith('SYN-')), isFalse,
          reason: 'ngưỡng mockFallbackThreshold=50 đã đạt');
      expect(JobsRepository.mockFallbackThreshold, 50);
    });

    test('apiJobs lẫn public và pending (DRAFT) → chỉ job public được qua filter', () {
      final api = [
        ...mkMany(10),
        for (var i = 1; i <= 5; i++)
          mk('draft-$i', status: JobStatus.draft, approved: false),
      ];
      final out = JobsRepository.mergeWithMocks(api);
      expect(out.length, 22, reason: '5 draft bị lọc bỏ, 10 public merge với 12 mock');
      expect(out.any((j) => j.jobId.startsWith('draft-')), isFalse);
    });

    test('apiJobs có job jobId rỗng → bị bỏ qua', () {
      final api = [...mkMany(3), mk('')];
      final out = JobsRepository.mergeWithMocks(api);
      expect(out.length, 15, reason: '12 mock + 3 real, job id rỗng bị drop');
      expect(out.any((j) => j.jobId.isEmpty), isFalse);
    });

    test('apiJobs 60 job nhưng 55 pending + 5 public → vẫn fallback mock (publicApi=5 < 50)', () {
      final api = [
        ...mkMany(5),
        for (var i = 1; i <= 55; i++)
          mk('pending-$i', status: JobStatus.draft, approved: false),
      ];
      final out = JobsRepository.mergeWithMocks(api);
      expect(out.length, 17, reason: '12 mock + 5 public thật');
      expect(out.any((j) => j.jobId.startsWith('pending-')), isFalse);
    });

    test('apiJob trùng jobId với SYN mock — fallback branch: mock giữ chỗ, api bị bỏ (keep-first)', () {
      final dupe = mk('SYN-00001', title: 'Bản thật bị trùng id');
      final out = JobsRepository.mergeWithMocks([...mkMany(3), dupe]);
      expect(out.length, 15, reason: '12 mock + 3 real; dupe không nhân thêm entry');
      final syn1 = out.firstWhere((j) => j.jobId == 'SYN-00001');
      expect(syn1.source, 'mock', reason: 'mock ghi trước nên thắng trong putIfAbsent');
      expect(syn1.jobTitle, isNot(dupe.jobTitle));
    });

    test('apiJob trùng jobId với SYN mock — non-fallback branch (≥50 public): không có mock nào', () {
      final api = [...mkMany(59), mk('SYN-00001')];
      final out = JobsRepository.mergeWithMocks(api);
      expect(out.length, 60, reason: 'đủ ngưỡng 50 → trả nguyên publicApi');
      // Chỉ có 1 entry SYN-00001 và nó là bản database, không phải mock.
      final syns = out.where((j) => j.jobId == 'SYN-00001').toList();
      expect(syns.length, 1);
      expect(syns.single.source, 'database');
      // Không entry nào là mock của DemoData.
      final mockIds = DemoData.sampleJobs().map((j) => j.jobId).toSet();
      expect(out.any((j) => mockIds.contains(j.jobId) && j.source == 'mock'), isFalse);
    });
  });
}
