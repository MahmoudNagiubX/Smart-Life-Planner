import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import '../../../core/network/providers.dart';
import '../../../core/notifications/notification_scheduler.dart';
import '../models/reminder_preferences_model.dart';
import '../services/reminder_preferences_service.dart';

final reminderPreferencesServiceProvider = Provider<ReminderPreferencesService>(
  (ref) {
    return ReminderPreferencesService(ref.watch(apiClientProvider));
  },
);

class ReminderPreferencesState {
  final bool notificationsEnabled;
  final ReminderPreferences preferences;
  final bool isLoading;
  final bool isSaving;
  final bool hasLoaded;
  final String? error;

  const ReminderPreferencesState({
    this.notificationsEnabled = true,
    required this.preferences,
    this.isLoading = false,
    this.isSaving = false,
    this.hasLoaded = false,
    this.error,
  });

  factory ReminderPreferencesState.initial() =>
      ReminderPreferencesState(preferences: ReminderPreferences.defaults());

  ReminderPreferencesState copyWith({
    bool? notificationsEnabled,
    ReminderPreferences? preferences,
    bool? isLoading,
    bool? isSaving,
    bool? hasLoaded,
    String? error,
  }) {
    return ReminderPreferencesState(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      preferences: preferences ?? this.preferences,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      error: error,
    );
  }
}

class ReminderPreferencesNotifier
    extends StateNotifier<ReminderPreferencesState> {
  final Ref _ref;

  ReminderPreferencesNotifier(this._ref)
    : super(ReminderPreferencesState.initial());

  Future<void> loadPreferences() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _ref
          .read(reminderPreferencesServiceProvider)
          .getPreferences();
      state = state.copyWith(
        notificationsEnabled: result.notificationsEnabled,
        preferences: result.preferences,
        isLoading: false,
        hasLoaded: true,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: friendlyApiError(e, 'Failed to load reminder preferences'),
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load reminder preferences',
      );
    }
  }

  Future<void> updateNotificationsEnabled(bool value) async {
    await _save(notificationsEnabled: value);
  }

  Future<void> updatePreferences(ReminderPreferences preferences) async {
    await _save(preferences: preferences);
  }

  Future<bool> canScheduleLocal(
    String reminderType, {
    DateTime? scheduledAt,
  }) async {
    if (!state.hasLoaded && !state.isLoading) {
      await loadPreferences();
    }
    if (!state.notificationsEnabled ||
        !state.preferences.channels.local ||
        !state.preferences.types.isEnabled(reminderType)) {
      return false;
    }
    if (scheduledAt != null &&
        _quietHoursApplies(reminderType) &&
        _isInQuietHours(scheduledAt, state.preferences.quietHours)) {
      return false;
    }
    return true;
  }

  Future<void> _save({
    bool? notificationsEnabled,
    ReminderPreferences? preferences,
  }) async {
    final previousNotificationsEnabled = state.notificationsEnabled;
    final previousPreferences = state.preferences;
    state = state.copyWith(isSaving: true, error: null);
    try {
      final result = await _ref
          .read(reminderPreferencesServiceProvider)
          .updatePreferences(
            notificationsEnabled: notificationsEnabled,
            preferences: preferences,
          );
      state = state.copyWith(
        notificationsEnabled: result.notificationsEnabled,
        preferences: result.preferences,
        isSaving: false,
        hasLoaded: true,
      );
      if (_shouldCancelLocalNotifications(
        previousNotificationsEnabled,
        previousPreferences,
        result.notificationsEnabled,
        result.preferences,
      )) {
        await _ref
            .read(notificationSchedulerProvider)
            .cancelAllLocalNotifications();
      }
    } on DioException catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: friendlyApiError(e, 'Failed to save reminder preferences'),
      );
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        error: 'Failed to save reminder preferences',
      );
    }
  }
}

bool _shouldCancelLocalNotifications(
  bool previousNotificationsEnabled,
  ReminderPreferences previous,
  bool nextNotificationsEnabled,
  ReminderPreferences next,
) {
  if (previousNotificationsEnabled && !nextNotificationsEnabled) return true;
  if (previous.channels.local && !next.channels.local) return true;
  if (previous.types.task && !next.types.task) return true;
  if (previous.types.note && !next.types.note) return true;
  if (previous.types.habit && !next.types.habit) return true;
  if (previous.types.prayer && !next.types.prayer) return true;
  if (previous.types.quranGoal && !next.types.quranGoal) return true;
  if (previous.types.constantReminders && !next.types.constantReminders) {
    return true;
  }
  return false;
}

bool _quietHoursApplies(String reminderType) {
  return reminderType != 'prayer' &&
      reminderType != 'quran_goal' &&
      reminderType != 'bedtime';
}

bool _isInQuietHours(DateTime scheduledAt, ReminderQuietHours quietHours) {
  if (!quietHours.enabled) return false;
  final start = _minutesFromMidnight(quietHours.start);
  final end = _minutesFromMidnight(quietHours.end);
  final current = scheduledAt.hour * 60 + scheduledAt.minute;
  if (start == end) return true;
  if (start < end) {
    return current >= start && current < end;
  }
  return current >= start || current < end;
}

int _minutesFromMidnight(String value) {
  final parts = value.split(':');
  if (parts.length != 2) return 0;
  final hour = int.tryParse(parts[0]) ?? 0;
  final minute = int.tryParse(parts[1]) ?? 0;
  return (hour.clamp(0, 23).toInt() * 60) + minute.clamp(0, 59).toInt();
}

final reminderPreferencesProvider =
    StateNotifierProvider<
      ReminderPreferencesNotifier,
      ReminderPreferencesState
    >((ref) {
      return ReminderPreferencesNotifier(ref);
    });
