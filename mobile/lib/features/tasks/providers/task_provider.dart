import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/providers.dart';
import '../../../core/notifications/notification_scheduler.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';

final taskServiceProvider = Provider<TaskService>((ref) {
  return TaskService(ref.watch(apiClientProvider));
});

class TasksState {
  final List<TaskModel> tasks;
  final bool isLoading;
  final String? error;

  const TasksState({this.tasks = const [], this.isLoading = false, this.error});

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
      await _syncTaskReminders(tasks);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data['detail'] as String? ?? 'Failed to load tasks',
      );
    }
  }

  Future<bool> createTask({
    required String title,
    String priority = 'medium',
    String? description,
    String? projectId,
    DateTime? reminderAt,
  }) async {
    try {
      final service = _ref.read(taskServiceProvider);
      final task = await service.createTask(
        title: title,
        description: description,
        priority: priority,
        projectId: projectId,
        reminderAt: reminderAt?.toUtc().toIso8601String(),
      );

      await _syncTaskReminder(task);

      await loadTasks();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        error: e.response?.data['detail'] as String? ?? 'Failed to create task',
      );
      return false;
    } catch (_) {
      state = state.copyWith(error: 'Failed to create task');
      return false;
    }
  }

  Future<void> completeTask(String taskId) async {
    try {
      final service = _ref.read(taskServiceProvider);
      final updated = await service.completeTask(taskId);

      // Cancel reminder since task is done
      await _ref.read(notificationSchedulerProvider).cancelTaskReminder(taskId);

      state = state.copyWith(
        tasks: state.tasks.map((t) => t.id == taskId ? updated : t).toList(),
      );
    } catch (_) {}
  }

  Future<void> deleteTask(String taskId) async {
    try {
      final service = _ref.read(taskServiceProvider);
      await service.deleteTask(taskId);

      // Cancel reminder since task is deleted
      await _ref.read(notificationSchedulerProvider).cancelTaskReminder(taskId);

      state = state.copyWith(
        tasks: state.tasks.where((t) => t.id != taskId).toList(),
      );
    } catch (_) {}
  }

  Future<void> _syncTaskReminders(List<TaskModel> tasks) async {
    for (final task in tasks) {
      await _syncTaskReminder(task);
    }
  }

  Future<void> _syncTaskReminder(TaskModel task) async {
    final scheduler = _ref.read(notificationSchedulerProvider);

    if (task.status != 'pending' || task.isDeleted || task.reminderAt == null) {
      await scheduler.cancelTaskReminder(task.id);
      return;
    }

    try {
      final reminderAt = DateTime.parse(task.reminderAt!).toLocal();
      if (reminderAt.isAfter(DateTime.now())) {
        await scheduler.scheduleTaskReminder(
          taskId: task.id,
          taskTitle: task.title,
          reminderAt: reminderAt,
        );
      } else {
        await scheduler.cancelTaskReminder(task.id);
      }
    } catch (_) {
      await scheduler.cancelTaskReminder(task.id);
    }
  }
}

final tasksProvider = StateNotifierProvider<TasksNotifier, TasksState>((ref) {
  return TasksNotifier(ref);
});
