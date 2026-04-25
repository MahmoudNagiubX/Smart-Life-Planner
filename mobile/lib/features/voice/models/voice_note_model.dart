class VoiceNoteResult {
  final String transcribedText;
  final String? language;
  final String provider;
  final String? title;
  final String content;
  final String noteType;
  final List<String> tags;
  final String confidence;

  VoiceNoteResult({
    required this.transcribedText,
    this.language,
    required this.provider,
    this.title,
    required this.content,
    required this.noteType,
    required this.tags,
    required this.confidence,
  });

  factory VoiceNoteResult.fromJson(Map<String, dynamic> json) {
    return VoiceNoteResult(
      transcribedText: json['transcribed_text'] as String,
      language: json['language'] as String?,
      provider: json['provider'] as String,
      title: json['title'] as String?,
      content: json['content'] as String,
      noteType: json['note_type'] as String? ?? 'text',
      tags: (json['tags'] as List<dynamic>?)
              ?.map((t) => t.toString())
              .toList() ??
          [],
      confidence: json['confidence'] as String? ?? 'low',
    );
  }
}