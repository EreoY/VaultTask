import 'dart:convert';

class DocumentModel {
  final String id;
  final String boardId;
  final String title;
  final String notes;
  final String summary;
  final List<Map<String, String>> attachments;
  final int updatedAt;
  final DateTime createdAt;

  DocumentModel({
    required this.id,
    required this.boardId,
    required this.title,
    this.notes = '',
    this.summary = '',
    this.attachments = const [],
    this.updatedAt = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory DocumentModel.fromMap(Map<String, dynamic> map) {
    return DocumentModel(
      id: map['id']?.toString() ?? '',
      boardId: map['board_id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      notes: map['notes']?.toString() ?? '',
      summary: map['summary']?.toString() ?? '',
      attachments: _parseAttachments(map['attachments']),
      updatedAt: map['updated_at'] is int
          ? map['updated_at'] as int
          : int.tryParse(map['updated_at']?.toString() ?? '') ?? 0,
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id']?.toString() ?? '',
      boardId: (json['board_id'] ?? json['boardId'])?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      summary: (json['summary'] ?? '').toString(),
      attachments: _parseAttachments(json['attachments']),
      updatedAt: json['updated_at'] is int
          ? json['updated_at'] as int
          : int.tryParse(json['updated_at']?.toString() ?? '') ?? 0,
      createdAt:
          DateTime.tryParse((json['created_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'board_id': boardId,
      'title': title,
      'notes': notes,
      'summary': summary,
      'attachments': jsonEncode(attachments),
      'updated_at': updatedAt,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'board_id': boardId,
      'title': title,
      'notes': notes,
      'summary': summary,
      'attachments': attachments,
      'updated_at': updatedAt,
      'created_at': createdAt.toIso8601String(),
    };
  }

  DocumentModel copyWith({
    String? id,
    String? boardId,
    String? title,
    String? notes,
    String? summary,
    List<Map<String, String>>? attachments,
    int? updatedAt,
    DateTime? createdAt,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      boardId: boardId ?? this.boardId,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      summary: summary ?? this.summary,
      attachments: attachments ?? this.attachments,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static List<Map<String, String>> _parseAttachments(dynamic raw) {
    if (raw == null) return [];
    final List list = (raw is String && raw.isNotEmpty)
        ? (jsonDecode(raw) as List? ?? [])
        : (raw is List ? raw : []);
    return list
        .map(
          (e) => Map<String, String>.from(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }
}
