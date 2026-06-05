import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_model.dart';
import '../models/board_model.dart';
import '../databases/db_personal_sqlite.dart';
import '../databases/api_cloudflare.dart';
import '../ai_agent/tools/handlers/team_handlers.dart';
import 'state_boards.dart';

class StateTasks extends ChangeNotifier {
  StateBoards? _stateBoards;
  StreamSubscription<String>? _teamHandlerSub;
  StreamSubscription<String>? _boardChangeSub;

  StateTasks() {
    // Listen to AI handler changes for immediate refresh
    _teamHandlerSub = TeamHandlers.onBoardChange.listen((boardId) {
      debugPrint('🤖 AI triggered board change: $boardId');
      // 🛡️ Don't rely on _stateBoards being initialized yet
      final board = BoardModel(
        id: boardId, name: '', type: 'team', ownerUid: '', columns: [],
        members: const [],
      );
      fetchTasksForBoard(board, silent: true).then((_) {
        debugPrint('🤖 AI fetch completed for board: $boardId');
        // Notify other clients via Supabase Broadcast
        _broadcastUpdate(boardId);
      }).catchError((e) {
        debugPrint('🤖 AI fetch error for board $boardId: $e');
      });
    });
    // 🔄 Listen to board structure changes (columns, labels, etc.)
    _boardChangeSub = StateBoards.onBoardChange.listen((boardId) {
      debugPrint('📋 Board structure change: $boardId');
      final board = BoardModel(
        id: boardId, name: '', type: 'team', ownerUid: '', columns: [],
        members: const [],
      );
      fetchTasksForBoard(board, silent: true).then((_) {
        debugPrint('📋 Board fetch completed for board: $boardId');
        _broadcastUpdate(boardId);
      }).catchError((e) {
        debugPrint('📋 Board fetch error for board $boardId: $e');
      });
    });
  }

  // 🚀 Restore for main.dart
  void updateStateBoards(StateBoards? boards) {
    _stateBoards = boards;
  }

  final Map<String, List<TaskModel>> _tasksByBoard = {};
  final Map<String, ValueNotifier<TaskModel>> _taskNotifiers = {};
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  
  ValueNotifier<TaskModel>? getTaskNotifier(String taskId) => _taskNotifiers[taskId];

  // 🚀 Restore for dashboard and calendar
  List<TaskModel> get allTasks {
    return _tasksByBoard.values.expand((list) => list).toList();
  }

  List<TaskModel> get allTasksWithDueDate {
    return allTasks.where((t) => t.dueDate != null).toList();
  }

  int get totalCompletedCount => allTasks.where((t) => t.isCompleted).length;
  int get totalInProgressCount => allTasks.where((t) => !t.isCompleted).length;
  int get totalUpcomingCount => allTasksWithDueDate.where((t) => !t.isCompleted && t.dueDate.isAfter(DateTime.now())).length;

  List<TaskModel> tasksForBoard(String boardId) {
    final list = _tasksByBoard[boardId] ?? [];
    final sorted = List<TaskModel>.from(list);
    sorted.sort((a, b) {
      int cmp = a.orderIndex.compareTo(b.orderIndex);
      if (cmp != 0) return cmp;
      return a.dueDate.compareTo(b.dueDate);
    });
    return sorted;
  }

  // Real-time WebSocket Management via Supabase Realtime Broadcast
  final Map<String, RealtimeChannel> _channels = {};
  final Map<String, bool> _connecting = {};

  void subscribeBoard(BoardModel board) {
    if (board.type == 'personal') return;
    if (_channels.containsKey(board.id)) return;
    if (_connecting[board.id] == true) return;

    _connecting[board.id] = true;
    try {
      final channel = Supabase.instance.client.channel('board_${board.id}');
      channel.onBroadcast(
        event: 'update',
        callback: (payload) async {
          debugPrint('📨 Supabase Broadcast received for board ${board.id}: $payload');
          await fetchTasksForBoard(board, silent: true);
          if (_stateBoards != null) { await _stateBoards!.fetchSingleBoard(board.id); } 
        },
      ).subscribe();

      _channels[board.id] = channel;
      debugPrint('✅ Subscribed to Supabase Broadcast for board: ${board.id}');
      _connecting[board.id] = false;
    } catch (e) {
      debugPrint('Supabase Connection Exception: $e');
      _connecting[board.id] = false;
      _scheduleReconnect(board);
    }
  }

  void unsubscribeBoard(String boardId) {
    final ch = _channels[boardId];
    if (ch != null) {
      Supabase.instance.client.removeChannel(ch);
    }
    _channels.remove(boardId);
  }

