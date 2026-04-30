import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../models/note_model.dart';

class NoteOcrException implements Exception {
  final String message;

  const NoteOcrException(this.message);

  @override
  String toString() => message;
}

class NoteOcrResult {
  final String text;
  final int blockCount;
  final String sourcePath;

  const NoteOcrResult({
    required this.text,
    required this.blockCount,
    required this.sourcePath,
  });

  bool get hasText => text.trim().isNotEmpty;
}

bool isOcrSupportedAttachment(NoteAttachmentModel attachment) {
  final type = attachment.fileType.toLowerCase();
  final path = (attachment.localPath ?? attachment.fileUrl ?? '').toLowerCase();
  return type.startsWith('image/') ||
      path.endsWith('.jpg') ||
      path.endsWith('.jpeg') ||
      path.endsWith('.png') ||
      path.endsWith('.webp') ||
      path.endsWith('.heic');
}

NoteAttachmentModel? firstLocalOcrAttachment(
  List<NoteAttachmentModel> attachments,
) {
  for (final attachment in attachments) {
    final path = attachment.localPath;
    if (path != null &&
        path.trim().isNotEmpty &&
        isOcrSupportedAttachment(attachment)) {
      return attachment;
    }
  }
  return null;
}

class NoteOcrService {
  Future<NoteOcrResult> extractTextFromImagePath(String imagePath) async {
    final trimmedPath = imagePath.trim();
    if (trimmedPath.isEmpty) {
      throw const NoteOcrException('No local image was selected for OCR.');
    }

    final file = File(trimmedPath);
    if (!await file.exists()) {
      throw const NoteOcrException(
        'This image is no longer available on this device.',
      );
    }

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFilePath(trimmedPath);
      final recognizedText = await recognizer.processImage(inputImage);
      return NoteOcrResult(
        text: recognizedText.text.trim(),
        blockCount: recognizedText.blocks.length,
        sourcePath: trimmedPath,
      );
    } catch (_) {
      throw const NoteOcrException(
        'Could not read text from this image. Try a clearer photo.',
      );
    } finally {
      await recognizer.close();
    }
  }
}
