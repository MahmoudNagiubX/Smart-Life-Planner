import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import '../../../core/network/providers.dart';
import '../models/ramadan_fasting_model.dart';
import '../services/ramadan_fasting_service.dart';

final ramadanFastingServiceProvider = Provider<RamadanFastingService>((ref) {
  return RamadanFastingService(ref.watch(apiClientProvider));
});

class RamadanFastingState {
  final RamadanFastingSummary? summary;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const RamadanFastingState({
    this.summary,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  RamadanFastingState copyWith({
    RamadanFastingSummary? summary,
    bool? isLoading,
    bool? isSaving,
    String? error,
  }) {
    return RamadanFastingState(
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
    );
  }
}

class RamadanFastingNotifier extends StateNotifier<RamadanFastingState> {
  final Ref _ref;

  RamadanFastingNotifier(this._ref) : super(const RamadanFastingState());

  Future<void> loadToday() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final summary = await _ref
          .read(ramadanFastingServiceProvider)
          .getTodaySummary();
      state = state.copyWith(summary: summary, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: friendlyApiError(e, 'Failed to load fasting log'),
      );
    }
  }

  Future<void> updateToday({required bool fasted, String? note}) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final summary = await _ref
          .read(ramadanFastingServiceProvider)
          .updateToday(fasted: fasted, note: note);
      state = state.copyWith(summary: summary, isSaving: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: friendlyApiError(e, 'Failed to update fasting log'),
      );
    }
  }
}

final ramadanFastingProvider =
    StateNotifierProvider<RamadanFastingNotifier, RamadanFastingState>((ref) {
      return RamadanFastingNotifier(ref);
    });
