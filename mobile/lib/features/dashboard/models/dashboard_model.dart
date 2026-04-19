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
      id: json['id'] as String,
      title: json['title'] as String,
      priority: json['priority'] as String,
      dueAt: json['due_at'] as String?,
      status: json['status'] as String,
    );
  }
}

class DashboardData {
  final int pendingCount;
  final int completedToday;
  final List<DashboardTopTask> topTasks;

  DashboardData({
    required this.pendingCount,
    required this.completedToday,
    required this.topTasks,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      pendingCount: json['pending_count'] as int,
      completedToday: json['completed_today'] as int,
      topTasks: (json['top_tasks'] as List<dynamic>)
          .map((t) => DashboardTopTask.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }
}