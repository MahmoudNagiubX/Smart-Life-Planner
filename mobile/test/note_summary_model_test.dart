import 'package:flutter_test/flutter_test.dart';
import 'package:smart_life_planner/features/notes/models/note_summary_model.dart';

void main() {
  test('summary styles map to backend contract keys', () {
    expect(NoteSummaryStyle.short.apiKey, 'short');
    expect(NoteSummaryStyle.bullets.apiKey, 'bullets');
    expect(NoteSummaryStyle.studyNotes.apiKey, 'study_notes');
    expect(NoteSummaryStyle.actionFocused.apiKey, 'action_focused');
    expect(noteSummaryStyleFromApi('study_notes'), NoteSummaryStyle.studyNotes);
  });

  test('note summary result parses backend response safely', () {
    final result = NoteSummaryResult.fromJson(const {
      'summary': 'Short summary',
      'confidence': 'medium',
      'fallback_used': true,
      'safety_notes': 'Review before inserting.',
    });

    expect(result.summary, 'Short summary');
    expect(result.confidence, 'medium');
    expect(result.fallbackUsed, isTrue);
    expect(result.safetyNotes, 'Review before inserting.');
  });
}
