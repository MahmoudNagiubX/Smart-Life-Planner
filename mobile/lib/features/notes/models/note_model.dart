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
    final text = _jsonString(json['text']);
    return ChecklistItemModel(
      id: _jsonString(json['id'], fallback: 'item_${text.hashCode}'),
      text: text,
      isCompleted: _jsonBool(json['is_completed']),
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
  final String? imageUrl;
  final String? localPath;
  final String? fileType;
  final String? reminderAt;
  final String? taskId;
  final String? taskTitle;

  const NoteStructuredBlockModel({
    required this.id,
    required this.type,
    this.text,
    this.items = const [],
    this.checklistItems = const [],
    this.imageUrl,
    this.localPath,
    this.fileType,
    this.reminderAt,
    this.taskId,
    this.taskTitle,
  });

  factory NoteStructuredBlockModel.fromJson(Map<String, dynamic> json) {
    final type = _jsonString(json['type'], fallback: 'paragraph');
    final rawItems = _jsonList(json['items']);
    return NoteStructuredBlockModel(
      id: _jsonString(json['id'], fallback: 'block_${json.hashCode}'),
      type: type,
      text: _jsonNullableString(json['text']),
      items: type == 'bullet_list'
          ? rawItems.map((item) => item.toString()).toList()
          : const [],
      checklistItems: type == 'checklist'
          ? rawItems
                .map(_jsonMap)
                .whereType<Map<String, dynamic>>()
                .map(ChecklistItemModel.fromJson)
                .toList()
          : const [],
      imageUrl: _jsonNullableString(json['image_url']),
      localPath: _jsonNullableString(json['local_path']),
      fileType: _jsonNullableString(json['file_type']),
      reminderAt: _jsonNullableString(json['reminder_at']),
      taskId: _jsonNullableString(json['task_id']),
      taskTitle: _jsonNullableString(json['task_title']),
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{'id': id, 'type': type};
    if (text != null && text!.isNotEmpty) data['text'] = text;
    if (type == 'bullet_list') data['items'] = items;
    if (type == 'checklist') {
      data['items'] = checklistItems.map((item) => item.toJson()).toList();
    }
    if (imageUrl != null && imageUrl!.isNotEmpty) data['image_url'] = imageUrl;
    if (localPath != null && localPath!.isNotEmpty) {
      data['local_path'] = localPath;
    }
    if (fileType != null && fileType!.isNotEmpty) data['file_type'] = fileType;
    if (reminderAt != null) data['reminder_at'] = reminderAt;
    if (taskId != null && taskId!.isNotEmpty) data['task_id'] = taskId;
    if (taskTitle != null && taskTitle!.isNotEmpty) {
      data['task_title'] = taskTitle;
    }
    return data;
  }
}

class NoteAttachmentModel {
  final String? id;
  final String? noteId;
  final String? fileUrl;
  final String? localPath;
  final String fileType;
  final int fileSize;
  final String? createdAt;

  const NoteAttachmentModel({
    this.id,
    this.noteId,
    this.fileUrl,
    this.localPath,
    required this.fileType,
    required this.fileSize,
    this.createdAt,
  });

  factory NoteAttachmentModel.fromJson(Map<String, dynamic> json) {
    return NoteAttachmentModel(
      id: _jsonNullableString(json['id']),
      noteId: _jsonNullableString(json['note_id']),
      fileUrl: _jsonNullableString(json['file_url']),
      localPath: _jsonNullableString(json['local_path']),
      fileType: _jsonString(json['file_type'], fallback: 'image/jpeg'),
      fileSize: _jsonInt(json['file_size']),
      createdAt: _jsonNullableString(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (fileUrl != null) 'file_url': fileUrl,
      if (localPath != null) 'local_path': localPath,
      'file_type': fileType,
      'file_size': fileSize,
    };
  }

  String? get displaySource {
    final local = localPath?.trim();
    if (local != null && local.isNotEmpty) return local;
    final remote = fileUrl?.trim();
    if (remote != null && remote.isNotEmpty) return remote;
    return null;
  }

  bool get isImage {
    final type = fileType.trim().toLowerCase();
    final source = displaySource?.toLowerCase() ?? '';
    return type.startsWith('image/') ||
        source.endsWith('.jpg') ||
        source.endsWith('.jpeg') ||
        source.endsWith('.png') ||
        source.endsWith('.webp') ||
        source.endsWith('.heic');
  }
}

class NoteModel {
  final String id;
  final String? taskId;
  final String? title;
  final String content;
  final String noteType;
  final List<String> tags;
  final List<ChecklistItemModel> checklistItems;
  final List<NoteStructuredBlockModel> structuredBlocks;
  final List<NoteAttachmentModel> attachments;
  final String colorKey;
  final bool isPinned;
  final bool isArchived;
  final String? archivedAt;
  final String? reminderAt;
  final String sourceType;
  final String createdAt;
  final String updatedAt;

  NoteModel({
    required this.id,
    this.taskId,
    this.title,
    required this.content,
    required this.noteType,
    required this.tags,
    required this.checklistItems,
    required this.structuredBlocks,
    required this.attachments,
    required this.colorKey,
    required this.isPinned,
    required this.isArchived,
    this.archivedAt,
    this.reminderAt,
    required this.sourceType,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: _jsonString(json['id']),
      taskId: _jsonNullableString(json['task_id']),
      title: _jsonNullableString(json['title']),
      content: _jsonString(json['content']),
      noteType: _jsonString(json['note_type'], fallback: 'text'),
      tags: _jsonList(json['tags']).map((t) => t.toString()).toList(),
      checklistItems: _jsonList(json['checklist_items'])
          .map(_jsonMap)
          .whereType<Map<String, dynamic>>()
          .map(ChecklistItemModel.fromJson)
          .toList(),
      structuredBlocks: _jsonList(json['structured_blocks'])
          .map(_jsonMap)
          .whereType<Map<String, dynamic>>()
          .map(NoteStructuredBlockModel.fromJson)
          .toList(),
      attachments: _jsonList(json['attachments'])
          .map(_jsonMap)
          .whereType<Map<String, dynamic>>()
          .map(NoteAttachmentModel.fromJson)
          .toList(),
      colorKey: _jsonString(json['color_key'], fallback: 'default'),
      isPinned: _jsonBool(json['is_pinned']),
      isArchived: _jsonBool(json['is_archived']),
      archivedAt: _jsonNullableString(json['archived_at']),
      reminderAt: _jsonNullableString(json['reminder_at']),
      sourceType: _jsonString(json['source_type'], fallback: 'manual'),
      createdAt: _jsonString(json['created_at']),
      updatedAt: _jsonString(json['updated_at']),
    );
  }

  List<NoteAttachmentModel> get imageAttachments {
    final merged = <NoteAttachmentModel>[];
    final seen = <String>{};

    void addAttachment(NoteAttachmentModel attachment) {
      if (!attachment.isImage) return;
      final source = attachment.displaySource;
      if (source == null || source.isEmpty || !seen.add(source)) return;
      merged.add(attachment);
    }

    for (final attachment in attachments) {
      addAttachment(attachment);
    }

    for (final block in structuredBlocks) {
      if (block.type != 'image') continue;
      addAttachment(
        NoteAttachmentModel(
          fileUrl: block.imageUrl,
          localPath: block.localPath,
          fileType: block.fileType ?? 'image/jpeg',
          fileSize: 0,
        ),
      );
    }

    return merged;
  }
}

String _jsonString(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? fallback : text;
}

String? _jsonNullableString(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

bool _jsonBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final clean = value.trim().toLowerCase();
    if (clean == 'true' || clean == '1') return true;
    if (clean == 'false' || clean == '0') return false;
  }
  return fallback;
}

int _jsonInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

List<dynamic> _jsonList(dynamic value) {
  return value is List<dynamic> ? value : const [];
}

Map<String, dynamic>? _jsonMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return null;
}
