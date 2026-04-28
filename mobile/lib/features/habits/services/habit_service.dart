import '../../../core/network/api_client.dart';
import '../models/habit_model.dart';

class HabitService {
  final ApiClient _apiClient;

  HabitService(this._apiClient);

  Future<List<HabitModel>> getHabits() async {
    final response = await _apiClient.dio.get('/habits');
    return (response.data as List<dynamic>)
        .map((h) => HabitModel.fromJson(h as Map<String, dynamic>))
        .toList();
  }

  Future<HabitModel> createHabit({
    required String title,
    String? description,
    String frequencyType = 'daily',
    Map<String, dynamic>? frequencyConfig,
    String? category,
  }) async {
    final data = <String, dynamic>{
      'title': title,
      'frequency_type': frequencyType,
    };
    if (description != null) data['description'] = description;
    if (frequencyConfig != null) data['frequency_config'] = frequencyConfig;
    if (category != null) data['category'] = category;

    final response = await _apiClient.dio.post('/habits', data: data);
    return HabitModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<HabitLogModel> completeHabit(String habitId) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final response = await _apiClient.dio.post(
      '/habits/$habitId/complete',
      queryParameters: {'log_date': today},
    );
    return HabitLogModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<HabitModel> archiveHabit(String habitId) async {
    final response = await _apiClient.dio.patch(
      '/habits/$habitId',
      data: {'is_active': false},
    );
    return HabitModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteHabit(String habitId) async {
    await _apiClient.dio.delete('/habits/$habitId');
  }
}
