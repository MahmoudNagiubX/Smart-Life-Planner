import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_error.dart';
import '../../../core/network/providers.dart';
import '../models/analytics_model.dart';
import '../services/analytics_service.dart';

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService(ref.watch(apiClientProvider));
});

class AnalyticsState {
  final TodayAnalytics? today;
  final WeeklyAnalytics? weekly;
  final List<AnalyticsInsight> insights;
  final bool isLoading;
  final String? error;

  const AnalyticsState({
    this.today,
    this.weekly,
    this.insights = const [],
    this.isLoading = false,
    this.error,
  });

  AnalyticsState copyWith({
    TodayAnalytics? today,
    WeeklyAnalytics? weekly,
    List<AnalyticsInsight>? insights,
    bool? isLoading,
    String? error,
  }) {
    return AnalyticsState(
      today: today ?? this.today,
      weekly: weekly ?? this.weekly,
      insights: insights ?? this.insights,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  final Ref _ref;

  AnalyticsNotifier(this._ref) : super(const AnalyticsState());

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final service = _ref.read(analyticsServiceProvider);
      final results = await Future.wait([
        service.getTodayAnalytics(),
        service.getWeeklyAnalytics(),
        service.getInsights(),
      ]);

      state = state.copyWith(
        today: results[0] as TodayAnalytics,
        weekly: results[1] as WeeklyAnalytics,
        insights: results[2] as List<AnalyticsInsight>,
        isLoading: false,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: friendlyApiError(e, 'Failed to load analytics'),
      );
    }
  }
}

final analyticsProvider =
    StateNotifierProvider<AnalyticsNotifier, AnalyticsState>((ref) {
      return AnalyticsNotifier(ref);
    });
