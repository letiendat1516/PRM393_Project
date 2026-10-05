import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../../shared/models/job_model.dart';
import '../../../shared/models/recommendation_models.dart';
import '../../../shared/models/resume_model.dart';
import '../../config/app_config.dart';
import '../../utils/failure.dart';

typedef AiLogSink = Future<void> Function(AiMatchingLog log);
typedef ApiKeyResolver = Future<String?> Function();
typedef ProviderOrderResolver = Future<List<String>> Function();

/// Multi-provider AI client (keeps the `GeminiService` name because many
/// imports already depend on it, but now orchestrates Gemini + DeepSeek +
/// z.ai). Prompt-building + log sink are shared; transport differs per
/// provider:
///   • Gemini — native REST (:generateContent)
///   • DeepSeek — OpenAI-compatible /v1/chat/completions
///   • z.ai (Zhipu GLM) — OpenAI-compatible /chat/completions
///
/// `chatCompletion` tries providers in [resolveProviderOrder] order; a
/// transient failure (503/429) on one triggers the next. A missing key
/// transparently skips its provider so partial configurations still work.
class GeminiService {
  GeminiService({
    required this.resolveApiKey,
    required this.logSink,
    this.resolveDeepseekKey,
    this.resolveZaiKey,
    this.resolveProviderOrder,
    http.Client? client,
    this.baseUrl = AppConfig.geminiBaseUrl,
    this.model = AppConfig.geminiModel,
    this.deepseekBaseUrl = AppConfig.deepseekBaseUrl,
    this.deepseekModel = AppConfig.deepseekModel,
    this.zaiBaseUrl = AppConfig.zaiBaseUrl,
    this.zaiModel = AppConfig.zaiModel,
  }) : _client = client ?? http.Client();

  final ApiKeyResolver resolveApiKey;
  final ApiKeyResolver? resolveDeepseekKey;
  final ApiKeyResolver? resolveZaiKey;
  final ProviderOrderResolver? resolveProviderOrder;
  final AiLogSink logSink;
  final http.Client _client;
  final String baseUrl;
  final String model;
  final String deepseekBaseUrl;
  final String deepseekModel;
  final String zaiBaseUrl;
  final String zaiModel;

  static const taskResumeExtraction = 'resume_extraction';
  static const taskJobMatching = 'job_matching';

  // ── Transport (native Gemini REST) ────────────────────────────────────
  //
  // Call shape:
  //   POST {baseUrl}/models/{model}:generateContent?key={apiKey}
  //   body: { systemInstruction?, contents, generationConfig }
  // and parse `candidates[0].content.parts[0].text` + `usageMetadata`.
  //
  // The caller supplies OpenAI-style messages ([{role: system/user/assistant,
  // content: ...}]) and this method translates them to Gemini's native shape
  // so the prompt-builder code keeps its OpenAI parity verbatim.
  /// Gemini fallback models tried after the primary Gemini model fails
  /// with 503. Each model has an independent quota pool.
  static const _fallbackModels = <String>[
    'gemini-2.5-flash',
    'gemini-1.5-flash-latest',
    'gemini-1.5-flash',
  ];

  /// Default provider order when the admin hasn't configured one.
  static const _defaultOrder = <String>['gemini', 'deepseek', 'zai'];

  Future<({String content, int tokensIn, int tokensOut})> chatCompletion(
    List<Map<String, String>> messages, {
    Duration timeout = const Duration(seconds: 120),
    int? maxTokens,
  }) async {
    final order = await _resolveOrder();
    Failure? lastFailure;
    var anyKeyFound = false;

    for (final provider in order) {
      try {
        final result = await _tryProvider(
          provider,
          messages,
          timeout: timeout,
          maxTokens: maxTokens,
        );
        return result;
      } on _KeyMissing {
        // Provider not configured — silently try the next one.
        continue;
      } on Failure catch (f) {
        anyKeyFound = true;
        lastFailure = f;
        // Only move to the next provider on transient overload. A 400 /
        // 401 / 403 means that specific provider is misconfigured — try
        // the next one too (don't let a bad DeepSeek key kill z.ai).
        continue;
      }
    }

    if (!anyKeyFound && lastFailure == null) {
      throw const Failure(
        'Chưa cấu hình API key cho AI nào. Admin vào Cấu hình hệ thống → '
        'GEMINI_API_KEY / DEEPSEEK_API_KEY / ZAI_API_KEY.',
        status: 503,
        code: 'AI_KEY_MISSING',
      );
    }
    throw lastFailure ??
        const Failure('AI không phản hồi.', status: 503, code: 'AI_HTTP');
  }

