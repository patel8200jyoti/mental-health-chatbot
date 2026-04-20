import 'package:dio/dio.dart';
import '../services/core/api_service.dart';

class ProfessionalApi {
  final _client = ApiClient().dio;
  final _core = AppApi();

  // ── Auth ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) => _core.login(email: email, password: password);

  Future<void> logout() => _core.logout();

  /// Called by ProffSignupScreen
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String medicalRegistrationNumber,
    required String stateMedicalCouncil,
    required String yearOfRegistration,
    required String educationalQualifications,
    required String email,
    required String password,
    DateTime? dob,
    String? gender,
  }) async {
    try {
      final response = await _client.post(
        "/professional/register",
        data: {
          "full_name":                   fullName,
          "medical_registration_number": medicalRegistrationNumber,
          "state_medical_council":       stateMedicalCouncil,
          "year_of_registration":        yearOfRegistration,
          "educational_qualifications":  educationalQualifications,
          "user_email":                  email,
          "password":                    password,
          if (dob != null) "user_dob": dob.toIso8601String().split("T").first,
          if (gender != null) "user_gender": gender,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          "success": true,
          ...Map<String, dynamic>.from(response.data as Map? ?? {}),
        };
      }
      final detail = (response.data as Map?)?["detail"]?.toString() ??
          "Registration failed";
      return {"success": false, "message": detail};
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = (data is Map ? data["detail"]?.toString() : null) ??
          "Registration failed";
      return {"success": false, "message": msg};
    } catch (_) {
      return {"success": false, "message": "Network error. Check your connection."};
    }
  }

  // ── Own profile ───────────────────────────────────────────────────────────

  /// Used by ProffLogin screen
  Future<Map<String, dynamic>> getMe() => getProfessionalMe();

  /// Used by other existing pages — kept so nothing else breaks
  Future<Map<String, dynamic>> getProfessionalMe() async {
    final response = await _client.get("/professional/me");
    return Map<String, dynamic>.from(response.data as Map);
  }

  // ── Browse ────────────────────────────────────────────────────────────────

Future<List<Map<String, dynamic>>> getProfessionals() async {
  final r = await _client.get("/professional/");
  final data = r.data;

  return List<Map<String, dynamic>>.from(data["data"]);
}

  // ── Dashboard ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getDashboardStats() async {
    final r = await _client.get('/professional/dashboard/stats');
    return Map<String, dynamic>.from(r.data as Map);
  }

  // ── Patients ──────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getPatients() async {
    final r = await _client.get('/professional/patients');
    return List<Map<String, dynamic>>.from(r.data as List);
  }

  Future<List<Map<String, dynamic>>> getPendingRequests() async {
    final r = await _client.get('/professional/patients/pending');
    return List<Map<String, dynamic>>.from(r.data as List);
  }

  Future<void> respondToRequest(String userId, bool accept) async {
    await _client.post('/professional/patients/$userId/respond',
        data: {'accept': accept});
  }

  Future<void> removePatient(String userId) async {
    await _client.delete('/professional/patients/$userId');
  }

  // ── Patient detail ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getPatientProfile(String userId) async {
    final r = await _client.get('/professional/patients/$userId/profile');
    return Map<String, dynamic>.from(r.data as Map);
  }

  Future<List<Map<String, dynamic>>> getPatientMoods(String userId) async {
    final r = await _client.get('/professional/patients/$userId/moods');
    return List<Map<String, dynamic>>.from(r.data as List);
  }

  Future<List<Map<String, dynamic>>> getPatientJournals(String userId) async {
    final r = await _client.get('/professional/patients/$userId/journals');
    return List<Map<String, dynamic>>.from(r.data as List);
  }

  // ── Crisis ────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getCrisisAlerts(
      {bool resolved = false}) async {
    final r = await _client.get('/professional/crisis',
        queryParameters: {'resolved': resolved});
    return List<Map<String, dynamic>>.from(r.data as List);
  }

  Future<void> resolveAlert(String alertId) async {
    await _client.post('/professional/crisis/$alertId/resolve');
  }

  // ── Notes ─────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getNotes(String userId) async {
    final r = await _client.get('/professional/patients/$userId/notes');
    return List<Map<String, dynamic>>.from(r.data as List);
  }

  Future<void> addNote(String userId, String note) async {
    await _client.post('/professional/patients/$userId/notes',
        data: {'note': note});
  }

  Future<void> deleteNote(String userId, String noteId) async {
    await _client.delete('/professional/patients/$userId/notes/$noteId');
  }
}


