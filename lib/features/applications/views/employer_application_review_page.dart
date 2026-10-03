import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/enums.dart';
import '../../../core/utils/failure.dart';
import '../../../shared/models/application_model.dart';
import '../../../shared/widgets/public_layout.dart';
import '../../../shared/widgets/status_history_timeline.dart';
import '../../../shared/widgets/ui_primitives.dart';
import '../../auth/viewmodels/current_user_provider.dart';
import '../data/applications_repository.dart';
import '../viewmodels/applications_providers.dart';
import '../viewmodels/review_viewmodel.dart';
import '../widgets/applications_common.dart';
import '../widgets/review_cards.dart';

/// EmployerApplicationReviewPage (pages/EmployerApplicationsPage.jsx) —
/// /employer/applications/:id (employer owner or admin).
class EmployerApplicationReviewPage extends ConsumerWidget {
  const EmployerApplicationReviewPage({super.key, required this.applicationId});
  final String applicationId;

  /// ApplicationService.ensureOwnedByEmployer (403).
  static const _forbiddenMessage = 'Bạn không có quyền xem hồ sơ này.';

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.employerApplications);
    }
  }

  /// Web `update()`: PATCH {status: next, expectedCurrentStatus: data.status}
  /// then `load()` (the detail stream refreshes by itself and the viewmodel
  /// clears the selection). No toast / success message on the web.
  Future<void> _update(WidgetRef ref, ApplicationModel current, ApplicationStatus next) {
    return ref
        .read(reviewViewModelProvider(applicationId).notifier)
        .updateStatus(current: current, next: next);
  }

  Future<void> _chat(BuildContext context, WidgetRef ref, ApplicationModel app) async {
    final id = await ref
        .read(reviewViewModelProvider(applicationId).notifier)
        .openChatWithCandidate(app);
    if (id != null && context.mounted) context.push(AppRoutes.chatRoomOf(id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider).valueOrNull;
    final detail = ref.watch(applicationWithHistoryProvider(applicationId));
    final review = ref.watch(reviewViewModelProvider(applicationId));

    return PublicLayout(
      child: detail.when(
        loading: () => const ApplicationsPageShell(
          verticalPadding: 64,
          child: Text('Đang tải...', style: TextStyle(color: AppColors.ink)),
        ),
        error: (e, _) {
          // ensureOwnedByEmployer → 403 'Bạn không có quyền xem hồ sơ này.';
          // firestore.rules denies the read for non-owners the same way.
          final f = Failure.from(e);
          final msg = f.code == 'FORBIDDEN' ? _forbiddenMessage : f.message;
          return ApplicationsPageShell(
            verticalPadding: 64,
            child: RedBanner(message: msg),
          );
        },
        data: (app) {
          final forbidden = app != null && me != null && !me.isAdmin && app.employerId != me.uid;
          if (app == null || forbidden) {
            return ApplicationsPageShell(
              verticalPadding: 64,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RedBanner(
                    message: forbidden
                        ? _forbiddenMessage
                        : ApplicationsRepository.notFoundMessage,
                  ),
                  const SizedBox(height: 16),
                  BackTextLink(label: '← Danh sách hồ sơ', onTap: () => _back(context)),
                ],
              ),
            );
          }

          final recommendation = ref.watch(
            latestRecommendationProvider((seekerUid: app.jobSeekerId, jobId: app.jobId)),
          );

          return ApplicationsPageShell(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BackTextLink(label: '← Danh sách hồ sơ', onTap: () => _back(context)),
                const SizedBox(height: 24),
                MainAsideLayout(
                  main: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CandidateCard(
                        app: app,
                        openingChat: review.openingChat,
                        onChat: () => _chat(context, ref, app),
                      ),
                      const SizedBox(height: 24),
                      MatchInfoCard(recommendation: recommendation, app: app),
                    ],
                  ),
                  aside: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      StatusUpdateCard(
                        app: app,
                        selected: review.selected,
                        submitting: review.submitting,
                        error: review.error,
                        onSelect: (s) =>
                            ref.read(reviewViewModelProvider(applicationId).notifier).select(s),
                        onUpdate: () {
                          final next = review.selected;
                          if (next != null) _update(ref, app, next);
                        },
                      ),
                      const SizedBox(height: 24),
                      AppCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const CardHeading('Lịch sử trạng thái'),
                            const SizedBox(height: 20),
                            StatusHistoryTimeline(items: app.timeline),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
