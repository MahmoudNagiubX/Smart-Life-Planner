import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/voice_result_model.dart';
import '../models/voice_note_model.dart';

class VoiceApiService {
  final ApiClient _apiClient;

  VoiceApiService(this._apiClient);

  Future<VoiceParseResult> transcribeAndParse({
    required String audioPath,
    String language = 'auto',
  }) async {
    final file = File(audioPath);
    final bytes = await file.readAsBytes();

    final formData = FormData.fromMap({
      'audio': MultipartFile.fromBytes(
        bytes,
        filename: file.uri.pathSegments.last,
      ),
      'language': language,
    });

    final response = await _apiClient.dio.post(
      '/voice/transcribe-and-parse',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );

    return VoiceParseResult.fromJson(response.data as Map<String, dynamic>);
  }

  Future<BulkCreateResult> bulkCreateTasks(
    List<ParsedVoiceTaskModel> tasks,
  ) async {
    final tasksList = tasks
        .map(
          (t) => {
            'title': t.title,
            'description': t.description,
            'due_at': t.dueDate != null
                ? '${t.dueDate}T${t.dueTime ?? "00:00"}:00'
                : null,
            'priority': t.priority,
            'estimated_duration_minutes': t.estimatedDurationMinutes,
            'category': t.category,
            'subtasks': t.subtasks
                .map((s) => {'title': s.title, 'completed': s.completed})
                .toList(),
          },
        )
        .toList();

    final response = await _apiClient.dio.post(
      '/tasks/bulk-create',
      data: {'tasks': tasksList},
    );

    return BulkCreateResult.fromJson(response.data as Map<String, dynamic>);
  }

  Future<VoiceNoteResult> transcribeNote({
    required String audioPath,
    String language = 'auto',
  }) async {
    final file = File(audioPath);
    final bytes = await file.readAsBytes();

    final formData = FormData.fromMap({
      'audio': MultipartFile.fromBytes(
        bytes,
        filename: file.uri.pathSegments.last,
      ),
      'language': language,
    });

    final response = await _apiClient.dio.post(
      '/voice/transcribe-note',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );

    return VoiceNoteResult.fromJson(response.data as Map<String, dynamic>);
  }

  Future<VoiceNoteResult> transcribeNoteBytes({
    required Uint8List audioBytes,
    required String filename,
    String language = 'auto',
  }) async {
    final formData = FormData.fromMap({
      'audio': MultipartFile.fromBytes(audioBytes, filename: filename),
      'language': language,
    });

    final response = await _apiClient.dio.post(
      '/voice/transcribe-note',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );

    return VoiceNoteResult.fromJson(response.data as Map<String, dynamic>);
  }
}
