import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/utils/enums.dart';

/// job_skill row (embedded in jobs/{id}.requiredSkills[]).
class JobSkillRef {
  const JobSkillRef({
    required this.skillName,
    this.skillId,
    this.isRequired = true,
    this.minExperienceYears = 0,
    this.weight = 1,
  });

  final String? skillId;
  final String skillName;
  final bool isRequired;
  final double minExperienceYears;
  final int weight;

  factory JobSkillRef.fromJson(Map<String, dynamic> j) => JobSkillRef(
        skillId: j['skillId'] as String?,
        skillName: (j['skillName'] ?? j['name'] ?? '') as String,
        isRequired: (j['isRequired'] ?? j['required'] ?? true) as bool,
        minExperienceYears:
            ((j['minExperienceYears'] ?? j['minYears'] ?? 0) as num).toDouble(),
        weight: ((j['weight'] ?? 1) as num).toInt(),
      );

  Map<String, dynamic> toJson() => {
        if (skillId != null) 'skillId': skillId,
        'skillName': skillName,
        'isRequired': isRequired,
        'minExperienceYears': minExperienceYears,
        'weight': weight,
      };
}

/// Structured job_description contract (scripts/crawl-topcv/README.md).
/// Falls back to a plain-text split when the stored description is not JSON.
class JobDescription {
  const JobDescription({
    this.moTaCongViec = const [],
    this.yeuCauUngVien = const [],
    this.quyenLoi = const [],
    this.thoiGianLamViec = '',
    this.yeuCauKinhNghiem = '',
    this.yeuCauBangCap = 'Không yêu cầu',
  });

  final List<String> moTaCongViec;
  final List<String> yeuCauUngVien;
  final List<String> quyenLoi;
  final String thoiGianLamViec;
  final String yeuCauKinhNghiem;
  final String yeuCauBangCap;

  bool get isEmpty =>
      moTaCongViec.isEmpty && yeuCauUngVien.isEmpty && quyenLoi.isEmpty;

  static List<String> _lines(Object? v) {
    if (v is List) return v.map((e) => e.toString()).toList();
    if (v is String) return _splitBullets(v);
    return const [];
  }

  static List<String> _splitBullets(String text) => text
      .split(RegExp(r'\r?\n'))
      .map((l) => l.replaceFirst(RegExp(r'^\s*[-•*]\s*'), '').trim())
      .where((l) => l.isNotEmpty)
      .toList();

  factory JobDescription.fromMap(Map<String, dynamic> m) => JobDescription(
        moTaCongViec: _lines(m['moTaCongViec'] ?? m['mo_ta_cong_viec']),
        yeuCauUngVien: _lines(m['yeuCauUngVien'] ?? m['yeu_cau_ung_vien']),
        quyenLoi: _lines(m['quyenLoi'] ?? m['quyen_loi']),
        thoiGianLamViec:
            (m['thoiGianLamViec'] ?? m['thoi_gian_lam_viec'] ?? '') as String,
        yeuCauKinhNghiem:
            (m['yeuCauKinhNghiem'] ?? m['yeu_cau_kinh_nghiem'] ?? '') as String,
        yeuCauBangCap: (m['yeuCauBangCap'] ??
            m['yeu_cau_bang_cap'] ??
            'Không yêu cầu') as String,
      );

  /// jobMapper.parseJobDetail: object → as is; JSON string → parse; plain text
  /// → bullet lines into moTaCongViec.
  factory JobDescription.parse(Object? raw, {String experienceLabel = ''}) {
    if (raw == null) return JobDescription(yeuCauKinhNghiem: experienceLabel);
    if (raw is Map) return JobDescription.fromMap(raw.cast<String, dynamic>());
    final s = raw.toString().trim();
    if (s.startsWith('{')) {
      try {
        final m = jsonDecode(s);
        if (m is Map) return JobDescription.fromMap(m.cast<String, dynamic>());
      } catch (_) {}
    }
    return JobDescription(
      moTaCongViec: _splitBullets(s),
      yeuCauKinhNghiem: experienceLabel,
    );
  }

  Map<String, dynamic> toJson() => {
        'moTaCongViec': moTaCongViec,
        'yeuCauUngVien': yeuCauUngVien,
        'quyenLoi': quyenLoi,
        'thoiGianLamViec': thoiGianLamViec,
        'yeuCauKinhNghiem': yeuCauKinhNghiem,
        'yeuCauBangCap': yeuCauBangCap,
      };

