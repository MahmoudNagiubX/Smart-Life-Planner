import 'task_model.dart';

class ProjectTimelineModel {
  final TaskProject project;
  final List<ProjectTimelineTaskBarModel> taskBars;
  final List<ProjectTimelineDependencyModel> dependencies;

  const ProjectTimelineModel({
    required this.project,
    required this.taskBars,
    this.dependencies = const [],
  });

  factory ProjectTimelineModel.fromJson(Map<String, dynamic> json) {
    return ProjectTimelineModel(
      project: TaskProject.fromJson(json['project'] as Map<String, dynamic>),
      taskBars: (json['task_bars'] as List<dynamic>? ?? [])
          .map(
            (item) => ProjectTimelineTaskBarModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
      dependencies: (json['dependencies'] as List<dynamic>? ?? [])
          .map(
            (item) => ProjectTimelineDependencyModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}

class ProjectTimelineTaskBarModel {
  final String taskId;
  final String title;
  final String status;
  final String priority;
  final String projectId;
  final String? startDate;
  final String? dueDate;
  final int? estimatedDurationMinutes;
  final List<String> dependencyIds;
  final bool overdue;
  final bool conflict;
  final List<String> conflictReasons;

  const ProjectTimelineTaskBarModel({
    required this.taskId,
    required this.title,
    required this.status,
    required this.priority,
    required this.projectId,
    this.startDate,
    this.dueDate,
    this.estimatedDurationMinutes,
    this.dependencyIds = const [],
    this.overdue = false,
    this.conflict = false,
    this.conflictReasons = const [],
  });

  factory ProjectTimelineTaskBarModel.fromJson(Map<String, dynamic> json) {
    return ProjectTimelineTaskBarModel(
      taskId: json['task_id'] as String,
      title: json['title'] as String,
      status: json['status'] as String,
      priority: json['priority'] as String,
      projectId: json['project_id'] as String,
      startDate: json['start_date'] as String?,
      dueDate: json['due_date'] as String?,
      estimatedDurationMinutes: json['estimated_duration_minutes'] as int?,
      dependencyIds: (json['dependency_ids'] as List<dynamic>? ?? [])
          .map((item) => item as String)
          .toList(),
      overdue: json['overdue'] as bool? ?? false,
      conflict: json['conflict'] as bool? ?? false,
      conflictReasons: (json['conflict_reasons'] as List<dynamic>? ?? [])
          .map((item) => item as String)
          .toList(),
    );
  }

  DateTime? get startDateTime => _parseLocal(startDate);
  DateTime? get dueDateTime => _parseLocal(dueDate);
}

class ProjectTimelineDependencyModel {
  final String taskId;
  final String dependsOnTaskId;
  final String dependencyType;

  const ProjectTimelineDependencyModel({
    required this.taskId,
    required this.dependsOnTaskId,
    required this.dependencyType,
  });

  factory ProjectTimelineDependencyModel.fromJson(Map<String, dynamic> json) {
    return ProjectTimelineDependencyModel(
      taskId: json['task_id'] as String,
      dependsOnTaskId: json['depends_on_task_id'] as String,
      dependencyType: json['dependency_type'] as String,
    );
  }
}

DateTime? _parseLocal(String? value) {
  if (value == null) return null;
  return DateTime.tryParse(value)?.toLocal();
}
