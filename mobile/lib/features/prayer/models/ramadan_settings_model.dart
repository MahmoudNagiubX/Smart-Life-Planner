class RamadanSettings {
  final bool ramadanModeEnabled;
  final bool suhoorReminderEnabled;
  final int suhoorReminderMinutesBeforeFajr;
  final bool iftarReminderEnabled;
  final bool taraweehTrackingEnabled;
  final bool fastingTrackerEnabled;

  const RamadanSettings({
    required this.ramadanModeEnabled,
    required this.suhoorReminderEnabled,
    required this.suhoorReminderMinutesBeforeFajr,
    required this.iftarReminderEnabled,
    required this.taraweehTrackingEnabled,
    required this.fastingTrackerEnabled,
  });

  factory RamadanSettings.fromJson(Map<String, dynamic> json) {
    return RamadanSettings(
      ramadanModeEnabled: json['ramadan_mode_enabled'] as bool? ?? false,
      suhoorReminderEnabled: json['suhoor_reminder_enabled'] as bool? ?? true,
      suhoorReminderMinutesBeforeFajr:
          json['suhoor_reminder_minutes_before_fajr'] as int? ?? 45,
      iftarReminderEnabled: json['iftar_reminder_enabled'] as bool? ?? true,
      taraweehTrackingEnabled:
          json['taraweeh_tracking_enabled'] as bool? ?? false,
      fastingTrackerEnabled: json['fasting_tracker_enabled'] as bool? ?? true,
    );
  }

  RamadanSettings copyWith({
    bool? ramadanModeEnabled,
    bool? suhoorReminderEnabled,
    int? suhoorReminderMinutesBeforeFajr,
    bool? iftarReminderEnabled,
    bool? taraweehTrackingEnabled,
    bool? fastingTrackerEnabled,
  }) {
    return RamadanSettings(
      ramadanModeEnabled: ramadanModeEnabled ?? this.ramadanModeEnabled,
      suhoorReminderEnabled:
          suhoorReminderEnabled ?? this.suhoorReminderEnabled,
      suhoorReminderMinutesBeforeFajr:
          suhoorReminderMinutesBeforeFajr ??
          this.suhoorReminderMinutesBeforeFajr,
      iftarReminderEnabled: iftarReminderEnabled ?? this.iftarReminderEnabled,
      taraweehTrackingEnabled:
          taraweehTrackingEnabled ?? this.taraweehTrackingEnabled,
      fastingTrackerEnabled:
          fastingTrackerEnabled ?? this.fastingTrackerEnabled,
    );
  }
}
