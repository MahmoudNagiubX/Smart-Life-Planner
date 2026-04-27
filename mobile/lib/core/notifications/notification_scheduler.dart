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
      title: '🎯 Focus Session Complete!',
      body: 'Great work! You focused for $plannedMinutes minutes.',
      scheduledAt: fireAt,
      payload: 'focus',
    );
  }

  Future<void> cancelFocusNotification(String sessionId) async {
    await _service.cancelNotification(NotificationIds.focusComplete(sessionId));
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

  Future<void> cancelAllPrayerReminders() async {
    const prayerNames = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
    for (final prayerName in prayerNames) {
      await cancelPrayerReminder(prayerName);
    }
  }

  // ── Tasks ──────────────────────────────────────────────

  // Ramadan
  Future<void> scheduleRamadanSuhoorReminder({
    required DateTime fajrAt,
    required int minutesBeforeFajr,
  }) async {
    final fireAt = fajrAt.subtract(Duration(minutes: minutesBeforeFajr));
    if (fireAt.isBefore(DateTime.now())) return;

    await _service.scheduleNotification(
      id: NotificationIds.ramadanSuhoor,
      title: 'Suhoor Reminder',
      body: 'Fajr is in $minutesBeforeFajr minutes.',
      scheduledAt: fireAt,
      payload: 'ramadan:suhoor',
    );
  }

  Future<void> scheduleRamadanIftarReminder({
    required DateTime maghribAt,
  }) async {
    if (maghribAt.isBefore(DateTime.now())) return;

    await _service.scheduleNotification(
      id: NotificationIds.ramadanIftar,
      title: 'Iftar Time',
      body: 'Maghrib has started. Iftar time is now.',
      scheduledAt: maghribAt,
      payload: 'ramadan:iftar',
    );
  }

  Future<void> cancelRamadanReminders() async {
    await _service.cancelNotification(NotificationIds.ramadanSuhoor);
    await _service.cancelNotification(NotificationIds.ramadanIftar);
  }

  // Tasks
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

  Future<void> rescheduleTaskReminder({
    required String taskId,
    required String taskTitle,
    required DateTime reminderAt,
  }) async {
    await cancelTaskReminder(taskId);
    await scheduleTaskReminder(
      taskId: taskId,
      taskTitle: taskTitle,
      reminderAt: reminderAt,
    );
  }

  Future<void> cancelTaskReminder(String taskId) async {
    await _service.cancelNotification(NotificationIds.taskReminder(taskId));
  }

  Future<void> cancelTaskReminders(String taskId) async {
    await cancelTaskReminder(taskId);
  }

  Future<void> scheduleNoteReminder({
    required String noteId,
    required String noteTitle,
    required DateTime reminderAt,
  }) async {
    if (reminderAt.isBefore(DateTime.now())) return;

    await _service.scheduleNotification(
      id: NotificationIds.noteReminder(noteId),
      title: 'Note Reminder',
      body: noteTitle,
      scheduledAt: reminderAt,
      payload: 'note:$noteId',
    );
  }

  Future<void> rescheduleNoteReminder({
    required String noteId,
    required String noteTitle,
    required DateTime reminderAt,
  }) async {
    await cancelNoteReminder(noteId);
    await scheduleNoteReminder(
      noteId: noteId,
      noteTitle: noteTitle,
      reminderAt: reminderAt,
    );
  }

  Future<void> cancelNoteReminder(String noteId) async {
    await _service.cancelNotification(NotificationIds.noteReminder(noteId));
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

  Future<void> cancelHabitReminder(String habitId) async {
    await _service.cancelNotification(NotificationIds.habitReminder(habitId));
  }

  Future<void> cancelHabitReminders(String habitId) async {
    await cancelHabitReminder(habitId);
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
