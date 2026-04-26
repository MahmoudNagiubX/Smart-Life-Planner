import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_error.dart';
import '../../../core/theme/app_colors.dart';
import '../models/voice_note_model.dart';
import '../services/audio_recorder_service.dart';
import '../services/voice_api_service.dart';
import '../../notes/providers/note_provider.dart';
import '../../../core/network/providers.dart';

enum _VoiceNoteState { idle, recording, processing, preview, saving }

class VoiceNoteSheet extends ConsumerStatefulWidget {
  const VoiceNoteSheet({super.key});

  @override
  ConsumerState<VoiceNoteSheet> createState() => _VoiceNoteSheetState();
}

class _VoiceNoteSheetState extends ConsumerState<VoiceNoteSheet>
    with SingleTickerProviderStateMixin {
  final AudioRecorderService _recorder = AudioRecorderService();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  _VoiceNoteState _state = _VoiceNoteState.idle;
  VoiceNoteResult? _result;
  String? _error;
  int _recordingSeconds = 0;
  Timer? _timer;
  bool _isStartingRecording = false;

  // Editable fields
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(_pulseController);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _startRecording() async {
    if (_isStartingRecording || _state != _VoiceNoteState.idle) return;

    setState(() {
      _isStartingRecording = true;
      _error = null;
    });

    try {
      final hasPermission = await _recorder.hasPermission();
      if (!mounted) return;

      if (!hasPermission) {
        setState(() {
          _isStartingRecording = false;
          _error = 'Microphone permission required.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎙️ Microphone permission required.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      await _recorder.startRecording();
      if (!mounted) return;

      setState(() {
        _state = _VoiceNoteState.recording;
        _recordingSeconds = 0;
        _isStartingRecording = false;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _recordingSeconds++);
        if (_recordingSeconds >= 60) _stopAndProcess();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isStartingRecording = false;
        _error = 'Could not start recording: $e';
      });
    }
  }

  Future<void> _stopAndProcess() async {
    _timer?.cancel();
    final path = await _recorder.stopRecording();

    if (path == null) {
      setState(() {
        _state = _VoiceNoteState.idle;
        _error = 'Recording failed. Please try again.';
      });
      return;
    }

    setState(() => _state = _VoiceNoteState.processing);

    try {
      final service = VoiceApiService(ref.read(apiClientProvider));
      final audioBytes = await _recorder.readRecordingBytes(path);
      final result = await service.transcribeNoteBytes(
        audioBytes: audioBytes,
        filename: _recorder.currentFilename,
      );

      await _recorder.deleteRecording(path);

      setState(() {
        _result = result;
        _state = _VoiceNoteState.preview;
        _titleController.text = result.title ?? '';
        _contentController.text = result.content;
      });
    } on DioException catch (e) {
      setState(() {
        _state = _VoiceNoteState.idle;
        _error = friendlyApiError(e, 'Voice processing failed. Try again.');
      });
    } catch (_) {
      setState(() {
        _state = _VoiceNoteState.idle;
        _error = 'Something went wrong. Please try again.';
      });
    }
  }

  Future<void> _saveNote() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _state = _VoiceNoteState.saving);

    await ref
        .read(notesProvider.notifier)
        .createNote(
          content: content,
          title: _titleController.text.trim().isEmpty
              ? null
              : _titleController.text.trim(),
        );

    if (mounted) Navigator.pop(context, true);
  }

  Color _confidenceColor(String c) {
    if (c == 'high') return AppColors.success;
    if (c == 'medium') return AppColors.warning;
    return AppColors.error;
  }

  String _noteTypeEmoji(String type) {
    switch (type) {
      case 'checklist':
        return '☑️';
      case 'reflection':
        return '💭';
      default:
        return '📝';
    }
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

          // Build based on state
          if (_state == _VoiceNoteState.idle) _buildIdleState(),
          if (_state == _VoiceNoteState.recording) _buildRecordingState(),
          if (_state == _VoiceNoteState.processing) _buildProcessingState(),
          if (_state == _VoiceNoteState.preview) _buildPreviewState(),
          if (_state == _VoiceNoteState.saving) _buildSavingState(),
        ],
      ),
    );
  }

  Widget _buildIdleState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🎙️ Voice Note',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Speak your note — AI will organize it for you',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _error!,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
        ],
        const SizedBox(height: 32),
        Center(
          child: InkWell(
            onTap: _startRecording,
            borderRadius: BorderRadius.circular(56),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: _isStartingRecording
                        ? const Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Icon(Icons.mic, color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isStartingRecording ? 'Starting...' : 'Tap to record',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildRecordingState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '🎙️ Recording...',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Speak naturally — tap stop when done',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        Text(
          _formatTime(_recordingSeconds),
          style: const TextStyle(
            color: AppColors.error,
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${60 - _recordingSeconds}s remaining',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: _recordingSeconds / 60,
          backgroundColor: AppColors.error.withValues(alpha: 0.15),
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.error),
          minHeight: 4,
        ),
        const SizedBox(height: 24),
        Center(
          child: ScaleTransition(
            scale: _pulseAnimation,
            child: GestureDetector(
              onTap: _stopAndProcess,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.error.withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 6,
                    ),
                  ],
                ),
                child: const Icon(Icons.stop, color: Colors.white, size: 36),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildProcessingState() {
    return Column(
      children: [
        const SizedBox(height: 16),
        const CircularProgressIndicator(color: AppColors.primary),
        const SizedBox(height: 20),
        Text(
          'Organizing your note...',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          '🤖 Transcribing → Structuring content',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPreviewState() {
    final result = _result!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          children: [
            Text(
              '${_noteTypeEmoji(result.noteType)} AI Note Preview',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _confidenceColor(
                  result.confidence,
                ).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                result.confidence.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _confidenceColor(result.confidence),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),

        // Original transcript
        Text(
          '"${result.transcribedText}"',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 16),

        // Editable title
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Title (optional)',
            prefixIcon: Icon(Icons.title),
          ),
        ),
        const SizedBox(height: 12),

        // Editable content
        TextField(
          controller: _contentController,
          maxLines: 6,
          minLines: 3,
          decoration: const InputDecoration(
            labelText: 'Note content',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 12),

        // Tags row
        if (result.tags.isNotEmpty)
          Wrap(
            spacing: 6,
            children: result.tags
                .map(
                  (tag) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '#$tag',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),

        const SizedBox(height: 16),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() {
                  _state = _VoiceNoteState.idle;
                  _result = null;
                  _error = null;
                  _titleController.clear();
                  _contentController.clear();
                }),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Re-record'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 46)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _saveNote,
                icon: const Icon(Icons.save, size: 18),
                label: const Text('Save Note'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(0, 46)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSavingState() {
    return const Column(
      children: [
        SizedBox(height: 16),
        CircularProgressIndicator(color: AppColors.primary),
        SizedBox(height: 16),
        Text('Saving your note...'),
        SizedBox(height: 16),
      ],
    );
  }
}
