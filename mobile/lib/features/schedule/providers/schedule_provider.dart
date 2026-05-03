import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import '../../../core/network/providers.dart';
import '../models/schedule_model.dart';
import '../services/schedule_service.dart';

final scheduleServiceProvider = Provider<ScheduleService>((ref) {
  return ScheduleService(ref.watch(apiClientProvider));
});

class ScheduleState {
  final DailyScheduleModel? schedule;
  final bool isLoading;
  final String? error;

  const ScheduleState({this.schedule, this.isLoading = false, this.error});

  ScheduleState copyWith({
    DailyScheduleModel? schedule,
    bool? isLoading,
    String? error,
    bool clearSchedule = false,
  }) {
    return ScheduleState(
      schedule: clearSchedule ? null : schedule ?? this.schedule,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ScheduleNotifier extends StateNotifier<ScheduleState> {
  final Ref _ref;

  ScheduleNotifier(this._ref) : super(const ScheduleState());

  Future<void> loadSchedule({String? date}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final schedule = await _ref
          .read(scheduleServiceProvider)
          .getSchedule(date: date);
      state = state.copyWith(schedule: schedule, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        clearSchedule: true,
        error: friendlyApiError(e, 'Failed to load schedule'),
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        clearSchedule: true,
        error: 'Failed to read schedule',
      );
    }
  }
}

final scheduleProvider =
    StateNotifierProvider<ScheduleNotifier, ScheduleState>((ref) {
  return ScheduleNotifier(ref);
});
