import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/utils/enums.dart';

/// job_seeker_skill row (embedded in jobSeekerProfiles/{uid}.skills[]).
class ProfileSkill {
  const ProfileSkill({
    required this.skillName,
    this.skillId,
    this.experienceYears = 0,
    this.skillDetail,
    this.source = SkillSource.manual,
  });

  final String? skillId;
  final String skillName;
  final double experienceYears;
  final String? skillDetail;
  final SkillSource source;

  factory ProfileSkill.fromJson(Map<String, dynamic> j) => ProfileSkill(
        skillId: j['skillId'] as String?,
        skillName: (j['skillName'] ?? j['name'] ?? '') as String,
        experienceYears:
            ((j['experienceYears'] ?? j['years'] ?? 0) as num).toDouble(),
        skillDetail: j['skillDetail'] as String?,
        source: parseSkillSource(j['source'] as String?),
      );

  Map<String, dynamic> toJson() => {
        if (skillId != null) 'skillId': skillId,
        'skillName': skillName,
        'experienceYears': experienceYears,
        if (skillDetail != null) 'skillDetail': skillDetail,
        'source': enumToWire(source),
      };
}

/// work_experience row (embedded).
class WorkExperience {
  const WorkExperience({
    required this.companyName,
    required this.position,
    this.experienceId,
    this.startDate,
    this.endDate,
    this.description,
  });

  final String? experienceId;
  final String companyName;
  final String position;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? description;

  bool get isCurrent => endDate == null;

  factory WorkExperience.fromJson(Map<String, dynamic> j) => WorkExperience(
        experienceId: j['experienceId'] as String?,
        companyName: (j['companyName'] ?? j['company'] ?? '') as String,
        position: (j['position'] ?? '') as String,
        startDate: _date(j['startDate']),
        endDate: _date(j['endDate']),
        description: j['description'] as String?,
      );

  Map<String, dynamic> toJson() => {
        if (experienceId != null) 'experienceId': experienceId,
        'companyName': companyName,
        'position': position,
        if (startDate != null) 'startDate': Timestamp.fromDate(startDate!),
        if (endDate != null) 'endDate': Timestamp.fromDate(endDate!),
        if (description != null) 'description': description,
      };
}

/// education row (embedded).
class Education {
  const Education({
    required this.schoolName,
    this.educationId,
    this.degree,
    this.major,
    this.startYear,
    this.endYear,
  });

  final String? educationId;
  final String schoolName;
  final String? degree;
  final String? major;
  final int? startYear;
  final int? endYear;

  factory Education.fromJson(Map<String, dynamic> j) => Education(
        educationId: j['educationId'] as String?,
        schoolName: (j['schoolName'] ?? j['school'] ?? '') as String,
        degree: j['degree'] as String?,
        major: j['major'] as String?,
        startYear: (j['startYear'] as num?)?.toInt(),
        endYear: (j['endYear'] as num?)?.toInt(),
      );

  Map<String, dynamic> toJson() => {
        if (educationId != null) 'educationId': educationId,
        'schoolName': schoolName,
        if (degree != null) 'degree': degree,
        if (major != null) 'major': major,
        if (startYear != null) 'startYear': startYear,
        if (endYear != null) 'endYear': endYear,
      };
}

