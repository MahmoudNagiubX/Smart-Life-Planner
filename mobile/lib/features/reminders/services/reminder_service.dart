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
}
