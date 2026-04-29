import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'notification_ids.dart';
import 'notification_service.dart';

class NotificationScheduler {
  final NotificationService _service;

  NotificationScheduler(this._service);

  Future<void> scheduleFocusComplete({
    required String sessionId,
    required int plannedMinutes,
  }) async {
    final fireAt = DateTime.now().add(Duration(minutes: plannedMinutes));
    await scheduleFocusCompleteAt(
      sessionId: sessionId,
      plannedMinutes: plannedMinutes,
      fireAt: fireAt,
    );
  }

  Future<void> scheduleFocusCompleteAt({
    required String sessionId,
    required int plannedMinutes,
    required DateTime fireAt,
  }) async {
    await _service.scheduleNotification(
      id: NotificationIds.focusComplete(sessionId),
      title: 'Focus Session Complete',
      body: 'Great work! You focused for $plannedMinutes minutes.',
      scheduledAt: fireAt,
      payload: 'focus',
    );
  }

  Future<void> cancelFocusNotification(String sessionId) async {
    await _service.cancelNotification(NotificationIds.focusComplete(sessionId));
  }

  Future<void> schedulePrayerReminder({
    required String prayerName,
    required DateTime scheduledAt,
    int minutesBefore = 10,
    String? reminderId,
    String notificationSoundKey = 'default',
  }) async {
    final fireAt = scheduledAt.subtract(Duration(minutes: minutesBefore));
    if (fireAt.isBefore(DateTime.now())) return;

    final displayName = _prayerDisplayName(prayerName);
    await _service.scheduleNotification(
      id: NotificationIds.prayerReminder(prayerName),
      title: '$displayName Prayer',
      body: '$displayName is in $minutesBefore minutes.',
      scheduledAt: fireAt,
      payload: reminderId == null
          ? 'prayer:$prayerName'
          : 'prayer:$prayerName:reminder:$reminderId',
      notificationSoundKey: notificationSoundKey,
    );
  }

  Future<void> cancelPrayerReminder(String prayerName) async {
    await _service.cancelNotification(
      NotificationIds.prayerReminder(prayerName),
    );
  }

  Future<void> cancelAllPrayerReminders() async {
    const prayerNames = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
    for (final prayerName in prayerNames) {
      await cancelPrayerReminder(prayerName);
    }
  }

  Future<void> scheduleRamadanSuhoorReminder({
    required DateTime fajrAt,
    required int minutesBeforeFajr,
    String? reminderId,
  }) async {
    final fireAt = fajrAt.subtract(Duration(minutes: minutesBeforeFajr));
    if (fireAt.isBefore(DateTime.now())) return;

    await _service.scheduleNotification(
      id: NotificationIds.ramadanSuhoor,
      title: 'Suhoor Reminder',
      body: 'Fajr is in $minutesBeforeFajr minutes.',
      scheduledAt: fireAt,
      payload: reminderId == null
          ? 'ramadan:suhoor'
          : 'ramadan:suhoor:reminder:$reminderId',
    );
  }

  Future<void> scheduleRamadanIftarReminder({
    required DateTime maghribAt,
    String? reminderId,
  }) async {
    if (maghribAt.isBefore(DateTime.now())) return;

    await _service.scheduleNotification(
      id: NotificationIds.ramadanIftar,
      title: 'Iftar Time',
      body: 'Maghrib has started. Iftar time is now.',
      scheduledAt: maghribAt,
      payload: reminderId == null
          ? 'ramadan:iftar'
          : 'ramadan:iftar:reminder:$reminderId',
    );
  }

  Future<void> cancelRamadanReminders() async {
    await _service.cancelNotification(NotificationIds.ramadanSuhoor);
    await _service.cancelNotification(NotificationIds.ramadanIftar);
  }

  Future<void> scheduleTaskReminder({
    required String taskId,
    required String taskTitle,
    required DateTime reminderAt,
    String? reminderId,
  }) async {
    if (reminderAt.isBefore(DateTime.now())) return;

    await _service.scheduleNotification(
      id: NotificationIds.taskReminder(taskId),
      title: 'Task Reminder',
      body: taskTitle,
      scheduledAt: reminderAt,
      payload: reminderId == null
          ? 'task:$taskId'
          : 'task:$taskId:reminder:$reminderId',
      actions: NotificationService.taskReminderActions,
    );
  }

  Future<void> rescheduleTaskReminder({
    required String taskId,
    required String taskTitle,
    required DateTime reminderAt,
    String? reminderId,
  }) async {
    await cancelTaskReminder(taskId);
    await scheduleTaskReminder(
      taskId: taskId,
      taskTitle: taskTitle,
      reminderAt: reminderAt,
      reminderId: reminderId,
    );
  }

