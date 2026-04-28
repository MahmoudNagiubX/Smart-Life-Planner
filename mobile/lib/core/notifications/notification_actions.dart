abstract class NotificationActions {
  static const markTaskDone = 'task_mark_done';
  static const snooze10 = 'reminder_snooze_10';
  static const snooze60 = 'reminder_snooze_60';
  static const reschedule = 'reminder_reschedule';
  static const dismiss = 'reminder_dismiss';
  static const openTask = 'task_open';
}

class TaskNotificationPayload {
  final String taskId;
  final String? reminderId;

  const TaskNotificationPayload({required this.taskId, this.reminderId});

  static TaskNotificationPayload? parse(String? payload) {
    if (payload == null || !payload.startsWith('task:')) return null;
    final parts = payload.split(':');
    if (parts.length < 2 || parts[1].isEmpty) return null;
    return TaskNotificationPayload(
      taskId: parts[1],
      reminderId: parts.length >= 4 && parts[2] == 'reminder' ? parts[3] : null,
    );
  }
}
