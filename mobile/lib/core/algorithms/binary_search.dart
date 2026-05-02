import 'algorithm_demo_models.dart';

/// Algorithm: Binary Search
/// Type: Divide-and-conquer searching algorithm
/// Time Complexity: O(log n)
/// Space Complexity: O(1) iterative
/// App Connection:
/// Demonstrates efficient lookup in sorted task/note/reminder collections.
int binarySearchIndex<T>(
  List<T> sortedItems,
  int Function(T item) compareItemToTarget,
) {
  var low = 0;
  var high = sortedItems.length - 1;

  while (low <= high) {
    final mid = low + ((high - low) ~/ 2);
    final comparison = compareItemToTarget(sortedItems[mid]);

    if (comparison == 0) {
      return mid;
    }
    if (comparison < 0) {
      low = mid + 1;
    } else {
      high = mid - 1;
    }
  }

  return -1;
}

AlgorithmDemoTask? binarySearchTaskById(
  List<AlgorithmDemoTask> sortedTasks,
  String targetId,
) {
  final index = binarySearchIndex<AlgorithmDemoTask>(
    sortedTasks,
    (task) => task.id.compareTo(targetId),
  );

  return index == -1 ? null : sortedTasks[index];
}
