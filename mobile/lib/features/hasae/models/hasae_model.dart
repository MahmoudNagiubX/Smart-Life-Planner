class HasaeNextAction {
  final String? taskId;
  final String? title;
  final double score;
  final String reason;
  final Map<String, dynamic>? components;
  final HasaeAlternative? alternative;
  final int minutesUntilPrayer;
  final String? nextPrayer;

  HasaeNextAction({
    this.taskId,
    this.title,
    required this.score,
    required this.reason,
    this.components,
    this.alternative,
    required this.minutesUntilPrayer,
    this.nextPrayer,
  });

  factory HasaeNextAction.fromJson(Map<String, dynamic> json) {
    return HasaeNextAction(
      taskId: json['task_id'] as String?,
      title: json['title'] as String?,
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      reason: json['reason'] as String? ?? '',
      components: json['components'] as Map<String, dynamic>?,
      alternative: json['alternative'] != null
          ? HasaeAlternative.fromJson(
              json['alternative'] as Map<String, dynamic>)
          : null,
      minutesUntilPrayer: json['minutes_until_prayer'] as int? ?? 120,
      nextPrayer: json['next_prayer'] as String?,
    );
  }
}

class HasaeAlternative {
  final String? taskId;
  final String? title;
  final double score;

  HasaeAlternative({this.taskId, this.title, required this.score});

  factory HasaeAlternative.fromJson(Map<String, dynamic> json) {
    return HasaeAlternative(
      taskId: json['task_id'] as String?,
      title: json['title'] as String?,
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class HasaeOverload {
  final bool overloadDetected;
  final double loadRatio;
  final int totalNeededMinutes;
  final int availableMinutes;
  final int overloadedByMinutes;
  final String? message;

  HasaeOverload({
    required this.overloadDetected,
    required this.loadRatio,
    required this.totalNeededMinutes,
    required this.availableMinutes,
    required this.overloadedByMinutes,
    this.message,
  });

  factory HasaeOverload.fromJson(Map<String, dynamic> json) {
    return HasaeOverload(
      overloadDetected: json['overload_detected'] as bool? ?? false,
      loadRatio: (json['load_ratio'] as num?)?.toDouble() ?? 0.0,
      totalNeededMinutes: json['total_needed_minutes'] as int? ?? 0,
      availableMinutes: json['available_minutes'] as int? ?? 960,
      overloadedByMinutes: json['overloaded_by_minutes'] as int? ?? 0,
      message: json['message'] as String?,
    );
  }
}

class HasaeRankedTask {
  final String taskId;
  final String title;
  final double score;
  final String explanation;
  final Map<String, dynamic> components;

  HasaeRankedTask({
    required this.taskId,
    required this.title,
    required this.score,
    required this.explanation,
    required this.components,
  });

  factory HasaeRankedTask.fromJson(Map<String, dynamic> json) {
    return HasaeRankedTask(
      taskId: json['task_id'] as String,
      title: json['title'] as String,
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      explanation: json['explanation'] as String? ?? '',
      components:
          json['components'] as Map<String, dynamic>? ?? {},
    );
  }
}

class HasaePlanBlock {
  final String? id;
  final String? taskId;
  final String blockType;
  final String title;
  final String startTime;
  final String endTime;
  final bool isLocked;
  final String? explanation;
  final double? score;

  HasaePlanBlock({
    this.id,
    this.taskId,
    required this.blockType,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.isLocked,
    this.explanation,
    this.score,
  });

  factory HasaePlanBlock.fromJson(Map<String, dynamic> json) {
    return HasaePlanBlock(
      id: json['id'] as String?,
      taskId: json['task_id'] as String?,
      blockType: json['block_type'] as String? ?? 'task',
      title: json['title'] as String? ?? 'Untitled block',
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
      isLocked: json['is_locked'] as bool? ?? false,
      explanation: json['explanation'] as String?,
      score: (json['score'] as num?)?.toDouble(),
    );
  }

  int get durationMinutes {
    final start = DateTime.tryParse(startTime);
    final end = DateTime.tryParse(endTime);
    if (start == null || end == null) return 0;
    return end.difference(start).inMinutes.clamp(0, 1440);
  }

  String get timeLabel {
    final start = DateTime.tryParse(startTime)?.toLocal();
    if (start == null) return '--:--';
    final h = start.hour.toString().padLeft(2, '0');
    final m = start.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class HasaePlanTask {
  final String taskId;
  final String title;
  final double score;
  final String reason;
  final int durationMinutes;

  HasaePlanTask({
    required this.taskId,
    required this.title,
    required this.score,
    required this.reason,
    required this.durationMinutes,
  });

  factory HasaePlanTask.fromJson(Map<String, dynamic> json) {
    return HasaePlanTask(
      taskId: json['task_id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled task',
      score: (json['score'] as num?)?.toDouble() ?? 0,
      reason: json['reason'] as String? ?? '',
      durationMinutes: _readInt(json['duration_minutes']) ?? 30,
    );
  }
}

class HasaeSkippedTask {
  final String taskId;
  final String title;
  final String reason;

  HasaeSkippedTask({
    required this.taskId,
    required this.title,
    required this.reason,
  });

  factory HasaeSkippedTask.fromJson(Map<String, dynamic> json) {
    return HasaeSkippedTask(
      taskId: json['task_id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled task',
      reason: json['reason'] as String? ?? '',
    );
  }
}

class HasaeDailyPlan {
  final String date;
  final List<HasaePlanBlock> blocks;
  final List<HasaePlanTask> selectedTasks;
  final List<HasaeSkippedTask> skippedTasks;
  final bool overloadWarning;
  final String? overloadMessage;
  final int totalTaskMinutes;
  final int scheduledTaskMinutes;
  final int availableMinutes;
  final String explanation;
  final bool requiresConfirmation;
  final bool persisted;

  HasaeDailyPlan({
    required this.date,
    required this.blocks,
    required this.selectedTasks,
    required this.skippedTasks,
    required this.overloadWarning,
    this.overloadMessage,
    required this.totalTaskMinutes,
    required this.scheduledTaskMinutes,
    required this.availableMinutes,
    required this.explanation,
    required this.requiresConfirmation,
    required this.persisted,
  });

  factory HasaeDailyPlan.fromJson(Map<String, dynamic> json) {
    return HasaeDailyPlan(
      date: json['date'] as String? ?? '',
      blocks: (json['blocks'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(HasaePlanBlock.fromJson)
          .toList(),
      selectedTasks:
          (json['selected_tasks'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(HasaePlanTask.fromJson)
              .toList(),
      skippedTasks:
          (json['skipped_tasks'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(HasaeSkippedTask.fromJson)
              .toList(),
      overloadWarning: json['overload_warning'] as bool? ?? false,
      overloadMessage: json['overload_message'] as String?,
      totalTaskMinutes: _readInt(json['total_task_minutes']) ?? 0,
      scheduledTaskMinutes: _readInt(json['scheduled_task_minutes']) ?? 0,
      availableMinutes: _readInt(json['available_minutes']) ?? 0,
      explanation: json['explanation'] as String? ?? '',
      requiresConfirmation: json['requires_confirmation'] as bool? ?? true,
      persisted: json['persisted'] as bool? ?? false,
    );
  }
}

int? _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value);
  return null;
}
