import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_error.dart';
import '../../../core/network/providers.dart';
import '../../../core/notifications/notification_scheduler.dart';
import '../models/prayer_model.dart';
import 'ramadan_settings_provider.dart';
import '../services/prayer_service.dart';

final prayerServiceProvider = Provider<PrayerService>((ref) {
  return PrayerService(ref.watch(apiClientProvider));
});

class PrayerState {
  final DailyPrayers? data;
  final bool isLoading;
  final String? error;

  const PrayerState({this.data, this.isLoading = false, this.error});

  PrayerState copyWith({DailyPrayers? data, bool? isLoading, String? error}) {
    return PrayerState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class PrayerNotifier extends StateNotifier<PrayerState> {
  final Ref _ref;

  PrayerNotifier(this._ref) : super(const PrayerState());

  Future<void> loadTodayPrayers() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final service = _ref.read(prayerServiceProvider);
      final data = await service.getTodayPrayers();
      state = state.copyWith(data: data, isLoading: false);

      await _ref.read(notificationSchedulerProvider).cancelAllPrayerReminders();
      await _schedulePrayerReminders(data);
      await _ref
          .read(ramadanSettingsProvider.notifier)
          .syncRemindersForPrayers(data.prayers);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: friendlyApiError(e, 'Failed to load prayers'),
      );
    }
  }

  Future<void> _schedulePrayerReminders(DailyPrayers data) async {
    final scheduler = _ref.read(notificationSchedulerProvider);
    for (final prayer in data.prayers) {
      if (!prayer.completed && prayer.scheduledAt != null) {
        try {
          final scheduledAt = DateTime.parse(prayer.scheduledAt!);
          await scheduler.schedulePrayerReminder(
            prayerName: prayer.prayerName,
            scheduledAt: scheduledAt,
          );
        } catch (_) {}
      } else {
        // Cancel reminder if already completed
        await scheduler.cancelPrayerReminder(prayer.prayerName);
      }
    }
  }

  Future<void> refreshPrayerRemindersAfterSettingsChange() async {
    await _ref.read(notificationSchedulerProvider).cancelAllPrayerReminders();
    await loadTodayPrayers();
  }

  Future<void> togglePrayer(String prayerName, bool currentlyCompleted) async {
    final data = state.data;
    if (data == null) return;
    try {
      final service = _ref.read(prayerServiceProvider);
      if (currentlyCompleted) {
        await service.uncompletePrayer(prayerName, data.date);
      } else {
        await service.completePrayer(prayerName, data.date);
        // Cancel reminder since prayer is now done
        await _ref
            .read(notificationSchedulerProvider)
            .cancelPrayerReminder(prayerName);
      }
      await loadTodayPrayers();
    } on DioException catch (e) {
      state = state.copyWith(
        error: friendlyApiError(e, 'Failed to update prayer'),
      );
    }
  }
}

final prayerProvider = StateNotifierProvider<PrayerNotifier, PrayerState>((
  ref,
) {
  return PrayerNotifier(ref);
});
