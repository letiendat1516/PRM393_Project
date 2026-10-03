// Mirrors the PostgreSQL enum types in docs/08_DATABASE.md so Firestore wire
// values stay identical to the web backend (UPPER_SNAKE_CASE).

enum UserRole { jobSeeker, employer, admin }

enum SkillSource { manual, ai }

enum SalaryPeriod { hour, month, year }

enum WorkMode { onsite, remote, hybrid }

enum JobType { fullTime, partTime, internship, contract }

enum ExperienceLevel { intern, fresher, junior, mid, senior, lead }

enum JobStatus { draft, open, paused, closed, expired }

enum ApplicationStatus {
  submitted,
  underReview,
  interview,
  offer,
  accepted,
  rejected,
  withdrawn,
}

enum RecommendationStatus { new_, viewed, dismissed, applied }

enum ApprovalStatus { pending, approved, rejected }

enum VerificationStatus { pending, verified, rejected }

enum Gender { male, female, other }

enum NotificationType {
  applicationStatus,
  newApplication,
  jobApproved,
  jobRejected,
  employerVerified,
  system,
}

String _camelToSnake(String s) => s
    .replaceAll('_', '')
    .replaceAllMapped(RegExp(r'([a-z0-9])([A-Z])'), (m) => '${m[1]}_${m[2]}')
    .toUpperCase();

/// `ApplicationStatus.underReview` → `UNDER_REVIEW`, `RecommendationStatus.new_` → `NEW`.
String enumToWire(Object e) => _camelToSnake(e.toString().split('.').last);

T _parse<T>(Iterable<T> values, String? wire, T fallback) {
  if (wire == null || wire.isEmpty) return fallback;
  final target = wire.replaceAll('-', '_').toUpperCase();
  for (final v in values) {
    if (enumToWire(v as Object) == target) return v;
    final plain = v.toString().split('.').last.replaceAll('_', '').toLowerCase();
    if (plain == target.replaceAll('_', '').toLowerCase()) return v;
  }
  return fallback;
}

UserRole parseUserRole(String? s) {
  switch ((s ?? '').toLowerCase()) {
    case 'employer':
      return UserRole.employer;
    case 'admin':
      return UserRole.admin;
    default:
      return UserRole.jobSeeker;
  }
}

String userRoleToWire(UserRole r) => switch (r) {
      UserRole.jobSeeker => 'job_seeker',
      UserRole.employer => 'employer',
      UserRole.admin => 'admin',
    };

SkillSource parseSkillSource(String? s) =>
    _parse(SkillSource.values, s, SkillSource.manual);
SalaryPeriod parseSalaryPeriod(String? s) =>
    _parse(SalaryPeriod.values, s, SalaryPeriod.month);
WorkMode parseWorkMode(String? s) => _parse(WorkMode.values, s, WorkMode.onsite);
JobType parseJobType(String? s) => _parse(JobType.values, s, JobType.fullTime);
ExperienceLevel parseLevel(String? s) =>
    _parse(ExperienceLevel.values, s, ExperienceLevel.junior);
JobStatus parseJobStatus(String? s) => _parse(JobStatus.values, s, JobStatus.open);
ApplicationStatus parseAppStatus(String? s) =>
    _parse(ApplicationStatus.values, s, ApplicationStatus.submitted);
RecommendationStatus parseRecommendationStatus(String? s) =>
    _parse(RecommendationStatus.values, s, RecommendationStatus.new_);
ApprovalStatus parseApprovalStatus(String? s) =>
    _parse(ApprovalStatus.values, s, ApprovalStatus.pending);
VerificationStatus parseVerificationStatus(String? s) =>
    _parse(VerificationStatus.values, s, VerificationStatus.pending);
Gender? parseGender(String? s) {
  if (s == null || s.isEmpty) return null;
  return _parse(Gender.values, s, Gender.other);
}
NotificationType parseNotifType(String? s) =>
    _parse(NotificationType.values, s, NotificationType.system);

// Vietnamese display labels used across screens (mirrors frontend/src/utils/format.js).
extension WorkModeLabel on WorkMode {
  String get label => switch (this) {
        WorkMode.onsite => 'Tại văn phòng',
        WorkMode.remote => 'Từ xa',
        WorkMode.hybrid => 'Kết hợp',
      };
}

extension JobTypeLabel on JobType {
  String get label => switch (this) {
        JobType.fullTime => 'Toàn thời gian',
        JobType.partTime => 'Bán thời gian',
        JobType.internship => 'Thực tập',
        JobType.contract => 'Hợp đồng',
      };
}

extension ExperienceLevelLabel on ExperienceLevel {
  String get label => switch (this) {
        ExperienceLevel.intern => 'Thực tập sinh',
        ExperienceLevel.fresher => 'Fresher',
        ExperienceLevel.junior => 'Junior',
        ExperienceLevel.mid => 'Middle',
        ExperienceLevel.senior => 'Senior',
        ExperienceLevel.lead => 'Lead / Quản lý',
      };
}

extension JobStatusLabel on JobStatus {
  String get label => switch (this) {
        JobStatus.draft => 'Nháp',
        JobStatus.open => 'Đang tuyển',
        JobStatus.paused => 'Tạm dừng',
        JobStatus.closed => 'Đã đóng',
        JobStatus.expired => 'Hết hạn',
      };
}

extension ApplicationStatusLabel on ApplicationStatus {
  String get label => switch (this) {
        ApplicationStatus.submitted => 'Đã nộp',
        ApplicationStatus.underReview => 'Đang xem xét',
        ApplicationStatus.interview => 'Phỏng vấn',
        ApplicationStatus.offer => 'Đã có offer',
        ApplicationStatus.accepted => 'Được nhận',
        ApplicationStatus.rejected => 'Từ chối',
        ApplicationStatus.withdrawn => 'Đã rút',
      };
}

extension SalaryPeriodLabel on SalaryPeriod {
  String get label => switch (this) {
        SalaryPeriod.hour => '/giờ',
        SalaryPeriod.month => '/tháng',
        SalaryPeriod.year => '/năm',
      };
}

extension GenderLabel on Gender {
  String get label => switch (this) {
        Gender.male => 'Nam',
        Gender.female => 'Nữ',
        Gender.other => 'Khác',
      };
}
