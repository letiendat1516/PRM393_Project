import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../shared/widgets/public_layout.dart';
import '../widgets/career_resources_section.dart';
import '../widgets/company_logo_grid.dart';
import '../widgets/cta_band.dart';
import '../widgets/featured_jobs_section.dart';
import '../widgets/hero_section.dart';
import '../widgets/statistics_section.dart';
import '../widgets/testimonials_section.dart';
import '../widgets/top_companies_section.dart';
import '../widgets/why_jobhub_section.dart';
import '../widgets/workflow_section.dart';

/// pages/HomePage.jsx — landing page: Hero, CompanyLogoGrid, FeaturedJobs,
/// Statistics, WhyJobHub, Workflow (ai-analysis), TopCompanies, Testimonials,
/// CareerResources, CtaBand. `?section=<id>` (navbar/footer hash links)
/// scrolls to the matching anchor after the first frame (HashScroll.jsx).
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key, this.section});
  final String? section;

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final ScrollController _scroll = ScrollController();

  static const List<String> _sectionIds = [
    AppConfig.sectionFeaturedJobs,
    AppConfig.sectionWhyJobHub,
    AppConfig.sectionAiAnalysis,
    AppConfig.sectionTopCompanies,
    AppConfig.sectionTestimonials,
    AppConfig.sectionCareerResources,
  ];

  late final Map<String, GlobalKey> _anchors = {
    for (final id in _sectionIds) id: GlobalKey(debugLabel: 'home-$id'),
  };

  @override
  void initState() {
    super.initState();
    _scheduleScroll(widget.section);
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.section != oldWidget.section) _scheduleScroll(widget.section);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scheduleScroll(String? id) {
    if (id == null || id.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollTo(id));
  }

  Future<void> _scrollTo(String id) async {
    if (!mounted) return;
    final ctx = _anchors[id]?.currentContext;
    if (ctx == null) return;
    final reduce = MediaQuery.disableAnimationsOf(context);
    await Scrollable.ensureVisible(
      ctx,
      alignment: 0,
      duration: reduce ? Duration.zero : const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PublicLayout(
      scrollController: _scroll,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const HeroSection(),
          const CompanyLogoGrid(),
          FeaturedJobsSection(key: _anchors[AppConfig.sectionFeaturedJobs]),
          const StatisticsSection(),
          WhyJobHubSection(key: _anchors[AppConfig.sectionWhyJobHub]),
          WorkflowSection(key: _anchors[AppConfig.sectionAiAnalysis]),
          TopCompaniesSection(key: _anchors[AppConfig.sectionTopCompanies]),
          TestimonialsSection(key: _anchors[AppConfig.sectionTestimonials]),
          CareerResourcesSection(
            key: _anchors[AppConfig.sectionCareerResources],
            onSeeAll: () => _scrollTo(AppConfig.sectionCareerResources),
          ),
          const CtaBand(),
        ],
      ),
    );
  }
}
