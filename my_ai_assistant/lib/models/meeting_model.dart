import 'dart:convert';

class MeetingModel {
  final String id;
  final String boardId;
  final String title;
  final String description;
  final String notes;
  final DateTime startAt;
  final DateTime? endAt;
  final List<String> roleTags;
  final List<Map<String, String>> attachments;
  final String transcript;
  final String summary;
  final int updatedAt;
  final DateTime createdAt;

  MeetingModel({
    required this.id,
    required this.boardId,
    required this.title,
    this.description = '',
    this.notes = '',
    required this.startAt,
    this.endAt,
    this.roleTags = const [],
    this.attachments = const [],
    this.transcript = '',
    this.summary = '',
    this.updatedAt = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory MeetingModel.fromMap(Map<String, dynamic> map) {
    return MeetingModel(
      id: map['id']?.toString() ?? '',
      boardId: map['board_id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      notes: map['notes']?.toString() ?? '',
      startAt:
          DateTime.tryParse(map['start_at']?.toString() ?? '') ??
          DateTime.now(),
      endAt: DateTime.tryParse(map['end_at']?.toString() ?? ''),
      roleTags: _parseStringList(map['role_tags']),
      attachments: _parseAttachments(map['attachments']),
      transcript: map['transcript']?.toString() ?? '',
      summary: map['summary']?.toString() ?? '',
      updatedAt: map['updated_at'] is int
          ? map['updated_at'] as int
          : int.tryParse(map['updated_at']?.toString() ?? '') ?? 0,
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  factory MeetingModel.fromJson(Map<String, dynamic> json) {
    return MeetingModel(
      id: json['id']?.toString() ?? '',
      boardId: (json['board_id'] ?? json['boardId'])?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      startAt:
          DateTime.tryParse((json['start_at'] ?? json['startAt']).toString()) ??
          DateTime.now(),
      endAt: DateTime.tryParse(
        (json['end_at'] ?? json['endAt'] ?? '').toString(),
      ),
      roleTags: _parseStringList(json['role_tags'] ?? json['roleTags']),
      attachments: _parseAttachments(json['attachments']),
      transcript: (json['transcript'] ?? '').toString(),
      summary: (json['summary'] ?? '').toString(),
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
      'description': description,
      'notes': notes,
      'start_at': startAt.toIso8601String(),
      'end_at': endAt?.toIso8601String() ?? '',
      'role_tags': jsonEncode(roleTags),
      'attachments': jsonEncode(attachments),
      'transcript': transcript,
      'summary': summary,
      'updated_at': updatedAt,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'board_id': boardId,
      'title': title,
      'description': description,
      'notes': notes,
      'start_at': startAt.toIso8601String(),
      'end_at': endAt?.toIso8601String(),
      'role_tags': roleTags,
      'attachments': attachments,
      'transcript': transcript,
      'summary': summary,
      'updated_at': updatedAt,
      'created_at': createdAt.toIso8601String(),
    };
  }

  MeetingModel copyWith({
    String? id,
    String? boardId,
    String? title,
    String? description,
    String? notes,
    DateTime? startAt,
    DateTime? endAt,
    bool clearEndAt = false,
    List<String>? roleTags,
    List<Map<String, String>>? attachments,
    String? transcript,
    String? summary,
    int? updatedAt,
    DateTime? createdAt,
  }) {
    return MeetingModel(
      id: id ?? this.id,
      boardId: boardId ?? this.boardId,
      title: title ?? this.title,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      startAt: startAt ?? this.startAt,
      endAt: clearEndAt ? null : (endAt ?? this.endAt),
      roleTags: roleTags ?? this.roleTags,
      attachments: attachments ?? this.attachments,
      transcript: transcript ?? this.transcript,
      summary: summary ?? this.summary,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isPast => (endAt ?? startAt).isBefore(DateTime.now());
  bool get isUpcoming => !isPast;

  static List<String> _parseStringList(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }
    return [];
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
