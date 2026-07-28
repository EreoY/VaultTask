import 'dart:convert';

class AiChatSession {
  final String id;
  final String title;
  final String summaryText;
  final List<Map<String, String>> messages;
  final DateTime createdAt;

  AiChatSession({
    required this.id,
    required this.title,
    this.summaryText = '',
    List<Map<String, String>>? messages,
    DateTime? createdAt,
  })  : messages = messages ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'summaryText': summaryText,
      'messages': messages,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AiChatSession.fromMap(Map<String, dynamic> map) {
    return AiChatSession(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'เสสชัน',
      summaryText: map['summaryText']?.toString() ?? '',
      messages: (map['messages'] as List<dynamic>?)
              ?.map((e) => Map<String, String>.from(e as Map))
              .toList() ??
          [],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory AiChatSession.fromJson(String source) =>
      AiChatSession.fromMap(json.decode(source) as Map<String, dynamic>);

  AiChatSession copyWith({
    String? id,
    String? title,
    String? summaryText,
    List<Map<String, String>>? messages,
    DateTime? createdAt,
  }) {
    return AiChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      summaryText: summaryText ?? this.summaryText,
      messages: messages ?? List.from(this.messages),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