// have you used all the methods there were  in the main api i sent you because there are errors coming so i am building a project of flutter fastapi mongodb and the thing is the backend complete api is in one file and i get confused i want three files of professional apiconnect , admin api connect and other chat api connect this is the code import 'package:dio/dio.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// class ApiService {
//   // Android Emulator  → http://10.0.2.2:8000
//   // Real Device       → http://YOUR_LOCAL_IP:8000
//   // Production        → https://your-backend.com
//   static const String baseUrl = "http://172.16.26.248:8000";
//   final Dio _dio = Dio(
//     BaseOptions(
//       baseUrl: baseUrl,
//       connectTimeout: const Duration(seconds: 10),
//       receiveTimeout: const Duration(seconds: 15),
//       headers: {"Content-Type": "application/json"},
//       // ✅ THE FIX: Dio throws exceptions for any status >= 400 by default.

      
//       // This means 201 Created, 400 Bad Request, 409 Conflict etc. all become
//       // unhandled exceptions instead of normal responses.
//       // By setting validateStatus to only reject 500+, we get all responses
//       // back normally so we can read statusCode and show proper error messages.
//       validateStatus: (status) => status != null && status < 500,
//     ),
//   );

//   final FlutterSecureStorage _storage = const FlutterSecureStorage();

//   ApiService() {
//     _dio.interceptors.add(
//       InterceptorsWrapper(
//         onRequest: (options, handler) async {
//           final token = await _storage.read(key: "access_token");
//           if (token != null) {
//             options.headers["Authorization"] = "Bearer $token";
//           }
//           debugPrint("➡️  ${options.method} ${options.uri}");
//           return handler.next(options);
//         },
//         onResponse: (response, handler) {
//           debugPrint("✅ ${response.statusCode} ${response.requestOptions.uri}");
//           return handler.next(response);
//         },
//         onError: (e, handler) async {
//           debugPrint("❌ ${e.response?.statusCode} ${e.requestOptions.uri} — ${e.message}");
//           if (e.response?.statusCode == 401) await logout();
//           return handler.next(e);
//         },
//       ),
//     );
//   }

//   // ── Storage helpers ───────────────────────────────────────────────────────

//   Future<void> saveToken(String token) =>
//       _storage.write(key: "access_token", value: token);

//   Future<String?> getToken() => _storage.read(key: "access_token");

//   Future<void> saveChatId(String id) =>
//       _storage.write(key: "chat_id", value: id);

//   Future<String?> getSavedChatId() => _storage.read(key: "chat_id");

//   Future<void> saveUserId(String id) =>
//       _storage.write(key: "user_id", value: id);

//   Future<String?> getSavedUserId() => _storage.read(key: "user_id");

//   Future<void> logout() => _storage.deleteAll();

//   // ── AUTH ──────────────────────────────────────────────────────────────────

