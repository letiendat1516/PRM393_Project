import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/failure.dart';
import '../../../shared/models/catalog_models.dart';
import '../../../shared/widgets/ui_primitives.dart';
import '../../auth/viewmodels/current_user_provider.dart';

/// Admin → AI Logs → DeepSeek + z.ai keys + provider order.
///
/// Lightweight sibling of [GeminiKeyPanel] — one row per field, direct
/// writes to systemConfigurations via [systemConfigRepositoryProvider]
/// without going through a dedicated StateNotifier. The AI client picks
/// up the new keys / order on the next call (both are resolved on each
/// chatCompletion through the resolver closures in providers.dart).
class AiProvidersPanel extends ConsumerStatefulWidget {
  const AiProvidersPanel({
    super.key,
    required this.deepseekKey,
    required this.zaiKey,
    required this.providerOrder,
  });

  final String? deepseekKey;
  final String? zaiKey;
  final String? providerOrder;

  @override
  ConsumerState<AiProvidersPanel> createState() => _AiProvidersPanelState();
}

class _AiProvidersPanelState extends ConsumerState<AiProvidersPanel> {
  late final TextEditingController _deepseek =
      TextEditingController(text: widget.deepseekKey ?? '');
  late final TextEditingController _zai =
      TextEditingController(text: widget.zaiKey ?? '');
  late final TextEditingController _order = TextEditingController(
      text: widget.providerOrder ?? AppConfig.aiProviderOrderDefault);

  bool _busy = false;
  String? _success;
  String? _error;

  @override
  void didUpdateWidget(covariant AiProvidersPanel old) {
    super.didUpdateWidget(old);
    if (old.deepseekKey != widget.deepseekKey && !_deepseek.text.contains('…')) {
      _deepseek.text = widget.deepseekKey ?? '';
    }
    if (old.zaiKey != widget.zaiKey && !_zai.text.contains('…')) {
      _zai.text = widget.zaiKey ?? '';
    }
    if (old.providerOrder != widget.providerOrder) {
      _order.text = widget.providerOrder ?? AppConfig.aiProviderOrderDefault;
    }
  }

  @override
  void dispose() {
    _deepseek.dispose();
    _zai.dispose();
    _order.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    final uid = ref.read(currentUidProvider);
    setState(() {
      _busy = true;
      _error = null;
      _success = null;
    });
    try {
      final repo = ref.read(systemConfigRepositoryProvider);
      await repo.ensureDefaults();

      // Normalize the order CSV: whitelist to known providers, dedupe,
      // fall back to the default if the user wiped the field.
      final allowed = {'gemini', 'deepseek', 'zai'};
      final seen = <String>{};
      final normalized = <String>[];
      for (final raw in _order.text.split(',')) {
        final p = raw.trim().toLowerCase();
        if (!allowed.contains(p)) continue;
        if (seen.add(p)) normalized.add(p);
      }
      final orderCsv = normalized.isEmpty
          ? AppConfig.aiProviderOrderDefault
          : normalized.join(',');
      _order.text = orderCsv;

      await Future.wait([
        repo.update(SystemConfig.keyDeepseekApiKey, _deepseek.text.trim(),
            updatedBy: uid),
        repo.update(SystemConfig.keyZaiApiKey, _zai.text.trim(), updatedBy: uid),
        repo.update(SystemConfig.keyAiProviderOrder, orderCsv,
            updatedBy: uid),
      ]);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _success = 'Đã lưu — các lời gọi AI tiếp theo sẽ dùng cấu hình mới.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = Failure.from(e).message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.hub_outlined, size: 20, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Nhà cung cấp AI khác',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Khi Gemini quá tải, GeminiService tự fallback sang DeepSeek / z.ai '
            'theo thứ tự ở "Thứ tự thử". Để trống key của provider nào thì sẽ bỏ qua.',
            style: TextStyle(fontSize: 12, color: AppColors.inkMuted, height: 1.5),
          ),
          const SizedBox(height: 20),
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.red50,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.dangerBorder),
              ),
              child: Text(_error!,
                  style: const TextStyle(
                      color: AppColors.danger, fontSize: 13)),
            ),
            const SizedBox(height: 12),
          ],
          if (_success != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.green50,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: AppColors.green500.withValues(alpha: 0.3),
                ),
              ),
              child: Text(_success!,
                  style: const TextStyle(
                      color: AppColors.green500, fontSize: 13)),
            ),
            const SizedBox(height: 12),
          ],
          _LabeledField(
            label: 'DeepSeek API key',
            hint: 'sk-…',
            controller: _deepseek,
            enabled: !_busy,
            obscure: true,
          ),
          const SizedBox(height: 16),
          _LabeledField(
            label: 'z.ai API key (Zhipu GLM)',
            hint: '…',
            controller: _zai,
            enabled: !_busy,
            obscure: true,
          ),
          const SizedBox(height: 16),
          _LabeledField(
            label: 'Thứ tự thử (CSV)',
            hint: 'gemini,deepseek,zai',
            controller: _order,
            enabled: !_busy,
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _busy ? null : _save,
              icon: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_outlined, size: 18),
              label: Text(_busy ? 'Đang lưu…' : 'Lưu cấu hình'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    required this.enabled,
    this.hint,
    this.obscure = false,
  });

  final String label;
  final TextEditingController controller;
  final bool enabled;
  final String? hint;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.ink)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 12),
            isDense: true,
          ),
        ),
      ],
    );
  }
}
