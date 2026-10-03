import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/section.dart';
import 'home_layout_helpers.dart';
import 'reveal.dart';

/// components/section/CtaBand.jsx — closing green (`bg-secondary`) panel with
/// blurred blobs; both buttons link to /dang-ky.
class CtaBand extends StatelessWidget {
  const CtaBand({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final sm = width >= 640;
    return Section(
      background: AppColors.canvas,
      verticalPadding: homeSectionPadding(context),
      child: Reveal(
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(32),
            boxShadow: AppShadows.elevated,
          ),
          child: Stack(
            children: [
              Positioned(
                right: -40,
                top: -40,
                child: DecorBlob(color: Colors.white.withValues(alpha: 0.12), size: 224),
              ),
              Positioned(
                left: 40,
                bottom: -64,
                child: DecorBlob(color: AppColors.primary.withValues(alpha: 0.25), size: 224),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: sm ? 48 : 24, vertical: sm ? 64 : 48),
                child: LayoutBuilder(builder: (context, c) {
                  final wide = c.maxWidth >= 900;
                  final copy = Column(
                    crossAxisAlignment: wide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Sẵn sàng tìm kiếm cơ hội nghề nghiệp tiếp theo?',
                        textAlign: wide ? TextAlign.start : TextAlign.center,
                        style: TextStyle(
                          fontSize: sm ? 30 : 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.2,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tải CV lên hôm nay để AI phân tích hồ sơ và gợi ý những việc làm phù hợp nhất dành riêng cho bạn.',
                        textAlign: wide ? TextAlign.start : TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.75,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  );
                  final buttons = Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => context.push(AppRoutes.register),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.secondary,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        ),
                        icon: const Icon(Icons.upload_file_outlined, size: 18),
                        label: const Text('Tải CV miễn phí'),
                      ),
                      OutlinedButton(
                        onPressed: () => context.push(AppRoutes.register),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Đăng tuyển dụng'),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 18),
                          ],
                        ),
                      ),
                    ],
                  );
                  if (wide) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 672),
                            child: copy,
                          ),
                        ),
                        const SizedBox(width: 32),
                        buttons,
                      ],
                    );
                  }
                  return Column(
                    children: [copy, const SizedBox(height: 32), buttons],
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
