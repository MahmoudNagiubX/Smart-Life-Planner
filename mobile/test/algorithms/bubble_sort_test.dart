import 'package:flutter_test/flutter_test.dart';
import 'package:smart_life_planner/core/algorithms/algorithm_demo_models.dart';
import 'package:smart_life_planner/core/algorithms/bubble_sort.dart';

void main() {
  group('Bubble Sort academic demo', () {
    test('sorts priorities descending', () {
      final tasks = [
        const AlgorithmDemoTask(
          id: '2',
          title: 'Medium',
          priorityScore: 2,
          estimatedMinutes: 20,
        ),
        const AlgorithmDemoTask(
          id: '1',
          title: 'High',
          priorityScore: 5,
          estimatedMinutes: 20,
        ),
        const AlgorithmDemoTask(
          id: '3',
          title: 'Low',
          priorityScore: 1,
          estimatedMinutes: 20,
        ),
      ];

      final sorted = bubbleSortTasksByPriority(tasks);

      expect(sorted.map((task) => task.priorityScore), [5, 2, 1]);
      expect(tasks.map((task) => task.priorityScore), [2, 5, 1]);
    });

    test('sorts priorities ascending', () {
      final tasks = [
        const AlgorithmDemoTask(
          id: '1',
          title: 'High',
          priorityScore: 5,
          estimatedMinutes: 20,
        ),
        const AlgorithmDemoTask(
          id: '2',
          title: 'Low',
          priorityScore: 1,
          estimatedMinutes: 20,
        ),
      ];

      final sorted = bubbleSortTasksByPriority(
        tasks,
        order: BubbleSortOrder.ascending,
      );

      expect(sorted.map((task) => task.priorityScore), [1, 5]);
    });

    test('handles empty list', () {
      expect(bubbleSortTasksByPriority(const []), isEmpty);
    });

    test('handles single item', () {
      final task = const AlgorithmDemoTask(
        id: '1',
        title: 'Only task',
        priorityScore: 3,
        estimatedMinutes: 15,
      );

      expect(bubbleSortTasksByPriority([task]), [task]);
    });

    test('handles already sorted list', () {
      final tasks = [
        const AlgorithmDemoTask(
          id: '1',
          title: 'First',
          priorityScore: 3,
          estimatedMinutes: 15,
        ),
        const AlgorithmDemoTask(
          id: '2',
          title: 'Second',
          priorityScore: 2,
          estimatedMinutes: 15,
        ),
      ];

      final sorted = bubbleSortTasksByPriority(tasks);

      expect(sorted.map((task) => task.id), ['1', '2']);
    });
  });
}
