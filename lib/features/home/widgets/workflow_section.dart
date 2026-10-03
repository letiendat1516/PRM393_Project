import 'package:flutter/material.dart';

import '../../../core/data/demo_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_icons.dart';
import '../../../shared/widgets/section.dart';
import 'home_layout_helpers.dart';
import 'reveal.dart';

/// components/workflow/WorkflowSection.jsx (`id="ai-analysis"`, bg-white):
/// photo card with floating "CV của bạn đã được phân tích" banner on the left,
/// left-aligned heading + 5 numbered step cards on the right.
class WorkflowSection extends StatelessWidget {
  const WorkflowSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Section(
      background: AppColors.surface,
      verticalPadding: homeSectionPadding(context),
      child: LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth >= 900;
        if (wide) {
          return const Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _WorkflowPhoto()),
              SizedBox(width: 64),
              Expanded(child: _WorkflowSteps()),
            ],
          );
        }
        // order-last lg:order-first → photo after the steps on phones
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _WorkflowSteps(),
            const SizedBox(height: 48),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 448),
                child: const _WorkflowPhoto(),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _WorkflowPhoto extends StatelessWidget {
  const _WorkflowPhoto();

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 640;
    final inset = wide ? 40.0 : 24.0;
    return Reveal(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: AppShadows.elevated,
              ),
              child: const AspectRatio(
                aspectRatio: 4 / 3,
                child: HomeAssetImage(DemoData.workflowImage),
              ),
            ),
            Positioned(
              left: inset,
              right: inset,
              bottom: -20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(AppRadius.x2l),
                  border: Border.all(color: AppColors.borderMuted),
                  boxShadow: AppShadows.card,
                ),
                child: const Row(
                  children: [
                    IconTile(
                      icon: Icons.description_outlined,
                      background: AppColors.secondary50,
                      foreground: AppColors.secondary,
                      size: 44,
                      iconSize: 22,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'CV của bạn đã được phân tích',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Kỹ năng & kinh nghiệm được trích xuất tự động',
                            style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
                          ),
                        ],
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
}

class _WorkflowSteps extends StatelessWidget {
  const _WorkflowSteps();

  @override
  Widget build(BuildContext context) {
    final steps = DemoData.workflowSteps;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Reveal(
          child: SectionHeading(
            eyebrow: 'AI Resume Analysis',
            title: 'Hành trình từ CV đến cơ hội việc làm',
            description:
                'Chỉ với một lần tải CV, JobHub tự động phân tích, trích xuất thông tin và so khớp bạn với những việc làm phù hợp nhất.',
            center: false,
          ),
        ),
        const SizedBox(height: 32),
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == steps.length - 1 ? 0 : 20),
            child: Reveal(
              delay: Duration(milliseconds: i * 60),
              child: WorkflowStepCard(step: steps[i], index: i + 1),
            ),
          ),
      ],
    );
  }
}

/// Step card: canvas surface, primary icon tile with the numbered secondary
/// badge overlapping its top-right corner, title + description.
class WorkflowStepCard extends StatelessWidget {
  const WorkflowStepCard({super.key, required this.step, required this.index});
  final WorkflowStep step;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppRadius.x2l),
        border: Border.all(color: AppColors.borderMuted),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconTile(
                icon: AppIcons.of(step.icon),
                background: AppColors.primary,
                foreground: Colors.white,
                size: 44,
                iconSize: 22,
              ),
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(
                    '$index',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white, height: 1),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
                const SizedBox(height: 4),
                Text(
                  step.description,
                  style: const TextStyle(fontSize: 14, height: 1.7, color: AppColors.inkSoft),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
