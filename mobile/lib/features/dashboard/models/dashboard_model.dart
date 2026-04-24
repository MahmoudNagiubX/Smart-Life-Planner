class DashboardTopTask {
  final String id;
  final String title;
  final String priority;
  final String? dueAt;
  final String status;

  DashboardTopTask({
    required this.id,
    required this.title,
    required this.priority,
    this.dueAt,
    required this.status,
  });

  factory DashboardTopTask.fromJson(Map<String, dynamic> json) {
    return DashboardTopTask(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled task',
      priority: json['priority'] as String? ?? 'medium',
      dueAt: json['due_at'] as String?,
      status: json['status'] as String? ?? 'pending',
    );
  }
}

class PrayerProgress {
  final int completed;
  final int total;

  PrayerProgress({required this.completed, required this.total});

  factory PrayerProgress.fromJson(Map<String, dynamic> json) {
    return PrayerProgress(
      completed: _readInt(json['completed']) ?? 0,
      total: _readInt(json['total']) ?? 5,
    );
  }
}

class DashboardData {
  final int pendingCount;
  final int completedToday;
  final PrayerProgress prayerProgress;
  final List<DashboardTopTask> topTasks;

  DashboardData({
    required this.pendingCount,
    required this.completedToday,
    required this.prayerProgress,
    required this.topTasks,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      pendingCount: _readInt(json['pending_count']) ?? 0,
      completedToday: _readInt(json['completed_today']) ?? 0,
      prayerProgress: PrayerProgress.fromJson(
        json['prayer_progress'] as Map<String, dynamic>? ?? const {},
      ),
      topTasks: (json['top_tasks'] as List<dynamic>? ?? const [])
          .map((t) => DashboardTopTask.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }
}

int? _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value);
  return null;
}
