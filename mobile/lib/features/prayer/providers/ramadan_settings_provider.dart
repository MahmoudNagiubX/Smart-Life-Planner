import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import '../../../core/network/providers.dart';
import '../../../core/notifications/notification_scheduler.dart';
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
  }) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final service = _ref.read(ramadanSettingsServiceProvider);
      final settings = await service.updateSettings(
        ramadanModeEnabled: ramadanModeEnabled,
        suhoorReminderEnabled: suhoorReminderEnabled,
        suhoorReminderMinutesBeforeFajr: suhoorReminderMinutesBeforeFajr,
      );
      state = state.copyWith(settings: settings, isSaving: false);
      if (!settings.ramadanModeEnabled) {
        await _ref.read(notificationSchedulerProvider).cancelRamadanReminders();
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
      if (!settings.ramadanModeEnabled) return;

      final fajr = _prayerTime(prayers, 'fajr');
      final maghrib = _prayerTime(prayers, 'maghrib');

      if (settings.suhoorReminderEnabled && fajr != null) {
        await scheduler.scheduleRamadanSuhoorReminder(
          fajrAt: fajr,
          minutesBeforeFajr: settings.suhoorReminderMinutesBeforeFajr,
        );
      }
      if (maghrib != null) {
        await scheduler.scheduleRamadanIftarReminder(maghribAt: maghrib);
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
}

final ramadanSettingsProvider =
    StateNotifierProvider<RamadanSettingsNotifier, RamadanSettingsState>((ref) {
      return RamadanSettingsNotifier(ref);
    });
