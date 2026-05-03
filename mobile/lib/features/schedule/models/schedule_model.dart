class ScheduleBlockModel {
  final String id;
  final String? taskId;
  final String blockType;
  final String title;
  final String startTime;
  final String endTime;
  final bool isLocked;
  final bool isCompleted;
  final String scheduleDate;
  final String? explanation;

  ScheduleBlockModel({
    required this.id,
    this.taskId,
    required this.blockType,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.isLocked,
    required this.isCompleted,
    required this.scheduleDate,
    this.explanation,
  });

  factory ScheduleBlockModel.fromJson(Map<String, dynamic> json) {
    return ScheduleBlockModel(
      id: json['id'] as String? ?? '',
      taskId: json['task_id'] as String?,
      blockType: json['block_type'] as String? ?? 'task',
      title: json['title'] as String? ?? 'Untitled block',
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
      isLocked: json['is_locked'] as bool? ?? false,
      isCompleted: json['is_completed'] as bool? ?? false,
      scheduleDate: json['schedule_date'] as String? ?? '',
      explanation: json['explanation'] as String?,
    );
  }

  int get durationMinutes {
    final start = DateTime.tryParse(startTime);
    final end = DateTime.tryParse(endTime);
    if (start == null || end == null) return 0;
    return end.difference(start).inMinutes.clamp(0, 1440);
  }
}

class DailyScheduleModel {
  final String date;
  final List<ScheduleBlockModel> blocks;
  final bool overloadDetected;
  final String? overloadMessage;
  final int totalScheduledMinutes;
  final int availableMinutes;

  DailyScheduleModel({
    required this.date,
    required this.blocks,
    required this.overloadDetected,
    this.overloadMessage,
    required this.totalScheduledMinutes,
    required this.availableMinutes,
  });

  factory DailyScheduleModel.fromJson(Map<String, dynamic> json) {
    return DailyScheduleModel(
      date: json['date'] as String? ?? '',
      blocks: (json['blocks'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ScheduleBlockModel.fromJson)
          .toList(),
      overloadDetected: json['overload_detected'] as bool? ?? false,
      overloadMessage: json['overload_message'] as String?,
      totalScheduledMinutes: _readInt(json['total_scheduled_minutes']) ?? 0,
      availableMinutes: _readInt(json['available_minutes']) ?? 480,
    );
  }
}

int? _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value);
  return null;
}
