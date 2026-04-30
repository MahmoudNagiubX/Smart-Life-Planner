import 'package:flutter_test/flutter_test.dart';
import 'package:smart_life_planner/features/tasks/models/project_timeline_model.dart';

void main() {
  test('ProjectTimelineModel parses backend timeline contract', () {
    final timeline = ProjectTimelineModel.fromJson(const {
      'project': {
        'id': 'project-1',
        'title': 'Capstone',
        'color_code': '#6C63FF',
        'status': 'active',
      },
      'task_bars': [
        {
          'task_id': 'task-1',
          'title': 'Write report',
          'status': 'pending',
          'priority': 'high',
          'project_id': 'project-1',
          'start_date': '2026-05-01T09:00:00Z',
          'due_date': '2026-05-01T11:00:00Z',
          'estimated_duration_minutes': 120,
          'dependency_ids': ['task-0'],
          'overdue': true,
          'conflict': true,
          'conflict_reasons': ['dependency_finishes_after_start'],
        },
      ],
      'dependencies': [
        {
          'task_id': 'task-1',
          'depends_on_task_id': 'task-0',
          'dependency_type': 'finish_to_start',
        },
      ],
    });

    final bar = timeline.taskBars.single;
    expect(timeline.project.title, 'Capstone');
    expect(bar.taskId, 'task-1');
    expect(bar.estimatedDurationMinutes, 120);
    expect(bar.dependencyIds, ['task-0']);
    expect(bar.overdue, isTrue);
    expect(bar.conflict, isTrue);
    expect(bar.startDateTime, isNotNull);
    expect(timeline.dependencies.single.dependsOnTaskId, 'task-0');
  });
}
