import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/failure.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/job_model.dart';
import '../../../shared/models/resume_model.dart';
import '../../../shared/widgets/public_layout.dart';
import '../../../shared/widgets/ui_primitives.dart';
import '../viewmodels/applications_providers.dart';
import '../viewmodels/apply_viewmodel.dart';
import '../widgets/applications_common.dart';
import '../widgets/apply_context_sections.dart';

/// Mobile-only apply wizard (FLUTTER_REBUILD_PLAN) — /viec-lam/:id/ung-tuyen.
/// 3 steps: chọn CV → thư giới thiệu → xác nhận. Same ApplyViewModel and
/// server-side gates as ApplyModal.
class ApplyJobPage extends ConsumerStatefulWidget {
  const ApplyJobPage({super.key, required this.jobId});
  final String jobId;

  @override
  ConsumerState<ApplyJobPage> createState() => _ApplyJobPageState();
}

class _ApplyJobPageState extends ConsumerState<ApplyJobPage> {
  int _step = 0;

  static const _titles = ['Chọn CV', 'Thư giới thiệu', 'Xác nhận'];

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.jobDetailOf(widget.jobId));
    }
  }

  bool _canContinue(ApplyState s) {
    if (s.phase != ApplyPhase.ready && s.phase != ApplyPhase.error) return false;
    if (s.alreadyApplied || s.missingProfile.isNotEmpty) return false;
    return switch (_step) {
      0 => s.resume != null,
      1 => s.coverLetter.length <= ApplyState.coverLetterMax,
      _ => s.canSubmit,
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(applyViewModelProvider(widget.jobId));
    final vm = ref.read(applyViewModelProvider(widget.jobId).notifier);
    final jobAsync = ref.watch(applyJobProvider(widget.jobId));
    final job = state.context?.job ?? jobAsync.valueOrNull;

    return PublicLayout(
      child: ApplicationsPageShell(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BackTextLink(label: '← Quay lại tin tuyển dụng', onTap: _back),
              const SizedBox(height: 24),
              _JobHeader(job: job, loading: jobAsync.isLoading && job == null),
              const SizedBox(height: 24),
              if (state.blocker != ApplyBlocker.none)
                AppCard(
                  padding: const EdgeInsets.all(24),
                  child: ApplyBlockerBanner(blocker: state.blocker),
                )
              else if (state.phase == ApplyPhase.success)
                AppCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ApplySuccessBlock(),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ElevatedButton(
                            onPressed: () => context.go(AppRoutes.myApplications),
                            child: const Text('Theo dõi hồ sơ ứng tuyển'),
                          ),
                          OutlinedButton(
                            onPressed: () => context.go(AppRoutes.jobs),
                            child: const Text('Khám phá việc làm'),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              else if (state.phase == ApplyPhase.validating && state.context == null)
                const AppCard(
                  padding: EdgeInsets.all(40),
                  child: RouteLoader(label: 'Đang kiểm tra hồ sơ và CV...'),
                )
              else if (state.context == null)
                AppCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RedBanner(message: state.error ?? Failure.defaultMessage),
                      const SizedBox(height: 12),
                      OutlinedButton(onPressed: vm.retry, child: const Text('Thử lại')),
                    ],
                  ),
                )
              else
                AppCard(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                  child: Stepper(
                    currentStep: _step,
                    physics: const NeverScrollableScrollPhysics(),
                    onStepTapped: (i) {
                      if (i < _step) setState(() => _step = i);
                    },
                    onStepContinue: () async {
                      if (_step < 2) {
                        setState(() => _step++);
                      } else {
                        await vm.submit();
                      }
                    },
                    onStepCancel: _step == 0 ? _back : () => setState(() => _step--),
                    controlsBuilder: (ctx, details) => Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Row(
                        children: [
                          ElevatedButton(
                            onPressed: _canContinue(state) && !state.isBusy
                                ? details.onStepContinue
                                : null,
                            child: Text(
                              _step < 2
                                  ? 'Tiếp tục'
                                  : (state.phase == ApplyPhase.submitting
                                      ? 'Đang gửi...'
                                      : 'Xác nhận ứng tuyển'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: state.isBusy ? null : details.onStepCancel,
                            child: Text(_step == 0 ? 'Đóng' : 'Quay lại'),
                          ),
                        ],
                      ),
                    ),
                    steps: [
                      Step(
                        title: Text(_titles[0]),
                        subtitle: Text(
                          state.resume == null
                              ? 'Chọn CV sẽ gửi cho nhà tuyển dụng'
                              : (state.resume!.title.isNotEmpty
                                  ? state.resume!.title
                                  : state.resume!.fileName),
                        ),
                        isActive: _step >= 0,
                        state: _step > 0 ? StepState.complete : StepState.indexed,
                        content: _ResumeStep(state: state, onSelect: vm.selectResume),
                      ),
                      Step(
                        title: Text(_titles[1]),
                        subtitle: Text(
                          state.coverLetter.trim().isEmpty
                              ? 'Không bắt buộc'
                              : '${state.coverLetter.length}/${ApplyState.coverLetterMax} ký tự',
                        ),
                        isActive: _step >= 1,
                        state: _step > 1 ? StepState.complete : StepState.indexed,
                        content: CoverLetterField(
                          value: state.coverLetter,
                          onChanged: vm.setCoverLetter,
                          rows: 8,
                        ),
                      ),
                      Step(
                        title: Text(_titles[2]),
                        subtitle: const Text('Kiểm tra lại thông tin trước khi gửi'),
                        isActive: _step >= 2,
                        state: state.phase == ApplyPhase.error ? StepState.error : StepState.indexed,
                        content: _ConfirmStep(state: state, job: job),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JobHeader extends StatelessWidget {
  const _JobHeader({required this.job, required this.loading});
  final JobModel? job;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final j = job;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ApplicationsPageHeader(eyebrow: 'Ứng tuyển', title: 'Ứng tuyển công việc'),
        const SizedBox(height: 16),
        if (loading)
          const Text('Đang tải tin tuyển dụng...',
              style: TextStyle(color: AppColors.inkMuted, fontSize: 14))
        else if (j == null)
          const RedBanner(message: 'Không tìm thấy công việc.')
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CompanyLogoTile(name: j.employerName, logoUrl: j.employerLogoUrl, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(j.jobTitle,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
                    const SizedBox(height: 2),
                    Text(
                      '${j.employerName} · ${(j.location ?? '').trim().isNotEmpty ? j.location : j.city}',
                      style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
                    ),
                    if (j.applicationDeadline != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Hạn nộp: ${Formatters.deadlineFull(j.applicationDeadline)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// Step 1 — profile summary, warnings, resume picker (RadioGroup).
class _ResumeStep extends StatelessWidget {
  const _ResumeStep({required this.state, required this.onSelect});
  final ApplyState state;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final ctx = state.context!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ApplyProfileSection(profile: ctx.profile),
        const SizedBox(height: 16),
        ApplyWarnings(state: state),
        if (ctx.resumes.isEmpty)
          ApplySection(label: 'CV sẽ được gửi', child: const NoResumeNotice())
        else
          ApplySection(
            label: 'CV sẽ được gửi',
            child: RadioGroup<String>(
              groupValue: state.selectedResumeId,
              onChanged: onSelect,
              child: Column(
                children: [
                  for (final r in ctx.resumes)
                    _ResumeTile(
                      resume: r,
                      isPrimary: r.isPrimary || r.resumeId == ctx.profile.primaryResumeId,
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ResumeTile extends StatelessWidget {
  const _ResumeTile({required this.resume, required this.isPrimary});
  final ResumeModel resume;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final title = resume.title.trim().isNotEmpty ? resume.title : resume.fileName;
    return RadioListTile<String>(
      value: resume.resumeId,
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Row(
        children: [
          Flexible(
            child: Text(title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ),
          if (isPrimary) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary50,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: const Text('CV chính',
                  style: TextStyle(
                      fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
          ],
        ],
      ),
      subtitle: Text(
        [
          if (resume.fileName.trim().isNotEmpty && resume.fileName != title) resume.fileName,
          if (resume.uploadDate != null) 'Tải lên ${Formatters.date(resume.uploadDate)}',
          if (resume.hasAnalysis) 'Đã phân tích AI',
        ].join(' · '),
        style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
      ),
    );
  }
}

/// Step 3 — summary of what will be sent + error banner.
class _ConfirmStep extends StatelessWidget {
  const _ConfirmStep({required this.state, required this.job});
  final ApplyState state;
  final JobModel? job;

  @override
  Widget build(BuildContext context) {
    final ctx = state.context!;
    final letter = state.coverLetter.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (job != null) ...[
          ApplySection(
            label: 'Vị trí ứng tuyển',
            child: Text('${job!.jobTitle} · ${job!.employerName}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          ),
          const SizedBox(height: 16),
        ],
        ApplyProfileSection(profile: ctx.profile),
        const SizedBox(height: 16),
        ApplyResumeSection(resume: state.resume),
        const SizedBox(height: 16),
        ApplySection(
          label: 'Thư giới thiệu',
          child: Text(
            letter.isEmpty ? 'Không có thư giới thiệu.' : letter,
            style: const TextStyle(fontSize: 14, color: AppColors.inkSoft, height: 1.6),
          ),
        ),
        const SizedBox(height: 16),
        ApplyWarnings(state: state),
        if (state.error != null) RedBanner(message: state.error!, padding: 12),
      ],
    );
  }
}
