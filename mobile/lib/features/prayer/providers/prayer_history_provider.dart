import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_error.dart';
import '../models/prayer_model.dart';
import 'prayer_provider.dart';

class PrayerHistoryState {
  final PrayerWeeklySummary? summary;
  final bool isLoading;
  final String? error;

  const PrayerHistoryState({
    this.summary,
    this.isLoading = false,
    this.error,
  });

  PrayerHistoryState copyWith({
    PrayerWeeklySummary? summary,
    bool? isLoading,
    String? error,
  }) {
    return PrayerHistoryState(
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class PrayerHistoryNotifier extends StateNotifier<PrayerHistoryState> {
  final Ref _ref;

  PrayerHistoryNotifier(this._ref) : super(const PrayerHistoryState());

  Future<void> loadWeeklySummary() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final service = _ref.read(prayerServiceProvider);
      final summary = await service.getWeeklySummary();
      state = state.copyWith(summary: summary, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: friendlyApiError(e, 'Failed to load prayer history'),
      );
    }
  }
}

final prayerHistoryProvider =
    StateNotifierProvider<PrayerHistoryNotifier, PrayerHistoryState>((ref) {
  return PrayerHistoryNotifier(ref);
});
