import '../../../core/network/api_client.dart';

class AiService {
  final ApiClient _apiClient;

  AiService(this._apiClient);

  Future<Map<String, dynamic>> parseTask(String inputText) async {
    final response = await _apiClient.dio.post(
      '/ai/parse-task',
      data: {'input_text': inputText},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> classifyCapture(String inputText) async {
    final response = await _apiClient.dio.post(
      '/ai/classify-capture',
      data: {'input_text': inputText},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getNextAction() async {
    final response = await _apiClient.dio.get('/ai/next-action');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getDailyPlan({String? date}) async {
    final response = await _apiClient.dio.post(
      '/ai/daily-plan',
      data: {'date': date},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> generateGoalRoadmap({
    required String goalTitle,
    String? deadline,
    String? currentLevel,
    required int weeklyAvailableHours,
    String? constraints,
  }) async {
    final data = <String, dynamic>{
      'goal_title': goalTitle,
      'weekly_available_hours': weeklyAvailableHours,
    };
    if (deadline != null) data['deadline'] = deadline;
    if (currentLevel != null) data['current_level'] = currentLevel;
    if (constraints != null) data['constraints'] = constraints;
    final response = await _apiClient.dio.post('/ai/goal-roadmap', data: data);
    return response.data as Map<String, dynamic>;
  }
}
