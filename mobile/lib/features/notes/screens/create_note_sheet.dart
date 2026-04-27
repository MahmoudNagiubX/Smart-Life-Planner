import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/note_provider.dart';
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
  String _selectedColorKey = 'default';
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
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

  Future<void> _submit() async {
    if (_contentController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);

    await ref
        .read(notesProvider.notifier)
        .createNote(
          content: _contentController.text.trim(),
          title: _titleController.text.trim().isEmpty
              ? null
              : _titleController.text.trim(),
          tags: _parseTags(),
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
          TextField(
            controller: _contentController,
            autofocus: true,
            maxLines: 5,
            minLines: 3,
            decoration: const InputDecoration(labelText: 'Note content'),
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
