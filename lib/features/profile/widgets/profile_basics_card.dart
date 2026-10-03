import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/jobseeker_profile_model.dart';
import '../../../shared/widgets/ui_primitives.dart';
import '../viewmodels/profile_viewmodel.dart';
import 'city_field.dart';
import 'profile_form_widgets.dart';

/// ResumePage SECTION 1 — "Thông tin hồ sơ" card (fullName / headline / city).
/// The form is the source of truth after priming; missing-field banner is
/// recomputed live as the user types.
class ProfileBasicsCard extends ConsumerStatefulWidget {
  const ProfileBasicsCard({super.key, required this.profile, this.loading = false});

  final JobSeekerProfile? profile;
  final bool loading;

  @override
  ConsumerState<ProfileBasicsCard> createState() => _ProfileBasicsCardState();
}

class _ProfileBasicsCardState extends ConsumerState<ProfileBasicsCard> {
  late final TextEditingController _fullName =
      TextEditingController(text: widget.profile?.fullName ?? '');
  late final TextEditingController _headline =
      TextEditingController(text: widget.profile?.headline ?? '');
  late final TextEditingController _city =
      TextEditingController(text: widget.profile?.city?.trim() ?? '');

  @override
  void initState() {
    super.initState();
    _headline.addListener(_onChanged);
    _fullName.addListener(_onChanged);
    _city.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _fullName.dispose();
    _headline.dispose();
    _city.dispose();
    super.dispose();
  }

  List<String> get _missingFields => [
        if (_headline.text.trim().isEmpty) 'Tiêu đề hồ sơ',
        if (_city.text.trim().isEmpty) 'Địa điểm',
      ];

  Future<void> _save() async {
    await ref.read(profileViewModelProvider.notifier).saveBasics(
          fullName: _fullName.text,
          headline: _headline.text,
          city: _city.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(profileViewModelProvider);
    final missing = _missingFields;

    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeading(
            title: 'Thông tin hồ sơ',
            subtitle:
                'Những thông tin này sẽ hiển thị khi nhà tuyển dụng xem hồ sơ của bạn.',
            trailing: TextButton.icon(
              onPressed: () => context.push(AppRoutes.editProfile),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Chỉnh sửa đầy đủ'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
          if (missing.isNotEmpty) ...[
            const SizedBox(height: 16),
            StatusBanner(
              tone: BannerTone.warning,
              bordered: true,
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Cần bổ sung để ứng tuyển:',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: ' ${missing.join(', ')}.'),
                  ],
                ),
              ),
            ),
          ],
          if (vm.hasMessage) ...[
            const SizedBox(height: 16),
            StatusBanner(
              tone: vm.isSuccess ? BannerTone.success : BannerTone.error,
              text: vm.message!,
            ),
          ],
          const SizedBox(height: 16),
          if (widget.loading)
            const Text('Đang tải hồ sơ...',
                style: TextStyle(fontSize: 14, color: AppColors.inkMuted))
          else
            _buildForm(vm),
        ],
      ),
    );
  }

  Widget _buildForm(ProfileEditState vm) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth >= 1024 - 48 ? 3 : (c.maxWidth >= 640 - 48 ? 2 : 1);
        const gap = 16.0;
        final fieldWidth = (c.maxWidth - gap * (cols - 1)) / cols;

        final fields = <Widget>[
          FieldLabel(
            label: 'Họ và tên',
            child: TextField(
              controller: _fullName,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(hintText: 'Nguyễn Văn A'),
            ),
          ),
          FieldLabel(
            label: 'Tiêu đề hồ sơ',
            required: true,
            child: TextField(
              controller: _headline,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(hintText: 'VD: Backend Developer'),
            ),
          ),
          FieldLabel(
            label: 'Địa điểm',
            required: true,
            child: CityField(
              controller: _city,
              textInputAction: TextInputAction.done,
            ),
          ),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final f in fields) SizedBox(width: fieldWidth, child: f),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                onPressed: vm.saving ? null : _save,
                child: Text(vm.saving ? 'Đang lưu...' : 'Lưu thông tin'),
              ),
            ),
          ],
        );
      },
    );
  }
}
