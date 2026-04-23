import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notification_service.dart';
import 'notification_ids.dart';

class NotificationScheduler {
  final NotificationService _service;

  NotificationScheduler(this._service);

  // ── Focus ──────────────────────────────────────────────

  Future<void> scheduleFocusComplete({
    required String sessionId,
    required int plannedMinutes,
  }) async {
    final fireAt = DateTime.now().add(Duration(minutes: plannedMinutes));
    await _service.scheduleNotification(
      id: NotificationIds.focusComplete(sessionId),
      title: '🎯 Focus Session Complete!',
      body: 'Great work! You focused for $plannedMinutes minutes.',
      scheduledAt: fireAt,
      payload: 'focus',
    );
  }

  Future<void> cancelFocusNotification(String sessionId) async {
    await _service.cancelNotification(
      NotificationIds.focusComplete(sessionId),
    );
  }

  // ── Prayer ─────────────────────────────────────────────

  Future<void> schedulePrayerReminder({
    required String prayerName,
    required DateTime scheduledAt,
    int minutesBefore = 10,
  }) async {
    final fireAt = scheduledAt.subtract(Duration(minutes: minutesBefore));
    if (fireAt.isBefore(DateTime.now())) return;

    final displayName = _prayerDisplayName(prayerName);
    await _service.scheduleNotification(
      id: NotificationIds.prayerReminder(prayerName),
      title: '🕌 $displayName Prayer',
      body: '$displayName is in $minutesBefore minutes.',
      scheduledAt: fireAt,
      payload: 'prayer',
    );
  }

  Future<void> cancelPrayerReminder(String prayerName) async {
    await _service.cancelNotification(
      NotificationIds.prayerReminder(prayerName),
    );
  }

  // ── Tasks ──────────────────────────────────────────────

  Future<void> scheduleTaskReminder({
    required String taskId,
    required String taskTitle,
    required DateTime reminderAt,
  }) async {
    if (reminderAt.isBefore(DateTime.now())) return;

    await _service.scheduleNotification(
      id: NotificationIds.taskReminder(taskId),
      title: '✅ Task Reminder',
      body: taskTitle,
      scheduledAt: reminderAt,
      payload: 'task:$taskId',
    );
  }

  Future<void> cancelTaskReminder(String taskId) async {
    await _service.cancelNotification(NotificationIds.taskReminder(taskId));
  }

  // ── Habits ─────────────────────────────────────────────

  Future<void> showHabitReminder({
    required String habitId,
    required String habitTitle,
  }) async {
    await _service.showNotification(
      id: NotificationIds.habitReminder(habitId),
      title: '💪 Habit Reminder',
      body: "Don't forget: $habitTitle",
      payload: 'habit:$habitId',
    );
  }

  String _prayerDisplayName(String name) {
    const names = {
      'fajr': 'Fajr',
      'dhuhr': 'Dhuhr',
      'asr': 'Asr',
      'maghrib': 'Maghrib',
      'isha': 'Isha',
    };
    return names[name] ?? name;
  }
}

final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) {
  return NotificationScheduler(NotificationService());
});