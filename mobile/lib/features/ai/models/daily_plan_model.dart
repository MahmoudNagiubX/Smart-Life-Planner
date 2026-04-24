class DailyPlanItem {
  final String taskId;
  final String title;
  final String suggestedTime;
  final int durationMinutes;
  final String reason;

  DailyPlanItem({
    required this.taskId,
    required this.title,
    required this.suggestedTime,
    required this.durationMinutes,
    required this.reason,
  });

  factory DailyPlanItem.fromJson(Map<String, dynamic> json) {
    return DailyPlanItem(
      taskId: json['task_id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled task',
      suggestedTime: json['suggested_time'] as String? ?? '09:00',
      durationMinutes: _readInt(json['duration_minutes']) ?? 30,
      reason: json['reason'] as String? ?? '',
    );
  }

  static int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class DailyPlanData {
  final String date;
  final List<DailyPlanItem> plan;

  DailyPlanData({required this.date, required this.plan});

  factory DailyPlanData.fromJson(Map<String, dynamic> json) {
    return DailyPlanData(
      date: json['date'] as String? ?? '',
      plan: (json['plan'] as List<dynamic>? ?? const [])
          .map((i) => DailyPlanItem.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }
}

class NextActionData {
  final String? taskId;
  final String? title;
  final String reason;
  final String confidence;

  NextActionData({
    this.taskId,
    this.title,
    required this.reason,
    required this.confidence,
  });

  factory NextActionData.fromJson(Map<String, dynamic> json) {
    return NextActionData(
      taskId: json['task_id'] as String?,
      title: json['title'] as String?,
      reason: json['reason'] as String? ?? 'No suggestion available',
      confidence: json['confidence'] as String? ?? 'low',
    );
  }
}