  String get plainText => [
        ...moTaCongViec,
        if (yeuCauUngVien.isNotEmpty) 'Yêu cầu: ${yeuCauUngVien.join('. ')}',
        if (quyenLoi.isNotEmpty) 'Quyền lợi: ${quyenLoi.join('. ')}',
      ].join('\n');
}

/// jobs/{jobId} — mirrors table job + job_skill + denormalised employer /
/// category fields for list rendering.
class JobModel {
  const JobModel({
    required this.jobId,
    required this.employerId,
    required this.employerName,
    required this.jobTitle,
    this.employerLogoUrl,
    this.employerCity,
    this.employerWebsite,
    this.categoryId,
    this.categoryName,
    this.description = const JobDescription(),
    this.rawDescription,
    this.salaryMin,
    this.salaryMax,
    this.salaryCurrency = 'VND',
    this.salaryPeriod = SalaryPeriod.month,
    this.isSalaryNegotiable = false,
    this.location,
    this.city = '',
    this.country = 'Vietnam',
    this.workMode = WorkMode.onsite,
    this.jobType = JobType.fullTime,
    this.experienceLevel = ExperienceLevel.intern,
    this.positionsAvailable = 1,
    this.applicationDeadline,
    this.status = JobStatus.open,
    this.isApproved = false,
    this.requiredSkills = const [],
    this.titleTokens = const [],
    this.applicationsCount = 0,
    this.source = 'database',
    this.createdAt,
    this.updatedAt,
  });

  final String jobId;
  final String employerId;
  final String employerName;
  final String? employerLogoUrl;
  final String? employerCity;
  final String? employerWebsite;
  final String? categoryId;
  final String? categoryName;
  final String jobTitle;
  final JobDescription description;
  final String? rawDescription;
  final num? salaryMin;
  final num? salaryMax;
  final String salaryCurrency;
  final SalaryPeriod salaryPeriod;
  final bool isSalaryNegotiable;
  final String? location;
  final String city;
  final String country;
  final WorkMode workMode;
  final JobType jobType;
  final ExperienceLevel experienceLevel;
  final int positionsAvailable;
  final DateTime? applicationDeadline;
  final JobStatus status;
  final bool isApproved;
  final List<JobSkillRef> requiredSkills;
  final List<String> titleTokens;
  final int applicationsCount;
  final String source; // 'database' | 'mock'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // ── Derived (jobMapper.js parity) ───────────────────────────────────
  List<String> get tags =>
      requiredSkills.map((s) => s.skillName).where((s) => s.isNotEmpty).toList();

  /// jobMapper: hot = salary_max >= 50.000.000.
  bool get hot => (salaryMax ?? 0) >= 50000000;

  bool get isPublic => isApproved && status == JobStatus.open;

  /// jobMapper getDeadlineFullLabel + applications apply gate: deadline is
  /// compared at day granularity (deadline < today), matching
  /// ApplicationsRepository.deadlinePassed so both sources agree.
  bool get isExpired {
    final d = applicationDeadline;
    if (d == null) return false;
    final now = DateTime.now();
    return DateTime(d.year, d.month, d.day)
        .isBefore(DateTime(now.year, now.month, now.day));
  }

  bool get acceptsApplications => isPublic && !isExpired;

  /// AdminPendingJobsPage: pending == DRAFT && !isApproved.
  bool get isPendingReview => status == JobStatus.draft && !isApproved;

  /// Reopen is forbidden once a job was rejected (isApproved=false, CLOSED).
  bool get isRejected => status == JobStatus.closed && !isApproved;

  double get minExperienceYears => switch (experienceLevel) {
        ExperienceLevel.intern => 0,
        ExperienceLevel.fresher => 0.5,
        ExperienceLevel.junior => 1,
        ExperienceLevel.mid => 3,
        ExperienceLevel.senior => 5,
        ExperienceLevel.lead => 7,
      };

  String get applicationsLabel => '$applicationsCount người';

