import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_error.dart';
import '../../../core/network/providers.dart';
import '../../../core/notifications/notification_scheduler.dart';
import '../../reminders/providers/reminder_preferences_provider.dart';
import '../../reminders/providers/reminder_provider.dart';
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
    String? taskId,
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
        taskId: taskId,
      );
      state = state.copyWith(notes: notes, isLoading: false);
      await _syncNoteReminders(notes);
    } on DioException catch (e, stackTrace) {
      _logNoteSafeError('load_notes', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: friendlyApiError(e, 'Failed to load notes'),
      );
    } catch (e, stackTrace) {
      _logNoteSafeError('load_notes_parse', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: 'Notes could not be loaded. Please try again.',
      );
    }
  }

  Future<bool> createNote({
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
    try {
      final service = _ref.read(noteServiceProvider);
      final note = await service.createNote(
        content: content,
        title: title,
        taskId: taskId,
        noteType: noteType,
        tags: tags,
        checklistItems: checklistItems,
        structuredBlocks: structuredBlocks,
        attachments: attachments,
        reminderAt: reminderAt,
        sourceType: sourceType,
        colorKey: colorKey,
      );
      await _syncNoteReminder(note);
      state = state.copyWith(
        notes: _upsertVisibleNote(state.notes, note),
        isLoading: false,
        error: null,
      );
      await _refreshNotesAfterSuccessfulSave(fallbackNote: note);
      return true;
    } on DioException catch (e, stackTrace) {
      _logNoteSafeError('create_note', e, stackTrace);
      state = state.copyWith(
        error: friendlyApiError(e, 'Failed to create note'),
      );
      return false;
    } catch (e, stackTrace) {
      _logNoteSafeError('create_note_parse', e, stackTrace);
      state = state.copyWith(error: 'Note was not saved. Please try again.');
      return false;
    }
  }

  Future<bool> updateNote({
    required String noteId,
    required String content,
    String? title,
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
  }) async {
    try {
      final service = _ref.read(noteServiceProvider);
      final note = await service.updateNote(
        noteId: noteId,
        title: title,
        content: content,
        taskId: taskId,
        noteType: noteType,
        tags: tags,
        checklistItems: checklistItems,
        structuredBlocks: structuredBlocks,
        attachments: attachments,
        reminderAt: reminderAt,
        clearReminderAt: clearReminderAt,
        sourceType: sourceType,
        colorKey: colorKey,
      );
      await _syncNoteReminder(note);
      state = state.copyWith(
        notes: _upsertVisibleNote(state.notes, note),
        isLoading: false,
        error: null,
      );
      await _refreshNotesAfterSuccessfulSave(fallbackNote: note);
      return true;
    } on DioException catch (e, stackTrace) {
      _logNoteSafeError('update_note', e, stackTrace);
      state = state.copyWith(
        error: friendlyApiError(e, 'Failed to update note'),
      );
      return false;
    } catch (e, stackTrace) {
      _logNoteSafeError('update_note_parse', e, stackTrace);
      state = state.copyWith(
        error: 'Note changes were not saved. Please try again.',
      );
      return false;
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
      if (archive) {
        await _ref
            .read(notificationSchedulerProvider)
            .cancelNoteReminder(noteId);
        await _ref
            .read(reminderServiceProvider)
            .dismissTargetReminders(
              targetType: 'note',
              targetId: noteId,
              reminderType: 'note',
              recurrenceRule: _noteReminderRule,
            );
      }
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
      await _ref.read(notificationSchedulerProvider).cancelNoteReminder(noteId);
      await _ref
          .read(reminderServiceProvider)
          .dismissTargetReminders(
            targetType: 'note',
            targetId: noteId,
            reminderType: 'note',
            recurrenceRule: _noteReminderRule,
          );
      state = state.copyWith(
        notes: state.notes.where((n) => n.id != noteId).toList(),
      );
    } catch (_) {}
  }

  Future<void> _syncNoteReminders(List<NoteModel> notes) async {
    for (final note in notes) {
      await _syncNoteReminder(note);
    }
  }

  Future<void> _syncNoteReminder(NoteModel note) async {
    try {
      final scheduler = _ref.read(notificationSchedulerProvider);
      if (note.isArchived || note.reminderAt == null) {
        await scheduler.cancelNoteReminder(note.id);
        await _ref
            .read(reminderServiceProvider)
            .dismissTargetReminders(
              targetType: 'note',
              targetId: note.id,
              reminderType: 'note',
              recurrenceRule: _noteReminderRule,
            );
        return;
      }

      final reminderAt = DateTime.parse(note.reminderAt!).toLocal();
      if (reminderAt.isAfter(DateTime.now())) {
        final reminder = await _ref
            .read(reminderServiceProvider)
            .syncTargetReminder(
              targetType: 'note',
              targetId: note.id,
              reminderType: 'note',
              scheduledAt: reminderAt,
              recurrenceRule: _noteReminderRule,
              timezone: DateTime.now().timeZoneName,
            );
        if (reminder == null ||
            !await _ref
                .read(reminderPreferencesProvider.notifier)
                .canScheduleLocal('note', scheduledAt: reminderAt)) {
          await scheduler.cancelNoteReminder(note.id);
          return;
        }
        await scheduler.rescheduleNoteReminder(
          noteId: note.id,
          noteTitle: note.title ?? 'Untitled note',
          reminderAt: reminderAt,
          reminderId: reminder.id,
        );
      } else {
        await scheduler.cancelNoteReminder(note.id);
        await _ref
            .read(reminderServiceProvider)
            .dismissTargetReminders(
              targetType: 'note',
              targetId: note.id,
              reminderType: 'note',
              recurrenceRule: _noteReminderRule,
            );
      }
    } on DioException catch (e, stackTrace) {
      _logNoteSafeError('sync_note_reminder', e, stackTrace);
      await _cancelLocalNoteReminderSafely(note.id);
    } catch (e, stackTrace) {
      _logNoteSafeError('sync_note_reminder_local', e, stackTrace);
      await _cancelLocalNoteReminderSafely(note.id);
    }
  }

  Future<void> _cancelLocalNoteReminderSafely(String noteId) async {
    try {
      await _ref.read(notificationSchedulerProvider).cancelNoteReminder(noteId);
    } catch (e, stackTrace) {
      _logNoteSafeError('cancel_local_note_reminder', e, stackTrace);
    }
  }

  Future<void> _refreshNotesAfterSuccessfulSave({
    required NoteModel fallbackNote,
  }) async {
    try {
      final service = _ref.read(noteServiceProvider);
      final notes = await service.getNotes(
        search: state.search,
        tag: state.selectedTag,
        isArchived: state.showingArchived,
      );
      state = state.copyWith(
        notes: _upsertVisibleNote(notes, fallbackNote),
        isLoading: false,
        error: null,
      );
      await _syncNoteReminders(notes);
    } on DioException catch (e, stackTrace) {
      _logNoteSafeError('refresh_notes_after_save', e, stackTrace);
    } catch (e, stackTrace) {
      _logNoteSafeError('refresh_notes_after_save_parse', e, stackTrace);
    }
  }

  List<NoteModel> _upsertVisibleNote(List<NoteModel> notes, NoteModel note) {
    if (!_noteMatchesCurrentView(note)) {
      return notes.where((item) => item.id != note.id).toList();
    }
    final withoutNote = notes.where((item) => item.id != note.id).toList();
    return [note, ...withoutNote];
  }

  bool _noteMatchesCurrentView(NoteModel note) {
    if (note.isArchived != state.showingArchived) return false;
    final selectedTag = state.selectedTag;
    if (selectedTag != null && !note.tags.contains(selectedTag)) return false;
    final search = state.search?.trim().toLowerCase();
    if (search != null && search.isNotEmpty) {
      final title = note.title?.toLowerCase() ?? '';
      final content = note.content.toLowerCase();
      return title.contains(search) || content.contains(search);
    }
    return true;
  }
}

