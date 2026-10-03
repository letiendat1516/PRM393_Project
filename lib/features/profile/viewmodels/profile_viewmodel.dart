import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/failure.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/models/jobseeker_profile_model.dart';
import '../data/profile_repository.dart';
import 'profile_providers.dart';

enum ProfileMessageType { none, success, error }

/// ResumePage `profileSaving` + `profileMsg` and EditProfilePage save state.
class ProfileEditState {
  const ProfileEditState({
    this.saving = false,
    this.messageType = ProfileMessageType.none,
    this.message,
  });

  final bool saving;
  final ProfileMessageType messageType;
  final String? message;

  bool get hasMessage => messageType != ProfileMessageType.none && message != null;
  bool get isSuccess => messageType == ProfileMessageType.success;

  ProfileEditState copyWith({
    bool? saving,
    ProfileMessageType? messageType,
    String? message,
  }) =>
      ProfileEditState(
        saving: saving ?? this.saving,
        messageType: messageType ?? this.messageType,
        message: message,
      );
}

class ProfileViewModel extends StateNotifier<ProfileEditState> {
  ProfileViewModel(this._ref) : super(const ProfileEditState());
  final Ref _ref;

  static const savedMessage = 'Đã cập nhật hồ sơ.';
  static const saveFailedMessage = 'Không thể cập nhật hồ sơ.';

  // backend/src/validators/jobSeekerValidator.js (Zod `updateProfile`).
  static const headlineTooLong = 'Tiêu đề hồ sơ quá dài.';
  static const cityTooLong = 'Tên thành phố quá dài.';
  static const phoneTooLong = 'Số điện thoại quá dài.';
  static const addressTooLong = 'Địa chỉ quá dài.';
  static const summaryTooLong = 'Giới thiệu bản thân quá dài.';

  ProfileRepository get _repo => _ref.read(profileRepositoryProvider);

  /// PUT /job-seekers/me body rules for the ResumePage form:
  /// fullName trim 2..255 (or empty), headline ≤ 255, city ≤ 100.
  /// Returns the first offending message (shown in the red banner) or null.
  static String? validateBasics({
    required String fullName,
    required String headline,
    required String city,
  }) {
    final fn = fullName.trim();
    if (fn.isNotEmpty) {
      // 'Họ tên phải có ít nhất 2 ký tự.' / 'Họ tên tối đa 255 ký tự.'
      final err = Validators.lengthBetween(fn, 2, 255, label: 'Họ tên');
      if (err != null) return err;
    }
    if (headline.trim().length > 255) return headlineTooLong;
    if (city.trim().length > 100) return cityTooLong;
    return null;
  }

  String _requireUid() {
    final uid = _ref.read(currentUidProvider);
    if (uid == null) throw const Failure.unauthorized();
    return uid;
  }

  void clearMessage() {
    if (state.hasMessage) {
      state = state.copyWith(messageType: ProfileMessageType.none, message: null);
    }
  }

  /// ResumePage form (fullName / headline / city). Returns true on success.
  Future<bool> saveBasics({
    required String fullName,
    required String headline,
    required String city,
  }) async {
    final invalid =
        validateBasics(fullName: fullName, headline: headline, city: city);
    if (invalid != null) {
      state = state.copyWith(
        saving: false,
        messageType: ProfileMessageType.error,
        message: invalid,
      );
      return false;
    }
    state = state.copyWith(
        saving: true, messageType: ProfileMessageType.none, message: null);
    try {
      await _repo.updateProfileBasics(
        uid: _requireUid(),
        fullName: fullName.trim(),
        headline: headline.trim(),
        city: city.trim(),
      );
      state = state.copyWith(
        saving: false,
        messageType: ProfileMessageType.success,
        message: savedMessage,
      );
      return true;
    } catch (e) {
      final f = Failure.from(e);
      state = state.copyWith(
        saving: false,
        messageType: ProfileMessageType.error,
        message: f.message.isEmpty ? saveFailedMessage : f.message,
      );
      return false;
    }
  }

  /// EditProfilePage: full payload, arrays replaced wholesale.
  Future<bool> saveFull(JobSeekerProfile profile) async {
    state = state.copyWith(
        saving: true, messageType: ProfileMessageType.none, message: null);
    try {
      final uid = _requireUid();
      final toSave = profile.uid == uid ? profile : _rekey(profile, uid);
      await _repo.updateProfile(toSave);
      state = state.copyWith(
        saving: false,
        messageType: ProfileMessageType.success,
        message: savedMessage,
      );
      return true;
    } catch (e) {
      final f = Failure.from(e);
      state = state.copyWith(
        saving: false,
        messageType: ProfileMessageType.error,
        message: f.message.isEmpty ? saveFailedMessage : f.message,
      );
      return false;
    }
  }

  JobSeekerProfile _rekey(JobSeekerProfile p, String uid) => JobSeekerProfile(
        uid: uid,
        fullName: p.fullName,
        email: p.email,
        phone: p.phone,
        address: p.address,
        city: p.city,
        headline: p.headline,
        profileSummary: p.profileSummary,
        isVerified: p.isVerified,
        isOpenToWork: p.isOpenToWork,
        isActive: p.isActive,
        skills: p.skills,
        workExperiences: p.workExperiences,
        educations: p.educations,
        primaryResumeId: p.primaryResumeId,
        createdAt: p.createdAt,
      );
}

final profileViewModelProvider =
    StateNotifierProvider.autoDispose<ProfileViewModel, ProfileEditState>(
  (ref) => ProfileViewModel(ref),
);
