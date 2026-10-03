import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/recommendation_models.dart';
import '../../../shared/widgets/ui_primitives.dart';

/// One accordion row of AiLogsPage: status square, task badge + model,
/// timestamp, latency / tokens, chevron; expanded → error chip, prompt &
/// response code blocks (monospace, copy buttons), metadata line.
class AiLogTile extends StatelessWidget {
  const AiLogTile({
    super.key,
    required this.log,
    required this.expanded,
    required this.onToggle,
  });

  final AiMatchingLog log;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 640;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderMuted),
        borderRadius: BorderRadius.circular(AppRadius.x2l),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  _StatusSquare(success: log.success),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            _TaskBadge(task: log.task),
                            if (log.modelName != null)
                              Text(log.modelName!,
                                  style:
                                      const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          log.createdAt == null ? '-' : Formatters.localeDateTime(log.createdAt!),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, color: AppColors.inkSoft),
                        ),
                        if (narrow)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(_metaText,
                                style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (!narrow)
                    Text(_metaText, style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.inkMuted),
                  ),
                ],
              ),
            ),
          ),
          if (expanded) _ExpandedPanel(log: log),
        ],
      ),
    );
  }

  String get _metaText => '${log.processingTimeMs}ms · ${log.tokensIn + log.tokensOut} tok';
}

class _StatusSquare extends StatelessWidget {
  const _StatusSquare({required this.success});
  final bool success;

  @override
  Widget build(BuildContext context) => Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: success ? AppColors.green50 : AppColors.red50,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        alignment: Alignment.center,
        child: Icon(success ? Icons.check : Icons.close,
            size: 16, color: success ? AppColors.green600 : AppColors.red600),
      );
}

class _TaskBadge extends StatelessWidget {
  const _TaskBadge({required this.task});
  final String task;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.primary50,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Text(
          task.toUpperCase(),
          style: const TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary, letterSpacing: 0.3),
        ),
      );
}

class _ExpandedPanel extends StatelessWidget {
  const _ExpandedPanel({required this.log});
  final AiMatchingLog log;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borderMuted)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (log.error != null && log.error!.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.red50,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text('Lỗi: ${log.error}',
                  style: const TextStyle(fontSize: 14, color: AppColors.red600)),
            ),
            const SizedBox(height: 16),
          ],
          _CodeSection(
            title: 'Prompt',
            text: log.promptText,
            dark: true,
            copyMessage: 'Đã sao chép prompt',
          ),
          if (log.responseText.isNotEmpty) ...[
            const SizedBox(height: 16),
            _CodeSection(
              title: 'Response',
              text: log.responseText,
              dark: false,
              copyMessage: 'Đã sao chép response',
            ),
          ],
          if (log.metadata.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text.rich(
              TextSpan(
                style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
                children: [
                  const TextSpan(text: 'Metadata: ', style: TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(text: jsonEncode(log.metadata)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// `pre.max-h-60.overflow-auto` — owns its ScrollController so the always-
/// visible Scrollbar never falls back to the PrimaryScrollController (which
/// has no / several positions here → debug assertions).
class _CodeSection extends StatefulWidget {
  const _CodeSection({
    required this.title,
    required this.text,
    required this.dark,
    required this.copyMessage,
  });

  final String title;
  final String text;
  final bool dark;
  final String copyMessage;

  @override
  State<_CodeSection> createState() => _CodeSectionState();
}

class _CodeSectionState extends State<_CodeSection> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fg = widget.dark ? AppColors.slate100 : AppColors.ink;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.inkMuted,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => copyToClipboard(context, widget.text, message: widget.copyMessage),
              icon: const Icon(Icons.copy_outlined, size: 14),
              label: const Text('Sao chép'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 240),
          decoration: BoxDecoration(
            color: widget.dark ? AppColors.ink : AppColors.slate100,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Scrollbar(
            controller: _scroll,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _scroll,
              primary: false,
              padding: const EdgeInsets.all(12),
              child: SelectableText(
                widget.text,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontFamilyFallback: const ['Consolas', 'Menlo', 'Courier New'],
                  fontSize: 12,
                  height: 1.6,
                  color: fg,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
