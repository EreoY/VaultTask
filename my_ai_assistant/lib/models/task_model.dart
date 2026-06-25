import 'dart:convert';

class TaskImage {
  final String id;
  final String url;
  final String r2Key;
  final bool isCover;
  final String aiDescription;
  final String name;

  TaskImage({
    required this.id,
    required this.url,
    required this.r2Key,
    this.isCover = false,
    this.aiDescription = '',
    this.name = '',
  });

  factory TaskImage.fromMap(Map<String, dynamic> map) {
    return TaskImage(
      id: map['id'] as String? ?? '',
      url: map['url'] as String? ?? '',
      r2Key: map['r2_key'] as String? ?? '',
      isCover: (map['is_cover'] == 1 || map['is_cover'] == true),
      aiDescription: map['ai_description'] as String? ?? '',
      name: map['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'r2_key': r2Key,
      'is_cover': isCover ? 1 : 0,
      'ai_description': aiDescription,
      'name': name,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'r2Key': r2Key,
      'isCover': isCover,
      'aiDescription': aiDescription,
      'name': name,
    };
  }

  factory TaskImage.fromJson(Map<String, dynamic> json) {
    return TaskImage(
      id: json['id']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      r2Key: (json['r2Key'] ?? json['r2_key'])?.toString() ?? '',
      isCover:
          json['isCover'] == true ||
          json['is_cover'] == 1 ||
          json['isCover'] == 1,
      aiDescription:
          (json['aiDescription'] ?? json['ai_description'])?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }

  TaskImage copyWith({
    String? id,
    String? url,
    String? r2Key,
    bool? isCover,
    String? aiDescription,
    String? name,
  }) {
    return TaskImage(
      id: id ?? this.id,
      url: url ?? this.url,
      r2Key: r2Key ?? this.r2Key,
      isCover: isCover ?? this.isCover,
      aiDescription: aiDescription ?? this.aiDescription,
      name: name ?? this.name,
    );
  }
}

class TaskComment {
  final String id;
  final String userId;
  final String userName;
  final String text;
  final DateTime time;

  TaskComment({
    required this.id,
    required this.userId,
    this.userName = '',
    required this.text,
    required this.time,
  });

  factory TaskComment.fromMap(Map<String, dynamic> map) {
    return TaskComment(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? map['userId']?.toString() ?? '',
      userName:
          map['user_name']?.toString() ?? map['userName']?.toString() ?? '',
      text: map['text']?.toString() ?? '',
      time: DateTime.tryParse(map['time']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'text': text,
      'time': time.toIso8601String(),
    };
  }
}

class TaskChecklistItem {
  final String id;
  final String text;
  final bool isDone;

  TaskChecklistItem({
    required this.id,
    required this.text,
    this.isDone = false,
  });

  factory TaskChecklistItem.fromMap(Map<String, dynamic> map) {
    return TaskChecklistItem(
      id: map['id']?.toString() ?? '',
      text: (map['text'] ?? map['title'] ?? '').toString(),
      isDone:
          map['is_done'] == 1 ||
          map['is_done'] == true ||
          map['isDone'] == true ||
          map['isDone'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'text': text, 'is_done': isDone ? 1 : 0};
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'text': text, 'isDone': isDone};
  }

  factory TaskChecklistItem.fromJson(Map<String, dynamic> json) {
    return TaskChecklistItem(
      id: json['id']?.toString() ?? '',
      text: (json['text'] ?? json['title'] ?? '').toString(),
      isDone:
          json['isDone'] == true ||
          json['is_done'] == true ||
          json['is_done'] == 1 ||
          json['isDone'] == 1,
    );
  }

  TaskChecklistItem copyWith({String? id, String? text, bool? isDone}) {
    return TaskChecklistItem(
      id: id ?? this.id,
      text: text ?? this.text,
      isDone: isDone ?? this.isDone,
    );
  }
}

class TaskModel {
  final String id;
  final String boardId;
  final String title;
  final String description;
  final DateTime dueDate;
  final String type;
  final List<String> members;
  final List<String> labelIds;
  final String status;
  final bool isCompleted;
  final List<TaskChecklistItem> checklist;
  final List<TaskImage> images;
  final List<TaskComment> comments;
  final int updatedAt;
  final int orderIndex;

  TaskModel({
    required this.id,
    this.boardId = '',
    required this.title,
    this.description = '',
    required this.dueDate,
    required this.type,
    this.members = const [],
    this.labelIds = const [],
    this.status = 'todo',
    this.isCompleted = false,
    List<TaskChecklistItem>? checklist,
    this.images = const [],
    this.comments = const [],
    this.updatedAt = 0,
    this.orderIndex = 0,
  }) : checklist = checklist ?? parseChecklistFromMarkdown(description);

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    String description = map['description'] as String? ?? '';
    final parsedChecklist = parseChecklistFromMarkdown(description);
    if (parsedChecklist.isEmpty) {
      final legacyChecklist = _parseChecklist(map['checklist']);
      if (legacyChecklist.isNotEmpty) {
        final listMarkdown = legacyChecklist.map((item) {
          final box = item.isDone ? '[x]' : '[ ]';
          return '- $box ${item.text}';
        }).join('\n');
        description = description.isEmpty ? listMarkdown : '$description\n\n$listMarkdown';
      }
    }

    return TaskModel(
      id: map['id'] as String,
      boardId: map['board_id'] as String? ?? '',
      title: map['title'] as String,
      description: description,
      dueDate: DateTime.parse((map['due_date'] ?? map['time']) as String),
      type: map['type'] as String? ?? 'personal',
      members: _parseList(map['members']),
      labelIds: _parseList(map['label_ids']),
      status: map['status'] as String? ?? 'todo',
      isCompleted: (map['is_completed'] == 1 || map['is_completed'] == true),
      checklist: null,
      images: _parseImages(map['images']),
      comments: _parseComments(map['comments']),
      updatedAt: map['updated_at'] is int ? map['updated_at'] as int : 0,
      orderIndex: map['order_index'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'board_id': boardId,
      'title': title,
      'description': description,
      'due_date': dueDate.toIso8601String(),
      'type': type,
      'members': jsonEncode(members),
      'label_ids': jsonEncode(labelIds),
      'status': status,
      'is_completed': isCompleted ? 1 : 0,
      'checklist': jsonEncode(checklist.map((e) => e.toMap()).toList()),
      'images': jsonEncode(images.map((e) => e.toMap()).toList()),
      'comments': jsonEncode(comments.map((e) => e.toMap()).toList()),
      'updated_at': updatedAt,
      'order_index': orderIndex,
    };
  }

  // 🚀 Task 65.2: The Ultimate Robust Parser
  factory TaskModel.fromJson(Map<String, dynamic> json) {
    String description = (json['description'] ?? '').toString();
    final parsedChecklist = parseChecklistFromMarkdown(description);
    if (parsedChecklist.isEmpty) {
      final legacyChecklist = _parseChecklist(json['checklist']);
      if (legacyChecklist.isNotEmpty) {
        final listMarkdown = legacyChecklist.map((item) {
          final box = item.isDone ? '[x]' : '[ ]';
          return '- $box ${item.text}';
        }).join('\n');
        description = description.isEmpty ? listMarkdown : '$description\n\n$listMarkdown';
      }
    }

    return TaskModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      boardId: (json['board_id'] ?? json['boardId'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: description,
      dueDate:
          DateTime.tryParse(
            (json['due_date'] ?? json['time'] ?? '').toString(),
          ) ??
          DateTime.now(),
      type: json['type']?.toString() ?? 'team',
      status: json['status']?.toString() ?? 'todo',
      isCompleted:
          json['is_completed'] == 1 ||
          json['is_completed'] == true ||
          json['is_completed'] == 'true',
      checklist: null,
      members: _parseList(json['members'] ?? json['members']),
      labelIds: _parseList(json['label_ids'] ?? json['labelIds']),
      images: _parseImages(json['images']),
      comments: _parseComments(json['comments']),
      updatedAt: json['updated_at'] is int
          ? json['updated_at']
          : (int.tryParse(json['updated_at']?.toString() ?? '') ?? 0),
      orderIndex: json['order_index'] is int
          ? json['order_index']
          : (int.tryParse(json['order_index']?.toString() ?? '') ?? 0),
    );
  }

  static List<TaskChecklistItem> parseChecklistFromMarkdown(String markdown) {
    if (markdown.isEmpty) return [];
    final List<TaskChecklistItem> items = [];
    final lines = markdown.split('\n');
    final regExp = RegExp(r'^\s*[-*]?\s*\[([ xX])\]\s*(.*)$');
    for (final line in lines) {
      final match = regExp.firstMatch(line);
      if (match != null) {
        final isDone = match.group(1)!.toLowerCase() == 'x';
        final text = match.group(2)!.trim();
        final id = 'md_${items.length}_${text.hashCode.abs()}';
        items.add(TaskChecklistItem(id: id, text: text, isDone: isDone));
      }
    }
    return items;
  }

  static List<String> _parseList(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) return decoded.map((e) => e.toString()).toList();
      } catch (_) {}
    }
    return [];
  }

  static List<TaskImage> _parseImages(dynamic raw) {
    if (raw == null) return [];
    final List list = (raw is String && raw.isNotEmpty)
        ? (jsonDecode(raw) as List? ?? [])
        : (raw is List ? raw : []);
    return list
        .map((e) => TaskImage.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static List<TaskComment> _parseComments(dynamic raw) {
    if (raw == null) return [];
    final List list = (raw is String && raw.isNotEmpty)
        ? (jsonDecode(raw) as List? ?? [])
        : (raw is List ? raw : []);
    return list
        .map((e) => TaskComment.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static List<TaskChecklistItem> _parseChecklist(dynamic raw) {
    if (raw == null) return [];
    final List list = (raw is String && raw.isNotEmpty)
        ? (jsonDecode(raw) as List? ?? [])
        : (raw is List ? raw : []);
    return list
        .map(
          (e) =>
              TaskChecklistItem.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  int get checklistDoneCount => checklist.where((item) => item.isDone).length;
  int get checklistTotalCount => checklist.length;
  String get checklistProgressLabel =>
      '$checklistDoneCount/$checklistTotalCount';
  bool get hasChecklist => checklist.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'board_id': boardId,
      'title': title,
      'description': description,
      'due_date': dueDate.toIso8601String(),
      'type': type,
      'members': members,
      'label_ids': labelIds,
      'status': status,
      'is_completed': isCompleted,
      'checklist': checklist.map((e) => e.toJson()).toList(),
      'images': images.map((e) => e.toJson()).toList(),
      'comments': comments.map((e) => e.toMap()).toList(),
      'updated_at': updatedAt,
      'order_index': orderIndex,
    };
  }

  TaskModel copyWith({
    String? id,
    String? boardId,
    String? title,
    String? description,
    DateTime? dueDate,
    String? type,
    List<String>? members,
    List<String>? labelIds,
    String? status,
    bool? isCompleted,
    List<TaskChecklistItem>? checklist,
    List<TaskImage>? images,
    List<TaskComment>? comments,
    int? updatedAt,
    int? orderIndex,
  }) {
    return TaskModel(
      id: id ?? this.id,
      boardId: boardId ?? this.boardId,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      type: type ?? this.type,
      members: members ?? this.members,
      labelIds: labelIds ?? this.labelIds,
      status: status ?? this.status,
      isCompleted: isCompleted ?? this.isCompleted,
      checklist: checklist ?? this.checklist,
      images: images ?? this.images,
      comments: comments ?? this.comments,
      updatedAt: updatedAt ?? this.updatedAt,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }
}
