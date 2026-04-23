import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
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

  const NotesState({
    this.notes = const [],
    this.isLoading = false,
    this.error,
  });

  NotesState copyWith({
    List<NoteModel>? notes,
    bool? isLoading,
    String? error,
  }) {
    return NotesState(
      notes: notes ?? this.notes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class NotesNotifier extends StateNotifier<NotesState> {
  final Ref _ref;

  NotesNotifier(this._ref) : super(const NotesState());

  Future<void> loadNotes({String? search}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final service = _ref.read(noteServiceProvider);
      final notes = await service.getNotes(search: search);
      state = state.copyWith(notes: notes, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data['detail'] as String? ?? 'Failed to load notes',
      );
    }
  }

  Future<void> createNote({required String content, String? title}) async {
    try {
      final service = _ref.read(noteServiceProvider);
      await service.createNote(content: content, title: title);
      await loadNotes();
    } on DioException catch (e) {
      state = state.copyWith(
        error: e.response?.data['detail'] as String? ?? 'Failed to create note',
      );
    }
  }

  Future<void> togglePin(String noteId, bool currentlyPinned) async {
    try {
      final service = _ref.read(noteServiceProvider);
      await service.updateNote(noteId: noteId, isPinned: !currentlyPinned);
      await loadNotes();
    } catch (_) {}
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