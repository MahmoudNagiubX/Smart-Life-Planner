import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/note_model.dart';
import '../models/smart_note_processing_model.dart';
import '../services/note_ocr_service.dart';

final noteOcrServiceProvider = Provider<NoteOcrService>((ref) {
  return NoteOcrService();
});

class SmartNoteProcessingNotifier
    extends StateNotifier<SmartNoteProcessingState> {
  final Ref _ref;

  SmartNoteProcessingNotifier(this._ref)
    : super(const SmartNoteProcessingState());

  Future<void> runOcr(NoteModel note) async {
    final attachment = firstLocalOcrAttachment(note.attachments);
    if (attachment == null) {
      state = SmartNoteProcessingState.fail(
        jobType: SmartNoteJobType.ocr,
        noteId: note.id,
        errorMessage: 'Attach a local image to this note before running OCR.',
      );
      return;
    }

    state = SmartNoteProcessingState.processing(
      jobType: SmartNoteJobType.ocr,
      noteId: note.id,
      inputAttachmentId: attachment.id,
    );

    try {
      final result = await _ref
          .read(noteOcrServiceProvider)
          .extractTextFromImagePath(attachment.localPath!);
      if (!result.hasText) {
        state = SmartNoteProcessingState.fail(
          jobType: SmartNoteJobType.ocr,
          noteId: note.id,
          errorMessage:
              'No readable text was found in this image. Try a clearer photo.',
        );
        return;
      }

      state = SmartNoteProcessingState.preview(
        jobType: SmartNoteJobType.ocr,
        noteId: note.id,
        inputAttachmentId: attachment.id,
        previewText: result.text,
        previewJson: {
          'block_count': result.blockCount,
          'source': 'on_device_mlkit',
          'source_path': result.sourcePath,
        },
      );
    } on NoteOcrException catch (e) {
      state = SmartNoteProcessingState.fail(
        jobType: SmartNoteJobType.ocr,
        noteId: note.id,
        errorMessage: e.message,
      );
    } catch (_) {
      state = SmartNoteProcessingState.fail(
        jobType: SmartNoteJobType.ocr,
        noteId: note.id,
        errorMessage: 'OCR failed. Please try again with a clearer image.',
      );
    }
  }

  void markSuccess({
    required SmartNoteJobType jobType,
    required String noteId,
  }) {
    state = SmartNoteProcessingState.success(jobType: jobType, noteId: noteId);
  }

  void reset() {
    state = const SmartNoteProcessingState();
  }
}

final smartNoteProcessingProvider =
    StateNotifierProvider<
      SmartNoteProcessingNotifier,
      SmartNoteProcessingState
    >((ref) {
      return SmartNoteProcessingNotifier(ref);
    });
