import '../../../core/network/api_client.dart';
import '../models/note_model.dart';

class NoteService {
  final ApiClient _apiClient;

  NoteService(this._apiClient);

  Future<List<NoteModel>> getNotes({String? search}) async {
    final response = await _apiClient.dio.get(
      '/notes',
      queryParameters: search != null ? {'search': search} : null,
    );
    return (response.data as List<dynamic>)
        .map((n) => NoteModel.fromJson(n as Map<String, dynamic>))
        .toList();
  }

  Future<NoteModel> createNote({
    required String content,
    String? title,
  }) async {
    final response = await _apiClient.dio.post('/notes', data: {
      'content': content,
      if (title != null && title.isNotEmpty) 'title': title,
    });
    return NoteModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<NoteModel> updateNote({
    required String noteId,
    String? title,
    String? content,
    bool? isPinned,
  }) async {
    final response = await _apiClient.dio.patch('/notes/$noteId', data: {
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (isPinned != null) 'is_pinned': isPinned,
    });
    return NoteModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteNote(String noteId) async {
    await _apiClient.dio.delete('/notes/$noteId');
  }
}