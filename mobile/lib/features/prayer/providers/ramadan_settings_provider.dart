import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import '../../../core/network/providers.dart';
import '../../../core/notifications/notification_scheduler.dart';
import '../../reminders/providers/reminder_preferences_provider.dart';
import '../../reminders/providers/reminder_provider.dart';
import '../models/prayer_model.dart';
import '../models/ramadan_settings_model.dart';
import '../services/ramadan_settings_service.dart';

final ramadanSettingsServiceProvider = Provider<RamadanSettingsService>((ref) {
  return RamadanSettingsService(ref.watch(apiClientProvider));
});

class RamadanSettingsState {
  final RamadanSettings? settings;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const RamadanSettingsState({
    this.settings,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  RamadanSettingsState copyWith({
    RamadanSettings? settings,
    bool? isLoading,
    bool? isSaving,
    String? error,
  }) {
    return RamadanSettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
    );
  }
}

class RamadanSettingsNotifier extends StateNotifier<RamadanSettingsState> {
  final Ref _ref;

  RamadanSettingsNotifier(this._ref) : super(const RamadanSettingsState());

  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final service = _ref.read(ramadanSettingsServiceProvider);
      final settings = await service.getSettings();
      state = state.copyWith(settings: settings, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: friendlyApiError(e, 'Failed to load Ramadan settings'),
      );
    }
  }

  Future<void> updateSettings({
    bool? ramadanModeEnabled,
    bool? suhoorReminderEnabled,
    int? suhoorReminderMinutesBeforeFajr,
    bool? iftarReminderEnabled,
    bool? taraweehTrackingEnabled,
    bool? fastingTrackerEnabled,
  }) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final service = _ref.read(ramadanSettingsServiceProvider);
      final settings = await service.updateSettings(
        ramadanModeEnabled: ramadanModeEnabled,
        suhoorReminderEnabled: suhoorReminderEnabled,
        suhoorReminderMinutesBeforeFajr: suhoorReminderMinutesBeforeFajr,
        iftarReminderEnabled: iftarReminderEnabled,
        taraweehTrackingEnabled: taraweehTrackingEnabled,
        fastingTrackerEnabled: fastingTrackerEnabled,
      );
      state = state.copyWith(settings: settings, isSaving: false);
      if (!settings.ramadanModeEnabled) {
        await _ref.read(notificationSchedulerProvider).cancelRamadanReminders();
        await _dismissRamadanReminders();
      }
    } on DioException catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: friendlyApiError(e, 'Failed to update Ramadan settings'),
      );
    }
  }

  Future<void> syncRemindersForPrayers(List<PrayerTime> prayers) async {
    try {
      final settings = state.settings ?? await _loadSettingsForSync();
      final scheduler = _ref.read(notificationSchedulerProvider);

      await scheduler.cancelRamadanReminders();
      if (!settings.ramadanModeEnabled) {
        await _dismissRamadanReminders();
        return;
      }

      final fajr = _prayerTime(prayers, 'fajr');
      final maghrib = _prayerTime(prayers, 'maghrib');
      final canScheduleLocal = await _ref
          .read(reminderPreferencesProvider.notifier)
          .canScheduleLocal('prayer');

      if (settings.suhoorReminderEnabled && fajr != null) {
        final fireAt = fajr.subtract(
          Duration(minutes: settings.suhoorReminderMinutesBeforeFajr),
        );
        final reminder = await _ref
            .read(reminderServiceProvider)
            .syncTargetReminder(
              targetType: 'ramadan',
              reminderType: 'ramadan',
              scheduledAt: fireAt,
              recurrenceRule: _ramadanRule('suhoor', fajr),
              timezone: DateTime.now().timeZoneName,
            );
        if (canScheduleLocal) {
          await scheduler.scheduleRamadanSuhoorReminder(
            fajrAt: fajr,
            minutesBeforeFajr: settings.suhoorReminderMinutesBeforeFajr,
            reminderId: reminder?.id,
          );
        }
      } else {
        await _dismissRamadanReminder('suhoor', fajr ?? DateTime.now());
      }
      if (settings.iftarReminderEnabled && maghrib != null) {
        final reminder = await _ref
            .read(reminderServiceProvider)
            .syncTargetReminder(
              targetType: 'ramadan',
              reminderType: 'ramadan',
              scheduledAt: maghrib,
              recurrenceRule: _ramadanRule('iftar', maghrib),
              timezone: DateTime.now().timeZoneName,
            );
        if (canScheduleLocal) {
          await scheduler.scheduleRamadanIftarReminder(
            maghribAt: maghrib,
            reminderId: reminder?.id,
          );
        }
      } else {
        await _dismissRamadanReminder('iftar', maghrib ?? DateTime.now());
      }
    } on DioException catch (e) {
      state = state.copyWith(
        error: friendlyApiError(e, 'Failed to sync Ramadan reminders'),
      );
    } catch (_) {
      state = state.copyWith(error: 'Failed to sync Ramadan reminders');
    }
  }

  Future<RamadanSettings> _loadSettingsForSync() async {
    final service = _ref.read(ramadanSettingsServiceProvider);
    final settings = await service.getSettings();
    state = state.copyWith(settings: settings);
    return settings;
  }

  DateTime? _prayerTime(List<PrayerTime> prayers, String prayerName) {
    for (final prayer in prayers) {
      if (prayer.prayerName == prayerName && prayer.scheduledAt != null) {
        return DateTime.tryParse(prayer.scheduledAt!)?.toLocal();
      }
    }
    return null;
  }

  Future<void> _dismissRamadanReminders() async {
    await _ref
        .read(reminderServiceProvider)
        .dismissTargetReminders(
          targetType: 'ramadan',
          reminderType: 'ramadan',
          anyRecurrence: true,
        );
  }

  Future<void> _dismissRamadanReminder(String type, DateTime date) async {
    await _ref
        .read(reminderServiceProvider)
        .dismissTargetReminders(
          targetType: 'ramadan',
          reminderType: 'ramadan',
          recurrenceRule: _ramadanRule(type, date),
        );
  }
}

final ramadanSettingsProvider =
    StateNotifierProvider<RamadanSettingsNotifier, RamadanSettingsState>((ref) {
      return RamadanSettingsNotifier(ref);
    });

String _ramadanRule(String type, DateTime date) {
  final day =
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  return 'ramadan:$type:$day';
}
