import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/providers.dart';
import '../models/daily_plan_model.dart';
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
    final data = json['data'] as Map<String, dynamic>? ?? const {};
    return ParsedTask(
      title: data['title'] as String? ?? rawInput,
      priority: data['priority'] as String? ?? 'medium',
      dueAt: data['due_at'] as String?,
      estimatedMinutes: _readInt(data['estimated_minutes']),
      category: data['category'] as String?,
      confidence: data['confidence'] as String? ?? 'low',
      rawInput: rawInput,
    );
  }

  static int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class AiState {
  final ParsedTask? parsedTask;
  final NextActionData? nextAction;
  final DailyPlanData? dailyPlan;
  final bool isLoading;
  final bool isPlanLoading;
  final bool isNextActionLoading;
  final String? error;

  const AiState({
    this.parsedTask,
    this.nextAction,
    this.dailyPlan,
    this.isLoading = false,
    this.isPlanLoading = false,
    this.isNextActionLoading = false,
    this.error,
  });

  AiState copyWith({
    ParsedTask? parsedTask,
    NextActionData? nextAction,
    DailyPlanData? dailyPlan,
    bool? isLoading,
    bool? isPlanLoading,
    bool? isNextActionLoading,
    String? error,
    bool clearParsed = false,
    bool clearNextAction = false,
    bool clearDailyPlan = false,
  }) {
    return AiState(
      parsedTask: clearParsed ? null : parsedTask ?? this.parsedTask,
      nextAction: clearNextAction ? null : nextAction ?? this.nextAction,
      dailyPlan: clearDailyPlan ? null : dailyPlan ?? this.dailyPlan,
      isLoading: isLoading ?? this.isLoading,
      isPlanLoading: isPlanLoading ?? this.isPlanLoading,
      isNextActionLoading: isNextActionLoading ?? this.isNextActionLoading,
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
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to read AI task parsing result',
      );
    }
  }

  Future<void> loadNextAction() async {
    state = state.copyWith(isNextActionLoading: true, error: null);
    try {
      final service = _ref.read(aiServiceProvider);
      final result = await service.getNextAction();
      final next = NextActionData.fromJson(result);
      state = state.copyWith(nextAction: next, isNextActionLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isNextActionLoading: false,
        clearNextAction: true,
        error:
            e.response?.data['detail'] as String? ??
            'Failed to get next action',
      );
    } catch (_) {
      state = state.copyWith(
        isNextActionLoading: false,
        clearNextAction: true,
        error: 'Failed to read next action',
      );
    }
  }

  Future<void> loadDailyPlan({String? date}) async {
    state = state.copyWith(isPlanLoading: true, error: null);
    try {
      final service = _ref.read(aiServiceProvider);
      final result = await service.getDailyPlan(date: date);
      final plan = DailyPlanData.fromJson(result);
      state = state.copyWith(dailyPlan: plan, isPlanLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isPlanLoading: false,
        clearDailyPlan: true,
        error:
            e.response?.data['detail'] as String? ?? 'Failed to generate plan',
      );
    } catch (_) {
      state = state.copyWith(
        isPlanLoading: false,
        clearDailyPlan: true,
        error: 'Failed to read daily plan',
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
