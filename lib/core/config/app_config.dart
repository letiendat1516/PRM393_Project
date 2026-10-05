/// App-wide constants. Values mirror backend/src/config + JobService fallbacks
/// and the JobsPage filter option lists so UI copy matches the web.
class AppConfig {
  const AppConfig._();

  static const String appName = 'JobHub';
  static const String supportEmail = 'lienhe@jobhub.vn';
  static const String supportPhone = '1900 1234';
  static const String defaultLocale = 'vi';
  static const List<String> supportedLocales = ['vi', 'en'];

  // JobsPage PAGE_SIZE = 10; backend limit clamp [1, 1000]
  static const int pageSize = 10;
  static const int maxPageSize = 100;
  static const int listPreviewLimit = 6;

  // JobService fallbacks (also seeded into systemConfigurations)
  static const int defaultMaxSkillsPerJob = 30;
  static const int defaultDeadlineDays = 30;
  static const bool defaultRequireJobApproval = true;

  // AIScoreModal / RecommendationController
  static const int aiMaxJobsPerScoring = 100;
  static const int aiBatchSize = 10;
  static const int aiMaxConcurrency = 2;
  static const int aiMaxRetries = 2;
  static const List<Duration> aiRetryBackoff = [Duration(seconds: 5), Duration(seconds: 10)];
  static const int aiResumeTextCap = 8000;
  static const int aiJobDescCap = 800;
  static const int aiSessionCap = 20; // utils/aiScores.js MAX_SESSIONS
  static const int aiLogsPageLimit = 100;
  static const int aiStatsLogLimit = 200;

  // resumeUpload middleware: PDF only, 5 MB
  static const int resumeMaxBytes = 5 * 1024 * 1024;
  static const List<String> resumeExtensions = ['pdf', 'txt'];

