import '../../../core/network/api_client.dart';
import '../models/reminder_model.dart';

class ReminderService {
  final ApiClient _apiClient;

  ReminderService(this._apiClient);

  Future<List<ReminderModel>> getReminders({
    String? targetType,
    String? targetId,
    String? status,
  }) async {
    final params = <String, dynamic>{};
    if (targetType != null) params['target_type'] = targetType;
    if (targetId != null) params['target_id'] = targetId;
    if (status != null) params['status'] = status;

    final response = await _apiClient.dio.get(
      '/reminders',
      queryParameters: params.isEmpty ? null : params,
    );
    return (response.data as List<dynamic>)
        .map((item) => ReminderModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ReminderModel> createReminder(ReminderDraft draft) async {
    final response = await _apiClient.dio.post(
      '/reminders',
      data: draft.toJson(),
    );
    return ReminderModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ReminderModel> snoozeReminder({
    required String reminderId,
    required int minutes,
  }) async {
    final response = await _apiClient.dio.post(
      '/reminders/$reminderId/snooze',
      data: {'minutes': minutes},
    );
    return ReminderModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ReminderModel> rescheduleReminder({
    required String reminderId,
    required DateTime scheduledAt,
  }) async {
    final response = await _apiClient.dio.post(
      '/reminders/$reminderId/reschedule',
      data: {'scheduled_at': scheduledAt.toUtc().toIso8601String()},
    );
    return ReminderModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<ReminderModel>> saveTaskReminderPresets({
    required String taskId,
    required List<TaskReminderPresetDraft> presets,
    String timezone = 'UTC',
  }) async {
    final response = await _apiClient.dio.post(
      '/reminders/task-presets',
      data: {
        'task_id': taskId,
        'timezone': timezone,
        'presets': presets.map((preset) => preset.toJson()).toList(),
      },
    );
    return (response.data as List<dynamic>)
        .map((item) => ReminderModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
