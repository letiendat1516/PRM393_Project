import 'package:flutter/material.dart';

import '../../../core/data/demo_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/section.dart';
import 'home_layout_helpers.dart';
import 'reveal.dart';

/// HomePage.jsx §8.10 "Cẩm nang nghề nghiệp" (`id="career-resources"`,
/// bg-white): split header + 'Xem tất cả bài viết' (web links to
/// `/#career-resources`, i.e. this very section) and a grid of BlogCards.
class CareerResourcesSection extends StatelessWidget {
  const CareerResourcesSection({super.key, required this.onSeeAll});
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Section(
      background: AppColors.surface,
      verticalPadding: homeSectionPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Reveal(
            child: SplitSectionHeader(
              eyebrow: 'Cẩm nang nghề nghiệp',
              title: 'Kiến thức giúp bạn phát triển sự nghiệp',
              description:
                  'Những bài viết và hướng dẫn thực tế về viết CV, phỏng vấn và phát triển nghề nghiệp.',
              actionLabel: 'Xem tất cả bài viết',
              onAction: onSeeAll,
            ),
          ),
          const SizedBox(height: 40),
          ResponsiveGrid(
            spacing: 24,
            children: [
              for (var i = 0; i < DemoData.blogPosts.length; i++)
                Reveal(
                  delay: Duration(milliseconds: i * 70),
                  child: BlogCard(post: DemoData.blogPosts[i]),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// components/blog/BlogCard.jsx — 16:10 cover (scales on hover) with the
/// category pill overlay, bold title, excerpt, read-time + date footer.
class BlogCard extends StatefulWidget {
  const BlogCard({super.key, required this.post});
  final BlogPost post;

  @override
  State<BlogCard> createState() => _BlogCardState();
}

class _BlogCardState extends State<BlogCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
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
              children: [
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: ClipRect(
                    child: AnimatedScale(
                      scale: _hover ? 1.05 : 1,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                      child: HomeAssetImage(post.cover),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  top: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      boxShadow: AppShadows.soft,
                    ),
                    child: Text(
                      post.category,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                        fontFamily: DefaultTextStyle.of(context).style.fontFamily,
                        color: _hover ? AppColors.primary : AppColors.ink,
                      ),
                      child: Text(post.title),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        post.excerpt,
                        style: const TextStyle(fontSize: 14, height: 1.6, color: AppColors.inkSoft),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.only(top: 16),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: AppColors.borderMuted)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.schedule_outlined, size: 14, color: AppColors.inkMuted),
                              const SizedBox(width: 6),
                              Text(post.readTime, style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                            ],
                          ),
                          Text(post.date, style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
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
