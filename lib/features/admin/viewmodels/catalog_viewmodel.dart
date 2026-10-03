import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/failure.dart';
import '../data/admin_repository.dart';

enum CatalogKind { category, skill }

/// CatalogManagementPage state: which form is saving, which row is being
/// deleted, and the two banners (error + success).
class CatalogState {
  const CatalogState({this.savingType, this.busyKey, this.error, this.message});

  final CatalogKind? savingType;
  /// `category-{id}` | `skill-{id}` — single row in flight (web deletingKey).
  final String? busyKey;
  final String? error;
  final String? message;

  bool isSaving(CatalogKind k) => savingType == k;
  bool isBusy(CatalogKind k, String id) => busyKey == keyFor(k, id);

  static String keyFor(CatalogKind k, String id) => '${k.name}-$id';
}

/// Add / delete only — the web page has no rename action.
class CatalogNotifier extends StateNotifier<CatalogState> {
  CatalogNotifier(this._ref) : super(const CatalogState());
  final Ref _ref;

  AdminRepository get _repo => _ref.read(adminRepositoryProvider);

  Future<bool> addCategory(String raw) => _add(
        CatalogKind.category,
        raw,
        emptyMessage: 'Vui lòng nhập tên ngành nghề.',
        fallback: 'Không thể thêm ngành nghề.',
        success: (n) => 'Đã thêm ngành nghề "$n".',
        op: (n) => _repo.createCategory(n),
      );

  Future<bool> addSkill(String raw) => _add(
        CatalogKind.skill,
        raw,
        emptyMessage: 'Vui lòng nhập tên kỹ năng.',
        fallback: 'Không thể thêm kỹ năng.',
        success: (n) => 'Đã thêm kỹ năng "$n".',
        op: (n) => _repo.createSkill(n),
      );

  Future<bool> deleteCategory(String id, String name) => _rowOp(
        CatalogKind.category,
        id,
        missingIdMessage: 'Không xác định được mã ngành nghề cần xoá.',
        fallback: 'Không thể xoá ngành nghề.',
        success: 'Đã xoá ngành nghề "$name".',
        op: () => _repo.deleteCategory(id),
      );

  Future<bool> deleteSkill(String id, String name) => _rowOp(
        CatalogKind.skill,
        id,
        missingIdMessage: 'Không xác định được mã kỹ năng cần xoá.',
        fallback: 'Không thể xoá kỹ năng.',
        success: 'Đã xoá kỹ năng "$name".',
        op: () => _repo.deleteSkill(id),
      );

  Future<bool> _add(
    CatalogKind kind,
    String raw, {
    required String emptyMessage,
    required String fallback,
    required String Function(String) success,
    required Future<void> Function(String) op,
  }) async {
    if (!mounted) return false;
    final n = raw.trim();
    if (n.isEmpty) {
      state = CatalogState(error: emptyMessage, message: state.message);
      return false;
    }
    state = CatalogState(savingType: kind);
    try {
      await op(n);
      _set(CatalogState(message: success(n)));
      return true;
    } catch (e) {
      _set(CatalogState(error: _message(e, fallback)));
      return false;
    }
  }

  Future<bool> _rowOp(
    CatalogKind kind,
    String id, {
    required String missingIdMessage,
    required String fallback,
    required String success,
    required Future<void> Function() op,
  }) async {
    if (!mounted) return false;
    if (id.isEmpty) {
      state = CatalogState(error: missingIdMessage, message: state.message);
      return false;
    }
    state = CatalogState(busyKey: CatalogState.keyFor(kind, id));
    try {
      await op();
      _set(CatalogState(message: success));
      return true;
    } catch (e) {
      _set(CatalogState(error: _message(e, fallback)));
      return false;
    }
  }

  static String _message(Object e, String fallback) {
    final f = Failure.from(e);
    return f.code == 'UNKNOWN' ? fallback : f.message;
  }

  void dismissError() => _set(CatalogState(message: state.message));
  void dismissMessage() => _set(CatalogState(error: state.error));

  /// autoDispose provider: never assign state after the page was left.
  void _set(CatalogState next) {
    if (mounted) state = next;
  }
}

final catalogNotifierProvider =
    StateNotifierProvider.autoDispose<CatalogNotifier, CatalogState>(
        (ref) => CatalogNotifier(ref));