  // Gemini (OpenAI-compatible endpoint) — key comes from --dart-define or
  // systemConfigurations/GEMINI_API_KEY (admin-set).
  // Native Gemini REST (v1beta/models/{model}:generateContent) rather than
  // the OpenAI-compat shim: the latter only accepts the legacy `AIzaSy...`
  // key format via `Authorization: Bearer`, and Google now only issues
  // the newer `AQ.` scoped keys from AI Studio / Cloud Console, which
  // return HTTP 400 "Invalid Auth key." on the OpenAI endpoint. Both key
  // formats work on the native endpoint via `?key=...`.
  static const String geminiBaseUrl = String.fromEnvironment(
    'GEMINI_BASE_URL',
    defaultValue: 'https://generativelanguage.googleapis.com/v1beta',
  );
  // `gemini-flash-latest` + `gemini-3.8-flash` succeed with current keys;
  // `gemini-2.5-flash` returns 404 "no longer available to new users".
  static const String geminiModel = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-flash-latest',
  );
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

  // ── DeepSeek (OpenAI-compatible) ──────────────────────────────────────
  //
  // DeepSeek exposes an OpenAI-shaped /v1/chat/completions endpoint, so
  // one JSON body works for both DeepSeek and z.ai (below). Model names
  // and keys differ; auth is Bearer.
  static const String deepseekBaseUrl = String.fromEnvironment(
    'DEEPSEEK_BASE_URL',
    defaultValue: 'https://api.deepseek.com',
  );
  static const String deepseekModel = String.fromEnvironment(
    'DEEPSEEK_MODEL',
    defaultValue: 'deepseek-chat',
  );
  static const String deepseekApiKey =
      String.fromEnvironment('DEEPSEEK_API_KEY');

  // ── z.ai (international GLM endpoint, OpenAI-compatible) ──────────────
  //
  // Two base URLs exist on `api.z.ai`:
  //   • /api/paas/v4         — standard GLM chat, pay-per-token billing.
  //                           Models: glm-4.5-flash, glm-4.6, glm-5.x…
  //   • /api/coding/paas/v4  — Coding Plan subscription (Claude-Code-style
  //                           routing). Models: glm-5.3, glm-5.3-flash,
  //                           glm-5.2, glm-image, cogvideox-3.
  //
  // Default matches the Zed IDE Coding Plan config most students use for
  // this course since the Coding Plan subscription includes the GLM-5.x
  // family and avoids per-call overages. If your key is a standard
  // per-token one, override with `--dart-define=ZAI_BASE_URL=
  // https://api.z.ai/api/paas/v4` and `ZAI_MODEL=glm-4.5-flash`.
  //
  // Keys issued on `open.bigmodel.cn` (Zhipu China) are NOT valid against
  // either `api.z.ai` host — mint a new key at
  // https://z.ai/manage-apikey/apikey-list first.
  static const String zaiBaseUrl = String.fromEnvironment(
    'ZAI_BASE_URL',
    defaultValue: 'https://api.z.ai/api/coding/paas/v4',
  );
  static const String zaiModel = String.fromEnvironment(
    'ZAI_MODEL',
    defaultValue: 'glm-5.3-flash',
  );
  static const String zaiApiKey = String.fromEnvironment('ZAI_API_KEY');

  /// CSV order of providers to try (first → fallback). Values in
  /// {'gemini','deepseek','zai'}. Admin can override in Firestore via
  /// systemConfigurations/AI_PROVIDER_ORDER.
  static const String aiProviderOrderDefault = 'gemini,deepseek,zai';

  /// Admin accounts cannot self-register (AuthService.js). For the course demo
  /// an account registered with one of these emails is promoted to admin.
  /// Override: `--dart-define=ADMIN_EMAILS=a@x.com,b@y.com`.
  static const String _adminEmailsRaw =
      String.fromEnvironment('ADMIN_EMAILS', defaultValue: 'admin@jobhub.vn');
  static List<String> get adminEmails =>
      _adminEmailsRaw.split(',').map((e) => e.trim().toLowerCase()).where((e) => e.isNotEmpty).toList();

  /// Hero / SearchBar popular chips.
  static const List<String> popularKeywords = ['ReactJS', 'Marketing', 'Kế toán', 'Remote'];

  /// JobsPage salary bands (triệu VND); overlap semantics in filtering.
  static const List<SalaryBand> salaryBands = [
    SalaryBand('0-10', 'Dưới 10 triệu', 0, 10000000),
    SalaryBand('10-15', '10 - 15 triệu', 10000000, 15000000),
    SalaryBand('15-20', '15 - 20 triệu', 15000000, 20000000),
    SalaryBand('20-30', '20 - 30 triệu', 20000000, 30000000),
    SalaryBand('30-50', '30 - 50 triệu', 30000000, 50000000),
    SalaryBand('50-', 'Trên 50 triệu', 50000000, null),
    SalaryBand('negotiable', 'Thoả thuận', null, null),
  ];

  /// JobsPage sort options.
  static const List<SortOption> sortOptions = [
    SortOption('posted', 'Ngày đăng'),
    SortOption('updated', 'Ngày cập nhật'),
    SortOption('salaryDesc', 'Lương cao nhất'),
    SortOption('urgent', 'Cần tuyển gấp'),
    SortOption('aiScore', 'Độ phù hợp AI (cao→thấp)'),
  ];

  /// Homepage featured-jobs category chips.
  static const List<String> homeCategoryChips = [
    'Tất cả',
    'Công nghệ thông tin',
    'Kinh doanh',
    'Marketing',
    'Tài chính – Kế toán',
    'Nhân sự',
  ];

  /// Section anchors used by Navbar/Footer hash links (HomePage GlobalKeys).
  static const sectionFeaturedJobs = 'featured-jobs';
  static const sectionWhyJobHub = 'why-jobhub';
  static const sectionAiAnalysis = 'ai-analysis';
  static const sectionTopCompanies = 'top-companies';
  static const sectionTestimonials = 'testimonials';
  static const sectionCareerResources = 'career-resources';
}

class SalaryBand {
  const SalaryBand(this.key, this.label, this.min, this.max);
  final String key;
  final String label;
  final int? min;
  final int? max;

  /// Overlap test used by JobsPage: a job matches a band if its salary range
  /// intersects the band; 'negotiable' matches jobs without salary.
  bool matches({num? jobMin, num? jobMax, bool negotiable = false}) {
    if (key == 'negotiable') return negotiable || (jobMin == null && jobMax == null);
    if (jobMin == null && jobMax == null) return false;
    final jMin = jobMin ?? 0;
    final jMax = jobMax ?? double.infinity;
    final bMin = min ?? 0;
    final bMax = max ?? double.infinity;
    return jMin <= bMax && jMax >= bMin;
  }
}

class SortOption {
  const SortOption(this.key, this.label);
  final String key;
  final String label;
}
