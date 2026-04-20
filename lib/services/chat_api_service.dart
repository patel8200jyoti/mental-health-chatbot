import 'package:dio/dio.dart';
import '../services/core/api_service.dart';

class AppApi {
  final ApiClient _apiClient = ApiClient();
  late final Dio _dio = _apiClient.dio;

  // ───────── STORAGE HELPERS ─────────

  Future<void> saveChatId(String id) async {}

  // Actually use ApiClient storage directly:
  Future<void> saveToken(String token) => _apiClient.saveToken(token);

  // ── AUTH ──────────────────────────────────────────────────────────────────

  /// Returns { "success": true } on 200 or 201.
  /// Returns { "success": false, "message": "..." } — never throws.
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String userName,
    DateTime? dob,
    String? userGender,
  }) async {
    try {
      final response = await _dio.post(
        "/auth/register",
        data: {
          "user_email": email,
          "password": password,
          "user_name": userName,
          if (dob != null) "user_dob": dob.toIso8601String().split("T").first,
          if (userGender != null) "user_gender": userGender,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          "success": true,
          ...Map<String, dynamic>.from(response.data as Map? ?? {}),
        };
      }

      // 400 / 409 — e.g. "email already exists"
      final detail =
          (response.data as Map?)?["detail"]?.toString() ??
          "Registration failed";
      return {"success": false, "message": detail};
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg =
          (data is Map ? data["detail"]?.toString() : null) ??
          "Registration failed";
      return {"success": false, "message": msg};
    } catch (e) {
      return {
        "success": false,
        "message": "Network error. Check your connection.",
      };
    }
  }

  /// FastAPI OAuth2PasswordRequestForm requires form-encoded "username" field.
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        "/auth/login",
        data: {"username": email, "password": password},
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          responseType: ResponseType.json,
        ),
      );

      if (response.statusCode == 200) {
        final token = response.data["access_token"];
        if (token != null) {
          await saveToken(token);
          return {"success": true, "token": token};
        }
        return {"success": false, "message": "Token missing in response"};
      }

      final detail =
          (response.data as Map?)?["detail"]?.toString() ??
          "Invalid credentials";
      return {"success": false, "message": detail};
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg =
          (data is Map ? data["detail"]?.toString() : null) ?? "Login failed";
      return {"success": false, "message": msg};
    } catch (e) {
      return {"success": false, "message": "Unexpected error occurred"};
    }
  }

  // ── CHAT ──────────────────────────────────────────────────────────────────

  Future<String> createChat() async {
    final response = await _dio.post("/chat/");
    final chatId = response.data["chat_id"] as String;
    await saveChatId(chatId);
    return chatId;
  }

  Future<List<Map<String, dynamic>>> getChats() async {
    final response = await _dio.get("/chat/list");
    return List<Map<String, dynamic>>.from(response.data as List);
  }

  Future<List<Map<String, dynamic>>> getMessages(String chatId) async {
    final response = await _dio.get("/chat/$chatId");
    final data = response.data;
    List<dynamic> raw = [];
    if (data != null && data is Map<String, dynamic>) {
      if (data["message"] is List)
        raw = data["message"];
      else if (data["messages"] is List)
        raw = data["messages"];
    } else if (data is List) {
      raw = data;
    }
    return raw
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }

  Future<Map<String, dynamic>> sendMessage(
    String chatId,
    String message,
  ) async {
    final res = await _dio.post(
      "/chat/$chatId",
      data: {"chat_id": chatId, "message": message},
    );

    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<void> clearChat(String chatId) async =>
      _dio.delete("/chat/$chatId/clear");

  Future<void> deleteChat(String chatId) async {
    await _dio.delete("/chat/$chatId");
  }

  // ── MOOD ──────────────────────────────────────────────────────────────────

  // Backend score scale: sad=2, okay=3, calm=4, happy=5, great=6
  static const Map<String, int> moodValues = {
    "sad":   2,
    "okay":  3,
    "calm":  4,
    "happy": 5,
    "great": 6,
  };

  Future<void> addMood(String mood, {DateTime? date}) async {
    final d = date ?? DateTime.now();
    await _dio.post(
      "/mood/",
      data: {
        "user_mood":  mood.toLowerCase(),
        "mood_score": moodValues[mood.toLowerCase()] ?? 4,
        "mood_date":  d.toIso8601String().split("T").first,
      },
    );
  }

  /// Last 7 days — kept for backward compat.
  Future<List<Map<String, dynamic>>> getWeekMood() async {
    final response = await _dio.get("/mood/week");
    return List<Map<String, dynamic>>.from(response.data as List);
  }

  /// Full mood history, sorted oldest → newest.
  Future<List<Map<String, dynamic>>> getAllMoods() async {
    final response = await _dio.get("/mood/all");
    return List<Map<String, dynamic>>.from(response.data as List);
  }

  /// Pre-aggregated stats from the backend.
  /// Returns:
  /// {
  ///   "daily":   [ { "date": "2025-06-07", "avg_score": 4.5 }, ... ],
  ///   "weekly":  [ { "year": 2025, "week": 23,  "avg_score": 4.2 }, ... ],
  ///   "monthly": [ { "year": 2025, "month": 6,  "avg_score": 4.0 }, ... ],
  /// }
  Future<Map<String, dynamic>> getMoodStats() async {
    final response = await _dio.get("/mood/stats");
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<int> getStreak() async {
    final response = await _dio.get("/mood/streak");
    return (response.data["current_streak"] as num).toInt();
  }

  // ── JOURNAL ───────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getJournals() async {
    final response = await _dio.get("/journal/");
    return List<Map<String, dynamic>>.from(response.data as List);
  }

  Future<Map<String, dynamic>> addJournal(String content) async {
    final response = await _dio.post("/journal/", data: {"content": content});
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> updateJournal(String id, String content) async {
    final response = await _dio.put("/journal/$id", data: {"content": content});
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<void> deleteJournal(String id) async => _dio.delete("/journal/$id");

  // ── TOOLKIT ───────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAllTools() async {
    final response = await _dio.get("/toolkit/");
    return List<Map<String, dynamic>>.from(response.data as List);
  }

  Future<Map<String, dynamic>> getGroupedTools() async {
    final response = await _dio.get("/toolkit/grouped");
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> getToolById(String id) async {
    final response = await _dio.get("/toolkit/$id");
    return Map<String, dynamic>.from(response.data as Map);
  }

  // ───────── PROFILE ─────────

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _dio.get("/profile/me");
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>?> getReport() async {
    try {
      final response = await _dio.get("/profile/report/me");
      if (response.statusCode == 404) return null;
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<Map<String, dynamic>> regenerateReport() async {
    final response = await _dio.post("/profile/report/me");
    return Map<String, dynamic>.from(response.data as Map);
  }

  // ───────── LOGOUT ─────────
  Future<void> logout() async {
    // Delete all stored tokens / IDs
    await _apiClient.logout(); // calls the actual ApiClient logout
  }

  // ── Professional browsing / linking ──────────────────────────────────────

  /// All approved professionals (browse list)
  Future<List<Map<String, dynamic>>> getProfessionals() async {
    final r = await _dio.get('/professional/');
    final data = r.data;
    if (data is Map) {
      final inner = data['data'] ?? data['professionals'] ?? data['results'];
      if (inner is List) return List<Map<String, dynamic>>.from(inner);
      // single-key map — grab first list value
      for (final v in data.values) {
        if (v is List) return List<Map<String, dynamic>>.from(v);
      }
      return [];
    }
    return List<Map<String, dynamic>>.from(data as List);
  }

  /// Send a link request to a professional
  Future<Map<String, dynamic>> requestProfessional(
    String professionalId,
  ) async {
    final r = await _dio.post(
      '/professional/request',
      data: {'professional_id': professionalId},
    );
    return Map<String, dynamic>.from(r.data as Map);
  }

  /// Cancel a pending request
  Future<void> cancelRequest(String professionalId) async {
    await _dio.delete('/my-doctor/request/$professionalId');
  }

  /// All link records for the current user (any status)
  Future<List<Map<String, dynamic>>> getMyLinks() async {
    try {
      final r = await _dio.get('/my-doctor/links');
      final data = r.data;
      if (data is Map) {
        return List<Map<String, dynamic>>.from(data['data'] as List? ?? []);
      }
      return List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      return [];
    }
  }

  /// Link info + permissions for a specific professional
  Future<Map<String, dynamic>> getMyLinkWith(String professionalId) async {
    final r = await _dio.get('/my-doctor/link/$professionalId');
    return Map<String, dynamic>.from(r.data as Map);
  }

  /// Update mood / journal share permissions
  Future<void> updateLinkPermissions(
    String professionalId, {
    required bool allowMood,
    required bool allowJournal,
  }) async {
    await _dio.put(
      '/my-doctor/link/$professionalId/permissions',
      data: {'allow_mood': allowMood, 'allow_journal': allowJournal},
    );
  }

  /// Unlink a professional completely
  Future<void> unlinkProfessional(String professionalId) async {
    await _dio.delete('/my-doctor/link/$professionalId');
  }

  /// Public profile of a professional
  Future<Map<String, dynamic>> getProfProfile(String professionalId) async {
    final r = await _dio.get('/my-doctor/$professionalId/profile');
    return Map<String, dynamic>.from(r.data as Map);
  }

  // ── Sessions ──────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getSessions(String professionalId) async {
    final r = await _dio.get('/my-doctor/$professionalId/sessions');
    return List<Map<String, dynamic>>.from(r.data as List);
  }

  Future<void> requestSession(
    String professionalId,
    String isoDate,
    String sessionType,
    String note,
  ) async {
    await _dio.post(
      '/my-doctor/$professionalId/sessions',
      data: {
        'session_date': isoDate,
        'session_type': sessionType,
        'note': note,
      },
    );
  }

  // ── Portal messages ───────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getPortalMessages(
    String professionalId,
  ) async {
    final r = await _dio.get('/my-doctor/$professionalId/messages');
    return List<Map<String, dynamic>>.from(r.data as List);
  }

  Future<void> sendPortalMessage(String professionalId, String text) async {
    await _dio.post(
      '/my-doctor/$professionalId/messages',
      data: {'text': text},
    );
  }
}