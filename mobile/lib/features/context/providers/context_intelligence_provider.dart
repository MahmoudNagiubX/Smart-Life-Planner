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
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const ContextIntelligenceState({
    this.snapshot = const ContextIntelligenceSnapshot(),
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  ContextIntelligenceState copyWith({
    ContextIntelligenceSnapshot? snapshot,
    bool? isLoading,
    bool? isSaving,
    String? error,
  }) {
    return ContextIntelligenceState(
      snapshot: snapshot ?? this.snapshot,
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
      state = state.copyWith(snapshot: snapshot, isLoading: false);
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
      state = state.copyWith(snapshot: snapshot, isSaving: false);
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
      state = state.copyWith(snapshot: snapshot, isSaving: false);
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
}

final contextIntelligenceProvider =
    StateNotifierProvider<
      ContextIntelligenceNotifier,
      ContextIntelligenceState
    >((ref) => ContextIntelligenceNotifier(ref));
