import '../../../core/network/api_client.dart';
import '../models/focus_model.dart';

class FocusService {
  final ApiClient _apiClient;

  FocusService(this._apiClient);

  Future<FocusSession> startSession({
    required int plannedMinutes,
    String sessionType = 'pomodoro',
    String? taskId,
  }) async {
    final response = await _apiClient.dio.post(
      '/focus/sessions',
      data: {
        'planned_minutes': plannedMinutes,
        'session_type': sessionType,
        // ignore: use_null_aware_elements
        if (taskId != null) 'task_id': taskId,
      },
    );
    return FocusSession.fromJson(response.data as Map<String, dynamic>);
  }

  Future<FocusSession?> getActiveSession() async {
    try {
      final response = await _apiClient.dio.get('/focus/sessions/active');
      return FocusSession.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<FocusSession> completeSession(String sessionId) async {
    final response = await _apiClient.dio.patch(
      '/focus/sessions/$sessionId/complete',
    );
    return FocusSession.fromJson(response.data as Map<String, dynamic>);
  }

  Future<FocusSession> cancelSession(String sessionId) async {
    final response = await _apiClient.dio.patch(
      '/focus/sessions/$sessionId/cancel',
    );
    return FocusSession.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<FocusSession>> getSessions() async {
    final response = await _apiClient.dio.get('/focus/sessions');
    return (response.data as List<dynamic>)
        .map((s) => FocusSession.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  Future<FocusAnalytics> getAnalytics() async {
    final response = await _apiClient.dio.get('/focus/analytics');
    return FocusAnalytics.fromJson(response.data as Map<String, dynamic>);
  }

  Future<FocusRecommendation> getRecommendation() async {
    final response = await _apiClient.dio.get('/focus/recommendation');
    return FocusRecommendation.fromJson(response.data as Map<String, dynamic>);
  }

  Future<FocusSettings> getSettings() async {
    final response = await _apiClient.dio.get('/focus/settings');
    return FocusSettings.fromJson(response.data as Map<String, dynamic>);
  }

  Future<FocusSettings> updateSettings(FocusSettings settings) async {
    final response = await _apiClient.dio.patch(
      '/focus/settings',
      data: settings.toJson(),
    );
    return FocusSettings.fromJson(response.data as Map<String, dynamic>);
  }
}
