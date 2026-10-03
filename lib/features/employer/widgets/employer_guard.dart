import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/public_layout.dart';
import '../../../shared/widgets/section.dart';
import '../../auth/viewmodels/current_user_provider.dart';
import 'employer_page_header.dart';
import 'employer_state_banners.dart';

/// Web auth gate shared by every employer page:
/// - authLoading → 'Đang kiểm tra phiên đăng nhập...' card
/// - unauthenticated → redirect to /dang-nhap
/// - wrong role → red 'Không có quyền truy cập' header (no card)
/// - employer → [builder].
class EmployerGuard extends ConsumerWidget {
  const EmployerGuard({
    super.key,
    required this.deniedTitle,
    required this.builder,
    this.maxWidth = 1152,
  });

  final String deniedTitle;
  final Widget Function(BuildContext context, UserModel user) builder;
  final double maxWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return user.when(
      loading: () => EmployerPageShell(
        maxWidth: 896,
        child: const StateCard(text: 'Đang kiểm tra phiên đăng nhập...'),
      ),
      error: (e, _) => EmployerPageShell(
        maxWidth: 896,
        child: StateCard.error(text: 'Không thể kiểm tra phiên đăng nhập. Vui lòng thử lại.'),
      ),
      data: (u) {
        if (u == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go(AppRoutes.login);
          });
          return EmployerPageShell(
            maxWidth: 896,
            child: const StateCard(text: 'Đang chuyển đến trang đăng nhập...'),
          );
        }
        if (!u.isEmployer) {
          return EmployerPageShell(
            maxWidth: 896,
            child: EmployerPageHeader(
              eyebrow: 'Không có quyền truy cập',
              eyebrowColor: AppColors.red600,
              title: deniedTitle,
              subtitle: 'Chức năng này chỉ dành cho tài khoản nhà tuyển dụng.',
            ),
          );
        }
        return builder(context, u);
      },
    );
  }
}

/// `<main class="mx-auto max-w-* px-6 py-28">` inside the PublicLayout.
class EmployerPageShell extends StatelessWidget {
  const EmployerPageShell({
    super.key,
    required this.child,
    this.maxWidth = 1152,
    this.scrollController,
  });

  final Widget child;
  final double maxWidth;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width >= 1024 ? 32.0 : (width >= 640 ? 24.0 : 16.0);
    return PublicLayout(
      scrollController: scrollController,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth > kContentMaxWidth ? kContentMaxWidth : maxWidth),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: width >= 640 ? 48 : 28),
            child: child,
          ),
        ),
      ),
    );
  }
}
