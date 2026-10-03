import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/failure.dart';
import '../../../shared/models/catalog_models.dart';
import '../viewmodels/system_config_viewmodel.dart';
import '../widgets/admin_page_shell.dart';

/// Cấu hình hệ thống (/admin/system-configurations).
///
/// Web page = header + error/success banners + ONE form card (three keys).
/// The only addition is a warning card shown while the default keys are
/// missing in Firestore (the web backend seeds them via SQL migration).
class AdminSystemConfigurationPage extends ConsumerStatefulWidget {
  const AdminSystemConfigurationPage({super.key});

  @override
  ConsumerState<AdminSystemConfigurationPage> createState() =>
      _AdminSystemConfigurationPageState();
}

class _AdminSystemConfigurationPageState extends ConsumerState<AdminSystemConfigurationPage> {
  final _maxSkills = TextEditingController();
  final _deadlineDays = TextEditingController();
  bool _requireApproval = SystemConfigNotifier.defaultRequireApproval;
  bool _seeded = false;

  static const _knownKeys = {
    SystemConfig.keyMaxSkillsPerJob,
    SystemConfig.keyDefaultDeadlineDays,
    SystemConfig.keyRequireJobApproval,
    SystemConfig.keyGeminiApiKey,
  };

  @override
  void initState() {
    super.initState();
    // Seed the form from the first loaded snapshot outside build().
    ref.listenManual<AsyncValue<List<SystemConfig>>>(
      systemConfigsProvider,
      (_, next) {
        final configs = next.valueOrNull;
        if (configs == null || _seeded || !mounted) return;
        setState(() => _seedForm(configs));
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _maxSkills.dispose();
    _deadlineDays.dispose();
    super.dispose();
  }

  static SystemConfig? _byKey(List<SystemConfig> configs, String key) {
    for (final c in configs) {
      if (c.configKey == key) return c;
    }
    return null;
  }

  /// Fill the form once from the first loaded snapshot (DEFAULT_CONFIG fallbacks).
  void _seedForm(List<SystemConfig> configs) {
    _seeded = true;
    final max = _byKey(configs, SystemConfig.keyMaxSkillsPerJob)?.asNumber;
    final days = _byKey(configs, SystemConfig.keyDefaultDeadlineDays)?.asNumber;
    final approval = _byKey(configs, SystemConfig.keyRequireJobApproval);
    _maxSkills.text = '${(max == null || max <= 0) ? SystemConfigNotifier.defaultMaxSkills : max.toInt()}';
    _deadlineDays.text =
        '${(days == null || days <= 0) ? SystemConfigNotifier.defaultDeadlineDays : days.toInt()}';
    _requireApproval = approval?.asBool ?? SystemConfigNotifier.defaultRequireApproval;
  }

  Future<void> _save() async {
    final ok = await ref.read(systemConfigNotifierProvider.notifier).save(
          maxSkillsRaw: _maxSkills.text,
          deadlineDaysRaw: _deadlineDays.text,
          requireApproval: _requireApproval,
        );
    if (ok && mounted) {
      // normalise typed numbers like the web page does after a successful save
      _maxSkills.text = '${int.parse(_maxSkills.text.trim())}';
      _deadlineDays.text = '${int.parse(_deadlineDays.text.trim())}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final configs = ref.watch(systemConfigsProvider);
    final state = ref.watch(systemConfigNotifierProvider);
    final notifier = ref.read(systemConfigNotifierProvider.notifier);

    final list = configs.valueOrNull ?? const <SystemConfig>[];
    final missingDefaults =
        configs.hasValue && _knownKeys.any((k) => _byKey(list, k) == null);

    return AdminPageShell(
      maxWidth: 896,
      children: [
        const AdminPageHeader(
          eyebrow: 'Quản trị hệ thống',
          title: 'Cấu hình hệ thống',
          subtitle: 'Quản lý các quy tắc dùng chung của hệ thống JobHub.',
        ),
        const SizedBox(height: 32),
        if (state.error != null) ...[
          AdminErrorBanner(title: 'Lỗi hệ thống', message: state.error!, onDismiss: notifier.dismissError),
          const SizedBox(height: 24),
        ],
        if (state.message != null) ...[
          AdminSuccessBanner(message: state.message!, onDismiss: notifier.dismissMessage),
          const SizedBox(height: 24),
        ],
        if (configs.isLoading && !configs.hasValue)
          const AdminStateCard(
            text: 'Đang tải cấu hình hệ thống...',
            loading: true,
            center: false,
            padding: EdgeInsets.all(24),
          )
        else if (configs.hasError)
          AdminErrorBanner(
            title: 'Lỗi hệ thống',
            message: Failure.from(configs.error!).code == 'UNKNOWN'
                ? 'Không thể xử lý cấu hình hệ thống.'
                : Failure.from(configs.error!).message,
          )
        else ...[
          if (missingDefaults) ...[
            _SeedDefaultsCard(seeding: state.seeding, onSeed: notifier.seedDefaults),
            const SizedBox(height: 24),
          ],
          _FormCard(
            maxSkills: _maxSkills,
            deadlineDays: _deadlineDays,
            requireApproval: _requireApproval,
            onApprovalChanged: (v) => setState(() => _requireApproval = v),
            saving: state.saving,
            onSave: _save,
          ),
        ],
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.maxSkills,
    required this.deadlineDays,
    required this.requireApproval,
    required this.onApprovalChanged,
    required this.saving,
    required this.onSave,
  });

  final TextEditingController maxSkills;
  final TextEditingController deadlineDays;
  final bool requireApproval;
  final ValueChanged<bool> onApprovalChanged;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.x2l),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _NumberRow(
            label: 'Số kỹ năng tối đa trong một tin',
            helper: 'Giới hạn số kỹ năng Employer được chọn khi tạo tin tuyển dụng.',
            unit: 'kỹ năng',
            controller: maxSkills,
            enabled: !saving,
          ),
          const _RowDivider(),
          _NumberRow(
            label: 'Hạn tuyển dụng mặc định',
            helper: 'Số ngày mặc định trước khi một tin tuyển dụng hết hạn.',
            unit: 'ngày',
            controller: deadlineDays,
            enabled: !saving,
          ),
          const _RowDivider(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: _FieldLabel(
                  label: 'Bắt buộc Admin duyệt tin',
                  helper: 'Khi bật, tin mới phải được Admin duyệt trước khi hiển thị.',
                ),
              ),
              const SizedBox(width: 24),
              Switch(
                value: requireApproval,
                onChanged: saving ? null : onApprovalChanged,
                activeTrackColor: AppColors.blue700,
                inactiveTrackColor: AppColors.slate300,
                inactiveThumbColor: Colors.white,
                trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink),
              children: [
                const TextSpan(text: 'Trạng thái: '),
                TextSpan(
                  text: requireApproval ? 'Đang bật' : 'Đang tắt',
                  style: TextStyle(color: requireApproval ? AppColors.green600 : AppColors.amber700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // `mt-8 flex justify-end border-t pt-6` — just the right-aligned button
          Container(
            padding: const EdgeInsets.only(top: 24),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.borderMuted)),
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: saving ? null : onSave,
                child: Text(saving ? 'Đang lưu...' : 'Lưu cấu hình'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Divider(height: 1),
      );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, required this.helper});
  final String label;
  final String helper;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
          const SizedBox(height: 4),
          Text(helper, style: const TextStyle(fontSize: 14, color: AppColors.inkMuted, height: 1.5)),
        ],
      );
}

class _NumberRow extends StatelessWidget {
  const _NumberRow({
    required this.label,
    required this.helper,
    required this.unit,
    required this.controller,
    required this.enabled,
  });

