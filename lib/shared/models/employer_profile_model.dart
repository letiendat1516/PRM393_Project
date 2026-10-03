import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/utils/enums.dart';

/// employerProfiles/{uid} — mirrors table employer.
class EmployerProfile {
  const EmployerProfile({
    required this.uid,
    required this.companyName,
    this.email,
    this.phone,
    this.website,
    this.companyDescription,
    this.city,
    this.contactName,
    this.gender,
    this.logoUrl,
    this.industry,
    this.companySize,
    this.isVerified = false,
    this.isActive = true,
    this.openPositions = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String companyName;
  final String? email;
  final String? phone;
  final String? website;
  final String? companyDescription;
  final String? city;
  final String? contactName;
  final Gender? gender;
  final String? logoUrl;
  final String? industry;
  final String? companySize;
  final bool isVerified;
  final bool isActive;
  final int openPositions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get verificationLabel => isVerified ? 'Đã xác thực' : 'Chờ xác thực';

  factory EmployerProfile.fromJson(Map<String, dynamic> j) => EmployerProfile(
        uid: (j['uid'] ?? j['id'] ?? '') as String,
        companyName: (j['companyName'] ?? '') as String,
        email: j['email'] as String?,
        phone: j['phone'] as String?,
        website: j['website'] as String?,
        companyDescription:
            (j['companyDescription'] ?? j['description']) as String?,
        city: j['city'] as String?,
        contactName: j['contactName'] as String?,
        gender: parseGender(j['gender'] as String?),
        logoUrl: j['logoUrl'] as String?,
        industry: j['industry'] as String?,
        companySize: j['companySize'] as String?,
        isVerified: (j['isVerified'] ?? false) as bool,
        isActive: (j['isActive'] ?? true) as bool,
        openPositions: ((j['openPositions'] ?? 0) as num).toInt(),
        createdAt: (j['createdAt'] as Timestamp?)?.toDate(),
        updatedAt: (j['updatedAt'] as Timestamp?)?.toDate(),
      );

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'companyName': companyName,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (website != null) 'website': website,
        if (companyDescription != null) 'companyDescription': companyDescription,
        if (city != null) 'city': city,
        if (contactName != null) 'contactName': contactName,
        if (gender != null) 'gender': gender!.name,
        if (logoUrl != null) 'logoUrl': logoUrl,
        if (industry != null) 'industry': industry,
        if (companySize != null) 'companySize': companySize,
        'isVerified': isVerified,
        'isActive': isActive,
        'openPositions': openPositions,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  EmployerProfile copyWith({
    String? companyName,
    String? phone,
    String? website,
    String? companyDescription,
    String? city,
    String? contactName,
    Gender? gender,
    String? logoUrl,
    String? industry,
    String? companySize,
    bool? isVerified,
    bool? isActive,
  }) =>
      EmployerProfile(
        uid: uid,
        companyName: companyName ?? this.companyName,
        email: email,
        phone: phone ?? this.phone,
        website: website ?? this.website,
        companyDescription: companyDescription ?? this.companyDescription,
        city: city ?? this.city,
        contactName: contactName ?? this.contactName,
        gender: gender ?? this.gender,
        logoUrl: logoUrl ?? this.logoUrl,
        industry: industry ?? this.industry,
        companySize: companySize ?? this.companySize,
        isVerified: isVerified ?? this.isVerified,
        isActive: isActive ?? this.isActive,
        openPositions: openPositions,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}