  void _broadcastUpdate(String boardId) {
    final ch = _channels[boardId];
    if (ch != null) {
      try {
        ch.sendBroadcastMessage(
          event: 'update',
          payload: {'action': 'refresh', 'timestamp': DateTime.now().toIso8601String()},
        );
        debugPrint('📢 Broadcast sent for board: $boardId');
      } catch (e) {
        debugPrint('Error sending broadcast: $e');
      }
    }
  }

  // 🚀 For dashboard initialization
  Future<void> fetchAllTasks(List<BoardModel> boards) async {
    _isLoading = true;
    notifyListeners();
    for (final b in boards) {
      await fetchTasksForBoard(b, silent: true);
    }
    _isLoading = false;
    notifyListeners();
  }

  final Map<String, int> _lastVersions = {};

  void _updateLastVersion(String boardId, List<TaskModel> tasks) {
    if (tasks.isEmpty) return;
    final maxUp = tasks.map((t) => t.updatedAt).reduce((a, b) => a > b ? a : b);
    if ((_lastVersions[boardId] ?? 0) < maxUp) {
      _lastVersions[boardId] = maxUp;
    }
  }

  Future<void> fetchTasksForBoard(BoardModel board, {bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final latestBoard = _stateBoards?.boards.firstWhere((b) => b.id == board.id, orElse: () => board) ?? board;

      List<TaskModel> tasks;
      if (latestBoard.type == 'personal') {
        tasks = kIsWeb ? [] : await DbPersonalSqlite.instance.getTasksByBoard(latestBoard.id);
      } else {
        tasks = await ApiCloudflare.getTasksByBoard(latestBoard.id);
      }
      
      if (latestBoard.columns.isNotEmpty) {
        tasks = tasks.map((t) {
          final trimmedStatus = t.status.trim();
          final statusMatch = latestBoard.columns.any((col) => col.trim() == trimmedStatus);
          if (!statusMatch) {
            return t.copyWith(status: latestBoard.columns.first);
          }
          return t;
        }).toList();
      }
      _tasksByBoard[latestBoard.id] = tasks;
      // 🚀 Sync individual notifiers
      for (var t in tasks) {
        final n = _taskNotifiers[t.id];
        if (n != null) n.value = t; else _taskNotifiers[t.id] = ValueNotifier(t);
      }
      _updateLastVersion(latestBoard.id, tasks);
    } catch (e) {
      debugPrint('Error fetching tasks for board ${board.id}: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTask(BoardModel board, TaskModel task) async {
    try {
      String id;
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (board.type == 'personal') {
        id = kIsWeb ? task.id : await DbPersonalSqlite.instance.insertTask(task.copyWith(boardId: board.id));
      } else {
        id = await ApiCloudflare.insertTask(uid, task.copyWith(boardId: board.id));
      }
      final saved = task.copyWith(id: id, boardId: board.id, updatedAt: DateTime.now().millisecondsSinceEpoch);
      _injectSingleTask(board.id, saved);
      _broadcastUpdate(board.id);
    } catch (e) { debugPrint('Error adding task: $e'); }
  }

  Future<void> updateTask(BoardModel board, TaskModel task) async {
    try {
      if (board.type == 'personal') {
        if (!kIsWeb) await DbPersonalSqlite.instance.updateTask(task);
      } else {
        await ApiCloudflare.updateTask(task);
      }
      final withTs = task.copyWith(updatedAt: DateTime.now().millisecondsSinceEpoch);
      _injectSingleTask(board.id, withTs);
      _broadcastUpdate(board.id);
    } catch (e) { debugPrint('Error updating task: $e'); }
  }

  Future<void> updateTaskStatus(BoardModel board, TaskModel task, String newStatus) async {
    try {
      if (board.type == 'personal') {
        if (!kIsWeb) await DbPersonalSqlite.instance.updateTaskStatus(task.id, newStatus);
      } else {
        await ApiCloudflare.updateTaskStatus(task.id, newStatus, board.id);
      }
      final updated = task.copyWith(status: newStatus, updatedAt: DateTime.now().millisecondsSinceEpoch);
      _injectSingleTask(board.id, updated);
      _broadcastUpdate(board.id);
    } catch (e) { debugPrint('Error updating task status: $e'); }
  }

  void reorderWithinColumn(BoardModel board, String columnId, int fromIndex, int toIndex) {
    final list = _tasksByBoard[board.id];
    if (list == null) return;
    final fullList = List<TaskModel>.from(list);
    final sameCol = fullList.where((t) => t.status == columnId).toList();
    if (fromIndex < 0 || fromIndex >= sameCol.length || toIndex < 0 || toIndex >= sameCol.length) return;
    final moving = sameCol.removeAt(fromIndex);
    sameCol.insert(toIndex, moving);

    final now = DateTime.now().millisecondsSinceEpoch;
    List<Map<String, dynamic>> updates = [];
    List<TaskModel> rebuilt = [];
    int sameColIdx = 0;
    for (final t in fullList) {
      if (t.status == columnId) {
        final ut = sameCol[sameColIdx].copyWith(orderIndex: sameColIdx, updatedAt: now);
        rebuilt.add(ut);
        updates.add({'id': ut.id, 'order_index': ut.orderIndex});
        // Update notifier instantly
        final n = _taskNotifiers[ut.id]; if (n != null) n.value = ut; else _taskNotifiers[ut.id] = ValueNotifier(ut);
        sameColIdx++;
      } else { rebuilt.add(t); }
    }
    _tasksByBoard[board.id] = rebuilt;
    notifyListeners();
    if (board.type != 'personal') { 
      ApiCloudflare.updateTaskOrder(board.id, updates).then((_) {
        _broadcastUpdate(board.id);
      }); 
    }
  }

  Future<void> deleteTask(BoardModel board, TaskModel task) async {
    try {
      if (board.type == 'personal') {
        if (!kIsWeb) await DbPersonalSqlite.instance.deleteTask(task.id);
      } else {
        await ApiCloudflare.deleteTask(task.id);
      }
      final list = _tasksByBoard[board.id];
      if (list != null) {
        list.removeWhere((t) => t.id == task.id);
        _taskNotifiers.remove(task.id);
        notifyListeners();
      }
      _broadcastUpdate(board.id);
    } catch (e) { debugPrint('Error deleting task: $e'); }
  }

  void _injectSingleTask(String boardId, TaskModel updatedTask) {
    final tasks = _tasksByBoard[boardId] ?? [];
    final notifier = _taskNotifiers[updatedTask.id];
    if (notifier != null) notifier.value = updatedTask; else _taskNotifiers[updatedTask.id] = ValueNotifier(updatedTask);

    int idx = tasks.indexWhere((t) => t.id == updatedTask.id);
    if (idx != -1) {
      final existing = tasks[idx];
      bool structuralChange = existing.status != updatedTask.status || existing.orderIndex != updatedTask.orderIndex;
      if (existing.updatedAt < updatedTask.updatedAt || structuralChange) {
        tasks[idx] = updatedTask;
        _tasksByBoard[boardId] = List.from(tasks);
        if (structuralChange) notifyListeners();
      }
    } else {
      tasks.add(updatedTask);
      _tasksByBoard[boardId] = List.from(tasks);
      notifyListeners();
    }
  }

  void _applyAtomicUpdate(String boardId, List<TaskModel> newTasks) {
    final currentTasks = _tasksByBoard[boardId] ?? [];
    final Map<String, TaskModel> taskMap = {for (var t in currentTasks) t.id: t};
    bool changed = false;
    for (var nt in newTasks) {
      final n = _taskNotifiers[nt.id]; if (n != null) n.value = nt; else _taskNotifiers[nt.id] = ValueNotifier(nt);
      final existing = taskMap[nt.id];
      if (existing == null || existing.updatedAt != nt.updatedAt || existing.status != nt.status || existing.orderIndex != nt.orderIndex) {
        taskMap[nt.id] = nt;
        changed = true;
      }
    }
    if (changed) {
      _tasksByBoard[boardId] = taskMap.values.toList();
      _updateLastVersion(boardId, newTasks);
      notifyListeners();
    }
  }

  final Map<String, int> _reconnectAttempts = {};
  void _scheduleReconnect(BoardModel board) {
    if (board.type == 'personal' || _connecting[board.id] == true) return;
    final attempts = _reconnectAttempts[board.id] ?? 0;
    if (attempts > 5) return;
    _connecting[board.id] = true;
    final delaySeconds = (pow(2, attempts) as int).clamp(1, 60);
    Future.delayed(Duration(seconds: delaySeconds), () {
      _connecting[board.id] = false;
      _reconnectAttempts[board.id] = attempts + 1;
      subscribeBoard(board);
    });
  }

  void clearNotifiersForBoard(String boardId) {
    final tasks = _tasksByBoard[boardId] ?? [];
    for (var t in tasks) {
      _taskNotifiers[t.id]?.dispose();
      _taskNotifiers.remove(t.id);
    }
  }

  @override
  void dispose() {
    _teamHandlerSub?.cancel();
    _boardChangeSub?.cancel();
    for (final ch in _channels.values) {
      Supabase.instance.client.removeChannel(ch);
    }
    _channels.clear();
    for (final n in _taskNotifiers.values) {
      n.dispose();
    }
    _taskNotifiers.clear();
    super.dispose();
  }
}
