import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/note_provider.dart';
import '../models/note_model.dart';
import '../../voice/screens/voice_note_sheet.dart';

class CreateNoteSheet extends ConsumerStatefulWidget {
  const CreateNoteSheet({super.key});

  @override
  ConsumerState<CreateNoteSheet> createState() => _CreateNoteSheetState();
}

class _CreateNoteSheetState extends ConsumerState<CreateNoteSheet> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();
  final List<_ChecklistDraftItem> _checklistItems = [];
  String _noteType = 'text';
  String _selectedColorKey = 'default';
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
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

  Future<void> _submit() async {
    final checklistItems = _noteType == 'checklist'
        ? _buildChecklistItems()
        : <ChecklistItemModel>[];
    final content = _noteType == 'checklist'
        ? checklistItems.map((item) => item.text).join('\n')
        : _contentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isLoading = true);

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
          colorKey: _selectedColorKey,
        );

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
                  '📝 New Note',
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
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags',
                hintText: 'study, ideas, reflection',
                prefixIcon: Icon(Icons.label_outline),
              ),
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
                    child: const Text('Save Note'),
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

  _ChecklistDraftItem({required this.id});
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
