import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/views/admin_dashboard_page.dart';
import '../../features/admin/views/admin_employers_page.dart';
import '../../features/admin/views/admin_pending_jobs_page.dart';
import '../../features/admin/views/admin_system_configuration_page.dart';
import '../../features/admin/views/admin_users_page.dart';
import '../../features/admin/views/ai_logs_page.dart';
import '../../features/admin/views/ai_stats_page.dart';
import '../../features/admin/views/catalog_management_page.dart';
import '../../features/applications/views/application_detail_page.dart';
import '../../features/applications/views/apply_job_page.dart';
import '../../features/applications/views/employer_application_review_page.dart';
import '../../features/applications/views/employer_applications_page.dart';
import '../../features/applications/views/my_applications_page.dart';
import '../../features/auth/viewmodels/current_user_provider.dart';
import '../../features/auth/views/forgot_password_page.dart';
import '../../features/auth/views/login_page.dart';
import '../../features/auth/views/onboarding_page.dart';
import '../../features/auth/views/register_employer_page.dart';
import '../../features/auth/views/register_page.dart';
import '../../features/chat/views/chat_room_page.dart';
import '../../features/chat/views/chats_page.dart';
import '../../features/employer/views/create_job_page.dart';
import '../../features/employer/views/employer_company_profile_page.dart';
import '../../features/employer/views/employer_dashboard_page.dart';
import '../../features/employer/views/employer_jobs_page.dart';
import '../../features/employer/views/job_applicants_page.dart';
import '../../features/home/views/forbidden_page.dart';
import '../../features/home/views/home_page.dart';
import '../../features/home/views/not_found_page.dart';
import '../../features/jobs/views/company_detail_page.dart';
import '../../features/jobs/views/job_detail_page.dart';
import '../../features/jobs/views/jobs_search_page.dart';
import '../../features/jobs/views/saved_jobs_page.dart';
import '../../features/notifications/views/notifications_page.dart';
import '../../features/profile/views/ai_analysis_page.dart';
import '../../features/profile/views/edit_profile_page.dart';
import '../../features/profile/views/resume_profile_page.dart';
import '../../features/recommendations/views/recommended_page.dart';
import '../../features/recommendations/views/session_detail_page.dart';
import '../../features/settings/views/settings_page.dart';
import '../../features/splash/views/splash_page.dart';
import '../../shared/widgets/nav_items.dart';
import '../providers.dart';
import '../utils/enums.dart';
import 'routes.dart';

