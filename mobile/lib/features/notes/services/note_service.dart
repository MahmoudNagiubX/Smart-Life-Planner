import '../../../core/network/api_client.dart';
import '../models/note_action_extraction_model.dart';
import '../models/note_model.dart';
import '../models/note_summary_model.dart';

class NoteService {
  final ApiClient _apiClient;

  NoteService(this._apiClient);

  Future<List<NoteModel>> getNotes({
    String? search,
    String? tag,
    bool isArchived = false,
    String? taskId,
  }) async {
    final queryParameters = <String, dynamic>{'is_archived': isArchived};
    if (search != null && search.isNotEmpty) {
      queryParameters['search'] = search;
    }
    if (tag != null && tag.isNotEmpty) {
      queryParameters['tag'] = tag;
    }
    if (taskId != null && taskId.isNotEmpty) {
      queryParameters['task_id'] = taskId;
    }

    final response = await _apiClient.dio.get(
      '/notes',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
    return (response.data as List<dynamic>)
        .map((n) => NoteModel.fromJson(n as Map<String, dynamic>))
        .toList();
  }

  Future<NoteModel> createNote({
    required String content,
    String? title,
    String? taskId,
    String noteType = 'text',
    List<String>? tags,
    List<ChecklistItemModel>? checklistItems,
    List<NoteStructuredBlockModel>? structuredBlocks,
    List<NoteAttachmentModel>? attachments,
    String? reminderAt,
    String sourceType = 'manual',
    String colorKey = 'default',
  }) async {
    final data = <String, dynamic>{
      'content': content,
      'note_type': noteType,
      'color_key': colorKey,
      'source_type': sourceType,
    };
    if (title != null && title.isNotEmpty) {
      data['title'] = title;
    }
    if (taskId != null && taskId.isNotEmpty) {
      data['task_id'] = taskId;
    }
    if (tags != null) {
      data['tags'] = tags;
    }
    if (checklistItems != null) {
      data['checklist_items'] = checklistItems
          .map((item) => item.toJson())
          .toList();
    }
    if (structuredBlocks != null) {
      data['structured_blocks'] = structuredBlocks
          .map((block) => block.toJson())
          .toList();
    }
    if (attachments != null) {
      data['attachments'] = attachments
          .map((attachment) => attachment.toJson())
          .toList();
    }
    if (reminderAt != null) {
      data['reminder_at'] = reminderAt;
    }

    final response = await _apiClient.dio.post('/notes', data: data);
    return NoteModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<NoteModel> updateNote({
    required String noteId,
    String? title,
    String? content,
    String? taskId,
    String? noteType,
    List<String>? tags,
    List<ChecklistItemModel>? checklistItems,
    List<NoteStructuredBlockModel>? structuredBlocks,
    List<NoteAttachmentModel>? attachments,
    String? reminderAt,
    bool clearReminderAt = false,
    String? sourceType,
    String? colorKey,
    bool? isPinned,
    bool? isArchived,
  }) async {
    final data = <String, dynamic>{
      'title': ?title,
      'content': ?content,
      'task_id': ?taskId,
      'note_type': ?noteType,
      'color_key': ?colorKey,
      'source_type': ?sourceType,
      'reminder_at': ?reminderAt,
      if (clearReminderAt) 'clear_reminder_at': true,
      'is_pinned': ?isPinned,
      'is_archived': ?isArchived,
    };
    if (tags != null) {
      data['tags'] = tags;
    }
    if (checklistItems != null) {
      data['checklist_items'] = checklistItems
          .map((item) => item.toJson())
          .toList();
    }
    if (structuredBlocks != null) {
      data['structured_blocks'] = structuredBlocks
          .map((block) => block.toJson())
          .toList();
    }
    if (attachments != null) {
      data['attachments'] = attachments
          .map((attachment) => attachment.toJson())
          .toList();
    }

    final response = await _apiClient.dio.patch('/notes/$noteId', data: data);
    return NoteModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteNote(String noteId) async {
    await _apiClient.dio.delete('/notes/$noteId');
  }

  Future<NoteSummaryResult> summarizeNote({
    required String noteId,
    required NoteSummaryStyle style,
  }) async {
    final response = await _apiClient.dio.post(
      '/notes/$noteId/summarize',
      data: {'summary_style': style.apiKey},
    );
    return NoteSummaryResult.fromJson(response.data as Map<String, dynamic>);
  }

  Future<NoteActionExtractionResult> extractNoteActions({
    required String noteId,
  }) async {
    final response = await _apiClient.dio.post(
      '/notes/$noteId/extract-actions',
    );
    return NoteActionExtractionResult.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}
