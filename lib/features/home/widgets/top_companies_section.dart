import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/failure.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/section.dart';
import '../../../shared/widgets/ui_primitives.dart';
import '../data/home_repository.dart';
import '../viewmodels/home_providers.dart';
import 'home_layout_helpers.dart';
import 'reveal.dart';

/// HomePage.jsx §8.7 "Doanh nghiệp hàng đầu" (`id="top-companies"`, bg-white).
class TopCompaniesSection extends ConsumerWidget {
  const TopCompaniesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companies = ref.watch(topCompaniesProvider);
    return Section(
      background: AppColors.surface,
      verticalPadding: homeSectionPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Reveal(
            child: SectionHeading(
              eyebrow: 'Doanh nghiệp hàng đầu',
              title: 'Làm việc tại những công ty tốt nhất',
              description:
                  'Khám phá các doanh nghiệp uy tín đang mở rộng đội ngũ và tìm môi trường phù hợp với định hướng của bạn.',
            ),
          ),
          const SizedBox(height: 48),
          companies.when(
            skipLoadingOnReload: true,
            loading: () => const SizedBox(
              height: 200,
              child: RouteLoader(label: 'Đang tải doanh nghiệp...'),
            ),
            error: (e, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AlertError(
                  message: Failure.from(e).message,
                  onRetry: () => ref.invalidate(topCompaniesProvider),
                ),
                const SizedBox(height: 20),
                _CompaniesGrid(items: HomeRepository.demoTopCompanies()),
              ],
            ),
            data: (items) => _CompaniesGrid(items: items),
          ),
        ],
      ),
    );
  }
}

class _CompaniesGrid extends StatelessWidget {
  const _CompaniesGrid({required this.items});
  final List<TopCompanyItem> items;

  @override
  Widget build(BuildContext context) {
    return ResponsiveGrid(
      spacing: 24,
      children: [
        for (var i = 0; i < items.length; i++)
          Reveal(
            delay: Duration(milliseconds: i * 70),
            child: TopCompanyCard(company: items[i]),
          ),
      ],
    );
  }
}

/// components/company/TopCompanyCard.jsx — 128px cover with gradient overlay,
/// overlapping brand-coloured initials badge, name/industry, dl rows and a
/// full-width secondary CTA 'Xem hồ sơ công ty'.
class TopCompanyCard extends StatefulWidget {
  const TopCompanyCard({super.key, required this.company});
  final TopCompanyItem company;

  @override
  State<TopCompanyCard> createState() => _TopCompanyCardState();
}

class _TopCompanyCardState extends State<TopCompanyCard> {
  bool _hover = false;

  void _open(BuildContext context) {
    final c = widget.company;
    if (c.isLive) {
      context.push(AppRoutes.companyDetailOf(c.id));
    } else {
      context.push(Uri(path: AppRoutes.jobs, queryParameters: {'q': c.name}).toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.company;
    final (badgeBg, badgeFg) = c.brand != null
        ? CompanyPalette.fromTailwind(c.brand)
        : CompanyPalette.at(CompanyDisplay.of(c.name).paletteIndex);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        clipBehavior: Clip.antiAlias,
        transform: Matrix4.translationValues(0, _hover ? -4 : 0, 0),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.x2l),
          border: Border.all(color: AppColors.borderMuted),
          boxShadow: _hover ? AppShadows.elevated : AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                SizedBox(height: 128, child: HomeAssetImage(c.cover)),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [AppColors.primary900.withValues(alpha: 0.4), Colors.transparent],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  bottom: -24,
                  child: Container(
                    width: 56,
                    height: 56,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: AppShadows.soft,
                    ),
                    alignment: Alignment.center,
                    child: (c.logoUrl != null && c.logoUrl!.isNotEmpty)
                        ? Image.network(
                            c.logoUrl!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => _initials(c.initials, badgeFg),
                          )
                        : _initials(c.initials, badgeFg),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontFamily: DefaultTextStyle.of(context).style.fontFamily,
                        color: _hover ? AppColors.primary : AppColors.ink,
                      ),
                      child: Text(c.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(height: 4),
                    Text(c.industry, style: const TextStyle(fontSize: 14, color: AppColors.inkSoft)),
                    const SizedBox(height: 16),
                    _row(Icons.place_outlined, Text(c.location)),
                    const SizedBox(height: 8),
                    _row(Icons.people_outline, Text(c.size)),
                    const SizedBox(height: 8),
                    _row(
                      Icons.work_outline,
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${c.openPositions}',
                              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.secondary),
                            ),
                            const TextSpan(text: ' việc làm đang tuyển'),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => _open(context),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Xem hồ sơ công ty'),
                            SizedBox(width: 6),
                            Icon(Icons.north_east, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _initials(String s, Color fg) =>
      Text(s, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: fg));

  Widget _row(IconData icon, Widget text) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DefaultTextStyle.merge(
              style: const TextStyle(fontSize: 14, color: AppColors.inkSoft, height: 1.5),
              child: text,
            ),
          ),
        ],
      );
}