  Future<List<String>> _resolveOrder() async {
    List<String> order;
    try {
      order = (await resolveProviderOrder?.call()) ?? const [];
    } catch (_) {
      order = const [];
    }
    if (order.isEmpty) order = _defaultOrder;
    // Dedupe + whitelist.
    final seen = <String>{};
    final out = <String>[];
    for (final p in order) {
      final norm = p.trim().toLowerCase();
      if (!_defaultOrder.contains(norm)) continue;
      if (seen.add(norm)) out.add(norm);
    }
    return out.isEmpty ? _defaultOrder : out;
  }

  Future<({String content, int tokensIn, int tokensOut})> _tryProvider(
    String provider,
    List<Map<String, String>> messages, {
    required Duration timeout,
    int? maxTokens,
  }) async {
    switch (provider) {
      case 'gemini':
        return _tryGemini(messages, timeout: timeout, maxTokens: maxTokens);
      case 'deepseek':
        return _tryOpenAiCompatible(
          messages,
          providerLabel: 'DeepSeek',
          keyResolver: resolveDeepseekKey,
          baseUrlOverride: deepseekBaseUrl,
          modelOverride: deepseekModel,
          chatPath: '/v1/chat/completions',
          timeout: timeout,
          maxTokens: maxTokens,
        );
      case 'zai':
        return _tryOpenAiCompatible(
          messages,
          providerLabel: 'z.ai',
          keyResolver: resolveZaiKey,
          baseUrlOverride: zaiBaseUrl,
          modelOverride: zaiModel,
          // Zhipu's base already includes /paas/v4, so the chat path is
          // just /chat/completions. DeepSeek uses /v1 as a prefix.
          chatPath: '/chat/completions',
          timeout: timeout,
          maxTokens: maxTokens,
        );
      default:
        throw _KeyMissing(provider);
    }
  }

  Future<({String content, int tokensIn, int tokensOut})> _tryGemini(
    List<Map<String, String>> messages, {
    required Duration timeout,
    int? maxTokens,
  }) async {
    final key = await resolveApiKey();
    if (key == null || key.isEmpty) throw _KeyMissing('gemini');

    final attemptModels = <String>[
      model,
      for (final m in _fallbackModels)
        if (m != model) m,
    ];
    Failure? lastFailure;
    for (final m in attemptModels) {
      for (var attempt = 0; attempt < 3; attempt++) {
        try {
          return await _postOnce(
            messages,
            modelOverride: m,
            key: key,
            timeout: timeout,
            maxTokens: maxTokens,
          );
        } on Failure catch (f) {
          lastFailure = f;
          final isOverload = f.status == 503 || f.status == 429;
          if (!isOverload) break;
          if (attempt < 2) {
            final backoffSec = 1 << (attempt + 1); // 2, 4
            await Future<void>.delayed(Duration(seconds: backoffSec));
          }
        }
      }
      if (lastFailure == null) continue;
      if (lastFailure.status != 503 && lastFailure.status != 429) break;
    }
    throw lastFailure ??
        const Failure('AI không phản hồi.', status: 503, code: 'AI_HTTP');
  }

