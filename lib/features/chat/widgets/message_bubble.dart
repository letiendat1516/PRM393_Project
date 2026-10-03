import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/misc_models.dart';
import '../../settings/widgets/adaptive_colors.dart';

/// Chat bubble: mine → right, primary background; theirs → left, slate
/// (theme chip colour so dark mode stays legible).
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.mine,
    this.showTime = true,
  });

  final ChatMessage message;
  final bool mine;
  final bool showTime;

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.sizeOf(context).width * 0.72;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(AppRadius.x2l),
      topRight: const Radius.circular(AppRadius.x2l),
      bottomLeft: Radius.circular(mine ? AppRadius.x2l : AppRadius.sm),
      bottomRight: Radius.circular(mine ? AppRadius.sm : AppRadius.x2l),
    );
    final hasImage = (message.imageUrl ?? '').isNotEmpty;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth.clamp(200, 560)),
        child: Column(
          crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: hasImage ? 6 : 14, vertical: hasImage ? 6 : 10),
              decoration: BoxDecoration(
                color: mine ? AppColors.primary : context.chipColor,
                borderRadius: radius,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasImage) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      child: _BubbleImage(url: message.imageUrl!, mine: mine),
                    ),
                    if (message.content.isNotEmpty) const SizedBox(height: 6),
                  ],
                  if (message.content.isNotEmpty)
                    Padding(
                      padding: hasImage
                          ? const EdgeInsets.fromLTRB(8, 0, 8, 4)
                          : EdgeInsets.zero,
                      child: SelectableText(
                        message.content,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: mine ? Colors.white : context.inkColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (showTime)
              Padding(
                padding: const EdgeInsets.only(top: 3, left: 6, right: 6),
                child: Text(
                  message.createdAt == null ? 'Đang gửi…' : Formatters.time(message.createdAt),
                  style: TextStyle(fontSize: 11, color: context.inkMutedColor),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Network image with a sized placeholder while loading and a graceful
/// fallback when the URL is dead (Storage object deleted / bucket disabled).
class _BubbleImage extends StatelessWidget {
  const _BubbleImage({required this.url, required this.mine});
  final String url;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final fg = mine ? Colors.white70 : context.inkMutedColor;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 320, minWidth: 120, minHeight: 80),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            width: 180,
            height: 140,
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: fg),
              ),
            ),
          );
        },
        errorBuilder: (_, _, _) => SizedBox(
          width: 180,
          height: 100,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image_outlined, color: fg),
              const SizedBox(height: 6),
              Text('Không tải được ảnh', style: TextStyle(fontSize: 12, color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Hôm nay" / "Hôm qua" / dd/MM/yyyy divider between days.
class DaySeparator extends StatelessWidget {
  const DaySeparator({super.key, required this.day});
  final DateTime day;

  static String labelFor(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);
    final diff = today.difference(target).inDays;
    if (diff == 0) return 'Hôm nay';
    if (diff == 1) return 'Hôm qua';
    return Formatters.date(d);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              labelFor(day),
              style: TextStyle(
                  fontSize: 11, color: context.inkMutedColor, fontWeight: FontWeight.w600),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}
