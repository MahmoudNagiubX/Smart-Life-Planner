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

  Future<ReminderModel> updateReminder({
    required String reminderId,
    DateTime? scheduledAt,
    String? recurrenceRule,
    String? timezone,
    String? status,
    String? channel,
    String? priority,
    bool? isPersistent,
    int? persistentIntervalMinutes,
    int? persistentMaxOccurrences,
  }) async {
    final data = <String, dynamic>{};
    if (scheduledAt != null) {
      data['scheduled_at'] = scheduledAt.toUtc().toIso8601String();
    }
    if (recurrenceRule != null) data['recurrence_rule'] = recurrenceRule;
    if (timezone != null) data['timezone'] = timezone;
    if (status != null) data['status'] = status;
    if (channel != null) data['channel'] = channel;
    if (priority != null) data['priority'] = priority;
    if (isPersistent != null) data['is_persistent'] = isPersistent;
    if (persistentIntervalMinutes != null) {
      data['persistent_interval_minutes'] = persistentIntervalMinutes;
    }
    if (persistentMaxOccurrences != null) {
      data['persistent_max_occurrences'] = persistentMaxOccurrences;
    }

    final response = await _apiClient.dio.patch(
      '/reminders/$reminderId',
      data: data,
    );
    return ReminderModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ReminderModel?> syncTargetReminder({
    required String targetType,
    String? targetId,
    required String reminderType,
    required DateTime? scheduledAt,
    String? recurrenceRule,
    String timezone = 'UTC',
    String channel = 'local',
    String priority = 'normal',
    bool isPersistent = false,
    int? persistentIntervalMinutes,
    int? persistentMaxOccurrences,
  }) async {
    final existing = await _matchingReminders(
      targetType: targetType,
      targetId: targetId,
      reminderType: reminderType,
      recurrenceRule: recurrenceRule,
    );

    if (scheduledAt == null) {
      for (final reminder in existing) {
        await dismissReminder(reminder.id);
      }
      return null;
    }

    if (existing.isEmpty) {
      return createReminder(
        ReminderDraft(
          targetType: targetType,
          targetId: targetId,
          reminderType: reminderType,
          scheduledAt: scheduledAt,
          recurrenceRule: recurrenceRule,
          timezone: timezone,
          channel: channel,
          priority: priority,
          isPersistent: isPersistent,
          persistentIntervalMinutes: persistentIntervalMinutes,
          persistentMaxOccurrences: persistentMaxOccurrences,
        ),
      );
    }

    final primary = existing.first;
    final updated = await updateReminder(
      reminderId: primary.id,
      scheduledAt: scheduledAt,
      recurrenceRule: recurrenceRule,
      timezone: timezone,
      status: 'scheduled',
      channel: channel,
      priority: priority,
      isPersistent: isPersistent,
      persistentIntervalMinutes: persistentIntervalMinutes,
      persistentMaxOccurrences: persistentMaxOccurrences,
    );

    for (final duplicate in existing.skip(1)) {
      await dismissReminder(duplicate.id);
    }
    return updated;
  }

  Future<void> dismissTargetReminders({
    required String targetType,
    String? targetId,
    required String reminderType,
    String? recurrenceRule,
    bool anyRecurrence = false,
  }) async {
    final reminders = await _matchingReminders(
      targetType: targetType,
      targetId: targetId,
      reminderType: reminderType,
      recurrenceRule: recurrenceRule,
      anyRecurrence: anyRecurrence,
    );
    for (final reminder in reminders) {
      await dismissReminder(reminder.id);
    }
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

  Future<ReminderModel> dismissReminder(String reminderId) async {
    final response = await _apiClient.dio.post(
      '/reminders/$reminderId/dismiss',
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

  Future<List<ReminderModel>> _matchingReminders({
    required String targetType,
    String? targetId,
    required String reminderType,
    String? recurrenceRule,
    bool anyRecurrence = false,
  }) async {
    final reminders = await getReminders(
      targetType: targetType,
      targetId: targetId,
    );
    return reminders
        .where((reminder) => _isActive(reminder))
        .where((reminder) => reminder.reminderType == reminderType)
        .where(
          (reminder) =>
              anyRecurrence || reminder.recurrenceRule == recurrenceRule,
        )
        .toList();
  }

  bool _isActive(ReminderModel reminder) {
    return reminder.status != 'cancelled' &&
        reminder.status != 'dismissed' &&
        reminder.cancelledAt == null &&
        reminder.dismissedAt == null;
  }
}
