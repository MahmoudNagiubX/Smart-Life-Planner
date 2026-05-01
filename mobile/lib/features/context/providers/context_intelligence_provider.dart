import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import '../../../core/network/providers.dart';
import '../models/context_intelligence_model.dart';
import '../services/context_intelligence_service.dart';

final contextIntelligenceServiceProvider = Provider<ContextIntelligenceService>(
  (ref) => ContextIntelligenceService(ref.watch(apiClientProvider)),
);

class ContextIntelligenceState {
  final ContextIntelligenceSnapshot snapshot;
  final TimeContextRecommendationResult? recommendations;
  final ContextTaskRecommendationResult? taskRecommendations;
  final String? previewTimeBlock;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const ContextIntelligenceState({
    this.snapshot = const ContextIntelligenceSnapshot(),
    this.recommendations,
    this.taskRecommendations,
    this.previewTimeBlock,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  ContextIntelligenceState copyWith({
    ContextIntelligenceSnapshot? snapshot,
    TimeContextRecommendationResult? recommendations,
    ContextTaskRecommendationResult? taskRecommendations,
    String? previewTimeBlock,
    bool clearPreviewTimeBlock = false,
    bool? isLoading,
    bool? isSaving,
    String? error,
  }) {
    return ContextIntelligenceState(
      snapshot: snapshot ?? this.snapshot,
      recommendations: recommendations ?? this.recommendations,
      taskRecommendations: taskRecommendations ?? this.taskRecommendations,
      previewTimeBlock: clearPreviewTimeBlock
          ? null
          : previewTimeBlock ?? this.previewTimeBlock,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
    );
  }
}

class ContextIntelligenceNotifier
    extends StateNotifier<ContextIntelligenceState> {
  final Ref _ref;

  ContextIntelligenceNotifier(this._ref)
    : super(const ContextIntelligenceState());

  Future<void> loadSnapshot() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final snapshot = await _ref
          .read(contextIntelligenceServiceProvider)
          .getSnapshot();
      final recommendations = await _ref
          .read(contextIntelligenceServiceProvider)
          .getRecommendations(timeBlock: state.previewTimeBlock);
      final taskRecommendations = await _ref
          .read(contextIntelligenceServiceProvider)
          .getTaskRecommendations(timeBlock: state.previewTimeBlock);
      state = state.copyWith(
        snapshot: snapshot,
        recommendations: recommendations,
        taskRecommendations: taskRecommendations,
        isLoading: false,
      );
    } on DioException catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: friendlyApiError(error, 'Failed to load context snapshot'),
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load context snapshot',
      );
    }
  }

  Future<void> setEnergyLevel(String energyLevel) async {
    if (!{'low', 'medium', 'high'}.contains(energyLevel)) return;
    state = state.copyWith(isSaving: true, error: null);
    try {
      final snapshot = await _ref
          .read(contextIntelligenceServiceProvider)
          .createSnapshot(
            state.snapshot.toCreatePayload(nextEnergyLevel: energyLevel),
          );
      final recommendations = await _ref
          .read(contextIntelligenceServiceProvider)
          .getRecommendations(timeBlock: state.previewTimeBlock);
      final taskRecommendations = await _ref
          .read(contextIntelligenceServiceProvider)
          .getTaskRecommendations(timeBlock: state.previewTimeBlock);
      state = state.copyWith(
        snapshot: snapshot,
        recommendations: recommendations,
        taskRecommendations: taskRecommendations,
        isSaving: false,
      );
    } on DioException catch (error) {
      state = state.copyWith(
        isSaving: false,
        error: friendlyApiError(error, 'Failed to update energy level'),
      );
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        error: 'Failed to update energy level',
      );
    }
  }

  Future<void> refreshTimeContext() async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final snapshot = await _ref
          .read(contextIntelligenceServiceProvider)
          .createSnapshot(state.snapshot.toCreatePayload());
      final recommendations = await _ref
          .read(contextIntelligenceServiceProvider)
          .getRecommendations(timeBlock: state.previewTimeBlock);
      final taskRecommendations = await _ref
          .read(contextIntelligenceServiceProvider)
          .getTaskRecommendations(timeBlock: state.previewTimeBlock);
      state = state.copyWith(
        snapshot: snapshot,
        recommendations: recommendations,
        taskRecommendations: taskRecommendations,
        isSaving: false,
      );
    } on DioException catch (error) {
      state = state.copyWith(
        isSaving: false,
        error: friendlyApiError(error, 'Failed to refresh context'),
      );
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        error: 'Failed to refresh context',
      );
    }
  }

  Future<void> previewTimeBlock(String? timeBlock) async {
    if (timeBlock != null &&
        !{'morning', 'afternoon', 'evening', 'night'}.contains(timeBlock)) {
      return;
    }
    state = state.copyWith(
      previewTimeBlock: timeBlock,
      clearPreviewTimeBlock: timeBlock == null,
      isSaving: true,
      error: null,
    );
    try {
      final recommendations = await _ref
          .read(contextIntelligenceServiceProvider)
          .getRecommendations(timeBlock: timeBlock);
      final taskRecommendations = await _ref
          .read(contextIntelligenceServiceProvider)
          .getTaskRecommendations(timeBlock: timeBlock);
      state = state.copyWith(
        recommendations: recommendations,
        taskRecommendations: taskRecommendations,
        isSaving: false,
      );
    } on DioException catch (error) {
      state = state.copyWith(
        isSaving: false,
        error: friendlyApiError(error, 'Failed to load recommendations'),
      );
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        error: 'Failed to load recommendations',
      );
    }
  }
}

final contextIntelligenceProvider =
    StateNotifierProvider<
      ContextIntelligenceNotifier,
      ContextIntelligenceState
    >((ref) => ContextIntelligenceNotifier(ref));
