import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/recommendation_models.dart';
import '../../../shared/widgets/public_layout.dart';
import '../../../shared/widgets/ui_primitives.dart';
import 'method_badge.dart';

/// `bg-canvas pt-18` > `mx-auto max-w-4xl px-4 py-6 sm:px-6 lg:px-8` shell
/// shared by RecommendedPage and SessionDetailPage (inside PublicLayout).
class RecommendationsShell extends StatelessWidget {
  const RecommendationsShell({super.key, required this.child, this.maxWidth = 896});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final horizontal = width >= 1024 ? 32.0 : (width >= 640 ? 24.0 : 16.0);
    return PublicLayout(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: 24),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// One tappable session card on /de-xuat:
/// avatar · cvName + MethodBadge · '{date} · N việc làm · Điểm TB: x.x/10' · 'Xem chi tiết' →.
class SessionRow extends StatelessWidget {
  const SessionRow({super.key, required this.session});

  final AiSession session;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.of(context).size.width < 480;
    final avg = (session.avgScore.round() / 10).toStringAsFixed(1);
    final meta =
        '${Formatters.localeDateTime(session.scoredAt)} · ${session.jobCount} việc làm · Điểm TB: $avg/10';

    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () => context.push(AppRoutes.recommendedSessionOf(session.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary50,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: const Icon(Icons.auto_awesome, size: 22, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          session.cvName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
                        ),
                      ),
                      const SizedBox(width: 8),
                      MethodBadge(method: session.method),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meta,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            if (!narrow) ...[
              const Text('Xem chi tiết',
                  style: TextStyle(fontSize: 12, color: AppColors.primary)),
              const SizedBox(width: 6),
            ],
            const Icon(Icons.arrow_forward, size: 18, color: AppColors.inkMuted),
          ],
        ),
      ),
    );
  }
}
