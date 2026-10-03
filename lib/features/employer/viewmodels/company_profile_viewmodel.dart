import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/enums.dart';
import '../../../core/utils/failure.dart';
import '../../auth/viewmodels/current_user_provider.dart';
import '../data/employer_repository.dart';

class CompanyProfileState {
  const CompanyProfileState({
    this.saving = false,
    this.uploadingLogo = false,
    this.error,
    this.message,
    this.fieldErrors = const {},
  });

  final bool saving;
  final bool uploadingLogo;
  final String? error;
  final String? message;
  final Map<String, String> fieldErrors;

  CompanyProfileState copyWith({
    bool? saving,
    bool? uploadingLogo,
    Object? error = _unset,
    Object? message = _unset,
    Map<String, String>? fieldErrors,
  }) =>
      CompanyProfileState(
        saving: saving ?? this.saving,
        uploadingLogo: uploadingLogo ?? this.uploadingLogo,
        error: identical(error, _unset) ? this.error : error as String?,
        message: identical(message, _unset) ? this.message : message as String?,
        fieldErrors: fieldErrors ?? this.fieldErrors,
      );
}

const Object _unset = Object();

/// EmployerCompanyProfilePage form actions (PUT /employers/me).
class CompanyProfileViewModel extends StateNotifier<CompanyProfileState> {
  CompanyProfileViewModel(this._ref) : super(const CompanyProfileState());
  final Ref _ref;

  Future<bool> save({
    required String companyName,
    required String phone,
    required String website,
    required String companyDescription,
    required String city,
    required String contactName,
    Gender? gender,
  }) async {
    final me = _ref.read(currentUserProvider).valueOrNull;
    if (me == null || !me.isEmployer) {
      state = state.copyWith(error: 'Bạn không có quyền thực hiện thao tác này.', message: null);
      return false;
    }
    state = state.copyWith(saving: true, error: null, message: null, fieldErrors: const {});
    try {
      await _ref.read(employerRepositoryProvider).updateProfile(
            me.uid,
            companyName: companyName,
            phone: phone,
            website: website,
            companyDescription: companyDescription,
            city: city,
            contactName: contactName,
            gender: gender,
          );
      if (mounted) {
        state = state.copyWith(saving: false, message: 'Cập nhật hồ sơ công ty thành công.');
      }
      return true;
    } catch (e) {
      final f = Failure.from(e);
      if (mounted) {
        state = state.copyWith(
          saving: false,
          error: f.message.isEmpty ? 'Không thể cập nhật hồ sơ công ty.' : f.message,
          fieldErrors: f.fieldErrors,
        );
      }
      return false;
    }
  }

  /// Storage may be disabled (no Blaze plan) — failures are reported softly.
  Future<void> uploadLogo(Uint8List bytes, String fileName) async {
    final me = _ref.read(currentUserProvider).valueOrNull;
    if (me == null) return;
    state = state.copyWith(uploadingLogo: true, error: null, message: null);
    try {
      await _ref.read(employerRepositoryProvider).uploadLogo(uid: me.uid, bytes: bytes, fileName: fileName);
      if (mounted) state = state.copyWith(uploadingLogo: false, message: 'Đã cập nhật logo công ty.');
    } catch (_) {
      if (mounted) {
        state = state.copyWith(
          uploadingLogo: false,
          error: 'Không thể tải logo lên lúc này (Firebase Storage chưa được bật). Các thông tin khác vẫn lưu bình thường.',
        );
      }
    }
  }

  void clearMessages() => state = state.copyWith(error: null, message: null);
}

final companyProfileViewModelProvider =
    StateNotifierProvider.autoDispose<CompanyProfileViewModel, CompanyProfileState>(
        (ref) => CompanyProfileViewModel(ref));
