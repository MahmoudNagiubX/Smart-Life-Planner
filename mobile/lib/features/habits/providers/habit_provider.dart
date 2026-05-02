import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_error.dart';
import '../../../core/network/providers.dart';
import '../../../core/notifications/notification_scheduler.dart';
import '../../reminders/providers/reminder_preferences_provider.dart';
import '../../reminders/providers/reminder_provider.dart';
import '../models/habit_model.dart';
import '../services/habit_service.dart';

final habitServiceProvider = Provider<HabitService>((ref) {
  return HabitService(ref.watch(apiClientProvider));
});

class HabitsState {
  final List<HabitModel> habits;
  final Set<String> completedTodayIds;
  final bool isLoading;
  final String? error;

  const HabitsState({
    this.habits = const [],
    this.completedTodayIds = const {},
    this.isLoading = false,
    this.error,
  });

  HabitsState copyWith({
    List<HabitModel>? habits,
    Set<String>? completedTodayIds,
    bool? isLoading,
    String? error,
  }) {
    return HabitsState(
      habits: habits ?? this.habits,
      completedTodayIds: completedTodayIds ?? this.completedTodayIds,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class HabitsNotifier extends StateNotifier<HabitsState> {
  final Ref _ref;

  HabitsNotifier(this._ref) : super(const HabitsState());

  Future<void> loadHabits() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final service = _ref.read(habitServiceProvider);
      final habits = await service.getHabits();
      state = state.copyWith(habits: habits, isLoading: false);
      await _syncHabitReminders(habits);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: friendlyApiError(e, 'Failed to load habits'),
      );
    } catch (error) {
      debugPrint('Habit load failed: $error');
      state = state.copyWith(isLoading: false, error: 'Failed to load habits');
    }
  }

  Future<void> createHabit({
    required String title,
    String? description,
    String frequencyType = 'daily',
    Map<String, dynamic>? frequencyConfig,
    String? category,
    String? reminderTime,
  }) async {
    try {
      final service = _ref.read(habitServiceProvider);
      await service.createHabit(
        title: title,
        description: description,
        frequencyType: frequencyType,
        frequencyConfig: frequencyConfig,
        category: category,
        reminderTime: reminderTime,
      );
      await loadHabits();
    } on DioException catch (e) {
      state = state.copyWith(
        error: friendlyApiError(e, 'Failed to create habit'),
      );
    } catch (error) {
      debugPrint('Habit create failed: $error');
      state = state.copyWith(error: 'Failed to create habit');
    }
  }

  Future<void> completeHabit(String habitId) async {
    try {
      final service = _ref.read(habitServiceProvider);
      await service.completeHabit(habitId);
      state = state.copyWith(
        completedTodayIds: {...state.completedTodayIds, habitId},
      );
      await loadHabits();
    } on DioException catch (e) {
      state = state.copyWith(
        error: friendlyApiError(e, 'Failed to complete habit'),
      );
    } catch (error) {
      debugPrint('Habit complete failed: $error');
      state = state.copyWith(error: 'Failed to complete habit');
    }
  }

  Future<void> deleteHabit(String habitId) async {
    try {
      final service = _ref.read(habitServiceProvider);
      await service.deleteHabit(habitId);
      await _ref
          .read(notificationSchedulerProvider)
          .cancelHabitReminders(habitId);
      await _ref
          .read(reminderServiceProvider)
          .dismissTargetReminders(
            targetType: 'habit',
            targetId: habitId,
            reminderType: 'habit',
            recurrenceRule: _habitReminderRule,
          );
      state = state.copyWith(
        habits: state.habits.where((h) => h.id != habitId).toList(),
      );
    } catch (_) {}
  }

