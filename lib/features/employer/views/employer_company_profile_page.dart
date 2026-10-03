import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/enums.dart';
import '../../../core/utils/failure.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/models/employer_profile_model.dart';
import '../../../shared/widgets/application_status_badge.dart';
import '../../../shared/widgets/ui_primitives.dart';
import '../data/employer_repository.dart';
import '../viewmodels/company_profile_viewmodel.dart';
import '../viewmodels/employer_providers.dart';
import '../widgets/employer_guard.dart';
import '../widgets/employer_page_header.dart';
import '../widgets/employer_state_banners.dart';
import '../widgets/form_helpers.dart';

/// pages/EmployerCompanyProfilePage.jsx — "Quản lý hồ sơ công ty".
class EmployerCompanyProfilePage extends ConsumerStatefulWidget {
  const EmployerCompanyProfilePage({super.key});

  @override
  ConsumerState<EmployerCompanyProfilePage> createState() => _EmployerCompanyProfilePageState();
}

class _EmployerCompanyProfilePageState extends ConsumerState<EmployerCompanyProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _companyName = TextEditingController();
  final _phone = TextEditingController();
  final _website = TextEditingController();
  final _contactName = TextEditingController();
  final _description = TextEditingController();
  final _city = TextEditingController();
  Gender? _gender;
  String? _initializedFor;

  @override
  void initState() {
    super.initState();
    // Fill the form once per profile uid, outside build (the web page does
    // this in a useEffect after getMyProfile resolves). fireImmediately
    // covers the case where the profile stream is already cached.
    ref.listenManual<AsyncValue<EmployerProfile?>>(
      employerProfileProvider,
      (_, next) {
        final p = next.valueOrNull;
        if (p != null) _fill(p);
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _companyName.dispose();
    _phone.dispose();
    _website.dispose();
    _contactName.dispose();
    _description.dispose();
    _city.dispose();
    super.dispose();
  }

  void _fill(EmployerProfile p) {
    if (_initializedFor == p.uid) return;
    _initializedFor = p.uid;
    _companyName.text = p.companyName;
    _phone.text = p.phone ?? '';
    _website.text = p.website ?? '';
    _contactName.text = p.contactName ?? '';
    _description.text = p.companyDescription ?? '';
    _city.text = p.city ?? '';
    if (mounted) setState(() => _gender = p.gender);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref.read(companyProfileViewModelProvider.notifier).save(
          companyName: _companyName.text,
          phone: _phone.text,
          website: _website.text,
          companyDescription: _description.text,
          city: _city.text,
          contactName: _contactName.text,
          gender: _gender,
        );
  }

  // ── Client validators = employerValidator.updateProfile (every optional
  //    field also accepts ''; companyName 2..255 only when non-empty) ──────
  static String? _companyNameValidator(String? v) {
    final s = (v ?? '').trim();
    if (s.isNotEmpty && (s.length < 2 || s.length > 255)) {
      return 'Tên công ty phải từ 2 đến 255 ký tự.';
    }
    return null;
  }

  Future<void> _pickLogo() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 512, imageQuality: 85);
    if (x == null) return;
    final bytes = await x.readAsBytes();
    await ref.read(companyProfileViewModelProvider.notifier).uploadLogo(bytes, x.name);
  }

  @override
  Widget build(BuildContext context) {
    return EmployerGuard(
      deniedTitle: 'Bạn không thể truy cập trang hồ sơ công ty',
      builder: (context, user) {
        final profile = ref.watch(employerProfileProvider);
        final vm = ref.watch(companyProfileViewModelProvider);
        final wide = MediaQuery.sizeOf(context).width >= 1024;
        final data = profile.valueOrNull;

        return EmployerPageShell(
          maxWidth: wide ? 1152 : 896,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const EmployerPageHeader(
                eyebrow: 'Hồ sơ công ty',
                title: 'Quản lý hồ sơ công ty',
                subtitle: 'Cập nhật thông tin công ty để hiển thị cùng các tin tuyển dụng.',
              ),
              if (profile.isLoading) ...[
                const SizedBox(height: 24),
                const StateCard(text: 'Đang tải hồ sơ công ty...', spinner: true),
              ],
              if (profile.hasError) ...[
                const SizedBox(height: 24),
                StateCard.error(text: Failure.from(profile.error!).message),
              ],
              if (vm.error != null) ...[
                const SizedBox(height: 24),
                StateCard.error(text: vm.error!),
              ],
              if (vm.message != null) ...[
                const SizedBox(height: 24),
                StateCard.success(text: vm.message!),
              ],
              if (!profile.isLoading && !profile.hasError) ...[
                const SizedBox(height: 32),
                if (data == null)
                  const StateCard.error(text: EmployerRepository.msgProfileNotFound)
                else if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 320, child: _SideCard(profile: data, uploading: vm.uploadingLogo, onPickLogo: _pickLogo)),
                      const SizedBox(width: 24),
                      Expanded(child: _form(vm)),
                    ],
                  )
                else ...[
                  _SideCard(profile: data, uploading: vm.uploadingLogo, onPickLogo: _pickLogo),
                  const SizedBox(height: 16),
                  _form(vm),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _form(CompanyProfileState vm) {
    final fe = vm.fieldErrors;

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: FormCard(
        children: [
          FieldBlock(
            // Web: plain <input placeholder="Tên công ty"> (not required;
            // backend keeps the existing name when '' is submitted).
            label: 'Tên công ty',
            error: fe['companyName'],
            child: TextFormField(
              controller: _companyName,
              validator: _companyNameValidator,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(hintText: 'Tên công ty'),
            ),
          ),
          TwoColumn(
            left: FieldBlock(
              label: 'Số điện thoại',
              error: fe['phone'],
              child: TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                validator: (v) => Validators.maxLength(v?.trim(), 20, label: 'Số điện thoại'),
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(hintText: 'Số điện thoại liên hệ'),
              ),
            ),
            right: FieldBlock(
              label: 'Website',
              error: fe['website'],
              child: TextFormField(
                controller: _website,
                keyboardType: TextInputType.url,
                validator: (v) => Validators.maxLength(v?.trim(), 255, label: 'Website'),
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(hintText: 'https://company.com'),
              ),
            ),
          ),
          TwoColumn(
            left: FieldBlock(
              // Web: free-text <input placeholder="Hà Nội">, backend max 100.
              label: 'Thành phố',
              error: fe['city'],
              child: TextFormField(
                controller: _city,
                maxLength: 100,
                validator: (v) => Validators.maxLength(v?.trim(), 100, label: 'Thành phố'),
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(hintText: 'Hà Nội', counterText: ''),
              ),
            ),
            right: FieldBlock(
              label: 'Người liên hệ',
              error: fe['contactName'],
              child: TextFormField(
                controller: _contactName,
                validator: (v) => Validators.maxLength(v?.trim(), 255, label: 'Người liên hệ'),
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(hintText: 'Tên người phụ trách tuyển dụng'),
              ),
            ),
          ),
          FieldBlock(
            label: 'Giới tính người liên hệ',
            child: RadioGroup<Gender?>(
              groupValue: _gender,
              onChanged: (v) => setState(() => _gender = v),
              child: Wrap(
                spacing: 12,
                children: [
                  for (final g in Gender.values)
                    InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      onTap: () => setState(() => _gender = g),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Radio<Gender?>(value: g, visualDensity: VisualDensity.compact),
                          Text(g.label, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          FieldBlock(
            label: 'Giới thiệu công ty',
            error: fe['companyDescription'],
            child: TextFormField(
              controller: _description,
              minLines: 5,
              maxLines: 12,
              maxLength: 5000,
              validator: (v) => Validators.maxLength(v, 5000, label: 'Giới thiệu công ty'),
              decoration: const InputDecoration(
                hintText: 'Mô tả ngắn gọn về công ty, lĩnh vực hoạt động và môi trường làm việc.',
                alignLabelWithHint: true,
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: vm.saving ? null : _save,
              child: Text(vm.saving ? 'Đang lưu...' : 'Lưu hồ sơ công ty'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SideCard extends StatelessWidget {
  const _SideCard({required this.profile, required this.uploading, required this.onPickLogo});
  final EmployerProfile profile;
  final bool uploading;
  final VoidCallback onPickLogo;

  @override
  Widget build(BuildContext context) {
    final name = profile.companyName.trim().isEmpty ? 'Công ty chưa cập nhật' : profile.companyName;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CompanyLogoTile(name: name, logoUrl: profile.logoUrl, size: 72, radius: 16),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
                    const SizedBox(height: 6),
                    BoolBadge(
                      value: profile.isVerified,
                      trueLabel: 'Đã xác thực',
                      falseLabel: 'Chờ xác thực',
                      falseTone: const (AppColors.amber50, AppColors.amber700),
                    ),
                    if (!profile.isActive) ...[
                      const SizedBox(height: 6),
                      const BoolBadge(value: false, trueLabel: 'Đang hoạt động', falseLabel: 'Đã bị khoá'),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: uploading ? null : onPickLogo,
            icon: uploading
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.image_outlined, size: 16),
            label: Text(uploading ? 'Đang tải logo...' : 'Tải logo lên'),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tuỳ chọn. PNG/JPG, tối đa 512px. Nếu Firebase Storage chưa bật, logo chữ cái sẽ được dùng.',
            style: TextStyle(fontSize: 11, color: AppColors.inkMuted, height: 1.4),
          ),
          const Divider(height: 28),
          _row(Icons.mail_outline, profile.email ?? 'Chưa cập nhật email'),
          _row(Icons.work_outline, '${profile.openPositions} vị trí đang tuyển'),
          _row(Icons.verified_outlined,
              profile.isVerified
                  ? 'Công ty đã được quản trị viên xác thực.'
                  : 'Hồ sơ đang chờ quản trị viên xác thực. Tin tuyển dụng vẫn có thể được đăng.'),
          _row(Icons.schedule_outlined, 'Tham gia ${Formatters.date(profile.createdAt)}'),
          if (profile.updatedAt != null)
            _row(Icons.update_outlined, 'Cập nhật ${Formatters.relative(profile.updatedAt)}'),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 15, color: AppColors.inkMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.inkSoft, height: 1.4)),
            ),
          ],
        ),
      );
}
