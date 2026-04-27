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
  final bool showingArchived;

  const NotesState({
    this.notes = const [],
    this.isLoading = false,
    this.error,
    this.search,
    this.selectedTag,
    this.showingArchived = false,
  });

  NotesState copyWith({
    List<NoteModel>? notes,
    bool? isLoading,
    String? error,
    String? search,
    String? selectedTag,
    bool? showingArchived,
    bool clearSearch = false,
    bool clearSelectedTag = false,
  }) {
    return NotesState(
      notes: notes ?? this.notes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      search: clearSearch ? null : search ?? this.search,
      selectedTag: clearSelectedTag ? null : selectedTag ?? this.selectedTag,
      showingArchived: showingArchived ?? this.showingArchived,
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

  Future<void> loadNotes({
    String? search,
    String? tag,
    bool? isArchived,
  }) async {
    final archived = isArchived ?? state.showingArchived;
    state = state.copyWith(
      isLoading: true,
      error: null,
      search: search,
      selectedTag: tag,
      showingArchived: archived,
      clearSearch: search == null,
      clearSelectedTag: tag == null,
    );
    try {
      final service = _ref.read(noteServiceProvider);
      final notes = await service.getNotes(
        search: search,
        tag: tag,
        isArchived: archived,
      );
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
    String noteType = 'text',
    List<String>? tags,
    List<ChecklistItemModel>? checklistItems,
    List<NoteStructuredBlockModel>? structuredBlocks,
    List<NoteAttachmentModel>? attachments,
    String colorKey = 'default',
  }) async {
    try {
      final service = _ref.read(noteServiceProvider);
      await service.createNote(
        content: content,
        title: title,
        noteType: noteType,
        tags: tags,
        checklistItems: checklistItems,
        structuredBlocks: structuredBlocks,
        attachments: attachments,
        colorKey: colorKey,
      );
      await loadNotes(
        search: state.search,
        tag: state.selectedTag,
        isArchived: state.showingArchived,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        error: friendlyApiError(e, 'Failed to create note'),
      );
    }
  }

  Future<void> updateNote({
    required String noteId,
    required String content,
    String? title,
    String? noteType,
    List<String>? tags,
    List<ChecklistItemModel>? checklistItems,
    List<NoteStructuredBlockModel>? structuredBlocks,
    List<NoteAttachmentModel>? attachments,
    String? colorKey,
  }) async {
    try {
      final service = _ref.read(noteServiceProvider);
      await service.updateNote(
        noteId: noteId,
        title: title,
        content: content,
        noteType: noteType,
        tags: tags,
        checklistItems: checklistItems,
        structuredBlocks: structuredBlocks,
        attachments: attachments,
        colorKey: colorKey,
      );
      await loadNotes(
        search: state.search,
        tag: state.selectedTag,
        isArchived: state.showingArchived,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        error: friendlyApiError(e, 'Failed to update note'),
      );
    }
  }

  Future<void> togglePin(String noteId, bool currentlyPinned) async {
    try {
      final service = _ref.read(noteServiceProvider);
      await service.updateNote(noteId: noteId, isPinned: !currentlyPinned);
      await loadNotes(
        search: state.search,
        tag: state.selectedTag,
        isArchived: state.showingArchived,
      );
    } catch (_) {}
  }

  Future<void> updateColor(String noteId, String colorKey) async {
    try {
      final service = _ref.read(noteServiceProvider);
      await service.updateNote(noteId: noteId, colorKey: colorKey);
      await loadNotes(
        search: state.search,
        tag: state.selectedTag,
        isArchived: state.showingArchived,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        error: friendlyApiError(e, 'Failed to update note color'),
      );
    }
  }

  Future<void> archiveNote(String noteId, bool archive) async {
    try {
      final service = _ref.read(noteServiceProvider);
      await service.updateNote(noteId: noteId, isArchived: archive);
      await loadNotes(
        search: state.search,
        tag: state.selectedTag,
        isArchived: state.showingArchived,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        error: friendlyApiError(
          e,
          archive ? 'Failed to archive note' : 'Failed to unarchive note',
        ),
      );
    }
  }

  Future<void> updateTags(String noteId, List<String> tags) async {
    try {
      final service = _ref.read(noteServiceProvider);
      await service.updateNote(noteId: noteId, tags: tags);
      await loadNotes(
        search: state.search,
        tag: state.selectedTag,
        isArchived: state.showingArchived,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        error: friendlyApiError(e, 'Failed to update note tags'),
      );
    }
  }

  Future<void> updateChecklistItems(
    String noteId,
    List<ChecklistItemModel> checklistItems,
  ) async {
    try {
      final content = checklistItems.map((item) => item.text).join('\n');
      final service = _ref.read(noteServiceProvider);
      await service.updateNote(
        noteId: noteId,
        content: content,
        checklistItems: checklistItems,
      );
      await loadNotes(
        search: state.search,
        tag: state.selectedTag,
        isArchived: state.showingArchived,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        error: friendlyApiError(e, 'Failed to update checklist'),
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
