import 'package:flutter_test/flutter_test.dart';
import 'package:smart_life_planner/features/notes/models/smart_note_processing_model.dart';

void main() {
  test('smart note state exposes processing and preview phases', () {
    final processing = SmartNoteProcessingState.processing(
      jobType: SmartNoteJobType.ocr,
      noteId: 'note-1',
      inputAttachmentId: 'attachment-1',
    );

    expect(processing.isProcessing, isTrue);
    expect(processing.hasPreview, isFalse);

    final preview = SmartNoteProcessingState.preview(
      jobType: SmartNoteJobType.ocr,
      noteId: 'note-1',
      previewText: 'Recognized text',
      previewJson: const {'confidence': 0.8},
    );

    expect(preview.hasPreview, isTrue);
    expect(preview.previewText, 'Recognized text');
  });

  test('smart note job type maps to backend contract keys', () {
    expect(smartNoteJobTypeToApi(SmartNoteJobType.ocr), 'ocr');
    expect(
      smartNoteJobTypeToApi(SmartNoteJobType.actionExtraction),
      'action_extraction',
    );
    expect(
      smartNoteJobTypeFromApi('handwriting'),
      SmartNoteJobType.handwriting,
    );
  });
}
