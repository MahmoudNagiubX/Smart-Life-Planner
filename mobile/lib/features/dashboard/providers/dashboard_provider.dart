import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_error.dart';
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

  const DashboardState({this.data, this.isLoading = false, this.error});

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
        error: friendlyApiError(e, 'Failed to load dashboard'),
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to read dashboard data',
      );
    }
  }

  Future<bool> updateDashboardWidgets(List<String> widgets) async {
    try {
      final service = _ref.read(dashboardServiceProvider);
      await service.updateDashboardWidgets(widgets);
      await loadDashboard();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        error: friendlyApiError(e, 'Failed to update dashboard'),
      );
      return false;
    } catch (_) {
      state = state.copyWith(error: 'Failed to update dashboard');
      return false;
    }
  }
}

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
      return DashboardNotifier(ref);
    });
