import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_error.dart';
import '../../../core/network/providers.dart';
import '../models/hasae_model.dart';
import '../services/hasae_service.dart';

final hasaeServiceProvider = Provider<HasaeService>((ref) {
  return HasaeService(ref.watch(apiClientProvider));
});

class HasaeState {
  final HasaeNextAction? nextAction;
  final HasaeOverload? overload;
  final List<HasaeRankedTask> rankedTasks;
  final HasaeDailyPlan? dailyPlan;
  final bool isNextActionLoading;
  final bool isOverloadLoading;
  final bool isRankLoading;
  final bool isPlanLoading;
  final bool isPlanAccepting;
  final String? error;

  const HasaeState({
    this.nextAction,
    this.overload,
    this.rankedTasks = const [],
    this.dailyPlan,
    this.isNextActionLoading = false,
    this.isOverloadLoading = false,
    this.isRankLoading = false,
    this.isPlanLoading = false,
    this.isPlanAccepting = false,
    this.error,
  });

  HasaeState copyWith({
    HasaeNextAction? nextAction,
    HasaeOverload? overload,
    List<HasaeRankedTask>? rankedTasks,
    HasaeDailyPlan? dailyPlan,
    bool? isNextActionLoading,
    bool? isOverloadLoading,
    bool? isRankLoading,
    bool? isPlanLoading,
    bool? isPlanAccepting,
    String? error,
    bool clearDailyPlan = false,
  }) {
    return HasaeState(
      nextAction: nextAction ?? this.nextAction,
      overload: overload ?? this.overload,
      rankedTasks: rankedTasks ?? this.rankedTasks,
      dailyPlan: clearDailyPlan ? null : dailyPlan ?? this.dailyPlan,
      isNextActionLoading: isNextActionLoading ?? this.isNextActionLoading,
      isOverloadLoading: isOverloadLoading ?? this.isOverloadLoading,
      isRankLoading: isRankLoading ?? this.isRankLoading,
      isPlanLoading: isPlanLoading ?? this.isPlanLoading,
      isPlanAccepting: isPlanAccepting ?? this.isPlanAccepting,
      error: error,
    );
  }
}

class HasaeNotifier extends StateNotifier<HasaeState> {
  final Ref _ref;

  HasaeNotifier(this._ref) : super(const HasaeState());

  Future<void> loadNextAction() async {
    state = state.copyWith(isNextActionLoading: true, error: null);
    try {
      final service = _ref.read(hasaeServiceProvider);
      final result = await service.getNextAction();
      state = state.copyWith(nextAction: result, isNextActionLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isNextActionLoading: false,
        error: friendlyApiError(e, 'Failed to get next action'),
      );
    }
  }

  Future<void> loadOverload() async {
    state = state.copyWith(isOverloadLoading: true, error: null);
    try {
      final service = _ref.read(hasaeServiceProvider);
      final result = await service.checkOverload();
      state = state.copyWith(overload: result, isOverloadLoading: false);
    } on DioException catch (_) {
      state = state.copyWith(isOverloadLoading: false);
    }
  }

  Future<void> loadRankedTasks() async {
    state = state.copyWith(isRankLoading: true);
    try {
      final service = _ref.read(hasaeServiceProvider);
      final tasks = await service.getRankedTasks();
      state = state.copyWith(rankedTasks: tasks, isRankLoading: false);
    } on DioException catch (_) {
      state = state.copyWith(isRankLoading: false);
    }
  }

  Future<void> loadAll() async {
    await Future.wait([loadNextAction(), loadOverload()]);
  }

  Future<void> generateDailyPlan({String? date}) async {
    state = state.copyWith(isPlanLoading: true, error: null);
    try {
      final service = _ref.read(hasaeServiceProvider);
      final plan = await service.generateDailyPlan(date: date);
      state = state.copyWith(dailyPlan: plan, isPlanLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isPlanLoading: false,
        clearDailyPlan: true,
        error: friendlyApiError(e, 'Failed to generate H-ASAE plan'),
      );
    } catch (_) {
      state = state.copyWith(
        isPlanLoading: false,
        clearDailyPlan: true,
        error: 'Failed to read H-ASAE plan',
      );
    }
  }

  Future<bool> acceptDailyPlan({String? date}) async {
    state = state.copyWith(isPlanAccepting: true, error: null);
    try {
      final service = _ref.read(hasaeServiceProvider);
      final plan = await service.acceptDailyPlan(date: date);
      state = state.copyWith(dailyPlan: plan, isPlanAccepting: false);
      await loadAll();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isPlanAccepting: false,
        error: friendlyApiError(e, 'Failed to accept H-ASAE plan'),
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isPlanAccepting: false,
        error: 'Failed to save H-ASAE plan',
      );
      return false;
    }
  }
}

final hasaeProvider = StateNotifierProvider<HasaeNotifier, HasaeState>((ref) {
  return HasaeNotifier(ref);
});
