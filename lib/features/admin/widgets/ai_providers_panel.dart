import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers.dart';
import '../../../core/services/system_config_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/failure.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/catalog_models.dart';
import '../../auth/viewmodels/current_user_provider.dart';
import 'admin_page_shell.dart';

/// Spec for the three admin AI-key panels. Each provider gets the same
/// shape — current masked key + source badge, hint, test / save / clear
/// buttons — but reads/writes its own Firestore key and hits its own
/// `GeminiService.testProviderKey(provider)` endpoint. Replaces the
/// Gemini-only `GeminiKeyPanel` + the old mixed AiProvidersPanel.
class AiProviderSpec {
  const AiProviderSpec({
    required this.id,
    required this.label,
    required this.configKey,
    required this.envValue,
    required this.hint,
    required this.consoleUrl,
    required this.icon,
    required this.showPrefix,
  });

  final String id; // 'gemini' | 'deepseek' | 'zai'
  final String label; // 'Gemini API key'
  final String configKey; // SystemConfig.key*
  final String envValue; // AppConfig.*apiKey (empty if not set at build time)
  final String hint;
  final String consoleUrl;
  final IconData icon;
  /// Common prefix admins can expect — used only for the input hint.
  final String showPrefix;

  static const gemini = AiProviderSpec(
    id: 'gemini',
    label: 'Gemini API key',
    configKey: SystemConfig.keyGeminiApiKey,
    envValue: AppConfig.geminiApiKey,
    hint: 'Dán Gemini API key (AIza… hoặc AQ.…)',
    consoleUrl: 'https://aistudio.google.com/apikey',
    icon: Icons.shield_outlined,
    showPrefix: 'AIza',
  );

  static const deepseek = AiProviderSpec(
    id: 'deepseek',
    label: 'DeepSeek API key',
    configKey: SystemConfig.keyDeepseekApiKey,
    envValue: AppConfig.deepseekApiKey,
    hint: 'Dán DeepSeek API key (sk-…)',
    consoleUrl: 'https://platform.deepseek.com/api_keys',
    icon: Icons.flash_on_outlined,
    showPrefix: 'sk-',
  );

  static const zai = AiProviderSpec(
    id: 'zai',
    label: 'z.ai API key (Coding Plan)',
    configKey: SystemConfig.keyZaiApiKey,
    envValue: AppConfig.zaiApiKey,
    hint: 'Dán z.ai API key (Coding Plan — glm-5.3-flash). KHÔNG dùng key từ open.bigmodel.cn.',
    consoleUrl: 'https://z.ai/manage-apikey/apikey-list',
    icon: Icons.hub_outlined,
    showPrefix: '',
  );
}

/// Generic AI key panel: current masked key, "Hiện/Ẩn" toggle, three
/// actions (Kiểm tra / Lưu & dùng / Xoá key). Self-contained — writes
/// through `systemConfigRepositoryProvider`, tests via
/// `GeminiService.testProviderKey`. Each instance owns its own
/// busy / result banners so clicking "Save" on one panel doesn't
/// freeze the others.
class AiKeyPanel extends ConsumerStatefulWidget {
  const AiKeyPanel({super.key, required this.spec, required this.stored});

  final AiProviderSpec spec;
  final SystemConfig? stored;

  @override
  ConsumerState<AiKeyPanel> createState() => _AiKeyPanelState();
}

class _AiKeyPanelState extends ConsumerState<AiKeyPanel> {
  final _controller = TextEditingController();
  bool _showKey = false;
  bool _testing = false;
  bool _saving = false;
  ({bool valid, int latencyMs, String? error})? _testResult;
  _KeyMessage? _message;

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

