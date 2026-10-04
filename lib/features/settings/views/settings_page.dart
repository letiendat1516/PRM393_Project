import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/enums.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/brand.dart';
import '../../../shared/widgets/ui_primitives.dart';
import '../../auth/viewmodels/current_user_provider.dart';
import '../../notifications/widgets/notification_type_meta.dart';
import '../viewmodels/settings_viewmodel.dart';
import '../widgets/adaptive_colors.dart';
import '../widgets/change_password_dialog.dart';
import '../widgets/settings_section.dart';

/// Settings (FLUTTER_REBUILD_PLAN TVV5 #3): theme, language, notification
/// toggles, account, local data, about. Everything persists via
/// SharedPreferences through [settingsProvider].
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  void initState() {
    super.initState();
    // Session / search counters may have changed on other screens.
    Future.microtask(() {
      if (mounted) ref.read(settingsProvider.notifier).refreshCounters();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider);
    final vm = ref.read(settingsProvider.notifier);
    final user = ref.watch(currentUserProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 1024;

    final appearance = SettingsSection(
      icon: Icons.palette_outlined,
      title: 'Giao diện',
      subtitle: 'Chế độ hiển thị của ứng dụng.',
      children: [
        RadioGroup<ThemeMode>(
          groupValue: s.themeMode,
          onChanged: (v) {
            if (v != null) vm.setThemeMode(v);
          },
          child: const Column(
            children: [
              RadioListTile<ThemeMode>(
                value: ThemeMode.system,
                title: Text('Theo hệ thống'),
                secondary: Icon(Icons.brightness_auto_outlined),
                contentPadding: EdgeInsets.zero,
              ),
              RadioListTile<ThemeMode>(
                value: ThemeMode.light,
                title: Text('Sáng'),
                secondary: Icon(Icons.light_mode_outlined),
                contentPadding: EdgeInsets.zero,
              ),
              RadioListTile<ThemeMode>(
                value: ThemeMode.dark,
                title: Text('Tối'),
                secondary: Icon(Icons.dark_mode_outlined),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ],
    );

    final language = SettingsSection(
      icon: Icons.translate_outlined,
      title: 'Ngôn ngữ',
      subtitle: 'Ngôn ngữ hiển thị.',
      children: [
        RadioGroup<String>(
          groupValue: s.locale,
          onChanged: (v) {
            if (v != null) vm.setLocale(v);
          },
          child: const Column(
            children: [
              RadioListTile<String>(
                value: 'vi',
                title: Text('Tiếng Việt'),
                contentPadding: EdgeInsets.zero,
              ),
              RadioListTile<String>(
                value: 'en',
                title: Text('English'),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        // Honest caption: there is no l10n layer yet — app copy is Vietnamese
        // only; the toggle drives the Material locale (date pickers, dialog
        // buttons, tooltips, number/date formats).
        const SettingsHint(
          'Nội dung ứng dụng hiện chỉ hiển thị bằng tiếng Việt. Lựa chọn này áp dụng cho các '
          'thành phần hệ thống (lịch, hộp thoại, định dạng ngày và số).',
        ),
      ],
    );

    final notifications = SettingsSection(
      icon: Icons.notifications_none,
      title: 'Thông báo',
      subtitle: 'Thông báo đẩy (FCM) trên thiết bị này.',
      children: [
        SwitchListTile.adaptive(
          value: s.notificationsEnabled,
          onChanged: vm.setNotifications,
          title: const Text('Nhận thông báo đẩy'),
          subtitle: const Text('Bật/tắt toàn bộ thông báo đẩy.'),
          contentPadding: EdgeInsets.zero,
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: Text('Loại thông báo',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: context.inkMutedColor,
                  letterSpacing: 0.4)),
        ),
        for (final t in NotificationToggle.all)
          SwitchListTile.adaptive(
            value: s.notificationsEnabled && s.isTypeEnabled(t.key),
            // Persist every wire value the toggle governs (JOB_APPROVED +
            // JOB_REJECTED, SYSTEM + EMPLOYER_VERIFIED) — the delivery side
            // checks prefs by the payload's own NotificationType wire value.
            onChanged:
                s.notificationsEnabled ? (v) => vm.setNotificationTypes(t.wireKeys, v) : null,
            secondary: Icon(t.icon, color: context.inkSoftColor),
            title: Text(t.label),
            subtitle: Text(t.subtitle),
            contentPadding: EdgeInsets.zero,
          ),
      ],
    );

    final account = SettingsSection(
      icon: Icons.person_outline,
      title: 'Tài khoản',
      children: [
        user.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: RouteLoader(),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: AlertError(
              message: 'Không tải được thông tin tài khoản.',
              onRetry: () => ref.invalidate(currentUserProvider),
            ),
          ),
          data: (u) => u == null
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bạn chưa đăng nhập.',
                          style: TextStyle(color: context.inkSoftColor)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => context.go(AppRoutes.login),
                        child: const Text('Đăng nhập'),
                      ),
                    ],
                  ),
                )
              : _AccountBody(user: u),
        ),
      ],
    );

    final data = SettingsSection(
      icon: Icons.storage_outlined,
      title: 'Dữ liệu',
      subtitle: 'Dữ liệu lưu cục bộ trên thiết bị này.',
      children: [
        // The 3-word trailing "Xoá phiên chấm điểm" previously squeezed
        // the title column into ~3 lines on 360dp phones ("Phiên chấm /
        // điểm / đã lưu"). Switched to a trash IconButton so the title
        // keeps the full remaining width — the destructive meaning stays
        // obvious via the icon colour + confirm dialog.
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.auto_awesome_outlined, color: context.inkSoftColor),
          title: const Text('Phiên chấm điểm đã lưu'),
          subtitle: Text(
            s.savedSessions == 0
                ? 'Chưa có phiên chấm điểm nào.'
                : '${s.savedSessions} phiên (tối đa 20).',
          ),
          trailing: IconButton(
            tooltip: 'Xoá phiên chấm điểm',
            color: AppColors.danger,
            onPressed: s.savedSessions == 0 || s.clearing
                ? null
                : () => _confirmClear(
                      context,
                      title: 'Xoá phiên chấm điểm',
                      message:
                          'Xoá toàn bộ ${s.savedSessions} phiên chấm điểm AI đã lưu trên thiết bị? Thao tác này không thể hoàn tác.',
                      onConfirm: vm.clearAiSessions,
                      successMessage: 'Đã xoá phiên chấm điểm.',
                    ),
            icon: const Icon(Icons.delete_outline),
          ),
        ),
        const Divider(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.history, color: context.inkSoftColor),
          title: const Text('Lịch sử tìm kiếm'),
          subtitle: Text(
            s.searchHistoryCount == 0
                ? 'Chưa có từ khoá nào.'
                : '${s.searchHistoryCount} từ khoá gần đây.',
          ),
          trailing: IconButton(
            tooltip: 'Xoá lịch sử tìm kiếm',
            color: AppColors.danger,
            onPressed: s.searchHistoryCount == 0 || s.clearing
                ? null
                : () => _confirmClear(
                      context,
                      title: 'Xoá lịch sử tìm kiếm',
                      message: 'Xoá các từ khoá tìm kiếm gần đây trên thiết bị?',
                      onConfirm: vm.clearSearchHistory,
                      successMessage: 'Đã xoá lịch sử tìm kiếm.',
                    ),
            icon: const Icon(Icons.delete_outline),
          ),
        ),
      ],
    );

    final about = SettingsSection(
      icon: Icons.info_outline,
      title: 'Giới thiệu',
      children: [
        // AboutListTile forces its own non-zero contentPadding, so the
        // icon ended up ~16dp further right than the "Phiên bản" row
        // below (which uses contentPadding: EdgeInsets.zero). Switched to
        // a plain ListTile with matching zero padding so both leading
        // icons share the same left edge; onTap opens the stock about
        // dialog the way AboutListTile would have.
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.info_outline, color: context.inkSoftColor),
          title: const Text('Về JobHub'),
          trailing: Icon(Icons.chevron_right, color: context.inkMutedColor),
          onTap: () => showAboutDialog(
            context: context,
            applicationName: 'JobHub',
            applicationVersion: '1.0.0',
            applicationIcon: const BrandLogo(compact: true, size: 28),
            applicationLegalese: 'Nền tảng tuyển dụng Flutter — đồ án PRM393',
            children: [
              const SizedBox(height: 12),
              Text('Nền tảng tuyển dụng Flutter — đồ án PRM393',
                  style: TextStyle(color: context.inkSoftColor, height: 1.5)),
            ],
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.verified_outlined, color: context.inkSoftColor),
          title: const Text('Phiên bản'),
          trailing: Text('1.0.0', style: TextStyle(color: context.inkMutedColor)),
        ),
      ],
    );

    final body = isWide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    appearance,
                    const SizedBox(height: 16),
                    language,
                    const SizedBox(height: 16),
                    about,
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    account,
                    const SizedBox(height: 16),
                    notifications,
                    const SizedBox(height: 16),
                    data,
                  ],
                ),
              ),
            ],
          )
        : Column(
            children: [
              appearance,
              const SizedBox(height: 16),
              language,
              const SizedBox(height: 16),
              notifications,
              const SizedBox(height: 16),
              account,
              const SizedBox(height: 16),
              data,
              const SizedBox(height: 16),
              about,
            ],
          );

    return AppScaffold(
      title: 'Cài đặt',
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: body,
      ),
    );
  }

  Future<void> _confirmClear(
    BuildContext context, {
    required String title,
    required String message,
    required Future<void> Function() onConfirm,
    required String successMessage,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.x2l)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Huỷ')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await onConfirm();
      if (context.mounted) showSuccess(context, successMessage);
    } catch (e) {
      if (context.mounted) showFailure(context, e);
    }
  }
}

