import 'package:flutter_test/flutter_test.dart';
import 'package:smart_life_planner/features/notes/models/note_model.dart';

void main() {
  test('note model tolerates legacy null optional fields', () {
    final note = NoteModel.fromJson(const {
      'id': 'note-1',
      'content': 'Keep this text',
      'note_type': null,
      'tags': null,
      'checklist_items': null,
      'structured_blocks': null,
      'attachments': null,
      'color_key': null,
      'is_pinned': null,
      'is_archived': null,
      'source_type': null,
      'created_at': '2026-05-02T10:00:00Z',
      'updated_at': '2026-05-02T10:00:00Z',
    });

    expect(note.id, 'note-1');
    expect(note.content, 'Keep this text');
    expect(note.noteType, 'text');
    expect(note.tags, isEmpty);
    expect(note.checklistItems, isEmpty);
    expect(note.structuredBlocks, isEmpty);
    expect(note.attachments, isEmpty);
    expect(note.isPinned, isFalse);
    expect(note.isArchived, isFalse);
    expect(note.sourceType, 'manual');
  });

  test('note model parses loose checklist and attachment values', () {
    final note = NoteModel.fromJson(const {
      'id': 'note-2',
      'content': 'Checklist',
      'note_type': 'checklist',
      'checklist_items': [
        {'id': 7, 'text': 'Buy milk', 'is_completed': 'true'},
      ],
      'attachments': [
        {'id': 'a1', 'file_type': null, 'file_size': '12'},
      ],
      'is_pinned': 1,
      'is_archived': 0,
      'created_at': '2026-05-02T10:00:00Z',
      'updated_at': '2026-05-02T10:00:00Z',
    });

    expect(note.checklistItems.single.id, '7');
    expect(note.checklistItems.single.isCompleted, isTrue);
    expect(note.attachments.single.fileType, 'image/jpeg');
    expect(note.attachments.single.fileSize, 12);
    expect(note.isPinned, isTrue);
    expect(note.isArchived, isFalse);
  });
}
