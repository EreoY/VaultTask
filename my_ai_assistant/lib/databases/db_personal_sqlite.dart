import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import '../models/board_model.dart';
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
    return await openDatabase(path, version: 8, onCreate: _createDB, onUpgrade: _upgradeDB);
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
  images TEXT DEFAULT '[]',
  updated_at INTEGER DEFAULT 0,
  FOREIGN KEY(board_id) REFERENCES personal_boards(id)
)
''');
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
      await db.execute('ALTER TABLE personal_boards ADD COLUMN labels TEXT DEFAULT "[]";');
      await db.execute('ALTER TABLE personal_tasks ADD COLUMN label_ids TEXT DEFAULT "[]";');
    }
    if (oldVersion < 4) {
      try {
        await db.execute('ALTER TABLE personal_tasks ADD COLUMN description TEXT DEFAULT ""');
      } catch (_) {}
    }
    if (oldVersion < 5) {
      try {
        await db.execute('ALTER TABLE personal_tasks ADD COLUMN is_completed INTEGER NOT NULL DEFAULT 0');
      } catch (_) {}
    }
    if (oldVersion < 6) {
      try {
        await db.execute('ALTER TABLE personal_tasks ADD COLUMN updated_at INTEGER DEFAULT 0');
      } catch (_) {}
    }
    if (oldVersion < 7) {
      try {
        await db.execute('ALTER TABLE personal_tasks ADD COLUMN images TEXT DEFAULT "[]"');
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
        await db.execute('ALTER TABLE personal_boards ADD COLUMN workspace_id TEXT DEFAULT ""');
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
      await db.insert('personal_workspaces', map, conflictAlgorithm: ConflictAlgorithm.replace);
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
    final result = await db.query('personal_workspaces', orderBy: 'created_at DESC');
    return result.map((m) => WorkspaceModel.fromMap(m)).toList();
  }

  Future<void> updateWorkspace(WorkspaceModel workspace) async {
    if (kIsWeb) return;
    final db = await database;
    await db.update('personal_workspaces', workspace.toMap(), where: 'id = ?', whereArgs: [workspace.id]);
  }

  Future<void> deleteWorkspace(String workspaceId) async {
    if (kIsWeb) return;
    final db = await database;
    // Delete all boards belonging to this workspace
    final boards = await db.query('personal_boards', where: 'workspace_id = ?', whereArgs: [workspaceId]);
    for (final board in boards) {
      final boardId = board['id'] as String;
      await deleteBoard(boardId);
    }
    await db.delete('personal_workspaces', where: 'id = ?', whereArgs: [workspaceId]);
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
      await db.insert('personal_boards', map, conflictAlgorithm: ConflictAlgorithm.replace);
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
    final result = await db.query('personal_boards', orderBy: 'created_at DESC');
    return result.map((m) => BoardModel.fromMap(m)).toList();
  }

  Future<void> updateBoard(BoardModel board) async {
    if (kIsWeb) return;
    final db = await database;
    await db.update('personal_boards', board.toMap(), where: 'id = ?', whereArgs: [board.id]);
  }

  Future<void> deleteBoard(String boardId) async {
    if (kIsWeb) return;
    final db = await database;
    await db.delete('personal_tasks', where: 'board_id = ?', whereArgs: [boardId]);
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
      await db.insert('personal_tasks', map, conflictAlgorithm: ConflictAlgorithm.replace);
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
    final result = await db.query('personal_tasks', where: 'board_id = ?', whereArgs: [boardId], orderBy: 'time ASC');
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
    final result = await db.query('personal_tasks', where: "due_date IS NOT NULL AND due_date != ''", orderBy: 'due_date ASC');
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
      await db.update('personal_tasks', {'status': status}, where: 'id = ?', whereArgs: [id]);
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
}
