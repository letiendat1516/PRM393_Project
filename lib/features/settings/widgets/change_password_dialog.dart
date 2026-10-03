import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/failure.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/ui_primitives.dart';
import '../viewmodels/settings_viewmodel.dart';
import 'adaptive_colors.dart';

/// UC26 Change Password: current / new / confirm with backend validator
/// limits (8–128). Resolves true when the password was changed.
Future<bool> showChangePasswordDialog(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _ChangePasswordDialog(),
  );
  return ok ?? false;
}

class _ChangePasswordDialog extends ConsumerStatefulWidget {
  const _ChangePasswordDialog();

  @override
  ConsumerState<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  Failure? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    if (_current.text == _next.text) {
      setState(() => _error = const Failure.validation('Mật khẩu mới phải khác mật khẩu hiện tại.'));
      return;
    }
    try {
      await ref.read(settingsProvider.notifier).changePassword(
            currentPassword: _current.text,
            newPassword: _next.text,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = Failure.from(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(settingsProvider.select((s) => s.changingPassword));

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.x2l)),
      title: const Text('Đổi mật khẩu'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Nhập mật khẩu hiện tại để xác thực, sau đó đặt mật khẩu mới (8–128 ký tự).',
                style: TextStyle(fontSize: 13, color: context.inkSoftColor, height: 1.5),
              ),
              const SizedBox(height: 16),
              if (_error != null) ...[
                AlertError(message: _error!.message),
                const SizedBox(height: 12),
              ],
              PasswordField(
                controller: _current,
                label: 'Mật khẩu hiện tại',
                validator: Validators.password,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.password],
              ),
              const SizedBox(height: 12),
              PasswordField(
                controller: _next,
                label: 'Mật khẩu mới',
                hint: 'Tối thiểu 8 ký tự',
                validator: Validators.password,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
              ),
              const SizedBox(height: 12),
              PasswordField(
                controller: _confirm,
                label: 'Xác nhận mật khẩu mới',
                validator: (v) => Validators.confirmPassword(v, _next.text),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => busy ? null : _submit(),
                autofillHints: const [AutofillHints.newPassword],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Huỷ'),
        ),
        ElevatedButton(
          onPressed: busy ? null : _submit,
          child: busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Cập nhật mật khẩu'),
        ),
      ],
    );
  }
}
