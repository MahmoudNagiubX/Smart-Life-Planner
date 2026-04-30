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
    await _runImageTextExtraction(
      note: note,
      jobType: SmartNoteJobType.ocr,
      missingImageMessage:
          'Attach a local image to this note before running OCR.',
      emptyResultMessage:
          'No readable text was found in this image. Try a clearer photo.',
      failureMessage: 'OCR failed. Please try again with a clearer image.',
      sourceMode: 'ocr',
    );
  }

  Future<void> runHandwriting(NoteModel note) async {
    await _runImageTextExtraction(
      note: note,
      jobType: SmartNoteJobType.handwriting,
      missingImageMessage:
          'Attach a local handwriting image to this note first.',
      emptyResultMessage:
          'No readable handwriting was found. Try a clearer, brighter image.',
      failureMessage: 'Handwriting extraction failed. Try a clearer image.',
      sourceMode: 'handwriting_best_effort',
    );
  }

  Future<void> _runImageTextExtraction({
    required NoteModel note,
    required SmartNoteJobType jobType,
    required String missingImageMessage,
    required String emptyResultMessage,
    required String failureMessage,
    required String sourceMode,
  }) async {
    final attachment = firstLocalOcrAttachment(note.attachments);
    if (attachment == null) {
      state = SmartNoteProcessingState.fail(
        jobType: jobType,
        noteId: note.id,
        errorMessage: missingImageMessage,
      );
      return;
    }

    state = SmartNoteProcessingState.processing(
      jobType: jobType,
      noteId: note.id,
      inputAttachmentId: attachment.id,
    );

    try {
      final result = await _ref
          .read(noteOcrServiceProvider)
          .extractTextFromImagePath(attachment.localPath!);
      if (!result.hasText) {
        state = SmartNoteProcessingState.fail(
          jobType: jobType,
          noteId: note.id,
          errorMessage: emptyResultMessage,
        );
        return;
      }

      state = SmartNoteProcessingState.preview(
        jobType: jobType,
        noteId: note.id,
        inputAttachmentId: attachment.id,
        previewText: result.text,
        previewJson: {
          'block_count': result.blockCount,
          'line_count': result.lineCount,
          'average_confidence': result.averageConfidence,
          'confidence_available': result.averageConfidence != null,
          'source': 'on_device_mlkit_text_recognition',
          'mode': sourceMode,
          'source_path': result.sourcePath,
        },
      );
    } on NoteOcrException catch (e) {
      state = SmartNoteProcessingState.fail(
        jobType: jobType,
        noteId: note.id,
        errorMessage: e.message,
      );
    } catch (_) {
      state = SmartNoteProcessingState.fail(
        jobType: jobType,
        noteId: note.id,
        errorMessage: failureMessage,
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
