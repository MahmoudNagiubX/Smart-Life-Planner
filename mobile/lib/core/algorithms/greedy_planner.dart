import 'algorithm_demo_models.dart';

/// Algorithm: Greedy Algorithm
/// Type: Optimization heuristic
/// Time Complexity: O(n log n) if sorting is used
/// Space Complexity: O(n) for the ranked copy and selected result
/// App Connection:
/// Used to demonstrate how Smart Life Planner can select the best tasks
/// for today based on priority, urgency, and available time.
List<AlgorithmDemoTask> greedySelectTasksForAvailableTime(
  List<AlgorithmDemoTask> tasks,
  int availableMinutes,
) {
  if (availableMinutes <= 0 || tasks.isEmpty) {
    return const [];
  }

  final ranked = List<AlgorithmDemoTask>.of(tasks)
    ..sort((left, right) {
      final scoreComparison = right.academicGreedyScore.compareTo(
        left.academicGreedyScore,
      );
      if (scoreComparison != 0) return scoreComparison;

      final durationComparison = left.estimatedMinutes.compareTo(
        right.estimatedMinutes,
      );
      if (durationComparison != 0) return durationComparison;

      return left.title.compareTo(right.title);
    });

  final selected = <AlgorithmDemoTask>[];
  var remainingMinutes = availableMinutes;

  for (final task in ranked) {
    if (task.estimatedMinutes <= 0) continue;
    if (task.estimatedMinutes <= remainingMinutes) {
      selected.add(task);
      remainingMinutes -= task.estimatedMinutes;
    }
  }

  return selected;
}
