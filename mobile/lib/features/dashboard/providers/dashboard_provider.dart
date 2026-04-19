import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/providers.dart';
import '../models/dashboard_model.dart';
import '../services/dashboard_service.dart';

final dashboardServiceProvider = Provider<DashboardService>((ref) {
  return DashboardService(ref.watch(apiClientProvider));
});

class DashboardState {
  final DashboardData? data;
  final bool isLoading;
  final String? error;

  const DashboardState({
    this.data,
    this.isLoading = false,
    this.error,
  });

  DashboardState copyWith({
    DashboardData? data,
    bool? isLoading,
    String? error,
  }) {
    return DashboardState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final Ref _ref;

  DashboardNotifier(this._ref) : super(const DashboardState());

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final service = _ref.read(dashboardServiceProvider);
      final data = await service.getHomeDashboard();
      state = state.copyWith(data: data, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data['detail'] as String? ?? 'Failed to load dashboard',
      );
    }
  }
}

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier(ref);
});