import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/auth_shell.dart';
import '../../../shared/widgets/ui_primitives.dart';
import '../viewmodels/forgot_password_viewmodel.dart';
import '../widgets/auth_buttons.dart';
import '../widgets/auth_form_widgets.dart';

/// ForgotPasswordPage — /quen-mat-khau (mobile-only screen from
/// docs/FLUTTER_REBUILD_PLAN.md): email form → FirebaseAuth reset mail →
/// success state.
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    ref.read(forgotPasswordViewModelProvider.notifier).submit(_email.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordViewModelProvider);
    final vm = ref.read(forgotPasswordViewModelProvider.notifier);

    return AuthShell(
      title: 'Quên mật khẩu?',
      subtitle: 'Nhập email đã đăng ký, chúng tôi sẽ gửi liên kết đặt lại mật khẩu cho bạn.',
      footer: const AuthFooterText(
        prefix: 'Nhớ mật khẩu rồi?',
        linkText: 'Đăng nhập',
        route: AppRoutes.login,
      ),
      child: state.sent
          ? _SentState(
              email: state.sentTo!,
              onResend: vm.reset,
              onBackToLogin: () => context.go(AppRoutes.login),
            )
          : Form(
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
                    label: 'Email',
                    child: TextFormField(
                      controller: _email,
                      enabled: !state.submitting,
                      autofocus: true,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.email],
                      autocorrect: false,
                      decoration: const InputDecoration(
                        hintText: 'ban@example.com',
                        prefixIcon: Icon(Icons.mail_outline, size: 20),
                      ),
                      validator: Validators.email,
                      onChanged: (_) => vm.clearError(),
                      onFieldSubmitted: (_) => _submit(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  AuthSubmitButton(
                    label: 'Gửi email đặt lại mật khẩu',
                    loadingLabel: 'Đang gửi...',
                    submitting: state.submitting,
                    onPressed: _submit,
                    icon: Icons.send_outlined,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Liên kết đặt lại mật khẩu có hiệu lực trong thời gian ngắn. '
                    'Nếu không thấy email, hãy kiểm tra mục Spam.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.inkMuted, height: 1.5),
                  ),
                ],
              ),
            ),
    );
  }
}

/// Success state after FirebaseAuth accepted the reset request.
class _SentState extends StatelessWidget {
  const _SentState({
    required this.email,
    required this.onResend,
    required this.onBackToLogin,
  });

  final String email;
  final VoidCallback onResend;
  final VoidCallback onBackToLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.emerald50,
            border: Border.all(color: AppColors.emerald100),
            borderRadius: BorderRadius.circular(AppRadius.x2l),
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.emerald100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mark_email_read_outlined,
                    color: AppColors.emerald700, size: 24),
              ),
              const SizedBox(height: 14),
              const Text(
                'Đã gửi email đặt lại mật khẩu',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.emerald700,
                ),
              ),
              const SizedBox(height: 6),
              Text.rich(
                TextSpan(
                  text: 'Đã gửi email đặt lại mật khẩu đến ',
                  children: [
                    TextSpan(
                      text: email,
                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink),
                    ),
                    const TextSpan(
                      text: '. Vui lòng kiểm tra hộp thư (kể cả mục Spam) và làm theo hướng dẫn để tạo mật khẩu mới.',
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.inkSoft, height: 1.55),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: onBackToLogin,
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Quay lại đăng nhập'),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: onResend,
          child: const Text('Chưa nhận được email? Gửi lại'),
        ),
      ],
    );
  }
}
