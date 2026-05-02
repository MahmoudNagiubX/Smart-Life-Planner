import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_confirmation_dialog.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../tasks/providers/task_provider.dart';
import '../../voice/screens/voice_note_sheet.dart';
import '../models/app_template_library.dart';
import '../models/note_action_extraction_model.dart';
import '../models/note_model.dart';
import '../models/note_summary_model.dart';
import '../models/smart_note_processing_model.dart';
import '../providers/note_provider.dart';
import '../providers/smart_note_processing_provider.dart';
import '../services/note_ocr_service.dart';
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
      backgroundColor: AppColors.bgApp,
      appBar: AppBar(
        backgroundColor: AppColors.bgApp,
        surfaceTintColor: AppColors.bgApp,
        elevation: 0,
        titleSpacing: AppSpacing.screenH,
        title: Text('Notes', style: AppTextStyles.h2Light),
        actions: [
          IconButton(
            tooltip: 'Templates',
            onPressed: () => _showNoteTemplatePicker(context),
            icon: const Icon(Icons.dashboard_customize_outlined),
            color: AppColors.textHeading,
          ),
          IconButton(
            tooltip: 'Smart note tools',
            onPressed: () => _showSmartNoteMenu(context),
            icon: const Icon(Icons.auto_awesome_outlined),
            color: AppColors.textHeading,
          ),
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
            color: AppColors.textHeading,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Capture ideas before they disappear.',
                style: AppTextStyles.bodySmall(AppColors.textHint),
              ),
            ),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenH,
              AppSpacing.s4,
              AppSpacing.screenH,
              0,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: AppRadius.pillBr,
                border: Border.all(color: AppColors.borderSoft),
                boxShadow: AppShadows.soft,
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search notes...',
                  hintStyle: AppTextStyles.bodySmall(AppColors.textHint),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.textHint,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          color: AppColors.textHint,
                          onPressed: () {
                            _searchController.clear();
                            ref.read(notesProvider.notifier).loadNotes();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.s16,
                  ),
                ),
                style: AppTextStyles.body(AppColors.textBody),
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
                      child: _NotesFilterChip(
                        label: '#$selectedTag',
                        icon: Icons.close,
                        selected: true,
                        onTap: () => ref
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
                      child: _NotesFilterChip(
                        label: '#$tag',
                        selected: tag == selectedTag,
                        onTap: () => ref
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
                        : Icons.edit_note_outlined,
                    title: state.showingArchived
                        ? 'No archived notes'
                        : 'No notes yet',
                    message: selectedTag != null
                        ? 'No notes found with #$selectedTag.'
                        : state.showingArchived
                        ? 'Archived notes will appear here.'
                        : 'Capture your first idea, reminder, or reflection.',
                    accentColor: AppColors.brandPrimary,
                    action: state.showingArchived
                        ? null
                        : ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.brandPrimary,
                              foregroundColor: AppColors.bgSurface,
                              minimumSize: const Size(0, AppButtonHeight.small),
                              shape: RoundedRectangleBorder(
                                borderRadius: AppRadius.pillBr,
                              ),
                            ),
                            onPressed: () async {
                              await showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Theme.of(
                                  context,
                                ).scaffoldBackgroundColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: AppRadius.sheetBr,
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
                            icon: const Icon(Icons.add),
                            label: const Text('Create Note'),
                          ),
                  )
                : RefreshIndicator(
                    onRefresh: () => ref
                        .read(notesProvider.notifier)
                        .loadNotes(
                          search: state.search,
                          tag: state.selectedTag,
                          isArchived: state.showingArchived,
                        ),
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenH,
                        AppSpacing.s8,
                        AppSpacing.screenH,
                        132,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: AppSpacing.s12,
                            mainAxisSpacing: AppSpacing.s12,
                            childAspectRatio: 0.78,
                          ),
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
                  backgroundColor: AppColors.bgSurface,
                  foregroundColor: AppColors.brandPink,
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
                  backgroundColor: AppColors.brandPink,
                  foregroundColor: AppColors.bgSurface,
                  child: const Icon(Icons.add),
                ),
              ],
            ),
    );
  }

  Future<void> _showNoteTemplatePicker(BuildContext context) async {
    final template = await showModalBottomSheet<AppTemplate>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _TemplatePickerSheet(),
    );
    if (template == null || !context.mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CreateNoteSheet(template: template),
    );
    if (!context.mounted) return;
    final state = ref.read(notesProvider);
    await ref
        .read(notesProvider.notifier)
        .loadNotes(
          search: state.search,
          tag: state.selectedTag,
          isArchived: state.showingArchived,
        );
  }
}

