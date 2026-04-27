import '../../../core/network/api_client.dart';
import '../models/note_model.dart';

class NoteService {
  final ApiClient _apiClient;

  NoteService(this._apiClient);

  Future<List<NoteModel>> getNotes({
    String? search,
    String? tag,
    bool isArchived = false,
  }) async {
    final queryParameters = <String, dynamic>{'is_archived': isArchived};
    if (search != null && search.isNotEmpty) {
      queryParameters['search'] = search;
    }
    if (tag != null && tag.isNotEmpty) {
      queryParameters['tag'] = tag;
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
    String noteType = 'text',
    List<String>? tags,
    List<ChecklistItemModel>? checklistItems,
    List<NoteStructuredBlockModel>? structuredBlocks,
    String colorKey = 'default',
  }) async {
    final data = <String, dynamic>{
      'content': content,
      'note_type': noteType,
      'color_key': colorKey,
    };
    if (title != null && title.isNotEmpty) {
      data['title'] = title;
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

    final response = await _apiClient.dio.post('/notes', data: data);
    return NoteModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<NoteModel> updateNote({
    required String noteId,
    String? title,
    String? content,
    String? noteType,
    List<String>? tags,
    List<ChecklistItemModel>? checklistItems,
    List<NoteStructuredBlockModel>? structuredBlocks,
    String? colorKey,
    bool? isPinned,
    bool? isArchived,
  }) async {
    final data = <String, dynamic>{
      'title': ?title,
      'content': ?content,
      'note_type': ?noteType,
      'color_key': ?colorKey,
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

    final response = await _apiClient.dio.patch('/notes/$noteId', data: data);
    return NoteModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteNote(String noteId) async {
    await _apiClient.dio.delete('/notes/$noteId');
  }
}
