import '../../../core/utils/enums.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/models/job_model.dart';

const Object _unset = Object();

/// Create/Edit job form payload (jobValidator.js createJobSchema parity).
/// Serialisable so the draft can be persisted in SharedPreferences.
class JobFormInput {
  const JobFormInput({
    this.title = '',
    this.categoryId,
    this.categoryName = '',
    this.moTaCongViec = '',
    this.yeuCauUngVien = '',
    this.quyenLoi = '',
    this.thoiGianLamViec = '',
    this.yeuCauBangCap = 'Không yêu cầu',
    this.salaryMin,
    this.salaryMax,
    this.currency = 'VND',
    this.salaryPeriod = SalaryPeriod.month,
    this.isSalaryNegotiable = false,
    this.location = '',
    this.city = '',
    this.workMode = WorkMode.hybrid,
    this.jobType = JobType.fullTime,
    this.experienceLevel = ExperienceLevel.junior,
    this.positions = 1,
    this.deadline,
    this.skills = const [],
  });

  final String title;
  final String? categoryId;
  final String categoryName;
  final String moTaCongViec;
  final String yeuCauUngVien;
  final String quyenLoi;
  final String thoiGianLamViec;
  final String yeuCauBangCap;
  final int? salaryMin;
  final int? salaryMax;
  final String currency;
  final SalaryPeriod salaryPeriod;
  final bool isSalaryNegotiable;
  final String location;
  final String city;
  final WorkMode workMode;
  final JobType jobType;
  final ExperienceLevel experienceLevel;
  final int positions;
  final DateTime? deadline;
  final List<String> skills;

  static const bangCapOptions = [
    'Không yêu cầu',
    'Trung cấp',
    'Cao đẳng',
    'Đại học',
    'Sau đại học',
  ];

  /// True when nothing meaningful was typed (draft not worth saving).
  bool get isBlank =>
      title.trim().isEmpty &&
      moTaCongViec.trim().isEmpty &&
      location.trim().isEmpty &&
      skills.isEmpty;

  JobFormInput copyWith({
    String? title,
    Object? categoryId = _unset,
    String? categoryName,
    String? moTaCongViec,
    String? yeuCauUngVien,
    String? quyenLoi,
    String? thoiGianLamViec,
    String? yeuCauBangCap,
    Object? salaryMin = _unset,
    Object? salaryMax = _unset,
    String? currency,
    SalaryPeriod? salaryPeriod,
    bool? isSalaryNegotiable,
    String? location,
    String? city,
    WorkMode? workMode,
    JobType? jobType,
    ExperienceLevel? experienceLevel,
    int? positions,
    Object? deadline = _unset,
    List<String>? skills,
  }) =>
      JobFormInput(
        title: title ?? this.title,
        categoryId:
            identical(categoryId, _unset) ? this.categoryId : categoryId as String?,
        categoryName: categoryName ?? this.categoryName,
        moTaCongViec: moTaCongViec ?? this.moTaCongViec,
        yeuCauUngVien: yeuCauUngVien ?? this.yeuCauUngVien,
        quyenLoi: quyenLoi ?? this.quyenLoi,
        thoiGianLamViec: thoiGianLamViec ?? this.thoiGianLamViec,
        yeuCauBangCap: yeuCauBangCap ?? this.yeuCauBangCap,
        salaryMin: identical(salaryMin, _unset) ? this.salaryMin : salaryMin as int?,
        salaryMax: identical(salaryMax, _unset) ? this.salaryMax : salaryMax as int?,
        currency: currency ?? this.currency,
        salaryPeriod: salaryPeriod ?? this.salaryPeriod,
        isSalaryNegotiable: isSalaryNegotiable ?? this.isSalaryNegotiable,
        location: location ?? this.location,
        city: city ?? this.city,
        workMode: workMode ?? this.workMode,
        jobType: jobType ?? this.jobType,
        experienceLevel: experienceLevel ?? this.experienceLevel,
        positions: positions ?? this.positions,
        deadline: identical(deadline, _unset) ? this.deadline : deadline as DateTime?,
        skills: skills ?? this.skills,
      );

  // ── Description helpers ───────────────────────────────────────────────
  static List<String> splitLines(String text) => text
      .split(RegExp(r'\r?\n'))
      .map((l) => l.replaceFirst(RegExp(r'^\s*[-•*]\s*'), '').trim())
      .where((l) => l.isNotEmpty)
      .toList();

  JobDescription toDescription() => JobDescription(
        moTaCongViec: splitLines(moTaCongViec),
        yeuCauUngVien: splitLines(yeuCauUngVien),
        quyenLoi: splitLines(quyenLoi),
        thoiGianLamViec: thoiGianLamViec.trim(),
        yeuCauKinhNghiem: experienceLevel.jobMapperLabel,
        yeuCauBangCap: yeuCauBangCap,
      );

