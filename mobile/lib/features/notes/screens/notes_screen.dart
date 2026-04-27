import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_confirmation_dialog.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../voice/screens/voice_note_sheet.dart';
import '../providers/note_provider.dart';
import '../models/note_model.dart';
import 'create_note_sheet.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notesProvider.notifier).loadNotes();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notesProvider);
    final selectedTag = state.selectedTag;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '📝 Notes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search notes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(notesProvider.notifier).loadNotes();
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                ref
                    .read(notesProvider.notifier)
                    .loadNotes(
                      search: value.isEmpty ? null : value,
                      tag: selectedTag,
                    );
              },
            ),
          ),
          if (state.availableTags.isNotEmpty || selectedTag != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  if (selectedTag != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        avatar: const Icon(Icons.close, size: 16),
                        label: Text('#$selectedTag'),
                        onPressed: () => ref
                            .read(notesProvider.notifier)
                            .loadNotes(
                              search: _searchController.text.trim().isEmpty
                                  ? null
                                  : _searchController.text.trim(),
                            ),
                      ),
                    ),
                  ...state.availableTags.map(
                    (tag) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('#$tag'),
                        selected: tag == selectedTag,
                        onSelected: (_) => ref
                            .read(notesProvider.notifier)
                            .loadNotes(
                              search: _searchController.text.trim().isEmpty
                                  ? null
                                  : _searchController.text.trim(),
                              tag: tag,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),

          // Notes list
          Expanded(
            child: state.isLoading
                ? const AppLoadingState(message: 'Loading notes...')
                : state.error != null
                ? AppErrorState(
                    title: 'Notes could not load',
                    message: state.error!,
                    onRetry: () => ref.read(notesProvider.notifier).loadNotes(),
                  )
                : state.notes.isEmpty
                ? AppEmptyState(
                    icon: Icons.note_add_outlined,
                    title: 'No notes yet',
                    message: selectedTag == null
                        ? 'Capture a note, idea, or voice transcript when you are ready.'
                        : 'No notes found with #$selectedTag.',
                  )
                : RefreshIndicator(
                    onRefresh: () => ref
                        .read(notesProvider.notifier)
                        .loadNotes(
                          search: state.search,
                          tag: state.selectedTag,
                        ),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.notes.length,
                      itemBuilder: (context, index) {
                        return _NoteCard(note: state.notes[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'voice_note',
            onPressed: () async {
              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) => const VoiceNoteSheet(),
              );
              if (context.mounted) {
                ref.read(notesProvider.notifier).loadNotes();
              }
            },
            backgroundColor: AppColors.primary.withValues(alpha: 0.7),
            child: const Icon(Icons.mic, size: 20),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'text_note',
            onPressed: () async {
              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) => const CreateNoteSheet(),
              );
              if (context.mounted) {
                ref.read(notesProvider.notifier).loadNotes();
              }
            },
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends ConsumerWidget {
  final NoteModel note;

  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: note.isPinned
            ? Border.all(color: AppColors.prayerGold.withValues(alpha: 0.5))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (note.isPinned)
                const Icon(
                  Icons.push_pin,
                  size: 16,
                  color: AppColors.prayerGold,
                ),
              if (note.isPinned) const SizedBox(width: 4),
              Expanded(
                child: Text(
                  note.title ?? 'Untitled',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18),
                onSelected: (value) async {
                  if (value == 'pin') {
                    ref
                        .read(notesProvider.notifier)
                        .togglePin(note.id, note.isPinned);
                  } else if (value == 'tags') {
                    final tags = await _showTagEditor(context, note.tags);
                    if (tags == null) return;
                    await ref
                        .read(notesProvider.notifier)
                        .updateTags(note.id, tags);
                  } else if (value == 'delete') {
                    final confirmed = await confirmDestructiveAction(
                      context: context,
                      title: 'Delete Note',
                      message:
                          'Delete "${note.title ?? 'Untitled'}"? This note will be removed.',
                    );
                    if (!confirmed) return;
                    await ref.read(notesProvider.notifier).deleteNote(note.id);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'pin',
                    child: Text(note.isPinned ? 'Unpin' : 'Pin'),
                  ),
                  const PopupMenuItem(value: 'tags', child: Text('Edit tags')),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Delete',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            note.content,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          if (note.tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: note.tags
                  .map(
                    (tag) => InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () =>
                          ref.read(notesProvider.notifier).loadNotes(tag: tag),
                      child: _TagChip(tag: tag),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            note.updatedAt.substring(0, 10),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Future<List<String>?> _showTagEditor(
    BuildContext context,
    List<String> currentTags,
  ) async {
    final controller = TextEditingController(text: currentTags.join(', '));
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit tags'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Tags',
            hintText: 'study, ideas, reflection',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(context).pop(_parseTags(controller.text)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  List<String> _parseTags(String value) {
    final tags = <String>[];
    final seen = <String>{};
    for (final raw in value.split(',')) {
      final tag = raw.trim().toLowerCase().replaceFirst(RegExp(r'^#+'), '');
      if (tag.isEmpty || seen.contains(tag)) continue;
      seen.add(tag);
      tags.add(tag);
    }
    return tags;
  }
}

class _TagChip extends StatelessWidget {
  final String tag;

  const _TagChip({required this.tag});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
      ),
      child: Text(
        '#$tag',
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
