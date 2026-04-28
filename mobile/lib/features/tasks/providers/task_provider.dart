import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_error.dart';
import '../../../core/network/providers.dart';
import '../../../core/notifications/notification_scheduler.dart';
import '../../reminders/models/reminder_model.dart';
import '../../reminders/providers/reminder_preferences_provider.dart';
import '../../reminders/providers/reminder_provider.dart';
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
      state = state.copyWith(
        tasks: tasks..sort(_compareManualOrder),
        isLoading: false,
      );
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
    String? status,
    List<TaskReminderPresetDraft> reminderPresets = const [],
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
        status: status,
      );

      if (reminderPresets.isNotEmpty) {
        await _createAndSyncTaskPresetReminders(task, reminderPresets);
      } else {
        await _syncTaskReminder(task);
      }

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
      await _cancelTaskPresetReminders(taskId);

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
      await _cancelTaskPresetReminders(taskId);

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
    String? status,
    int? manualOrder,
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
        status: status,
        manualOrder: manualOrder,
        clearDueAt: clearDueAt,
        clearReminderAt: clearReminderAt,
      );

      await _syncTaskReminder(updated);
      await _syncTaskPresetReminders(updated);

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

  Future<bool> moveTaskToStatus({
    required TaskModel task,
    required String status,
  }) async {
    try {
      final service = _ref.read(taskServiceProvider);
      TaskModel updated;

      if (status == 'completed') {
        updated = await service.completeTask(task.id);
        await _ref
            .read(notificationSchedulerProvider)
            .cancelTaskReminders(task.id);
        await _cancelTaskPresetReminders(task.id);
      } else if (task.status == 'completed') {
        final reopened = await service.reopenTask(task.id);
        updated = status == 'pending'
            ? reopened
            : await service.updateTask(taskId: task.id, status: status);
      } else {
        updated = await service.updateTask(taskId: task.id, status: status);
      }

      await _syncTaskReminder(updated);
      state = state.copyWith(
        tasks: state.tasks
            .map((current) => current.id == task.id ? updated : current)
            .toList(),
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(error: friendlyApiError(e, 'Failed to move task'));
      return false;
    } catch (_) {
      state = state.copyWith(error: 'Failed to move task');
      return false;
    }
  }

  Future<bool> reorderTasks(List<TaskModel> orderedTasks) async {
    final orderedIds = orderedTasks.map((task) => task.id).toList();
    try {
      final updatedTasks = await _ref
          .read(taskServiceProvider)
          .reorderTasks(orderedIds);
      final updatedById = {for (final task in updatedTasks) task.id: task};
      state = state.copyWith(
        tasks: state.tasks.map((task) => updatedById[task.id] ?? task).toList()
          ..sort(_compareManualOrder),
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        error: friendlyApiError(e, 'Failed to reorder tasks'),
      );
      return false;
    } catch (_) {
      state = state.copyWith(error: 'Failed to reorder tasks');
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

    if (task.status == 'completed' ||
        task.isDeleted ||
        task.reminderAt == null) {
      await scheduler.cancelTaskReminder(task.id);
      await _ref
          .read(reminderServiceProvider)
          .dismissTargetReminders(
            targetType: 'task',
            targetId: task.id,
            reminderType: 'task_due',
            recurrenceRule: _taskSingleReminderRule,
          );
      return;
    }
    try {
      final reminderAt = DateTime.parse(task.reminderAt!).toLocal();
      final reminder = await _ref
          .read(reminderServiceProvider)
          .syncTargetReminder(
            targetType: 'task',
            targetId: task.id,
            reminderType: 'task_due',
            scheduledAt: reminderAt,
            recurrenceRule: _taskSingleReminderRule,
            timezone: DateTime.now().timeZoneName,
            priority: task.priority == 'high' ? 'high' : 'normal',
          );
      if (reminder == null ||
          !await _ref
              .read(reminderPreferencesProvider.notifier)
              .canScheduleLocal('task', scheduledAt: reminderAt)) {
        await scheduler.cancelTaskReminder(task.id);
        return;
      }
      if (reminderAt.isAfter(DateTime.now())) {
        await scheduler.rescheduleTaskReminder(
          taskId: task.id,
          taskTitle: task.title,
          reminderAt: reminderAt,
          reminderId: reminder.id,
        );
      } else {
        await scheduler.cancelTaskReminder(task.id);
        await _ref
            .read(reminderServiceProvider)
            .dismissTargetReminders(
              targetType: 'task',
              targetId: task.id,
              reminderType: 'task_due',
              recurrenceRule: _taskSingleReminderRule,
            );
      }
    } catch (_) {
      await scheduler.cancelTaskReminder(task.id);
    }
  }

  Future<void> _createAndSyncTaskPresetReminders(
    TaskModel task,
    List<TaskReminderPresetDraft> presets,
  ) async {
    final reminders = await _ref
        .read(reminderServiceProvider)
        .saveTaskReminderPresets(
          taskId: task.id,
          presets: presets,
          timezone: DateTime.now().timeZoneName,
        );
    await _scheduleTaskPresetReminders(task, reminders);
  }

  Future<void> _syncTaskPresetReminders(TaskModel task) async {
    try {
      final reminders = await _ref
          .read(reminderServiceProvider)
          .getReminders(
            targetType: 'task',
            targetId: task.id,
            status: 'scheduled',
          );
      await _scheduleTaskPresetReminders(task, reminders);
    } catch (_) {}
  }

  Future<void> _cancelTaskPresetReminders(String taskId) async {
    try {
      final reminders = await _ref
          .read(reminderServiceProvider)
          .getReminders(targetType: 'task', targetId: taskId);
      final scheduler = _ref.read(notificationSchedulerProvider);
      for (final reminder in reminders) {
        await scheduler.cancelTaskPresetReminder(reminder.id);
        await scheduler.cancelPersistentTaskReminderSeries(reminder.id);
      }
    } catch (_) {}
  }

  Future<void> _scheduleTaskPresetReminders(
    TaskModel task,
    List<ReminderModel> reminders,
  ) async {
    final scheduler = _ref.read(notificationSchedulerProvider);
    for (final reminder in reminders) {
      if (reminder.reminderType != 'task_due' || reminder.channel != 'local') {
        continue;
      }
      final reminderAt = DateTime.tryParse(reminder.scheduledAt)?.toLocal();
      if (reminderAt == null ||
          !await _ref
              .read(reminderPreferencesProvider.notifier)
              .canScheduleLocal('task', scheduledAt: reminderAt)) {
        await scheduler.cancelTaskPresetReminder(reminder.id);
        await scheduler.cancelPersistentTaskReminderSeries(reminder.id);
        continue;
      }
      if (reminder.isPersistent &&
          _ref
              .read(reminderPreferencesProvider)
              .preferences
              .types
              .constantReminders) {
        await scheduler.schedulePersistentTaskReminderSeries(
          reminderId: reminder.id,
          taskId: task.id,
          taskTitle: task.title,
          firstReminderAt: reminderAt,
          intervalMinutes: reminder.persistentIntervalMinutes ?? 30,
          maxOccurrences: reminder.persistentMaxOccurrences ?? 3,
        );
        continue;
      }
      await scheduler.scheduleTaskPresetReminder(
        reminderId: reminder.id,
        taskId: task.id,
        taskTitle: task.title,
        reminderAt: reminderAt,
      );
    }
  }
}

final tasksProvider = StateNotifierProvider<TasksNotifier, TasksState>((ref) {
  return TasksNotifier(ref);
});

class TaskCalendarState {
  final List<TaskModel> tasks;
  final bool isLoading;
  final String? error;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  const TaskCalendarState({
    this.tasks = const [],
    this.isLoading = false,
    this.error,
    this.dateFrom,
    this.dateTo,
  });

  TaskCalendarState copyWith({
    List<TaskModel>? tasks,
    bool? isLoading,
    String? error,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) {
    return TaskCalendarState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
    );
  }
}

class TaskCalendarNotifier extends StateNotifier<TaskCalendarState> {
  final Ref _ref;

  TaskCalendarNotifier(this._ref) : super(const TaskCalendarState());

  Future<void> loadRange({
    required DateTime dateFrom,
    required DateTime dateTo,
  }) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
    try {
      final tasks = await _ref
          .read(taskServiceProvider)
          .getTasksForRange(dateFrom: dateFrom, dateTo: dateTo);
      state = state.copyWith(
        tasks: tasks..sort(_compareManualOrder),
        isLoading: false,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: friendlyApiError(e, 'Failed to load calendar tasks'),
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load calendar tasks',
      );
    }
  }

  Future<bool> reorderTasks(List<TaskModel> orderedTasks) async {
    try {
      final updatedTasks = await _ref
          .read(taskServiceProvider)
          .reorderTasks(orderedTasks.map((task) => task.id).toList());
      final updatedById = {for (final task in updatedTasks) task.id: task};
      state = state.copyWith(
        tasks: state.tasks.map((task) => updatedById[task.id] ?? task).toList()
          ..sort(_compareManualOrder),
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

final taskCalendarProvider =
    StateNotifierProvider<TaskCalendarNotifier, TaskCalendarState>((ref) {
      return TaskCalendarNotifier(ref);
    });

class ProjectTimelineState {
  final TaskProject? project;
  final List<TaskModel> tasks;
  final bool isLoading;
  final String? error;

  const ProjectTimelineState({
    this.project,
    this.tasks = const [],
    this.isLoading = false,
    this.error,
  });

  ProjectTimelineState copyWith({
    TaskProject? project,
    List<TaskModel>? tasks,
    bool? isLoading,
    String? error,
  }) {
    return ProjectTimelineState(
      project: project ?? this.project,
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ProjectTimelineNotifier extends StateNotifier<ProjectTimelineState> {
  final Ref _ref;
  final String projectId;

  ProjectTimelineNotifier(this._ref, this.projectId)
    : super(const ProjectTimelineState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final service = _ref.read(taskServiceProvider);
      final projects = await service.getProjects();
      TaskProject? project;
      for (final candidate in projects) {
        if (candidate.id == projectId) {
          project = candidate;
          break;
        }
      }
      if (project == null) {
        state = state.copyWith(isLoading: false, error: 'Project not found');
        return;
      }
      final tasks = await service.getTasks(projectId: projectId);
      state = state.copyWith(
        project: project,
        tasks: tasks..sort(_compareManualOrder),
        isLoading: false,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: friendlyApiError(e, 'Failed to load project timeline'),
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load project timeline',
      );
    }
  }

  Future<bool> reorderProjectTasks(List<TaskModel> orderedTasks) async {
    try {
      final updatedTasks = await _ref
          .read(taskServiceProvider)
          .reorderTasks(orderedTasks.map((task) => task.id).toList());
      state = state.copyWith(tasks: updatedTasks..sort(_compareManualOrder));
      return true;
    } catch (_) {
      return false;
    }
  }
}

final projectTimelineProvider =
    StateNotifierProvider.family<
      ProjectTimelineNotifier,
      ProjectTimelineState,
      String
    >((ref, projectId) {
      return ProjectTimelineNotifier(ref, projectId);
    });

int _compareManualOrder(TaskModel left, TaskModel right) {
  final orderCompare = left.manualOrder.compareTo(right.manualOrder);
  if (orderCompare != 0) return orderCompare;
  return left.createdAt.compareTo(right.createdAt);
}

const _taskSingleReminderRule = 'source=task_reminder_at';
