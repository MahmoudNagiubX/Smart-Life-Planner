import 'package:flutter_test/flutter_test.dart';
import 'package:smart_life_planner/features/prayer/models/dhikr_reminder_model.dart';

void main() {
  test('DhikrReminderModel parses backend reminder contract', () {
    final reminder = DhikrReminderModel.fromJson(const {
      'id': 'dhikr-1',
      'title': 'Morning dhikr',
      'phrase': 'SubhanAllah',
      'schedule_time': '07:30:00',
      'recurrence_rule': 'daily',
      'timezone': 'Africa/Cairo',
      'enabled': true,
    });

    expect(reminder.id, 'dhikr-1');
    expect(reminder.title, 'Morning dhikr');
    expect(reminder.scheduleTime, '07:30:00');
    expect(reminder.enabled, isTrue);
  });

  test('DhikrReminderDraft serializes create payload', () {
    const draft = DhikrReminderDraft(
      title: 'Evening dhikr',
      scheduleTime: '19:00:00',
      recurrenceRule: 'weekdays',
      timezone: 'UTC',
    );

    expect(draft.toJson()['title'], 'Evening dhikr');
    expect(draft.toJson()['schedule_time'], '19:00:00');
    expect(draft.toJson()['recurrence_rule'], 'weekdays');
  });
}