  Future<void> cancelTaskReminder(String taskId) async {
    await _service.cancelNotification(NotificationIds.taskReminder(taskId));
  }

  Future<void> cancelTaskReminders(String taskId) async {
    await cancelTaskReminder(taskId);
  }

  Future<void> scheduleTaskPresetReminder({
    required String reminderId,
    required String taskId,
    required String taskTitle,
    required DateTime reminderAt,
  }) async {
    if (reminderAt.isBefore(DateTime.now())) return;

    await _service.scheduleNotification(
      id: NotificationIds.taskPresetReminder(reminderId),
      title: 'Task Reminder',
      body: taskTitle,
      scheduledAt: reminderAt,
      payload: 'task:$taskId:reminder:$reminderId',
      actions: NotificationService.taskReminderActions,
    );
  }

  Future<void> cancelTaskPresetReminder(String reminderId) async {
    await _service.cancelNotification(
      NotificationIds.taskPresetReminder(reminderId),
    );
  }

  Future<void> schedulePersistentTaskReminderSeries({
    required String reminderId,
    required String taskId,
    required String taskTitle,
    required DateTime firstReminderAt,
    required int intervalMinutes,
    required int maxOccurrences,
  }) async {
    final safeInterval = intervalMinutes.clamp(30, 240);
    final safeMax = maxOccurrences.clamp(2, 6);
    for (var index = 0; index < safeMax; index++) {
      final fireAt = firstReminderAt.add(
        Duration(minutes: safeInterval * index),
      );
      if (fireAt.isBefore(DateTime.now())) continue;
      await _service.scheduleNotification(
        id: NotificationIds.taskPersistentReminder(reminderId, index),
        title: 'Task Reminder',
        body: taskTitle,
        scheduledAt: fireAt,
        payload: 'task:$taskId:reminder:$reminderId',
        actions: NotificationService.taskReminderActions,
      );
    }
  }

  Future<void> cancelPersistentTaskReminderSeries(String reminderId) async {
    for (var index = 0; index < 6; index++) {
      await _service.cancelNotification(
        NotificationIds.taskPersistentReminder(reminderId, index),
      );
    }
  }

  Future<void> scheduleNoteReminder({
    required String noteId,
    required String noteTitle,
    required DateTime reminderAt,
    String? reminderId,
  }) async {
    if (reminderAt.isBefore(DateTime.now())) return;

    await _service.scheduleNotification(
      id: NotificationIds.noteReminder(noteId),
      title: 'Note Reminder',
      body: noteTitle,
      scheduledAt: reminderAt,
      payload: reminderId == null
          ? 'note:$noteId'
          : 'note:$noteId:reminder:$reminderId',
    );
  }

  Future<void> rescheduleNoteReminder({
    required String noteId,
    required String noteTitle,
    required DateTime reminderAt,
    String? reminderId,
  }) async {
    await cancelNoteReminder(noteId);
    await scheduleNoteReminder(
      noteId: noteId,
      noteTitle: noteTitle,
      reminderAt: reminderAt,
      reminderId: reminderId,
    );
  }

  Future<void> cancelNoteReminder(String noteId) async {
    await _service.cancelNotification(NotificationIds.noteReminder(noteId));
  }

  Future<void> scheduleHabitReminder({
    required String habitId,
    required String habitTitle,
    required DateTime reminderAt,
    String? reminderId,
  }) async {
    if (reminderAt.isBefore(DateTime.now())) return;

    await _service.scheduleNotification(
      id: NotificationIds.habitReminder(habitId),
      title: 'Habit Reminder',
      body: "Don't forget: $habitTitle",
      scheduledAt: reminderAt,
      payload: reminderId == null
          ? 'habit:$habitId'
          : 'habit:$habitId:reminder:$reminderId',
    );
  }

  Future<void> showHabitReminder({
    required String habitId,
    required String habitTitle,
  }) async {
    await _service.showNotification(
      id: NotificationIds.habitReminder(habitId),
      title: 'Habit Reminder',
      body: "Don't forget: $habitTitle",
      payload: 'habit:$habitId',
    );
  }

  Future<void> cancelHabitReminder(String habitId) async {
    await _service.cancelNotification(NotificationIds.habitReminder(habitId));
  }

  Future<void> cancelHabitReminders(String habitId) async {
    await cancelHabitReminder(habitId);
  }

  Future<void> cancelAllLocalNotifications() async {
    await _service.cancelAll();
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
