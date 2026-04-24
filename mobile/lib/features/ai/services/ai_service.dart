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
}