  Future<void> _test() async {
    final typed = _controller.text.trim();
    setState(() {
      _testing = true;
      _testResult = null;
      _message = null;
    });
    try {
      final service = ref.read(geminiServiceProvider);
      final r = await service.testProviderKey(
        widget.spec.id,
        typed.isEmpty ? null : typed,
      );
      if (!mounted) return;
      setState(() {
        _testing = false;
        _testResult = (
          valid: r.valid,
          latencyMs: r.latencyMs,
          error: r.error,
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _testing = false;
        _testResult = (valid: false, latencyMs: 0, error: Failure.from(e).message);
      });
    }
  }

  Future<void> _save() async {
    final typed = _controller.text.trim();
    if (typed.length < 8) {
      setState(() => _message = _KeyMessage.error('Key phải có ít nhất 8 ký tự.'));
      return;
    }
    final uid = ref.read(currentUidProvider);
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      final repo = ref.read(systemConfigRepositoryProvider);
      await repo.update(widget.spec.configKey, typed, updatedBy: uid);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _message = _KeyMessage.success(
            'Đã lưu — các lời gọi AI tiếp theo sẽ dùng key này.');
      });
      _controller.clear();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _message = _KeyMessage.error(Failure.from(e).message);
      });
    }
  }

  Future<void> _clear() async {
    final ok = await showConfirmDialog(
      context,
      message: widget.spec.envValue.isNotEmpty
          ? 'Xoá override, dùng lại key trong .env?'
          : 'Xoá ${widget.spec.label} đã lưu? Provider này sẽ bị bỏ qua trong chuỗi fallback.',
      confirmLabel: 'Xoá',
      danger: true,
    );
    if (!ok || !mounted) return;
    final uid = ref.read(currentUidProvider);
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      final repo = ref.read(systemConfigRepositoryProvider);
      await repo.update(widget.spec.configKey, '', updatedBy: uid);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _message = _KeyMessage.success(widget.spec.envValue.isNotEmpty
            ? 'Đã revert về key trong .env.'
            : 'Đã xoá key đã lưu.');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _message = _KeyMessage.error(Failure.from(e).message);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final storedValue = widget.stored?.configValue ?? '';
    final hasOverride = storedValue.isNotEmpty;
    final hasEnv = widget.spec.envValue.isNotEmpty;
    final source = hasOverride
        ? _Source.override
        : hasEnv
            ? _Source.env
            : _Source.none;
    final typed = _controller.text.trim();
    final narrow = MediaQuery.sizeOf(context).width < 640;

    final currentMasked = switch (source) {
      _Source.env => SystemConfigRepository.masked(widget.spec.envValue),
      _Source.override => SystemConfigRepository.masked(storedValue),
      _Source.none => '(chưa set)',
    };

    final actions = <Widget>[
      OutlinedButton(
        onPressed:
            (_testing || _saving || (typed.isEmpty && source == _Source.none))
                ? null
                : _test,
        style: _compact,
        child: Text(_testing ? 'Đang kiểm tra…' : 'Kiểm tra'),
      ),
      ElevatedButton(
        onPressed: (_saving || _testing || typed.length < 8) ? null : _save,
        style: _compact,
        child: Text(_saving ? 'Đang lưu…' : 'Lưu & dùng'),
      ),
      if (hasOverride)
        OutlinedButton(
          onPressed: _saving || _testing ? null : _clear,
          style: _compact,
          child: Text(hasEnv ? 'Dùng .env' : 'Xoá key'),
        ),
    ];

    final input = TextField(
      controller: _controller,
      obscureText: !_showKey,
      autocorrect: false,
      enableSuggestions: false,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: widget.spec.hint,
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
                child: Icon(widget.spec.icon, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.spec.label,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink)),
                    const SizedBox(height: 2),
                    Text(
                      'Lấy key từ ${widget.spec.consoleUrl}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.inkSoft,
                          height: 1.5),
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
                      text:
                          '  · cập nhật ${Formatters.localeDateTime(widget.stored!.updatedAt!)}',
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
          if (_testResult != null) ...[
            const SizedBox(height: 12),
            _ResultBanner(
              ok: _testResult!.valid,
              icon: _testResult!.valid
                  ? Icons.check_circle_outline
                  : Icons.close,
              text: _testResult!.valid
                  ? 'Key hợp lệ ✓ (${_testResult!.latencyMs}ms)'
                  : 'Key KHÔNG hợp lệ — ${_testResult!.error ?? 'kiểm tra lại'}',
            ),
          ],
          if (_message != null) ...[
            const SizedBox(height: 12),
            _ResultBanner(ok: _message!.ok, text: _message!.text),
          ],
        ],
      ),
    );
  }

  ButtonStyle get _compact => ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(0, 42)),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16)),
        textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      );
}

