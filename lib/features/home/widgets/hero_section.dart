import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/demo_data.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/section.dart';
import 'hero_search_bar.dart';
import 'home_layout_helpers.dart';
import 'reveal.dart';

/// components/hero/Hero.jsx — gradient hero, 7/5 grid at lg, eyebrow,
/// headline with highlighted "đúng công việc", SearchBar, CTAs, trust row and
/// the photo card with two floating glass stat chips.
class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 1024;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xB3EFF6FC), AppColors.canvas, AppColors.canvas],
          stops: [0, 0.6, 1],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            left: -96,
            top: 40,
            child: DecorBlob(color: AppColors.primary200.withValues(alpha: 0.4)),
          ),
          Positioned(
            right: -40,
            top: 160,
            child: DecorBlob(color: AppColors.secondary200.withValues(alpha: 0.4)),
          ),
          Padding(
            padding: EdgeInsets.only(top: wide ? 72 : 48, bottom: wide ? 96 : 64),
            child: PageContainer(
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(flex: 7, child: _HeroCopy(width: width)),
                        const SizedBox(width: 32),
                        const Expanded(flex: 5, child: _HeroImageCard()),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _HeroCopy(width: width),
                        const SizedBox(height: 48),
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 448),
                            child: const _HeroImageCard(),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({required this.width});
  final double width;

  @override
  Widget build(BuildContext context) {
    final h1Size = width >= 1024 ? 54.0 : (width >= 640 ? 48.0 : 36.0);
    return Reveal(
      immediate: true,
      offsetY: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Eyebrow(label: 'Nền tảng tuyển dụng ứng dụng AI', icon: Icons.auto_awesome),
          const SizedBox(height: 20),
          Text.rich(
            const TextSpan(
              children: [
                TextSpan(text: 'Tìm '),
                TextSpan(text: 'đúng công việc', style: TextStyle(color: AppColors.primary)),
                TextSpan(text: ' phù hợp với năng lực của bạn.'),
              ],
            ),
            style: TextStyle(
              fontSize: h1Size,
              fontWeight: FontWeight.w800,
              height: 1.12,
              letterSpacing: -1,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 576),
            child: Text(
              'JobHub ứng dụng trí tuệ nhân tạo để phân tích CV, hiểu rõ điểm mạnh của bạn và đề xuất '
              'những cơ hội nghề nghiệp phù hợp nhất — giúp bạn ứng tuyển nhanh và tự tin hơn.',
              style: TextStyle(
                fontSize: width >= 640 ? 18 : 16,
                height: 1.6,
                color: AppColors.inkSoft,
              ),
            ),
          ),
          const SizedBox(height: 32),
          const HeroSearchBar(),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => context.push(AppRoutes.resumeProfile),
                icon: const Icon(Icons.upload_file_outlined, size: 18),
                label: const Text('Tải CV của bạn'),
              ),
              OutlinedButton(
                onPressed: () => context.push(AppRoutes.jobs),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Khám phá việc làm'),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 36),
          const _TrustRow(),
        ],
      ),
    );
  }
}

/// Overlapping avatar stack + 5 secondary stars + "Được 150.000+ ứng viên tin tưởng".
class _TrustRow extends StatelessWidget {
  const _TrustRow();

  @override
  Widget build(BuildContext context) {
    const avatars = DemoData.heroAvatars;
    const size = 40.0;
    const overlap = 12.0;
    return Row(
      children: [
        SizedBox(
          width: size + (avatars.length - 1) * (size - overlap),
          height: size,
          child: Stack(
            children: [
              for (var i = avatars.length - 1; i >= 0; i--)
                Positioned(
                  left: i * (size - overlap),
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: AppShadows.soft,
                      color: AppColors.primary100,
                      image: DecorationImage(image: AssetImage(avatars[i]), fit: BoxFit.cover),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 5; i++)
                    const Padding(
                      padding: EdgeInsets.only(right: 2),
                      child: Icon(Icons.star_rounded, size: 16, color: AppColors.secondary),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'Được '),
                    TextSpan(
                      text: '150.000+',
                      style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink),
                    ),
                    TextSpan(text: ' ứng viên tin tưởng'),
                  ],
                ),
                style: TextStyle(fontSize: 14, color: AppColors.inkSoft),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Right column: rounded-[1.75rem] photo card + floating stat chips.
class _HeroImageCard extends StatelessWidget {
  const _HeroImageCard();

  @override
  Widget build(BuildContext context) {
    final showFloating = MediaQuery.sizeOf(context).width >= 640;
    return Reveal(
      immediate: true,
      delay: const Duration(milliseconds: 100),
      child: Padding(
        // room for the floating chips that overflow the card edges
        padding: EdgeInsets.only(bottom: showFloating ? 20 : 0, left: showFloating ? 16 : 0),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
                boxShadow: AppShadows.elevated,
              ),
              child: const AspectRatio(
                aspectRatio: 4 / 5,
                child: HomeAssetImage(DemoData.heroImage),
              ),
            ),
            if (showFloating) ...[
              const Positioned(
                left: -16,
                top: 40,
                child: _FloatingStat(
                  icon: Icons.gps_fixed,
                  tileBg: AppColors.secondary50,
                  tileFg: AppColors.secondary,
                  value: '95%',
                  label: 'độ chính xác gợi ý',
                  delay: Duration(milliseconds: 500),
                ),
              ),
              const Positioned(
                right: -12,
                bottom: -20,
                child: _FloatingStat(
                  icon: Icons.business_outlined,
                  tileBg: AppColors.primary50,
                  tileFg: AppColors.primary,
                  value: '10.000+',
                  label: 'doanh nghiệp đối tác',
                  delay: Duration(milliseconds: 650),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FloatingStat extends StatelessWidget {
  const _FloatingStat({
    required this.icon,
    required this.tileBg,
    required this.tileFg,
    required this.value,
    required this.label,
    required this.delay,
  });

  final IconData icon;
  final Color tileBg;
  final Color tileFg;
  final String value;
  final String label;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return Reveal(
      immediate: true,
      delay: delay,
      offsetY: 12,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(AppRadius.x2l),
          border: Border.all(color: AppColors.borderMuted),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconTile(icon: icon, background: tileBg, foreground: tileFg),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