  /// Builds a JobModel used by the live preview card (not persisted).
  JobModel toPreview({
    required String employerId,
    required String employerName,
    String? employerLogoUrl,
    String? employerCity,
    bool requireApproval = true,
  }) =>
      JobModel(
        jobId: 'preview',
        employerId: employerId,
        employerName: employerName,
        employerLogoUrl: employerLogoUrl,
        employerCity: employerCity,
        jobTitle: title.trim().isEmpty ? 'Tin tuyển dụng chưa có tiêu đề' : title.trim(),
        categoryId: categoryId,
        categoryName: categoryName.trim().isEmpty ? null : categoryName.trim(),
        description: toDescription(),
        salaryMin: salaryMin,
        salaryMax: salaryMax,
        salaryCurrency: currency,
        salaryPeriod: salaryPeriod,
        isSalaryNegotiable: isSalaryNegotiable,
        location: location.trim().isEmpty ? null : location.trim(),
        city: city.trim().isEmpty ? location.trim() : city.trim(),
        workMode: workMode,
        jobType: jobType,
        experienceLevel: experienceLevel,
        positionsAvailable: positions,
        applicationDeadline: deadline,
        status: requireApproval ? JobStatus.draft : JobStatus.open,
        isApproved: !requireApproval,
        requiredSkills: [for (final s in skills) JobSkillRef(skillName: s)],
        createdAt: DateTime.now(),
      );

  // ── Mapping from an existing job (edit mode) ──────────────────────────
  factory JobFormInput.fromJob(JobModel job) => JobFormInput(
        title: job.jobTitle,
        categoryId: job.categoryId,
        categoryName: job.categoryName ?? '',
        moTaCongViec: job.description.moTaCongViec.join('\n'),
        yeuCauUngVien: job.description.yeuCauUngVien.join('\n'),
        quyenLoi: job.description.quyenLoi.join('\n'),
        thoiGianLamViec: job.description.thoiGianLamViec,
        yeuCauBangCap: job.description.yeuCauBangCap,
        salaryMin: job.salaryMin?.toInt(),
        salaryMax: job.salaryMax?.toInt(),
        currency: job.salaryCurrency,
        salaryPeriod: job.salaryPeriod,
        isSalaryNegotiable: job.isSalaryNegotiable,
        location: job.location ?? '',
        city: job.city,
        workMode: job.workMode,
        jobType: job.jobType,
        experienceLevel: job.experienceLevel,
        positions: job.positionsAvailable,
        deadline: job.applicationDeadline,
        skills: job.tags,
      );

  // ── Draft persistence (PrefsService.jobDraft) ─────────────────────────
  Map<String, dynamic> toJson() => {
        'title': title,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'moTaCongViec': moTaCongViec,
        'yeuCauUngVien': yeuCauUngVien,
        'quyenLoi': quyenLoi,
        'thoiGianLamViec': thoiGianLamViec,
        'yeuCauBangCap': yeuCauBangCap,
        'salaryMin': salaryMin,
        'salaryMax': salaryMax,
        'currency': currency,
        'salaryPeriod': enumToWire(salaryPeriod),
        'isSalaryNegotiable': isSalaryNegotiable,
        'location': location,
        'city': city,
        'workMode': enumToWire(workMode),
        'jobType': enumToWire(jobType),
        'experienceLevel': enumToWire(experienceLevel),
        'positions': positions,
        'deadline': deadline?.toIso8601String(),
        'skills': skills,
        'savedAt': DateTime.now().toIso8601String(),
      };

  factory JobFormInput.fromJson(Map<String, dynamic> j) => JobFormInput(
        title: (j['title'] ?? '') as String,
        categoryId: j['categoryId'] as String?,
        categoryName: (j['categoryName'] ?? '') as String,
        moTaCongViec: (j['moTaCongViec'] ?? '') as String,
        yeuCauUngVien: (j['yeuCauUngVien'] ?? '') as String,
        quyenLoi: (j['quyenLoi'] ?? '') as String,
        thoiGianLamViec: (j['thoiGianLamViec'] ?? '') as String,
        yeuCauBangCap: (j['yeuCauBangCap'] ?? 'Không yêu cầu') as String,
        salaryMin: (j['salaryMin'] as num?)?.toInt(),
        salaryMax: (j['salaryMax'] as num?)?.toInt(),
        currency: (j['currency'] ?? 'VND') as String,
        salaryPeriod: parseSalaryPeriod(j['salaryPeriod'] as String?),
        isSalaryNegotiable: (j['isSalaryNegotiable'] ?? false) as bool,
        location: (j['location'] ?? '') as String,
        city: (j['city'] ?? '') as String,
        workMode: parseWorkMode(j['workMode'] as String?),
        jobType: parseJobType(j['jobType'] as String?),
        experienceLevel: parseLevel(j['experienceLevel'] as String?),
        positions: ((j['positions'] ?? 1) as num).toInt(),
        deadline: j['deadline'] == null ? null : DateTime.tryParse(j['deadline'] as String),
        skills: ((j['skills'] as List?)?.map((e) => e.toString()).toList()) ?? const [],
      );

