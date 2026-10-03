import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../models/application_model.dart';
import 'application_status_badge.dart';

/// components/application/StatusHistoryTimeline.jsx — vertical timeline with
/// status badge, actor role (fixes the web bug that always showed 'Ứng viên')
/// and timestamp. Pass `application.timeline` (synthetic SUBMITTED node included).
class StatusHistoryTimeline extends StatelessWidget {
  const StatusHistoryTimeline({super.key, required this.items});
  final List<ApplicationStatusHistoryItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Text('Chưa có lịch sử trạng thái.',
          style: TextStyle(color: AppColors.inkMuted, fontSize: 13));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < items.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: i == items.length - 1
                            ? ApplicationStatusBadge.styleOf(items[i].newStatus).$2
                            : AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [BoxShadow(color: AppColors.border, blurRadius: 0, spreadRadius: 1)],
                      ),
                    ),
                    if (i != items.length - 1)
                      Expanded(child: Container(width: 2, color: AppColors.border)),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            ApplicationStatusBadge(status: items[i].newStatus, compact: true),
                            if (items[i].oldStatus != null)
                              Text(
                                'từ ${ApplicationStatusBadge.styleOf(items[i].oldStatus!).$3}',
                                style: const TextStyle(color: AppColors.inkMuted, fontSize: 12),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          // StatusHistoryTimeline.jsx: `{toLocaleString('vi-VN')} · {role}`
                          '${Formatters.localeDateTime(items[i].changedAt)} · ${items[i].actorLabel}',
                          style: const TextStyle(color: AppColors.inkMuted, fontSize: 12),
                        ),
                        if ((items[i].note ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.slate50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.borderMuted),
                              ),
                              child: Text(items[i].note!,
                                  style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
