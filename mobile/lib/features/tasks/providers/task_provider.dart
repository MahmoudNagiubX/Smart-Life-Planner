import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/providers.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';

final taskServiceProvider = Provider<TaskService>((ref) {
  return TaskService(ref.watch(apiClientProvider));
});

class TasksState {
  final List<TaskModel> tasks;
  final bool isLoading;
  final String? error;

  const TasksState({
    this.tasks = const [],
    this.isLoading = false,
    this.error,
  });

  TasksState copyWith({
    List<TaskModel>? tasks,
    bool? isLoading,
    String? error,
  }) {
    return TasksState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class TasksNotifier extends StateNotifier<TasksState> {
  final Ref _ref;

  TasksNotifier(this._ref) : super(const TasksState());

  Future<void> loadTasks({String? status}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final service = _ref.read(taskServiceProvider);
      final tasks = await service.getTasks(status: status);
      state = state.copyWith(tasks: tasks, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data['detail'] ?? 'Failed to load tasks',
      );
    }
  }

  Future<void> createTask({
    required String title,
    String priority = 'medium',
    String? description,
    String? projectId,
  }) async {
    try {
      final service = _ref.read(taskServiceProvider);
      final task = await service.createTask(
        title: title,
        description: description,
        priority: priority,
        projectId: projectId,
      );
      state = state.copyWith(tasks: [task, ...state.tasks]);
    } on DioException catch (e) {
      state = state.copyWith(
        error: e.response?.data['detail'] ?? 'Failed to create task',
      );
    }
  }

  Future<void> completeTask(String taskId) async {
    try {
      final service = _ref.read(taskServiceProvider);
      final updated = await service.completeTask(taskId);
      state = state.copyWith(
        tasks: state.tasks.map((t) => t.id == taskId ? updated : t).toList(),
      );
    } catch (_) {}
  }

  Future<void> deleteTask(String taskId) async {
    try {
      final service = _ref.read(taskServiceProvider);
      await service.deleteTask(taskId);
      state = state.copyWith(
        tasks: state.tasks.where((t) => t.id != taskId).toList(),
      );
    } catch (_) {}
  }
}

final tasksProvider = StateNotifierProvider<TasksNotifier, TasksState>((ref) {
  return TasksNotifier(ref);
});