/// jobSeekerProfiles/{uid} — mirrors table job_seeker plus the three
/// one-to-many tables embedded as bounded arrays.
class JobSeekerProfile {
  const JobSeekerProfile({
    required this.uid,
    this.fullName,
    this.email,
    this.phone,
    this.address,
    this.city,
    this.headline,
    this.profileSummary,
    this.isVerified = false,
    this.isOpenToWork = true,
    this.isActive = true,
    this.skills = const [],
    this.workExperiences = const [],
    this.educations = const [],
    this.primaryResumeId,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String? fullName;
  final String? email;
  final String? phone;
  final String? address;
  final String? city;
  final String? headline;
  final String? profileSummary;
  final bool isVerified;
  final bool isOpenToWork;
  final bool isActive;
  final List<ProfileSkill> skills;
  final List<WorkExperience> workExperiences;
  final List<Education> educations;
  final String? primaryResumeId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// ApplicationService.applyJob precondition: full_name, headline, city.
  List<String> get missingRequiredFields => [
        if ((fullName ?? '').trim().isEmpty) 'họ tên',
        if ((headline ?? '').trim().isEmpty) 'chức danh',
        if ((city ?? '').trim().isEmpty) 'thành phố',
      ];

  bool get isComplete => missingRequiredFields.isEmpty;

  factory JobSeekerProfile.fromJson(Map<String, dynamic> j) => JobSeekerProfile(
        uid: (j['uid'] ?? j['id'] ?? '') as String,
        fullName: j['fullName'] as String?,
        email: j['email'] as String?,
        phone: j['phone'] as String?,
        address: j['address'] as String?,
        city: j['city'] as String?,
        headline: j['headline'] as String?,
        profileSummary: (j['profileSummary'] ?? j['summary']) as String?,
        isVerified: (j['isVerified'] ?? false) as bool,
        isOpenToWork: (j['isOpenToWork'] ?? true) as bool,
        isActive: (j['isActive'] ?? true) as bool,
        skills: _list(j['skills'], ProfileSkill.fromJson),
        workExperiences:
            _list(j['workExperiences'] ?? j['experiences'], WorkExperience.fromJson),
        educations: _list(j['educations'], Education.fromJson),
        primaryResumeId: j['primaryResumeId'] as String?,
        createdAt: (j['createdAt'] as Timestamp?)?.toDate(),
        updatedAt: (j['updatedAt'] as Timestamp?)?.toDate(),
      );

  Map<String, dynamic> toJson() => {
        'uid': uid,
        if (fullName != null) 'fullName': fullName,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address,
        if (city != null) 'city': city,
        if (headline != null) 'headline': headline,
        if (profileSummary != null) 'profileSummary': profileSummary,
        'isVerified': isVerified,
        'isOpenToWork': isOpenToWork,
        'isActive': isActive,
        'skills': skills.map((e) => e.toJson()).toList(),
        'workExperiences': workExperiences.map((e) => e.toJson()).toList(),
        'educations': educations.map((e) => e.toJson()).toList(),
        if (primaryResumeId != null) 'primaryResumeId': primaryResumeId,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  JobSeekerProfile copyWith({
    String? fullName,
    String? phone,
    String? address,
    String? city,
    String? headline,
    String? profileSummary,
    bool? isOpenToWork,
    List<ProfileSkill>? skills,
    List<WorkExperience>? workExperiences,
    List<Education>? educations,
    String? primaryResumeId,
  }) =>
      JobSeekerProfile(
        uid: uid,
        fullName: fullName ?? this.fullName,
        email: email,
        phone: phone ?? this.phone,
        address: address ?? this.address,
        city: city ?? this.city,
        headline: headline ?? this.headline,
        profileSummary: profileSummary ?? this.profileSummary,
        isVerified: isVerified,
        isOpenToWork: isOpenToWork ?? this.isOpenToWork,
        isActive: isActive,
        skills: skills ?? this.skills,
        workExperiences: workExperiences ?? this.workExperiences,
        educations: educations ?? this.educations,
        primaryResumeId: primaryResumeId ?? this.primaryResumeId,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}

DateTime? _date(Object? v) {
  if (v == null) return null;
  if (v is Timestamp) return v.toDate();
  if (v is String) return DateTime.tryParse(v);
  return null;
}

List<T> _list<T>(Object? raw, T Function(Map<String, dynamic>) f) =>
    (raw as List?)
        ?.whereType<Map>()
        .map((m) => f(m.cast<String, dynamic>()))
        .toList() ??
    const [];
