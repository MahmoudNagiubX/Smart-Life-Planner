import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/note_provider.dart';
import '../models/note_model.dart';
import '../../voice/screens/voice_note_sheet.dart';

class CreateNoteSheet extends ConsumerStatefulWidget {
  final NoteModel? initialNote;

  const CreateNoteSheet({super.key, this.initialNote});

  @override
  ConsumerState<CreateNoteSheet> createState() => _CreateNoteSheetState();
}

class _CreateNoteSheetState extends ConsumerState<CreateNoteSheet> {
  final _titleController = TextEditingController();
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
  bool _isLoading = false;

  bool get _isEditing => widget.initialNote != null;

  @override
  void initState() {
    super.initState();
    final note = widget.initialNote;
    if (note == null) return;

    _titleController.text = note.title ?? '';
    _contentController.text = note.content;
    _tagsController.text = note.tags.join(', ');
    _noteType = note.noteType == 'checklist' ? 'checklist' : 'text';
    _selectedColorKey = note.colorKey;
    if (note.reminderAt != null) {
      _reminderAt = DateTime.tryParse(note.reminderAt!)?.toLocal();
    }
    _attachments.addAll(note.attachments);

    for (final block in note.structuredBlocks) {
      if (block.type == 'bullet_list') {
        _bulletController.text = block.items.join('\n');
      } else if (_reminderAt == null &&
          block.type == 'reminder' &&
          block.reminderAt != null) {
        _reminderAt = DateTime.tryParse(block.reminderAt!)?.toLocal();
      } else if (block.type == 'task_link') {
        _linkedTaskController.text = block.taskTitle ?? block.taskId ?? '';
      }
    }

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

  @override
  void dispose() {
    _titleController.dispose();
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
            backgroundColor: AppColors.error,
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
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _submit() async {
    final checklistItems = _noteType == 'checklist'
        ? _buildChecklistItems()
        : <ChecklistItemModel>[];
    final content = _noteType == 'checklist'
        ? checklistItems.map((item) => item.text).join('\n')
        : _contentController.text.trim();
    if (content.isEmpty) return;
    final structuredBlocks = _buildStructuredBlocks(
      content: content,
      checklistItems: checklistItems,
    );

    setState(() => _isLoading = true);

    if (_isEditing) {
      await ref
          .read(notesProvider.notifier)
          .updateNote(
            noteId: widget.initialNote!.id,
            content: content,
            title: _titleController.text.trim().isEmpty
                ? null
                : _titleController.text.trim(),
            noteType: _noteType,
            tags: _parseTags(),
            checklistItems: _noteType == 'checklist' ? checklistItems : null,
            structuredBlocks: structuredBlocks,
            attachments: _attachments,
            reminderAt: _reminderAt?.toUtc().toIso8601String(),
            clearReminderAt: _reminderAt == null,
            colorKey: _selectedColorKey,
          );
    } else {
      await ref
          .read(notesProvider.notifier)
          .createNote(
            content: content,
            title: _titleController.text.trim().isEmpty
                ? null
                : _titleController.text.trim(),
            noteType: _noteType,
            tags: _parseTags(),
            checklistItems: _noteType == 'checklist' ? checklistItems : null,
            structuredBlocks: structuredBlocks,
            attachments: _attachments,
            reminderAt: _reminderAt?.toUtc().toIso8601String(),
            colorKey: _selectedColorKey,
          );
    }

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
    }
  }

  Future<void> _openVoiceNote() async {
    // Close this sheet first
    Navigator.pop(context);

    // Open voice note sheet
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const VoiceNoteSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
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
                  color: AppColors.textSecondary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header row with voice button
            Row(
              children: [
                Text(
                  _isEditing ? 'Edit Note' : '📝 New Note',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                // 🎙️ Voice note button
                GestureDetector(
                  onTap: _openVoiceNote,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.mic, color: AppColors.primary, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Voice',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title (optional)'),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
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
                decoration: const InputDecoration(labelText: 'Note content'),
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
                  avatar: const Icon(Icons.notifications_outlined, size: 18),
                  label: Text(
                    _reminderAt == null
                        ? 'Reminder'
                        : _reminderAt!.toLocal().toString().substring(0, 16),
                  ),
                  onPressed: _pickReminder,
                ),
                if (_reminderAt != null)
                  ActionChip(
                    avatar: const Icon(Icons.close, size: 18),
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
                            color: option.color ?? Theme.of(context).cardColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _selectedColorKey == option.key
                                  ? AppColors.primary
                                  : AppColors.textSecondary.withValues(
                                      alpha: 0.35,
                                    ),
                              width: _selectedColorKey == option.key ? 2 : 1,
                            ),
                          ),
                          child: _selectedColorKey == option.key
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
            const SizedBox(height: 20),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submit,
                    child: Text(_isEditing ? 'Update Note' : 'Save Note'),
                  ),
          ],
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
                final path = attachment.localPath;
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: path == null
                          ? Container(
                              width: 92,
                              height: 92,
                              color: AppColors.cardDark,
                              child: const Icon(Icons.broken_image_outlined),
                            )
                          : Image.file(
                              File(path),
                              width: 92,
                              height: 92,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    width: 92,
                                    height: 92,
                                    color: AppColors.cardDark,
                                    child: const Icon(
                                      Icons.broken_image_outlined,
                                    ),
                                  ),
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
