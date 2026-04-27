class NoteModel {
  final String id;
  final String? title;
  final String content;
  final String noteType;
  final List<String> tags;
  final String colorKey;
  final bool isPinned;
  final bool isArchived;
  final String? archivedAt;
  final String createdAt;
  final String updatedAt;

  NoteModel({
    required this.id,
    this.title,
    required this.content,
    required this.noteType,
    required this.tags,
    required this.colorKey,
    required this.isPinned,
    required this.isArchived,
    this.archivedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'] as String,
      title: json['title'] as String?,
      content: json['content'] as String,
      noteType: json['note_type'] as String,
      tags:
          (json['tags'] as List<dynamic>?)?.map((t) => t.toString()).toList() ??
          [],
      colorKey: json['color_key'] as String? ?? 'default',
      isPinned: json['is_pinned'] as bool,
      isArchived: json['is_archived'] as bool,
      archivedAt: json['archived_at'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }
}
