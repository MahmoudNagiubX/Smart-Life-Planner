import '../../../core/network/api_client.dart';
import '../models/hasae_model.dart';

class HasaeService {
  final ApiClient _apiClient;

  HasaeService(this._apiClient);

  Future<HasaeNextAction> getNextAction() async {
    final response = await _apiClient.dio.get('/hasae/next-action');
    return HasaeNextAction.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<HasaeOverload> checkOverload() async {
    final response = await _apiClient.dio.get('/hasae/overload');
    return HasaeOverload.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<List<HasaeRankedTask>> getRankedTasks() async {
    final response = await _apiClient.dio.get('/hasae/rank');
    final data = response.data as Map<String, dynamic>;
    return (data['tasks'] as List<dynamic>)
        .map((t) =>
            HasaeRankedTask.fromJson(t as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> triggerReplan(String event) async {
    final response = await _apiClient.dio
        .get('/hasae/replan', queryParameters: {'event': event});
    return response.data as Map<String, dynamic>;
  }

  Future<HasaeDailyPlan> generateDailyPlan({String? date}) async {
    final response = await _apiClient.dio.post(
      '/hasae/daily-plan',
      data: {'date': date}..removeWhere((_, value) => value == null),
    );
    return HasaeDailyPlan.fromJson(response.data as Map<String, dynamic>);
  }

  Future<HasaeDailyPlan> acceptDailyPlan({String? date}) async {
    final response = await _apiClient.dio.post(
      '/hasae/daily-plan/accept',
      data: {'date': date}..removeWhere((_, value) => value == null),
    );
    return HasaeDailyPlan.fromJson(response.data as Map<String, dynamic>);
  }
}
