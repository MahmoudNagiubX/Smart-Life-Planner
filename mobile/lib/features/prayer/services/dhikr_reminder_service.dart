import '../../../core/network/api_client.dart';
import '../models/dhikr_reminder_model.dart';

class DhikrReminderService {
  final ApiClient _apiClient;

  DhikrReminderService(this._apiClient);

  Future<List<DhikrReminderModel>> getReminders() async {
    final response = await _apiClient.dio.get('/dhikr-reminders');
    return (response.data as List<dynamic>)
        .map(
          (item) => DhikrReminderModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<DhikrReminderModel> createReminder(DhikrReminderDraft draft) async {
    final response = await _apiClient.dio.post(
      '/dhikr-reminders',
      data: draft.toJson(),
    );
    return DhikrReminderModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<DhikrReminderModel> updateReminder({
    required String id,
    String? title,
    String? phrase,
    String? scheduleTime,
    String? recurrenceRule,
    String? timezone,
    bool? enabled,
  }) async {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (phrase != null) data['phrase'] = phrase;
    if (scheduleTime != null) data['schedule_time'] = scheduleTime;
    if (recurrenceRule != null) data['recurrence_rule'] = recurrenceRule;
    if (timezone != null) data['timezone'] = timezone;
    if (enabled != null) data['enabled'] = enabled;

    final response = await _apiClient.dio.patch(
      '/dhikr-reminders/$id',
      data: data,
    );
    return DhikrReminderModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<DhikrReminderModel> disableReminder(String id) async {
    final response = await _apiClient.dio.delete('/dhikr-reminders/$id');
    return DhikrReminderModel.fromJson(response.data as Map<String, dynamic>);
  }
}