  static DateTime? savedAtOf(Map<String, dynamic> j) =>
      j['savedAt'] == null ? null : DateTime.tryParse(j['savedAt'] as String);

  // ── Validation (Validators = backend jobValidator limits) ─────────────
  static const fieldLabels = {
    'title': 'Tên vị trí tuyển dụng',
    'description': 'Mô tả công việc',
    'salaryMin': 'Lương tối thiểu',
    'salaryMax': 'Lương tối đa',
    'currency': 'Đơn vị tiền tệ',
    'location': 'Địa điểm làm việc',
    'city': 'Thành phố',
    'experience': 'Kinh nghiệm',
    'category': 'Ngành nghề',
    'categoryId': 'Ngành nghề',
    'workType': 'Hình thức làm việc',
    'employmentType': 'Loại hình công việc',
    'skills': 'Kỹ năng yêu cầu',
    'positionsAvailable': 'Số lượng tuyển',
    'applicationDeadline': 'Hạn nộp hồ sơ',
  };

  /// Step 1 (Thông tin) field errors.
  Map<String, String> validateInfo() {
    final errors = <String, String>{};
    final t = Validators.jobTitle(title);
    if (t != null) errors['title'] = t;
    final d = Validators.jobDescription(moTaCongViec);
    if (d != null) errors['description'] = d;
    if (categoryName.trim().isEmpty && (categoryId == null || categoryId!.isEmpty)) {
      errors['category'] = 'Vui lòng chọn hoặc nhập ngành nghề.';
    } else if (categoryName.trim().length > 100) {
      errors['category'] = 'Ngành nghề tối đa 100 ký tự.';
    }
    return errors;
  }

  /// Step 2 (Lương & địa điểm) field errors.
  Map<String, String> validateSalaryLocation() {
    final errors = <String, String>{};
    if (!isSalaryNegotiable) {
      if (salaryMin != null && salaryMin! < 0) {
        errors['salaryMin'] = 'Lương tối thiểu phải là số không âm.';
      }
      if (salaryMax != null && salaryMax! < 0) {
        errors['salaryMax'] = 'Lương tối đa phải là số không âm.';
      }
      final range = Validators.salaryRange(salaryMin, salaryMax);
      if (range != null) errors['salaryMax'] = range;
    }
    final cur = currency.trim();
    if (cur.length != 3 || !RegExp(r'^[A-Za-z]{3}$').hasMatch(cur)) {
      errors['currency'] = 'Đơn vị tiền tệ phải gồm đúng 3 chữ cái (ví dụ VND).';
    }
    final loc = Validators.jobLocation(location);
    if (loc != null) errors['location'] = loc;
    // Web: <input required placeholder="Hà Nội"> — any text, max 100.
    if (city.trim().isEmpty) {
      errors['city'] = 'Thành phố là bắt buộc.';
    } else if (city.trim().length > 100) {
      errors['city'] = 'Thành phố tối đa 100 ký tự.';
    }
    final pos = Validators.positiveInt('$positions', label: 'Số lượng tuyển');
    if (pos != null) errors['positionsAvailable'] = pos;
    // Web: <input required type="date" min={today}>.
    if (deadline == null) {
      errors['applicationDeadline'] = 'Hạn nộp hồ sơ là bắt buộc.';
    } else {
      final dl = Validators.deadlineNotPast(deadline);
      if (dl != null) errors['applicationDeadline'] = dl;
    }
    return errors;
  }

  /// Step 3 (Kỹ năng) field errors.
  Map<String, String> validateSkills(int maxSkills) {
    final errors = <String, String>{};
    final normalized = normalizeSkills(skills);
    if (normalized.length > maxSkills) {
      errors['skills'] = 'Một tin tuyển dụng không được có quá $maxSkills kỹ năng.';
    }
    for (final s in normalized) {
      if (s.length > 80) {
        errors['skills'] = 'Tên kỹ năng tối đa 80 ký tự.';
        break;
      }
    }
    return errors;
  }

  Map<String, String> validateAll(int maxSkills) => {
        ...validateInfo(),
        ...validateSalaryLocation(),
        ...validateSkills(maxSkills),
      };

  /// JobService.normalizeSkillNames: trim, drop blanks, case-insensitive
  /// de-dup keeping the first casing.
  static List<String> normalizeSkills(Iterable<String> names) {
    final seen = <String>{};
    final out = <String>[];
    for (final raw in names) {
      final n = raw.trim();
      if (n.isEmpty) continue;
      if (seen.add(n.toLowerCase())) out.add(n);
    }
    return out;
  }
}