class _TemplatePickerSheet extends StatelessWidget {
  const _TemplatePickerSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: appTemplates.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final template = appTemplates[index];
          return ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            tileColor: Theme.of(context).cardTheme.color,
            leading: const Icon(Icons.description_outlined),
            title: Text(template.title),
            subtitle: Text(template.description),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pop(context, template),
          );
        },
      ),
    );
  }
}

class _NotesFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData? icon;
  final VoidCallback onTap;

  const _NotesFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppRadius.pillBr,
      onTap: onTap,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
        decoration: BoxDecoration(
          gradient: selected ? AppGradients.action : null,
          color: selected ? null : AppColors.bgSurface,
          borderRadius: AppRadius.pillBr,
          border: Border.all(
            color: selected
                ? AppColors.bgSurface.withValues(alpha: 0)
                : AppColors.borderSoft,
          ),
          boxShadow: selected ? AppShadows.glowPurple : AppShadows.soft,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: selected ? AppColors.bgSurface : AppColors.textBody,
              ),
              const SizedBox(width: AppSpacing.s4),
            ],
            Text(
              label,
              style: AppTextStyles.label(
                selected ? AppColors.bgSurface : AppColors.textBody,
              ),
            ),
          ],
        ),
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
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: _noteBackgroundColor(note.colorKey),
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        boxShadow: AppShadows.soft,
        border: note.isPinned
            ? Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.35))
            : Border.all(color: AppColors.borderSoft),
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
                  color: AppColors.brandPrimary,
                ),
              if (note.isPinned) const SizedBox(width: 4),
              Expanded(
                child: Text(
                  note.title ?? 'Untitled',
                  style: AppTextStyles.h4(AppColors.textHeading),
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
                  } else if (value == 'smart') {
                    _showSmartNoteMenu(context, note: note);
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
                    value: 'smart',
                    child: Text('Smart tools'),
                  ),
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textBody,
                height: 1.35,
                fontSize: 12,
              ),
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
          if (note.taskId != null) ...[
            const SizedBox(height: 10),
            const Chip(
              avatar: Icon(Icons.task_alt, size: 15),
              label: Text('Linked task'),
            ),
          ],
          if (note.sourceType == 'voice') ...[
            const SizedBox(height: 10),
            const Chip(
              avatar: Icon(Icons.mic_none, size: 15),
              label: Text('Voice transcript'),
            ),
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
              color: AppColors.textHint,
              fontWeight: FontWeight.w600,
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
        color: AppColors.bgSurfaceLavender,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Text('#$tag', style: AppTextStyles.label(AppColors.brandPrimary)),
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
    NoteStructuredBlockModel? headingBlock;
    NoteStructuredBlockModel? bulletBlock;
    NoteStructuredBlockModel? taskBlock;
    NoteStructuredBlockModel? dividerBlock;
    NoteStructuredBlockModel? imageBlock;
    for (final block in blocks) {
      if (headingBlock == null && block.type == 'heading') {
        headingBlock = block;
      } else if (bulletBlock == null &&
          block.type == 'bullet_list' &&
          block.items.isNotEmpty) {
        bulletBlock = block;
      } else if (taskBlock == null && block.type == 'task_link') {
        taskBlock = block;
      } else if (dividerBlock == null && block.type == 'divider') {
        dividerBlock = block;
      } else if (imageBlock == null && block.type == 'image') {
        imageBlock = block;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (headingBlock != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Text(
              headingBlock.text ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
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
        if (dividerBlock != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Divider(
              color: AppColors.textSecondary.withValues(alpha: 0.25),
            ),
          ),
        if (imageBlock != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Chip(
              avatar: const Icon(Icons.image_outlined, size: 15),
              label: Text(
                imageBlock.localPath == null ? 'Image block' : 'Local image',
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

Color _noteBackgroundColor(String colorKey) {
  return switch (colorKey) {
    'red' => AppColors.noteRed,
    'orange' => AppColors.noteOrange,
    'yellow' => AppColors.noteYellow,
    'green' => AppColors.noteGreen,
    'blue' => AppColors.noteBlue,
    'purple' => AppColors.notePurple,
    _ => AppColors.bgSurface,
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

Future<void> _showSmartNoteMenu(BuildContext context, {NoteModel? note}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _SmartNoteToolsSheet(note: note),
  );
}

class _SmartNoteToolsSheet extends ConsumerWidget {
  final NoteModel? note;

  const _SmartNoteToolsSheet({this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(smartNoteProcessingProvider);
    final activeNote = note;
    final ocrAttachment = activeNote == null
        ? null
        : firstLocalOcrAttachment(activeNote.attachments);
    final canRunImageExtraction = activeNote != null && ocrAttachment != null;
    final isOcrForThisNote =
        activeNote != null &&
        state.jobType == SmartNoteJobType.ocr &&
        state.noteId == activeNote.id;
    final isHandwritingForThisNote =
        activeNote != null &&
        state.jobType == SmartNoteJobType.handwriting &&
        state.noteId == activeNote.id;
    final isImageExtractionForThisNote =
        isOcrForThisNote || isHandwritingForThisNote;
    final isSummaryForThisNote =
        activeNote != null &&
        state.jobType == SmartNoteJobType.summary &&
        state.noteId == activeNote.id;
    final isActionExtractionForThisNote =
        activeNote != null &&
        state.jobType == SmartNoteJobType.actionExtraction &&
        state.noteId == activeNote.id;
    final isOcrProcessing = isOcrForThisNote && state.isProcessing;
    final isHandwritingProcessing =
        isHandwritingForThisNote && state.isProcessing;
    final isSummaryProcessing = isSummaryForThisNote && state.isProcessing;
    final isActionExtractionProcessing =
        isActionExtractionForThisNote && state.isProcessing;
    final canSummarize =
        activeNote != null && activeNote.content.trim().isNotEmpty;
    final canExtractActions = canSummarize;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_outlined,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      activeNote == null ? 'Smart Note Tools' : 'Smart Tools',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (activeNote != null) ...[
                const SizedBox(height: 6),
                Text(
                  activeNote.title ?? 'Untitled note',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              _SmartToolTile(
                icon: Icons.document_scanner_outlined,
                title: 'OCR from images',
                description: canRunImageExtraction
                    ? 'Read text from the first attached local image.'
                    : 'Open a saved note with a local image attachment.',
                statusLabel: canRunImageExtraction ? 'Run' : 'Needs image',
                enabled: canRunImageExtraction && !isOcrProcessing,
                onTap: activeNote == null
                    ? null
                    : () => ref
                          .read(smartNoteProcessingProvider.notifier)
                          .runOcr(activeNote),
              ),
              if (isOcrProcessing) ...[
                const SizedBox(height: 4),
                const LinearProgressIndicator(),
                const SizedBox(height: 10),
                Text(
                  'Reading image text on this device...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              _SmartToolTile(
                icon: Icons.draw_outlined,
                title: 'Handwriting extraction',
                description: canRunImageExtraction
                    ? 'Best-effort reading for clear handwritten notes.'
                    : 'Open a saved note with a local handwriting image.',
                statusLabel: canRunImageExtraction ? 'Run' : 'Needs image',
                enabled: canRunImageExtraction && !isHandwritingProcessing,
                onTap: activeNote == null
                    ? null
                    : () => ref
                          .read(smartNoteProcessingProvider.notifier)
                          .runHandwriting(activeNote),
              ),
              if (activeNote != null && !canRunImageExtraction) ...[
                const SizedBox(height: 4),
                _SmartNoteFailureCard(
                  message:
                      'No local image attachment was found. Attach an image or add the text manually.',
                  manualLabel: 'Edit note',
                  onManualFallback: () =>
                      _openManualNoteEditor(context, ref, activeNote),
                ),
              ],
              if (isHandwritingProcessing) ...[
                const SizedBox(height: 4),
                const LinearProgressIndicator(),
                const SizedBox(height: 10),
                Text(
                  'Reading handwriting as best-effort text...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (isImageExtractionForThisNote && state.isFailure) ...[
                const SizedBox(height: 10),
                _SmartNoteFailureCard(
                  message: state.errorMessage ?? 'Text extraction failed.',
                  onRetry: () {
                    if (state.jobType == SmartNoteJobType.handwriting) {
                      ref
                          .read(smartNoteProcessingProvider.notifier)
                          .runHandwriting(activeNote);
                    } else {
                      ref
                          .read(smartNoteProcessingProvider.notifier)
                          .runOcr(activeNote);
                    }
                  },
                  manualLabel: 'Edit note',
                  onManualFallback: () =>
                      _openManualNoteEditor(context, ref, activeNote),
                ),
              ],
              if (isImageExtractionForThisNote && state.hasPreview) ...[
                const SizedBox(height: 12),
                _TextExtractionPreviewCard(
                  note: activeNote,
                  jobType: state.jobType ?? SmartNoteJobType.ocr,
                  previewText: state.previewText ?? '',
                  previewJson: state.previewJson,
                ),
              ],
              _SmartToolTile(
                icon: Icons.summarize_outlined,
                title: 'AI note summary',
                description: canSummarize
                    ? 'Create an editable summary preview.'
                    : 'Add note content before summarizing.',
                statusLabel: canSummarize ? 'Choose' : 'Needs text',
                enabled: canSummarize && !isSummaryProcessing,
                onTap: activeNote == null
                    ? null
                    : () => _showSummaryStylePicker(context, ref, activeNote),
              ),
              if (isSummaryProcessing) ...[
                const SizedBox(height: 4),
                const LinearProgressIndicator(),
                const SizedBox(height: 10),
                Text(
                  'Creating summary preview...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (isSummaryForThisNote && state.isFailure) ...[
                const SizedBox(height: 10),
                _SmartNoteFailureCard(
                  message: state.errorMessage ?? 'Summary failed.',
                  onRetry: () =>
                      _showSummaryStylePicker(context, ref, activeNote),
                  manualLabel: 'Write summary',
                  onManualFallback: () =>
                      _openManualNoteEditor(context, ref, activeNote),
                ),
              ],
              if (isSummaryForThisNote && state.hasPreview) ...[
                const SizedBox(height: 12),
                _SummaryPreviewCard(
                  note: activeNote,
                  previewText: state.previewText ?? '',
                  previewJson: state.previewJson,
                ),
              ],
              _SmartToolTile(
                icon: Icons.playlist_add_check_outlined,
                title: 'AI action extraction',
                description: canExtractActions
                    ? 'Preview possible tasks before creating anything.'
                    : 'Add note content before extracting actions.',
                statusLabel: canExtractActions ? 'Run' : 'Needs text',
                enabled: canExtractActions && !isActionExtractionProcessing,
                onTap: activeNote == null
                    ? null
                    : () => ref
                          .read(smartNoteProcessingProvider.notifier)
                          .runActionExtraction(activeNote),
              ),
              if (isActionExtractionProcessing) ...[
                const SizedBox(height: 4),
                const LinearProgressIndicator(),
                const SizedBox(height: 10),
                Text(
                  'Finding possible actions...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (isActionExtractionForThisNote && state.isFailure) ...[
                const SizedBox(height: 10),
                _SmartNoteFailureCard(
                  message: state.errorMessage ?? 'Action extraction failed.',
                  onRetry: () => ref
                      .read(smartNoteProcessingProvider.notifier)
                      .runActionExtraction(activeNote),
                  manualLabel: 'Edit note',
                  onManualFallback: () =>
                      _openManualNoteEditor(context, ref, activeNote),
                ),
              ],
              if (isActionExtractionForThisNote && state.hasPreview) ...[
                const SizedBox(height: 12),
                _ActionExtractionPreviewCard(
                  note: activeNote,
                  previewJson: state.previewJson,
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'Text extraction never changes the note until you choose an action.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showSummaryStylePicker(
  BuildContext context,
  WidgetRef ref,
  NoteModel note,
) async {
  final style = await showDialog<NoteSummaryStyle>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Summary style'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final style in NoteSummaryStyle.values)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(style.label),
              subtitle: Text(style.description),
              onTap: () => Navigator.of(context).pop(style),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );
  if (style == null || !context.mounted) return;
  await ref.read(smartNoteProcessingProvider.notifier).runSummary(note, style);
}

Future<void> _openManualNoteEditor(
  BuildContext context,
  WidgetRef ref,
  NoteModel note,
) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => CreateNoteSheet(initialNote: note),
  );
  if (!context.mounted) return;
  await ref.read(notesProvider.notifier).loadNotes();
}

class _SummaryPreviewCard extends ConsumerStatefulWidget {
  final NoteModel note;
  final String previewText;
  final Map<String, dynamic>? previewJson;

  const _SummaryPreviewCard({
    required this.note,
    required this.previewText,
    required this.previewJson,
  });

  @override
  ConsumerState<_SummaryPreviewCard> createState() =>
      _SummaryPreviewCardState();
}

class _SummaryPreviewCardState extends ConsumerState<_SummaryPreviewCard> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.previewText);
  }

  @override
  void didUpdateWidget(covariant _SummaryPreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.previewText != widget.previewText) {
      _controller.text = widget.previewText;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = _summaryStyleFromPreview(widget.previewJson);
    final confidence = widget.previewJson?['confidence']?.toString() ?? 'low';
    final fallbackUsed = widget.previewJson?['fallback_used'] == true;
    final safetyNotes = widget.previewJson?['safety_notes']?.toString();
    final lowConfidence = confidence == 'low';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.summarize_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${style.label} summary preview',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Chip(label: Text(confidence)),
            ],
          ),
          if (fallbackUsed ||
              lowConfidence ||
              (safetyNotes != null && safetyNotes.isNotEmpty)) ...[
            const SizedBox(height: 10),
            _SmartNoteNotice(
              message: fallbackUsed
                  ? safetyNotes ??
                        'Fallback summary created. Review before inserting.'
                  : safetyNotes?.isNotEmpty == true
                  ? safetyNotes!
                  : 'Low confidence summary. Review carefully before inserting.',
              color: fallbackUsed || lowConfidence
                  ? AppColors.warning
                  : AppColors.primary,
            ),
          ],
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            minLines: 4,
            maxLines: 8,
            decoration: InputDecoration(
              hintText: 'Review and edit summary before inserting.',
              filled: true,
              fillColor: Theme.of(context).cardTheme.color,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, _) {
              final editedSummary = value.text.trim();
              final hasSummary = editedSummary.isNotEmpty;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: hasSummary
                        ? () =>
                              _insertSummary(context, ref, style, editedSummary)
                        : null,
                    icon: const Icon(Icons.add_outlined),
                    label: const Text('Insert'),
                  ),
                  OutlinedButton.icon(
                    onPressed: hasSummary
                        ? () async {
                            await Clipboard.setData(
                              ClipboardData(text: editedSummary),
                            );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Summary copied.')),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.copy_outlined),
                    label: const Text('Copy'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => ref
                        .read(smartNoteProcessingProvider.notifier)
                        .runSummary(widget.note, style),
                    icon: const Icon(Icons.refresh_outlined),
                    label: const Text('Regenerate'),
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.read(smartNoteProcessingProvider.notifier).reset(),
                    child: const Text('Cancel'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _insertSummary(
    BuildContext context,
    WidgetRef ref,
    NoteSummaryStyle style,
    String summary,
  ) async {
    await ref
        .read(notesProvider.notifier)
        .updateNote(
          noteId: widget.note.id,
          title: widget.note.title,
          content: _appendSummaryText(widget.note.content, style, summary),
          taskId: widget.note.taskId,
          noteType: widget.note.noteType,
          tags: widget.note.tags,
          checklistItems: widget.note.checklistItems,
          structuredBlocks: widget.note.structuredBlocks,
          attachments: widget.note.attachments,
          reminderAt: widget.note.reminderAt,
          sourceType: widget.note.sourceType,
          colorKey: widget.note.colorKey,
        );
    ref
        .read(smartNoteProcessingProvider.notifier)
        .markSuccess(jobType: SmartNoteJobType.summary, noteId: widget.note.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Summary inserted.')));
    Navigator.of(context).pop();
  }
}

class _ActionExtractionPreviewCard extends ConsumerStatefulWidget {
  final NoteModel note;
  final Map<String, dynamic>? previewJson;

  const _ActionExtractionPreviewCard({
    required this.note,
    required this.previewJson,
  });

  @override
  ConsumerState<_ActionExtractionPreviewCard> createState() =>
      _ActionExtractionPreviewCardState();
}

class _ActionExtractionPreviewCardState
    extends ConsumerState<_ActionExtractionPreviewCard> {
  late List<_EditableActionSuggestion> _items;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _items = _buildEditableItems(widget.previewJson);
  }

  @override
  void didUpdateWidget(covariant _ActionExtractionPreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.previewJson != widget.previewJson) {
      for (final item in _items) {
        item.dispose();
      }
      _items = _buildEditableItems(widget.previewJson);
    }
  }

  @override
  void dispose() {
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = NoteActionExtractionResult.fromJson(
      widget.previewJson ?? {},
    );
    final hasSelected = _items.any((item) => item.isSelected);
    final hasInvalidDates = _items.any((item) => item.hasInvalidDates);
    final hasLowConfidence = _items.any((item) => item.confidence == 'low');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.playlist_add_check_outlined,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Action suggestions',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Chip(label: Text('${_items.length} found')),
            ],
          ),
          const SizedBox(height: 10),
          _SmartNoteNotice(
            message:
                result.safetyNotes ??
                'Review, edit, or reject each suggestion before creating anything.',
            color: result.fallbackUsed ? AppColors.warning : AppColors.primary,
          ),
          if (hasLowConfidence) ...[
            const SizedBox(height: 10),
            const _SmartNoteNotice(
              message:
                  'Some suggestions have low confidence. Edit or reject them before creating.',
              color: AppColors.warning,
            ),
          ],
          const SizedBox(height: 12),
          for (var index = 0; index < _items.length; index++) ...[
            _EditableActionSuggestionTile(
              item: _items[index],
              onChanged: () => setState(() {}),
            ),
            if (index != _items.length - 1) const SizedBox(height: 10),
          ],
          if (hasInvalidDates) ...[
            const SizedBox(height: 10),
            const _SmartNoteError(
              message: 'Use ISO date/time format or clear invalid date fields.',
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: !_isSaving && hasSelected && !hasInvalidDates
                    ? _confirmSelectedActions
                    : null,
                icon: const Icon(Icons.check_outlined),
                label: Text(_isSaving ? 'Creating...' : 'Create selected'),
              ),
              OutlinedButton.icon(
                onPressed: _isSaving
                    ? null
                    : () => ref
                          .read(smartNoteProcessingProvider.notifier)
                          .runActionExtraction(widget.note),
                icon: const Icon(Icons.refresh_outlined),
                label: const Text('Regenerate'),
              ),
              TextButton(
                onPressed: _isSaving
                    ? null
                    : () => ref
                          .read(smartNoteProcessingProvider.notifier)
                          .reset(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSelectedActions() async {
    final selected = _items.where((item) => item.isSelected).toList();
    if (selected.isEmpty) return;

    setState(() => _isSaving = true);
    var createdTasks = 0;
    var addedChecklistItems = 0;
    var failed = false;

    for (final item in selected) {
      final title = item.titleController.text.trim();
      if (title.isEmpty) continue;
      if (item.itemType == 'checklist_item') {
        addedChecklistItems++;
        continue;
      }

      final created = await ref
          .read(tasksProvider.notifier)
          .createTask(
            title: title,
            priority: 'medium',
            dueAt: _parseActionDate(item.dueDateController.text),
            reminderAt: _parseActionDate(item.reminderTimeController.text),
            category: _categoryForActionType(item.itemType),
          );
      if (created) {
        createdTasks++;
      } else {
        failed = true;
      }
    }

    if (addedChecklistItems > 0) {
      final checklistItems = [
        ...widget.note.checklistItems,
        for (final item in selected.where(
          (item) => item.itemType == 'checklist_item',
        ))
          ChecklistItemModel(
            id: 'smart_${DateTime.now().microsecondsSinceEpoch}_${item.hashCode}',
            text: item.titleController.text.trim(),
            isCompleted: false,
          ),
      ];
      await ref
          .read(notesProvider.notifier)
          .updateNote(
            noteId: widget.note.id,
            title: widget.note.title,
            content: widget.note.content,
            taskId: widget.note.taskId,
            noteType: widget.note.noteType,
            tags: widget.note.tags,
            checklistItems: checklistItems,
            structuredBlocks: widget.note.structuredBlocks,
            attachments: widget.note.attachments,
            reminderAt: widget.note.reminderAt,
            sourceType: widget.note.sourceType,
            colorKey: widget.note.colorKey,
          );
    }

    ref
        .read(smartNoteProcessingProvider.notifier)
        .markSuccess(
          jobType: SmartNoteJobType.actionExtraction,
          noteId: widget.note.id,
        );

    if (!mounted) return;
    setState(() => _isSaving = false);
    final message = failed
        ? 'Some suggestions could not be created.'
        : 'Created $createdTasks task(s), added $addedChecklistItems checklist item(s).';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    if (!failed) Navigator.of(context).pop();
  }
}

class _EditableActionSuggestionTile extends StatelessWidget {
  final _EditableActionSuggestion item;
  final VoidCallback onChanged;

  const _EditableActionSuggestionTile({
    required this.item,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Checkbox(
                value: item.isSelected,
                onChanged: (value) {
                  item.isSelected = value ?? false;
                  onChanged();
                },
              ),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: item.itemType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(value: 'task', child: Text('Task')),
                    DropdownMenuItem(
                      value: 'reminder',
                      child: Text('Reminder'),
                    ),
                    DropdownMenuItem(
                      value: 'checklist_item',
                      child: Text('Checklist item'),
                    ),
                    DropdownMenuItem(
                      value: 'calendar_suggestion',
                      child: Text('Calendar suggestion'),
                    ),
                    DropdownMenuItem(
                      value: 'focus_suggestion',
                      child: Text('Focus suggestion'),
                    ),
                  ],
                  onChanged: (value) {
                    item.itemType = value ?? 'task';
                    onChanged();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Chip(label: Text(item.confidence)),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: item.titleController,
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(
              labelText: 'Title',
              prefixIcon: Icon(Icons.edit_outlined),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: item.dueDateController,
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(
              labelText: 'Due date',
              hintText: 'YYYY-MM-DDTHH:MM:SS',
              prefixIcon: const Icon(Icons.event_outlined),
              errorText: _invalidActionDate(item.dueDateController.text)
                  ? 'Invalid date'
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: item.reminderTimeController,
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(
              labelText: 'Reminder time',
              hintText: 'YYYY-MM-DDTHH:MM:SS',
              prefixIcon: const Icon(Icons.notifications_outlined),
              errorText: _invalidActionDate(item.reminderTimeController.text)
                  ? 'Invalid date'
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              item.reason,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableActionSuggestion {
  String itemType;
  bool isSelected;
  final String confidence;
  final String reason;
  final TextEditingController titleController;
  final TextEditingController dueDateController;
  final TextEditingController reminderTimeController;

  _EditableActionSuggestion({
    required this.itemType,
    required this.isSelected,
    required this.confidence,
    required this.reason,
    required String title,
    String? dueDate,
    String? reminderTime,
  }) : titleController = TextEditingController(text: title),
       dueDateController = TextEditingController(text: dueDate ?? ''),
       reminderTimeController = TextEditingController(text: reminderTime ?? '');

  bool get hasInvalidDates {
    return _invalidActionDate(dueDateController.text) ||
        _invalidActionDate(reminderTimeController.text);
  }

  void dispose() {
    titleController.dispose();
    dueDateController.dispose();
    reminderTimeController.dispose();
  }
}

List<_EditableActionSuggestion> _buildEditableItems(
  Map<String, dynamic>? previewJson,
) {
  final result = NoteActionExtractionResult.fromJson(previewJson ?? {});
  return result.extractedItems
      .map(
        (item) => _EditableActionSuggestion(
          itemType: item.itemType,
          isSelected: item.requiresConfirmation,
          confidence: item.confidence,
          reason: item.reason,
          title: item.title,
          dueDate: item.dueDate,
          reminderTime: item.reminderTime,
        ),
      )
      .toList();
}

bool _invalidActionDate(String value) {
  final text = value.trim();
  return text.isNotEmpty && DateTime.tryParse(text) == null;
}

DateTime? _parseActionDate(String value) {
  final text = value.trim();
  if (text.isEmpty) return null;
  return DateTime.tryParse(text);
}

String _categoryForActionType(String itemType) {
  return switch (itemType) {
    'reminder' => 'smart_note_reminder',
    'calendar_suggestion' => 'smart_note_calendar',
    'focus_suggestion' => 'smart_note_focus',
    _ => 'smart_note',
  };
}

class _TextExtractionPreviewCard extends ConsumerStatefulWidget {
  final NoteModel note;
  final SmartNoteJobType jobType;
  final String previewText;
  final Map<String, dynamic>? previewJson;

  const _TextExtractionPreviewCard({
    required this.note,
    required this.jobType,
    required this.previewText,
    required this.previewJson,
  });

  @override
  ConsumerState<_TextExtractionPreviewCard> createState() =>
      _TextExtractionPreviewCardState();
}

class _TextExtractionPreviewCardState
    extends ConsumerState<_TextExtractionPreviewCard> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.previewText);
  }

  @override
  void didUpdateWidget(covariant _TextExtractionPreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.previewText != widget.previewText) {
      _controller.text = widget.previewText;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final confidence = _previewConfidence(widget.previewJson);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.text_snippet_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _textExtractionPreviewTitle(widget.jobType),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (widget.jobType == SmartNoteJobType.handwriting) ...[
            _HandwritingConfidenceNotice(confidence: confidence),
            const SizedBox(height: 10),
          ],
          TextField(
            controller: _controller,
            minLines: 4,
            maxLines: 8,
            decoration: InputDecoration(
              hintText: 'Review and edit extracted text before saving.',
              filled: true,
              fillColor: Theme.of(context).cardTheme.color,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, _) {
              final editedText = value.text.trim();
              final hasEditedText = editedText.isNotEmpty;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: hasEditedText
                        ? () => _applyExtractedText(
                            context,
                            ref,
                            _appendOcrText(widget.note.content, editedText),
                          )
                        : null,
                    icon: const Icon(Icons.add_outlined),
                    label: const Text('Append'),
                  ),
                  OutlinedButton.icon(
                    onPressed: hasEditedText
                        ? () async {
                            final confirmed = await confirmDestructiveAction(
                              context: context,
                              title: 'Replace note content?',
                              message:
                                  'This will replace the current note body with the reviewed text.',
                              confirmLabel: 'Replace',
                            );
                            if (!confirmed || !context.mounted) return;
                            await _applyExtractedText(context, ref, editedText);
                          }
                        : null,
                    icon: const Icon(Icons.swap_horiz_outlined),
                    label: const Text('Replace'),
                  ),
                  OutlinedButton.icon(
                    onPressed: hasEditedText
                        ? () async {
                            await Clipboard.setData(
                              ClipboardData(text: editedText),
                            );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Extracted text copied.'),
                              ),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.copy_outlined),
                    label: const Text('Copy'),
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.read(smartNoteProcessingProvider.notifier).reset(),
                    child: const Text('Cancel'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _applyExtractedText(
    BuildContext context,
    WidgetRef ref,
    String content,
  ) async {
    await ref
        .read(notesProvider.notifier)
        .updateNote(
          noteId: widget.note.id,
          title: widget.note.title,
          content: content,
          taskId: widget.note.taskId,
          noteType: widget.note.noteType,
          tags: widget.note.tags,
          checklistItems: widget.note.checklistItems,
          structuredBlocks: widget.note.structuredBlocks,
          attachments: widget.note.attachments,
          reminderAt: widget.note.reminderAt,
          sourceType: widget.note.sourceType,
          colorKey: widget.note.colorKey,
        );
    ref
        .read(smartNoteProcessingProvider.notifier)
        .markSuccess(jobType: widget.jobType, noteId: widget.note.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${_textExtractionActionName(widget.jobType)} saved to note.',
        ),
      ),
    );
    Navigator.of(context).pop();
  }
}

class _HandwritingConfidenceNotice extends StatelessWidget {
  final double? confidence;

  const _HandwritingConfidenceNotice({required this.confidence});

  @override
  Widget build(BuildContext context) {
    final confidenceText = confidence == null
        ? 'Confidence unavailable on this device.'
        : 'Estimated confidence: ${(confidence! * 100).round()}%.';
    final needsCarefulReview = confidence == null || confidence! < 0.65;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.28)),
      ),
      child: Text(
        needsCarefulReview
            ? '$confidenceText Review carefully before saving.'
            : '$confidenceText Still review before saving; handwriting is best-effort.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.warning,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SmartNoteNotice extends StatelessWidget {
  final String message;
  final Color color;

  const _SmartNoteNotice({required this.message, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

NoteSummaryStyle _summaryStyleFromPreview(Map<String, dynamic>? previewJson) {
  return noteSummaryStyleFromApi(
    previewJson?['summary_style']?.toString() ?? 'short',
  );
}

String _appendSummaryText(
  String currentContent,
  NoteSummaryStyle style,
  String summary,
) {
  final current = currentContent.trimRight();
  final reviewedSummary = summary.trim();
  final block = 'Summary (${style.label})\n$reviewedSummary';
  if (current.isEmpty) return block;
  return '$current\n\n$block';
}

String _textExtractionPreviewTitle(SmartNoteJobType jobType) {
  return switch (jobType) {
    SmartNoteJobType.handwriting => 'Handwriting preview',
    _ => 'Extracted text preview',
  };
}

String _textExtractionActionName(SmartNoteJobType jobType) {
  return switch (jobType) {
    SmartNoteJobType.handwriting => 'Handwriting text',
    _ => 'Extracted text',
  };
}

double? _previewConfidence(Map<String, dynamic>? previewJson) {
  final confidence = previewJson?['average_confidence'];
  if (confidence is num) {
    return confidence.toDouble().clamp(0.0, 1.0).toDouble();
  }
  return null;
}

String _appendOcrText(String currentContent, String extractedText) {
  final current = currentContent.trimRight();
  final extracted = extractedText.trim();
  if (current.isEmpty) return extracted;
  return '$current\n\n$extracted';
}

class _SmartNoteError extends StatelessWidget {
  final String message;

  const _SmartNoteError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.24)),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.error,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SmartNoteFailureCard extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String manualLabel;
  final VoidCallback onManualFallback;

  const _SmartNoteFailureCard({
    required this.message,
    this.onRetry,
    required this.manualLabel,
    required this.onManualFallback,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (onRetry != null)
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_outlined),
                  label: const Text('Try again'),
                ),
              TextButton.icon(
                onPressed: onManualFallback,
                icon: const Icon(Icons.edit_outlined),
                label: Text(manualLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmartToolTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String statusLabel;
  final bool enabled;
  final VoidCallback? onTap;

  const _SmartToolTile({
    required this.icon,
    required this.title,
    required this.description,
    this.statusLabel = 'Future',
    this.enabled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = enabled ? AppColors.primary : AppColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: foreground.withValues(alpha: enabled ? 0.36 : 0.18),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: foreground),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Chip(label: Text(statusLabel)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
