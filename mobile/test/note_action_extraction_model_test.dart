import 'package:flutter_test/flutter_test.dart';
import 'package:smart_life_planner/features/notes/models/note_action_extraction_model.dart';

void main() {
  test('action extraction result parses editable suggestions', () {
    final result = NoteActionExtractionResult.fromJson(const {
      'extracted_items': [
        {
          'item_type': 'task',
          'title': 'Submit report',
          'due_date': '2026-05-01T20:00:00+00:00',
          'reminder_time': '2026-05-01T20:00:00+00:00',
          'confidence': 'medium',
          'reason': 'Action wording detected.',
          'requires_confirmation': true,
        },
        {'item_type': 'task', 'title': ''},
      ],
      'requires_confirmation': true,
      'fallback_used': true,
      'safety_notes': 'Review first.',
    });

    expect(result.extractedItems, hasLength(1));
    expect(result.extractedItems.single.title, 'Submit report');
    expect(result.fallbackUsed, isTrue);
    expect(result.toJson()['extracted_items'], isA<List<dynamic>>());
  });
}
