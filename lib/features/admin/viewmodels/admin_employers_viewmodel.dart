import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/enums.dart';
import '../../../shared/models/employer_profile_model.dart';
import '../../../shared/models/user_model.dart';
import 'admin_providers.dart';
import 'admin_users_viewmodel.dart';

/// adminValidator verification enum all|verified|pending.
enum VerificationFilter { all, verified, pending }

extension VerificationFilterLabel on VerificationFilter {
  String get label => switch (this) {
        VerificationFilter.all => 'Tất cả xác minh',
        VerificationFilter.verified => 'Đã xác minh',
        VerificationFilter.pending => 'Chờ xác minh',
      };

  bool matches(bool isVerified) => switch (this) {
        VerificationFilter.all => true,
        VerificationFilter.verified => isVerified,
        VerificationFilter.pending => !isVerified,
      };
}

extension AccountStatusFilterEmployerLabel on AccountStatusFilter {
  /// Employer page uses "Tất cả tài khoản" for the `all` option.
  String get employerLabel =>
      this == AccountStatusFilter.all ? 'Tất cả tài khoản' : label;
}

class AdminEmployersFilter {
  const AdminEmployersFilter({
    this.keyword = '',
    this.status = AccountStatusFilter.all,
    this.verification = VerificationFilter.all,
    this.page = 1,
    this.limit = 20,
  });

  final String keyword;
  final AccountStatusFilter status;
  final VerificationFilter verification;
  final int page;
  final int limit;

  AdminEmployersFilter copyWith({
    String? keyword,
    AccountStatusFilter? status,
    VerificationFilter? verification,
    int? page,
  }) =>
      AdminEmployersFilter(
        keyword: keyword ?? this.keyword,
        status: status ?? this.status,
        verification: verification ?? this.verification,
        page: page ?? this.page,
        limit: limit,
      );
}

class AdminEmployersFilterNotifier extends StateNotifier<AdminEmployersFilter> {
  AdminEmployersFilterNotifier() : super(const AdminEmployersFilter());

  void submitKeyword(String raw) =>
      state = state.copyWith(keyword: sanitizeKeyword(raw), page: 1);
  void setStatus(AccountStatusFilter s) => state = state.copyWith(status: s, page: 1);
  void setVerification(VerificationFilter v) =>
      state = state.copyWith(verification: v, page: 1);
  void setPage(int page) => state = state.copyWith(page: page < 1 ? 1 : page);
}

final adminEmployersFilterProvider = StateNotifierProvider.autoDispose<
    AdminEmployersFilterNotifier, AdminEmployersFilter>((_) => AdminEmployersFilterNotifier());

/// Employer projection used by the verification page.
class AdminEmployerRow {
  const AdminEmployerRow({
    required this.id,
    required this.companyName,
    required this.email,
    required this.isActive,
    required this.isVerified,
    this.contactName,
    this.city,
    this.phone,
    this.website,
    this.createdAt,
  });

  final String id;
  final String companyName;
  final String email;
  final bool isActive;
  final bool isVerified;
  final String? contactName;
  final String? city;
  final String? phone;
  final String? website;
  final DateTime? createdAt;
}

/// Employers = employerProfiles joined with users/{uid} (email / isActive /
/// isVerified authority), filtered client-side.
final adminEmployersPageProvider =
    Provider.autoDispose<AsyncValue<PagedResult<AdminEmployerRow>>>((ref) {
  final filter = ref.watch(adminEmployersFilterProvider);
  final profiles = ref.watch(employerProfilesProvider);
  final users = ref.watch(usersByRoleProvider(UserRole.employer));

  if (profiles.hasError) {
    return AsyncError(profiles.error!, profiles.stackTrace ?? StackTrace.current);
  }
  if (profiles.isLoading && !profiles.hasValue) return const AsyncLoading();

  final userByUid = <String, UserModel>{
    for (final u in users.valueOrNull ?? const <UserModel>[]) u.uid: u,
  };
  final seen = <String>{};
  final rows = <AdminEmployerRow>[];

  void add(AdminEmployerRow r) {
    if (!seen.add(r.id)) return;
    if (!filter.status.matches(r.isActive)) return;
    if (!filter.verification.matches(r.isVerified)) return;
    if (!keywordMatches(filter.keyword, [r.companyName, r.email])) return;
    rows.add(r);
  }

  for (final p in profiles.value ?? const <EmployerProfile>[]) {
    final u = userByUid[p.uid];
    add(AdminEmployerRow(
      id: p.uid,
      companyName: p.companyName.isNotEmpty ? p.companyName : (u?.fullName ?? ''),
      email: p.email ?? u?.email ?? '',
      isActive: u?.isActive ?? p.isActive,
      isVerified: u?.isVerified ?? p.isVerified,
      contactName: p.contactName,
      city: p.city ?? u?.city,
      phone: p.phone ?? u?.phone,
      website: p.website ?? u?.website,
      createdAt: p.createdAt ?? u?.createdAt,
    ));
  }
  // employer accounts without a profile doc yet
  for (final u in userByUid.values) {
    add(AdminEmployerRow(
      id: u.uid,
      companyName: u.fullName,
      email: u.email,
      isActive: u.isActive,
      isVerified: u.isVerified,
      city: u.city,
      phone: u.phone,
      website: u.website,
      createdAt: u.createdAt,
    ));
  }
  rows.sort((a, b) {
    if (a.createdAt == null && b.createdAt == null) return 0;
    if (a.createdAt == null) return 1;
    if (b.createdAt == null) return -1;
    return b.createdAt!.compareTo(a.createdAt!);
  });
  return AsyncData(PagedResult.paginate(rows, filter.page, filter.limit));
});
