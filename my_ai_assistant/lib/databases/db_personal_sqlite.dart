import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/chat_model.dart';
import '../models/board_model.dart';
import '../models/meeting_model.dart';
import '../models/task_model.dart';
import '../models/workspace_model.dart';

class DbPersonalSqlite {
  static final DbPersonalSqlite instance = DbPersonalSqlite._init();
  static Database? _database;

  DbPersonalSqlite._init();

  Future<Database> get database async {
    if (kIsWeb) throw UnsupportedError('SQLite is not supported on Web');
    if (_database != null) return _database!;
    _database = await _initDB('calenda_personal.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 13,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE personal_workspaces (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  owner_uid TEXT DEFAULT '',
  members TEXT DEFAULT '[]',
  created_at TEXT NOT NULL
)
''');
    await db.execute('''
CREATE TABLE personal_boards (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  type TEXT NOT NULL DEFAULT 'personal',
  color INTEGER DEFAULT 0,
  members TEXT DEFAULT '[]',
  columns TEXT DEFAULT '["todo","doing","done"]',
  labels TEXT DEFAULT '[]',
  workspace_id TEXT DEFAULT '',
  documents TEXT DEFAULT '[]',
  created_at TEXT NOT NULL
)
''');
    await db.execute('''
CREATE TABLE personal_tasks (
  id TEXT PRIMARY KEY,
  board_id TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT DEFAULT '',
  time TEXT NOT NULL,
  due_date TEXT DEFAULT '',
  type TEXT NOT NULL DEFAULT 'personal',
  members TEXT DEFAULT '[]',
  label_ids TEXT DEFAULT '[]',
  status TEXT NOT NULL DEFAULT 'todo',
  is_completed INTEGER NOT NULL DEFAULT 0,
  checklist TEXT DEFAULT '[]',
  images TEXT DEFAULT '[]',
  comments TEXT DEFAULT '[]',
  updated_at INTEGER DEFAULT 0,
  FOREIGN KEY(board_id) REFERENCES personal_boards(id)
)
''');
    await db.execute('''
CREATE TABLE personal_meetings (
  id TEXT PRIMARY KEY,
  board_id TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT DEFAULT '',
  notes TEXT DEFAULT '',
  start_at TEXT NOT NULL,
  end_at TEXT DEFAULT '',
  role_tags TEXT DEFAULT '[]',
  attachments TEXT DEFAULT '[]',
  transcript TEXT DEFAULT '',
  summary TEXT DEFAULT '',
  updated_at INTEGER DEFAULT 0,
  created_at TEXT NOT NULL,
  FOREIGN KEY(board_id) REFERENCES personal_boards(id)
)
''');
    await _createChatTables(db);
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('DROP TABLE IF EXISTS tasks');
      } catch (_) {}
      await _createDB(db, newVersion);
      return;
    }
    if (oldVersion == 2) {
      await db.execute(
        'ALTER TABLE personal_boards ADD COLUMN labels TEXT DEFAULT "[]";',
      );
      await db.execute(
        'ALTER TABLE personal_tasks ADD COLUMN label_ids TEXT DEFAULT "[]";',
      );
    }
    if (oldVersion < 4) {
      try {
        await db.execute(
          'ALTER TABLE personal_tasks ADD COLUMN description TEXT DEFAULT ""',
        );
      } catch (_) {}
    }
    if (oldVersion < 5) {
      try {
        await db.execute(
          'ALTER TABLE personal_tasks ADD COLUMN is_completed INTEGER NOT NULL DEFAULT 0',
        );
      } catch (_) {}
    }
    if (oldVersion < 6) {
      try {
        await db.execute(
          'ALTER TABLE personal_tasks ADD COLUMN updated_at INTEGER DEFAULT 0',
        );
      } catch (_) {}
    }
    if (oldVersion < 7) {
      try {
        await db.execute(
          'ALTER TABLE personal_tasks ADD COLUMN images TEXT DEFAULT "[]"',
        );
      } catch (_) {}
    }
    if (oldVersion < 8) {
      try {
        await db.execute('''
CREATE TABLE personal_workspaces (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  owner_uid TEXT DEFAULT '',
  members TEXT DEFAULT '[]',
  created_at TEXT NOT NULL
)
''');
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE personal_boards ADD COLUMN workspace_id TEXT DEFAULT ""',
        );
      } catch (_) {}
    }
    if (oldVersion < 9) {
      try {
        await db.execute(
          'ALTER TABLE personal_boards ADD COLUMN documents TEXT DEFAULT "[]"',
        );
      } catch (_) {}
    }
    if (oldVersion < 10) {
      try {
        await db.execute(
          'ALTER TABLE personal_tasks ADD COLUMN comments TEXT DEFAULT "[]"',
        );
      } catch (_) {}
    }
    if (oldVersion < 11) {
      try {
        await _createChatTables(db);
      } catch (_) {}
    }
    if (oldVersion < 12) {
      try {
        await db.execute(
          'ALTER TABLE personal_tasks ADD COLUMN checklist TEXT DEFAULT "[]"',
        );
      } catch (_) {}
    }
    if (oldVersion < 13) {
      try {
        await db.execute('''
CREATE TABLE personal_meetings (
  id TEXT PRIMARY KEY,
  board_id TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT DEFAULT '',
  notes TEXT DEFAULT '',
  start_at TEXT NOT NULL,
  end_at TEXT DEFAULT '',
  role_tags TEXT DEFAULT '[]',
  attachments TEXT DEFAULT '[]',
  transcript TEXT DEFAULT '',
  summary TEXT DEFAULT '',
  updated_at INTEGER DEFAULT 0,
  created_at TEXT NOT NULL,
  FOREIGN KEY(board_id) REFERENCES personal_boards(id)
)
''');
      } catch (_) {}
    }
  }

  // ─── WORKSPACES ───────────────────────────────────────

  Future<String> insertWorkspace(WorkspaceModel workspace) async {
    if (kIsWeb) return workspace.id;
    final db = await database;
    final id = workspace.id.isEmpty
        ? DateTime.now().millisecondsSinceEpoch.toString()
        : workspace.id;
    final map = {...workspace.toMap(), 'id': id};
    try {
      await db.insert(
        'personal_workspaces',
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('DB DEBUG insertWorkspace success id=$id');
    } catch (e) {
      debugPrint('DB DEBUG insertWorkspace error: $e');
      rethrow;
    }
    return id;
  }

  Future<List<WorkspaceModel>> getAllWorkspaces() async {
    if (kIsWeb) return [];
    final db = await database;
    final result = await db.query(
      'personal_workspaces',
      orderBy: 'created_at DESC',
    );
    return result.map((m) => WorkspaceModel.fromMap(m)).toList();
  }

  Future<void> updateWorkspace(WorkspaceModel workspace) async {
    if (kIsWeb) return;
    final db = await database;
    await db.update(
      'personal_workspaces',
      workspace.toMap(),
      where: 'id = ?',
      whereArgs: [workspace.id],
    );
  }

  Future<void> deleteWorkspace(String workspaceId) async {
    if (kIsWeb) return;
    final db = await database;
    // Delete all boards belonging to this workspace
    final boards = await db.query(
      'personal_boards',
      where: 'workspace_id = ?',
      whereArgs: [workspaceId],
    );
    for (final board in boards) {
      final boardId = board['id'] as String;
      await deleteBoard(boardId);
    }
    await db.delete(
      'personal_workspaces',
      where: 'id = ?',
      whereArgs: [workspaceId],
    );
  }

  // ─── BOARDS ───────────────────────────────────────────

  Future<String> insertBoard(BoardModel board) async {
    if (kIsWeb) return board.id;
    final db = await database;
    final id = board.id.isEmpty
        ? DateTime.now().millisecondsSinceEpoch.toString()
        : board.id;
    final map = {...board.toMap(), 'id': id};
    try {
      await db.insert(
        'personal_boards',
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('DB DEBUG insertBoard success id=$id');
    } catch (e) {
      debugPrint('DB DEBUG insertBoard error: $e');
      rethrow;
    }
    return id;
  }

  Future<List<BoardModel>> getAllBoards() async {
    if (kIsWeb) return [];
    final db = await database;
    final result = await db.query(
      'personal_boards',
      orderBy: 'created_at DESC',
    );
    return result.map((m) => BoardModel.fromMap(m)).toList();
  }

  Future<void> updateBoard(BoardModel board) async {
    if (kIsWeb) return;
    final db = await database;
    await db.update(
      'personal_boards',
      board.toMap(),
      where: 'id = ?',
      whereArgs: [board.id],
    );
  }

  Future<void> deleteBoard(String boardId) async {
    if (kIsWeb) return;
    final db = await database;
    await db.delete(
      'personal_tasks',
      where: 'board_id = ?',
      whereArgs: [boardId],
    );
    await db.delete(
      'personal_meetings',
      where: 'board_id = ?',
      whereArgs: [boardId],
    );
    await db.delete('personal_boards', where: 'id = ?', whereArgs: [boardId]);
  }

  // ─── TASKS ────────────────────────────────────────────

  Future<String> insertTask(TaskModel task) async {
    if (kIsWeb) return task.id;
    final db = await database;
    final id = task.id.isEmpty
        ? DateTime.now().millisecondsSinceEpoch.toString()
        : task.id;
    final map = {...task.toMap(), 'id': id};
    try {
      await db.insert(
        'personal_tasks',
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('DB DEBUG insertTask success id=$id board=${task.boardId}');
    } catch (e) {
      debugPrint('DB DEBUG insertTask error: $e');
      rethrow;
    }
    return id;
  }

  Future<List<TaskModel>> getTasksByBoard(String boardId) async {
    if (kIsWeb) return [];
    final db = await database;
    final result = await db.query(
      'personal_tasks',
      where: 'board_id = ?',
      whereArgs: [boardId],
      orderBy: 'time ASC',
    );
    return result.map((m) => TaskModel.fromMap(m)).toList();
  }

  Future<List<TaskModel>> getAllTasks() async {
    if (kIsWeb) return [];
    final db = await database;
    final result = await db.query('personal_tasks', orderBy: 'time ASC');
    return result.map((m) => TaskModel.fromMap(m)).toList();
  }

  Future<List<TaskModel>> getAllTasksWithDueDate() async {
    if (kIsWeb) return [];
    final db = await database;
    final result = await db.query(
      'personal_tasks',
      where: "due_date IS NOT NULL AND due_date != ''",
      orderBy: 'due_date ASC',
    );
    return result.map((m) => TaskModel.fromMap(m)).toList();
  }

  Future<void> updateTask(TaskModel task) async {
    if (kIsWeb) return;
    final db = await database;
    try {
      await db.update(
        'personal_tasks',
        task.toMap(),
        where: 'id = ?',
        whereArgs: [task.id],
      );
      debugPrint('DB DEBUG updateTask id=${task.id}');
    } catch (e) {
      debugPrint('DB DEBUG updateTask error: $e');
      rethrow;
    }
  }

  Future<void> updateTaskStatus(String id, String status) async {
    if (kIsWeb) return;
    final db = await database;
    try {
      await db.update(
        'personal_tasks',
        {'status': status},
        where: 'id = ?',
        whereArgs: [id],
      );
      debugPrint('DB DEBUG updateTaskStatus id=$id status=$status');
    } catch (e) {
      debugPrint('DB DEBUG updateTaskStatus error: $e');
      rethrow;
    }
  }

  Future<void> deleteTask(String id) async {
    if (kIsWeb) return;
    final db = await database;
    try {
      await db.delete('personal_tasks', where: 'id = ?', whereArgs: [id]);
      debugPrint('DB DEBUG deleteTask id=$id');
    } catch (e) {
      debugPrint('DB DEBUG deleteTask error: $e');
      rethrow;
    }
  }

  // ─── MEETINGS ────────────────────────────────────────

  Future<String> insertMeeting(MeetingModel meeting) async {
    if (kIsWeb) return meeting.id;
    final db = await database;
    final id = meeting.id.isEmpty
        ? DateTime.now().millisecondsSinceEpoch.toString()
        : meeting.id;
    final map = {...meeting.toMap(), 'id': id};
    await db.insert(
      'personal_meetings',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return id;
  }

  Future<List<MeetingModel>> getMeetingsByBoard(String boardId) async {
    if (kIsWeb) return [];
    final db = await database;
    final result = await db.query(
      'personal_meetings',
      where: 'board_id = ?',
      whereArgs: [boardId],
      orderBy: 'start_at ASC',
    );
    return result.map((m) => MeetingModel.fromMap(m)).toList();
  }

  Future<List<MeetingModel>> getAllMeetings() async {
    if (kIsWeb) return [];
    final db = await database;
    final result = await db.query('personal_meetings', orderBy: 'start_at ASC');
    return result.map((m) => MeetingModel.fromMap(m)).toList();
  }

  Future<void> updateMeeting(MeetingModel meeting) async {
    if (kIsWeb) return;
    final db = await database;
    await db.update(
      'personal_meetings',
      meeting.toMap(),
      where: 'id = ?',
      whereArgs: [meeting.id],
    );
  }

  Future<void> deleteMeeting(String id) async {
    if (kIsWeb) return;
    final db = await database;
    await db.delete('personal_meetings', where: 'id = ?', whereArgs: [id]);
  }

  // ─── CHAT SYSTEM ──────────────────────────────────────

  Future<void> _createChatTables(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS chat_sessions (
  id TEXT PRIMARY KEY,
  uid TEXT NOT NULL,
  task_id TEXT DEFAULT '',
  name TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at INTEGER DEFAULT 0
)
''');
    await db.execute('''
CREATE TABLE IF NOT EXISTS chat_messages (
  id TEXT PRIMARY KEY,
  session_id TEXT NOT NULL,
  text TEXT NOT NULL,
  reasoning TEXT DEFAULT '',
  is_user INTEGER NOT NULL,
  has_draft INTEGER DEFAULT 0,
  pending_call TEXT DEFAULT '',
  tool_calls TEXT DEFAULT '[]',
  attachments TEXT DEFAULT '[]',
  timestamp TEXT NOT NULL,
  FOREIGN KEY(session_id) REFERENCES chat_sessions(id) ON DELETE CASCADE
)
''');
  }

  Future<void> insertChatSession(
    String id,
    String uid,
    String name, {
    String taskId = '',
  }) async {
    if (kIsWeb) return;
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.insert('chat_sessions', {
      'id': id,
      'uid': uid,
      'task_id': taskId,
      'name': name,
      'created_at': now,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getChatSessions(
    String uid, {
    String taskId = '',
  }) async {
    if (kIsWeb) return [];
    final db = await database;
    return await db.query(
      'chat_sessions',
      where: 'uid = ? AND task_id = ?',
      whereArgs: [uid, taskId],
      orderBy: 'updated_at DESC',
    );
  }

  Future<void> updateChatSessionName(String sessionId, String newName) async {
    if (kIsWeb) return;
    final db = await database;
    await db.update(
      'chat_sessions',
      {'name': newName, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<void> deleteChatSession(String sessionId) async {
    if (kIsWeb) return;
    final db = await database;
    await db.delete('chat_sessions', where: 'id = ?', whereArgs: [sessionId]);
    await db.delete(
      'chat_messages',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<void> insertChatMessage(ChatMessage message, String sessionId) async {
    if (kIsWeb) return;
    final db = await database;
    await db.update(
      'chat_sessions',
      {'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
    final cleanedAttachments = message.attachments.map((a) {
      final copy = Map<String, String>.from(a);
      copy.remove('b64');
      return copy;
    }).toList();
    await db.insert('chat_messages', {
      'id': message.id,
      'session_id': sessionId,
      'text': message.text,
      'reasoning': message.reasoning ?? '',
      'is_user': message.isUser ? 1 : 0,
      'has_draft': message.hasDraft ? 1 : 0,
      'pending_call': message.pendingCall != null
          ? jsonEncode({
              'name': message.pendingCall.name,
              'arguments': message.pendingCall.args,
            })
          : '',
      'tool_calls': jsonEncode(
        message.toolCalls
            .map((tc) => {'name': tc.name, 'arguments': tc.arguments})
            .toList(),
      ),
      'attachments': jsonEncode(cleanedAttachments),
      'timestamp': message.timestamp.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ChatMessage>> getChatMessages(String sessionId) async {
    if (kIsWeb) return [];
    final db = await database;
    final result = await db.query(
      'chat_messages',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp ASC',
    );
    List<ChatMessage> list = [];
    for (final m in result) {
      final pendingCallStr = m['pending_call'] as String? ?? '';
      dynamic parsedPendingCall;
      if (pendingCallStr.isNotEmpty) {
        try {
          final pMap = jsonDecode(pendingCallStr);
          parsedPendingCall = FunctionCall(
            pMap['name'],
            Map<String, Object?>.from(pMap['arguments']),
          );
        } catch (_) {}
      }
      final toolCallsStr = m['tool_calls'] as String? ?? '[]';
      List<ToolCallInfo> parsedToolCalls = [];
      try {
        final tcList = jsonDecode(toolCallsStr) as List;
        parsedToolCalls = tcList
            .map(
              (tc) => ToolCallInfo(
                name: tc['name'].toString(),
                arguments: Map<String, dynamic>.from(tc['arguments']),
              ),
            )
            .toList();
      } catch (_) {}

      final attachmentsStr = m['attachments'] as String? ?? '[]';
      List<Map<String, String>> parsedAttachments = [];
      try {
        final attList = jsonDecode(attachmentsStr) as List;
        parsedAttachments = attList
            .map((a) => Map<String, String>.from(a))
            .toList();
      } catch (_) {}

      list.add(
        ChatMessage(
          id: m['id'] as String,
          text: m['text'] as String,
          reasoning: m['reasoning'] as String?,
          isUser: (m['is_user'] == 1),
          hasDraft: (m['has_draft'] == 1),
          pendingCall: parsedPendingCall,
          toolCalls: parsedToolCalls,
          attachments: parsedAttachments,
          timestamp:
              DateTime.tryParse(m['timestamp'] as String? ?? '') ??
              DateTime.now(),
        ),
      );
    }
    return list.reversed.toList();
  }
}