/// Route table + guards mirroring frontend/src/routes/{AppRoutes,RoleGuard}.jsx
/// and utils/redirectByRole.js.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    refreshListenable: refresh,
    redirect: (ctx, state) {
      final loc = state.matchedLocation;
      final auth = ref.read(authStateProvider);
      final current = ref.read(currentUserProvider);
      final loggedIn = auth.valueOrNull != null;
      final role = current.valueOrNull?.role;
      final prefs = ref.read(prefsServiceProvider);

      if (loc == AppRoutes.splash || loc == AppRoutes.onboarding) return null;

      // First launch → onboarding (FLUTTER_REBUILD_PLAN: isFirstLaunch).
      if (prefs.isFirstLaunch && !loggedIn && loc == AppRoutes.home) {
        return AppRoutes.onboarding;
      }

      final isAuthRoute = loc == AppRoutes.login ||
          loc == AppRoutes.register ||
          loc == AppRoutes.registerEmployer ||
          loc == AppRoutes.forgotPassword;

      // Authenticated users are redirected away from auth pages by role.
      if (loggedIn && isAuthRoute) {
        if (current.isLoading) return null;
        return NavItems.homeFor(role);
      }

      final required = _requiredRoles(loc);
      if (required == null) return null; // public
      if (!loggedIn) return AppRoutes.login;
      // users/{uid} failed 3× with no cached principal → treat as signed out
      // (requireActivePrincipal) instead of rendering guarded pages without a role.
      if (current.hasError && !current.isLoading) return AppRoutes.login;
      // Server-confirmed missing users/{uid} while FirebaseAuth is signed in →
      // requireActivePrincipal 401: never render guarded pages without a role.
      if (!current.isLoading && !current.hasError && current.valueOrNull == null) {
        return AppRoutes.login;
      }
      if (current.isLoading || role == null) return null; // wait for users/{uid}
      // RoleGuard.jsx renders the 403 surface in place for a wrong role.
      if (!required.contains(role)) return AppRoutes.forbidden;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashPage()),
      GoRoute(path: AppRoutes.onboarding, builder: (_, _) => const OnboardingPage()),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, s) => HomePage(section: s.uri.queryParameters['section']),
      ),
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginPage()),
      GoRoute(path: AppRoutes.register, builder: (_, _) => const RegisterPage()),
      GoRoute(path: AppRoutes.registerEmployer, builder: (_, _) => const RegisterEmployerPage()),
      GoRoute(path: AppRoutes.forgotPassword, builder: (_, _) => const ForgotPasswordPage()),

      GoRoute(
        path: AppRoutes.jobs,
        builder: (_, s) => JobsSearchPage(
          initialKeyword: s.uri.queryParameters['q'],
          initialLocation: s.uri.queryParameters['location'],
        ),
      ),
      GoRoute(
        path: AppRoutes.jobDetail,
        builder: (_, s) => JobDetailPage(jobId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.applyJob,
        builder: (_, s) => ApplyJobPage(jobId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.companyDetail,
        builder: (_, s) => CompanyDetailPage(employerUid: s.pathParameters['id']!),
      ),

      // Job seeker
      GoRoute(path: AppRoutes.resumeProfile, builder: (_, _) => const ResumeProfilePage()),
      GoRoute(path: AppRoutes.editProfile, builder: (_, _) => const EditProfilePage()),
      GoRoute(
        path: AppRoutes.aiAnalysis,
        builder: (_, s) => AiAnalysisPage(resumeId: s.pathParameters['resumeId']!),
      ),
      GoRoute(path: AppRoutes.savedJobs, builder: (_, _) => const SavedJobsPage()),
      GoRoute(path: AppRoutes.myApplications, builder: (_, _) => const MyApplicationsPage()),
      GoRoute(
        path: AppRoutes.applicationDetail,
        builder: (_, s) => ApplicationDetailPage(applicationId: s.pathParameters['id']!),
      ),
      GoRoute(path: AppRoutes.recommended, builder: (_, _) => const RecommendedPage()),
      GoRoute(
        path: AppRoutes.recommendedSession,
        builder: (_, s) => SessionDetailPage(sessionId: s.pathParameters['sessionId']!),
      ),

      // Employer
      GoRoute(path: AppRoutes.employerDashboard, builder: (_, _) => const EmployerDashboardPage()),
      GoRoute(
        path: AppRoutes.employerCompanyProfile,
        builder: (_, _) => const EmployerCompanyProfilePage(),
      ),
      GoRoute(path: AppRoutes.employerJobs, builder: (_, _) => const EmployerJobsPage()),
      GoRoute(path: AppRoutes.createJob, builder: (_, _) => const CreateJobPage()),
      GoRoute(
        path: AppRoutes.editJob,
        builder: (_, s) => CreateJobPage(editJobId: s.pathParameters['id']),
      ),
      GoRoute(
        path: AppRoutes.jobApplicants,
        builder: (_, s) => JobApplicantsPage(jobId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.employerApplications,
        builder: (_, _) => const EmployerApplicationsPage(),
      ),
      GoRoute(
        path: AppRoutes.employerApplicationReview,
        builder: (_, s) => EmployerApplicationReviewPage(applicationId: s.pathParameters['id']!),
      ),

      // Admin
      GoRoute(path: AppRoutes.adminDashboard, builder: (_, _) => const AdminDashboardPage()),
      GoRoute(path: AppRoutes.adminUsers, builder: (_, _) => const AdminUsersPage()),
      GoRoute(path: AppRoutes.adminEmployers, builder: (_, _) => const AdminEmployersPage()),
      GoRoute(path: AppRoutes.adminPendingJobs, builder: (_, _) => const AdminPendingJobsPage()),
      GoRoute(path: AppRoutes.adminCatalog, builder: (_, _) => const CatalogManagementPage()),
      GoRoute(
        path: AppRoutes.adminSystemConfig,
        builder: (_, _) => const AdminSystemConfigurationPage(),
      ),
      GoRoute(path: AppRoutes.adminAiLogs, builder: (_, _) => const AiLogsPage()),
      GoRoute(path: AppRoutes.adminAiStats, builder: (_, _) => const AiStatsPage()),

      // Shared (authenticated)
      GoRoute(path: AppRoutes.notifications, builder: (_, _) => const NotificationsPage()),
      GoRoute(path: AppRoutes.chats, builder: (_, _) => const ChatsPage()),
      GoRoute(
        path: AppRoutes.chatRoom,
        builder: (_, s) => ChatRoomPage(chatId: s.pathParameters['chatId']!),
      ),
      GoRoute(path: AppRoutes.settings, builder: (_, _) => const SettingsPage()),
      GoRoute(path: AppRoutes.notFound, builder: (_, _) => const NotFoundPage()),
      GoRoute(path: AppRoutes.forbidden, builder: (_, _) => const ForbiddenPage()),
      // AppRoutes.jsx `<Route path="*" element={<NotFoundPage />} />` — a real
      // route (not errorBuilder) so GoRouterState is registered for the page.
      GoRoute(
        path: '/:rest(.*)',
        builder: (_, s) => NotFoundPage(path: s.uri.toString()),
      ),
    ],
    errorBuilder: (_, state) => NotFoundPage(path: state.uri.toString()),
  );
});

/// RoleGuard.jsx role sets. null = public.
Set<UserRole>? _requiredRoles(String loc) {
  const seeker = {UserRole.jobSeeker};
  const employer = {UserRole.employer};
  const employerOrAdmin = {UserRole.employer, UserRole.admin};
  const admin = {UserRole.admin};
  const anyUser = {UserRole.jobSeeker, UserRole.employer, UserRole.admin};

  if (loc.startsWith('/admin') || loc == AppRoutes.adminAiLogs) return admin;
  if (loc == AppRoutes.employerApplications || loc.startsWith('/employer/applications')) {
    return employerOrAdmin;
  }
  if (loc.startsWith('/employer')) return employer;
  if (loc == AppRoutes.resumeProfile ||
      loc.startsWith('/ho-so') ||
      loc.startsWith('/applications') ||
      loc == AppRoutes.savedJobs ||
      loc.endsWith('/ung-tuyen')) {
    return seeker;
  }
  if (loc == AppRoutes.notifications || loc.startsWith('/tin-nhan') || loc == AppRoutes.settings) {
    return anyUser;
  }
  return null; // home, jobs, job detail, company, recommended (public like web)
}

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    _subs = [
      ref.listen(authStateProvider, (_, _) => notifyListeners()),
      ref.listen(currentUserProvider, (_, _) => notifyListeners()),
    ];
  }
  late final List<ProviderSubscription> _subs;

  @override
  void dispose() {
    for (final s in _subs) {
      s.close();
    }
    super.dispose();
  }
}
