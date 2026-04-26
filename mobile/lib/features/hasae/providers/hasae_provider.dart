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
  final bool isNextActionLoading;
  final bool isOverloadLoading;
  final bool isRankLoading;
  final String? error;

  const HasaeState({
    this.nextAction,
    this.overload,
    this.rankedTasks = const [],
    this.isNextActionLoading = false,
    this.isOverloadLoading = false,
    this.isRankLoading = false,
    this.error,
  });

  HasaeState copyWith({
    HasaeNextAction? nextAction,
    HasaeOverload? overload,
    List<HasaeRankedTask>? rankedTasks,
    bool? isNextActionLoading,
    bool? isOverloadLoading,
    bool? isRankLoading,
    String? error,
  }) {
    return HasaeState(
      nextAction: nextAction ?? this.nextAction,
      overload: overload ?? this.overload,
      rankedTasks: rankedTasks ?? this.rankedTasks,
      isNextActionLoading: isNextActionLoading ?? this.isNextActionLoading,
      isOverloadLoading: isOverloadLoading ?? this.isOverloadLoading,
      isRankLoading: isRankLoading ?? this.isRankLoading,
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
}

final hasaeProvider = StateNotifierProvider<HasaeNotifier, HasaeState>((ref) {
  return HasaeNotifier(ref);
});
