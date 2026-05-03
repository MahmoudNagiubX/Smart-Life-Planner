import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_tokens.dart';
import '../models/app_template_library.dart';
import '../providers/note_provider.dart';
import '../models/note_model.dart';
import '../../voice/screens/voice_note_sheet.dart';

class CreateNoteSheet extends ConsumerStatefulWidget {
  final NoteModel? initialNote;
  final String? linkedTaskId;
  final AppTemplate? template;

  const CreateNoteSheet({
    super.key,
    this.initialNote,
    this.linkedTaskId,
    this.template,
  });

  @override
  ConsumerState<CreateNoteSheet> createState() => _CreateNoteSheetState();
}

class _CreateNoteSheetState extends ConsumerState<CreateNoteSheet> {
  final _titleController = TextEditingController();
  final _headingController = TextEditingController();
  final _contentController = TextEditingController();
  final _bulletController = TextEditingController();
  final _tagsController = TextEditingController();
  final _linkedTaskController = TextEditingController();
  final List<_ChecklistDraftItem> _checklistItems = [];
  final List<NoteAttachmentModel> _attachments = [];
  final ImagePicker _imagePicker = ImagePicker();
  DateTime? _reminderAt;
  String _noteType = 'text';
  String _selectedColorKey = 'default';
  bool _dividerEnabled = false;
  bool _isLoading = false;

  bool get _isEditing => widget.initialNote != null;

  @override
  void initState() {
    super.initState();
    final note = widget.initialNote;
    if (note == null) {
      final template = widget.template;
      if (template != null) {
        _titleController.text = template.noteTitle;
        _contentController.text = template.noteContent;
        _tagsController.text = template.tags.join(', ');
        for (final block in template.blocks) {
          _hydrateStructuredBlock(block);
        }
      }
      return;
    }

    _titleController.text = note.title ?? '';
    _contentController.text = note.content;
    _tagsController.text = note.tags.join(', ');
    _noteType = note.noteType == 'checklist' ? 'checklist' : 'text';
    _selectedColorKey = note.colorKey;
    if (note.reminderAt != null) {
      _reminderAt = DateTime.tryParse(note.reminderAt!)?.toLocal();
    }
    _attachments.addAll(note.attachments);
    final seenSources = _attachments
        .map((attachment) => attachment.displaySource)
        .whereType<String>()
        .toSet();
    for (final attachment in note.imageAttachments) {
      final source = attachment.displaySource;
      if (source != null && seenSources.add(source)) {
        _attachments.add(attachment);
      }
    }

    for (final block in note.structuredBlocks) {
      _hydrateStructuredBlock(block);
    }

    if (_checklistItems.isEmpty) {
      final checklistItems = note.checklistItems.isNotEmpty
          ? note.checklistItems
          : note.structuredBlocks
                .where((block) => block.type == 'checklist')
                .expand((block) => block.checklistItems)
                .toList();
      for (final item in checklistItems) {
        _checklistItems.add(
          _ChecklistDraftItem(
            id: item.id,
            text: item.text,
            isCompleted: item.isCompleted,
          ),
        );
      }
    }
  }