class _AccountBody extends ConsumerWidget {
  const _AccountBody({required this.user});
  final UserModel user;

  static String _roleName(UserRole r) => switch (r) {
        UserRole.jobSeeker => 'Ứng viên',
        UserRole.employer => 'Nhà tuyển dụng',
        UserRole.admin => 'Quản trị viên',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary,
                backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                child: user.photoUrl == null
                    ? Text(user.initial,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16))
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.fullName.isEmpty ? 'Người dùng' : user.fullName,
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700, color: context.inkColor)),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: context.primaryWashColor,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(_roleName(user.role),
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: context.accentColor)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        SettingsInfoRow(label: 'Email', value: user.email),
        SettingsInfoRow(label: 'Vai trò', value: _roleName(user.role)),
        if (user.isVerified)
          const SettingsInfoRow(label: 'Xác minh', value: 'Đã xác minh'),
        const Divider(),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: () async {
                final changed = await showChangePasswordDialog(context);
                if (changed && context.mounted) {
                  showSuccess(context, 'Đổi mật khẩu thành công.');
                }
              },
              icon: const Icon(Icons.lock_outline, size: 18),
              label: const Text('Đổi mật khẩu'),
            ),
            OutlinedButton.icon(
              onPressed: () => _signOut(context, ref),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.dangerBorder),
              ),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Đăng xuất'),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.x2l)),
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất khỏi JobHub?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Huỷ')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(settingsProvider.notifier).signOut();
      if (context.mounted) context.go(AppRoutes.home);
    } catch (e) {
      if (context.mounted) showFailure(context, e);
    }
  }
}
