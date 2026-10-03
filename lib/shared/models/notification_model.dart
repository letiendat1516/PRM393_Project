import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/utils/enums.dart';

/// notifications/{notificationId} — mirrors table notification with the
/// (job_seeker_id | employer_id) pair flattened into recipientId/recipientType.
class NotificationModel {
  const NotificationModel({
    required this.notificationId,
    required this.recipientId,
    required this.type,
    required this.title,
    required this.message,
    this.recipientRole = UserRole.jobSeeker,
    this.data = const {},
    this.isRead = false,
    this.createdAt,
  });

  final String notificationId;
  final String recipientId;
  final UserRole recipientRole;
  final NotificationType type;
  final String title;
  final String message;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime? createdAt;

  factory NotificationModel.fromJson(Map<String, dynamic> j) => NotificationModel(
        notificationId: (j['notificationId'] ?? j['id'] ?? '') as String,
        recipientId: (j['recipientId'] ?? j['recipientUid'] ?? '') as String,
        recipientRole: parseUserRole(j['recipientRole'] as String?),
        type: parseNotifType(j['type'] as String?),
        title: (j['title'] ?? '') as String,
        message: (j['message'] ?? '') as String,
        data: ((j['data'] as Map?)?.cast<String, dynamic>()) ?? const {},
        isRead: (j['isRead'] ?? false) as bool,
        createdAt: (j['createdAt'] as Timestamp?)?.toDate(),
      );

  Map<String, dynamic> toJson() => {
        'notificationId': notificationId,
        'recipientId': recipientId,
        'recipientRole': userRoleToWire(recipientRole),
        'type': enumToWire(type),
        'title': title,
        'message': message,
        'data': data,
        'isRead': isRead,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };
}
