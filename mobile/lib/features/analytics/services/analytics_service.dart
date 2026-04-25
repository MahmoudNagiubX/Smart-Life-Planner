import '../../../core/network/api_client.dart';
import '../models/analytics_model.dart';

class AnalyticsService {
  final ApiClient _apiClient;

  AnalyticsService(this._apiClient);

  Future<TodayAnalytics> getTodayAnalytics() async {
    final response = await _apiClient.dio.get('/analytics/today');
    return TodayAnalytics.fromJson(response.data as Map<String, dynamic>);
  }

  Future<WeeklyAnalytics> getWeeklyAnalytics() async {
    final response = await _apiClient.dio.get('/analytics/weekly');
    return WeeklyAnalytics.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<AnalyticsInsight>> getInsights() async {
    final response = await _apiClient.dio.get('/analytics/insights');
    final data = response.data as Map<String, dynamic>;
    return (data['insights'] as List<dynamic>)
        .map((i) =>
            AnalyticsInsight.fromJson(i as Map<String, dynamic>))
        .toList();
  }
}