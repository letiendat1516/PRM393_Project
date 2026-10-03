import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/failure.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/ui_primitives.dart';
import '../viewmodels/create_job_viewmodel.dart';
import '../viewmodels/employer_providers.dart';
import '../widgets/employer_guard.dart';
import '../widgets/employer_page_header.dart';
import '../widgets/employer_state_banners.dart';
import '../widgets/form_step_header.dart';
import '../widgets/job_form_steps.dart';
import '../widgets/job_preview_panel.dart';

/// pages/CreateJobPage.jsx (+ mobile Edit Job screen) as a 3-step form:
/// 1 Thông tin · 2 Lương & địa điểm · 3 Kỹ năng & xem trước.
class CreateJobPage extends ConsumerStatefulWidget {
  const CreateJobPage({super.key, this.editJobId});
  final String? editJobId;

  @override
  ConsumerState<CreateJobPage> createState() => _CreateJobPageState();
}

class _CreateJobPageState extends ConsumerState<CreateJobPage> {
  final _controllers = JobFormControllers();
  final _scroll = ScrollController();

  bool get _editing => widget.editJobId != null;

  @override
  void initState() {
    super.initState();
    // Seed controllers with the defaults (currency VND, positions 1, …).
    _controllers.syncFrom(ref.read(createJobViewModelProvider(widget.editJobId)).input);
  }

  @override
  void dispose() {
    _controllers.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollTop() {
    if (_scroll.hasClients) {
      _scroll.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = createJobViewModelProvider(widget.editJobId);

    // Re-sync text controllers when the input was replaced from outside.
    ref.listen(provider.select((s) => s.syncVersion), (_, _) {
      _controllers.syncFrom(ref.read(provider).input);
    });
    // Navigate away once the submit succeeded.
    ref.listen(provider.select((s) => s.done), (prev, done) {
      if (done && prev != true) {
        final s = ref.read(provider);
        showSuccess(
          context,
          _editing
              ? 'Đã lưu thay đổi tin tuyển dụng.'
              : s.requireApproval
                  ? 'Đã tạo tin tuyển dụng. Tin đang chờ quản trị viên duyệt.'
                  : 'Đã đăng tin tuyển dụng.',
        );
        context.go(AppRoutes.employerJobs);
      }
    });
    // Scroll to the top when a step changes or an error banner appears.
    ref.listen(provider.select((s) => (s.step, s.error != null)), (_, _) => _scrollTop());

    return EmployerGuard(
      deniedTitle: _editing
          ? 'Bạn không thể chỉnh sửa tin tuyển dụng'
          : 'Bạn không thể đăng tin tuyển dụng',
      builder: (context, user) => _buildForm(context, user, provider),
    );
  }

  Widget _buildForm(BuildContext context, UserModel user,
      AutoDisposeStateNotifierProvider<CreateJobViewModel, CreateJobState> provider) {
    final state = ref.watch(provider);
    final vm = ref.read(provider.notifier);
    final profile = ref.watch(employerProfileProvider).valueOrNull;
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 1024;

    final preview = JobPreviewPanel(
      job: buildPreviewJob(
        state,
        employerId: user.uid,
        employerName: (profile?.companyName ?? '').trim().isEmpty
            ? user.fullName
            : profile!.companyName,
        employerLogoUrl: profile?.logoUrl,
        employerCity: profile?.city,
      ),
      requireApproval: state.requireApproval,
      editing: _editing,
    );

    Widget body;
    if (state.loading) {
      body = const StateCard(text: 'Đang tải tin tuyển dụng...', spinner: true);
    } else if (state.loadError != null) {
      body = StateCard.error(
        text: Failure.from(state.loadError!).message,
        action: OutlinedButton(
          onPressed: () => context.go(AppRoutes.employerJobs),
          child: const Text('Về danh sách tin'),
        ),
      );
    } else {
      final stepWidget = switch (state.step) {
        0 => JobInfoStep(c: _controllers, state: state, vm: vm),
        1 => JobSalaryLocationStep(c: _controllers, state: state, vm: vm),
        _ => JobSkillsStep(state: state, vm: vm, preview: wide ? null : preview),
      };
      final formColumn = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FormStepHeader(
            titles: CreateJobState.stepTitles,
            current: state.step,
            onTap: vm.goTo,
          ),
          const SizedBox(height: 20),
          stepWidget,
          const SizedBox(height: 16),
          _NavBar(state: state, vm: vm, editing: _editing),
        ],
      );
      body = wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: formColumn),
                const SizedBox(width: 24),
                Expanded(flex: 2, child: preview),
              ],
            )
          : formColumn;
    }

    return EmployerPageShell(
      maxWidth: wide ? 1152 : 896,
      scrollController: _scroll,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EmployerPageHeader(
            eyebrow: _editing ? 'Chỉnh sửa tin tuyển dụng' : 'Đăng tin tuyển dụng',
            title: _editing
                ? (state.input.title.trim().isEmpty ? 'Chỉnh sửa tin tuyển dụng' : state.input.title)
                : 'Tạo tin tuyển dụng mới',
            subtitle: _editing
                ? 'Cập nhật nội dung tin. Trạng thái duyệt của tin được giữ nguyên.'
                : state.requireApproval
                    ? 'Tin tuyển dụng mới sẽ ở trạng thái chờ duyệt trước khi được hiển thị công khai.'
                    : 'Tin tuyển dụng sẽ được hiển thị công khai ngay sau khi đăng.',
            action: TextButton.icon(
              onPressed: () => context.go(AppRoutes.employerJobs),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Danh sách tin'),
            ),
          ),
          if (state.hasDraft && !_editing) ...[
            const SizedBox(height: 24),
            _DraftBanner(savedAt: state.draftSavedAt, vm: vm),
          ],
          if (state.error != null) ...[
            const SizedBox(height: 24),
            ReasonsErrorBanner(
              title: state.error!.title,
              message: state.error!.message,
              reasons: state.error!.reasons,
              onClose: vm.clearError,
            ),
          ],
          const SizedBox(height: 32),
          body,
        ],
      ),
    );
  }
}

