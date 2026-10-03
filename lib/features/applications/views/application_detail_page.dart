import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/failure.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/application_model.dart';
import '../../../shared/widgets/application_status_badge.dart';
import '../../../shared/widgets/public_layout.dart';
import '../../../shared/widgets/status_history_timeline.dart';
import '../../../shared/widgets/ui_primitives.dart';
import '../../auth/viewmodels/current_user_provider.dart';
import '../data/applications_repository.dart';
import '../viewmodels/applications_providers.dart';
import '../viewmodels/review_viewmodel.dart';
import '../widgets/applications_common.dart';

/// MyApplicationDetailPage (pages/MyApplicationsPage.jsx) — /applications/:id.
class ApplicationDetailPage extends ConsumerStatefulWidget {
  const ApplicationDetailPage({super.key, required this.applicationId});
  final String applicationId;

  @override
  ConsumerState<ApplicationDetailPage> createState() => _ApplicationDetailPageState();
}

class _ApplicationDetailPageState extends ConsumerState<ApplicationDetailPage> {
  bool _openingChat = false;

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.myApplications);
    }
  }

  Future<void> _openChat(ApplicationModel app) async {
    setState(() => _openingChat = true);
    try {
      final id = await ref.read(openEmployerChatProvider)(app);
      if (!mounted || id == null) return;
      context.push(AppRoutes.chatRoomOf(id));
    } catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _openingChat = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(currentUserProvider).valueOrNull;
    final detail = ref.watch(applicationWithHistoryProvider(widget.applicationId));

    return PublicLayout(
      child: detail.when(
        loading: () => const ApplicationsPageShell(
          verticalPadding: 64,
          child: Text('Đang tải...', style: TextStyle(color: AppColors.ink)),
        ),
        error: (e, _) {
          // getMine answers 404 for a non-owned application (never leak
          // existence); firestore.rules surfaces that as permission-denied.
          final f = Failure.from(e);
          final msg = f.code == 'FORBIDDEN' ? ApplicationsRepository.notFoundMessage : f.message;
          return ApplicationsPageShell(
            verticalPadding: 64,
            child: RedBanner(message: msg),
          );
        },
        data: (app) {
          // getMine: 404 when missing OR not owned (never leak existence).
          if (app == null || (me != null && app.jobSeekerId != me.uid)) {
            return ApplicationsPageShell(
              verticalPadding: 64,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const RedBanner(message: ApplicationsRepository.notFoundMessage),
                  const SizedBox(height: 16),
                  BackTextLink(label: '← Hồ sơ đã ứng tuyển', onTap: _back),
                ],
              ),
            );
          }
          return ApplicationsPageShell(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BackTextLink(label: '← Hồ sơ đã ứng tuyển', onTap: _back),
                const SizedBox(height: 24),
                MainAsideLayout(
                  main: _MainCard(
                    app: app,
                    openingChat: _openingChat,
                    onChat: () => _openChat(app),
                  ),
                  aside: AppCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CardHeading('Lịch sử trạng thái', large: true),
                        const SizedBox(height: 20),
                        StatusHistoryTimeline(items: app.timeline),
                      ],
                    ),
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

class _MainCard extends StatelessWidget {
  const _MainCard({required this.app, required this.openingChat, required this.onChat});
  final ApplicationModel app;
  final bool openingChat;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    final cv = (app.resumeFileName ?? '').trim().isNotEmpty
        ? app.resumeFileName!
        : 'Không còn khả dụng';
    final letter = (app.coverLetter ?? '').trim();
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.jobTitle,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(app.companyName,
                        style: const TextStyle(fontSize: 16, color: AppColors.inkSoft)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ApplicationStatusBadge(status: app.status),
            ],
          ),
          const SizedBox(height: 24),
          DefinitionGrid(items: [
            DefinitionGrid.text('Ngày ứng tuyển', Formatters.date(app.applicationDate)),
            DefinitionGrid.text('CV đã dùng', cv),
          ]),
          const SizedBox(height: 32),
          const CardHeading('Thư giới thiệu'),
          const SizedBox(height: 8),
          SelectableText(
            letter.isEmpty ? 'Không có thư giới thiệu.' : letter,
            style: const TextStyle(fontSize: 14, color: AppColors.inkSoft, height: 1.6),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: () => context.push(AppRoutes.jobDetailOf(app.jobId)),
                icon: const Icon(Icons.work_outline, size: 18),
                label: const Text('Xem tin tuyển dụng'),
              ),
              OutlinedButton.icon(
                onPressed: openingChat ? null : onChat,
                icon: openingChat
                    ? const SizedBox(
                        width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.chat_bubble_outline, size: 18),
                label: const Text('Nhắn tin cho nhà tuyển dụng'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
