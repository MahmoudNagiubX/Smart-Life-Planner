// Stable unique IDs for each notification type
class NotificationIds {
  // Focus: base 1000
  static int focusComplete(String sessionId) =>
      1000 + sessionId.hashCode.abs() % 8000;

  // Tasks: base 10000
  static int taskReminder(String taskId) =>
      10000 + taskId.hashCode.abs() % 10000;

  // Prayer: base 20000
  static int prayerReminder(String prayerName) {
    const names = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
    final index = names.indexOf(prayerName);
    return 20000 + (index >= 0 ? index : 0);
  }

  // Habits: base 30000
  static int habitReminder(String habitId) =>
      30000 + habitId.hashCode.abs() % 10000;
}