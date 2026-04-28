import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/reminders/providers/reminder_provider.dart';
import '../../features/tasks/providers/task_provider.dart';
import '../../routes/app_routes.dart';
import 'notification_actions.dart';
import 'notification_scheduler.dart';

class NotificationActionHandler {
  final WidgetRef ref;
  final GoRouter router;

  const NotificationActionHandler({required this.ref, required this.router});

  Future<void> handle(NotificationResponse response) async {
    final payload = TaskNotificationPayload.parse(response.payload);
    if (payload == null) return;

    try {
      switch (response.actionId) {
        case NotificationActions.markTaskDone:
          await ref.read(tasksProvider.notifier).completeTask(payload.taskId);
          break;
        case NotificationActions.snooze10:
          await _snooze(payload, 10);
          break;
        case NotificationActions.snooze60:
          await _snooze(payload, 60);
          break;
        case NotificationActions.reschedule:
          await _reschedule(payload);
          _openTask(payload.taskId);
          break;
        case NotificationActions.dismiss:
          await _dismiss(payload);
          break;
        case NotificationActions.openTask:
        case '':
          _openTask(payload.taskId);
          break;
        default:
          _openTask(payload.taskId);
      }
    } catch (_) {}
  }

  Future<void> _snooze(TaskNotificationPayload payload, int minutes) async {
    final fireAt = DateTime.now().add(Duration(minutes: minutes));
    if (payload.reminderId != null) {
      final reminder = await ref
          .read(reminderServiceProvider)
          .snoozeReminder(reminderId: payload.reminderId!, minutes: minutes);
      final scheduledAt =
          DateTime.tryParse(reminder.scheduledAt)?.toLocal() ?? fireAt;
      await ref
          .read(notificationSchedulerProvider)
          .scheduleTaskPresetReminder(
            reminderId: reminder.id,
            taskId: payload.taskId,
            taskTitle: 'Task reminder',
            reminderAt: scheduledAt,
          );
      return;
    }
    await ref
        .read(notificationSchedulerProvider)
        .rescheduleTaskReminder(
          taskId: payload.taskId,
          taskTitle: 'Task reminder',
          reminderAt: fireAt,
        );
  }

  Future<void> _reschedule(TaskNotificationPayload payload) async {
    final fireAt = DateTime.now().add(const Duration(hours: 1));
    if (payload.reminderId != null) {
      final reminder = await ref
          .read(reminderServiceProvider)
          .rescheduleReminder(
            reminderId: payload.reminderId!,
            scheduledAt: fireAt,
          );
      final scheduledAt =
          DateTime.tryParse(reminder.scheduledAt)?.toLocal() ?? fireAt;
      await ref
          .read(notificationSchedulerProvider)
          .scheduleTaskPresetReminder(
            reminderId: reminder.id,
            taskId: payload.taskId,
            taskTitle: 'Task reminder',
            reminderAt: scheduledAt,
          );
      return;
    }
    await ref
        .read(notificationSchedulerProvider)
        .rescheduleTaskReminder(
          taskId: payload.taskId,
          taskTitle: 'Task reminder',
          reminderAt: fireAt,
        );
  }

  Future<void> _dismiss(TaskNotificationPayload payload) async {
    if (payload.reminderId == null) return;
    await ref
        .read(reminderServiceProvider)
        .dismissReminder(payload.reminderId!);
    await ref
        .read(notificationSchedulerProvider)
        .cancelPersistentTaskReminderSeries(payload.reminderId!);
    await ref
        .read(notificationSchedulerProvider)
        .cancelTaskPresetReminder(payload.reminderId!);
  }

  void _openTask(String taskId) {
    router.go(AppRoutes.taskDetails.replaceFirst(':taskId', taskId));
  }
}
