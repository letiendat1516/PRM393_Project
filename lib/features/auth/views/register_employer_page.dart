import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/demo_data.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/enums.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/auth_shell.dart';
import '../../../shared/widgets/nav_items.dart';
import '../../../shared/widgets/ui_primitives.dart';
import '../viewmodels/register_viewmodel.dart';
import '../widgets/auth_buttons.dart';
import '../widgets/auth_form_widgets.dart';

/// RegisterEmployerPage — /dang-ky-nha-tuyen-dung
/// (frontend/src/pages/RegisterEmployerPage.jsx). Detailed employer form:
/// Tài khoản / Thông tin nhà tuyển dụng / Đồng ý sections.
class RegisterEmployerPage extends ConsumerStatefulWidget {
  const RegisterEmployerPage({super.key});

  @override
  ConsumerState<RegisterEmployerPage> createState() => _RegisterEmployerPageState();
}

class _RegisterEmployerPageState extends ConsumerState<RegisterEmployerPage> {
  static const _consentError =
      'Bạn cần đồng ý với Điều khoản dịch vụ và Chính sách quyền riêng tư.';

  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _contactName = TextEditingController();
  final _phone = TextEditingController();
  final _companyName = TextEditingController();

  Gender? _gender;
  String? _genderError;
  String? _city;
  bool _agreeTerms = false;
  bool _agreeMarketing = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _contactName.dispose();
    _phone.dispose();
    _companyName.dispose();
    super.dispose();
  }

  String? _validateConfirm(String? v) {
    if (v == null || v.isEmpty) return Validators.confirmPassword(v, _password.text);
    if (v != _password.text) return 'Mật khẩu nhập lại không khớp.';
    return null;
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final vm = ref.read(registerViewModelProvider.notifier);
    vm.clearError();
    setState(() => _genderError = null);

    final fieldsOk = _formKey.currentState!.validate();
    if (!_agreeTerms) {
      vm.showError(_consentError);
      return;
    }
    final genderError = Validators.gender(_gender?.name);
    if (genderError != null) {
      setState(() => _genderError = genderError);
      return;
    }
    if (!fieldsOk) return;

    vm.submitEmployer(
      contactName: _contactName.text,
      gender: _gender!,
      phone: _phone.text,
      companyName: _companyName.text,
      city: _city!,
      email: _email.text,
      password: _password.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<RegisterState>(registerViewModelProvider, (prev, next) {
      if (next.success && !(prev?.success ?? false)) {
        context.go(NavItems.homeFor(next.user!.role));
      }
    });
    final state = ref.watch(registerViewModelProvider);
    final vm = ref.read(registerViewModelProvider.notifier);
    final fe = state.fieldErrors;
    final busy = state.submitting;

    return AuthShell(
      title: 'Đăng ký tài khoản Nhà tuyển dụng',
      subtitle: 'Đăng tin tuyển dụng và tiếp cận ứng viên phù hợp nhờ gợi ý từ hệ thống.',
      footer: const AuthFooterText(
        prefix: 'Đã có tài khoản?',
        linkText: 'Đăng nhập ngay',
        route: AppRoutes.login,
      ),
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.error != null) ...[
                AlertError(message: state.error!),
                const SizedBox(height: 16),
              ],

              // ── Tài khoản ────────────────────────────────────────────
              const FormSectionEyebrow('Tài khoản'),
              const SizedBox(height: 16),
              LabeledField(
                label: 'Email đăng nhập',
                child: TextFormField(
                  controller: _email,
                  enabled: !busy,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  autocorrect: false,
                  decoration: InputDecoration(
                    hintText: 'hr@congty.vn',
                    prefixIcon: const Icon(Icons.mail_outline, size: 20),
                    errorText: fe['email'],
                  ),
                  validator: Validators.email,
                  onChanged: (_) => vm.clearError('email'),
                ),
              ),
              const SizedBox(height: 16),
              LabeledField(
                label: 'Mật khẩu',
                child: PasswordField(
                  controller: _password,
                  floatingLabel: false,
                  hint: 'Tối thiểu 8 ký tự',
                  enabled: !busy,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: Validators.password,
                  onChanged: (_) => vm.clearError('password'),
                ),
              ),
              const SizedBox(height: 16),
              LabeledField(
                label: 'Nhập lại mật khẩu',
                child: PasswordField(
                  controller: _confirmPassword,
                  floatingLabel: false,
                  hint: 'Nhập lại mật khẩu',
                  enabled: !busy,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: _validateConfirm,
                  onChanged: (_) => vm.clearError('confirmPassword'),
                ),
              ),

              // ── Thông tin nhà tuyển dụng ────────────────────────────
              const FormSectionDivider(),
              const FormSectionEyebrow('Thông tin nhà tuyển dụng'),
              const SizedBox(height: 16),
              LabeledField(
                label: 'Họ và tên',
                child: TextFormField(
                  controller: _contactName,
                  enabled: !busy,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  decoration: InputDecoration(
                    hintText: 'Nguyễn Văn A',
                    prefixIcon: const Icon(Icons.people_outline, size: 20),
                    errorText: fe['contactName'],
                  ),
                  // authValidator.registerEmployer: contactName min(2, 'Họ và tên là bắt buộc.')
                  validator: (v) => Validators.fullName(v, label: 'Họ và tên'),
                  onChanged: (_) => vm.clearError('contactName'),
                ),
              ),
              const SizedBox(height: 16),
              GenderPicker(
                value: _gender,
                enabled: !busy,
                error: _genderError ?? fe['gender'],
                onChanged: (g) {
                  setState(() {
                    _gender = g;
                    _genderError = null;
                  });
                  vm.clearError('gender');
                },
              ),
              const SizedBox(height: 16),
              LabeledField(
                label: 'Số điện thoại cá nhân',
                child: TextFormField(
                  controller: _phone,
                  enabled: !busy,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  decoration: InputDecoration(
                    hintText: '09xx xxx xxx',
                    prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                    errorText: fe['phone'],
                  ),
                  validator: Validators.phone,
                  onChanged: (_) => vm.clearError('phone'),
                ),
              ),
              const SizedBox(height: 16),
              LabeledField(
                label: 'Công ty',
                child: TextFormField(
                  controller: _companyName,
                  enabled: !busy,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.organizationName],
                  decoration: InputDecoration(
                    hintText: 'Công ty Cổ phần ABC',
                    prefixIcon: const Icon(Icons.business_outlined, size: 20),
                    errorText: fe['companyName'],
                  ),
                  validator: Validators.companyName,
                  onChanged: (_) => vm.clearError('companyName'),
                ),
              ),
              const SizedBox(height: 16),
              // SelectField.jsx: label above + disabled placeholder option.
              LabeledField(
                label: 'Địa điểm làm việc',
                child: DropdownButtonFormField<String>(
                  initialValue: _city,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: AppColors.inkMuted),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  menuMaxHeight: 320,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.place_outlined, size: 20),
                    errorText: fe['city'],
                  ),
                  hint: const Text(
                    'Chọn tỉnh/thành phố',
                    style: TextStyle(color: AppColors.inkMuted, fontSize: 14),
                  ),
                  items: [
                    for (final p in DemoData.provinces)
                      DropdownMenuItem(value: p, child: Text(p, overflow: TextOverflow.ellipsis)),
                  ],
                  validator: Validators.city,
                  onChanged: busy
                      ? null
                      : (v) {
                          setState(() => _city = v);
                          vm.clearError('city');
                        },
                ),
              ),

              // ── Đồng ý ──────────────────────────────────────────────
              const FormSectionDivider(),
              AuthCheckbox(
                value: _agreeTerms,
                enabled: !busy,
                onChanged: (v) {
                  setState(() => _agreeTerms = v);
                  if (v && state.error == _consentError) vm.clearError();
                },
                label: const TextSpan(
                  text: 'Tôi đã đọc và đồng ý với ',
                  children: [
                    TextSpan(
                      text: 'Điều khoản dịch vụ',
                      style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.primary),
                    ),
                    TextSpan(text: ' và '),
                    TextSpan(
                      text: 'Chính sách quyền riêng tư',
                      style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.primary),
                    ),
                    TextSpan(text: ' của JobHub. '),
                    TextSpan(text: '*', style: TextStyle(color: AppColors.primary)),
                  ],
                ),
                hint: 'Chúng tôi không thể cung cấp dịch vụ nếu không nhận được sự đồng ý ở mục này.',
              ),
              const SizedBox(height: 12),
              AuthCheckbox(
                value: _agreeMarketing,
                enabled: !busy,
                onChanged: (v) => setState(() => _agreeMarketing = v),
                label: const TextSpan(
                  text:
                      'Tôi đồng ý nhận thông tin tư vấn để được hỗ trợ đăng tin nhanh và các giải pháp tuyển dụng phù hợp.',
                ),
                hint:
                    'Khuyên dùng: Nếu không có sự đồng ý, chuyên viên sẽ không thể liên hệ để hỗ trợ Quý khách xác thực tài khoản nhanh chóng.',
              ),

              const SizedBox(height: 24),
              AuthSubmitButton(
                label: 'Đăng ký tài khoản',
                loadingLabel: 'Đang tạo tài khoản...',
                submitting: busy,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
