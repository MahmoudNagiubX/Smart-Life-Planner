import '../../../core/network/api_client.dart';
import '../models/task_model.dart';

class TaskService {
  final ApiClient _apiClient;

  TaskService(this._apiClient);

  Future<List<TaskModel>> getTasks({String? status, String? priority}) async {
    final params = <String, dynamic>{};
    if (status != null) params['status'] = status;
    if (priority != null) params['priority'] = priority;

    final response = await _apiClient.dio.get(
      '/tasks',
      queryParameters: params.isNotEmpty ? params : null,
    );
    return (response.data as List).map((t) => TaskModel.fromJson(t)).toList();
  }

  Future<TaskModel> createTask({
    required String title,
    String? description,
    String priority = 'medium',
    String? projectId,
    String? dueAt,
    String? category,
  }) async {
    final response = await _apiClient.dio.post('/tasks', data: {
      'title': title,
      if (description != null) 'description': description,
      'priority': priority,
      if (projectId != null) 'project_id': projectId,
      if (dueAt != null) 'due_at': dueAt,
      if (category != null) 'category': category,
    });
    return TaskModel.fromJson(response.data);
  }

  Future<TaskModel> completeTask(String taskId) async {
    final response = await _apiClient.dio.patch('/tasks/$taskId/complete');
    return TaskModel.fromJson(response.data);
  }

  Future<TaskModel> reopenTask(String taskId) async {
    final response = await _apiClient.dio.patch('/tasks/$taskId/reopen');
    return TaskModel.fromJson(response.data);
  }

  Future<void> deleteTask(String taskId) async {
    await _apiClient.dio.delete('/tasks/$taskId');
  }

  Future<List<TaskProject>> getProjects() async {
    final response = await _apiClient.dio.get('/tasks/projects');
    return (response.data as List).map((p) => TaskProject.fromJson(p)).toList();
  }

  Future<TaskProject> createProject(String title, {String? colorCode}) async {
    final response = await _apiClient.dio.post('/tasks/projects', data: {
      'title': title,
      if (colorCode != null) 'color_code': colorCode,
    });
    return TaskProject.fromJson(response.data);
  }
}