  factory JobModel.fromJson(Map<String, dynamic> j) {
    final level = parseLevel(j['experienceLevel'] as String?);
    return JobModel(
      jobId: (j['jobId'] ?? j['id'] ?? '') as String,
      employerId: (j['employerId'] ?? j['employerUid'] ?? '') as String,
      employerName: (j['employerName'] ?? 'Công ty chưa cập nhật') as String,
      employerLogoUrl: j['employerLogoUrl'] as String?,
      employerCity: j['employerCity'] as String?,
      employerWebsite: j['employerWebsite'] as String?,
      categoryId: j['categoryId'] as String?,
      categoryName: j['categoryName'] as String?,
      jobTitle: (j['jobTitle'] ?? j['title'] ?? 'Tin tuyển dụng chưa có tiêu đề')
          as String,
      description: JobDescription.parse(
        j['description'] ?? j['jobDescription'],
        experienceLabel: level.jobMapperLabel,
      ),
      rawDescription: j['jobDescription'] is String
          ? j['jobDescription'] as String
          : (j['description'] is String ? j['description'] as String : null),
      salaryMin: j['salaryMin'] as num?,
      salaryMax: j['salaryMax'] as num?,
      salaryCurrency: (j['salaryCurrency'] ?? 'VND') as String,
      salaryPeriod: parseSalaryPeriod(j['salaryPeriod'] as String?),
      isSalaryNegotiable: (j['isSalaryNegotiable'] ?? false) as bool,
      location: j['location'] as String?,
      city: (j['city'] ?? '') as String,
      country: (j['country'] ?? 'Vietnam') as String,
      workMode: parseWorkMode(j['workMode'] as String?),
      jobType: parseJobType(j['jobType'] as String?),
      experienceLevel: level,
      positionsAvailable: ((j['positionsAvailable'] ?? j['positions'] ?? 1) as num).toInt(),
      applicationDeadline: _date(j['applicationDeadline'] ?? j['deadline']),
      status: parseJobStatus(j['status'] as String?),
      isApproved: (j['isApproved'] ?? false) as bool,
      requiredSkills: ((j['requiredSkills'] ?? j['skills']) as List?)
              ?.whereType<Map>()
              .map((m) => JobSkillRef.fromJson(m.cast<String, dynamic>()))
              .toList() ??
          const [],
      titleTokens: ((j['titleTokens'] as List?)?.cast<String>()) ?? const [],
      applicationsCount: ((j['applicationsCount'] ?? 0) as num).toInt(),
      source: (j['source'] ?? 'database') as String,
      createdAt: _date(j['createdAt']),
      updatedAt: _date(j['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'jobId': jobId,
        'employerId': employerId,
        'employerName': employerName,
        if (employerLogoUrl != null) 'employerLogoUrl': employerLogoUrl,
        if (employerCity != null) 'employerCity': employerCity,
        if (employerWebsite != null) 'employerWebsite': employerWebsite,
        if (categoryId != null) 'categoryId': categoryId,
        if (categoryName != null) 'categoryName': categoryName,
        'jobTitle': jobTitle,
        'description': description.toJson(),
        if (rawDescription != null) 'jobDescription': rawDescription,
        if (salaryMin != null) 'salaryMin': salaryMin,
        if (salaryMax != null) 'salaryMax': salaryMax,
        'salaryCurrency': salaryCurrency,
        'salaryPeriod': enumToWire(salaryPeriod),
        'isSalaryNegotiable': isSalaryNegotiable,
        if (location != null) 'location': location,
        'city': city,
        'country': country,
        'workMode': enumToWire(workMode),
        'jobType': enumToWire(jobType),
        'experienceLevel': enumToWire(experienceLevel),
        'positionsAvailable': positionsAvailable,
        if (applicationDeadline != null)
          'applicationDeadline': Timestamp.fromDate(applicationDeadline!),
        'status': enumToWire(status),
        'isApproved': isApproved,
        'requiredSkills': requiredSkills.map((e) => e.toJson()).toList(),
        'titleTokens': titleTokens.isNotEmpty ? titleTokens : tokenize(jobTitle, employerName),
        'applicationsCount': applicationsCount,
        'source': source,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  JobModel copyWith({
    String? jobId,
    String? employerName,
    String? employerLogoUrl,
    String? categoryId,
    String? categoryName,
    String? jobTitle,
    JobDescription? description,
    num? salaryMin,
    num? salaryMax,
    String? salaryCurrency,
    SalaryPeriod? salaryPeriod,
    bool? isSalaryNegotiable,
    String? location,
    String? city,
    WorkMode? workMode,
    JobType? jobType,
    ExperienceLevel? experienceLevel,
    int? positionsAvailable,
    DateTime? applicationDeadline,
    JobStatus? status,
    bool? isApproved,
    List<JobSkillRef>? requiredSkills,
    int? applicationsCount,
    DateTime? createdAt,
  }) =>
      JobModel(
        jobId: jobId ?? this.jobId,
        employerId: employerId,
        employerName: employerName ?? this.employerName,
        employerLogoUrl: employerLogoUrl ?? this.employerLogoUrl,
        employerCity: employerCity,
        employerWebsite: employerWebsite,
        categoryId: categoryId ?? this.categoryId,
        categoryName: categoryName ?? this.categoryName,
        jobTitle: jobTitle ?? this.jobTitle,
        description: description ?? this.description,
        rawDescription: rawDescription,
        salaryMin: salaryMin ?? this.salaryMin,
        salaryMax: salaryMax ?? this.salaryMax,
        salaryCurrency: salaryCurrency ?? this.salaryCurrency,
        salaryPeriod: salaryPeriod ?? this.salaryPeriod,
        isSalaryNegotiable: isSalaryNegotiable ?? this.isSalaryNegotiable,
        location: location ?? this.location,
        city: city ?? this.city,
        country: country,
        workMode: workMode ?? this.workMode,
        jobType: jobType ?? this.jobType,
        experienceLevel: experienceLevel ?? this.experienceLevel,
        positionsAvailable: positionsAvailable ?? this.positionsAvailable,
        applicationDeadline: applicationDeadline ?? this.applicationDeadline,
        status: status ?? this.status,
        isApproved: isApproved ?? this.isApproved,
        requiredSkills: requiredSkills ?? this.requiredSkills,
        titleTokens: titleTokens,
        applicationsCount: applicationsCount ?? this.applicationsCount,
        source: source,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: DateTime.now(),
      );

  /// Lower-cased, diacritics-stripped word tokens for Firestore
  /// `array-contains` keyword search (Firestore has no ILIKE).
  ///
  /// Full words are emitted BEFORE prefixes so when the 60-token cap kicks
  /// in on a long title we never drop the company name (previously the
  /// prefixes of the first ~13 words crowded the entire company out, and
  /// `_searchTokens` taking the first 10 tokens on the read side would
  /// return 2–3-letter prefixes instead of the actual keyword).
  static List<String> tokenize(
    String title, [
    String company = '',
    String category = '',
  ]) {
    List<String> wordsOf(String text) {
      final stripped = stripDiacritics(text.toLowerCase());
      return stripped
          .split(RegExp(r'[^a-z0-9+#.]+'))
          .where((w) => w.length >= 2)
          .toList();
    }

    final titleWords = wordsOf(title);
    final companyWords = wordsOf(company);
    final categoryWords = wordsOf(category);
    final out = <String>{};
    // 1. Every full word from title + company + category (category included
    // so an English category like "Backend Developer" surfaces the role words
    // even when the job's own title is Vietnamese — fixes "IT returns 19
    // jobs" because the Vietnamese titles never produced 'developer' /
    // 'engineer' tokens the search box expands "IT" to).
    for (final w in titleWords) {
      out.add(w);
    }
    for (final w in companyWords) {
      out.add(w);
    }
    for (final w in categoryWords) {
      out.add(w);
    }
    // 2. 2..6-char prefixes (for starts-with matches as the user types).
    for (final w in [...titleWords, ...companyWords, ...categoryWords]) {
      for (var i = 2; i < w.length && i <= 6; i++) {
        out.add(w.substring(0, i));
      }
    }
    return out.take(60).toList();
  }

  static String stripDiacritics(String s) {
    const from =
        'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    const to =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
    final buf = StringBuffer();
    for (final ch in s.split('')) {
      final i = from.indexOf(ch);
      buf.write(i >= 0 ? to[i] : ch);
    }
    return buf.toString();
  }
}

DateTime? _date(Object? v) {
  if (v == null) return null;
  if (v is Timestamp) return v.toDate();
  if (v is String) return DateTime.tryParse(v);
  if (v is DateTime) return v;
  return null;
}

/// Labels from frontend/src/utils/jobMapper.js EXPERIENCE_LABELS /
/// JOB_TYPE_LABELS / WORK_MODE_LABELS (the web list/detail cards use these).
extension JobMapperLabels on ExperienceLevel {
  String get jobMapperLabel => switch (this) {
        ExperienceLevel.intern => 'Không yêu cầu',
        ExperienceLevel.fresher => 'Dưới 1 năm',
        ExperienceLevel.junior => '1 - 2 năm',
        ExperienceLevel.mid => '2 - 4 năm',
        ExperienceLevel.senior => '5 năm',
        ExperienceLevel.lead => 'Trên 5 năm',
      };
}

extension WorkModeMapperLabel on WorkMode {
  String get jobMapperLabel => switch (this) {
        WorkMode.onsite => 'Tại văn phòng',
        WorkMode.remote => 'Remote',
        WorkMode.hybrid => 'Hybrid',
      };
}
