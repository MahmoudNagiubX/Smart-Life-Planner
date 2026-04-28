import '../../../core/network/api_client.dart';
import '../models/task_model.dart';

class TaskService {
  final ApiClient _apiClient;

  TaskService(this._apiClient);

  Future<List<TaskModel>> getTasks({
    String? status,
    String? priority,
    String? projectId,
  }) async {
    final params = <String, dynamic>{};
    if (status != null) params['status'] = status;
    if (priority != null) params['priority'] = priority;
    if (projectId != null) params['project_id'] = projectId;

    final response = await _apiClient.dio.get(
      '/tasks',
      queryParameters: params.isNotEmpty ? params : null,
    );
    return (response.data as List<dynamic>)
        .map((t) => TaskModel.fromJson(t as Map<String, dynamic>))
        .toList();
  }

  Future<TaskModel> getTask(String taskId) async {
    final response = await _apiClient.dio.get('/tasks/$taskId');
    return TaskModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<TaskCompletionEventModel>> getCompletionHistory(
    String taskId,
  ) async {
    final response = await _apiClient.dio.get(
      '/tasks/$taskId/completion-history',
    );
    return (response.data as List<dynamic>)
        .map(
          (event) =>
              TaskCompletionEventModel.fromJson(event as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<TaskModel>> getTasksForRange({
    required DateTime dateFrom,
    required DateTime dateTo,
  }) async {
    final response = await _apiClient.dio.get(
      '/tasks/range',
      queryParameters: {
        'date_from': dateFrom.toIso8601String().substring(0, 10),
        'date_to': dateTo.toIso8601String().substring(0, 10),
      },
    );
    return (response.data as List<dynamic>)
        .map((t) => TaskModel.fromJson(t as Map<String, dynamic>))
        .toList();
  }

  Future<TaskModel> createTask({
    required String title,
    String? description,
    String priority = 'medium',
    String? projectId,
    String? dueAt,
    String? reminderAt,
    String? category,
    int? estimatedMinutes,
    String? status,
  }) async {
    final data = <String, dynamic>{'title': title, 'priority': priority};
    if (description != null) data['description'] = description;
    if (projectId != null) data['project_id'] = projectId;
    if (dueAt != null) data['due_at'] = dueAt;
    if (reminderAt != null) data['reminder_at'] = reminderAt;
    if (category != null) data['category'] = category;
    if (estimatedMinutes != null) data['estimated_minutes'] = estimatedMinutes;
    if (status != null) data['status'] = status;

    final response = await _apiClient.dio.post('/tasks', data: data);
    return TaskModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TaskModel> completeTask(String taskId) async {
    final response = await _apiClient.dio.patch('/tasks/$taskId/complete');
    return TaskModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TaskModel> updateTask({
    required String taskId,
    String? title,
    String? description,
    String? priority,
    String? projectId,
    String? dueAt,
    String? reminderAt,
    String? category,
    int? estimatedMinutes,
    String? status,
    int? manualOrder,
    bool clearDueAt = false,
    bool clearReminderAt = false,
  }) async {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (description != null) data['description'] = description;
    if (priority != null) data['priority'] = priority;
    if (projectId != null) data['project_id'] = projectId;
    if (clearDueAt) {
      data['due_at'] = null;
    } else if (dueAt != null) {
      data['due_at'] = dueAt;
    }
    if (clearReminderAt) {
      data['reminder_at'] = null;
    } else if (reminderAt != null) {
      data['reminder_at'] = reminderAt;
    }
    if (category != null) data['category'] = category;
    if (estimatedMinutes != null) data['estimated_minutes'] = estimatedMinutes;
    if (status != null) data['status'] = status;
    if (manualOrder != null) data['manual_order'] = manualOrder;

    final response = await _apiClient.dio.patch('/tasks/$taskId', data: data);
    return TaskModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<TaskModel>> reorderTasks(List<String> taskIds) async {
    final response = await _apiClient.dio.patch(
      '/tasks/reorder',
      data: {'task_ids': taskIds},
    );
    return (response.data as List<dynamic>)
        .map((t) => TaskModel.fromJson(t as Map<String, dynamic>))
        .toList();
  }

  Future<TaskModel> reopenTask(String taskId) async {
    final response = await _apiClient.dio.patch('/tasks/$taskId/reopen');
    return TaskModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteTask(String taskId) async {
    await _apiClient.dio.delete('/tasks/$taskId');
  }

  Future<List<TaskProject>> getProjects() async {
    final response = await _apiClient.dio.get('/tasks/projects');
    return (response.data as List<dynamic>)
        .map((p) => TaskProject.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  Future<TaskProject> createProject(String title, {String? colorCode}) async {
    final data = <String, dynamic>{'title': title};
    if (colorCode != null) data['color_code'] = colorCode;

    final response = await _apiClient.dio.post('/tasks/projects', data: data);
    return TaskProject.fromJson(response.data as Map<String, dynamic>);
  }
}