  Future<void> archiveHabit(String habitId) async {
    try {
      final service = _ref.read(habitServiceProvider);
      final archived = await service.archiveHabit(habitId);
      await _ref
          .read(notificationSchedulerProvider)
          .cancelHabitReminders(habitId);
      await _ref
          .read(reminderServiceProvider)
          .dismissTargetReminders(
            targetType: 'habit',
            targetId: habitId,
            reminderType: 'habit',
            recurrenceRule: _habitReminderRule,
          );
      state = state.copyWith(
        habits: state.habits
            .map((h) => h.id == habitId ? archived : h)
            .where((h) => h.isActive)
            .toList(),
      );
    } on DioException catch (e) {
      state = state.copyWith(
        error: friendlyApiError(e, 'Failed to archive habit'),
      );
    } catch (error) {
      debugPrint('Habit archive failed: $error');
      state = state.copyWith(error: 'Failed to archive habit');
    }
  }

  Future<void> updateHabitReminder({
    required String habitId,
    String? reminderTime,
    bool clearReminderTime = false,
  }) async {
    try {
      final updated = await _ref
          .read(habitServiceProvider)
          .updateHabit(
            habitId: habitId,
            reminderTime: reminderTime,
            clearReminderTime: clearReminderTime,
          );
      await _syncHabitReminder(updated);
      state = state.copyWith(
        habits: state.habits
            .map((habit) => habit.id == habitId ? updated : habit)
            .toList(),
      );
    } on DioException catch (e) {
      state = state.copyWith(
        error: friendlyApiError(e, 'Failed to update habit reminder'),
      );
    } catch (error) {
      debugPrint('Habit reminder update failed: $error');
      state = state.copyWith(error: 'Failed to update habit reminder');
    }
  }

  Future<void> _syncHabitReminders(List<HabitModel> habits) async {
    for (final habit in habits) {
      try {
        await _syncHabitReminder(habit);
      } catch (error) {
        debugPrint('Habit reminder sync skipped for ${habit.id}: $error');
      }
    }
  }

  Future<void> _syncHabitReminder(HabitModel habit) async {
    final scheduler = _ref.read(notificationSchedulerProvider);
    try {
      if (!habit.isActive || habit.reminderTime == null) {
        await scheduler.cancelHabitReminders(habit.id);
        await _ref
            .read(reminderServiceProvider)
            .dismissTargetReminders(
              targetType: 'habit',
              targetId: habit.id,
              reminderType: 'habit',
              recurrenceRule: _habitReminderRule,
            );
        return;
      }

      final reminderAt = _nextHabitReminderAt(
        habit.reminderTime!,
        forceTomorrow: state.completedTodayIds.contains(habit.id),
      );
      if (reminderAt == null) {
        await scheduler.cancelHabitReminders(habit.id);
        return;
      }

      final reminder = await _ref
          .read(reminderServiceProvider)
          .syncTargetReminder(
            targetType: 'habit',
            targetId: habit.id,
            reminderType: 'habit',
            scheduledAt: reminderAt,
            recurrenceRule: _habitReminderRule,
            timezone: DateTime.now().timeZoneName,
          );
      if (reminder == null ||
          !await _ref
              .read(reminderPreferencesProvider.notifier)
              .canScheduleLocal('habit', scheduledAt: reminderAt)) {
        await scheduler.cancelHabitReminders(habit.id);
        return;
      }
      await scheduler.scheduleHabitReminder(
        habitId: habit.id,
        habitTitle: habit.title,
        reminderAt: reminderAt,
        reminderId: reminder.id,
      );
    } catch (error) {
      debugPrint('Habit reminder sync skipped for ${habit.id}: $error');
      await scheduler.cancelHabitReminders(habit.id);
    }
  }
}

final habitsProvider = StateNotifierProvider<HabitsNotifier, HabitsState>((
  ref,
) {
  return HabitsNotifier(ref);
});

const _habitReminderRule = 'FREQ=DAILY;source=habit_reminder_time';

DateTime? _nextHabitReminderAt(
  String reminderTime, {
  bool forceTomorrow = false,
}) {
  final parts = reminderTime.split(':');
  if (parts.length < 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  final now = DateTime.now();
  var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
  if (forceTomorrow || scheduled.isBefore(now)) {
    scheduled = scheduled.add(const Duration(days: 1));
  }
  return scheduled;
}
