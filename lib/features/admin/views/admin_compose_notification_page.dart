import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/enums.dart';
import '../../../core/utils/failure.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/ui_primitives.dart';
import '../data/admin_repository.dart';
import '../widgets/admin_page_shell.dart';

/// Admin → Soạn thông báo (/admin/notifications/compose).
///
/// A compose form that lets admins push a system notification to:
///   • a specific user (by email lookup)
///   • everyone with a given role
///   • everyone on the platform
///
/// The underlying write is a fan-out of one notifications/{id} doc per
/// recipient so inbox queries (watchForUser) keep working unchanged.
class AdminComposeNotificationPage extends ConsumerStatefulWidget {
  const AdminComposeNotificationPage({super.key});

  @override
  ConsumerState<AdminComposeNotificationPage> createState() =>
      _AdminComposeNotificationPageState();
}

enum _AudienceMode { everyone, byRole, specificUser }

class _AdminComposeNotificationPageState
    extends ConsumerState<AdminComposeNotificationPage> {
  final _title = TextEditingController();
  final _message = TextEditingController();
  final _email = TextEditingController();

  _AudienceMode _mode = _AudienceMode.everyone;
  UserRole _targetRole = UserRole.jobSeeker;
  UserModel? _resolvedUser; // populated after email lookup
  String? _emailLookupError;
  bool _lookingUp = false;
  bool _sending = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _title.dispose();
    _message.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _lookupEmail() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() {
        _emailLookupError = 'Nhập email để tìm.';
        _resolvedUser = null;
      });
      return;
    }
    setState(() {
      _lookingUp = true;
      _emailLookupError = null;
      _resolvedUser = null;
    });
    try {
      final user = await ref.read(adminRepositoryProvider).findUserByEmail(email);
      if (!mounted) return;
      setState(() {
        _lookingUp = false;
        _resolvedUser = user;
        _emailLookupError =
            user == null ? 'Không tìm thấy user với email này.' : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _lookingUp = false;
        _emailLookupError = Failure.from(e).message;
      });
    }
  }

  Future<void> _send() async {
    if (_sending) return;
    final repo = ref.read(adminRepositoryProvider);
    setState(() {
      _sending = true;
      _error = null;
      _success = null;
    });
    try {
      switch (_mode) {
        case _AudienceMode.everyone:
          final n = await repo.broadcastNotification(
            title: _title.text,
            message: _message.text,
          );
          if (!mounted) return;
          setState(() {
            _sending = false;
            _success = 'Đã gửi thông báo tới $n người dùng.';
            _title.clear();
            _message.clear();
          });
        case _AudienceMode.byRole:
          final n = await repo.broadcastNotification(
            title: _title.text,
            message: _message.text,
            role: _targetRole,
          );
          if (!mounted) return;
          setState(() {
            _sending = false;
            _success =
                'Đã gửi thông báo tới $n ${_roleLabel(_targetRole).toLowerCase()}.';
            _title.clear();
            _message.clear();
          });
        case _AudienceMode.specificUser:
          final recipient = _resolvedUser;
          if (recipient == null) {
            throw const Failure.validation(
                'Chưa chọn user. Hãy nhập email và nhấn Tìm.');
          }
          await repo.sendNotificationToUser(
            recipient: recipient,
            title: _title.text,
            message: _message.text,
          );
          if (!mounted) return;
          setState(() {
            _sending = false;
            _success = 'Đã gửi thông báo tới ${recipient.fullName}.';
            _title.clear();
            _message.clear();
          });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = Failure.from(e).message;
      });
    }
  }

  static String _roleLabel(UserRole r) => switch (r) {
        UserRole.jobSeeker => 'Ứng viên',
        UserRole.employer => 'Nhà tuyển dụng',
        UserRole.admin => 'Quản trị viên',
      };

  @override
  Widget build(BuildContext context) {
    return AdminPageShell(
      children: [
        const AdminPageHeader(
          eyebrow: 'Quản trị',
          title: 'Soạn thông báo',
          titleIcon: Icons.campaign_outlined,
          subtitle:
              'Gửi thông báo hệ thống tới một người dùng, một nhóm vai trò, hoặc toàn bộ nền tảng. Nội dung sẽ hiển thị ở mục Thông báo của người nhận.',
        ),
        const SizedBox(height: 24),
        if (_error != null) ...[
          AdminErrorBanner(
            message: _error!,
            onDismiss: () => setState(() => _error = null),
          ),
          const SizedBox(height: 16),
        ],
        if (_success != null) ...[
          AdminSuccessBanner(
            message: _success!,
            onDismiss: () => setState(() => _success = null),
          ),
          const SizedBox(height: 16),
        ],
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionLabel('Phạm vi gửi'),
              const SizedBox(height: 8),
              _audienceSelector(),
              if (_mode == _AudienceMode.byRole) ...[
                const SizedBox(height: 16),
                _roleSelector(),
              ],
              if (_mode == _AudienceMode.specificUser) ...[
                const SizedBox(height: 16),
                _emailLookup(),
              ],
              const SizedBox(height: 24),
              const _SectionLabel('Tiêu đề'),
              const SizedBox(height: 8),
              TextField(
                controller: _title,
                maxLength: 120,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'VD: Cập nhật tính năng mới trên JobHub',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const _SectionLabel('Nội dung'),
              const SizedBox(height: 8),
              TextField(
                controller: _message,
                maxLength: 1000,
                maxLines: 6,
                minLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Mô tả chi tiết thông báo…',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_outlined),
                    label: Text(_sending ? 'Đang gửi…' : 'Gửi thông báo'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _audienceSelector() {
    return RadioGroup<_AudienceMode>(
      groupValue: _mode,
      onChanged: (v) {
        if (v != null) setState(() => _mode = v);
      },
      child: Column(
        children: [
          for (final entry in const [
            (_AudienceMode.everyone, 'Toàn bộ user', Icons.public,
                'Gửi tới tất cả tài khoản đang hoạt động.'),
            (_AudienceMode.byRole, 'Theo vai trò', Icons.groups_outlined,
                'Chọn Ứng viên hoặc Nhà tuyển dụng.'),
            (_AudienceMode.specificUser, 'Một user cụ thể',
                Icons.person_outline, 'Nhập email để tìm user.'),
          ])
            RadioListTile<_AudienceMode>(
              value: entry.$1,
              contentPadding: EdgeInsets.zero,
              title: Row(
                children: [
                  Icon(entry.$3, size: 18, color: AppColors.inkSoft),
                  const SizedBox(width: 8),
                  Text(entry.$2,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, color: AppColors.ink)),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(left: 26, top: 2),
                child: Text(entry.$4,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.inkMuted)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _roleSelector() {
    return Wrap(
      spacing: 10,
      children: [
        for (final r in const [UserRole.jobSeeker, UserRole.employer])
          ChoiceChip(
            label: Text(_roleLabel(r)),
            selected: _targetRole == r,
            onSelected: (sel) {
              if (sel) setState(() => _targetRole = r);
            },
          ),
      ],
    );
  }

  Widget _emailLookup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _email,
                onSubmitted: (_) => _lookupEmail(),
                decoration: const InputDecoration(
                  hintText: 'user@example.com',
                  prefixIcon: Icon(Icons.alternate_email),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _lookingUp ? null : _lookupEmail,
              icon: _lookingUp
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search),
              label: const Text('Tìm'),
            ),
          ],
        ),
        if (_emailLookupError != null) ...[
          const SizedBox(height: 8),
          Text(_emailLookupError!,
              style: const TextStyle(color: AppColors.danger, fontSize: 12)),
        ],
        if (_resolvedUser != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary50,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.primary100),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary,
                  child: Text(_resolvedUser!.initial,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_resolvedUser!.fullName.isEmpty
                          ? 'Người dùng'
                          : _resolvedUser!.fullName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink)),
                      Text(_resolvedUser!.email,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.inkMuted)),
                      Text(_roleLabel(_resolvedUser!.role),
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
          letterSpacing: 0.3,
        ),
      );
}
