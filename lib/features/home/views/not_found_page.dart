import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/public_layout.dart';
import '../../../shared/widgets/section.dart';

/// pages/NotFoundPage.jsx — catch-all 404 inside PublicLayout: `404` eyebrow,
/// 'Không tìm thấy trang', description and the 'Về trang chủ' primary button.
/// [path] is the attempted location (kept for diagnostics; the web page does
/// not display it).
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key, this.path});
  final String? path;

  @override
  Widget build(BuildContext context) {
    final sm = MediaQuery.sizeOf(context).width >= 640;
    return PublicLayout(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: sm ? 128 : 96),
        child: PageContainer(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 576),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Eyebrow(label: '404'),
                  const SizedBox(height: 16),
                  Text(
                    'Không tìm thấy trang',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: sm ? 36 : 30,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.75,
                      height: 1.15,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Trang bạn đang tìm có thể đã bị di chuyển hoặc không còn tồn tại.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, height: 1.75, color: AppColors.inkSoft),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => context.go(AppRoutes.home),
                    child: const Text('Về trang chủ'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
