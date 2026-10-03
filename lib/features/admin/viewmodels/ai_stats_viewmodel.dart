import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../shared/models/recommendation_models.dart';
import 'admin_providers.dart';

class TaskStat {
  const TaskStat({
    required this.task,
    required this.count,
    required this.avgTimeMs,
    required this.tokens,
    required this.successCount,
  });
  final String task;
  final int count;
  final int avgTimeMs;
  final int tokens;
  final int successCount;
}

class DayBucket {
  const DayBucket({required this.date, required this.count});
  final DateTime date;
  final int count;

  /// toLocaleDateString('vi-VN', { weekday: 'short' }) → "Th 2" … "CN".
  String get weekdayLabel =>
      date.weekday == DateTime.sunday ? 'CN' : 'Th ${date.weekday + 1}';

  String get isoDate =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

/// Pure port of AiStatsPage.computeStats(logs).
class AiStats {
  const AiStats({
    required this.total,
    required this.successCount,
    required this.successRate,
    required this.avgTimeMs,
    required this.maxTimeMs,
    required this.tokensIn,
    required this.tokensOut,
    required this.byTask,
    required this.last7Days,
    required this.slowest,
  });

  final int total;
  final int successCount;
  final int successRate; // 0..100
  final int avgTimeMs;
  final int maxTimeMs;
  final int tokensIn;
  final int tokensOut;
  final List<TaskStat> byTask;
  final List<DayBucket> last7Days;
  final List<AiMatchingLog> slowest;

  /// DEEPSEEK_PRICE_PER_1M (USD per 1M tokens) — kept verbatim from the web
  /// page so the "Est. cost" tile and the token footer match.
  static const priceInPer1M = 0.27;
  static const priceOutPer1M = 1.1;

  int get totalTokens => tokensIn + tokensOut;
  int get maxDayCount => last7Days.fold<int>(1, (m, d) => d.count > m ? d.count : m);
  bool get isEmpty => total == 0;

  double get costIn => tokensIn / 1e6 * priceInPer1M;
  double get costOut => tokensOut / 1e6 * priceOutPer1M;

  /// `(tokensIn/1e6*0.27 + tokensOut/1e6*1.1).toFixed(4)`.
  String get estCost => (costIn + costOut).toStringAsFixed(4);

  static const empty = AiStats(
    total: 0,
    successCount: 0,
    successRate: 0,
    avgTimeMs: 0,
    maxTimeMs: 0,
    tokensIn: 0,
    tokensOut: 0,
    byTask: [],
    last7Days: [],
    slowest: [],
  );

  factory AiStats.compute(List<AiMatchingLog> logs, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final total = logs.length;
    final success = logs.where((l) => l.success).length;
    final times = logs.map((l) => l.processingTimeMs).toList();
    final avg = total == 0 ? 0 : (times.fold<int>(0, (a, b) => a + b) / total).round();
    final max = times.isEmpty ? 0 : times.reduce((a, b) => a > b ? a : b);
    final tokensIn = logs.fold<int>(0, (a, l) => a + l.tokensIn);
    final tokensOut = logs.fold<int>(0, (a, l) => a + l.tokensOut);

    // byTask — insertion order of first appearance
    final order = <String>[];
    final grouped = <String, List<AiMatchingLog>>{};
    for (final l in logs) {
      if (!grouped.containsKey(l.task)) order.add(l.task);
      grouped.putIfAbsent(l.task, () => []).add(l);
    }
    final byTask = [
      for (final t in order)
        TaskStat(
          task: t,
          count: grouped[t]!.length,
          avgTimeMs: (grouped[t]!.fold<int>(0, (a, l) => a + l.processingTimeMs) /
                  grouped[t]!.length)
              .round(),
          tokens: grouped[t]!.fold<int>(0, (a, l) => a + l.tokensIn + l.tokensOut),
          successCount: grouped[t]!.where((l) => l.success).length,
        ),
    ];

    // last 7 days — local calendar days (fixes the web UTC off-by-one quirk)
    final day0 = DateTime(today.year, today.month, today.day);
    final buckets = <DayBucket>[];
    for (var i = 6; i >= 0; i--) {
      final d = day0.subtract(Duration(days: i));
      final count = logs.where((l) {
        final c = l.createdAt;
        return c != null && c.year == d.year && c.month == d.month && c.day == d.day;
      }).length;
      buckets.add(DayBucket(date: d, count: count));
    }

    final slowest = [...logs]
      ..sort((a, b) => b.processingTimeMs.compareTo(a.processingTimeMs));

    return AiStats(
      total: total,
      successCount: success,
      successRate: total == 0 ? 0 : (success / total * 100).round(),
      avgTimeMs: avg,
      maxTimeMs: max,
      tokensIn: tokensIn,
      tokensOut: tokensOut,
      byTask: byTask,
      last7Days: buckets,
      slowest: slowest.take(5).toList(),
    );
  }
}

/// Stats over the last 200 logs (AppConfig.aiStatsLogLimit).
final aiStatsProvider = Provider<AsyncValue<AiStats>>((ref) {
  final logs = ref.watch(aiLogsProvider(AppConfig.aiStatsLogLimit));
  return logs.whenData(AiStats.compute);
});
