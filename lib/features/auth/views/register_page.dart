import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/auth_shell.dart';
import '../../../shared/widgets/nav_items.dart';
import '../../../shared/widgets/ui_primitives.dart';
import '../viewmodels/register_viewmodel.dart';
import '../widgets/auth_buttons.dart';
import '../widgets/auth_form_widgets.dart';

/// RegisterPage — /dang-ky (frontend/src/pages/RegisterPage.jsx).
/// Candidate (job_seeker) registration. Employers register at
/// /dang-ky-nha-tuyen-dung (detailed form).
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
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
    if (!_formKey.currentState!.validate()) return;
    vm.submitJobSeeker(
      fullName: _fullName.text,
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
      title: 'Tạo hồ sơ ứng viên miễn phí',
      subtitle: 'Chỉ mất 1 phút để bắt đầu tìm việc.',
      footer: const AuthFooterText(
        prefix: 'Đã có tài khoản?',
        linkText: 'Đăng nhập',
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
              LabeledField(
                label: 'Họ và tên',
                child: TextFormField(
                  controller: _fullName,
                  enabled: !busy,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  decoration: InputDecoration(
                    hintText: 'Nguyễn Văn A',
                    prefixIcon: const Icon(Icons.people_outline, size: 20),
                    errorText: fe['fullName'],
                  ),
                  // authValidator.registerJobSeeker: fullName min(2, 'Họ tên là bắt buộc.')
                  validator: (v) => Validators.fullName(v, label: 'Họ tên'),
                  onChanged: (_) => vm.clearError('fullName'),
                ),
              ),
              const SizedBox(height: 16),
              LabeledField(
                label: 'Email',
                child: TextFormField(
                  controller: _email,
                  enabled: !busy,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  autocorrect: false,
                  decoration: InputDecoration(
                    hintText: 'ban@example.com',
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
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: _validateConfirm,
                  onChanged: (_) => vm.clearError('confirmPassword'),
                  onFieldSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(height: 20),
              AuthSubmitButton(
                label: 'Tạo tài khoản',
                loadingLabel: 'Đang tạo tài khoản...',
                submitting: busy,
                onPressed: _submit,
              ),
              const SizedBox(height: 24),
              const EmployerCallout(route: AppRoutes.registerEmployer),
            ],
          ),
        ),
      ),
    );
  }
}
