import 'package:cloud_firestore/cloud_firestore.dart';

/// ai_analysis row — latest copy embedded in resumes/{id}.aiAnalysis and the
/// full history kept in resumes/{id}/aiAnalyses/{analysisId}.
class AiAnalysis {
  const AiAnalysis({
    this.analysisId,
    this.resumeId,
    this.summary,
    this.skills = const [],
    this.softSkills = const [],
    this.languages = const [],
    this.certifications = const [],
    this.workExperience = const [],
    this.totalExperienceYears,
    this.educationLevel,
    this.rawText,
    this.modelVersion,
    this.analyzedAt,
  });

  final String? analysisId;
  final String? resumeId;
  final String? summary;
  final List<String> skills;
  final List<String> softSkills;
  final List<String> languages;
  final List<String> certifications;
  final List<Map<String, dynamic>> workExperience;
  final double? totalExperienceYears;
  final String? educationLevel; // High School | Bachelor | Master | PhD | Other
  final String? rawText;
  final String? modelVersion;
  final DateTime? analyzedAt;

  /// Shape sent to the matching prompt / rule-based scorer (CV payload).
  Map<String, dynamic> toCvPayload() => {
        'skills': skills,
        'soft_skills': softSkills,
        'experience_years': totalExperienceYears ?? 0,
        'education_level': educationLevel ?? '',
        'languages': languages,
        'certifications': certifications,
        'work_experience': workExperience,
        'summary': summary ?? '',
      };

  factory AiAnalysis.fromJson(Map<String, dynamic> j) {
    final ex = (j['extractedSkills'] as Map?)?.cast<String, dynamic>() ?? j;
    List<String> strs(Object? v) =>
        (v as List?)?.map((e) => e.toString()).toList() ?? const [];
    return AiAnalysis(
      analysisId: (j['analysisId'] ?? j['id']) as String?,
      resumeId: j['resumeId'] as String?,
      summary: j['summary'] as String?,
      skills: strs(ex['skills']),
      softSkills: strs(ex['softSkills'] ?? ex['soft_skills']),
      languages: strs(ex['languages']),
      certifications: strs(ex['certifications']),
      workExperience: ((ex['workExperience'] ?? ex['work_experience']) as List?)
              ?.whereType<Map>()
              .map((m) => m.cast<String, dynamic>())
              .toList() ??
          const [],
      totalExperienceYears:
          ((j['totalExperienceYears'] ?? j['total_experience_years']) as num?)
              ?.toDouble(),
      educationLevel: (j['educationLevel'] ?? j['education_level']) as String?,
      rawText: j['rawText'] as String?,
      modelVersion: j['modelVersion'] as String?,
      analyzedAt: (j['analyzedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (analysisId != null) 'analysisId': analysisId,
        if (resumeId != null) 'resumeId': resumeId,
        if (summary != null) 'summary': summary,
        'extractedSkills': {
          'skills': skills,
          'softSkills': softSkills,
          'languages': languages,
          'certifications': certifications,
          'workExperience': workExperience,
        },
        if (totalExperienceYears != null)
          'totalExperienceYears': totalExperienceYears,
        if (educationLevel != null) 'educationLevel': educationLevel,
        if (rawText != null) 'rawText': rawText,
        if (modelVersion != null) 'modelVersion': modelVersion,
        'analyzedAt': analyzedAt != null
            ? Timestamp.fromDate(analyzedAt!)
            : FieldValue.serverTimestamp(),
      };
}

/// resumes/{resumeId} — mirrors table resume.
class ResumeModel {
  const ResumeModel({
    required this.resumeId,
    required this.jobSeekerId,
    required this.title,
    required this.fileName,
    this.filePath = '',
    this.downloadUrl,
    this.rawText,
    this.isPrimary = false,
    this.uploadDate,
    this.aiAnalysis,
  });

  final String resumeId;
  final String jobSeekerId;
  final String title;
  final String fileName;
  final String filePath;
  final String? downloadUrl;
  /// Plain text content when the CV was pasted/uploaded as text (no Storage).
  final String? rawText;
  final bool isPrimary;
  final DateTime? uploadDate;
  final AiAnalysis? aiAnalysis;

  bool get hasAnalysis => aiAnalysis != null;

  factory ResumeModel.fromJson(Map<String, dynamic> j) => ResumeModel(
        resumeId: (j['resumeId'] ?? j['id'] ?? '') as String,
        jobSeekerId: (j['jobSeekerId'] ?? j['ownerUid'] ?? '') as String,
        title: (j['title'] ?? '') as String,
        fileName: (j['fileName'] ?? '') as String,
        filePath: (j['filePath'] ?? j['storagePath'] ?? '') as String,
        downloadUrl: j['downloadUrl'] as String?,
        rawText: j['rawText'] as String?,
        isPrimary: (j['isPrimary'] ?? false) as bool,
        uploadDate: ((j['uploadDate'] ?? j['uploadedAt']) as Timestamp?)?.toDate(),
        aiAnalysis: j['aiAnalysis'] is Map
            ? AiAnalysis.fromJson((j['aiAnalysis'] as Map).cast<String, dynamic>())
            : null,
      );

  Map<String, dynamic> toJson() => {
        'resumeId': resumeId,
        'jobSeekerId': jobSeekerId,
        'title': title,
        'fileName': fileName,
        'filePath': filePath,
        if (downloadUrl != null) 'downloadUrl': downloadUrl,
        if (rawText != null) 'rawText': rawText,
        'isPrimary': isPrimary,
        'uploadDate': uploadDate != null
            ? Timestamp.fromDate(uploadDate!)
            : FieldValue.serverTimestamp(),
        if (aiAnalysis != null) 'aiAnalysis': aiAnalysis!.toJson(),
      };

  ResumeModel copyWith({
    bool? isPrimary,
    AiAnalysis? aiAnalysis,
    String? title,
    String? rawText,
    String? downloadUrl,
  }) =>
      ResumeModel(
        resumeId: resumeId,
        jobSeekerId: jobSeekerId,
        title: title ?? this.title,
        fileName: fileName,
        filePath: filePath,
        downloadUrl: downloadUrl ?? this.downloadUrl,
        rawText: rawText ?? this.rawText,
        isPrimary: isPrimary ?? this.isPrimary,
        uploadDate: uploadDate,
        aiAnalysis: aiAnalysis ?? this.aiAnalysis,
      );
}
