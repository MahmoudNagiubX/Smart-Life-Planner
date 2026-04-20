import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/providers.dart';
import '../models/prayer_model.dart';
import '../services/prayer_service.dart';

final prayerServiceProvider = Provider<PrayerService>((ref) {
  return PrayerService(ref.watch(apiClientProvider));
});

class PrayerState {
  final DailyPrayers? data;
  final bool isLoading;
  final String? error;

  const PrayerState({
    this.data,
    this.isLoading = false,
    this.error,
  });

  PrayerState copyWith({
    DailyPrayers? data,
    bool? isLoading,
    String? error,
  }) {
    return PrayerState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class PrayerNotifier extends StateNotifier<PrayerState> {
  final Ref _ref;

  PrayerNotifier(this._ref) : super(const PrayerState());

  Future<void> loadTodayPrayers() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final service = _ref.read(prayerServiceProvider);
      final data = await service.getTodayPrayers();
      state = state.copyWith(data: data, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data['detail'] as String? ?? 'Failed to load prayers',
      );
    }
  }

  Future<void> togglePrayer(String prayerName, bool currentlyCompleted) async {
    final data = state.data;
    if (data == null) return;

    try {
      final service = _ref.read(prayerServiceProvider);
      if (currentlyCompleted) {
        await service.uncompletePrayer(prayerName, data.date);
      } else {
        await service.completePrayer(prayerName, data.date);
      }
      await loadTodayPrayers();
    } on DioException catch (e) {
      state = state.copyWith(
        error: e.response?.data['detail'] as String? ?? 'Failed to update prayer',
      );
    }
  }
}

final prayerProvider = StateNotifierProvider<PrayerNotifier, PrayerState>((ref) {
  return PrayerNotifier(ref);
});