enum _Source { env, override, none }

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.source});
  final _Source source;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (source) {
      _Source.override => ('Override', AppColors.violet50, AppColors.violet600),
      _Source.env => ('Từ .env', AppColors.green50, AppColors.green600),
      _Source.none => ('Chưa set', AppColors.red50, AppColors.red600),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
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

class _KeyMessage {
  const _KeyMessage(this.ok, this.text);
  const _KeyMessage.success(String t) : this(true, t);
  const _KeyMessage.error(String t) : this(false, t);
  final bool ok;
  final String text;
}

/// Small sidekick panel for the provider-fallback order. The AI key
/// panels are 3× [AiKeyPanel]; this one just owns the CSV editor.
class AiProviderOrderPanel extends ConsumerStatefulWidget {
  const AiProviderOrderPanel({super.key, required this.stored});
  final SystemConfig? stored;

  @override
  ConsumerState<AiProviderOrderPanel> createState() =>
      _AiProviderOrderPanelState();
}

class _AiProviderOrderPanelState extends ConsumerState<AiProviderOrderPanel> {
  late final TextEditingController _order = TextEditingController(
    text: widget.stored?.configValue ?? AppConfig.aiProviderOrderDefault,
  );
  bool _saving = false;
  _KeyMessage? _message;

  @override
  void didUpdateWidget(covariant AiProviderOrderPanel old) {
    super.didUpdateWidget(old);
    if (old.stored?.configValue != widget.stored?.configValue) {
      _order.text =
          widget.stored?.configValue ?? AppConfig.aiProviderOrderDefault;
    }
  }

  @override
  void dispose() {
    _order.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final uid = ref.read(currentUidProvider);
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      final allowed = {'gemini', 'deepseek', 'zai'};
      final seen = <String>{};
      final normalized = <String>[];
      for (final raw in _order.text.split(',')) {
        final p = raw.trim().toLowerCase();
        if (!allowed.contains(p)) continue;
        if (seen.add(p)) normalized.add(p);
      }
      final csv = normalized.isEmpty
          ? AppConfig.aiProviderOrderDefault
          : normalized.join(',');
      _order.text = csv;
      final repo = ref.read(systemConfigRepositoryProvider);
      await repo.update(SystemConfig.keyAiProviderOrder, csv, updatedBy: uid);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _message = _KeyMessage.success('Đã lưu thứ tự: $csv');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _message = _KeyMessage.error(Failure.from(e).message);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
          const Row(
            children: [
              Icon(Icons.sort, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Thứ tự fallback',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'CSV các provider sẽ thử lần lượt khi provider trước quá tải / fail. '
            'Chỉ chấp nhận: gemini, deepseek, zai.',
            style: TextStyle(fontSize: 12, color: AppColors.inkSoft, height: 1.5),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _order,
                  enabled: !_saving,
                  decoration: const InputDecoration(
                    hintText: 'gemini,deepseek,zai',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Đang lưu…' : 'Lưu thứ tự'),
              ),
            ],
          ),
          if (_message != null) ...[
            const SizedBox(height: 12),
            _ResultBanner(ok: _message!.ok, text: _message!.text),
          ],
        ],
      ),
    );
  }
}
