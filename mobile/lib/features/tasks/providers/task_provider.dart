import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_error.dart';
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
        error: friendlyApiError(e, 'Failed to load tasks'),
      );
    }
  }

  Future<bool> createTask({
    required String title,
    String priority = 'medium',
    String? description,
    String? projectId,
    DateTime? dueAt,
    DateTime? reminderAt,
    String? category,
    int? estimatedMinutes,
  }) async {
    try {
      final service = _ref.read(taskServiceProvider);
      final task = await service.createTask(
        title: title,
        description: description,
        priority: priority,
        projectId: projectId,
        dueAt: dueAt?.toUtc().toIso8601String(),
        reminderAt: reminderAt?.toUtc().toIso8601String(),
        category: category,
        estimatedMinutes: estimatedMinutes,
      );

      await _syncTaskReminder(task);

      await loadTasks();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        error: friendlyApiError(e, 'Failed to create task'),
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

      await _ref
          .read(notificationSchedulerProvider)
          .cancelTaskReminders(taskId);

      state = state.copyWith(
        tasks: state.tasks.map((t) => t.id == taskId ? updated : t).toList(),
      );
    } catch (_) {}
  }

  Future<void> deleteTask(String taskId) async {
    try {
      final service = _ref.read(taskServiceProvider);
      await service.deleteTask(taskId);

      await _ref
          .read(notificationSchedulerProvider)
          .cancelTaskReminders(taskId);

      state = state.copyWith(
        tasks: state.tasks.where((t) => t.id != taskId).toList(),
      );
    } catch (_) {}
  }

  Future<bool> updateTask({
    required String taskId,
    String? title,
    String? description,
    String? priority,
    String? projectId,
    DateTime? dueAt,
    DateTime? reminderAt,
    String? category,
    int? estimatedMinutes,
    bool clearDueAt = false,
    bool clearReminderAt = false,
  }) async {
    try {
      final service = _ref.read(taskServiceProvider);
      final updated = await service.updateTask(
        taskId: taskId,
        title: title,
        description: description,
        priority: priority,
        projectId: projectId,
        dueAt: dueAt?.toUtc().toIso8601String(),
        reminderAt: reminderAt?.toUtc().toIso8601String(),
        category: category,
        estimatedMinutes: estimatedMinutes,
        clearDueAt: clearDueAt,
        clearReminderAt: clearReminderAt,
      );

      await _syncTaskReminder(updated);

      state = state.copyWith(
        tasks: state.tasks.map((t) => t.id == taskId ? updated : t).toList(),
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        error: friendlyApiError(e, 'Failed to update task'),
      );
      return false;
    } catch (_) {
      state = state.copyWith(error: 'Failed to update task');
      return false;
    }
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
        await scheduler.rescheduleTaskReminder(
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
