import 'dart:convert';

class BoardModel {
  final String id;
  final String name;
  final String type; // 'personal' or 'team'
  final String ownerUid;
  final int color;
  final List<String> members; // List of Firebase UIDs
  final Map<String, String> memberRoles; // Map of UID to Role Description
  final List<String> columns; // Custom Kanban column names e.g. ['todo','doing','done']
  final List<Map<String, dynamic>> labels; // Available tags e.g. [{id: '1', color: 0xFFF44336, name: 'Urgent'}]
  final String workspaceId;
  final List<Map<String, dynamic>> documents; // Documents attached to the board e.g. [{name: 'Rules.pdf', url: 'https://...', uploadedAt: 123456789000}]
  final DateTime createdAt;

  BoardModel({
    required this.id,
    required this.name,
    required this.type,
    this.color = 0xFF0D40A5,
    this.ownerUid = '',
    this.members = const [],
    this.memberRoles = const {},
    this.columns = const ['todo', 'doing', 'done'],
    this.labels = const [],
    this.workspaceId = '',
    this.documents = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // For SQLite
  factory BoardModel.fromMap(Map<String, dynamic> map) {
    return BoardModel(
      id: map['id'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      ownerUid: map['owner_uid'] as String? ?? '',
      color: map['color'] as int? ?? 0xFF0D40A5,
      members: map['members'] != null
          ? List<String>.from(jsonDecode(map['members'] as String))
          : [],
      memberRoles: map['member_roles'] != null
          ? Map<String, String>.from(jsonDecode(map['member_roles'] as String))
          : {},
      columns: map['columns'] != null
          ? List<String>.from(jsonDecode(map['columns'] as String))
          : ['todo', 'doing', 'done'],
      labels: map['labels'] != null
          ? List<Map<String, dynamic>>.from(jsonDecode(map['labels'] as String))
          : [],
      workspaceId: map['workspace_id'] as String? ?? '',
      documents: map['documents'] != null
          ? List<Map<String, dynamic>>.from(jsonDecode(map['documents'] as String))
          : [],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'owner_uid': ownerUid,
      'color': color,
      'members': jsonEncode(members),
      'member_roles': jsonEncode(memberRoles),
      'columns': jsonEncode(columns),
      'labels': jsonEncode(labels),
      'workspace_id': workspaceId,
      'documents': jsonEncode(documents),
      'created_at': createdAt.toIso8601String(),
    };
  }

  // For Cloudflare D1 (JSON response)
  factory BoardModel.fromJson(Map<String, dynamic> json) {
    return BoardModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String? ?? 'team',
      ownerUid: json['owner_uid']?.toString() ?? '',
      color: json['color'] as int? ?? 0xFF0D40A5,
      members: () {
        if (json['members'] == null) return <String>[];
        final raw = json['members'] is String ? jsonDecode(json['members'] as String) : json['members'];
        return (raw as List?)?.map((e) => e.toString()).toList() ?? [];
      }(),
      memberRoles: () {
        if (json['member_roles'] == null) return <String, String>{};
        final raw = json['member_roles'] is String ? jsonDecode(json['member_roles'] as String) : json['member_roles'];
        return Map<String, String>.from(raw as Map? ?? {});
      }(),
      columns: () {
        if (json['columns'] == null) return ['todo', 'doing', 'done'];
        final raw = json['columns'] is String ? jsonDecode(json['columns'] as String) : json['columns'];
        return (raw as List?)?.map((e) => e.toString()).toList() ?? ['todo', 'doing', 'done'];
      }(),
      labels: () {
        if (json['labels'] == null) return <Map<String, dynamic>>[];
        final raw = json['labels'] is String ? jsonDecode(json['labels'] as String) : json['labels'];
        return (raw as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
      }(),
      workspaceId: json['workspace_id'] as String? ?? '',
      documents: () {
        if (json['documents'] == null) return <Map<String, dynamic>>[];
        final raw = json['documents'] is String ? jsonDecode(json['documents'] as String) : json['documents'];
        return (raw as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
      }(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'owner_uid': ownerUid,
      'color': color,
      'members': members,
      'member_roles': memberRoles,
      'columns': columns,
      'labels': labels,
      'workspace_id': workspaceId,
      'documents': documents,
      'created_at': createdAt.toIso8601String(),
    };
  }

  BoardModel copyWith({
    String? id,
    String? name,
    String? type,
    String? ownerUid,
    int? color,
    List<String>? members,
    Map<String, String>? memberRoles,
    List<String>? columns,
    List<Map<String, dynamic>>? labels,
    String? workspaceId,
    List<Map<String, dynamic>>? documents,
    DateTime? createdAt,
  }) {
    return BoardModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      ownerUid: ownerUid ?? this.ownerUid,
      color: color ?? this.color,
      members: members ?? this.members,
      memberRoles: memberRoles ?? this.memberRoles,
      columns: columns ?? this.columns,
      labels: labels ?? this.labels,
      workspaceId: workspaceId ?? this.workspaceId,
      documents: documents ?? this.documents,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
