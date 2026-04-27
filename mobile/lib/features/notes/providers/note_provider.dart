import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_error.dart';
import '../../../core/network/providers.dart';
import '../models/note_model.dart';
import '../services/note_service.dart';

final noteServiceProvider = Provider<NoteService>((ref) {
  return NoteService(ref.watch(apiClientProvider));
});

class NotesState {
  final List<NoteModel> notes;
  final bool isLoading;
  final String? error;
  final String? search;
  final String? selectedTag;

  const NotesState({
    this.notes = const [],
    this.isLoading = false,
    this.error,
    this.search,
    this.selectedTag,
  });

  NotesState copyWith({
    List<NoteModel>? notes,
    bool? isLoading,
    String? error,
    String? search,
    String? selectedTag,
    bool clearSearch = false,
    bool clearSelectedTag = false,
  }) {
    return NotesState(
      notes: notes ?? this.notes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      search: clearSearch ? null : search ?? this.search,
      selectedTag: clearSelectedTag ? null : selectedTag ?? this.selectedTag,
    );
  }

  List<String> get availableTags {
    final tags = <String>{};
    for (final note in notes) {
      tags.addAll(note.tags);
    }
    final sorted = tags.toList()..sort();
    return sorted;
  }
}

class NotesNotifier extends StateNotifier<NotesState> {
  final Ref _ref;

  NotesNotifier(this._ref) : super(const NotesState());

  Future<void> loadNotes({String? search, String? tag}) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      search: search,
      selectedTag: tag,
      clearSearch: search == null,
      clearSelectedTag: tag == null,
    );
    try {
      final service = _ref.read(noteServiceProvider);
      final notes = await service.getNotes(search: search, tag: tag);
      state = state.copyWith(notes: notes, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: friendlyApiError(e, 'Failed to load notes'),
      );
    }
  }

  Future<void> createNote({
    required String content,
    String? title,
    List<String>? tags,
  }) async {
    try {
      final service = _ref.read(noteServiceProvider);
      await service.createNote(content: content, title: title, tags: tags);
      await loadNotes(search: state.search, tag: state.selectedTag);
    } on DioException catch (e) {
      state = state.copyWith(
        error: friendlyApiError(e, 'Failed to create note'),
      );
    }
  }

  Future<void> togglePin(String noteId, bool currentlyPinned) async {
    try {
      final service = _ref.read(noteServiceProvider);
      await service.updateNote(noteId: noteId, isPinned: !currentlyPinned);
      await loadNotes(search: state.search, tag: state.selectedTag);
    } catch (_) {}
  }

  Future<void> updateTags(String noteId, List<String> tags) async {
    try {
      final service = _ref.read(noteServiceProvider);
      await service.updateNote(noteId: noteId, tags: tags);
      await loadNotes(search: state.search, tag: state.selectedTag);
    } on DioException catch (e) {
      state = state.copyWith(
        error: friendlyApiError(e, 'Failed to update note tags'),
      );
    }
  }

  Future<void> deleteNote(String noteId) async {
    try {
      final service = _ref.read(noteServiceProvider);
      await service.deleteNote(noteId);
      state = state.copyWith(
        notes: state.notes.where((n) => n.id != noteId).toList(),
      );
    } catch (_) {}
  }
}

final notesProvider = StateNotifierProvider<NotesNotifier, NotesState>((ref) {
  return NotesNotifier(ref);
});
