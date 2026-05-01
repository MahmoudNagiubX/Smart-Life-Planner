class GoalRoadmapMilestone {
  final int index;
  final String title;
  final String description;
  final int targetWeek;

  const GoalRoadmapMilestone({
    required this.index,
    required this.title,
    required this.description,
    required this.targetWeek,
  });

  factory GoalRoadmapMilestone.fromJson(Map<String, dynamic> json) {
    return GoalRoadmapMilestone(
      index: json['index'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      targetWeek: json['target_week'] as int? ?? 1,
    );
  }
}

class GoalRoadmapTask {
  final int milestoneIndex;
  final String title;
  final String description;
  final String priority;
  final int estimatedMinutes;
  final int suggestedWeek;

  const GoalRoadmapTask({
    required this.milestoneIndex,
    required this.title,
    required this.description,
    required this.priority,
    required this.estimatedMinutes,
    required this.suggestedWeek,
  });

  factory GoalRoadmapTask.fromJson(Map<String, dynamic> json) {
    return GoalRoadmapTask(
      milestoneIndex: json['milestone_index'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      priority: json['priority'] as String? ?? 'medium',
      estimatedMinutes: json['estimated_minutes'] as int? ?? 30,
      suggestedWeek: json['suggested_week'] as int? ?? 1,
    );
  }

  GoalRoadmapTask copyWith({String? title, String? description}) {
    return GoalRoadmapTask(
      milestoneIndex: milestoneIndex,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority,
      estimatedMinutes: estimatedMinutes,
      suggestedWeek: suggestedWeek,
    );
  }
}

class GoalRoadmapResult {
  final String goalTitle;
  final String? deadline;
  final List<GoalRoadmapMilestone> milestones;
  final List<GoalRoadmapTask> suggestedTasks;
  final String scheduleSuggestion;
  final String confidence;
  final bool requiresConfirmation;
  final bool fallbackUsed;

  const GoalRoadmapResult({
    required this.goalTitle,
    this.deadline,
    required this.milestones,
    required this.suggestedTasks,
    required this.scheduleSuggestion,
    required this.confidence,
    required this.requiresConfirmation,
    required this.fallbackUsed,
  });

  factory GoalRoadmapResult.fromJson(Map<String, dynamic> json) {
    return GoalRoadmapResult(
      goalTitle: json['goal_title'] as String? ?? '',
      deadline: json['deadline'] as String?,
      milestones: (json['milestones'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                GoalRoadmapMilestone.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      suggestedTasks: (json['suggested_tasks'] as List<dynamic>? ?? const [])
          .map((item) => GoalRoadmapTask.fromJson(item as Map<String, dynamic>))
          .toList(),
      scheduleSuggestion: json['schedule_suggestion'] as String? ?? '',
      confidence: json['confidence'] as String? ?? 'low',
      requiresConfirmation: json['requires_confirmation'] as bool? ?? true,
      fallbackUsed: json['fallback_used'] as bool? ?? true,
    );
  }
}
