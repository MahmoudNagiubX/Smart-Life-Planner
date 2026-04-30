enum NoteSummaryStyle { short, bullets, studyNotes, actionFocused }

extension NoteSummaryStyleX on NoteSummaryStyle {
  String get apiKey {
    return switch (this) {
      NoteSummaryStyle.short => 'short',
      NoteSummaryStyle.bullets => 'bullets',
      NoteSummaryStyle.studyNotes => 'study_notes',
      NoteSummaryStyle.actionFocused => 'action_focused',
    };
  }

  String get label {
    return switch (this) {
      NoteSummaryStyle.short => 'Short',
      NoteSummaryStyle.bullets => 'Bullets',
      NoteSummaryStyle.studyNotes => 'Study notes',
      NoteSummaryStyle.actionFocused => 'Action focused',
    };
  }

  String get description {
    return switch (this) {
      NoteSummaryStyle.short => 'One or two concise sentences.',
      NoteSummaryStyle.bullets => 'A compact bullet summary.',
      NoteSummaryStyle.studyNotes => 'Key ideas and review points.',
      NoteSummaryStyle.actionFocused => 'Decisions and follow-ups only.',
    };
  }
}

NoteSummaryStyle noteSummaryStyleFromApi(String value) {
  return switch (value) {
    'bullets' => NoteSummaryStyle.bullets,
    'study_notes' => NoteSummaryStyle.studyNotes,
    'action_focused' => NoteSummaryStyle.actionFocused,
    _ => NoteSummaryStyle.short,
  };
}

class NoteSummaryResult {
  final String summary;
  final String confidence;
  final bool fallbackUsed;
  final String? safetyNotes;

  const NoteSummaryResult({
    required this.summary,
    required this.confidence,
    required this.fallbackUsed,
    this.safetyNotes,
  });

  factory NoteSummaryResult.fromJson(Map<String, dynamic> json) {
    return NoteSummaryResult(
      summary: json['summary'] as String? ?? '',
      confidence: json['confidence'] as String? ?? 'low',
      fallbackUsed: json['fallback_used'] as bool? ?? false,
      safetyNotes: json['safety_notes'] as String?,
    );
  }
}