//   /// Returns { "success": true } on 200 or 201.
//   /// Returns { "success": false, "message": "..." } — never throws.
//   Future<Map<String, dynamic>> register({
//     required String email,
//     required String password,
//     required String userName,
//     DateTime? dob,
//     String? userGender,
//   }) async {
//     try {
//       final response = await _dio.post(
//         "/auth/register",
//         data: {
//           "user_email": email,
//           "password":   password,
//           "user_name":  userName,
//           if (dob != null)
//             "user_dob": dob.toIso8601String().split("T").first,
//           if (userGender != null) "user_gender": userGender,
//         },
//       );

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         return {
//           "success": true,
//           ...Map<String, dynamic>.from(response.data as Map? ?? {}),
//         };
//       }

//       // 400 / 409 — e.g. "email already exists"
//       final detail = (response.data as Map?)?["detail"]?.toString()
//           ?? "Registration failed";
//       return {"success": false, "message": detail};

//     } on DioException catch (e) {
//       final data = e.response?.data;
//       final msg = (data is Map ? data["detail"]?.toString() : null)
//           ?? "Registration failed";
//       return {"success": false, "message": msg};
//     } catch (e) {
//       return {"success": false, "message": "Network error. Check your connection."};
//     }
//   }

//   /// FastAPI OAuth2PasswordRequestForm requires form-encoded "username" field.
//   Future<Map<String, dynamic>> login({
//     required String email,
//     required String password,
//   }) async {
//     try {
//       final response = await _dio.post(
//         "/auth/login",
//         data: {"username": email, "password": password},
//         options: Options(
//           contentType: Headers.formUrlEncodedContentType,
//           responseType: ResponseType.json,
//         ),
//       );

//       if (response.statusCode == 200) {
//         final token = response.data["access_token"];
//         if (token != null) {
//           await saveToken(token);
//           return {"success": true, "token": token};
//         }
//         return {"success": false, "message": "Token missing in response"};
//       }

//       final detail = (response.data as Map?)?["detail"]?.toString()
//           ?? "Invalid credentials";
//       return {"success": false, "message": detail};

//     } on DioException catch (e) {
//       final data = e.response?.data;
//       final msg = (data is Map ? data["detail"]?.toString() : null)
//           ?? "Login failed";
//       return {"success": false, "message": msg};
//     } catch (e) {
//       return {"success": false, "message": "Unexpected error occurred"};
//     }
//   }

//   // ── CHAT ──────────────────────────────────────────────────────────────────

//   Future<String> createChat() async {
//     final response = await _dio.post("/chat/");
//     final chatId = response.data["chat_id"] as String;
//     await saveChatId(chatId);
//     return chatId;
//   }

//   Future<List<Map<String, dynamic>>> getChats() async {
//     final response = await _dio.get("/chat/list");
//     return List<Map<String, dynamic>>.from(response.data as List);
//   }

//   Future<List<Map<String, dynamic>>> getMessages(String chatId) async {
//     final response = await _dio.get("/chat/$chatId");
//     final data = response.data;
//     List<dynamic> raw = [];
//     if (data != null && data is Map<String, dynamic>) {
//       if (data["message"] is List) raw = data["message"];
//       else if (data["messages"] is List) raw = data["messages"];
//     } else if (data is List) {
//       raw = data;
//     }
//     return raw.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
//   }

//   Future<Map<String, dynamic>> sendMessage(String chatId, String message) async {
//     final res = await _dio.post(
//       "/chat/$chatId",
//       data: {"chat_id": chatId, "message": message},
//     );
//     final inner = res.data["response"];
//     if (inner is Map) return Map<String, dynamic>.from(inner);
//     return {"response": inner.toString(), "crisis_detected": false};
//   }

//   Future<void> clearChat(String chatId) async =>
//       _dio.delete("/chat/$chatId/clear");

//   // ── MOOD ──────────────────────────────────────────────────────────────────

//   static const Map<String, int> moodValues = {
//     "sad": 1, "okay": 2, "calm": 3, "happy": 4, "great": 5,
//   };

//   Future<void> addMood(String mood, {DateTime? date}) async {
//     final d = date ?? DateTime.now();
//     await _dio.post("/mood/", data: {
//       "user_mood": mood.toLowerCase(),
//       "value":     moodValues[mood.toLowerCase()] ?? 3,
//       "mood_date": d.toIso8601String().split("T").first,
//     });
//   }

//   Future<List<Map<String, dynamic>>> getWeekMood() async {
//     final response = await _dio.get("/mood/week");
//     return List<Map<String, dynamic>>.from(response.data as List);
//   }

//   Future<int> getStreak() async {
//     final response = await _dio.get("/mood/streak");
//     return (response.data["current_streak"] as num).toInt();
//   }

//   // ── JOURNAL ───────────────────────────────────────────────────────────────

//   Future<List<Map<String, dynamic>>> getJournals() async {
//     final response = await _dio.get("/journal/");
//     return List<Map<String, dynamic>>.from(response.data as List);
//   }

//   Future<Map<String, dynamic>> addJournal(String content) async {
//     final response = await _dio.post("/journal/", data: {"content": content});
//     return Map<String, dynamic>.from(response.data as Map);
//   }

//   Future<Map<String, dynamic>> updateJournal(String id, String content) async {
//     final response = await _dio.put("/journal/$id", data: {"content": content});
//     return Map<String, dynamic>.from(response.data as Map);
//   }

//   Future<void> deleteJournal(String id) async => _dio.delete("/journal/$id");

//   // ── TOOLKIT ───────────────────────────────────────────────────────────────

//   Future<List<Map<String, dynamic>>> getAllTools() async {
//     final response = await _dio.get("/toolkit/");
//     return List<Map<String, dynamic>>.from(response.data as List);
//   }

//   Future<Map<String, dynamic>> getGroupedTools() async {
//     final response = await _dio.get("/toolkit/grouped");
//     return Map<String, dynamic>.from(response.data as Map);
//   }

//   Future<Map<String, dynamic>> getToolById(String id) async {
//     final response = await _dio.get("/toolkit/$id");
//     return Map<String, dynamic>.from(response.data as Map);
//   }

//   // ── PROFESSIONAL ──────────────────────────────────────────────────────────

//   /// Register a new professional account (no auth token needed).
//   /// Backend returns 201 on success.
//   Future<Map<String, dynamic>> registerProfessional({
//     required String userName,
//     required String professionalRole,
//     required String email,
//     required String password,
//     DateTime? dob,
//     String? gender,
//   }) async {
//     try {
//       final response = await _dio.post(
//         "/professional/register",
//         data: {
//           "user_name":         userName,
//           "professional_role": professionalRole,
//           "user_email":        email,
//           "password":          password,
//           if (dob != null)
//             "user_dob": dob.toIso8601String().split("T").first,
//           if (gender != null) "user_gender": gender,
//         },
//       );

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         return {
//           "success": true,
//           ...Map<String, dynamic>.from(response.data as Map? ?? {}),
//         };
//       }

//       final detail = (response.data as Map?)?["detail"]?.toString()
//           ?? "Registration failed";
//       return {"success": false, "message": detail};

//     } on DioException catch (e) {
//       final data = e.response?.data;
//       final msg = (data is Map ? data["detail"]?.toString() : null)
//           ?? "Registration failed";
//       return {"success": false, "message": msg};
//     } catch (e) {
//       return {"success": false, "message": "Network error. Check your connection."};
//     }
//   }

//   /// List all approved professionals (patient browse screen).
//   Future<List<Map<String, dynamic>>> getProfessionals() async {
//     final response = await _dio.get("/professional/");
//     return List<Map<String, dynamic>>.from(response.data as List);
//   }

//   /// Patient sends a connection request to a professional.
//   Future<Map<String, dynamic>> requestProfessional(String professionalId) async {
//     final response = await _dio.post(
//       "/professional/request",
//       data: {"professional_id": professionalId},
//     );
//     return Map<String, dynamic>.from(response.data as Map);
//   }

//   /// Get the logged-in professional's own profile.
//   Future<Map<String, dynamic>> getProfessionalMe() async {
//     final response = await _dio.get("/professional/me");
//     return Map<String, dynamic>.from(response.data as Map);
//   }

//   /// All pending patient requests waiting for accept/reject.
//   Future<List<Map<String, dynamic>>> getPendingRequests() async {
//     final response = await _dio.get("/professional/requests/pending");
//     return List<Map<String, dynamic>>.from(response.data as List);
//   }

//   /// Accept or reject a pending link request. action = 'accepted' | 'rejected'
//   Future<void> respondToRequest(String requestId, String action) async {
//     await _dio.patch(
//       "/professional/requests/$requestId",
//       queryParameters: {"action": action},
//     );
//   }

//   /// All accepted patients linked to the logged-in professional.
//   Future<List<Map<String, dynamic>>> getMyPatients() async {
//     final response = await _dio.get("/professional/patients");
//     return List<Map<String, dynamic>>.from(response.data as List);
//   }

//   Future<List<Map<String, dynamic>>> getPatientMoods(String patientId) async {
//     final response = await _dio.get("/professional/patients/$patientId/moods");
//     return List<Map<String, dynamic>>.from(response.data as List);
//   }

//   Future<List<Map<String, dynamic>>> getPatientJournals(String patientId) async {
//     final response = await _dio.get("/professional/patients/$patientId/journals");
//     return List<Map<String, dynamic>>.from(response.data as List);
//   }

//   Future<List<Map<String, dynamic>>> getPatientCrisis(String patientId) async {
//     final response = await _dio.get("/professional/patients/$patientId/crisis");
//     return List<Map<String, dynamic>>.from(response.data as List);
//   }

//   Future<List<Map<String, dynamic>>> getPatientTrends(String patientId) async {
//     final response = await _dio.get("/professional/patients/$patientId/trends");
//     return List<Map<String, dynamic>>.from(response.data as List);
//   }

//   Future<Map<String, dynamic>> addNote(String patientId, String note) async {
//     final response = await _dio.post(
//       "/professional/patients/$patientId/notes",
//       data: {"note": note},
//     );
//     return Map<String, dynamic>.from(response.data as Map);
//   }

//   Future<List<Map<String, dynamic>>> getNotes(String patientId) async {
//     final response = await _dio.get("/professional/patients/$patientId/notes");
//     return List<Map<String, dynamic>>.from(response.data as List);
//   }

//   // ── PROFILE ───────────────────────────────────────────────────────────────

//   Future<Map<String, dynamic>> getProfile() async {
//     final response = await _dio.get("/profile/me");
//     return Map<String, dynamic>.from(response.data as Map);
//   }

//   Future<Map<String, dynamic>?> getReport() async {
//     try {
//       final response = await _dio.get("/profile/report/me");
//       if (response.statusCode == 404) return null;
//       return Map<String, dynamic>.from(response.data as Map);
//     } on DioException catch (e) {
//       if (e.response?.statusCode == 404) return null;
//       rethrow;
//     }
//   }

//   Future<Map<String, dynamic>> regenerateReport() async {
//     final response = await _dio.post("/profile/report/me");
//     return Map<String, dynamic>.from(response.data as Map);
//   }

//   // ── ADMIN ─────────────────────────────────────────────────────────────────

//   Future<Map<String, dynamic>> getStats() async {
//     final response = await _dio.get("/admin/stats");
//     return Map<String, dynamic>.from(response.data);
//   }

//   Future<Map<String, dynamic>> getDashboardStats() async {
//     final response = await _dio.get("/admin/stats/dashboard");
//     return Map<String, dynamic>.from(response.data);
//   }

//   Future<List<Map<String, dynamic>>> getMoodTrends({String range = 'M'}) async {
//     final response = await _dio.get(
//       "/admin/stats/moods",
//       queryParameters: {"range": range},
//     );
//     return List<Map<String, dynamic>>.from(response.data as List);
//   }

//   Future<List<Map<String, dynamic>>> getUsers(
//       {int skip = 0, int limit = 50}) async {
//     final response = await _dio.get("/admin/users",
//         queryParameters: {"skip": skip, "limit": limit});
//     return List<Map<String, dynamic>>.from(response.data);
//   }

//   Future<List<Map<String, dynamic>>> getAdminProfessionals(
//       {int skip = 0, int limit = 50}) async {
//     final response = await _dio.get("/admin/professionals",
//         queryParameters: {"skip": skip, "limit": limit});
//     return List<Map<String, dynamic>>.from(response.data);
//   }

//   Future<void> toggleUser(String userId, bool disabled) async {
//     await _dio.patch("/admin/users/$userId/activate",
//         queryParameters: {"disabled": disabled});
//   }

//   Future<void> approveProfessional(String professionalId, bool approve) async {
//     await _dio.patch("/admin/professionals/$professionalId/approve",
//         queryParameters: {"approve": approve});
//   }

//   Future<List<Map<String, dynamic>>> getCrisisAlerts(
//       {bool? resolved, int skip = 0, int limit = 50}) async {
//     final response = await _dio.get("/admin/crisis", queryParameters: {
//       if (resolved != null) "resolved": resolved.toString(),
//       "skip":  skip,
//       "limit": limit,
//     });
//     return List<Map<String, dynamic>>.from(response.data);
//   }

//   Future<void> resolveAlert(String alertId) async {
//     await _dio.patch("/admin/crisis/$alertId/resolve");
//   }
// }