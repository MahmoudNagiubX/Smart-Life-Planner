class ParsedVoiceSubtaskModel {
  final String title;
  final bool completed;

  ParsedVoiceSubtaskModel({required this.title, this.completed = false});

  factory ParsedVoiceSubtaskModel.fromJson(Map<String, dynamic> json) {
    return ParsedVoiceSubtaskModel(
      title: json['title'] as String,
      completed: json['completed'] as bool? ?? false,
    );
  }
}

class ParsedVoiceTaskModel {
  final String title;
  final String? description;
  final String? dueDate;
  final String? dueTime;
  final String priority;
  final int? estimatedDurationMinutes;
  final String? project;
  final String? category;
  final List<ParsedVoiceSubtaskModel> subtasks;

  // Editable fields
  bool isSelected;

  ParsedVoiceTaskModel({
    required this.title,
    this.description,
    this.dueDate,
    this.dueTime,
    required this.priority,
    this.estimatedDurationMinutes,
    this.project,
    this.category,
    this.subtasks = const [],
    this.isSelected = true,
  });

  factory ParsedVoiceTaskModel.fromJson(Map<String, dynamic> json) {
    return ParsedVoiceTaskModel(
      title: json['title'] as String,
      description: json['description'] as String?,
      dueDate: json['due_date'] as String?,
      dueTime: json['due_time'] as String?,
      priority: json['priority'] as String? ?? 'medium',
      estimatedDurationMinutes:
          json['estimated_duration_minutes'] as int?,
      project: json['project'] as String?,
      category: json['category'] as String?,
      subtasks: (json['subtasks'] as List<dynamic>? ?? [])
          .map((s) => ParsedVoiceSubtaskModel.fromJson(
              s as Map<String, dynamic>))
          .toList(),
    );
  }

  ParsedVoiceTaskModel copyWith({
    String? title,
    String? priority,
    String? dueDate,
    bool? isSelected,
  }) {
    return ParsedVoiceTaskModel(
      title: title ?? this.title,
      description: description,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime,
      priority: priority ?? this.priority,
      estimatedDurationMinutes: estimatedDurationMinutes,
      project: project,
      category: category,
      subtasks: subtasks,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

class VoiceParseResult {
  final String transcribedText;
  final String? language;
  final String provider;
  final String detectedIntent;
  final String confidence;
  final List<ParsedVoiceTaskModel> tasks;
  final bool confirmationRequired;
  final String displayText;

  VoiceParseResult({
    required this.transcribedText,
    this.language,
    required this.provider,
    required this.detectedIntent,
    required this.confidence,
    required this.tasks,
    required this.confirmationRequired,
    required this.displayText,
  });

  factory VoiceParseResult.fromJson(Map<String, dynamic> json) {
    return VoiceParseResult(
      transcribedText: json['transcribed_text'] as String,
      language: json['language'] as String?,
      provider: json['provider'] as String,
      detectedIntent: json['detected_intent'] as String,
      confidence: json['confidence'] as String,
      tasks: (json['tasks'] as List<dynamic>? ?? [])
          .map((t) => ParsedVoiceTaskModel.fromJson(
              t as Map<String, dynamic>))
          .toList(),
      confirmationRequired:
          json['confirmation_required'] as bool? ?? true,
      displayText: json['display_text'] as String,
    );
  }
}

class BulkCreateResult {
  final int createdCount;
  final List<dynamic> tasks;

  BulkCreateResult({required this.createdCount, required this.tasks});

  factory BulkCreateResult.fromJson(Map<String, dynamic> json) {
    return BulkCreateResult(
      createdCount: json['created_count'] as int,
      tasks: json['tasks'] as List<dynamic>,
    );
  }
}