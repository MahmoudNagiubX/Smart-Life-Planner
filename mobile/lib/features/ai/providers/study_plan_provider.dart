import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import '../../tasks/providers/task_provider.dart';
import '../models/study_plan_model.dart';
import 'ai_provider.dart';

class StudyPlanState {
  final StudyPlanResult? result;
  final bool isGenerating;
  final bool isConfirming;
  final String? error;

  const StudyPlanState({
    this.result,
    this.isGenerating = false,
    this.isConfirming = false,
    this.error,
  });

  StudyPlanState copyWith({
    StudyPlanResult? result,
    bool? isGenerating,
    bool? isConfirming,
    String? error,
    bool clearResult = false,
  }) {
    return StudyPlanState(
      result: clearResult ? null : result ?? this.result,
      isGenerating: isGenerating ?? this.isGenerating,
      isConfirming: isConfirming ?? this.isConfirming,
      error: error,
    );
  }
}

class StudyPlanNotifier extends StateNotifier<StudyPlanState> {
  final Ref _ref;

  StudyPlanNotifier(this._ref) : super(const StudyPlanState());

  Future<void> generate({
    required String subject,
    required String examDate,
    required List<String> topics,
    required String difficulty,
    required int availableDailyStudyMinutes,
  }) async {
    state = state.copyWith(isGenerating: true, error: null, clearResult: true);
    try {
      final response = await _ref
          .read(aiServiceProvider)
          .generateStudyPlan(
            subject: subject,
            examDate: examDate,
            topics: topics,
            difficulty: difficulty,
            availableDailyStudyMinutes: availableDailyStudyMinutes,
          );
      state = state.copyWith(
        result: StudyPlanResult.fromJson(response),
        isGenerating: false,
      );
    } on DioException catch (error) {
      state = state.copyWith(
        isGenerating: false,
        error: friendlyApiError(error, 'Failed to generate study plan'),
      );
    } catch (_) {
      state = state.copyWith(
        isGenerating: false,
        error: 'Failed to generate study plan',
      );
    }
  }

  Future<bool> confirm({
    required String subject,
    required List<StudyPlanDay> selectedDays,
  }) async {
    if (selectedDays.isEmpty) {
      state = state.copyWith(error: 'Select at least one study task.');
      return false;
    }
    state = state.copyWith(isConfirming: true, error: null);
    try {
      final service = _ref.read(taskServiceProvider);
      final project = await service.createProject('Study: $subject');
      for (final day in selectedDays) {
        await service.createTask(
          title: day.title,
          description:
              '${day.topic} - study ${day.studyMinutes} min, practice ${day.practiceMinutes} min.',
          projectId: project.id,
          priority: day.priority,
          estimatedMinutes: day.totalMinutes,
          category: 'study-plan',
          dueAt: '${day.date}T18:00:00.000Z',
          status: 'pending',
        );
      }
      state = state.copyWith(isConfirming: false);
      return true;
    } on DioException catch (error) {
      state = state.copyWith(
        isConfirming: false,
        error: friendlyApiError(error, 'Failed to create study tasks'),
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isConfirming: false,
        error: 'Failed to create study tasks',
      );
      return false;
    }
  }
}

final studyPlanProvider =
    StateNotifierProvider<StudyPlanNotifier, StudyPlanState>((ref) {
      return StudyPlanNotifier(ref);
    });
