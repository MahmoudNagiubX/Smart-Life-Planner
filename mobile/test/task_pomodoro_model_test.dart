import 'package:flutter_test/flutter_test.dart';
import 'package:smart_life_planner/features/tasks/models/task_model.dart';

void main() {
  test('TaskModel parses Pomodoro progress fields', () {
    final task = TaskModel.fromJson(const {
      'id': 'task-1',
      'title': 'Study chapter',
      'description': null,
      'priority': 'medium',
      'status': 'pending',
      'project_id': null,
      'category': null,
      'due_at': null,
      'reminder_at': null,
      'estimated_minutes': null,
      'estimated_pomodoros': 3,
      'completed_pomodoros': 1,
      'manual_order': 0,
      'is_deleted': false,
      'completed_at': null,
      'created_at': '2026-05-01T12:00:00Z',
      'updated_at': '2026-05-01T12:00:00Z',
      'subtasks': [],
    });

    expect(task.estimatedPomodoros, 3);
    expect(task.completedPomodoros, 1);
  });
}
