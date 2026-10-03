import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import 'brand.dart';

/// components/auth/AuthShell.jsx — two-column shell: left brand panel
/// (bg-primary, headline, pitch, 3 highlights, copyright) and right form
/// (max-w-md). Auth pages render WITHOUT navbar/footer.
class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.footer,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;

  /// `<main class="… px-4 py-12 sm:px-6">`.
  static const double _verticalPadding = 48;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 1024;
    final horizontalPadding = isWide ? 48.0 : 20.0;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Row(
          children: [
            if (isWide) const Expanded(child: _AuthLeft()),
            Expanded(
              // `flex items-center justify-center`: the max-w-md column is
              // vertically centred while shorter than the viewport and the
              // panel scrolls once the form grows taller than it.
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final minHeight = constraints.hasBoundedHeight
                      ? math.max(0.0, constraints.maxHeight - _verticalPadding * 2)
                      : 0.0;
                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: _verticalPadding,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: minHeight),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 448),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (!isWide)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 32),
                                  child: Center(
                                    child: InkWell(
                                      onTap: () => context.go(AppRoutes.home),
                                      child: const BrandLogo(),
                                    ),
                                  ),
                                ),
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                  letterSpacing: -0.5,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                subtitle,
                                style: const TextStyle(
                                    fontSize: 14, color: AppColors.inkSoft, height: 1.6),
                              ),
                              const SizedBox(height: 28),
                              child,
                              if (footer != null) ...[
                                const SizedBox(height: 24),
                                Center(child: footer!),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `<aside class="relative hidden flex-col justify-between overflow-hidden
/// bg-primary p-12 text-white lg:flex">`.
class _AuthLeft extends StatelessWidget {
  const _AuthLeft();

  static const double _padding = 48;

  static const _highlights = [
    (
      Icons.auto_awesome_outlined,
      'Hiểu đúng hồ sơ của bạn',
      'Đọc CV và nhận diện kỹ năng, kinh nghiệm thực tế thay vì chỉ tìm theo từ khoá.',
    ),
    (
      Icons.shield_outlined,
      'An toàn cho dữ liệu cá nhân',
      'Thông tin được mã hoá và bảo vệ theo tiêu chuẩn phổ biến của các dịch vụ tài chính.',
    ),
    (
      Icons.trending_up,
      'Gợi ý việc làm sát với bạn',
      'Ưu tiên các tin tuyển dụng phù hợp kinh nghiệm và định hướng nghề nghiệp.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.hardEdge,
        children: [
          // `absolute -right-24 -top-24 h-72 w-72 rounded-full bg-white/10`
          Positioned(
            right: -96,
            top: -96,
            child: Container(
              width: 288,
              height: 288,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // `absolute -bottom-24 -left-24 h-72 w-72 rounded-full bg-white/5`
          Positioned(
            left: -96,
            bottom: -96,
            child: Container(
              width: 288,
              height: 288,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // `justify-between` between logo / pitch block / copyright while the
          // panel is taller than its content; on short (landscape) heights the
          // content scrolls instead of overflowing.
          LayoutBuilder(
            builder: (context, constraints) {
              final minHeight = constraints.hasBoundedHeight
                  ? math.max(0.0, constraints.maxHeight - _padding * 2)
                  : 0.0;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(_padding),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: minHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () => context.go(AppRoutes.home),
                        child: const BrandLogo(variant: BrandVariant.light),
                      ),
                      const SizedBox(height: 48),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 448),
                            child: const Text(
                              'Tìm việc đúng người, đúng việc',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 448),
                            child: const Text(
                              'JobHub giúp ứng viên tiếp cận các tin tuyển dụng phù hợp và để nhà tuyển dụng tìm được người đúng yêu cầu nhanh hơn.',
                              style: TextStyle(color: AppColors.primary100, fontSize: 15, height: 1.7),
                            ),
                          ),
                          const SizedBox(height: 40),
                          for (var i = 0; i < _highlights.length; i++) ...[
                            if (i > 0) const SizedBox(height: 24),
                            _highlight(_highlights[i].$1, _highlights[i].$2, _highlights[i].$3),
                          ],
                        ],
                      ),
                      const SizedBox(height: 48),
                      Text(
                        '© ${DateTime.now().year} JobHub. Mọi quyền được bảo lưu.',
                        style: const TextStyle(color: AppColors.primary100, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _highlight(IconData icon, String title, String description) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600, height: 1.4)),
                const SizedBox(height: 2),
                Text(description,
                    style: const TextStyle(color: AppColors.primary100, fontSize: 13, height: 1.5)),
              ],
            ),
          ),
        ],
      );
}
