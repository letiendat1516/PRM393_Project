import 'package:flutter/material.dart';

import '../../../core/data/demo_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/section.dart';
import 'home_layout_helpers.dart';
import 'reveal.dart';

/// components/company/CompanyLogoGrid.jsx — trusted-by strip of muted
/// typographic wordmarks (2 → 4 → 8 columns).
class CompanyLogoGrid extends StatelessWidget {
  const CompanyLogoGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.borderMuted),
          bottom: BorderSide(color: AppColors.borderMuted),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: PageContainer(
        child: Column(
          children: [
            Reveal(
              child: Text(
                'Được tin dùng bởi các doanh nghiệp hàng đầu tại Việt Nam'.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                  color: AppColors.inkMuted,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Reveal(
              delay: const Duration(milliseconds: 100),
              child: ResponsiveGrid(
                columnsFor: (w) => w >= 900 ? 8 : (w >= 600 ? 4 : 2),
                spacing: 24,
                children: [
                  for (final name in DemoData.trustedCompanies) _Wordmark(name: name),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Wordmark extends StatefulWidget {
  const _Wordmark({required this.name});
  final String name;

  @override
  State<_Wordmark> createState() => _WordmarkState();
}

class _WordmarkState extends State<_Wordmark> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            fontFamily: DefaultTextStyle.of(context).style.fontFamily,
            color: _hover ? AppColors.primary : AppColors.inkMuted.withValues(alpha: 0.8),
          ),
          child: Text(widget.name, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
