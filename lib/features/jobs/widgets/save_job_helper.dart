import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/failure.dart';
import '../../../shared/models/job_model.dart';
import '../../../shared/widgets/ui_primitives.dart';
import '../../auth/viewmodels/current_user_provider.dart';
import '../viewmodels/saved_jobs_provider.dart';

/// Bookmark toggle used by every job list/detail in this feature: guests get
/// a login prompt, other roles a forbidden message, seekers toggle
/// savedJobs/{uid_jobId}.
Future<void> handleToggleSave(
  BuildContext context,
  WidgetRef ref,
  JobModel job,
) async {
  final me = ref.read(currentUserProvider).valueOrNull;
  if (me == null) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Vui lòng đăng nhập để lưu tin.'),
          backgroundColor: AppColors.ink,
          action: SnackBarAction(
            label: 'Đăng nhập',
            textColor: Colors.white,
            onPressed: () => context.go(AppRoutes.login),
          ),
        ),
      );
    return;
  }
  final wasSaved =
      ref.read(savedJobIdsProvider).valueOrNull?.contains(job.jobId) ?? false;
  try {
    await toggleSavedJob(ref, job);
    if (context.mounted) {
      showSuccess(
        context,
        wasSaved ? 'Đã bỏ lưu tin tuyển dụng.' : 'Đã lưu tin tuyển dụng.',
      );
    }
  } on Failure catch (f) {
    if (context.mounted) showFailure(context, f);
  } catch (e) {
    if (context.mounted) showFailure(context, e);
  }
}
