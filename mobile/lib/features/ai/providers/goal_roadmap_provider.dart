import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import '../../tasks/providers/task_provider.dart';
import '../models/goal_roadmap_model.dart';
import 'ai_provider.dart';

class GoalRoadmapState {
  final GoalRoadmapResult? result;
  final bool isGenerating;
  final bool isConfirming;
  final String? error;
  final String? createdProjectId;

  const GoalRoadmapState({
    this.result,
    this.isGenerating = false,
    this.isConfirming = false,
    this.error,
    this.createdProjectId,
  });

  GoalRoadmapState copyWith({
    GoalRoadmapResult? result,
    bool? isGenerating,
    bool? isConfirming,
    String? error,
    String? createdProjectId,
    bool clearResult = false,
  }) {
    return GoalRoadmapState(
      result: clearResult ? null : result ?? this.result,
      isGenerating: isGenerating ?? this.isGenerating,
      isConfirming: isConfirming ?? this.isConfirming,
      error: error,
      createdProjectId: createdProjectId ?? this.createdProjectId,
    );
  }
}

class GoalRoadmapNotifier extends StateNotifier<GoalRoadmapState> {
  final Ref _ref;

  GoalRoadmapNotifier(this._ref) : super(const GoalRoadmapState());

  Future<void> generate({
    required String goalTitle,
    String? deadline,
    String? currentLevel,
    required int weeklyAvailableHours,
    String? constraints,
  }) async {
    state = state.copyWith(isGenerating: true, error: null, clearResult: true);
    try {
      final response = await _ref
          .read(aiServiceProvider)
          .generateGoalRoadmap(
            goalTitle: goalTitle,
            deadline: deadline,
            currentLevel: currentLevel,
            weeklyAvailableHours: weeklyAvailableHours,
            constraints: constraints,
          );
      state = state.copyWith(
        result: GoalRoadmapResult.fromJson(response),
        isGenerating: false,
      );
    } on DioException catch (error) {
      state = state.copyWith(
        isGenerating: false,
        error: friendlyApiError(error, 'Failed to generate roadmap'),
      );
    } catch (_) {
      state = state.copyWith(
        isGenerating: false,
        error: 'Failed to generate roadmap',
      );
    }
  }

  Future<bool> confirm({
    required String projectTitle,
    required List<GoalRoadmapTask> tasks,
  }) async {
    if (tasks.isEmpty) {
      state = state.copyWith(error: 'Select at least one task to create.');
      return false;
    }
    state = state.copyWith(isConfirming: true, error: null);
    try {
      final service = _ref.read(taskServiceProvider);
      final project = await service.createProject(projectTitle);
      for (final task in tasks) {
        await service.createTask(
          title: task.title,
          description: task.description,
          projectId: project.id,
          priority: task.priority,
          estimatedMinutes: task.estimatedMinutes,
          category: 'goal-roadmap',
          status: 'pending',
        );
      }
      state = state.copyWith(isConfirming: false, createdProjectId: project.id);
      return true;
    } on DioException catch (error) {
      state = state.copyWith(
        isConfirming: false,
        error: friendlyApiError(error, 'Failed to create roadmap tasks'),
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isConfirming: false,
        error: 'Failed to create roadmap tasks',
      );
      return false;
    }
  }
}

final goalRoadmapProvider =
    StateNotifierProvider<GoalRoadmapNotifier, GoalRoadmapState>((ref) {
      return GoalRoadmapNotifier(ref);
    });
