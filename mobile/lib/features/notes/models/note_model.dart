class ChecklistItemModel {
  final String id;
  final String text;
  final bool isCompleted;

  const ChecklistItemModel({
    required this.id,
    required this.text,
    required this.isCompleted,
  });

  factory ChecklistItemModel.fromJson(Map<String, dynamic> json) {
    return ChecklistItemModel(
      id: json['id'] as String,
      text: json['text'] as String,
      isCompleted: json['is_completed'] as bool? ?? false,
    );
  }

  ChecklistItemModel copyWith({String? text, bool? isCompleted}) {
    return ChecklistItemModel(
      id: id,
      text: text ?? this.text,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'text': text, 'is_completed': isCompleted};
  }
}

class NoteStructuredBlockModel {
  final String id;
  final String type;
  final String? text;
  final List<String> items;
  final List<ChecklistItemModel> checklistItems;
  final String? reminderAt;
  final String? taskId;
  final String? taskTitle;

  const NoteStructuredBlockModel({
    required this.id,
    required this.type,
    this.text,
    this.items = const [],
    this.checklistItems = const [],
    this.reminderAt,
    this.taskId,
    this.taskTitle,
  });

  factory NoteStructuredBlockModel.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? 'paragraph';
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return NoteStructuredBlockModel(
      id: json['id'] as String,
      type: type,
      text: json['text'] as String?,
      items: type == 'bullet_list'
          ? rawItems.map((item) => item.toString()).toList()
          : const [],
      checklistItems: type == 'checklist'
          ? rawItems
                .whereType<Map<String, dynamic>>()
                .map(ChecklistItemModel.fromJson)
                .toList()
          : const [],
      reminderAt: json['reminder_at'] as String?,
      taskId: json['task_id'] as String?,
      taskTitle: json['task_title'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{'id': id, 'type': type};
    if (text != null && text!.isNotEmpty) data['text'] = text;
    if (type == 'bullet_list') data['items'] = items;
    if (type == 'checklist') {
      data['items'] = checklistItems.map((item) => item.toJson()).toList();
    }
    if (reminderAt != null) data['reminder_at'] = reminderAt;
    if (taskId != null && taskId!.isNotEmpty) data['task_id'] = taskId;
    if (taskTitle != null && taskTitle!.isNotEmpty) {
      data['task_title'] = taskTitle;
    }
    return data;
  }
}

class NoteModel {
  final String id;
  final String? title;
  final String content;
  final String noteType;
  final List<String> tags;
  final List<ChecklistItemModel> checklistItems;
  final List<NoteStructuredBlockModel> structuredBlocks;
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
    required this.checklistItems,
    required this.structuredBlocks,
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
      checklistItems:
          (json['checklist_items'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(ChecklistItemModel.fromJson)
              .toList() ??
          [],
      structuredBlocks:
          (json['structured_blocks'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(NoteStructuredBlockModel.fromJson)
              .toList() ??
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
