import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/utils/enums.dart';

/// application_status_history row — subcollection
/// applications/{id}/statusHistory/{historyId}.
class ApplicationStatusHistoryItem {
  const ApplicationStatusHistoryItem({
    required this.newStatus,
    required this.changedAt,
    this.historyId,
    this.applicationId,
    this.oldStatus,
    this.changedBy,
    this.changedByRole = UserRole.jobSeeker,
    this.note,
  });

  final String? historyId;
  final String? applicationId;
  final ApplicationStatus? oldStatus;
  final ApplicationStatus newStatus;
  final String? changedBy;
  final UserRole changedByRole;
  final DateTime changedAt;
  final String? note;

  String get actorLabel => switch (changedByRole) {
        UserRole.jobSeeker => 'Ứng viên',
        UserRole.employer => 'Nhà tuyển dụng',
        UserRole.admin => 'Quản trị viên',
      };

  factory ApplicationStatusHistoryItem.fromJson(Map<String, dynamic> j) =>
      ApplicationStatusHistoryItem(
        historyId: (j['historyId'] ?? j['id']) as String?,
        applicationId: j['applicationId'] as String?,
        oldStatus: j['oldStatus'] == null
            ? null
            : parseAppStatus(j['oldStatus'] as String?),
        newStatus: parseAppStatus((j['newStatus'] ?? j['status']) as String?),
        changedBy: j['changedBy'] as String?,
        changedByRole: parseUserRole(j['changedByRole'] as String?),
        changedAt: (j['changedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        note: j['note'] as String?,
      );

  Map<String, dynamic> toJson() => {
        if (historyId != null) 'historyId': historyId,
        if (applicationId != null) 'applicationId': applicationId,
        if (oldStatus != null) 'oldStatus': enumToWire(oldStatus!),
        'newStatus': enumToWire(newStatus),
        if (changedBy != null) 'changedBy': changedBy,
        'changedByRole': userRoleToWire(changedByRole),
        'changedAt': Timestamp.fromDate(changedAt),
        if (note != null) 'note': note,
      };
}

/// applications/{applicationId} (docId = `${jobSeekerId}_${jobId}` so the
/// UNIQUE(job_seeker_id, job_id) constraint is enforced by the id).
class ApplicationModel {
  const ApplicationModel({
    required this.applicationId,
    required this.jobId,
    required this.jobSeekerId,
    required this.employerId,
    this.resumeId,
    this.resumeFileName,
    this.resumeUrl,
    this.coverLetter,
    this.applicationDate,
    this.status = ApplicationStatus.submitted,
    this.updatedAt,
    this.jobTitle = '',
    this.companyName = '',
    this.candidateFullName = '',
    this.candidateHeadline,
    this.candidateCity,
    this.candidateEmail,
    this.matchScore,
    this.recommendationReason,
    this.statusHistory = const [],
  });

  final String applicationId;
  final String jobId;
  final String jobSeekerId;
  final String employerId;
  final String? resumeId;
  final String? resumeFileName;
  final String? resumeUrl;
  final String? coverLetter;
  final DateTime? applicationDate;
  final ApplicationStatus status;
  final DateTime? updatedAt;

  // denormalised summary fields (list screens must not need joins)
  final String jobTitle;
  final String companyName;
  final String candidateFullName;
  final String? candidateHeadline;
  final String? candidateCity;
  final String? candidateEmail;
  final double? matchScore;
  final String? recommendationReason;

  /// Loaded separately from the statusHistory subcollection.
  final List<ApplicationStatusHistoryItem> statusHistory;

  static String docIdFor(String jobSeekerId, String jobId) => '${jobSeekerId}_$jobId';

  /// ApplicationService.TRANSITIONS — only 4 statuses are exposed.
  static const Map<ApplicationStatus, List<ApplicationStatus>> transitions = {
    ApplicationStatus.submitted: [
      ApplicationStatus.underReview,
      ApplicationStatus.accepted,
      ApplicationStatus.rejected,
    ],
    ApplicationStatus.underReview: [
      ApplicationStatus.accepted,
      ApplicationStatus.rejected,
    ],
    ApplicationStatus.accepted: [],
    ApplicationStatus.rejected: [],
  };

  List<ApplicationStatus> get allowedTransitions =>
      transitions[status] ?? const [];

  bool get isTerminal => allowedTransitions.isEmpty;

  /// Web StatusHistoryTimeline prepends a synthetic SUBMITTED node built from
  /// application_date when history has no genesis row.
  List<ApplicationStatusHistoryItem> get timeline {
    final hasGenesis = statusHistory.any((h) => h.oldStatus == null);
    final items = [...statusHistory]..sort((a, b) => a.changedAt.compareTo(b.changedAt));
    if (hasGenesis || applicationDate == null) return items;
    return [
      ApplicationStatusHistoryItem(
        newStatus: ApplicationStatus.submitted,
        changedAt: applicationDate!,
        changedBy: jobSeekerId,
        changedByRole: UserRole.jobSeeker,
      ),
      ...items,
    ];
  }

  factory ApplicationModel.fromJson(Map<String, dynamic> j) => ApplicationModel(
        applicationId: (j['applicationId'] ?? j['id'] ?? '') as String,
        jobId: (j['jobId'] ?? '') as String,
        jobSeekerId: (j['jobSeekerId'] ?? j['jobSeekerUid'] ?? '') as String,
        employerId: (j['employerId'] ?? j['employerUid'] ?? '') as String,
        resumeId: j['resumeId'] as String?,
        resumeFileName: j['resumeFileName'] as String?,
        resumeUrl: j['resumeUrl'] as String?,
        coverLetter: j['coverLetter'] as String?,
        applicationDate:
            ((j['applicationDate'] ?? j['appliedAt']) as Timestamp?)?.toDate(),
        status: parseAppStatus(j['status'] as String?),
        updatedAt: (j['updatedAt'] as Timestamp?)?.toDate(),
        jobTitle: (j['jobTitle'] ?? '') as String,
        companyName: (j['companyName'] ?? '') as String,
        candidateFullName:
            (j['candidateFullName'] ?? j['jobSeekerName'] ?? '') as String,
        candidateHeadline: j['candidateHeadline'] as String?,
        candidateCity: j['candidateCity'] as String?,
        candidateEmail: j['candidateEmail'] as String?,
        matchScore: (j['matchScore'] as num?)?.toDouble(),
        recommendationReason: j['recommendationReason'] as String?,
        statusHistory: (j['statusHistory'] as List?)
                ?.whereType<Map>()
                .map((m) => ApplicationStatusHistoryItem.fromJson(
                    m.cast<String, dynamic>()))
                .toList() ??
            const [],
      );

  Map<String, dynamic> toJson() => {
        'applicationId': applicationId,
        'jobId': jobId,
        'jobSeekerId': jobSeekerId,
        'employerId': employerId,
        if (resumeId != null) 'resumeId': resumeId,
        if (resumeFileName != null) 'resumeFileName': resumeFileName,
        if (resumeUrl != null) 'resumeUrl': resumeUrl,
        if (coverLetter != null) 'coverLetter': coverLetter,
        'applicationDate': applicationDate != null
            ? Timestamp.fromDate(applicationDate!)
            : FieldValue.serverTimestamp(),
        'status': enumToWire(status),
        'updatedAt': FieldValue.serverTimestamp(),
        'jobTitle': jobTitle,
        'companyName': companyName,
        'candidateFullName': candidateFullName,
        if (candidateHeadline != null) 'candidateHeadline': candidateHeadline,
        if (candidateCity != null) 'candidateCity': candidateCity,
        if (candidateEmail != null) 'candidateEmail': candidateEmail,
        if (matchScore != null) 'matchScore': matchScore,
        if (recommendationReason != null)
          'recommendationReason': recommendationReason,
      };

  ApplicationModel copyWith({
    ApplicationStatus? status,
    List<ApplicationStatusHistoryItem>? statusHistory,
    double? matchScore,
    String? recommendationReason,
  }) =>
      ApplicationModel(
        applicationId: applicationId,
        jobId: jobId,
        jobSeekerId: jobSeekerId,
        employerId: employerId,
        resumeId: resumeId,
        resumeFileName: resumeFileName,
        resumeUrl: resumeUrl,
        coverLetter: coverLetter,
        applicationDate: applicationDate,
        status: status ?? this.status,
        updatedAt: DateTime.now(),
        jobTitle: jobTitle,
        companyName: companyName,
        candidateFullName: candidateFullName,
        candidateHeadline: candidateHeadline,
        candidateCity: candidateCity,
        candidateEmail: candidateEmail,
        matchScore: matchScore ?? this.matchScore,
        recommendationReason: recommendationReason ?? this.recommendationReason,
        statusHistory: statusHistory ?? this.statusHistory,
      );
}
