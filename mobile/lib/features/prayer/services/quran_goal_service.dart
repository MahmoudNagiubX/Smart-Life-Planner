import '../../../core/network/api_client.dart';
import '../models/quran_goal_model.dart';

class QuranGoalService {
  final ApiClient _apiClient;

  QuranGoalService(this._apiClient);

  Future<QuranGoalSummary> getSummary() async {
    final response = await _apiClient.dio.get('/prayers/quran-goal');
    return QuranGoalSummary.fromJson(response.data as Map<String, dynamic>);
  }

  Future<QuranGoalSummary> saveGoal({required int dailyPageTarget}) async {
    final response = await _apiClient.dio.put(
      '/prayers/quran-goal',
      data: {'daily_page_target': dailyPageTarget},
    );
    return QuranGoalSummary.fromJson(response.data as Map<String, dynamic>);
  }

  Future<QuranGoalSummary> updateTodayProgress({
    required int pagesCompleted,
  }) async {
    final response = await _apiClient.dio.put(
      '/prayers/quran-progress/today',
      data: {'pages_completed': pagesCompleted},
    );
    return QuranGoalSummary.fromJson(response.data as Map<String, dynamic>);
  }

  Future<QuranGoalSummary> updateProgressForDate({
    required String progressDate,
    required int pagesCompleted,
  }) async {
    final response = await _apiClient.dio.put(
      '/prayers/quran-progress/$progressDate',
      data: {'pages_completed': pagesCompleted},
    );
    return QuranGoalSummary.fromJson(response.data as Map<String, dynamic>);
  }
}
