import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/providers.dart';
import '../services/ai_service.dart';

final aiServiceProvider = Provider<AiService>((ref) {
  return AiService(ref.watch(apiClientProvider));
});

class ParsedTask {
  final String title;
  final String priority;
  final String? dueAt;
  final int? estimatedMinutes;
  final String? category;
  final String confidence;
  final String rawInput;

  ParsedTask({
    required this.title,
    required this.priority,
    this.dueAt,
    this.estimatedMinutes,
    this.category,
    required this.confidence,
    required this.rawInput,
  });

  factory ParsedTask.fromJson(Map<String, dynamic> json, String rawInput) {
    final data = json['data'] as Map<String, dynamic>;
    return ParsedTask(
      title: data['title'] as String? ?? rawInput,
      priority: data['priority'] as String? ?? 'medium',
      dueAt: data['due_at'] as String?,
      estimatedMinutes: data['estimated_minutes'] as int?,
      category: data['category'] as String?,
      confidence: data['confidence'] as String? ?? 'low',
      rawInput: rawInput,
    );
  }
}

class AiState {
  final ParsedTask? parsedTask;
  final bool isLoading;
  final String? error;

  const AiState({
    this.parsedTask,
    this.isLoading = false,
    this.error,
  });

  AiState copyWith({
    ParsedTask? parsedTask,
    bool? isLoading,
    String? error,
    bool clearParsed = false,
  }) {
    return AiState(
      parsedTask: clearParsed ? null : parsedTask ?? this.parsedTask,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AiNotifier extends StateNotifier<AiState> {
  final Ref _ref;

  AiNotifier(this._ref) : super(const AiState());

  Future<void> parseTask(String inputText) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final service = _ref.read(aiServiceProvider);
      final result = await service.parseTask(inputText);
      final parsed = ParsedTask.fromJson(result, inputText);
      state = state.copyWith(parsedTask: parsed, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data['detail'] as String? ?? 'AI parsing failed',
      );
    }
  }

  void clearParsed() {
    state = state.copyWith(clearParsed: true);
  }
}

final aiProvider = StateNotifierProvider<AiNotifier, AiState>((ref) {
  return AiNotifier(ref);
});