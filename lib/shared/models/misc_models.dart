import 'package:cloud_firestore/cloud_firestore.dart';

/// savedJobs/{jobSeekerId_jobId} — table saved_job + snapshot for list render.
class SavedJob {
  const SavedJob({
    required this.jobSeekerId,
    required this.jobId,
    this.savedAt,
    this.jobSnapshot = const {},
  });

  final String jobSeekerId;
  final String jobId;
  final DateTime? savedAt;
  final Map<String, dynamic> jobSnapshot;

  static String docIdFor(String jobSeekerId, String jobId) => '${jobSeekerId}_$jobId';

  factory SavedJob.fromJson(Map<String, dynamic> j) => SavedJob(
        jobSeekerId: (j['jobSeekerId'] ?? '') as String,
        jobId: (j['jobId'] ?? '') as String,
        savedAt: (j['savedAt'] as Timestamp?)?.toDate(),
        jobSnapshot: ((j['jobSnapshot'] as Map?)?.cast<String, dynamic>()) ?? const {},
      );

  Map<String, dynamic> toJson() => {
        'jobSeekerId': jobSeekerId,
        'jobId': jobId,
        'savedAt': savedAt != null
            ? Timestamp.fromDate(savedAt!)
            : FieldValue.serverTimestamp(),
        'jobSnapshot': jobSnapshot,
      };
}

/// chats/{chatId} — FLUTTER_REBUILD_PLAN §4.
class ChatThread {
  const ChatThread({
    required this.chatId,
    required this.participants,
    this.participantNames = const {},
    this.lastMessage,
    this.lastSenderId,
    this.unreadCounts = const {},
    this.jobId,
    this.jobTitle,
    this.updatedAt,
  });

  final String chatId;
  final List<String> participants;
  final Map<String, String> participantNames;
  final String? lastMessage;
  final String? lastSenderId;
  final Map<String, int> unreadCounts;
  final String? jobId;
  final String? jobTitle;
  final DateTime? updatedAt;

  static String docIdFor(String a, String b) {
    final ids = [a, b]..sort();
    return ids.join('_');
  }

  String otherParticipant(String me) =>
      participants.firstWhere((p) => p != me, orElse: () => me);

  String otherName(String me) => participantNames[otherParticipant(me)] ?? 'Người dùng';

  factory ChatThread.fromJson(Map<String, dynamic> j) => ChatThread(
        chatId: (j['chatId'] ?? j['id'] ?? '') as String,
        participants: ((j['participants'] as List?)?.cast<String>()) ?? const [],
        participantNames:
            ((j['participantNames'] as Map?)?.cast<String, String>()) ?? const {},
        lastMessage: j['lastMessage'] as String?,
        lastSenderId: j['lastSenderId'] as String?,
        unreadCounts: ((j['unreadCounts'] as Map?)
                ?.map((k, v) => MapEntry(k.toString(), (v as num).toInt()))) ??
            const {},
        jobId: j['jobId'] as String?,
        jobTitle: j['jobTitle'] as String?,
        updatedAt: (j['updatedAt'] as Timestamp?)?.toDate(),
      );

  Map<String, dynamic> toJson() => {
        'chatId': chatId,
        'participants': participants,
        'participantNames': participantNames,
        if (lastMessage != null) 'lastMessage': lastMessage,
        if (lastSenderId != null) 'lastSenderId': lastSenderId,
        'unreadCounts': unreadCounts,
        if (jobId != null) 'jobId': jobId,
        if (jobTitle != null) 'jobTitle': jobTitle,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}

/// chats/{chatId}/messages/{msgId}
class ChatMessage {
  const ChatMessage({
    required this.messageId,
    required this.senderId,
    required this.content,
    this.imageUrl,
    this.createdAt,
  });

  final String messageId;
  final String senderId;
  final String content;
  final String? imageUrl;
  final DateTime? createdAt;

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        messageId: (j['messageId'] ?? j['id'] ?? '') as String,
        senderId: (j['senderId'] ?? '') as String,
        content: (j['content'] ?? '') as String,
        imageUrl: j['imageUrl'] as String?,
        createdAt: (j['createdAt'] as Timestamp?)?.toDate(),
      );

  Map<String, dynamic> toJson() => {
        'messageId': messageId,
        'senderId': senderId,
        'content': content,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };
}
