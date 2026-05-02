import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../models/habit_model.dart';

class HabitService {
  final ApiClient _apiClient;

  HabitService(this._apiClient);

  Future<List<HabitModel>> getHabits() async {
    final response = await _apiClient.dio.get('/habits');
    final data = response.data;
    if (data is! List<dynamic>) {
      debugPrint('Habits response was not a list: ${data.runtimeType}');
      return const [];
    }
    final habits = <HabitModel>[];
    for (final item in data) {
      try {
        final habit = switch (item) {
          Map<String, dynamic>() => HabitModel.fromJson(item),
          Map() => HabitModel.fromJson(Map<String, dynamic>.from(item)),
          _ => null,
        };
        if (habit == null || habit.id.isEmpty) continue;
        habits.add(habit);
      } catch (error) {
        debugPrint('Skipped malformed habit item: $error');
      }
    }
    return habits;
  }

  Future<HabitModel> createHabit({
    required String title,
    String? description,
    String frequencyType = 'daily',
    Map<String, dynamic>? frequencyConfig,
    String? category,
    String? reminderTime,
  }) async {
    final data = <String, dynamic>{
      'title': title,
      'frequency_type': frequencyType,
    };
    if (description != null) data['description'] = description;
    if (frequencyConfig != null) data['frequency_config'] = frequencyConfig;
    if (category != null) data['category'] = category;
    if (reminderTime != null) data['reminder_time'] = reminderTime;

    final response = await _apiClient.dio.post('/habits', data: data);
    return HabitModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<HabitModel> updateHabit({
    required String habitId,
    String? title,
    String? description,
    String? frequencyType,
    Map<String, dynamic>? frequencyConfig,
    String? category,
    String? reminderTime,
    bool clearReminderTime = false,
    bool? isActive,
  }) async {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (description != null) data['description'] = description;
    if (frequencyType != null) data['frequency_type'] = frequencyType;
    if (frequencyConfig != null) data['frequency_config'] = frequencyConfig;
    if (category != null) data['category'] = category;
    if (reminderTime != null || clearReminderTime) {
      data['reminder_time'] = clearReminderTime ? null : reminderTime;
    }
    if (isActive != null) data['is_active'] = isActive;

    final response = await _apiClient.dio.patch('/habits/$habitId', data: data);
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
    return updateHabit(habitId: habitId, isActive: false);
  }

  Future<void> deleteHabit(String habitId) async {
    await _apiClient.dio.delete('/habits/$habitId');
  }
}
