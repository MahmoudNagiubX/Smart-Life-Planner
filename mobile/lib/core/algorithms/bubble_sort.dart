import 'algorithm_demo_models.dart';

enum BubbleSortOrder { ascending, descending }

/// Algorithm: Bubble Sort
/// Type: Comparison-based sorting algorithm
/// Time Complexity: O(n^2)
/// Space Complexity: O(1) extra algorithm space; returns a copied list for safety
/// App Connection:
/// Demonstrates how a small task list can be sorted by priority or due date.
/// Used for academic demonstration; production lists can use optimized sorting.
List<T> bubbleSort<T>(List<T> items, int Function(T left, T right) compare) {
  final sorted = List<T>.of(items);

  for (var pass = 0; pass < sorted.length - 1; pass++) {
    var swapped = false;

    for (var index = 0; index < sorted.length - pass - 1; index++) {
      if (compare(sorted[index], sorted[index + 1]) > 0) {
        final temp = sorted[index];
        sorted[index] = sorted[index + 1];
        sorted[index + 1] = temp;
        swapped = true;
      }
    }

    if (!swapped) break;
  }

  return sorted;
}

List<AlgorithmDemoTask> bubbleSortTasksByPriority(
  List<AlgorithmDemoTask> tasks, {
  BubbleSortOrder order = BubbleSortOrder.descending,
}) {
  return bubbleSort(tasks, (left, right) {
    final comparison = left.priorityScore.compareTo(right.priorityScore);
    return order == BubbleSortOrder.ascending ? comparison : -comparison;
  });
}

List<AlgorithmDemoTask> bubbleSortTasksByDueDate(
  List<AlgorithmDemoTask> tasks, {
  BubbleSortOrder order = BubbleSortOrder.ascending,
}) {
  return bubbleSort(tasks, (left, right) {
    final leftDate = left.dueDate ?? DateTime.fromMillisecondsSinceEpoch(0);
    final rightDate = right.dueDate ?? DateTime.fromMillisecondsSinceEpoch(0);
    final comparison = leftDate.compareTo(rightDate);
    return order == BubbleSortOrder.ascending ? comparison : -comparison;
  });
}
