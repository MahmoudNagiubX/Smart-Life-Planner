import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/context_intelligence_model.dart';

class ContextIntelligenceState {
  final ContextIntelligenceSnapshot snapshot;

  const ContextIntelligenceState({
    this.snapshot = const ContextIntelligenceSnapshot(),
  });

  ContextIntelligenceState copyWith({ContextIntelligenceSnapshot? snapshot}) {
    return ContextIntelligenceState(snapshot: snapshot ?? this.snapshot);
  }
}

class ContextIntelligenceNotifier
    extends StateNotifier<ContextIntelligenceState> {
  ContextIntelligenceNotifier() : super(const ContextIntelligenceState());

  void setEnergyLevel(String energyLevel) {
    if (!{'low', 'medium', 'high'}.contains(energyLevel)) return;
    state = state.copyWith(
      snapshot: state.snapshot.copyWith(energyLevel: energyLevel),
    );
  }
}

final contextIntelligenceProvider =
    StateNotifierProvider<
      ContextIntelligenceNotifier,
      ContextIntelligenceState
    >((ref) => ContextIntelligenceNotifier());
