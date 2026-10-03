/// Route table mirroring frontend/src/routes/AppRoutes.jsx (same Vietnamese
/// slugs so web deep links keep working on Flutter web) plus the mobile-only
/// screens from docs/FLUTTER_REBUILD_PLAN.md.
class AppRoutes {
  const AppRoutes._();

  // ── Public ────────────────────────────────────────────────────────────
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const home = '/';
  static const login = '/dang-nhap';
  static const register = '/dang-ky';
  static const registerEmployer = '/dang-ky-nha-tuyen-dung';
  static const forgotPassword = '/quen-mat-khau';

  static const jobs = '/viec-lam';
  static const jobDetail = '/viec-lam/:id';
  static String jobDetailOf(String id) => '/viec-lam/$id';

  static const companyDetail = '/cong-ty/:id';
  static String companyDetailOf(String id) => '/cong-ty/$id';

  // ── Job seeker ────────────────────────────────────────────────────────
  static const resumeProfile = '/ho-so';
  static const editProfile = '/ho-so/chinh-sua';
  static const savedJobs = '/viec-da-luu';
  static const myApplications = '/applications';
  static const applicationDetail = '/applications/:id';
  static String applicationDetailOf(String id) => '/applications/$id';
  static const recommended = '/de-xuat';
  static const recommendedSession = '/de-xuat/:sessionId';
  static String recommendedSessionOf(String id) => '/de-xuat/$id';
  static const aiAnalysis = '/ho-so/phan-tich/:resumeId';
  static String aiAnalysisOf(String id) => '/ho-so/phan-tich/$id';
  static const applyJob = '/viec-lam/:id/ung-tuyen';
  static String applyJobOf(String id) => '/viec-lam/$id/ung-tuyen';

  // ── Employer ──────────────────────────────────────────────────────────
  static const employerDashboard = '/employer';
  static const employerCompanyProfile = '/employer/company-profile';
  static const employerJobs = '/employer/jobs';
  static const createJob = '/employer/jobs/create';
  static const editJob = '/employer/jobs/:id/edit';
  static String editJobOf(String id) => '/employer/jobs/$id/edit';
  static const jobApplicants = '/employer/jobs/:id/applicants';
  static String jobApplicantsOf(String id) => '/employer/jobs/$id/applicants';
  static const employerApplications = '/employer/applications';
  static const employerApplicationReview = '/employer/applications/:id';
  static String employerApplicationReviewOf(String id) =>
      '/employer/applications/$id';

  // ── Admin ─────────────────────────────────────────────────────────────
  static const adminDashboard = '/admin';
  static const adminUsers = '/admin/users';
  static const adminEmployers = '/admin/employers';
  static const adminPendingJobs = '/admin/pending-jobs';
  static const adminCatalog = '/admin/catalog';
  static const adminSystemConfig = '/admin/system-configurations';
  static const adminAiLogs = '/ai-logs';
  static const adminAiStats = '/admin/ai-stats';

  // ── Shared (authenticated) ────────────────────────────────────────────
  static const notifications = '/notifications';
  static const chats = '/tin-nhan';
  static const chatRoom = '/tin-nhan/:chatId';
  static String chatRoomOf(String id) => '/tin-nhan/$id';
  static const settings = '/settings';
  static const notFound = '/404';
  /// RoleGuard.jsx 403 surface (authenticated user with the wrong role).
  static const forbidden = '/403';
}
