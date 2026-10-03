import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/services/system_config_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/catalog_models.dart';
import '../viewmodels/system_config_viewmodel.dart';
import 'admin_page_shell.dart';

/// AiStatsPage "DeepSeek API Key" panel ported to Gemini: current masked key,
/// source badge, 'Kiểm tra' → GeminiService.testKey(), 'Lưu & dùng',
/// 'Dùng .env' (only while an override is stored).
class GeminiKeyPanel extends ConsumerStatefulWidget {
  const GeminiKeyPanel({super.key, required this.stored});

  /// systemConfigurations/GEMINI_API_KEY (null when never seeded).
  final SystemConfig? stored;

  @override
  ConsumerState<GeminiKeyPanel> createState() => _GeminiKeyPanelState();
}

class _GeminiKeyPanelState extends ConsumerState<GeminiKeyPanel> {
  final _controller = TextEditingController();
  bool _showKey = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(systemConfigNotifierProvider);
    final notifier = ref.read(systemConfigNotifierProvider.notifier);
    final storedValue = widget.stored?.configValue ?? '';
    final hasOverride = storedValue.isNotEmpty;
    final source = SystemConfigNotifier.sourceOf(widget.stored);
    final typed = _controller.text.trim();
    final narrow = MediaQuery.sizeOf(context).width < 640;

    final currentMasked = switch (source) {
      KeySource.env => SystemConfigRepository.masked(AppConfig.geminiApiKey),
      KeySource.override => SystemConfigRepository.masked(storedValue),
      KeySource.none => '(chưa set)',
    };

    final actions = <Widget>[
      OutlinedButton(
        onPressed: (state.keyTesting || (typed.isEmpty && source == KeySource.none))
            ? null
            : () => notifier.testKey(typed),
        style: _compact,
        child: Text(state.keyTesting ? 'Đang kiểm tra...' : 'Kiểm tra'),
      ),
      ElevatedButton(
        onPressed: (state.keySaving || typed.length < 8) ? null : () => _save(notifier, typed),
        style: _compact,
        child: Text(state.keySaving ? 'Đang lưu...' : 'Lưu & dùng'),
      ),
      if (hasOverride)
        OutlinedButton(
          onPressed: state.keySaving ? null : () => _clear(notifier),
          style: _compact,
          child: Text(AppConfig.geminiApiKey.isNotEmpty ? 'Dùng .env' : 'Xoá key'),
        ),
    ];

    final input = TextField(
      controller: _controller,
      obscureText: !_showKey,
      autocorrect: false,
      enableSuggestions: false,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Dán Gemini API key mới (AIza...)',
        suffixIcon: TextButton(
          onPressed: () => setState(() => _showKey = !_showKey),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: Size.zero,
            textStyle: const TextStyle(fontSize: 12),
            foregroundColor: AppColors.inkMuted,
          ),
          child: Text(_showKey ? 'Ẩn' : 'Hiện'),
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderMuted),
        borderRadius: BorderRadius.circular(AppRadius.x2l),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary50,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.shield_outlined, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Gemini API key',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
                    const SizedBox(height: 2),
                    const Text(
                      'Đổi key khi hết hạn — áp dụng ngay, không cần sửa code hay restart backend.',
                      style: TextStyle(fontSize: 12, color: AppColors.inkSoft, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _SourceBadge(source: source),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.slate50,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text.rich(
              TextSpan(
                style: const TextStyle(fontSize: 14, color: AppColors.inkMuted),
                children: [
                  const TextSpan(text: 'Key hiện tại: '),
                  TextSpan(
                    text: currentMasked,
                    style: const TextStyle(
                        fontFamily: 'monospace',
                        fontFamilyFallback: ['Consolas', 'Menlo', 'Courier New'],
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink),
                  ),
                  if (widget.stored?.updatedAt != null && hasOverride)
                    TextSpan(
                      text: '  · cập nhật ${Formatters.localeDateTime(widget.stored!.updatedAt!)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (narrow) ...[
            input,
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: actions),
          ] else
            Row(
              children: [
                Expanded(child: input),
                const SizedBox(width: 8),
                for (final a in actions) ...[a, const SizedBox(width: 8)],
              ],
            ),
          if (state.keyTestResult != null) ...[
            const SizedBox(height: 12),
            _ResultBanner(
              ok: state.keyTestResult!.valid,
              icon: state.keyTestResult!.valid ? Icons.check_circle_outline : Icons.close,
              text: state.keyTestResult!.valid
                  ? 'Key hợp lệ ✓ (${state.keyTestResult!.latencyMs}ms)'
                  : 'Key KHÔNG hợp lệ — ${state.keyTestResult!.error ?? 'kiểm tra lại'}',
            ),
          ],
          if (state.keyMessage != null) ...[
            const SizedBox(height: 12),
            _ResultBanner(
              ok: state.keyMessage!.type == KeyMessageType.success,
              text: state.keyMessage!.text,
            ),
          ],
        ],
      ),
    );
  }

  ButtonStyle get _compact => ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(0, 42)),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16)),
        textStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      );

  Future<void> _save(SystemConfigNotifier notifier, String typed) async {
    final ok = await notifier.saveKey(typed);
    if (ok && mounted) _controller.clear();
  }

  Future<void> _clear(SystemConfigNotifier notifier) async {
    final ok = await showConfirmDialog(
      context,
      message: AppConfig.geminiApiKey.isNotEmpty
          ? 'Xoá override, dùng lại key trong .env?'
          : 'Xoá Gemini API key đã lưu? Các tính năng AI sẽ ngừng hoạt động cho đến khi có key mới.',
      confirmLabel: 'Xoá',
      danger: true,
    );
    // the panel may have been disposed while the confirm dialog was open
    if (ok && mounted) await notifier.clearKey();
  }
}

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.source});
  final KeySource source;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (source) {
      KeySource.override => ('Override', AppColors.violet50, AppColors.violet600),
      KeySource.env => ('Từ .env', AppColors.green50, AppColors.green600),
      KeySource.none => ('Chưa set', AppColors.red50, AppColors.red600),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.ok, required this.text, this.icon});
  final bool ok;
  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fg = ok ? AppColors.emerald700 : AppColors.red600;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ok ? AppColors.green50 : AppColors.red50,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          if (icon != null) ...[Icon(icon, size: 16, color: fg), const SizedBox(width: 8)],
          Expanded(child: Text(text, style: TextStyle(fontSize: 14, color: fg))),
        ],
      ),
    );
  }
}
