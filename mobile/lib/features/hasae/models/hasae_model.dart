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