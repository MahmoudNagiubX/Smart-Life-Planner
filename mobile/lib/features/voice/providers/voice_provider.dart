import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_error.dart';
import '../../../core/network/providers.dart';
import '../models/voice_result_model.dart';
import '../services/audio_recorder_service.dart';
import '../services/voice_api_service.dart';

final voiceApiServiceProvider = Provider<VoiceApiService>((ref) {
  return VoiceApiService(ref.watch(apiClientProvider));
});

enum VoiceScreenState {
  idle,
  listening,
  processing,
  transcriptPreview,
  success,
  failed,
}

class VoiceState {
  final VoiceScreenState screenState;
  final VoiceParseResult? result;
  final List<ParsedVoiceTaskModel> editableTasks;
  final String editableTranscript;
  final String? error;
  final int recordingSeconds;
  final String? audioPath;

  const VoiceState({
    this.screenState = VoiceScreenState.idle,
    this.result,
    this.editableTasks = const [],
    this.editableTranscript = '',
    this.error,
    this.recordingSeconds = 0,
    this.audioPath,
  });

  VoiceState copyWith({
    VoiceScreenState? screenState,
    VoiceParseResult? result,
    List<ParsedVoiceTaskModel>? editableTasks,
    String? editableTranscript,
    String? error,
    int? recordingSeconds,
    String? audioPath,
  }) {
    return VoiceState(
      screenState: screenState ?? this.screenState,
      result: result ?? this.result,
      editableTasks: editableTasks ?? this.editableTasks,
      editableTranscript: editableTranscript ?? this.editableTranscript,
      error: error,
      recordingSeconds: recordingSeconds ?? this.recordingSeconds,
      audioPath: audioPath ?? this.audioPath,
    );
  }
}

class VoiceNotifier extends StateNotifier<VoiceState> {
  final Ref _ref;
  final AudioRecorderService _recorder = AudioRecorderService();

  VoiceNotifier(this._ref) : super(const VoiceState());

  Future<bool> checkPermission() async {
    return await _recorder.hasPermission();
  }

  Future<void> startRecording() async {
    state = state.copyWith(
      screenState: VoiceScreenState.listening,
      recordingSeconds: 0,
      error: null,
    );
    await _recorder.startRecording();
  }

  Future<void> stopAndProcess() async {
    final path = await _recorder.stopRecording();
    if (path == null) {
      state = state.copyWith(
        screenState: VoiceScreenState.failed,
        error: 'Recording failed. Please try again.',
      );
      return;
    }

    state = state.copyWith(
      screenState: VoiceScreenState.processing,
      audioPath: path,
    );

    try {
      final service = _ref.read(voiceApiServiceProvider);
      final result = await service.transcribeAndParse(audioPath: path);

      state = state.copyWith(
        screenState: VoiceScreenState.transcriptPreview,
        result: result,
        editableTasks: List.from(result.tasks),
        editableTranscript: result.transcribedText,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        screenState: VoiceScreenState.failed,
        error: friendlyApiError(e, 'Voice processing failed. Try again.'),
      );
    } catch (e) {
      state = state.copyWith(
        screenState: VoiceScreenState.failed,
        error: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<void> cancelRecording() async {
    await _recorder.cancelRecording();
    state = const VoiceState();
  }

  void tickTimer() {
    state = state.copyWith(recordingSeconds: state.recordingSeconds + 1);
    if (state.recordingSeconds >= 60) {
      stopAndProcess();
    }
  }

  void toggleTaskSelection(int index) {
    final tasks = List<ParsedVoiceTaskModel>.from(state.editableTasks);
    tasks[index] = tasks[index].copyWith(isSelected: !tasks[index].isSelected);
    state = state.copyWith(editableTasks: tasks);
  }

  void updateTaskTitle(int index, String title) {
    final tasks = List<ParsedVoiceTaskModel>.from(state.editableTasks);
    tasks[index] = tasks[index].copyWith(title: title);
    state = state.copyWith(editableTasks: tasks);
  }

  void updateTaskPriority(int index, String priority) {
    final tasks = List<ParsedVoiceTaskModel>.from(state.editableTasks);
    tasks[index] = tasks[index].copyWith(priority: priority);
    state = state.copyWith(editableTasks: tasks);
  }

  void updateTranscript(String transcript) {
    state = state.copyWith(editableTranscript: transcript);
  }

  void addManualTaskFromTranscript() {
    final title = state.editableTranscript.trim();
    if (title.isEmpty) return;

    final tasks = List<ParsedVoiceTaskModel>.from(state.editableTasks)
      ..add(
        ParsedVoiceTaskModel(
          title: title,
          priority: 'medium',
          isSelected: true,
        ),
      );
    state = state.copyWith(editableTasks: tasks);
  }

  void startManualEntry() {
    state = VoiceState(
      screenState: VoiceScreenState.transcriptPreview,
      result: VoiceParseResult(
        transcribedText: '',
        language: 'manual',
        provider: 'manual',
        detectedIntent: 'manual_task_fallback',
        confidence: 'low',
        tasks: const [],
        confirmationRequired: true,
        requiresConfirmation: true,
        displayText: 'Enter the transcript or task manually.',
        fallbackReason: 'manual_entry',
      ),
      editableTranscript: '',
    );
  }

  Future<int> confirmTasks() async {
    final selectedTasks = state.editableTasks
        .where((t) => t.isSelected)
        .toList();
    if (selectedTasks.isEmpty) return 0;

    final service = _ref.read(voiceApiServiceProvider);
    final result = await service.bulkCreateTasks(selectedTasks);
    state = state.copyWith(screenState: VoiceScreenState.success);
    return result.createdCount;
  }

  void reset() {
    state = const VoiceState();
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }
}

final voiceProvider = StateNotifierProvider<VoiceNotifier, VoiceState>((ref) {
  return VoiceNotifier(ref);
});