final notesProvider = StateNotifierProvider<NotesNotifier, NotesState>((ref) {
  return NotesNotifier(ref);
});

const _noteReminderRule = 'source=note_reminder_at';

void _logNoteSafeError(String action, Object error, StackTrace stackTrace) {
  final status = error is DioException ? error.response?.statusCode : null;
  final path = error is DioException ? error.requestOptions.path : null;
  debugPrint(
    'Notes hotfix: $action failed '
    'type=${error.runtimeType} status=$status path=$path',
  );
  debugPrintStack(stackTrace: stackTrace, label: 'Notes hotfix stack');
}

class TaskLinkedNotesState {
  final List<NoteModel> notes;
  final bool isLoading;
  final String? error;

  const TaskLinkedNotesState({
    this.notes = const [],
    this.isLoading = false,
    this.error,
  });

  TaskLinkedNotesState copyWith({
    List<NoteModel>? notes,
    bool? isLoading,
    String? error,
  }) {
    return TaskLinkedNotesState(
      notes: notes ?? this.notes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class TaskLinkedNotesNotifier extends StateNotifier<TaskLinkedNotesState> {
  final Ref _ref;
  final String taskId;

  TaskLinkedNotesNotifier(this._ref, this.taskId)
    : super(const TaskLinkedNotesState());

  Future<void> loadNotes() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final notes = await _ref
          .read(noteServiceProvider)
          .getNotes(taskId: taskId);
      state = state.copyWith(notes: notes, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: friendlyApiError(e, 'Failed to load linked notes'),
      );
    }
  }
}

final taskLinkedNotesProvider =
    StateNotifierProvider.family<
      TaskLinkedNotesNotifier,
      TaskLinkedNotesState,
      String
    >((ref, taskId) {
      return TaskLinkedNotesNotifier(ref, taskId);
    });
