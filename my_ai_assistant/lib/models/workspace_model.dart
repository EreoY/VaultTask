import 'dart:convert';

class WorkspaceModel {
  final String id;
  final String name;
  final String type; // 'personal' or 'team'
  final String ownerUid;
  final List<String> members; // List of Firebase UIDs
  final DateTime createdAt;

  WorkspaceModel({
    required this.id,
    required this.name,
    required this.type,
    this.ownerUid = '',
    this.members = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // For SQLite
  factory WorkspaceModel.fromMap(Map<String, dynamic> map) {
    return WorkspaceModel(
      id: map['id'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      ownerUid: map['owner_uid'] as String? ?? '',
      members: map['members'] != null
          ? List<String>.from(jsonDecode(map['members'] as String))
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
      'members': jsonEncode(members),
      'created_at': createdAt.toIso8601String(),
    };
  }

  // For Cloudflare D1
  factory WorkspaceModel.fromJson(Map<String, dynamic> json) {
    return WorkspaceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String? ?? 'team',
      ownerUid: json['owner_uid']?.toString() ?? '',
      members: () {
        if (json['members'] == null) return <String>[];
        final raw = json['members'] is String ? jsonDecode(json['members'] as String) : json['members'];
        return (raw as List?)?.map((e) => e.toString()).toList() ?? [];
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
      'members': members,
      'created_at': createdAt.toIso8601String(),
    };
  }

  WorkspaceModel copyWith({
    String? id,
    String? name,
    String? type,
    String? ownerUid,
    List<String>? members,
    DateTime? createdAt,
  }) {
    return WorkspaceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      ownerUid: ownerUid ?? this.ownerUid,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
