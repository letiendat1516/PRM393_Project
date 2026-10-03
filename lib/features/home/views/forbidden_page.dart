import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/public_layout.dart';

/// routes/RoleGuard.jsx — rendered when an authenticated user opens a route
/// their role is not allowed to see: `max-w-4xl px-6 py-28`, left-aligned
/// red eyebrow, h1 and muted description (no action button on the web).
class ForbiddenPage extends StatelessWidget {
  const ForbiddenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PublicLayout(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 896),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 112),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'KHÔNG CÓ QUYỀN TRUY CẬP',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: AppColors.red600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Bạn không thể truy cập trang này',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: AppColors.ink,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Chức năng này chỉ dành cho tài khoản có quyền phù hợp.',
                  style: TextStyle(fontSize: 16, height: 1.5, color: AppColors.inkMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
