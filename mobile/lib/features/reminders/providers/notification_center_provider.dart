import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import '../models/reminder_model.dart';
import 'reminder_provider.dart';

class NotificationCenterState {
  final List<ReminderModel> reminders;
  final bool isLoading;
  final bool isClearing;
  final String? error;

  const NotificationCenterState({
    this.reminders = const [],
    this.isLoading = false,
    this.isClearing = false,
    this.error,
  });

  NotificationCenterState copyWith({
    List<ReminderModel>? reminders,
    bool? isLoading,
    bool? isClearing,
    String? error,
  }) {
    return NotificationCenterState(
      reminders: reminders ?? this.reminders,
      isLoading: isLoading ?? this.isLoading,
      isClearing: isClearing ?? this.isClearing,
      error: error,
    );
  }

  List<ReminderModel> get recent {
    final items = reminders.where((reminder) => !_isCleared(reminder)).toList()
      ..sort(_newestFirst);
    return items.take(40).toList();
  }

  List<ReminderModel> get missed {
    final now = DateTime.now();
    return reminders.where((reminder) {
      final scheduledAt = DateTime.tryParse(reminder.scheduledAt)?.toLocal();
      return scheduledAt != null &&
          scheduledAt.isBefore(now) &&
          !_isCleared(reminder);
    }).toList()..sort(_newestFirst);
  }

  List<ReminderModel> get cleared {
    return reminders.where(_isCleared).toList()..sort(_newestFirst);
  }

  List<ReminderModel> get clearableOld {
    final now = DateTime.now();
    return reminders.where((reminder) {
      final scheduledAt = DateTime.tryParse(reminder.scheduledAt)?.toLocal();
      return !_isCleared(reminder) &&
          (scheduledAt == null ||
              scheduledAt.isBefore(now) ||
              reminder.status == 'sent' ||
              reminder.status == 'failed');
    }).toList();
  }
}

class NotificationCenterNotifier
    extends StateNotifier<NotificationCenterState> {
  final Ref _ref;

  NotificationCenterNotifier(this._ref)
    : super(const NotificationCenterState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final reminders = await _ref.read(reminderServiceProvider).getReminders();
      state = state.copyWith(reminders: reminders, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: friendlyApiError(e, 'Failed to load notification center'),
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load notification center',
      );
    }
  }

  Future<void> clearReminder(String reminderId) async {
    state = state.copyWith(isClearing: true, error: null);
    try {
      await _ref.read(reminderServiceProvider).dismissReminder(reminderId);
      await load();
      state = state.copyWith(isClearing: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isClearing: false,
        error: friendlyApiError(e, 'Failed to clear notification'),
      );
    } catch (_) {
      state = state.copyWith(
        isClearing: false,
        error: 'Failed to clear notification',
      );
    }
  }

  Future<void> clearOld() async {
    final clearable = state.clearableOld;
    if (clearable.isEmpty) return;

    state = state.copyWith(isClearing: true, error: null);
    try {
      final service = _ref.read(reminderServiceProvider);
      for (final reminder in clearable) {
        await service.dismissReminder(reminder.id);
      }
      await load();
      state = state.copyWith(isClearing: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isClearing: false,
        error: friendlyApiError(e, 'Failed to clear old notifications'),
      );
    } catch (_) {
      state = state.copyWith(
        isClearing: false,
        error: 'Failed to clear old notifications',
      );
    }
  }
}

final notificationCenterProvider =
    StateNotifierProvider<NotificationCenterNotifier, NotificationCenterState>(
      (ref) => NotificationCenterNotifier(ref),
    );

bool _isCleared(ReminderModel reminder) {
  return reminder.status == 'cancelled' ||
      reminder.status == 'dismissed' ||
      reminder.cancelledAt != null ||
      reminder.dismissedAt != null;
}

int _newestFirst(ReminderModel left, ReminderModel right) {
  return right.scheduledAt.compareTo(left.scheduledAt);
}
