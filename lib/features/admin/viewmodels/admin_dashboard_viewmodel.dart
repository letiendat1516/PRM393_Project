import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/failure.dart';
import 'admin_providers.dart';

class SeedState {
  const SeedState({this.running = false, this.error, this.message});
  final bool running;
  final String? error;
  final String? message;
}

/// 'Seed dữ liệu demo' action on the admin dashboard.
class SeedDemoNotifier extends StateNotifier<SeedState> {
  SeedDemoNotifier(this._ref) : super(const SeedState());
  final Ref _ref;

  Future<bool> run() async {
    if (state.running) return false;
    state = const SeedState(running: true);
    try {
      final s = await _ref.read(adminRepositoryProvider).seedDemoData();
      state = SeedState(
        message:
            'Đã seed dữ liệu demo: ${s.categories} ngành nghề, ${s.skills} kỹ năng, ${s.employers} nhà tuyển dụng, ${s.jobs} tin tuyển dụng và cấu hình mặc định.',
      );
      _ref.invalidate(adminCountsProvider);
      return true;
    } catch (e) {
      state = SeedState(error: Failure.from(e).message);
      return false;
    }
  }

  void dismiss() => state = const SeedState();
}

final seedDemoProvider = StateNotifierProvider.autoDispose<SeedDemoNotifier, SeedState>(
    (ref) => SeedDemoNotifier(ref));
