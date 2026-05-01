import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import '../../../core/network/providers.dart';
import '../models/islamic_calendar_model.dart';
import '../services/islamic_calendar_service.dart';

final islamicCalendarServiceProvider = Provider<IslamicCalendarService>((ref) {
  return IslamicCalendarService(ref.watch(apiClientProvider));
});

class IslamicCalendarState {
  final IslamicCalendarModel? calendar;
  final bool isLoading;
  final String? error;

  const IslamicCalendarState({
    this.calendar,
    this.isLoading = false,
    this.error,
  });

  IslamicCalendarState copyWith({
    IslamicCalendarModel? calendar,
    bool? isLoading,
    String? error,
  }) {
    return IslamicCalendarState(
      calendar: calendar ?? this.calendar,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class IslamicCalendarNotifier extends StateNotifier<IslamicCalendarState> {
  final Ref _ref;

  IslamicCalendarNotifier(this._ref) : super(const IslamicCalendarState());

  Future<void> loadCalendar() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final calendar = await _ref
          .read(islamicCalendarServiceProvider)
          .getCalendar();
      state = state.copyWith(calendar: calendar, isLoading: false);
    } on DioException catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: friendlyApiError(error, 'Failed to load Islamic calendar'),
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load Islamic calendar',
      );
    }
  }
}

final islamicCalendarProvider =
    StateNotifierProvider<IslamicCalendarNotifier, IslamicCalendarState>((ref) {
      return IslamicCalendarNotifier(ref);
    });
