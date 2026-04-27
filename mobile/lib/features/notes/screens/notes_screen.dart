import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_empty_state.dart';
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
                    .loadNotes(search: value.isEmpty ? null : value);
              },
            ),
          ),
          const SizedBox(height: 8),

          // Notes list
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                ? Center(child: Text(state.error!))
                : state.notes.isEmpty
                ? const AppEmptyState(
                    icon: Icons.note_add_outlined,
                    title: 'No notes yet',
                    message:
                        'Capture a note, idea, or voice transcript when you are ready.',
                  )
                : RefreshIndicator(
                    onRefresh: () =>
                        ref.read(notesProvider.notifier).loadNotes(),
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
                onSelected: (value) {
                  if (value == 'pin') {
                    ref
                        .read(notesProvider.notifier)
                        .togglePin(note.id, note.isPinned);
                  } else if (value == 'delete') {
                    ref.read(notesProvider.notifier).deleteNote(note.id);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'pin',
                    child: Text(note.isPinned ? 'Unpin' : 'Pin'),
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
          Text(
            note.content,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
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
}
