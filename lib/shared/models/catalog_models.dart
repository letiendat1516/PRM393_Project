import 'package:cloud_firestore/cloud_firestore.dart';

/// categories/{categoryId} — table category.
class CategoryModel {
  const CategoryModel({required this.categoryId, required this.name, this.jobCount = 0});
  final String categoryId;
  final String name;
  final int jobCount;

  factory CategoryModel.fromJson(Map<String, dynamic> j) => CategoryModel(
        categoryId: (j['categoryId'] ?? j['id'] ?? '') as String,
        name: (j['name'] ?? '') as String,
        jobCount: ((j['jobCount'] ?? 0) as num).toInt(),
      );

  Map<String, dynamic> toJson() => {
        'categoryId': categoryId,
        'name': name,
        'nameLower': name.toLowerCase(),
        'jobCount': jobCount,
      };
}

/// skills/{skillId} — table skill.
class SkillModel {
  const SkillModel({
    required this.skillId,
    required this.skillName,
    this.createdAt,
    this.updatedAt,
  });
  final String skillId;
  final String skillName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory SkillModel.fromJson(Map<String, dynamic> j) => SkillModel(
        skillId: (j['skillId'] ?? j['id'] ?? '') as String,
        skillName: (j['skillName'] ?? j['name'] ?? '') as String,
        createdAt: (j['createdAt'] as Timestamp?)?.toDate(),
        updatedAt: (j['updatedAt'] as Timestamp?)?.toDate(),
      );

  Map<String, dynamic> toJson() => {
        'skillId': skillId,
        'skillName': skillName,
        'skillNameLower': skillName.toLowerCase(),
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
}

/// systemConfigurations/{configKey} — table system_configurations (used by the
/// backend but missing from the SQL docs; shape taken from the repository).
class SystemConfig {
  const SystemConfig({
    required this.configKey,
    required this.configValue,
    this.valueType = 'STRING',
    this.description,
    this.updatedAt,
    this.updatedBy,
  });

  final String configKey;
  final String configValue;
  final String valueType; // NUMBER | BOOLEAN | STRING
  final String? description;
  final DateTime? updatedAt;
  final String? updatedBy;

  static const keyMaxSkillsPerJob = 'MAX_SKILLS_PER_JOB';
  static const keyDefaultDeadlineDays = 'DEFAULT_DEADLINE_DAYS';
  static const keyRequireJobApproval = 'REQUIRE_JOB_APPROVAL';
  static const keyGeminiApiKey = 'GEMINI_API_KEY';

  Object get parsedValue => switch (valueType) {
        'NUMBER' => num.tryParse(configValue) ?? 0,
        'BOOLEAN' => configValue.toLowerCase() == 'true',
        _ => configValue,
      };

  num get asNumber => parsedValue is num ? parsedValue as num : 0;
  /// Backend accepts 'true' as a STRING too (systemConfigurationService) —
  /// read the raw value so REQUIRE_JOB_APPROVAL never silently flips to false.
  bool get asBool => configValue.trim().toLowerCase() == 'true';

  factory SystemConfig.fromJson(Map<String, dynamic> j) => SystemConfig(
        configKey: (j['configKey'] ?? j['id'] ?? '') as String,
        configValue: (j['configValue'] ?? j['value'] ?? '').toString(),
        valueType: (j['valueType'] ?? 'STRING') as String,
        description: j['description'] as String?,
        updatedAt: (j['updatedAt'] as Timestamp?)?.toDate(),
        updatedBy: j['updatedBy'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'configKey': configKey,
        'configValue': configValue,
        'valueType': valueType,
        if (description != null) 'description': description,
        'updatedAt': FieldValue.serverTimestamp(),
        if (updatedBy != null) 'updatedBy': updatedBy,
      };
}
