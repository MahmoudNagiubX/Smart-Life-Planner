import 'package:flutter_test/flutter_test.dart';
import 'package:smart_life_planner/features/notes/models/note_model.dart';
import 'package:smart_life_planner/features/notes/services/note_ocr_service.dart';

void main() {
  group('OCR attachment selection', () {
    test('supports image mime types and common image file extensions', () {
      expect(
        isOcrSupportedAttachment(
          const NoteAttachmentModel(
            localPath: '/tmp/photo.jpg',
            fileType: 'image/jpeg',
            fileSize: 10,
          ),
        ),
        isTrue,
      );
      expect(
        isOcrSupportedAttachment(
          const NoteAttachmentModel(
            localPath: '/tmp/photo.png',
            fileType: 'application/octet-stream',
            fileSize: 10,
          ),
        ),
        isTrue,
      );
      expect(
        isOcrSupportedAttachment(
          const NoteAttachmentModel(
            localPath: '/tmp/document.pdf',
            fileType: 'application/pdf',
            fileSize: 10,
          ),
        ),
        isFalse,
      );
    });

    test('chooses the first supported local image attachment', () {
      final attachment = firstLocalOcrAttachment([
        const NoteAttachmentModel(
          fileUrl: 'https://example.com/photo.jpg',
          fileType: 'image/jpeg',
          fileSize: 10,
        ),
        const NoteAttachmentModel(
          localPath: '/tmp/document.pdf',
          fileType: 'application/pdf',
          fileSize: 10,
        ),
        const NoteAttachmentModel(
          id: 'image-1',
          localPath: '/tmp/photo.webp',
          fileType: 'application/octet-stream',
          fileSize: 10,
        ),
      ]);

      expect(attachment?.id, 'image-1');
    });
  });
}