class _DraftBanner extends StatelessWidget {
  const _DraftBanner({required this.savedAt, required this.vm});
  final DateTime? savedAt;
  final CreateJobViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary50,
        border: Border.all(color: AppColors.primary100),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 10,
        children: [
          const Icon(Icons.history, size: 18, color: AppColors.primary),
          Text(
            savedAt == null
                ? 'Bạn có một bản nháp tin tuyển dụng chưa đăng.'
                : 'Bạn có một bản nháp chưa đăng (lưu lúc ${Formatters.dateTime(savedAt)}).',
            style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500),
          ),
          ElevatedButton(
            onPressed: vm.restoreDraft,
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
            child: const Text('Khôi phục bản nháp'),
          ),
          TextButton(onPressed: vm.discardDraft, child: const Text('Bỏ bản nháp')),
        ],
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({required this.state, required this.vm, required this.editing});
  final CreateJobState state;
  final CreateJobViewModel vm;
  final bool editing;

  @override
  Widget build(BuildContext context) {
    final last = state.step == CreateJobState.stepTitles.length - 1;
    final submitLabel = state.saving
        ? (editing ? 'Đang lưu...' : 'Đang tạo tin...')
        : (editing ? 'Lưu thay đổi' : 'Tạo tin tuyển dụng');
    return Row(
      children: [
        if (state.step > 0)
          OutlinedButton.icon(
            onPressed: state.saving ? null : vm.back,
            icon: const Icon(Icons.chevron_left, size: 18),
            label: const Text('Quay lại'),
          ),
        const Spacer(),
        if (!editing && state.draftSavedAt != null && !state.hasDraft)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text(
              'Đã lưu nháp ${Formatters.time(state.draftSavedAt)}',
              style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
            ),
          ),
        if (!last)
          ElevatedButton.icon(
            onPressed: vm.next,
            icon: const Icon(Icons.chevron_right, size: 18),
            label: const Text('Tiếp tục'),
          )
        else
          ElevatedButton.icon(
            onPressed: state.saving ? null : vm.submit,
            icon: state.saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Icon(editing ? Icons.save_outlined : Icons.send_outlined, size: 18),
            label: Text(submitLabel),
          ),
      ],
    );
  }
}
