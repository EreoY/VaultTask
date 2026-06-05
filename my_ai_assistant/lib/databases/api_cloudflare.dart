import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/board_model.dart';
import '../models/task_model.dart';
import '../models/workspace_model.dart';
import '../config/env_config.dart';

// DeltaResult is defined inline here (not imported) to avoid Flutter Web DDC
// cross-file async return type issues (LegacyJavaScriptObject interop bug).
class DeltaResult {
  final List<TaskModel> tasks;
  final int maxUpdated;
  DeltaResult(this.tasks, this.maxUpdated);
}

class ApiCloudflare {
  static String get _base => EnvConfig.backendUrl;

  static Map<String, String> get _headers => {'Content-Type': 'application/json'};

  // ─── BOARDS ───────────────────────────────────────────

  static Future<BoardModel> getBoardById(String id) async {
    final url = '$_base/api/boards?id=$id';
    final response = await http.get(Uri.parse(url), headers: _headers);
    if (response.statusCode == 200) {
      return BoardModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to get board: ${response.body}');
    }
  }

  static Future<List<BoardModel>> getBoards(String uid) async {
    final url = '$_base/api/boards?uid=$uid';
    debugPrint('DEBUG GET $url');
    final response = await http.get(Uri.parse(url), headers: _headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is! List) return [];
      return data.map((j) => BoardModel.fromJson(j as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to get boards: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<String> insertBoard(String ownerUid, BoardModel board) async {
    final id = board.id.isEmpty
        ? '${DateTime.now().millisecondsSinceEpoch}'
        : board.id;
    final response = await http.post(
      Uri.parse('$_base/api/boards'),
      headers: _headers,
      body: jsonEncode({
        'id': id,
        'owner_uid': ownerUid,
        'name': board.name,
        'color': board.color,
        'members': board.members,
        'member_roles': board.memberRoles,
        'columns': board.columns,
        'labels': board.labels,
        'workspace_id': board.workspaceId,
      }),
    );
    if (response.statusCode != 201) {
      debugPrint('INSERT BOARD ERROR: ${response.body}');
      throw Exception('Failed to create board: ${response.body}');
    }
    return id;
  }

  static Future<void> updateBoard(BoardModel board) async {
    final response = await http.put(
      Uri.parse('$_base/api/boards'),
      headers: _headers,
      body: jsonEncode({
        'id': board.id,
        'name': board.name,
        'color': board.color,
        'members': board.members,
        'member_roles': board.memberRoles,
        'columns': board.columns,
        'labels': board.labels,
        'workspace_id': board.workspaceId,
      }),
    );
    if (response.statusCode != 200) {
      debugPrint('UPDATE BOARD ERROR: ${response.body}');
      throw Exception('Failed to update board: ${response.body}');
    }
  }

  static Future<void> deleteBoard(String boardId) async {
    final response = await http.delete(
      Uri.parse('$_base/api/boards?id=$boardId'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete board: ${response.body}');
    }
  }

  static Future<BoardModel> joinBoard(String uid, String boardId) async {
    final response = await http.post(
      Uri.parse('$_base/api/boards_join'),
      headers: _headers,
      body: jsonEncode({'id': boardId, 'uid': uid}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to join board: ${response.body}');
    }
    final json = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    return BoardModel.fromJson(json);
  }

  static Future<void> removeMember(String boardId, String uid) async {
    final response = await http.post(
      Uri.parse('$_base/api/boards_remove_member'),
      headers: _headers,
      body: jsonEncode({'id': boardId, 'uid': uid}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to remove member: ${response.body}');
    }
  }

  // ─── TASKS ────────────────────────────────────────────

  static Future<List<TaskModel>> getTasksByBoard(String boardId) async {
    final url = '$_base/api/tasks?board_id=$boardId';
    debugPrint('DEBUG GET $url');
    final response = await http.get(Uri.parse(url), headers: _headers);
    if (response.statusCode == 200) {
      try {
        final rawData = jsonDecode(response.body);
        final data = (rawData is List) ? List<dynamic>.from(rawData) : [];
        if (data.isEmpty) return [];
        return data.map((j) => TaskModel.fromJson(Map<String, dynamic>.from(j as Map))).toList();
      } catch (e) {
        debugPrint('JSON Decode Error in getTasksByBoard: $e');
        debugPrint('Raw: ${response.body}');
        throw Exception('Failed to decode tasks: $e');
      }
    } else {
      throw Exception('Failed to get tasks: ${response.statusCode} - ${response.body}');
    }
  }

  // Delta fetch
  static Future<DeltaResult> getTasksDelta(String boardId, int since) async {
    final url = '$_base/api/tasks_delta?board_id=$boardId&since=$since';
    final response = await http.get(Uri.parse(url), headers: _headers);
    if (response.statusCode == 200) {
      final dynamic rawData = jsonDecode(response.body);
      final Map<String, dynamic> data = Map<String, dynamic>.from(rawData as Map);
      final rawTasks = data['tasks'];
      final tasksJson = (rawTasks is List) ? List<dynamic>.from(rawTasks) : [];
      final maxUpdated = int.tryParse(data['maxUpdated']?.toString() ?? '') ?? since;
      final tasks = tasksJson
          .map((j) => TaskModel.fromJson(Map<String, dynamic>.from(j as Map)))
          .toList();
      return DeltaResult(tasks, maxUpdated);
    } else {
      throw Exception('Failed to get tasks delta: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<String> insertTask(String authorUid, TaskModel task) async {
    final id = task.id.isEmpty
        ? '${DateTime.now().millisecondsSinceEpoch}'
        : task.id;
    final response = await http.post(
      Uri.parse('$_base/api/tasks'),
      headers: _headers,
      body: jsonEncode({
        'id': id,
        'board_id': task.boardId,
        'author_uid': authorUid,
        'title': task.title,
        'description': task.description,
        'due_date': task.dueDate.toIso8601String(),
        'members': task.members,
        'label_ids': task.labelIds,
        'status': task.status,
        'is_completed': task.isCompleted,
        'images': task.images.map((e) => e.toJson()).toList(),
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to insert task: ${response.body}');
    }
    return id;
  }

  static Future<void> updateTask(TaskModel task) async {
    final response = await http.put(
      Uri.parse('$_base/api/tasks'),
      headers: _headers,
      body: jsonEncode({
        'id': task.id,
        'board_id': task.boardId, // 🚀 Task 64.1
        'title': task.title,
        'description': task.description,
        'due_date': task.dueDate.toIso8601String(),
        'members': task.members,
        'label_ids': task.labelIds,
        'status': task.status,
        'is_completed': task.isCompleted,
        'images': task.images.map((e) => e.toJson()).toList(),
      }),
    );
    if (response.statusCode != 200) {
      debugPrint('UPDATE TASK ERROR: ${response.body}');
      throw Exception('Failed to update task: ${response.body}');
    }
  }

  static Future<void> updateTaskStatus(String id, String status, String boardId) async {
    final response = await http.put(
      Uri.parse('$_base/api/tasks_status'),
      headers: _headers,
      body: jsonEncode({'id': id, 'status': status, 'board_id': boardId}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update task status: ${response.body}');
    }
  }

  static Future<void> deleteTask(String id) async {
    final response = await http.delete(
      Uri.parse('$_base/api/tasks?id=$id'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete task: ${response.body}');
    }
  }

  // Bulk Order Update
  static Future<void> updateTaskOrder(String boardId, List<Map<String, dynamic>> updates) async {
    final response = await http.put(
      Uri.parse('$_base/api/tasks_order'),
      headers: _headers,
      body: jsonEncode({
        'board_id': boardId,
        'updates': updates,
      }),
    );
    if (response.statusCode != 200) {
      debugPrint('UPDATE ORDER ERROR: ${response.body}');
      throw Exception('Failed to update task order: ${response.body}');
    }
  }

  // ─── IMAGES / R2 ──────────────────────────────────────

  static String getImageUrl(String key) {
    return '$_base/api/images/$key';
  }

  static Future<Map<String, dynamic>> uploadImage(List<int> bytes, String filename, {String path = 'uploads'}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');

    final uri = Uri.parse('$_base/api/upload');
    final request = http.MultipartRequest('POST', uri);
    request.fields['uid'] = user.uid;
    request.fields['folder'] = path;
    request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));

    try {
      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['url'] != null && !(data['url'] as String).startsWith('http')) {
          data['url'] = '$_base${data['url']}';
        }
        return data;
      } else {
        throw Exception('Failed to upload image (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<String> generateAiDescription(List<int> imageBytes, String mimeType) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return '';
    try {
      final base64Image = base64Encode(imageBytes);
      final body = {
        'uid': user.uid,
        'model': 'google/gemma-4-26b-a4b-it',
        'messages': [
          {
            'role': 'user',
            'content': [
              {'type': 'text', 'text': 'Describe this image clearly and concisely in Thai (1-2 sentences).'},
              {
                'type': 'image_url',
                'image_url': {'url': 'data:$mimeType;base64,$base64Image'}
              }
            ]
          }
        ],
        'max_tokens': 300,
      };
      
      final response = await http.post(Uri.parse('$_base/api/ai/chat'), headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['result']?['choices']?[0]?['message']?['content'] ?? '').toString().trim();
      }
    } catch (e) { debugPrint('Error generating AI description: $e'); }
    return '';
  }

  // ─── USERS ────────────────────────────────────────────

  static Future<Map<String, Map<String, String>>> getUsersByUids(List<String> uids) async {
    if (uids.isEmpty) return {};
    final query = uids.join(',');
    final url = '$_base/api/users?uids=$query';
    try {
      final response = await http.get(Uri.parse(url), headers: _headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          final map = <String, Map<String, String>>{};
          for (final u in data) {
            final uid = u['uid']?.toString() ?? '';
            final name = u['display_name']?.toString() ?? u['email']?.toString() ?? uid;
            final photo = u['photo_url']?.toString() ?? '';
            if (uid.isNotEmpty) map[uid] = {'name': name, 'photo': photo};
          }
          return map;
        }
      }
    } catch (e) { debugPrint('Failed to get users: $e'); }
    return {};
  }

  static Future<void> updateUserDisplayName(String uid, String displayName) async {
    await http.put(Uri.parse('$_base/api/users'), headers: _headers, body: jsonEncode({'uid': uid, 'display_name': displayName}));
  }

  // ─── WORKSPACES ───────────────────────────────────────

  static Future<List<WorkspaceModel>> getWorkspaces(String uid) async {
    final url = '$_base/api/workspaces?uid=$uid';
    final response = await http.get(Uri.parse(url), headers: _headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is! List) return [];
      return data.map((j) => WorkspaceModel.fromJson(j as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to get workspaces: ${response.body}');
    }
  }

  static Future<String> insertWorkspace(WorkspaceModel workspace) async {
    final response = await http.post(
      Uri.parse('$_base/api/workspaces'),
      headers: _headers,
      body: jsonEncode({
        'id': workspace.id,
        'owner_uid': workspace.ownerUid,
        'name': workspace.name,
        'members': workspace.members,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create workspace: ${response.body}');
    }
    return workspace.id;
  }

  static Future<void> deleteWorkspace(String id) async {
    final response = await http.delete(
      Uri.parse('$_base/api/workspaces?id=$id'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete workspace: ${response.body}');
    }
  }

  static Future<WorkspaceModel> joinWorkspace(String uid, String workspaceId) async {
    final response = await http.post(
      Uri.parse('$_base/api/workspaces_join'),
      headers: _headers,
      body: jsonEncode({
        'id': workspaceId,
        'uid': uid,
      }),
    );
    if (response.statusCode == 200) {
      return WorkspaceModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to join workspace: ${response.body}');
    }
  }
}

