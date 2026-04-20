import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static const String baseUrl = "http://127.0.0.1:8000";

  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late final Dio dio;

  ApiClient._internal() {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {"Content-Type": "application/json"},
      validateStatus: (status) => status != null && status < 500,
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: "access_token");
        if (token != null) {
          options.headers["Authorization"] = "Bearer $token";
        }
        debugPrint("➡️  ${options.method} ${options.uri}");
        return handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint("✅ ${response.statusCode} ${response.requestOptions.uri}");
        return handler.next(response);
      },
      onError: (e, handler) async {
        debugPrint("❌ ${e.response?.statusCode} ${e.requestOptions.uri}");
        if (e.response?.statusCode == 401) await logout();
        return handler.next(e);
      },
    ));
  }

  Future<void> saveToken(String token) =>
      _storage.write(key: "access_token", value: token);
  Future<String?> getToken() => _storage.read(key: "access_token");
  Future<void> saveUserId(String id) =>
      _storage.write(key: "user_id", value: id);
  Future<String?> getSavedUserId() => _storage.read(key: "user_id");
  Future<void> saveChatId(String id) =>
      _storage.write(key: "chat_id", value: id);
  Future<String?> getSavedChatId() => _storage.read(key: "chat_id");
  Future<void> logout() => _storage.deleteAll();
}

class AppApi {
  final _client = ApiClient();

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.dio.post(
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
          await _client.saveToken(token as String);
          return {"success": true, "token": token};
        }
        return {"success": false, "message": "Token missing in response"};
      }
      final detail = (response.data as Map?)?["detail"]?.toString() ??
          "Invalid credentials";
      return {"success": false, "message": detail};
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg =
          (data is Map ? data["detail"]?.toString() : null) ?? "Login failed";
      return {"success": false, "message": msg};
    } catch (_) {
      return {"success": false, "message": "Unexpected error occurred"};
    }
  }

  Future<void> logout() => _client.logout();
}