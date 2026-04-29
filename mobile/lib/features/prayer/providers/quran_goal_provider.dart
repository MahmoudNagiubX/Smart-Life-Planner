import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import '../../../core/network/providers.dart';
import '../models/quran_goal_model.dart';
import '../services/quran_goal_service.dart';

final quranGoalServiceProvider = Provider<QuranGoalService>((ref) {
  return QuranGoalService(ref.watch(apiClientProvider));
});

class QuranGoalState {
  final QuranGoalSummary? summary;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const QuranGoalState({
    this.summary,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  QuranGoalState copyWith({
    QuranGoalSummary? summary,
    bool? isLoading,
    bool? isSaving,
    String? error,
  }) {
    return QuranGoalState(
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
    );
  }
}

class QuranGoalNotifier extends StateNotifier<QuranGoalState> {
  final Ref _ref;

  QuranGoalNotifier(this._ref) : super(const QuranGoalState());

  Future<void> loadSummary() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final service = _ref.read(quranGoalServiceProvider);
      final summary = await service.getSummary();
      state = state.copyWith(summary: summary, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: friendlyApiError(e, 'Failed to load Quran goal'),
      );
    }
  }

  Future<bool> saveGoal(int dailyPageTarget) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final service = _ref.read(quranGoalServiceProvider);
      final summary = await service.saveGoal(dailyPageTarget: dailyPageTarget);
      state = state.copyWith(summary: summary, isSaving: false);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: friendlyApiError(e, 'Failed to save Quran goal'),
      );
      return false;
    }
  }

  Future<bool> updateTodayProgress(int pagesCompleted) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final service = _ref.read(quranGoalServiceProvider);
      final summary = await service.updateTodayProgress(
        pagesCompleted: pagesCompleted,
      );
      state = state.copyWith(summary: summary, isSaving: false);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: friendlyApiError(e, 'Failed to update Quran progress'),
      );
      return false;
    }
  }

  Future<bool> updateProgressForDate(
    String progressDate,
    int pagesCompleted,
  ) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final service = _ref.read(quranGoalServiceProvider);
      final summary = await service.updateProgressForDate(
        progressDate: progressDate,
        pagesCompleted: pagesCompleted,
      );
      state = state.copyWith(summary: summary, isSaving: false);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: friendlyApiError(e, 'Failed to update Quran progress'),
      );
      return false;
    }
  }
}

final quranGoalProvider =
    StateNotifierProvider<QuranGoalNotifier, QuranGoalState>((ref) {
      return QuranGoalNotifier(ref);
    });
