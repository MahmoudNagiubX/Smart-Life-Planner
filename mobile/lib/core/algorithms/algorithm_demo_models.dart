class AlgorithmDemoTask {
  final String id;
  final String title;
  final int priorityScore;
  final int estimatedMinutes;
  final DateTime? dueDate;
  final int urgencyScore;

  const AlgorithmDemoTask({
    required this.id,
    required this.title,
    required this.priorityScore,
    required this.estimatedMinutes,
    this.dueDate,
    this.urgencyScore = 0,
  });

  int get academicGreedyScore => priorityScore * 10 + urgencyScore;
}
