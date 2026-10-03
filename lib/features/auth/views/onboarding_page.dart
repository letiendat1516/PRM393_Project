import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/brand.dart';
import '../widgets/onboarding_slide.dart';

/// OnboardingPage — /onboarding (docs/FLUTTER_REBUILD_PLAN.md: "3 slide
/// intro", shown on first launch via PrefsService.isFirstLaunch).
/// No navbar/footer; 'Bỏ qua' or the last 'Bắt đầu' marks onboarding done
/// and continues to the home page.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  static const slides = [
    OnboardingSlideData(
      icon: Icons.auto_awesome,
      image: 'assets/images/resume-candidate.jpg',
      eyebrow: 'Ứng viên',
      title: 'Tìm việc bằng AI',
      description:
          'Tải CV lên, JobHub đọc hiểu kỹ năng và kinh nghiệm thực tế của bạn rồi chấm điểm '
          'mức độ phù hợp với từng tin tuyển dụng — thay vì chỉ tìm theo từ khoá.',
    ),
    OnboardingSlideData(
      icon: Icons.track_changes_outlined,
      image: 'assets/images/job-interview.jpg',
      eyebrow: 'Theo dõi',
      title: 'Theo dõi hồ sơ realtime',
      description:
          'Biết ngay khi nhà tuyển dụng xem hồ sơ, mời phỏng vấn hay gửi offer. '
          'Mọi thay đổi trạng thái được cập nhật tức thì kèm thông báo đẩy.',
    ),
    OnboardingSlideData(
      icon: Icons.fact_check_outlined,
      image: 'assets/images/team-meeting.jpg',
      eyebrow: 'Nhà tuyển dụng',
      title: 'Nhà tuyển dụng duyệt nhanh',
      description:
          'Đăng tin trong vài phút, nhận ứng viên đã được AI xếp hạng và duyệt hồ sơ '
          'theo từng vòng — trao đổi trực tiếp với ứng viên tiềm năng.',
    ),
  ];

  final _controller = PageController();
  int _index = 0;
  bool _finishing = false;

  bool get _isLast => _index == slides.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    try {
      await ref.read(prefsServiceProvider).setOnboardingDone(true);
    } catch (_) {
      // Preference write failures must never block entering the app.
    }
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  void _next() {
    if (_isLast) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 900;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isWide ? 48 : 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header: brand + "Bỏ qua".
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const BrandLogo(),
                      TextButton(
                        onPressed: _finishing ? null : _finish,
                        child: const Text('Bỏ qua'),
                      ),
                    ],
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: slides.length,
                      onPageChanged: (i) => setState(() => _index = i),
                      itemBuilder: (_, i) => OnboardingSlide(
                        data: slides[i],
                        isWide: isWide,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Dots + CTA.
                  _Footer(
                    count: slides.length,
                    index: _index,
                    isLast: _isLast,
                    busy: _finishing,
                    isWide: isWide,
                    onNext: _next,
                    onDot: (i) => _controller.animateToPage(
                      i,
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                    ),
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

class _Footer extends StatelessWidget {
  const _Footer({
    required this.count,
    required this.index,
    required this.isLast,
    required this.busy,
    required this.isWide,
    required this.onNext,
    required this.onDot,
  });

  final int count;
  final int index;
  final bool isLast;
  final bool busy;
  final bool isWide;
  final VoidCallback onNext;
  final ValueChanged<int> onDot;

  @override
  Widget build(BuildContext context) {
    final dots = Row(
      mainAxisAlignment: isWide ? MainAxisAlignment.start : MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          GestureDetector(
            onTap: () => onDot(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOut,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i == index ? 28 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == index ? AppColors.primary : AppColors.primary200,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
      ],
    );

    final cta = SizedBox(
      height: 50,
      width: isWide ? 240 : double.infinity,
      child: ElevatedButton(
        onPressed: busy ? null : onNext,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isLast ? 'Bắt đầu' : 'Tiếp tục'),
            const SizedBox(width: 8),
            Icon(isLast ? Icons.rocket_launch_outlined : Icons.arrow_forward, size: 18),
          ],
        ),
      ),
    );

    if (isWide) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [dots, cta],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          dots,
          const SizedBox(height: 20),
          cta,
        ],
      ),
    );
  }
}