  void _hydrateStructuredBlock(NoteStructuredBlockModel block) {
    if (block.type == 'heading') {
      _headingController.text = block.text ?? '';
    } else if (block.type == 'bullet_list') {
      _bulletController.text = block.items.join('\n');
    } else if (block.type == 'divider') {
      _dividerEnabled = true;
    } else if (_reminderAt == null &&
        block.type == 'reminder' &&
        block.reminderAt != null) {
      _reminderAt = DateTime.tryParse(block.reminderAt!)?.toLocal();
    } else if (block.type == 'task_link') {
      _linkedTaskController.text = block.taskTitle ?? block.taskId ?? '';
    } else if (block.type == 'checklist') {
      _noteType = 'checklist';
      for (final item in block.checklistItems) {
        _checklistItems.add(
          _ChecklistDraftItem(
            id: item.id,
            text: item.text,
            isCompleted: item.isCompleted,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _headingController.dispose();
    _contentController.dispose();
    _bulletController.dispose();
    _tagsController.dispose();
    _linkedTaskController.dispose();
    for (final item in _checklistItems) {
      item.controller.dispose();
    }
    super.dispose();
  }

  List<String> _parseTags() {
    final tags = <String>[];
    final seen = <String>{};
    for (final raw in _tagsController.text.split(',')) {
      final tag = raw.trim().toLowerCase().replaceFirst(RegExp(r'^#+'), '');
      if (tag.isEmpty || seen.contains(tag)) continue;
      seen.add(tag);
      tags.add(tag);
    }
    return tags;
  }

  void _addChecklistItem() {
    setState(() {
      _checklistItems.add(
        _ChecklistDraftItem(
          id: 'item_${DateTime.now().microsecondsSinceEpoch}',
        ),
      );
    });
  }

  List<ChecklistItemModel> _buildChecklistItems() {
    return _checklistItems
        .map(
          (item) => ChecklistItemModel(
            id: item.id,
            text: item.controller.text.trim(),
            isCompleted: item.isCompleted,
          ),
        )
        .where((item) => item.text.isNotEmpty)
        .toList();
  }

  List<String> _parseBulletItems() {
    return _bulletController.text
        .split('\n')
        .map((line) => line.trim().replaceFirst(RegExp(r'^[-*]\s*'), ''))
        .where((line) => line.isNotEmpty)
        .toList();
  }

  List<NoteStructuredBlockModel> _buildStructuredBlocks({
    required String content,
    required List<ChecklistItemModel> checklistItems,
  }) {
    final blocks = <NoteStructuredBlockModel>[];
    final heading = _headingController.text.trim();
    if (heading.isNotEmpty) {
      blocks.add(
        NoteStructuredBlockModel(
          id: 'heading_main',
          type: 'heading',
          text: heading,
        ),
      );
    }

    if (content.trim().isNotEmpty) {
      blocks.add(
        NoteStructuredBlockModel(
          id: 'paragraph_main',
          type: 'paragraph',
          text: content.trim(),
        ),
      );
    }

    final bulletItems = _parseBulletItems();
    if (bulletItems.isNotEmpty) {
      blocks.add(
        NoteStructuredBlockModel(
          id: 'bullet_main',
          type: 'bullet_list',
          items: bulletItems,
        ),
      );
    }

    if (checklistItems.isNotEmpty) {
      blocks.add(
        NoteStructuredBlockModel(
          id: 'checklist_main',
          type: 'checklist',
          checklistItems: checklistItems,
        ),
      );
    }

    if (_dividerEnabled) {
      blocks.add(
        const NoteStructuredBlockModel(id: 'divider_main', type: 'divider'),
      );
    }

    if (_reminderAt != null) {
      blocks.add(
        NoteStructuredBlockModel(
          id: 'reminder_main',
          type: 'reminder',
          reminderAt: _reminderAt!.toUtc().toIso8601String(),
        ),
      );
    }

    final linkedTaskText = _linkedTaskController.text.trim();
    if (linkedTaskText.isNotEmpty) {
      blocks.add(
        NoteStructuredBlockModel(
          id: 'task_link_main',
          type: 'task_link',
          taskTitle: linkedTaskText,
        ),
      );
    }

    for (var index = 0; index < _attachments.length; index++) {
      final attachment = _attachments[index];
      blocks.add(
        NoteStructuredBlockModel(
          id: 'image_$index',
          type: 'image',
          imageUrl: attachment.fileUrl,
          localPath: attachment.localPath,
          fileType: attachment.fileType,
        ),
      );
    }

    return blocks;
  }

  Future<void> _pickReminder() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _reminderAt ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_reminderAt ?? now),
    );
    if (time == null) return;
    setState(() {
      _reminderAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  String _imageMimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }

  Future<void> _pickImage() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image == null) return;
      final size = await image.length();
      if (size > 15 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image is too large.'),
            backgroundColor: AppColors.errorColor,
          ),
        );
        return;
      }
      setState(() {
        _attachments.add(
          NoteAttachmentModel(
            localPath: image.path,
            fileType: _imageMimeType(image.path),
            fileSize: size,
          ),
        );
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image could not be added.'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  Future<void> _submit() async {
    final checklistItems = _noteType == 'checklist'
        ? _buildChecklistItems()
        : <ChecklistItemModel>[];
    final rawContent = _noteType == 'checklist'
        ? checklistItems.map((item) => item.text).join('\n')
        : _contentController.text.trim();
    final content = rawContent.isNotEmpty
        ? rawContent
        : _headingController.text.trim().isNotEmpty
        ? _headingController.text.trim()
        : _titleController.text.trim();
    if (content.isEmpty) return;
    final structuredBlocks = _buildStructuredBlocks(
      content: content,
      checklistItems: checklistItems,
    );

    setState(() => _isLoading = true);

    final saved = _isEditing
        ? await ref
              .read(notesProvider.notifier)
              .updateNote(
                noteId: widget.initialNote!.id,
                content: content,
                taskId: widget.linkedTaskId ?? widget.initialNote!.taskId,
                title: _titleController.text.trim().isEmpty
                    ? null
                    : _titleController.text.trim(),
                noteType: _noteType,
                tags: _parseTags(),
                checklistItems: _noteType == 'checklist'
                    ? checklistItems
                    : null,
                structuredBlocks: structuredBlocks,
                attachments: _attachments,
                reminderAt: _reminderAt?.toUtc().toIso8601String(),
                clearReminderAt: _reminderAt == null,
                colorKey: _selectedColorKey,
              )
        : await ref
              .read(notesProvider.notifier)
              .createNote(
                content: content,
                taskId: widget.linkedTaskId,
                title: _titleController.text.trim().isEmpty
                    ? null
                    : _titleController.text.trim(),
                noteType: _noteType,
                tags: _parseTags(),
                checklistItems: _noteType == 'checklist'
                    ? checklistItems
                    : null,
                structuredBlocks: structuredBlocks,
                attachments: _attachments,
                reminderAt: _reminderAt?.toUtc().toIso8601String(),
                colorKey: _selectedColorKey,
              );

    if (mounted) {
      setState(() => _isLoading = false);
      if (saved) {
        Navigator.pop(context);
      } else {
        final error =
            ref.read(notesProvider).error ??
            'Note could not be saved. Please try again.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  Future<void> _openVoiceNote() async {
    // Close this sheet first
    Navigator.pop(context);

    // Open voice note sheet
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const VoiceNoteSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: AppRadius.sheetBr,
          boxShadow: AppShadows.floating,
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.s20,
            right: AppSpacing.s20,
            top: AppSpacing.s16,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.s24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderSoft,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s20),

                // Header row with voice button
                Row(
                  children: [
                    Text(
                      _isEditing ? 'Edit Note' : 'New Note',
                      style: AppTextStyles.h3Light,
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _openVoiceNote,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.bgSurfaceLavender,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: AppColors.brandPrimary.withValues(
                              alpha: 0.22,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.mic,
                              color: AppColors.brandPrimary,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Voice',
                              style: AppTextStyles.label(
                                AppColors.brandPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s16),

                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title (optional)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _headingController,
                  decoration: const InputDecoration(
                    labelText: 'Heading block',
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      return states.contains(WidgetState.selected)
                          ? AppColors.bgSurfaceLavender
                          : AppColors.bgSurfaceSoft;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      return states.contains(WidgetState.selected)
                          ? AppColors.brandPrimary
                          : AppColors.textBody;
                    }),
                    side: WidgetStateProperty.all(
                      const BorderSide(color: AppColors.borderSoft),
                    ),
                    textStyle: WidgetStateProperty.all(
                      AppTextStyles.label(AppColors.textHeading),
                    ),
                  ),
                  segments: const [
                    ButtonSegment(
                      value: 'text',
                      icon: Icon(Icons.notes),
                      label: Text('Text'),
                    ),
                    ButtonSegment(
                      value: 'checklist',
                      icon: Icon(Icons.checklist),
                      label: Text('Checklist'),
                    ),
                  ],
                  selected: {_noteType},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _noteType = selection.first;
                      if (_noteType == 'checklist' && _checklistItems.isEmpty) {
                        _checklistItems.add(
                          _ChecklistDraftItem(
                            id: 'item_${DateTime.now().microsecondsSinceEpoch}',
                          ),
                        );
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                if (_noteType == 'text')
                  TextField(
                    controller: _contentController,
                    autofocus: true,
                    maxLines: 5,
                    minLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Note content',
                    ),
                  )
                else
                  _ChecklistEditor(
                    items: _checklistItems,
                    onAdd: _addChecklistItem,
                    onChanged: () => setState(() {}),
                    onRemove: (item) {
                      setState(() {
                        _checklistItems.remove(item);
                        item.controller.dispose();
                      });
                    },
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: _bulletController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Bullet list',
                    hintText: 'One bullet per line',
                    prefixIcon: Icon(Icons.format_list_bulleted),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.bgSurfaceSoft,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.borderSoft),
                  ),
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s12,
                    ),
                    secondary: const Icon(
                      Icons.horizontal_rule,
                      color: AppColors.brandPrimary,
                    ),
                    title: Text(
                      'Divider block',
                      style: AppTextStyles.body(AppColors.textHeading),
                    ),
                    activeThumbColor: AppColors.brandPrimary,
                    value: _dividerEnabled,
                    onChanged: (value) =>
                        setState(() => _dividerEnabled = value),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _tagsController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Tags',
                    hintText: 'study, ideas, reflection',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                ),
                if (_parseTags().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _parseTags()
                        .map(
                          (tag) => Chip(
                            avatar: const Icon(Icons.label_outline, size: 15),
                            label: Text('#$tag'),
                            labelStyle: AppTextStyles.caption(
                              AppColors.brandPrimary,
                            ),
                            backgroundColor: AppColors.bgSurfaceLavender,
                            side: const BorderSide(color: AppColors.borderSoft),
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      avatar: const Icon(
                        Icons.notifications_outlined,
                        size: 18,
                      ),
                      backgroundColor: AppColors.bgSurfaceSoft,
                      side: const BorderSide(color: AppColors.borderSoft),
                      label: Text(
                        _reminderAt == null
                            ? 'Reminder'
                            : _reminderAt!.toLocal().toString().substring(
                                0,
                                16,
                              ),
                      ),
                      onPressed: _pickReminder,
                    ),
                    if (_reminderAt != null)
                      ActionChip(
                        avatar: const Icon(Icons.close, size: 18),
                        backgroundColor: AppColors.bgSurfaceSoft,
                        side: const BorderSide(color: AppColors.borderSoft),
                        label: const Text('Clear reminder'),
                        onPressed: () => setState(() => _reminderAt = null),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _linkedTaskController,
                  decoration: const InputDecoration(
                    labelText: 'Linked task block (optional)',
                    hintText: 'Task title or reference',
                    prefixIcon: Icon(Icons.task_alt),
                  ),
                ),
                const SizedBox(height: 12),
                _AttachmentEditor(
                  attachments: _attachments,
                  onAdd: _pickImage,
                  onRemove: (attachment) {
                    setState(() => _attachments.remove(attachment));
                  },
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _noteColorOptions
                      .map(
                        (option) => Tooltip(
                          message: option.label,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () =>
                                setState(() => _selectedColorKey = option.key),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: option.color ?? AppColors.bgSurfaceSoft,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _selectedColorKey == option.key
                                      ? AppColors.brandPrimary
                                      : AppColors.borderSoft,
                                  width: _selectedColorKey == option.key
                                      ? 2
                                      : 1,
                                ),
                              ),
                              child: _selectedColorKey == option.key
                                  ? const Icon(
                                      Icons.check,
                                      color: AppColors.brandPrimary,
                                      size: 18,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: AppSpacing.s20),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _SheetPrimaryButton(
                        label: _isEditing ? 'Update Note' : 'Save Note',
                        onPressed: _submit,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _SheetPrimaryButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppButtonHeight.primary,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppGradients.action,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.glowPurple,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: onPressed,
            child: Center(
              child: Text(label, style: AppTextStyles.button(Colors.white)),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChecklistDraftItem {
  final String id;
  final TextEditingController controller = TextEditingController();
  bool isCompleted = false;

  _ChecklistDraftItem({
    required this.id,
    String text = '',
    this.isCompleted = false,
  }) {
    controller.text = text;
  }
}

class _ChecklistEditor extends StatelessWidget {
  final List<_ChecklistDraftItem> items;
  final VoidCallback onAdd;
  final VoidCallback onChanged;
  final ValueChanged<_ChecklistDraftItem> onRemove;

  const _ChecklistEditor({
    required this.items,
    required this.onAdd,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Checkbox(
                  activeColor: AppColors.brandPrimary,
                  value: item.isCompleted,
                  onChanged: (value) {
                    item.isCompleted = value ?? false;
                    onChanged();
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: item.controller,
                    onChanged: (_) => onChanged(),
                    decoration: const InputDecoration(
                      hintText: 'Checklist item',
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Remove item',
                  onPressed: () => onRemove(item),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add item'),
          ),
        ),
      ],
    );
  }
}

class _AttachmentEditor extends StatelessWidget {
  final List<NoteAttachmentModel> attachments;
  final VoidCallback onAdd;
  final ValueChanged<NoteAttachmentModel> onRemove;

  const _AttachmentEditor({
    required this.attachments,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.image_outlined),
          label: const Text('Add image'),
        ),
        if (attachments.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: attachments.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final attachment = attachments[index];
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _NoteAttachmentImage(
                        attachment: attachment,
                        width: 92,
                        height: 92,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => onRemove(attachment),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _NoteAttachmentImage extends StatelessWidget {
  final NoteAttachmentModel attachment;
  final double width;
  final double height;

  const _NoteAttachmentImage({
    required this.attachment,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final source = attachment.displaySource;
    if (source == null) {
      return _MissingNoteImage(width: width, height: height);
    }

    final uri = Uri.tryParse(source);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return Image.network(
        source,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _MissingNoteImage(width: width, height: height),
      );
    }

    if (source.startsWith('/')) {
      final base = Uri.tryParse(ApiClient.baseUrl);
      if (base != null && base.hasScheme) {
        final origin = base.replace(path: '', query: '', fragment: '');
        return Image.network(
          origin.resolve(source).toString(),
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _MissingNoteImage(width: width, height: height),
        );
      }
    }

    final file = File(
      uri != null && uri.scheme == 'file' ? uri.toFilePath() : source,
    );
    return Image.file(
      file,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          _MissingNoteImage(width: width, height: height),
    );
  }
}

class _MissingNoteImage extends StatelessWidget {
  final double width;
  final double height;

  const _MissingNoteImage({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: AppColors.bgSurfaceLavender,
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: AppColors.textHint,
      ),
    );
  }
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
