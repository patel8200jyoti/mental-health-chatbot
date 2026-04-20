import '../services/core/api_service.dart';

class AdminApi {
  final _client = ApiClient().dio;

  Future<Map<String, dynamic>> getStats() async {
    final response = await _client.get("/admin/stats");
    return Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await _client.get("/admin/stats/dashboard");
    return Map<String, dynamic>.from(response.data);
  }

  Future<List<Map<String, dynamic>>> getMoodTrends({String range = 'M'}) async {
    final response = await _client.get(
      "/admin/stats/moods",
      queryParameters: {"range": range},
    );
    return List<Map<String, dynamic>>.from(response.data as List);
  }

  Future<List<Map<String, dynamic>>> getUsers(
      {int skip = 0, int limit = 50}) async {
    final response = await _client.get("/admin/users",
        queryParameters: {"skip": skip, "limit": limit});
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<List<Map<String, dynamic>>> getAdminProfessionals(
      {int skip = 0, int limit = 50}) async {
    final response = await _client.get("/admin/professionals",
        queryParameters: {"skip": skip, "limit": limit});
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<void> toggleUser(String userId, bool disabled) async {
    await _client.patch("/admin/users/$userId/activate",
        queryParameters: {"disabled": disabled});
  }

  Future<void> approveProfessional(String professionalId, bool approve) async {
    await _client.patch("/admin/professionals/$professionalId/approve", queryParameters: {"approve": approve});
  }

  Future<List<Map<String, dynamic>>> getCrisisAlerts(
      {bool? resolved, int skip = 0, int limit = 50}) async {
    final response = await _client.get("/admin/crisis", queryParameters: {
      if (resolved != null) "resolved": resolved.toString(),
      "skip":  skip,
      "limit": limit,
    });
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<void> resolveAlert(String alertId) async {
    await _client.patch("/admin/crisis/$alertId/resolve");
  }

  Future<Map<String, dynamic>> getMoodSummary() async {
  final response = await _client.get("/admin/stats/moods/summary");
  return Map<String, dynamic>.from(response.data);
}

Future<Map<String, dynamic>> getJournalStats() async {
  final response = await _client.get("/admin/stats/journals");
  return Map<String, dynamic>.from(response.data);
}
  
}