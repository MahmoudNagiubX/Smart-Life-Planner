class TaskProject {
  final String id;
  final String title;
  final String? colorCode;
  final String status;

  TaskProject({
    required this.id,
    required this.title,
    this.colorCode,
    required this.status,
  });

  factory TaskProject.fromJson(Map<String, dynamic> json) => TaskProject(
    id: json['id'],
    title: json['title'],
    colorCode: json['color_code'],
    status: json['status'],
  );
}

class TaskModel {
  final String id;
  final String title;
  final String? description;
  final String priority;
  final String status;
  final String? projectId;
  final String? category;
  final String? dueAt;
  final String? reminderAt;
  final int? estimatedMinutes;
  final int manualOrder;
  final bool isDeleted;
  final String? completedAt;
  final String createdAt;
  final String updatedAt;
  final List<SubtaskModel> subtasks;

  TaskModel({
    required this.id,
    required this.title,
    this.description,
    required this.priority,
    required this.status,
    this.projectId,
    this.category,
    this.dueAt,
    this.reminderAt,
    this.estimatedMinutes,
    required this.manualOrder,
    required this.isDeleted,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    this.subtasks = const [],
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    priority: json['priority'],
    status: json['status'],
    projectId: json['project_id'],
    category: json['category'],
    dueAt: json['due_at'],
    reminderAt: json['reminder_at'],
    estimatedMinutes: json['estimated_minutes'],
    manualOrder: json['manual_order'] as int? ?? 0,
    isDeleted: json['is_deleted'] ?? false,
    completedAt: json['completed_at'],
    createdAt: json['created_at'],
    updatedAt: json['updated_at'],
    subtasks: (json['subtasks'] as List<dynamic>? ?? [])
        .map((s) => SubtaskModel.fromJson(s))
        .toList(),
  );
}

class TaskCompletionEventModel {
  final String id;
  final String taskId;
  final String eventType;
  final String? previousStatus;
  final String nextStatus;
  final String occurredAt;
  final String createdAt;

  TaskCompletionEventModel({
    required this.id,
    required this.taskId,
    required this.eventType,
    this.previousStatus,
    required this.nextStatus,
    required this.occurredAt,
    required this.createdAt,
  });

  factory TaskCompletionEventModel.fromJson(Map<String, dynamic> json) =>
      TaskCompletionEventModel(
        id: json['id'],
        taskId: json['task_id'],
        eventType: json['event_type'],
        previousStatus: json['previous_status'],
        nextStatus: json['next_status'],
        occurredAt: json['occurred_at'],
        createdAt: json['created_at'],
      );
}

class SubtaskModel {
  final String id;
  final String title;
  final bool isCompleted;

  SubtaskModel({
    required this.id,
    required this.title,
    required this.isCompleted,
  });

  factory SubtaskModel.fromJson(Map<String, dynamic> json) => SubtaskModel(
    id: json['id'],
    title: json['title'],
    isCompleted: json['is_completed'] ?? false,
  );
}