  final String label;
  final String helper;
  final String unit;
  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label: label, helper: helper),
        const SizedBox(height: 12),
        Row(
          children: [
            SizedBox(
              width: 128,
              child: TextField(
                controller: controller,
                enabled: enabled,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(hintText: '1'),
              ),
            ),
            const SizedBox(width: 12),
            Text(unit, style: const TextStyle(fontSize: 14, color: AppColors.inkMuted)),
          ],
        ),
      ],
    );
  }
}

/// Warning card shown only while the default configuration keys are missing
/// in Firestore (the web backend creates them via SQL migration).
class _SeedDefaultsCard extends StatelessWidget {
  const _SeedDefaultsCard({required this.seeding, required this.onSeed});
  final bool seeding;
  final VoidCallback onSeed;

  @override
  Widget build(BuildContext context) {
    final md = MediaQuery.sizeOf(context).width >= kAdminMdBreakpoint;
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Thiếu khoá cấu hình mặc định',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.amber700),
        ),
        SizedBox(height: 4),
        Text(
          'Tạo các khoá MAX_SKILLS_PER_JOB, DEFAULT_DEADLINE_DAYS, REQUIRE_JOB_APPROVAL và GEMINI_API_KEY nếu chưa tồn tại. Giá trị hiện có sẽ được giữ nguyên.',
          style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.amber700),
        ),
      ],
    );
    final button = OutlinedButton.icon(
      onPressed: seeding ? null : onSeed,
      icon: seeding
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.auto_fix_high_outlined, size: 18),
      label: Text(seeding ? 'Đang khởi tạo...' : 'Khởi tạo cấu hình mặc định'),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.amber50,
        border: Border.all(color: AppColors.amber200),
        borderRadius: BorderRadius.circular(AppRadius.x2l),
      ),
      child: md
          ? Row(children: [Expanded(child: text), const SizedBox(width: 16), button])
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [text, const SizedBox(height: 12), button],
            ),
    );
  }
}
