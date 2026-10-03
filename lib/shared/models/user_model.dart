import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/utils/enums.dart';

/// Account record keyed by Firebase Auth uid. Mirrors the union of
/// job_seeker / employer / admin account columns + GET /auth/me payload.
class UserModel {
  const UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.role,
    this.phone,
    this.photoUrl,
    this.headline,
    this.city,
    this.website,
    this.isActive = true,
    this.isVerified = false,
    this.fcmTokens = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String email;
  final String fullName;
  final UserRole role;
  final String? phone;
  final String? photoUrl;
  final String? headline;
  final String? city;
  final String? website;
  final bool isActive;
  final bool isVerified;
  final List<String> fcmTokens;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isEmployer => role == UserRole.employer;
  bool get isJobSeeker => role == UserRole.jobSeeker;
  bool get isAdmin => role == UserRole.admin;
  bool get isBlocked => !isActive;

  String get roleLabel => switch (role) {
        UserRole.jobSeeker => 'Ứng viên',
        UserRole.employer => 'NTD',
        UserRole.admin => 'Admin',
      };

  String get initial =>
      fullName.trim().isEmpty ? 'U' : fullName.trim()[0].toUpperCase();

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        uid: (j['uid'] ?? j['id'] ?? '') as String,
        email: (j['email'] ?? '') as String,
        fullName: (j['fullName'] ?? j['name'] ?? '') as String,
        role: parseUserRole(j['role'] as String?),
        phone: j['phone'] as String?,
        photoUrl: j['photoUrl'] as String?,
        headline: j['headline'] as String?,
        city: j['city'] as String?,
        website: j['website'] as String?,
        isActive: (j['isActive'] ?? true) as bool,
        isVerified: (j['isVerified'] ?? false) as bool,
        fcmTokens: ((j['fcmTokens'] as List?)?.cast<String>()) ?? const [],
        createdAt: (j['createdAt'] as Timestamp?)?.toDate(),
        updatedAt: (j['updatedAt'] as Timestamp?)?.toDate(),
      );

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'fullName': fullName,
        'role': userRoleToWire(role),
        if (phone != null) 'phone': phone,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (headline != null) 'headline': headline,
        if (city != null) 'city': city,
        if (website != null) 'website': website,
        'isActive': isActive,
        'isVerified': isVerified,
        'fcmTokens': fcmTokens,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  UserModel copyWith({
    String? fullName,
    String? phone,
    String? photoUrl,
    String? headline,
    String? city,
    String? website,
    bool? isActive,
    bool? isVerified,
  }) =>
      UserModel(
        uid: uid,
        email: email,
        fullName: fullName ?? this.fullName,
        role: role,
        phone: phone ?? this.phone,
        photoUrl: photoUrl ?? this.photoUrl,
        headline: headline ?? this.headline,
        city: city ?? this.city,
        website: website ?? this.website,
        isActive: isActive ?? this.isActive,
        isVerified: isVerified ?? this.isVerified,
        fcmTokens: fcmTokens,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}
