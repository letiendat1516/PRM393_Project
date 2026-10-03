import 'package:cloud_firestore/cloud_firestore.dart';

import '../../shared/models/application_model.dart';
import '../../shared/models/catalog_models.dart';
import '../../shared/models/employer_profile_model.dart';
import '../../shared/models/job_model.dart';
import '../../shared/models/jobseeker_profile_model.dart';
import '../../shared/models/misc_models.dart';
import '../../shared/models/notification_model.dart';
import '../../shared/models/recommendation_models.dart';
import '../../shared/models/resume_model.dart';
import '../../shared/models/user_model.dart';

typedef JsonMap = Map<String, dynamic>;

/// Typed collection references — one per table of docs/full_database_schema.sql
/// (plus the mobile-only chats). Collection names are the single source of
/// truth for firestore.rules / firestore.indexes.json.
class FirestoreRefs {
  FirestoreRefs(this.db);
  final FirebaseFirestore db;

  static const colUsers = 'users';
  static const colJobSeekerProfiles = 'jobSeekerProfiles';
  static const colEmployerProfiles = 'employerProfiles';
  static const colCategories = 'categories';
  static const colSkills = 'skills';
  static const colJobs = 'jobs';
  static const colApplications = 'applications';
  static const subStatusHistory = 'statusHistory';
  static const colResumes = 'resumes';
  static const subAiAnalyses = 'aiAnalyses';
  static const colJobRecommendations = 'jobRecommendations';
  static const colSavedJobs = 'savedJobs';
  static const colNotifications = 'notifications';
  static const colAiMatchingLogs = 'aiMatchingLogs';
  static const colSystemConfigurations = 'systemConfigurations';
  static const colChats = 'chats';
  static const subMessages = 'messages';
  static const subAiSessions = 'aiSessions';

  CollectionReference<T> _col<T>(
    String path,
    T Function(JsonMap) fromJson,
    JsonMap Function(T) toJson,
  ) =>
      db.collection(path).withConverter<T>(
            fromFirestore: (s, _) => fromJson(_withId(s)),
            toFirestore: (m, _) => toJson(m),
          );

  CollectionReference<UserModel> users() =>
      _col(colUsers, UserModel.fromJson, (m) => m.toJson());

  CollectionReference<JobSeekerProfile> jobSeekerProfiles() =>
      _col(colJobSeekerProfiles, JobSeekerProfile.fromJson, (m) => m.toJson());

  CollectionReference<EmployerProfile> employerProfiles() =>
      _col(colEmployerProfiles, EmployerProfile.fromJson, (m) => m.toJson());

  CollectionReference<CategoryModel> categories() =>
      _col(colCategories, CategoryModel.fromJson, (m) => m.toJson());

  CollectionReference<SkillModel> skills() =>
      _col(colSkills, SkillModel.fromJson, (m) => m.toJson());

  CollectionReference<JobModel> jobs() =>
      _col(colJobs, JobModel.fromJson, (m) => m.toJson());

  CollectionReference<ApplicationModel> applications() =>
      _col(colApplications, ApplicationModel.fromJson, (m) => m.toJson());

  CollectionReference<ApplicationStatusHistoryItem> statusHistory(String applicationId) =>
      db
          .collection(colApplications)
          .doc(applicationId)
          .collection(subStatusHistory)
          .withConverter<ApplicationStatusHistoryItem>(
            fromFirestore: (s, _) =>
                ApplicationStatusHistoryItem.fromJson(_withId(s)),
            toFirestore: (m, _) => m.toJson(),
          );

  CollectionReference<ResumeModel> resumes() =>
      _col(colResumes, ResumeModel.fromJson, (m) => m.toJson());

  CollectionReference<AiAnalysis> aiAnalyses(String resumeId) => db
      .collection(colResumes)
      .doc(resumeId)
      .collection(subAiAnalyses)
      .withConverter<AiAnalysis>(
        fromFirestore: (s, _) => AiAnalysis.fromJson(_withId(s)),
        toFirestore: (m, _) => m.toJson(),
      );

  CollectionReference<JobRecommendation> jobRecommendations() =>
      _col(colJobRecommendations, JobRecommendation.fromJson, (m) => m.toJson());

  CollectionReference<SavedJob> savedJobs() =>
      _col(colSavedJobs, SavedJob.fromJson, (m) => m.toJson());

  CollectionReference<NotificationModel> notifications() =>
      _col(colNotifications, NotificationModel.fromJson, (m) => m.toJson());

  CollectionReference<AiMatchingLog> aiMatchingLogs() =>
      _col(colAiMatchingLogs, AiMatchingLog.fromJson, (m) => m.toJson());

  CollectionReference<SystemConfig> systemConfigurations() =>
      _col(colSystemConfigurations, SystemConfig.fromJson, (m) => m.toJson());

  CollectionReference<ChatThread> chats() =>
      _col(colChats, ChatThread.fromJson, (m) => m.toJson());

  CollectionReference<ChatMessage> messages(String chatId) => db
      .collection(colChats)
      .doc(chatId)
      .collection(subMessages)
      .withConverter<ChatMessage>(
        fromFirestore: (s, _) => ChatMessage.fromJson(_withId(s)),
        toFirestore: (m, _) => m.toJson(),
      );

  CollectionReference<AiSession> aiSessions(String uid) => db
      .collection(colUsers)
      .doc(uid)
      .collection(subAiSessions)
      .withConverter<AiSession>(
        fromFirestore: (s, _) => AiSession.fromJson(_withId(s)),
        toFirestore: (m, _) => m.toJson(),
      );

  static JsonMap _withId(DocumentSnapshot snap) {
    final data = (snap.data() as JsonMap?) ?? <String, dynamic>{};
    return {...data, 'id': snap.id};
  }
}
