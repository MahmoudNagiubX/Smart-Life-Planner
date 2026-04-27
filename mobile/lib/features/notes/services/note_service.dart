import '../../../core/network/api_client.dart';
import '../models/note_model.dart';

class NoteService {
  final ApiClient _apiClient;

  NoteService(this._apiClient);

  Future<List<NoteModel>> getNotes({String? search, String? tag}) async {
    final queryParameters = <String, dynamic>{};
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
    List<String>? tags,
  }) async {
    final data = <String, dynamic>{'content': content};
    if (title != null && title.isNotEmpty) {
      data['title'] = title;
    }
    if (tags != null) {
      data['tags'] = tags;
    }

    final response = await _apiClient.dio.post('/notes', data: data);
    return NoteModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<NoteModel> updateNote({
    required String noteId,
    String? title,
    String? content,
    List<String>? tags,
    bool? isPinned,
  }) async {
    final data = <String, dynamic>{
      'title': ?title,
      'content': ?content,
      'is_pinned': ?isPinned,
    };
    if (tags != null) {
      data['tags'] = tags;
    }

    final response = await _apiClient.dio.patch('/notes/$noteId', data: data);
    return NoteModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteNote(String noteId) async {
    await _apiClient.dio.delete('/notes/$noteId');
  }
}
