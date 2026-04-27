import 'dart:io';

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
        actions: [
          IconButton(
            tooltip: state.showingArchived
                ? 'Show active notes'
                : 'Show archive',
            onPressed: () => ref
                .read(notesProvider.notifier)
                .loadNotes(
                  search: _searchController.text.trim().isEmpty
                      ? null
                      : _searchController.text.trim(),
                  tag: selectedTag,
                  isArchived: !state.showingArchived,
                ),
            icon: Icon(
              state.showingArchived
                  ? Icons.note_alt_outlined
                  : Icons.archive_outlined,
            ),
          ),
        ],
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
                    icon: state.showingArchived
                        ? Icons.archive_outlined
                        : Icons.note_add_outlined,
                    title: state.showingArchived
                        ? 'No archived notes'
                        : 'No notes yet',
                    message: selectedTag != null
                        ? 'No notes found with #$selectedTag.'
                        : state.showingArchived
                        ? 'Archived notes will appear here.'
                        : 'Capture a note, idea, or voice transcript when you are ready.',
                  )
                : RefreshIndicator(
                    onRefresh: () => ref
                        .read(notesProvider.notifier)
                        .loadNotes(
                          search: state.search,
                          tag: state.selectedTag,
                          isArchived: state.showingArchived,
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
      floatingActionButton: state.showingArchived
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'voice_note',
                  onPressed: () async {
                    await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Theme.of(
                        context,
                      ).scaffoldBackgroundColor,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      builder: (_) => const VoiceNoteSheet(),
                    );
                    if (context.mounted) {
                      ref
                          .read(notesProvider.notifier)
                          .loadNotes(
                            search: state.search,
                            tag: state.selectedTag,
                            isArchived: state.showingArchived,
                          );
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
                      backgroundColor: Theme.of(
                        context,
                      ).scaffoldBackgroundColor,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      builder: (_) => const CreateNoteSheet(),
                    );
                    if (context.mounted) {
                      ref
                          .read(notesProvider.notifier)
                          .loadNotes(
                            search: state.search,
                            tag: state.selectedTag,
                            isArchived: state.showingArchived,
                          );
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
        color: _noteBackgroundColor(context, note.colorKey),
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
                  } else if (value == 'edit') {
                    await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Theme.of(
                        context,
                      ).scaffoldBackgroundColor,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      builder: (_) => CreateNoteSheet(initialNote: note),
                    );
                  } else if (value == 'color') {
                    final colorKey = await _showColorPicker(
                      context,
                      note.colorKey,
                    );
                    if (colorKey == null) return;
                    await ref
                        .read(notesProvider.notifier)
                        .updateColor(note.id, colorKey);
                  } else if (value == 'archive') {
                    await ref
                        .read(notesProvider.notifier)
                        .archiveNote(note.id, !note.isArchived);
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
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(
                    value: 'color',
                    child: Text('Change color'),
                  ),
                  PopupMenuItem(
                    value: 'archive',
                    child: Text(note.isArchived ? 'Unarchive' : 'Archive'),
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
          if (note.noteType == 'checklist' && note.checklistItems.isNotEmpty)
            _ChecklistPreview(
              items: note.checklistItems,
              onToggle: (item) {
                final updatedItems = note.checklistItems
                    .map(
                      (current) => current.id == item.id
                          ? current.copyWith(isCompleted: !current.isCompleted)
                          : current,
                    )
                    .toList();
                ref
                    .read(notesProvider.notifier)
                    .updateChecklistItems(note.id, updatedItems);
              },
            )
          else
            Text(
              note.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          if (note.structuredBlocks.isNotEmpty) ...[
            const SizedBox(height: 10),
            _StructuredBlocksPreview(blocks: note.structuredBlocks),
          ],
          if (note.attachments.isNotEmpty) ...[
            const SizedBox(height: 10),
            _AttachmentPreview(attachments: note.attachments),
          ],
          if (note.reminderAt != null) ...[
            const SizedBox(height: 10),
            _ReminderChip(reminderAt: note.reminderAt!),
          ],
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
            note.isArchived && note.archivedAt != null
                ? 'Archived ${note.archivedAt!.substring(0, 10)}'
                : note.updatedAt.substring(0, 10),
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

  Future<String?> _showColorPicker(
    BuildContext context,
    String currentColorKey,
  ) async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Note color'),
        content: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _noteColorOptions
              .map(
                (option) => Tooltip(
                  message: option.label,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => Navigator.of(context).pop(option.key),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color:
                            option.color ?? Theme.of(context).cardTheme.color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: currentColorKey == option.key
                              ? AppColors.primary
                              : AppColors.textSecondary.withValues(alpha: 0.35),
                          width: currentColorKey == option.key ? 2 : 1,
                        ),
                      ),
                      child: currentColorKey == option.key
                          ? const Icon(
                              Icons.check,
                              color: AppColors.primary,
                              size: 18,
                            )
                          : null,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
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

class _ChecklistPreview extends StatelessWidget {
  final List<ChecklistItemModel> items;
  final ValueChanged<ChecklistItemModel> onToggle;

  const _ChecklistPreview({required this.items, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final visibleItems = items.take(4).toList();
    final remaining = items.length - visibleItems.length;

    return Column(
      children: [
        ...visibleItems.map(
          (item) => InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => onToggle(item),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: Checkbox(
                      value: item.isCompleted,
                      onChanged: (_) => onToggle(item),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        decoration: item.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (remaining > 0)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+$remaining more',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StructuredBlocksPreview extends StatelessWidget {
  final List<NoteStructuredBlockModel> blocks;

  const _StructuredBlocksPreview({required this.blocks});

  @override
  Widget build(BuildContext context) {
    NoteStructuredBlockModel? bulletBlock;
    NoteStructuredBlockModel? taskBlock;
    for (final block in blocks) {
      if (bulletBlock == null &&
          block.type == 'bullet_list' &&
          block.items.isNotEmpty) {
        bulletBlock = block;
      } else if (taskBlock == null && block.type == 'task_link') {
        taskBlock = block;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (bulletBlock != null)
          ...bulletBlock.items
              .take(3)
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '•',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        if (taskBlock != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                Chip(
                  avatar: const Icon(Icons.task_alt, size: 15),
                  label: Text(
                    taskBlock.taskTitle ?? taskBlock.taskId ?? 'Linked task',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ReminderChip extends StatelessWidget {
  final String reminderAt;

  const _ReminderChip({required this.reminderAt});

  @override
  Widget build(BuildContext context) {
    final safeEnd = reminderAt.length < 16 ? reminderAt.length : 16;
    final label =
        DateTime.tryParse(reminderAt)?.toLocal().toString().substring(0, 16) ??
        reminderAt.substring(0, safeEnd);
    return Align(
      alignment: Alignment.centerLeft,
      child: Chip(
        avatar: const Icon(Icons.notifications_outlined, size: 15),
        label: Text(label),
      ),
    );
  }
}

class _AttachmentPreview extends StatelessWidget {
  final List<NoteAttachmentModel> attachments;

  const _AttachmentPreview({required this.attachments});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: attachments.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final path = attachments[index].localPath;
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: path == null
                ? Container(
                    width: 76,
                    height: 76,
                    color: Colors.black.withValues(alpha: 0.18),
                    child: const Icon(Icons.image_outlined),
                  )
                : Image.file(
                    File(path),
                    width: 76,
                    height: 76,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 76,
                      height: 76,
                      color: Colors.black.withValues(alpha: 0.18),
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
          );
        },
      ),
    );
  }
}

Color _noteBackgroundColor(BuildContext context, String colorKey) {
  return switch (colorKey) {
    'red' => AppColors.noteRed,
    'orange' => AppColors.noteOrange,
    'yellow' => AppColors.noteYellow,
    'green' => AppColors.noteGreen,
    'blue' => AppColors.noteBlue,
    'purple' => AppColors.notePurple,
    _ => Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
  };
}

class _NoteColorOption {
  final String key;
  final String label;
  final Color? color;

  const _NoteColorOption(this.key, this.label, this.color);
}

const _noteColorOptions = [
  _NoteColorOption('default', 'Default color', null),
  _NoteColorOption('red', 'Red', AppColors.noteRed),
  _NoteColorOption('orange', 'Orange', AppColors.noteOrange),
  _NoteColorOption('yellow', 'Yellow', AppColors.noteYellow),
  _NoteColorOption('green', 'Green', AppColors.noteGreen),
  _NoteColorOption('blue', 'Blue', AppColors.noteBlue),
  _NoteColorOption('purple', 'Purple', AppColors.notePurple),
];
