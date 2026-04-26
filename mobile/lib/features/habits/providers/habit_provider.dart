import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_error.dart';
import '../../../core/network/providers.dart';
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
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: friendlyApiError(e, 'Failed to load habits'),
      );
    }
  }

  Future<void> createHabit({
    required String title,
    String? description,
    String frequencyType = 'daily',
    String? category,
  }) async {
    try {
      final service = _ref.read(habitServiceProvider);
      await service.createHabit(
        title: title,
        description: description,
        frequencyType: frequencyType,
        category: category,
      );
      await loadHabits();
    } on DioException catch (e) {
      state = state.copyWith(
        error: friendlyApiError(e, 'Failed to create habit'),
      );
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
    }
  }

  Future<void> deleteHabit(String habitId) async {
    try {
      final service = _ref.read(habitServiceProvider);
      await service.deleteHabit(habitId);
      state = state.copyWith(
        habits: state.habits.where((h) => h.id != habitId).toList(),
      );
    } catch (_) {}
  }
}

final habitsProvider = StateNotifierProvider<HabitsNotifier, HabitsState>((
  ref,
) {
  return HabitsNotifier(ref);
});
