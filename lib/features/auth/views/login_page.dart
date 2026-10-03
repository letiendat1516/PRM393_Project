import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/auth_shell.dart';
import '../../../shared/widgets/nav_items.dart';
import '../../../shared/widgets/ui_primitives.dart';
import '../viewmodels/login_viewmodel.dart';
import '../widgets/auth_buttons.dart';
import '../widgets/auth_form_widgets.dart';

/// LoginPage — /dang-nhap (frontend/src/pages/LoginPage.jsx).
/// Auth page: AuthShell only (no navbar/footer). After login → redirect by
/// role (redirectByRole.js: admin → /admin/users, others → '/').
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  /// LoginPage.jsx initial form state: `rememberMe: true` on every load (the
  /// last choice is NOT restored; only the remembered email is prefilled).
  bool _rememberMe = true;
  bool _googleBusy = false;

  @override
  void initState() {
    super.initState();
    final saved = ref.read(prefsServiceProvider).rememberEmail;
    if (saved != null && saved.isNotEmpty) _email.text = saved;
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    ref.read(loginViewModelProvider.notifier).submit(
          email: _email.text,
          password: _password.text,
          rememberMe: _rememberMe,
        );
  }

  Future<void> _signInGoogle() async {
    if (_googleBusy) return;
    FocusScope.of(context).unfocus();
    setState(() => _googleBusy = true);
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
      // Email/password path uses an explicit context.go() when the view-model
      // reports success — do the same here. Relying only on the router's
      // auth-state redirect races against currentUserProvider: for brand-new
      // Google accounts the users/{uid} doc is written *after*
      // signInWithCredential fires authStateChanges, so the first redirect
      // cycle sees current.isLoading=true and no-ops; the second cycle
      // depends on the Firestore snapshot stream arriving — users reported
      // the login page just stuck. Firing go() ourselves guarantees the
      // transition, and the router's role-based redirect still fires for
      // admin → /admin/users once the role is known.
      if (!mounted) return;
      context.go(AppRoutes.home);
    } catch (e) {
      if (!mounted) return;
      final msg =
          e is Exception ? e.toString() : (e is Error ? e.toString() : '$e');
      // Prefer Failure.message when available.
      final shown = e.toString().contains('Failure(')
          ? e.toString().split("'").length > 1 ? e.toString().split("'")[1] : msg
          : msg;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(shown)),
      );
    } finally {
      if (mounted) setState(() => _googleBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<LoginState>(loginViewModelProvider, (prev, next) {
      if (next.success && !(prev?.success ?? false)) {
        context.go(NavItems.homeFor(next.user!.role));
      }
    });
    final state = ref.watch(loginViewModelProvider);
    final vm = ref.read(loginViewModelProvider.notifier);
    final busy = state.submitting;

    return AuthShell(
      title: 'Đăng nhập',
      subtitle: 'Chào mừng bạn quay lại JobHub.',
      footer: const AuthFooterText(
        prefix: 'Chưa có tài khoản?',
        linkText: 'Đăng ký miễn phí',
        route: AppRoutes.register,
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
                label: 'Email',
                child: TextFormField(
                  controller: _email,
                  enabled: !busy,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  autocorrect: false,
                  decoration: const InputDecoration(
                    hintText: 'ban@example.com',
                    prefixIcon: Icon(Icons.mail_outline, size: 20),
                  ),
                  validator: Validators.email,
                  onChanged: (_) => vm.clearError(),
                ),
              ),
              const SizedBox(height: 16),
              LabeledField(
                label: 'Mật khẩu',
                child: PasswordField(
                  controller: _password,
                  floatingLabel: false,
                  hint: '••••••••',
                  enabled: !busy,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  // authValidator.login: password min(1, 'Vui lòng nhập mật khẩu.')
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Vui lòng nhập mật khẩu.' : null,
                  onChanged: (_) => vm.clearError(),
                  onFieldSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AuthCheckbox(
                      value: _rememberMe,
                      enabled: !busy,
                      onChanged: (v) => setState(() => _rememberMe = v),
                      label: const TextSpan(
                        text: 'Ghi nhớ đăng nhập (giữ phiên 7 ngày, không bị out khi reload)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Mobile-plan addition (FLUTTER_REBUILD_PLAN: forgot password).
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: AuthLink(
                      text: 'Quên mật khẩu?',
                      route: AppRoutes.forgotPassword,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              AuthSubmitButton(
                label: 'Đăng nhập',
                loadingLabel: 'Đang đăng nhập...',
                submitting: busy,
                onPressed: _submit,
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('hoặc',
                        style: TextStyle(fontSize: 12, color: Colors.black45)),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: (busy || _googleBusy) ? null : _signInGoogle,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  side: const BorderSide(color: Colors.black26),
                ),
                icon: _googleBusy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Container(
                        width: 20,
                        height: 20,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(shape: BoxShape.circle),
                        child: const Text(
                          'G',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF4285F4),
                          ),
                        ),
                      ),
                label: Text(
                  _googleBusy ? 'Đang kết nối Google...' : 'Đăng nhập với Google',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
