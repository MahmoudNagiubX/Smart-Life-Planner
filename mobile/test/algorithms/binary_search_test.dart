import 'package:flutter_test/flutter_test.dart';
import 'package:smart_life_planner/core/algorithms/algorithm_demo_models.dart';
import 'package:smart_life_planner/core/algorithms/binary_search.dart';

void main() {
  group('Binary Search academic demo', () {
    const tasks = [
      AlgorithmDemoTask(
        id: 'A001',
        title: 'First',
        priorityScore: 1,
        estimatedMinutes: 10,
      ),
      AlgorithmDemoTask(
        id: 'A002',
        title: 'Second',
        priorityScore: 2,
        estimatedMinutes: 20,
      ),
      AlgorithmDemoTask(
        id: 'A003',
        title: 'Third',
        priorityScore: 3,
        estimatedMinutes: 30,
      ),
    ];

    test('finds existing item', () {
      final result = binarySearchTaskById(tasks, 'A002');

      expect(result?.title, 'Second');
    });

    test('returns null and -1 for missing item', () {
      final result = binarySearchTaskById(tasks, 'A004');
      final index = binarySearchIndex<int>([1, 2, 3], (item) => item - 4);

      expect(result, isNull);
      expect(index, -1);
    });

    test('handles empty list', () {
      expect(binarySearchTaskById(const [], 'A001'), isNull);
    });

    test('handles first and last elements', () {
      expect(binarySearchTaskById(tasks, 'A001')?.title, 'First');
      expect(binarySearchTaskById(tasks, 'A003')?.title, 'Third');
    });
  });
}
