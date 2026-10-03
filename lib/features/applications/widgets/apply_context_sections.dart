import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/jobseeker_profile_model.dart';
import '../../../shared/models/resume_model.dart';
import '../viewmodels/apply_viewmodel.dart';
import 'applications_common.dart';

/// `section.rounded-xl border border-slate-200 p-4` with an uppercase label.
class ApplySection extends StatelessWidget {
  const ApplySection({super.key, required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.inkMuted,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// "Hồ sơ ứng viên": full name + headline · city (with web fallbacks).
class ApplyProfileSection extends StatelessWidget {
  const ApplyProfileSection({super.key, required this.profile});
  final JobSeekerProfile profile;

  @override
  Widget build(BuildContext context) {
    final headline = (profile.headline ?? '').trim();
    final city = (profile.city ?? '').trim();
    return ApplySection(
      label: 'Hồ sơ ứng viên',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (profile.fullName ?? '').trim().isEmpty ? 'Chưa cập nhật họ tên' : profile.fullName!,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.ink),
          ),
          const SizedBox(height: 2),
          Text(
            '${headline.isEmpty ? 'Chưa có tiêu đề hồ sơ' : headline} · '
            '${city.isEmpty ? 'Chưa có địa điểm' : city}',
            style: const TextStyle(fontSize: 14, color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }
}

/// "CV sẽ được gửi": selected resume or the red "no CV" message + link.
class ApplyResumeSection extends StatelessWidget {
  const ApplyResumeSection({super.key, required this.resume, this.onNavigate});
  final ResumeModel? resume;

  /// Called before navigating to /ho-so (ApplyModal closes itself).
  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context) {
    final r = resume;
    return ApplySection(
      label: 'CV sẽ được gửi',
      child: r != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.title.trim().isNotEmpty ? r.title : r.fileName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.ink),
                ),
                if (r.fileName.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(r.fileName, style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                ],
              ],
            )
          : NoResumeNotice(onNavigate: onNavigate),
    );
  }
}

/// 'Bạn chưa có CV chính. Hãy tải CV trong hồ sơ cá nhân.' + 'Tải CV ngay'.
class NoResumeNotice extends StatelessWidget {
  const NoResumeNotice({super.key, this.onNavigate});
  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          ApplyState.noResumeMessage,
          style: TextStyle(fontSize: 14, color: AppColors.red600, height: 1.5),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () {
            // Capture the router BEFORE the modal pops its own route so the
            // navigation never depends on a dialog-scoped context.
            final router = GoRouter.of(context);
            onNavigate?.call();
            router.push(AppRoutes.resumeProfile);
          },
          child: const Text(
            'Tải CV ngay',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}

/// 'Hồ sơ còn thiếu: ...' (amber) and 'Bạn đã ứng tuyển công việc này.' (primary).
class ApplyWarnings extends StatelessWidget {
  const ApplyWarnings({super.key, required this.state});
  final ApplyState state;

  @override
  Widget build(BuildContext context) {
    final missing = state.missingProfile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (missing.isNotEmpty) ...[
          TintedNote(child: Text('Hồ sơ còn thiếu: ${missing.join(', ')}.')),
          const SizedBox(height: 12),
        ],
        if (state.alreadyApplied) ...[
          const TintedNote(
            background: AppColors.primary50,
            child: Text(
              ApplyState.alreadyAppliedMessage,
              style: TextStyle(color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

/// Textarea 'Thư giới thiệu (không bắt buộc)', maxLength 5000, rows=5 —
/// ApplyModal.jsx:143-152: no placeholder, no character counter.
class CoverLetterField extends StatefulWidget {
  const CoverLetterField({super.key, required this.value, required this.onChanged, this.rows = 5});
  final String value;
  final ValueChanged<String> onChanged;
  final int rows;

  @override
  State<CoverLetterField> createState() => _CoverLetterFieldState();
}

class _CoverLetterFieldState extends State<CoverLetterField> {
  late final TextEditingController _controller = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(covariant CoverLetterField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.value = _controller.value.copyWith(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thư giới thiệu (không bắt buộc)',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          // Enforce the 5000-char limit like the <textarea maxLength> but
          // suppress Flutter's default '0/5000' counter (web has none).
          maxLength: ApplyState.coverLetterMax,
          buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
          maxLines: widget.rows,
          minLines: widget.rows,
          onChanged: widget.onChanged,
          textInputAction: TextInputAction.newline,
          decoration: const InputDecoration(),
        ),
      ],
    );
  }
}

/// Success block: 'Ứng tuyển thành công.' + 'Theo dõi hồ sơ ứng tuyển' → /applications.
class ApplySuccessBlock extends StatelessWidget {
  const ApplySuccessBlock({super.key, this.onNavigate});
  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context) {
    return TintedNote(
      background: AppColors.emerald50,
      padding: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ứng tuyển thành công.',
            style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.emerald700),
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: () {
              final router = GoRouter.of(context);
              onNavigate?.call();
              router.go(AppRoutes.myApplications);
            },
            child: const Text(
              'Theo dõi hồ sơ ứng tuyển',
              style: TextStyle(
                color: AppColors.emerald700,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Guest / wrong-role banners shown instead of the form.
class ApplyBlockerBanner extends StatelessWidget {
  const ApplyBlockerBanner({super.key, required this.blocker, this.onNavigate});
  final ApplyBlocker blocker;
  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context) {
    switch (blocker) {
      case ApplyBlocker.guest:
        return TintedNote(
          padding: 16,
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('Vui lòng '),
              InkWell(
                onTap: () {
                  final router = GoRouter.of(context);
                  onNavigate?.call();
                  router.push(AppRoutes.login);
                },
                child: const Text(
                  'đăng nhập',
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
              ),
              const Text(' để ứng tuyển.'),
            ],
          ),
        );
      case ApplyBlocker.wrongRole:
        return const RedBanner(message: ApplyState.wrongRoleMessage);
      case ApplyBlocker.none:
        return const SizedBox.shrink();
    }
  }
}
