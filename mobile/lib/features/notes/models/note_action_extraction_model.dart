class NoteActionExtractionItemModel {
  final String itemType;
  final String title;
  final String? dueDate;
  final String? reminderTime;
  final String confidence;
  final String reason;
  final bool requiresConfirmation;

  const NoteActionExtractionItemModel({
    required this.itemType,
    required this.title,
    this.dueDate,
    this.reminderTime,
    required this.confidence,
    required this.reason,
    this.requiresConfirmation = true,
  });

  factory NoteActionExtractionItemModel.fromJson(Map<String, dynamic> json) {
    return NoteActionExtractionItemModel(
      itemType: json['item_type'] as String? ?? 'task',
      title: json['title'] as String? ?? '',
      dueDate: json['due_date'] as String?,
      reminderTime: json['reminder_time'] as String?,
      confidence: json['confidence'] as String? ?? 'low',
      reason: json['reason'] as String? ?? 'Suggested from note content.',
      requiresConfirmation: json['requires_confirmation'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_type': itemType,
      'title': title,
      if (dueDate != null) 'due_date': dueDate,
      if (reminderTime != null) 'reminder_time': reminderTime,
      'confidence': confidence,
      'reason': reason,
      'requires_confirmation': requiresConfirmation,
    };
  }
}

class NoteActionExtractionResult {
  final List<NoteActionExtractionItemModel> extractedItems;
  final bool requiresConfirmation;
  final bool fallbackUsed;
  final String? safetyNotes;

  const NoteActionExtractionResult({
    required this.extractedItems,
    this.requiresConfirmation = true,
    this.fallbackUsed = false,
    this.safetyNotes,
  });

  factory NoteActionExtractionResult.fromJson(Map<String, dynamic> json) {
    return NoteActionExtractionResult(
      extractedItems: (json['extracted_items'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(NoteActionExtractionItemModel.fromJson)
          .where((item) => item.title.trim().isNotEmpty)
          .toList(),
      requiresConfirmation: json['requires_confirmation'] as bool? ?? true,
      fallbackUsed: json['fallback_used'] as bool? ?? false,
      safetyNotes: json['safety_notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'extracted_items': extractedItems.map((item) => item.toJson()).toList(),
      'requires_confirmation': requiresConfirmation,
      'fallback_used': fallbackUsed,
      if (safetyNotes != null) 'safety_notes': safetyNotes,
    };
  }
}
