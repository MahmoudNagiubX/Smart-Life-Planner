class RamadanSettings {
  final bool ramadanModeEnabled;
  final bool suhoorReminderEnabled;
  final int suhoorReminderMinutesBeforeFajr;

  const RamadanSettings({
    required this.ramadanModeEnabled,
    required this.suhoorReminderEnabled,
    required this.suhoorReminderMinutesBeforeFajr,
  });

  factory RamadanSettings.fromJson(Map<String, dynamic> json) {
    return RamadanSettings(
      ramadanModeEnabled: json['ramadan_mode_enabled'] as bool? ?? false,
      suhoorReminderEnabled: json['suhoor_reminder_enabled'] as bool? ?? true,
      suhoorReminderMinutesBeforeFajr:
          json['suhoor_reminder_minutes_before_fajr'] as int? ?? 45,
    );
  }

  RamadanSettings copyWith({
    bool? ramadanModeEnabled,
    bool? suhoorReminderEnabled,
    int? suhoorReminderMinutesBeforeFajr,
  }) {
    return RamadanSettings(
      ramadanModeEnabled: ramadanModeEnabled ?? this.ramadanModeEnabled,
      suhoorReminderEnabled:
          suhoorReminderEnabled ?? this.suhoorReminderEnabled,
      suhoorReminderMinutesBeforeFajr:
          suhoorReminderMinutesBeforeFajr ??
          this.suhoorReminderMinutesBeforeFajr,
    );
  }
}
