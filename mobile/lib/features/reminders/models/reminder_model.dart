class ReminderModel {
  final String id;
  final String userId;
  final String targetType;
  final String? targetId;
  final String reminderType;
  final String scheduledAt;
  final String? recurrenceRule;
  final String timezone;
  final String status;
  final String? snoozeUntil;
  final String channel;
  final String priority;
  final bool isPersistent;
  final int? persistentIntervalMinutes;
  final int? persistentMaxOccurrences;
  final int persistentOccurrencesSent;
  final String createdAt;
  final String updatedAt;
  final String? cancelledAt;
  final String? dismissedAt;

  ReminderModel({
    required this.id,
    required this.userId,
    required this.targetType,
    this.targetId,
    required this.reminderType,
    required this.scheduledAt,
    this.recurrenceRule,
    required this.timezone,
    required this.status,
    this.snoozeUntil,
    required this.channel,
    required this.priority,
    this.isPersistent = false,
    this.persistentIntervalMinutes,
    this.persistentMaxOccurrences,
    this.persistentOccurrencesSent = 0,
    required this.createdAt,
    required this.updatedAt,
    this.cancelledAt,
    this.dismissedAt,
  });

  factory ReminderModel.fromJson(Map<String, dynamic> json) => ReminderModel(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    targetType: json['target_type'] as String,
    targetId: json['target_id'] as String?,
    reminderType: json['reminder_type'] as String,
    scheduledAt: json['scheduled_at'] as String,
    recurrenceRule: json['recurrence_rule'] as String?,
    timezone: json['timezone'] as String,
    status: json['status'] as String,
    snoozeUntil: json['snooze_until'] as String?,
    channel: json['channel'] as String,
    priority: json['priority'] as String,
    isPersistent: json['is_persistent'] as bool? ?? false,
    persistentIntervalMinutes: json['persistent_interval_minutes'] as int?,
    persistentMaxOccurrences: json['persistent_max_occurrences'] as int?,
    persistentOccurrencesSent: json['persistent_occurrences_sent'] as int? ?? 0,
    createdAt: json['created_at'] as String,
    updatedAt: json['updated_at'] as String,
    cancelledAt: json['cancelled_at'] as String?,
    dismissedAt: json['dismissed_at'] as String?,
  );
}

class ReminderDraft {
  final String targetType;
  final String? targetId;
  final String reminderType;
  final DateTime? scheduledAt;
  final String? recurrenceRule;
  final String timezone;
  final String channel;
  final String priority;
  final bool isPersistent;
  final int? persistentIntervalMinutes;
  final int? persistentMaxOccurrences;

  const ReminderDraft({
    required this.targetType,
    this.targetId,
    required this.reminderType,
    this.scheduledAt,
    this.recurrenceRule,
    this.timezone = 'UTC',
    this.channel = 'local',
    this.priority = 'normal',
    this.isPersistent = false,
    this.persistentIntervalMinutes,
    this.persistentMaxOccurrences,
  });

  ReminderDraft copyWith({
    String? targetType,
    String? targetId,
    String? reminderType,
    DateTime? scheduledAt,
    String? recurrenceRule,
    String? timezone,
    String? channel,
    String? priority,
    bool? isPersistent,
    int? persistentIntervalMinutes,
    int? persistentMaxOccurrences,
    bool clearScheduledAt = false,
    bool clearRecurrenceRule = false,
  }) {
    return ReminderDraft(
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      reminderType: reminderType ?? this.reminderType,
      scheduledAt: clearScheduledAt ? null : scheduledAt ?? this.scheduledAt,
      recurrenceRule: clearRecurrenceRule
          ? null
          : recurrenceRule ?? this.recurrenceRule,
      timezone: timezone ?? this.timezone,
      channel: channel ?? this.channel,
      priority: priority ?? this.priority,
      isPersistent: isPersistent ?? this.isPersistent,
      persistentIntervalMinutes:
          persistentIntervalMinutes ?? this.persistentIntervalMinutes,
      persistentMaxOccurrences:
          persistentMaxOccurrences ?? this.persistentMaxOccurrences,
    );
  }

  Map<String, dynamic> toJson() => {
    'target_type': targetType,
    if (targetId != null) 'target_id': targetId,
    'reminder_type': reminderType,
    if (scheduledAt != null)
      'scheduled_at': scheduledAt!.toUtc().toIso8601String(),
    if (recurrenceRule != null) 'recurrence_rule': recurrenceRule,
    'timezone': timezone,
    'channel': channel,
    'priority': priority,
    'is_persistent': isPersistent,
    if (persistentIntervalMinutes != null)
      'persistent_interval_minutes': persistentIntervalMinutes,
    if (persistentMaxOccurrences != null)
      'persistent_max_occurrences': persistentMaxOccurrences,
  };
}

class TaskReminderPresetDraft {
  final String preset;
  final DateTime? customScheduledAt;
  final String? customRecurrenceRule;
  final String channel;
  final String priority;
  final bool isPersistent;
  final int? persistentIntervalMinutes;
  final int? persistentMaxOccurrences;

  const TaskReminderPresetDraft({
    required this.preset,
    this.customScheduledAt,
    this.customRecurrenceRule,
    this.channel = 'local',
    this.priority = 'normal',
    this.isPersistent = false,
    this.persistentIntervalMinutes,
    this.persistentMaxOccurrences,
  });

  Map<String, dynamic> toJson() => {
    'preset': preset,
    if (customScheduledAt != null)
      'custom_scheduled_at': customScheduledAt!.toUtc().toIso8601String(),
    if (customRecurrenceRule != null)
      'custom_recurrence_rule': customRecurrenceRule,
    'channel': channel,
    'priority': priority,
    'is_persistent': isPersistent,
    if (persistentIntervalMinutes != null)
      'persistent_interval_minutes': persistentIntervalMinutes,
    if (persistentMaxOccurrences != null)
      'persistent_max_occurrences': persistentMaxOccurrences,
  };
}
