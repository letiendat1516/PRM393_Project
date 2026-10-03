import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/nav.dart';
import 'brand.dart';
import 'section.dart';

/// components/footer/Footer.jsx — brand blurb + 4 link groups + bottom bar.
class WebFooter extends StatelessWidget {
  const WebFooter({super.key});

  // Footer.jsx `groups` — hash links map to HomePage `?section=` anchors.
  static const _why = '/?section=${AppConfig.sectionWhyJobHub}';
  static const _career = '/?section=${AppConfig.sectionCareerResources}';
  static const _ai = '/?section=${AppConfig.sectionAiAnalysis}';

  static const _groups = <_LinkGroup>[
    _LinkGroup('Công ty', [
      _LinkItem('Giới thiệu JobHub', _why),
      _LinkItem('Tuyển dụng', _why),
      _LinkItem('Tin tức', _career),
      _LinkItem('Liên hệ', _why),
    ]),
    _LinkGroup('Sản phẩm', [
      _LinkItem('Tìm việc làm', AppRoutes.jobs),
      _LinkItem('Hồ sơ & CV', _ai),
      _LinkItem('Dành cho doanh nghiệp', AppRoutes.register),
      _LinkItem('Gợi ý việc làm AI', _ai),
    ]),
    _LinkGroup('Hỗ trợ', [
      _LinkItem('Trung tâm trợ giúp', _why),
      _LinkItem('Câu hỏi thường gặp', _why),
      _LinkItem('Hướng dẫn sử dụng', _career),
      _LinkItem('Báo cáo vấn đề', _why),
    ]),
    _LinkGroup('Pháp lý', [
      _LinkItem('Điều khoản dịch vụ', _why),
      _LinkItem('Chính sách bảo mật', _why),
      _LinkItem('Chính sách cookie', _why),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final wide = width >= 1024;
    final year = DateTime.now().year;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 56),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: PageContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(builder: (ctx, c) {
              // grid-cols-2 (phone) · lg: brand col-span-2 + 4 groups.
              final spacing = wide ? 40.0 : 24.0;
              final brandWidth = wide ? 320.0 : c.maxWidth;
              final groupWidth = wide
                  ? ((c.maxWidth - brandWidth - spacing * 4) / 4).clamp(140.0, 260.0)
                  : (c.maxWidth - spacing) / 2;
              return Wrap(
                spacing: spacing,
                runSpacing: 32,
                children: [
                  SizedBox(
                    width: brandWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const BrandLogo(),
                        const SizedBox(height: 14),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: const Text(
                            'JobHub — nền tảng tuyển dụng thông minh ứng dụng AI, kết nối ứng viên với doanh nghiệp thông qua việc làm phù hợp nhất.',
                            style: TextStyle(color: AppColors.inkSoft, fontSize: 14, height: 1.75),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(children: [
                          _social(ctx, Icons.work_outline, 'LinkedIn'),
                          const SizedBox(width: 8),
                          _social(ctx, Icons.facebook, 'Facebook'),
                          const SizedBox(width: 8),
                          _social(ctx, Icons.ondemand_video, 'YouTube'),
                        ]),
                      ],
                    ),
                  ),
                  for (final g in _groups) SizedBox(width: groupWidth, child: _LinkGroupWidget(group: g)),
                ],
              );
            }),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.only(top: 24),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.borderMuted)),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 8,
                children: [
                  Text('© $year JobHub. Mọi quyền được bảo lưu.',
                      style: const TextStyle(color: AppColors.inkMuted, fontSize: 12)),
                  Row(mainAxisSize: MainAxisSize.min, children: const [
                    Icon(Icons.mail_outline, size: 14, color: AppColors.inkMuted),
                    SizedBox(width: 6),
                    Text(AppConfig.supportEmail, style: TextStyle(color: AppColors.inkMuted, fontSize: 12)),
                    SizedBox(width: 16),
                    Icon(Icons.phone_outlined, size: 14, color: AppColors.inkMuted),
                    SizedBox(width: 6),
                    Text(AppConfig.supportPhone, style: TextStyle(color: AppColors.inkMuted, fontSize: 12)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Footer.jsx socials: href="/#why-jobhub", aria-label "JobHub trên {label}".
  Widget _social(BuildContext context, IconData icon, String label) => Tooltip(
        message: 'JobHub trên $label',
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => context.pushIfDifferent(_why),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppColors.inkSoft),
          ),
        ),
      );
}

class _LinkItem {
  const _LinkItem(this.label, this.route);
  final String label;
  final String route;
}

class _LinkGroup {
  const _LinkGroup(this.title, this.items);
  final String title;
  final List<_LinkItem> items;
}

class _LinkGroupWidget extends StatelessWidget {
  const _LinkGroupWidget({required this.group});
  final _LinkGroup group;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(group.title,
            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink, fontSize: 14)),
        const SizedBox(height: 14),
        for (final it in group.items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () => context.pushIfDifferent(it.route),
              child: Text(it.label, style: const TextStyle(color: AppColors.inkSoft, fontSize: 13)),
            ),
          ),
      ],
    );
  }
}
