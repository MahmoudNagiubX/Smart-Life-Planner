enum SmartNoteProcessingPhase { idle, processing, preview, success, fail }

enum SmartNoteJobType { ocr, handwriting, summary, actionExtraction }

class SmartNoteProcessingState {
  final SmartNoteProcessingPhase phase;
  final SmartNoteJobType? jobType;
  final String? jobId;
  final String? noteId;
  final String? inputAttachmentId;
  final String? previewText;
  final Map<String, dynamic>? previewJson;
  final String? errorMessage;

  const SmartNoteProcessingState({
    this.phase = SmartNoteProcessingPhase.idle,
    this.jobType,
    this.jobId,
    this.noteId,
    this.inputAttachmentId,
    this.previewText,
    this.previewJson,
    this.errorMessage,
  });

  bool get isIdle => phase == SmartNoteProcessingPhase.idle;
  bool get isProcessing => phase == SmartNoteProcessingPhase.processing;
  bool get hasPreview => phase == SmartNoteProcessingPhase.preview;
  bool get isSuccess => phase == SmartNoteProcessingPhase.success;
  bool get isFailure => phase == SmartNoteProcessingPhase.fail;

  SmartNoteProcessingState copyWith({
    SmartNoteProcessingPhase? phase,
    SmartNoteJobType? jobType,
    String? jobId,
    String? noteId,
    String? inputAttachmentId,
    String? previewText,
    Map<String, dynamic>? previewJson,
    String? errorMessage,
    bool clearPreview = false,
    bool clearError = false,
  }) {
    return SmartNoteProcessingState(
      phase: phase ?? this.phase,
      jobType: jobType ?? this.jobType,
      jobId: jobId ?? this.jobId,
      noteId: noteId ?? this.noteId,
      inputAttachmentId: inputAttachmentId ?? this.inputAttachmentId,
      previewText: clearPreview ? null : previewText ?? this.previewText,
      previewJson: clearPreview ? null : previewJson ?? this.previewJson,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  factory SmartNoteProcessingState.processing({
    required SmartNoteJobType jobType,
    required String noteId,
    String? jobId,
    String? inputAttachmentId,
  }) {
    return SmartNoteProcessingState(
      phase: SmartNoteProcessingPhase.processing,
      jobType: jobType,
      noteId: noteId,
      jobId: jobId,
      inputAttachmentId: inputAttachmentId,
    );
  }

  factory SmartNoteProcessingState.preview({
    required SmartNoteJobType jobType,
    required String noteId,
    String? jobId,
    String? inputAttachmentId,
    String? previewText,
    Map<String, dynamic>? previewJson,
  }) {
    return SmartNoteProcessingState(
      phase: SmartNoteProcessingPhase.preview,
      jobType: jobType,
      noteId: noteId,
      jobId: jobId,
      inputAttachmentId: inputAttachmentId,
      previewText: previewText,
      previewJson: previewJson,
    );
  }

  factory SmartNoteProcessingState.success({
    required SmartNoteJobType jobType,
    required String noteId,
    String? jobId,
  }) {
    return SmartNoteProcessingState(
      phase: SmartNoteProcessingPhase.success,
      jobType: jobType,
      noteId: noteId,
      jobId: jobId,
    );
  }

  factory SmartNoteProcessingState.fail({
    required SmartNoteJobType jobType,
    required String noteId,
    required String errorMessage,
    String? jobId,
  }) {
    return SmartNoteProcessingState(
      phase: SmartNoteProcessingPhase.fail,
      jobType: jobType,
      noteId: noteId,
      jobId: jobId,
      errorMessage: errorMessage,
    );
  }
}

String smartNoteJobTypeToApi(SmartNoteJobType type) {
  return switch (type) {
    SmartNoteJobType.ocr => 'ocr',
    SmartNoteJobType.handwriting => 'handwriting',
    SmartNoteJobType.summary => 'summary',
    SmartNoteJobType.actionExtraction => 'action_extraction',
  };
}

SmartNoteJobType smartNoteJobTypeFromApi(String value) {
  return switch (value) {
    'ocr' => SmartNoteJobType.ocr,
    'handwriting' => SmartNoteJobType.handwriting,
    'summary' => SmartNoteJobType.summary,
    'action_extraction' => SmartNoteJobType.actionExtraction,
    _ => SmartNoteJobType.summary,
  };
}
