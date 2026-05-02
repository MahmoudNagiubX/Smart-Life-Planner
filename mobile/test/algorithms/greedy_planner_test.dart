import 'package:flutter_test/flutter_test.dart';
import 'package:smart_life_planner/core/algorithms/algorithm_demo_models.dart';
import 'package:smart_life_planner/core/algorithms/greedy_planner.dart';

void main() {
  group('Greedy Planner academic demo', () {
    test('selects highest-priority tasks within available time', () {
      final tasks = [
        const AlgorithmDemoTask(
          id: 'low',
          title: 'Low value',
          priorityScore: 1,
          estimatedMinutes: 20,
          urgencyScore: 1,
        ),
        const AlgorithmDemoTask(
          id: 'high',
          title: 'High value',
          priorityScore: 5,
          estimatedMinutes: 30,
          urgencyScore: 2,
        ),
        const AlgorithmDemoTask(
          id: 'medium',
          title: 'Medium value',
          priorityScore: 3,
          estimatedMinutes: 30,
          urgencyScore: 1,
        ),
      ];

      final selected = greedySelectTasksForAvailableTime(tasks, 60);

      expect(selected.map((task) => task.id), ['high', 'medium']);
    });

    test('skips tasks that do not fit remaining time', () {
      final tasks = [
        const AlgorithmDemoTask(
          id: 'important-long',
          title: 'Important but long',
          priorityScore: 5,
          estimatedMinutes: 50,
        ),
        const AlgorithmDemoTask(
          id: 'quick',
          title: 'Quick task',
          priorityScore: 4,
          estimatedMinutes: 15,
        ),
        const AlgorithmDemoTask(
          id: 'medium',
          title: 'Medium task',
          priorityScore: 3,
          estimatedMinutes: 20,
        ),
      ];

      final selected = greedySelectTasksForAvailableTime(tasks, 35);

      expect(selected.map((task) => task.id), ['quick', 'medium']);
    });

    test('handles empty list', () {
      expect(greedySelectTasksForAvailableTime(const [], 30), isEmpty);
    });

    test('handles zero available time', () {
      final tasks = [
        const AlgorithmDemoTask(
          id: '1',
          title: 'Task',
          priorityScore: 3,
          estimatedMinutes: 10,
        ),
      ];

      expect(greedySelectTasksForAvailableTime(tasks, 0), isEmpty);
    });
  });
}
