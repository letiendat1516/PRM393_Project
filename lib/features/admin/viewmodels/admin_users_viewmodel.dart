import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/enums.dart';
import '../../../shared/models/employer_profile_model.dart';
import '../../../shared/models/user_model.dart';
import 'admin_providers.dart';

/// adminValidator status enum all|active|blocked.
enum AccountStatusFilter { all, active, blocked }

extension AccountStatusFilterLabel on AccountStatusFilter {
  String get label => switch (this) {
        AccountStatusFilter.all => 'Tất cả trạng thái',
        AccountStatusFilter.active => 'Đang hoạt động',
        AccountStatusFilter.blocked => 'Đã khóa',
      };

  bool matches(bool isActive) => switch (this) {
        AccountStatusFilter.all => true,
        AccountStatusFilter.active => isActive,
        AccountStatusFilter.blocked => !isActive,
      };
}

/// Generic page result mirroring `{ items, total, page, limit }`.
class PagedResult<T> {
  const PagedResult({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  final List<T> items;
  final int total;
  final int page;
  final int limit;

  int get totalPages => total == 0 ? 1 : ((total + limit - 1) ~/ limit).clamp(1, 1 << 30);

  static PagedResult<T> paginate<T>(List<T> all, int page, int limit) {
    final total = all.length;
    final totalPages = total == 0 ? 1 : (total + limit - 1) ~/ limit;
    final p = page.clamp(1, totalPages);
    final start = (p - 1) * limit;
    final end = (start + limit).clamp(0, total);
    return PagedResult(
      items: start >= total ? const [] : all.sublist(start, end),
      total: total,
      page: p,
      limit: limit,
    );
  }
}

/// Backend keyword sanitiser: trim, ≤100 chars, strip , % ( ).
String sanitizeKeyword(String raw) {
  var k = raw.trim();
  if (k.length > 100) k = k.substring(0, 100);
  return k.replaceAll(RegExp(r'[,%()]'), '').trim();
}

bool keywordMatches(String keyword, Iterable<String?> fields) {
  if (keyword.isEmpty) return true;
  final k = keyword.toLowerCase();
  return fields.any((f) => (f ?? '').toLowerCase().contains(k));
}

class AdminUsersFilter {
  const AdminUsersFilter({
    this.role = UserRole.jobSeeker,
    this.keyword = '',
    this.status = AccountStatusFilter.all,
    this.page = 1,
    this.limit = 20,
  });

  final UserRole role;
  final String keyword;
  final AccountStatusFilter status;
  final int page;
  final int limit;

  AdminUsersFilter copyWith({
    UserRole? role,
    String? keyword,
    AccountStatusFilter? status,
    int? page,
  }) =>
      AdminUsersFilter(
        role: role ?? this.role,
        keyword: keyword ?? this.keyword,
        status: status ?? this.status,
        page: page ?? this.page,
        limit: limit,
      );
}

class AdminUsersFilterNotifier extends StateNotifier<AdminUsersFilter> {
  AdminUsersFilterNotifier() : super(const AdminUsersFilter());

  /// changeType: status + keyword preserved, page reset.
  void setRole(UserRole role) => state = state.copyWith(role: role, page: 1);

  /// submitSearch: keyword applied only on submit, page reset.
  void submitKeyword(String raw) =>
      state = state.copyWith(keyword: sanitizeKeyword(raw), page: 1);

  void setStatus(AccountStatusFilter status) =>
      state = state.copyWith(status: status, page: 1);

  void setPage(int page) => state = state.copyWith(page: page < 1 ? 1 : page);
}

final adminUsersFilterProvider =
    StateNotifierProvider.autoDispose<AdminUsersFilterNotifier, AdminUsersFilter>(
        (_) => AdminUsersFilterNotifier());

/// Row projection shared by both tabs (job seeker: fullName; employer: companyName).
class AdminAccountRow {
  const AdminAccountRow({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    this.city,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final bool isActive;
  final String? city;
}

/// Users list: Firestore query by role, keyword/status/page applied client-side.
final adminUsersPageProvider =
    Provider.autoDispose<AsyncValue<PagedResult<AdminAccountRow>>>((ref) {
  final filter = ref.watch(adminUsersFilterProvider);
  final users = ref.watch(usersByRoleProvider(filter.role));
  final profiles = filter.role == UserRole.employer
      ? ref.watch(employerProfilesProvider)
      : const AsyncData<List<EmployerProfile>>([]);

  if (users.hasError) return AsyncError(users.error!, users.stackTrace ?? StackTrace.current);
  if (users.isLoading && !users.hasValue) return const AsyncLoading();

  final byUid = <String, EmployerProfile>{
    for (final p in profiles.valueOrNull ?? const <EmployerProfile>[]) p.uid: p,
  };

  final rows = <AdminAccountRow>[];
  for (final u in users.value ?? const <UserModel>[]) {
    final p = byUid[u.uid];
    final name = filter.role == UserRole.employer
        ? ((p?.companyName.isNotEmpty ?? false) ? p!.companyName : u.fullName)
        : u.fullName;
    if (!filter.status.matches(u.isActive)) continue;
    if (!keywordMatches(filter.keyword, [name, u.email, u.fullName])) continue;
    rows.add(AdminAccountRow(
      id: u.uid,
      name: name,
      email: u.email,
      role: u.role,
      isActive: u.isActive,
      city: u.city ?? p?.city,
    ));
  }
  return AsyncData(PagedResult.paginate(rows, filter.page, filter.limit));
});
