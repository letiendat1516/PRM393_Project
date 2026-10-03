import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/failure.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/models/jobseeker_profile_model.dart';
import '../../../shared/widgets/public_layout.dart';
import '../../../shared/widgets/section.dart';
import '../../../shared/widgets/ui_primitives.dart';
import '../viewmodels/profile_providers.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../widgets/city_field.dart';
import '../widgets/education_editor.dart';
import '../widgets/profile_form_widgets.dart';
import '../widgets/skills_editor.dart';
import '../widgets/work_experience_editor.dart';

/// /ho-so/chinh-sua — full PUT /job-seekers/me editor (mobile-plan screen):
/// scalar fields + skills / workExperiences / educations with replace-all
/// semantics.
class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _headline = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _summary = TextEditingController();
  final _city = TextEditingController();
  bool _openToWork = true;
  List<ProfileSkill> _skills = const [];
  List<WorkExperience> _experiences = const [];
  List<Education> _educations = const [];
  bool _primed = false;
  bool _dirty = false;

  @override
  void dispose() {
    _fullName.dispose();
    _headline.dispose();
    _phone.dispose();
    _address.dispose();
    _summary.dispose();
    _city.dispose();
    super.dispose();
  }

  /// Fills the form from the first non-null profile emission. A leading
  /// `null` (doc not created yet) must not count as primed, otherwise the
  /// real document arriving later would be ignored; and once the user has
  /// started typing we never overwrite their input.
  void _prime(JobSeekerProfile? p) {
    if (_primed || p == null || _dirty) return;
    _primed = true;
    _fullName.text = p.fullName ?? '';
    _headline.text = p.headline ?? '';
    _phone.text = p.phone ?? '';
    _address.text = p.address ?? '';
    _summary.text = p.profileSummary ?? '';
    _city.text = p.city?.trim() ?? '';
    _openToWork = p.isOpenToWork;
    _skills = p.skills;
    _experiences = p.workExperiences;
    _educations = p.educations;
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _save(JobSeekerProfile? current) async {
    if (!_formKey.currentState!.validate()) {
      showFailure(context, const Failure('Vui lòng kiểm tra lại các trường được đánh dấu.'));
      return;
    }
    final uid = ref.read(currentUidProvider) ?? current?.uid ?? '';
    final base = current ?? JobSeekerProfile(uid: uid);
    final updated = JobSeekerProfile(
      uid: base.uid.isEmpty ? uid : base.uid,
      fullName: _fullName.text.trim(),
      email: base.email,
      phone: _phone.text.trim(),
      address: _address.text.trim(),
      city: _city.text.trim(),
      headline: _headline.text.trim(),
      profileSummary: _summary.text.trim(),
      isVerified: base.isVerified,
      isOpenToWork: _openToWork,
      isActive: base.isActive,
      skills: _skills,
      workExperiences: _experiences,
      educations: _educations,
      primaryResumeId: base.primaryResumeId,
      createdAt: base.createdAt,
    );
    final ok = await ref.read(profileViewModelProvider.notifier).saveFull(updated);
    if (!mounted) return;
    if (ok) {
      showSuccess(context, ProfileViewModel.savedMessage);
      setState(() => _dirty = false);
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.resumeProfile);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(jobSeekerProfileProvider);
    final vm = ref.watch(profileViewModelProvider);

    return PublicLayout(
      child: PageContainer(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: profile.when(
            loading: () => const SizedBox(
              height: 320,
              child: RouteLoader(label: 'Đang tải hồ sơ...'),
            ),
            error: (e, _) => SizedBox(
              height: 320,
              child: RouteErrorView(
                error: e,
                compact: true,
                onRetry: () => ref.invalidate(jobSeekerProfileProvider),
              ),
            ),
            data: (p) {
              _prime(p);
              return _buildBody(context, p, vm);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, JobSeekerProfile? p, ProfileEditState vm) {
    return Form(
      key: _formKey,
      onChanged: _markDirty,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Eyebrow(label: 'Ứng viên'),
                    const SizedBox(height: 12),
                    Text('Chỉnh sửa hồ sơ',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                              letterSpacing: -0.5,
                            )),
                    const SizedBox(height: 8),
                    const Text(
                      'Hoàn thiện thông tin liên hệ, kỹ năng, kinh nghiệm và học vấn để nhà tuyển dụng và AI hiểu rõ hơn về bạn.',
                      style: TextStyle(color: AppColors.inkSoft, fontSize: 15, height: 1.6),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              TextButton.icon(
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go(AppRoutes.resumeProfile),
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Quay lại Hồ sơ & CV'),
              ),
            ],
          ),
          if (vm.hasMessage && !vm.isSuccess) ...[
            const SizedBox(height: 24),
            AlertError(message: vm.message!),
          ],
          const SizedBox(height: 32),
          LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth >= 1024 - 64;
              final left = _basicsCard();
              final right = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionCard(
                    title: 'Kỹ năng',
                    subtitle: 'Kỹ năng chuyên môn kèm số năm kinh nghiệm (nguồn: tự khai).',
                    child: SkillsEditor(
                      skills: _skills,
                      onChanged: (v) => setState(() {
                        _skills = v;
                        _dirty = true;
                      }),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _sectionCard(
                    title: 'Kinh nghiệm làm việc',
                    subtitle: 'Sắp xếp theo ngày bắt đầu mới nhất.',
                    child: WorkExperienceEditor(
                      items: _experiences,
                      onChanged: (v) => setState(() {
                        _experiences = v;
                        _dirty = true;
                      }),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _sectionCard(
                    title: 'Học vấn',
                    subtitle: 'Trường, bằng cấp, chuyên ngành và thời gian học.',
                    child: EducationEditor(
                      items: _educations,
                      onChanged: (v) => setState(() {
                        _educations = v;
                        _dirty = true;
                      }),
                    ),
                  ),
                ],
              );
              if (!wide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [left, const SizedBox(height: 24), right],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: left),
                  const SizedBox(width: 24),
                  Expanded(flex: 7, child: right),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 12,
              spacing: 12,
              children: [
                Text(
                  _dirty
                      ? 'Bạn có thay đổi chưa lưu.'
                      : 'Mọi thay đổi sẽ thay thế toàn bộ danh sách kỹ năng, kinh nghiệm và học vấn hiện tại.',
                  style: const TextStyle(fontSize: 13, color: AppColors.inkMuted),
                ),
                Wrap(
                  spacing: 12,
                  children: [
                    OutlinedButton(
                      onPressed: vm.saving
                          ? null
                          : () => context.canPop()
                              ? context.pop()
                              : context.go(AppRoutes.resumeProfile),
                      child: const Text('Hủy'),
                    ),
                    ElevatedButton.icon(
                      onPressed: vm.saving ? null : () => _save(p),
                      icon: vm.saving
                          ? const MiniSpinner(size: 16, color: Colors.white)
                          : const Icon(Icons.save_outlined, size: 18),
                      label: Text(vm.saving ? 'Đang lưu...' : 'Lưu thay đổi'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, String? subtitle, required Widget child}) {
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardHeading(title: title, subtitle: subtitle),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _basicsCard() {
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CardHeading(
            title: 'Thông tin cơ bản',
            subtitle: 'Những thông tin này sẽ hiển thị khi nhà tuyển dụng xem hồ sơ của bạn.',
          ),
          const SizedBox(height: 16),
          FieldLabel(
            label: 'Họ và tên',
            child: TextFormField(
              controller: _fullName,
              textInputAction: TextInputAction.next,
              validator: (v) {
                final s = (v ?? '').trim();
                if (s.isEmpty) return null;
                return Validators.lengthBetween(s, 2, 255, label: 'Họ tên');
              },
              decoration: const InputDecoration(hintText: 'Nguyễn Văn A'),
            ),
          ),
          const SizedBox(height: 16),
          FieldLabel(
            label: 'Tiêu đề hồ sơ',
            required: true,
            child: TextFormField(
              controller: _headline,
              textInputAction: TextInputAction.next,
              validator: (v) => (v ?? '').trim().length > 255
                  ? ProfileViewModel.headlineTooLong
                  : null,
              decoration: const InputDecoration(hintText: 'VD: Backend Developer'),
            ),
          ),
          const SizedBox(height: 16),
          FieldLabel(
            label: 'Địa điểm',
            required: true,
            child: CityField(
              controller: _city,
              validator: (v) => (v ?? '').trim().length > 100
                  ? ProfileViewModel.cityTooLong
                  : null,
              onChanged: (_) => _markDirty(),
            ),
          ),
          const SizedBox(height: 16),
          FieldLabel(
            label: 'Số điện thoại',
            child: TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              validator: (v) {
                final s = (v ?? '').trim();
                if (s.isEmpty) return null;
                if (s.length > 20) return ProfileViewModel.phoneTooLong;
                return Validators.phone(s, isRequired: false);
              },
              decoration: const InputDecoration(hintText: '0901 234 567'),
            ),
          ),
          const SizedBox(height: 16),
          FieldLabel(
            label: 'Địa chỉ',
            child: TextFormField(
              controller: _address,
              textInputAction: TextInputAction.next,
              validator: (v) => (v ?? '').trim().length > 500
                  ? ProfileViewModel.addressTooLong
                  : null,
              decoration: const InputDecoration(hintText: 'Số nhà, đường, quận/huyện'),
            ),
          ),
          const SizedBox(height: 16),
          FieldLabel(
            label: 'Giới thiệu bản thân',
            hint: 'Tối đa 5000 ký tự.',
            child: TextFormField(
              controller: _summary,
              minLines: 4,
              maxLines: 8,
              validator: (v) => (v ?? '').trim().length > 5000
                  ? ProfileViewModel.summaryTooLong
                  : null,
              decoration: const InputDecoration(
                hintText: 'Mục tiêu nghề nghiệp, điểm mạnh, lĩnh vực quan tâm...',
                alignLabelWithHint: true,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _openToWork,
            activeTrackColor: AppColors.secondary,
            onChanged: (v) => setState(() {
              _openToWork = v;
              _dirty = true;
            }),
            title: const Text('Sẵn sàng nhận việc',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text(
              'Cho phép nhà tuyển dụng biết bạn đang mở với cơ hội mới.',
              style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
            ),
          ),
        ],
      ),
    );
  }
}
