import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import '../../../core/network/providers.dart';
import '../../../core/notifications/notification_scheduler.dart';
import '../models/dhikr_reminder_model.dart';
import '../services/dhikr_reminder_service.dart';

final dhikrReminderServiceProvider = Provider<DhikrReminderService>((ref) {
  return DhikrReminderService(ref.watch(apiClientProvider));
});

class DhikrReminderState {
  final List<DhikrReminderModel> reminders;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const DhikrReminderState({
    this.reminders = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  DhikrReminderState copyWith({
    List<DhikrReminderModel>? reminders,
    bool? isLoading,
    bool? isSaving,
    String? error,
  }) {
    return DhikrReminderState(
      reminders: reminders ?? this.reminders,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
    );
  }
}

class DhikrReminderNotifier extends StateNotifier<DhikrReminderState> {
  final Ref _ref;

  DhikrReminderNotifier(this._ref) : super(const DhikrReminderState());

  Future<void> loadReminders() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final reminders = await _ref
          .read(dhikrReminderServiceProvider)
          .getReminders();
      state = state.copyWith(reminders: reminders, isLoading: false);
      for (final reminder in reminders.where((item) => item.enabled)) {
        unawaited(_scheduleLocal(reminder));
      }
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: friendlyApiError(e, 'Failed to load dhikr reminders'),
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load dhikr reminders',
      );
    }
  }

  Future<bool> createReminder(DhikrReminderDraft draft) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final reminder = await _ref
          .read(dhikrReminderServiceProvider)
          .createReminder(draft);
      state = state.copyWith(
        reminders: [reminder, ...state.reminders],
        isSaving: false,
      );
      if (reminder.enabled) {
        await _scheduleLocal(reminder);
      }
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: friendlyApiError(e, 'Failed to save dhikr reminder'),
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        error: 'Failed to save dhikr reminder',
      );
      return false;
    }
  }

  Future<bool> updateReminder({
    required DhikrReminderModel reminder,
    required DhikrReminderDraft draft,
  }) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final updated = await _ref
          .read(dhikrReminderServiceProvider)
          .updateReminder(
            id: reminder.id,
            title: draft.title,
            phrase: draft.phrase,
            scheduleTime: draft.scheduleTime,
            recurrenceRule: draft.recurrenceRule,
            timezone: draft.timezone,
            enabled: draft.enabled,
          );
      _replace(updated);
      state = state.copyWith(isSaving: false);
      if (updated.enabled) {
        await _scheduleLocal(updated);
      } else {
        await _ref
            .read(notificationSchedulerProvider)
            .cancelDhikrReminder(updated.id);
      }
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: friendlyApiError(e, 'Failed to update dhikr reminder'),
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        error: 'Failed to update dhikr reminder',
      );
      return false;
    }
  }

  Future<void> setEnabled(DhikrReminderModel reminder, bool enabled) async {
    try {
      final updated = await _ref
          .read(dhikrReminderServiceProvider)
          .updateReminder(id: reminder.id, enabled: enabled);
      _replace(updated);
      if (updated.enabled) {
        await _scheduleLocal(updated);
      } else {
        await _ref
            .read(notificationSchedulerProvider)
            .cancelDhikrReminder(updated.id);
      }
    } on DioException catch (e) {
      state = state.copyWith(
        error: friendlyApiError(e, 'Failed to update dhikr reminder'),
      );
    } catch (_) {
      state = state.copyWith(error: 'Failed to update dhikr reminder');
    }
  }

  Future<void> disableReminder(DhikrReminderModel reminder) async {
    try {
      final disabled = await _ref
          .read(dhikrReminderServiceProvider)
          .disableReminder(reminder.id);
      _replace(disabled);
      await _ref
          .read(notificationSchedulerProvider)
          .cancelDhikrReminder(disabled.id);
    } on DioException catch (e) {
      state = state.copyWith(
        error: friendlyApiError(e, 'Failed to disable dhikr reminder'),
      );
    } catch (_) {
      state = state.copyWith(error: 'Failed to disable dhikr reminder');
    }
  }

  void _replace(DhikrReminderModel updated) {
    state = state.copyWith(
      reminders: [
        for (final reminder in state.reminders)
          if (reminder.id == updated.id) updated else reminder,
      ],
      error: null,
    );
  }

  Future<void> _scheduleLocal(DhikrReminderModel reminder) async {
    final nextAt = _nextLocalOccurrence(reminder.scheduleTime);
    await _ref
        .read(notificationSchedulerProvider)
        .scheduleDhikrReminder(
          dhikrId: reminder.id,
          title: reminder.title,
          phrase: reminder.phrase,
          reminderAt: nextAt,
        );
  }
}

DateTime _nextLocalOccurrence(String scheduleTime) {
  final parts = scheduleTime.split(':');
  final hour = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 8;
  final minute = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
  final now = DateTime.now();
  var next = DateTime(now.year, now.month, now.day, hour, minute);
  if (!next.isAfter(now)) {
    next = next.add(const Duration(days: 1));
  }
  return next;
}

final dhikrReminderProvider =
    StateNotifierProvider<DhikrReminderNotifier, DhikrReminderState>((ref) {
      return DhikrReminderNotifier(ref);
    });