  /// Shared OpenAI-compatible transport for DeepSeek + z.ai. Translates
  /// the (role, content) list straight into {messages:[...]} and parses
  /// `choices[0].message.content` + `usage.*`.
  Future<({String content, int tokensIn, int tokensOut})> _tryOpenAiCompatible(
    List<Map<String, String>> messages, {
    required String providerLabel,
    required ApiKeyResolver? keyResolver,
    required String baseUrlOverride,
    required String modelOverride,
    required String chatPath,
    required Duration timeout,
    int? maxTokens,
  }) async {
    if (keyResolver == null) throw _KeyMissing(providerLabel.toLowerCase());
    final key = await keyResolver();
    if (key == null || key.isEmpty) throw _KeyMissing(providerLabel.toLowerCase());

    // z.ai Coding Plan (glm-5.x family) emits `reasoning_content` on every
    // response — even with `thinking.type = disabled` the model burns 5-15
    // tokens on reasoning before the real content, and
    // `response_format.json_object` is not accepted on
    // /api/coding/paas/v4. DeepSeek honours both, so we only switch the
    // body shape when talking to z.ai.
    final isZai = providerLabel == 'z.ai';
    final body = <String, dynamic>{
      'model': modelOverride,
      'messages': [
        for (final m in messages)
          {'role': m['role'] ?? 'user', 'content': m['content'] ?? ''},
      ],
      'temperature': 0,
      if (!isZai) 'response_format': {'type': 'json_object'},
      if (isZai) 'thinking': {'type': 'disabled'},
      // ignore: use_null_aware_elements
      if (maxTokens != null) 'max_tokens': maxTokens,
    };

    // 2-attempt retry on transient overload only.
    Failure? lastFailure;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final res = await _client
            .post(
              Uri.parse('$baseUrlOverride$chatPath'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $key',
              },
              body: jsonEncode(body),
            )
            .timeout(timeout);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          final friendly = switch (res.statusCode) {
            503 =>
              '$providerLabel đang quá tải (503). Thử lại sau ít phút.',
            429 =>
              '$providerLabel báo vượt quota (429). Chờ ít phút hoặc đổi key.',
            _ => '$providerLabel ${res.statusCode}: ${res.body}',
          };
          throw Failure(friendly,
              status: res.statusCode, code: 'AI_HTTP');
        }
        final json =
            jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        final choices = json['choices'] as List? ?? const [];
        var content = '';
        if (choices.isNotEmpty) {
          final c = choices.first as Map;
          final msg = (c['message'] as Map?) ?? const {};
          content = msg['content']?.toString() ?? '';
          // z.ai glm-5.x wraps JSON in markdown code fences ("```json\n
          // {...}\n```") even when told not to; strip them so the
          // downstream `jsonDecode(content)` in scoreJobs / extractResume
          // still works.
          content = _stripMarkdownFence(content);
        }
        final usage = json['usage'] as Map? ?? const {};
        return (
          content: content,
          tokensIn: ((usage['prompt_tokens'] ?? 0) as num).toInt(),
          tokensOut: ((usage['completion_tokens'] ?? 0) as num).toInt(),
        );
      } on Failure catch (f) {
        lastFailure = f;
        final isOverload = f.status == 503 || f.status == 429;
        if (!isOverload) break;
        if (attempt == 0) {
          await Future<void>.delayed(const Duration(seconds: 2));
        }
      }
    }
    throw lastFailure ??
        Failure('$providerLabel không phản hồi.',
            status: 503, code: 'AI_HTTP');
  }

  Future<({String content, int tokensIn, int tokensOut})> _postOnce(
    List<Map<String, String>> messages, {
    required String modelOverride,
    required String key,
    required Duration timeout,
    int? maxTokens,
  }) async {

    // OpenAI `system` messages → Gemini `systemInstruction` (singular, string).
    final systemParts = <String>[];
    final contents = <Map<String, dynamic>>[];
    for (final m in messages) {
      final role = m['role'] ?? 'user';
      final text = m['content'] ?? '';
      if (role == 'system') {
        systemParts.add(text);
        continue;
      }
      contents.add({
        // Gemini uses 'model' instead of OpenAI's 'assistant'.
        'role': role == 'assistant' ? 'model' : 'user',
        'parts': [
          {'text': text},
        ],
      });
    }

    final generationConfig = <String, dynamic>{
      'temperature': 0,
      // Match the OpenAI `response_format: json_object` the backend relies on.
      'responseMimeType': 'application/json',
      // ignore: use_null_aware_elements
      if (maxTokens != null) 'maxOutputTokens': maxTokens,
    };

    final body = <String, dynamic>{
      'contents': contents,
      if (systemParts.isNotEmpty)
        'systemInstruction': {
          'parts': [
            {'text': systemParts.join('\n\n')},
          ],
        },
      'generationConfig': generationConfig,
    };

    final res = await _client
        .post(
          Uri.parse('$baseUrl/models/$modelOverride:generateContent?key=$key'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(timeout);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      // Translate the two overload codes to human-readable Vietnamese so
      // the user doesn't see raw JSON. Everything else keeps the body for
      // debugging ("AI_HTTP" is still the sentinel code).
      final friendly = switch (res.statusCode) {
        503 =>
          'Gemini đang quá tải (503). Đã thử lại nhiều lần nhưng chưa phản hồi — vui lòng thử lại sau ít phút.',
        429 =>
          'Gemini báo vượt quota (429). Hãy chờ ít phút rồi thử lại hoặc cập nhật GEMINI_API_KEY.',
        _ => 'AI ${res.statusCode}: ${res.body}',
      };
      throw Failure(friendly, status: res.statusCode, code: 'AI_HTTP');
    }
    final json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final candidates = json['candidates'] as List? ?? const [];
    String content = '';
    if (candidates.isNotEmpty) {
      final cand = candidates.first as Map;
      final parts = (cand['content'] as Map?)?['parts'] as List? ?? const [];
      if (parts.isNotEmpty) {
        content = (parts.first as Map)['text']?.toString() ?? '';
      }
    }
    final usage = json['usageMetadata'] as Map? ?? const {};
    return (
      content: content,
      tokensIn: ((usage['promptTokenCount'] ?? 0) as num).toInt(),
      tokensOut: ((usage['candidatesTokenCount'] ?? 0) as num).toInt(),
    );
  }

  /// Ping used by GeminiKeyPanel.testKey. Low `maxOutputTokens` + empty
  /// prompt is enough to exercise auth + model availability without
  /// burning quota.
  Future<({bool valid, int? status, int latencyMs, String? error})> testKey() async {
    return testProviderKey('gemini', null);
  }

  /// Per-provider "ping" check used by the admin AI key panels. When
  /// [keyOverride] is non-null it bypasses the resolver chain so the
  /// admin can validate a freshly-typed key BEFORE saving it to
  /// Firestore. Returns a status / error pair the UI banner renders.
  Future<({bool valid, int? status, int latencyMs, String? error})>
      testProviderKey(String provider, String? keyOverride) async {
    final sw = Stopwatch()..start();
    try {
      switch (provider) {
        case 'gemini':
          final k = keyOverride?.trim();
          final r = await _postOnce(
            [
              {'role': 'user', 'content': 'Respond with {}'}
            ],
            modelOverride: model,
            key: (k == null || k.isEmpty)
                ? (await resolveApiKey()) ?? ''
                : k,
            timeout: const Duration(seconds: 20),
            maxTokens: 8,
          );
          // success — unused response but we need to touch the record.
          r.tokensIn;
        case 'deepseek':
          await _oneShotOpenAi(
            providerLabel: 'DeepSeek',
            baseUrlOverride: deepseekBaseUrl,
            modelOverride: deepseekModel,
            chatPath: '/v1/chat/completions',
            key: (keyOverride?.trim().isNotEmpty ?? false)
                ? keyOverride!.trim()
                : (await resolveDeepseekKey?.call()) ?? '',
          );
        case 'zai':
          await _oneShotOpenAi(
            providerLabel: 'z.ai',
            baseUrlOverride: zaiBaseUrl,
            modelOverride: zaiModel,
            chatPath: '/chat/completions',
            key: (keyOverride?.trim().isNotEmpty ?? false)
                ? keyOverride!.trim()
                : (await resolveZaiKey?.call()) ?? '',
          );
        default:
          throw Failure('Provider không hỗ trợ: $provider',
              status: 400, code: 'BAD_PROVIDER');
      }
      return (
        valid: true,
        status: 200,
        latencyMs: sw.elapsedMilliseconds,
        error: null
      );
    } catch (e) {
      final f = Failure.from(e);
      return (
        valid: false,
        status: f.status,
        latencyMs: sw.elapsedMilliseconds,
        error: f.message
      );
    }
  }

  /// Minimal one-shot OpenAI-compatible call used by [testProviderKey]
  /// so the ping doesn't go through the full retry + fallback chain.
  Future<void> _oneShotOpenAi({
    required String providerLabel,
    required String baseUrlOverride,
    required String modelOverride,
    required String chatPath,
    required String key,
  }) async {
    if (key.isEmpty) {
      throw Failure('Chưa cấu hình $providerLabel API key.',
          status: 503, code: 'AI_KEY_MISSING');
    }
    // z.ai glm-5.x spends 5-15 tokens on reasoning before producing
    // content even with thinking disabled, so an 8-token budget keeps
    // bouncing with finish_reason=length (looks like a key failure in
    // the admin test banner). 64 is enough for a visible "ping ok" tail.
    final isZai = providerLabel == 'z.ai';
    final body = <String, dynamic>{
      'model': modelOverride,
      'messages': [
        {'role': 'user', 'content': 'ping'},
      ],
      'temperature': 0,
      'max_tokens': isZai ? 64 : 8,
      if (isZai) 'thinking': {'type': 'disabled'},
    };
    final res = await _client
        .post(
          Uri.parse('$baseUrlOverride$chatPath'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $key',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Failure('$providerLabel ${res.statusCode}: ${res.body}',
          status: res.statusCode, code: 'AI_HTTP');
    }
  }

  /// Strip `` ```json\n{...}\n``` `` (or any ` ``` ` code fence) around
  /// a JSON blob the model returned despite the response_format /
  /// system-prompt hints. z.ai GLM-5.x almost always wraps; DeepSeek
  /// does it sometimes on reasoning-heavy requests.
  static String _stripMarkdownFence(String s) {
    var t = s.trim();
    if (!t.startsWith('```')) return t;
    // Drop the opening fence line (``` or ```json)
    final firstNl = t.indexOf('\n');
    if (firstNl < 0) return t;
    t = t.substring(firstNl + 1);
    // Drop the closing ``` (and any trailing text after it, which
    // models never produce but be defensive).
    final closeIdx = t.lastIndexOf('```');
    if (closeIdx >= 0) t = t.substring(0, closeIdx);
    return t.trim();
  }

  // ── Prompts (verbatim port of backend/src/ai/promptBuilder.js) ───────
  /// buildResumeExtractionPrompt(resumeText) — v2.
  static List<Map<String, String>> buildResumeExtractionPrompt(String resumeText) {
    const system = '''Bạn là trợ lý phân tích CV chuyên nghiệp. Trả về JSON đúng schema,
không kèm giải thích, không markdown. Nếu thông tin thiếu → null hoặc mảng rỗng.
Chuẩn hoá tên kỹ năng (vd "java" → "Java").

QUAN TRỌNG: Phân tích toàn bộ CV, bao gồm cả soft skills, thái độ làm việc,
khả năng teamwork, leadership, ngôn ngữ, chứng chỉ, sở thích nếu CV đề cập.''';

    final user = '''Đọc CV dưới đây và trích xuất:

=== CV TEXT ===
$resumeText
=== HẾT ===

Trả về JSON theo schema:
{
  "skills": ["danh sách kỹ năng chuyên môn"],
  "soft_skills": ["teamwork", "communication", "problem-solving", "leadership", ...],
  "total_experience_years": <số thực hoặc null>,
  "education_level": "High School | Bachelor | Master | PhD | Other",
  "languages": ["tên ngôn ngữ"],
  "certifications": ["tên chứng chỉ"],
  "work_experience": [
    {"company":"tên","position":"vị trí","start_date":"YYYY-MM|null","end_date":"YYYY-MM|null","description":"mô tả ngắn"}
  ],
  "summary": "Tóm tắt 2-3 câu về ứng viên: điểm mạnh, định hướng nghề nghiệp, phong cách làm việc."
}''';

    return [
      {'role': 'system', 'content': system},
      {'role': 'user', 'content': user},
    ];
  }

  /// buildJobMatchingPrompt(candidate, jobs) — v4 rubric. The only addition
  /// to the source text is the trailing note asking for the `{"scores": [...]}`
  /// object wrapper, required by `response_format: json_object`.
  static List<Map<String, String>> buildJobMatchingPrompt(
      Map<String, dynamic> cv, List<JobModel> jobs) {
    const system = '''Chuyên gia tuyển dụng đa ngành. Chấm điểm CV vs jobs, trọng số động (tổng=100).

QUY TẮC:
1. UU TIÊN PHÂN TÍCH MÔ TẢ CÔNG VIỆC (desc) để xác định yêu cầu thực tế.
   Nếu title nói "AI Engineer" nhưng desc là backend dev (REST API, CI/CD) → chấm theo DESC.
   Chỉ suy luận từ title khi KHÔNG có desc (Network Eng→TCP/IP, Kế toán→Excel/thuế).
2. Chuẩn hoá skill trước so sánh (JS=JavaScript, Sale=Sales).
3. Transferable skills: IT→Sales giữ communication/analysis; Sales→Marketing giữ customer insight.
4. "Không yêu cầu" = 50% điểm tiêu chí, KHÔNG tối đa. Job mờ → cap 65.
   Nếu tiêu chí KHÔNG liên quan đến job (vd: job thuần Việt không cần ngoại ngữ) →
   trọng số = 0, bỏ qua tiêu chí đó. Tổng trọng số các tiêu chí CÒN LẠI vẫn = 100.
5. CAP: thiếu TOÀN BỘ core skills → max 40. Thiếu HƠN NỬA → max 55.
6. Career fit = đúng chuyên môn (10-15), lệch nhánh (5-9), khác hẳn (2-4). KHÔNG phải "dễ vào".
7. KHÔNG cho 10/10 mọi tiêu chí. Phải có sự KHÁC BIỆT giữa các job.
   - Job cần Python mà CV không có → skills tối đa 5/10, KHÔNG 8+.
   - Job cần 5 năm KN mà CV có 0 → experience tối đa 3/10.
   - Job yêu cầu RÕ RÀNG kỹ năng X mà CV KHÔNG CÓ → tiêu chí đó tối đa 1/10.
     Vd: job yêu cầu "Good English" mà CV không có tiếng Anh → language = 0-1/10.
8. score_breakdown values MUST NOT exceed weights. Nếu weight=5 thì score tối đa = 5.
9. Reason: 2 câu, cụ thể skills/domain/KN THỰC TẾ. KHÔNG "phù hợp hoàn hảo".
10. Temperature=0, nhất quán. match_score = số nguyên.

VÍ DỤ ANCHOR (dạy chấm nhất quán — áp dụng CÙNG rubric cho mọi case):

[A] Match cao, cùng ngành (IT backend → IT backend):
CV: skills=[Python,Django,PostgreSQL,Docker], exp=3yr, summary=Backend dev
Job: Backend Engineer, skills=[Python,FastAPI,PostgreSQL], min_exp=2, industry=IT
→ match_score≈82. breakdown: skills≈24/30 (2/3 required + framework switch Django→FastAPI), experience≈18/20 (3≥2), domain≈13/15, career_fit≈9/10. reason: "Mạnh Python/PostgreSQL khớp 2/3 required skills. 3 năm backend vượt yêu cầu 2 năm. Chuyển Django→FastAPI thuận lợi."

[B] Transferable (IT → Sales, lệch nhánh):
CV: skills=[Python,SQL,analytical], exp=2yr IT, summary=Data analyst muốn chuyển sales
Job: Sales Executive B2B, skills=[Communication,CRM,Negotiation], min_exp=1, industry=Sales
→ match_score≈48. breakdown: skills≈8/30 (chỉ analytical giữ; thiếu CRM/Negotiation), experience≈10/20 (2yr nhưng khác domain), domain≈4/15 (IT≠Sales), career_fit≈6/10 (có intent). reason: "Nền phân tích tốt chuyển thành insight khách hàng được. Thiếu CRM + kỹ năng đàm phán sales. Cần training customer-facing."

[C] Cross-nhánh gần (Sales → Marketing, transferable mạnh):
CV: skills=[Customer insight,Negotiation,CRM,Communication], exp=4yr Sales B2C
Job: Marketing Executive, skills=[Content,SEO,Analytics,Customer insight], min_exp=2, industry=Marketing
→ match_score≈65. breakdown: skills≈15/30 (Customer insight khớp; thiếu Content/SEO/Analytics), experience≈16/20 (4yr thừa), domain≈9/15 (Sales/Marketing gần), career_fit≈8/10. reason: "Customer insight 4 năm là tài sản marketing. Cần học Content/SEO/Analytics. Transition sales→marketing phổ biến."''';

    // `(candidate.x || []).join(',')` — lists joined with ',' (no space).
    String joinList(Object? v) => (v as List?)?.map((e) => e.toString()).join(',') ?? '';
    final summary = (cv['summary'] ?? '').toString();
    final cvLine = 'CV: skills=[${joinList(cv['skills'])}], '
        'soft=[${joinList(cv['soft_skills'])}], '
        'exp=${cv['experience_years'] ?? cv['total_experience_years'] ?? '?'}yr, '
        'edu=${cv['education_level'] ?? '?'}, '
        'lang=[${joinList(cv['languages'])}], '
        'certs=[${joinList(cv['certifications'])}], '
        'summary=${summary.length > 200 ? summary.substring(0, 200) : summary}';

    final compactJobs = [
      for (final j in jobs)
        {
          'id': j.jobId,
          'title': j.jobTitle,
          'skills': j.requiredSkills.map((s) => s.skillName).toList(),
          // mapExpToYears() yields JS numbers (0, 0.5, 1, 3, 5…) — emit ints
          // for whole years so JSON reads `1`, not `1.0`.
          'min_exp': j.minExperienceYears == j.minExperienceYears.roundToDouble()
              ? j.minExperienceYears.toInt()
              : j.minExperienceYears,
          'level': j.experienceLevel.name.toUpperCase(),
          // frontend buildJobsPayload: `industry: j.category || null`
          'industry': (j.categoryName == null || j.categoryName!.isEmpty) ? null : j.categoryName,
          'desc': _desc(j),
        }
    ];

    final user = '$cvLine\n\nJOBS:\n${jsonEncode(compactJobs)}\n\n'
        'Trả JSON: [{"job_id","match_score":0-100,"weights":{skills,experience,education,domain,soft_skills,language,career_fit}(tổng=100),"score_breakdown":{...},"recommendation_reason":"2 câu cụ thể","missing_skills":[],"strengths":[]}]\n'
        '(Bọc mảng trong JSON object: {"scores": [...]})';

    return [
      {'role': 'system', 'content': system},
      {'role': 'user', 'content': user},
    ];
  }

  /// AIScoreModal.buildJobsPayload → `job_description` string ('Mô tả: … |
  /// Yêu cầu: … | Quyền lợi: …'), which promptBuilder then slices to 800
  /// chars. jobMapper.parseJobDetail turns a plain-text description into
  /// `mo_ta_cong_viec` lines, so `detail` always exists on the web.
  static String _desc(JobModel j) {
    final d = j.description;
    final moTa = d.isEmpty ? _textLines(j.rawDescription) : d.moTaCongViec;
    final yeuCau = d.isEmpty ? const <String>[] : d.yeuCauUngVien;
    final quyenLoi = d.isEmpty ? const <String>[] : d.quyenLoi;
    final text = 'Mô tả: ${moTa.join('. ')} | Yêu cầu: ${yeuCau.join('. ')} | Quyền lợi: ${quyenLoi.join('. ')}';
    return text.length > AppConfig.aiJobDescCap ? text.substring(0, AppConfig.aiJobDescCap) : text;
  }

  /// jobMapper.toTextArray(string): split on newlines, strip bullets, trim.
  static List<String> _textLines(String? value) {
    if (value == null || value.isEmpty) return const [];
    return value
        .split(RegExp(r'\r?\n'))
        .map((l) => l.replaceFirst(RegExp(r'^[-•*]\s*'), '').trim())
        .where((l) => l.isNotEmpty)
        .toList();
  }

  // ── High-level operations ─────────────────────────────────────────────
  Future<AiAnalysis> extractResume(String resumeText, {String? jobSeekerId, String? resumeId}) async {
    final text = resumeText.length > AppConfig.aiResumeTextCap
        ? resumeText.substring(0, AppConfig.aiResumeTextCap)
        : resumeText;
    final messages = buildResumeExtractionPrompt(text);
    final sw = Stopwatch()..start();
    try {
      final r = await chatCompletion(messages);
      final parsed = _parseJsonObject(r.content);
      await _log(
        task: taskResumeExtraction,
        messages: messages,
        response: r.content,
        ms: sw.elapsedMilliseconds,
        tokensIn: r.tokensIn,
        tokensOut: r.tokensOut,
        success: true,
        metadata: {'job_seeker_id': jobSeekerId, 'resume_id': resumeId, 'text_length': text.length},
      );
      return AiAnalysis(
        resumeId: resumeId,
        summary: parsed['summary']?.toString(),
        skills: _strs(parsed['skills']),
        softSkills: _strs(parsed['soft_skills']),
        languages: _strs(parsed['languages']),
        certifications: _strs(parsed['certifications']),
        workExperience: (parsed['work_experience'] as List?)
                ?.whereType<Map>()
                .map((m) => m.cast<String, dynamic>())
                .toList() ??
            const [],
        totalExperienceYears: (parsed['total_experience_years'] as num?)?.toDouble(),
        educationLevel: parsed['education_level']?.toString(),
        rawText: text,
        modelVersion: model,
        analyzedAt: DateTime.now(),
      );
    } catch (e) {
      await _log(
        task: taskResumeExtraction,
        messages: messages,
        response: '',
        ms: sw.elapsedMilliseconds,
        success: false,
        error: Failure.from(e).message,
        metadata: {'job_seeker_id': jobSeekerId, 'resume_id': resumeId},
      );
      rethrow;
    }
  }

  /// One AI call for ≤100 jobs, retrying malformed JSON up to 2 attempts
  /// (RecommendationController.scoreJobs).
  Future<List<JobScore>> scoreJobs(Map<String, dynamic> cv, List<JobModel> jobs,
      {String? jobSeekerId}) async {
    if (jobs.isEmpty) return const [];
    if (jobs.length > AppConfig.aiMaxJobsPerScoring) {
      throw const Failure('Tối đa 100 việc làm mỗi lần chấm điểm.', status: 400, code: 'TOO_MANY_JOBS');
    }
    final messages = buildJobMatchingPrompt(cv, jobs);
    Object? lastError;
    for (var attempt = 1; attempt <= 2; attempt++) {
      final sw = Stopwatch()..start();
      try {
        final r = await chatCompletion(messages, timeout: const Duration(seconds: 300));
        final scores = _parseScores(r.content);
        await _log(
          task: taskJobMatching,
          messages: messages,
          response: r.content,
          ms: sw.elapsedMilliseconds,
          tokensIn: r.tokensIn,
          tokensOut: r.tokensOut,
          success: true,
          totalJobsSent: jobs.length,
          metadata: {'job_seeker_id': jobSeekerId, 'total_jobs_sent': jobs.length, 'attempt': attempt},
        );
        return scores;
      } catch (e) {
        lastError = e;
        await _log(
          task: taskJobMatching,
          messages: messages,
          response: '',
          ms: sw.elapsedMilliseconds,
          success: false,
          error: Failure.from(e).message,
          totalJobsSent: jobs.length,
          metadata: {'job_seeker_id': jobSeekerId, 'total_jobs_sent': jobs.length, 'attempt': attempt},
        );
        // Backend retries ONLY when the response is not valid JSON; transport
        // errors (timeout, network, HTTP, missing key) surface immediately so
        // the caller's withRetry() is the single retry layer.
        if (e is! Failure || e.code != 'BAD_RESPONSE') rethrow;
      }
    }
    throw Failure('AI trả về JSON không hợp lệ. ${Failure.from(lastError!).message}', status: 502, code: 'BAD_RESPONSE');
  }

  // ── helpers ───────────────────────────────────────────────────────────
  static List<String> _strs(Object? v) =>
      (v as List?)?.map((e) => e.toString()).where((s) => s.isNotEmpty).toList() ?? const [];

  static String _stripFences(String s) {
    var t = s.trim();
    if (t.startsWith('```')) {
      t = t.replaceFirst(RegExp(r'^```(json)?'), '').replaceFirst(RegExp(r'```$'), '').trim();
    }
    return t;
  }

  static Map<String, dynamic> _parseJsonObject(String content) {
    try {
      final v = jsonDecode(_stripFences(content));
      if (v is Map) return v.cast<String, dynamic>();
    } catch (_) {}
    throw const Failure('AI trả về JSON không hợp lệ.', status: 502, code: 'BAD_RESPONSE');
  }

  static List<JobScore> _parseScores(String content) {
    Object? v;
    try {
      v = jsonDecode(_stripFences(content));
    } catch (_) {
      throw const Failure('AI trả về JSON không hợp lệ.', status: 502, code: 'BAD_RESPONSE');
    }
    final list = v is List ? v : (v is Map ? v['scores'] : null);
    if (list is! List) {
      throw const Failure('AI trả về JSON không hợp lệ.', status: 502, code: 'BAD_RESPONSE');
    }
    return list
        .whereType<Map>()
        .map((m) => JobScore.fromJson({...m.cast<String, dynamic>(), 'source': 'ai'}))
        .toList();
  }

  Future<void> _log({
    required String task,
    required List<Map<String, String>> messages,
    required String response,
    required int ms,
    int tokensIn = 0,
    int tokensOut = 0,
    required bool success,
    String? error,
    int? totalJobsSent,
    Map<String, dynamic> metadata = const {},
  }) async {
    final prompt = messages.map((m) => '[${m['role']}]\n${m['content']}').join('\n\n');
    final id = 'ai_${DateTime.now().toIso8601String().replaceAll(':', '-')}_${const Uuid().v4().substring(0, 6)}';
    try {
      await logSink(AiMatchingLog(
        logId: id,
        jobSeekerId: metadata['job_seeker_id']?.toString(),
        task: task,
        promptText: prompt,
        responseText: response,
        modelName: model,
        totalJobsSent: totalJobsSent,
        processingTimeMs: ms,
        tokensIn: tokensIn,
        tokensOut: tokensOut,
        success: success,
        error: error,
        metadata: {for (final e in metadata.entries) if (e.value != null) e.key: e.value},
        createdAt: DateTime.now(),
      ));
    } catch (_) {
      // logging must never fail the AI call
    }
  }
}

/// Internal signal: a provider has no API key configured. Caught by
/// [GeminiService.chatCompletion] and translated into "skip this
/// provider, try the next one" rather than a user-visible error.
class _KeyMissing implements Exception {
  _KeyMissing(this.provider);
  final String provider;
}
