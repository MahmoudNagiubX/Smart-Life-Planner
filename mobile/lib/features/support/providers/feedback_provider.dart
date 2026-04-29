import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import '../../../core/network/providers.dart';
import '../services/feedback_service.dart';

final feedbackServiceProvider = Provider<FeedbackService>((ref) {
  return FeedbackService(ref.watch(apiClientProvider));
});

class FeedbackState {
  final bool isSubmitting;
  final String? error;
  final String? successMessage;

  const FeedbackState({
    this.isSubmitting = false,
    this.error,
    this.successMessage,
  });

  FeedbackState copyWith({
    bool? isSubmitting,
    String? error,
    String? successMessage,
  }) {
    return FeedbackState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
      successMessage: successMessage,
    );
  }
}

class FeedbackNotifier extends StateNotifier<FeedbackState> {
  final Ref _ref;

  FeedbackNotifier(this._ref) : super(const FeedbackState());

  Future<bool> submit({
    required String category,
    required String message,
  }) async {
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      final successMessage = await _ref
          .read(feedbackServiceProvider)
          .submitFeedback(category: category, message: message);
      state = state.copyWith(
        isSubmitting: false,
        successMessage: successMessage,
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: friendlyApiError(e, 'Failed to send feedback'),
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        error: 'Failed to send feedback',
      );
      return false;
    }
  }

  void clear() {
    state = const FeedbackState();
  }
}

final feedbackProvider = StateNotifierProvider<FeedbackNotifier, FeedbackState>(
  (ref) {
    return FeedbackNotifier(ref);
  },
);
