import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';
import '../models/board_model.dart';
import '../databases/db_personal_sqlite.dart';
import '../databases/api_cloudflare.dart';
import '../ai_agent/tools/handlers/team_handlers.dart';
import 'state_boards.dart';
import 'state_chat.dart';
import 'package:intl/intl.dart';

class StateTasks extends ChangeNotifier {
  StateBoards? _stateBoards;
  StreamSubscription<String>? _teamHandlerSub;
  StreamSubscription<String>? _boardChangeSub;
  StreamSubscription<Map<String, dynamic>>? _descriptionRegenSub;

  Set<String> _readCommentIds = {};
  Set<String> get readCommentIds => _readCommentIds;

  int get unreadCommentsCount {
    int count = 0;
    for (final task in allTasks) {
      for (final comment in task.comments) {
        if (!_readCommentIds.contains(comment.id)) {
          count++;
        }
      }
    }
    return count;
  }

  StateTasks() {
    _loadReadComments();
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

    // 🖼️ Listen to AI image description regeneration events
    _descriptionRegenSub = StateChat.onImageDescriptionRegenerated.stream.listen((event) async {
      final name = event['name'] as String?;
      final url = event['url'] as String?;
      final description = event['aiDescription'] as String?;
      if (description == null) return;

      bool changed = false;

      // Scan all tasks in _tasksByBoard
      for (final entry in _tasksByBoard.entries) {
        final boardId = entry.key;
        final tasks = entry.value;

        // Try to find if the board is personal or team
        final board = _stateBoards?.boards.firstWhere(
          (b) => b.id == boardId,
          orElse: () => BoardModel(
            id: boardId,
            name: '',
            type: boardId.contains('_') ? 'team' : 'personal',
            ownerUid: '',
            columns: [],
            members: [],
          ),
        );
        final boardType = board?.type ?? 'personal';

        for (int i = 0; i < tasks.length; i++) {
          final task = tasks[i];
          final hasMatch = task.images.any((img) => img.url == url || (url == null && img.r2Key == name));
          if (hasMatch) {
            final updatedImages = task.images.map((img) {
              if (img.url == url || (url == null && img.r2Key == name)) {
                return img.copyWith(aiDescription: description);
              }
              return img;
            }).toList();

            final updatedTask = task.copyWith(
              images: updatedImages,
              updatedAt: DateTime.now().millisecondsSinceEpoch,
            );

            // Persist
            try {
              if (boardType == 'personal') {
                if (!kIsWeb) {
                  await DbPersonalSqlite.instance.updateTask(updatedTask);
                }
              } else {
                await ApiCloudflare.updateTask(updatedTask);
              }
            } catch (e) {
              debugPrint('Error persisting regenerated image description: $e');
            }

            // Update in-memory
            tasks[i] = updatedTask;
            final notifier = _taskNotifiers[task.id];
            if (notifier != null) {
              notifier.value = updatedTask;
            }
            changed = true;

            // Broadcast
            _broadcastUpdate(boardId);
          }
        }
      }

      if (changed) notifyListeners();
    });
  }

  Future<void> _loadReadComments() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final d1Reads = await ApiCloudflare.getReadCommentIds(uid);
        _readCommentIds = d1Reads.toSet();
      } else {
        final prefs = await SharedPreferences.getInstance();
        final list = prefs.getStringList('read_comment_ids') ?? [];
        _readCommentIds = list.toSet();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading read comments: $e');
    }
  }

  Future<void> markCommentAsRead(String id) async {
    if (_readCommentIds.contains(id)) return;
    _readCommentIds.add(id);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('read_comment_ids', _readCommentIds.toList());
      
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await ApiCloudflare.markCommentsAsRead(uid, [id]);
      }
    } catch (e) {
      debugPrint('Error saving read comment: $e');
    }
  }

  Future<void> markCommentsAsRead(List<String> ids) async {
    bool changed = false;
    final List<String> newIds = [];
    for (final id in ids) {
      if (!_readCommentIds.contains(id)) {
        _readCommentIds.add(id);
        newIds.add(id);
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('read_comment_ids', _readCommentIds.toList());
        
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null && newIds.isNotEmpty) {
          await ApiCloudflare.markCommentsAsRead(uid, newIds);
        }
      } catch (e) {
        debugPrint('Error saving read comments: $e');
      }
    }
  }

  Future<void> markAllCommentsAsReadForTask(TaskModel task) async {
    final commentIds = task.comments.map((c) => c.id).toList();
    await markCommentsAsRead(commentIds);
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
    await _loadReadComments();
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
    
    if (_readCommentIds.isEmpty) {
      await _loadReadComments();
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
      final now = DateTime.now();
      final currentUid = FirebaseAuth.instance.currentUser?.uid ?? 'system';
      final profile = _stateBoards?.getMemberProfile(currentUid);
      final currentUserName = profile?['name'] ?? 'Operative';

      final initialComment = TaskComment(
        id: '${now.millisecondsSinceEpoch}_sys_init',
        userId: currentUid,
        userName: currentUserName,
        text: '[ระบบ] สร้างงานใหม่สำเร็จ: "${task.title}"',
        time: now,
      );
      final updatedComments = List<TaskComment>.from(task.comments)..add(initialComment);
      final taskWithComment = task.copyWith(comments: updatedComments);

      String id;
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (board.type == 'personal') {
        id = kIsWeb ? taskWithComment.id : await DbPersonalSqlite.instance.insertTask(taskWithComment.copyWith(boardId: board.id));
      } else {
        id = await ApiCloudflare.insertTask(uid, taskWithComment.copyWith(boardId: board.id));
      }
      final saved = taskWithComment.copyWith(id: id, boardId: board.id, updatedAt: DateTime.now().millisecondsSinceEpoch);
      _injectSingleTask(board.id, saved);
      _broadcastUpdate(board.id);
    } catch (e) { debugPrint('Error adding task: $e'); }
  }

  Future<void> updateTask(BoardModel board, TaskModel task) async {
    try {
      TaskModel? oldTask;
      final list = _tasksByBoard[board.id];
      if (list != null) {
        try {
          oldTask = list.firstWhere((t) => t.id == task.id);
        } catch (_) {}
      }

      final systemComments = <TaskComment>[];
      final now = DateTime.now();
      final currentUid = FirebaseAuth.instance.currentUser?.uid ?? 'system';
      final profile = _stateBoards?.getMemberProfile(currentUid);
      final currentUserName = profile?['name'] ?? 'Operative';

      if (oldTask != null) {
        int idx = 0;
        String nextCommentId() => '${now.millisecondsSinceEpoch}_sys_${idx++}';

        if (oldTask.title != task.title) {
          systemComments.add(TaskComment(
            id: nextCommentId(),
            userId: currentUid,
            userName: currentUserName,
            text: '[ระบบ] เปลี่ยนชื่อเดิมจาก "${oldTask.title}" เป็น "${task.title}"',
            time: now,
          ));
        }

        if (oldTask.description != task.description) {
          systemComments.add(TaskComment(
            id: nextCommentId(),
            userId: currentUid,
            userName: currentUserName,
            text: '[ระบบ] อัปเดตรายละเอียดงาน',
            time: now,
          ));
        }

        if (oldTask.status != task.status) {
          String oldColName = oldTask.status;
          String newColName = task.status;
          if (board.columns.isNotEmpty) {
            final oldCol = board.columns.firstWhere((c) => c == oldTask!.status, orElse: () => oldTask!.status);
            final newCol = board.columns.firstWhere((c) => c == task.status, orElse: () => task.status);
            oldColName = oldCol;
            newColName = newCol;
          }
          systemComments.add(TaskComment(
            id: nextCommentId(),
            userId: currentUid,
            userName: currentUserName,
            text: '[ระบบ] ย้ายงานจากช่อง "$oldColName" ไปที่ "$newColName"',
            time: now,
          ));
        }

        if (oldTask.isCompleted != task.isCompleted) {
          systemComments.add(TaskComment(
            id: nextCommentId(),
            userId: currentUid,
            userName: currentUserName,
            text: '[ระบบ] ทำเครื่องหมายงานเป็น ${task.isCompleted ? "เสร็จสิ้น" : "ยังไม่เสร็จ"}',
            time: now,
          ));
        }

        if (oldTask.dueDate.millisecondsSinceEpoch != task.dueDate.millisecondsSinceEpoch) {
          final oldDateStr = DateFormat('dd/MM/yyyy HH:mm').format(oldTask.dueDate);
          final newDateStr = DateFormat('dd/MM/yyyy HH:mm').format(task.dueDate);
          systemComments.add(TaskComment(
            id: nextCommentId(),
            userId: currentUid,
            userName: currentUserName,
            text: '[ระบบ] เปลี่ยนวันครบกำหนดจาก "$oldDateStr" เป็น "$newDateStr"',
            time: now,
          ));
        }

        final oldMembers = oldTask.members;
        final newMembers = task.members;
        final addedMembers = newMembers.where((m) => !oldMembers.contains(m)).toList();
        final removedMembers = oldMembers.where((m) => !newMembers.contains(m)).toList();

        if (addedMembers.isNotEmpty) {
          final names = addedMembers.map((uid) {
            final profile = _stateBoards?.getMemberProfile(uid);
            return profile?['name'] ?? uid;
          }).join(', ');
          systemComments.add(TaskComment(
            id: nextCommentId(),
            userId: currentUid,
            userName: currentUserName,
            text: '[ระบบ] มอบหมายงานให้: $names',
            time: now,
          ));
        }
        if (removedMembers.isNotEmpty) {
          final names = removedMembers.map((uid) {
            final profile = _stateBoards?.getMemberProfile(uid);
            return profile?['name'] ?? uid;
          }).join(', ');
          systemComments.add(TaskComment(
            id: nextCommentId(),
            userId: currentUid,
            userName: currentUserName,
            text: '[ระบบ] ถอนการมอบหมายงานของ: $names',
            time: now,
          ));
        }

        final oldLabels = oldTask.labelIds;
        final newLabels = task.labelIds;
        final addedLabels = newLabels.where((l) => !oldLabels.contains(l)).toList();
        final removedLabels = oldLabels.where((l) => !newLabels.contains(l)).toList();

        if (addedLabels.isNotEmpty) {
          final names = addedLabels.map((id) {
            final label = board.labels.firstWhere((lbl) => lbl['id'] == id, orElse: () => {'name': id});
            return label['name'] ?? id;
          }).join(', ');
          systemComments.add(TaskComment(
            id: nextCommentId(),
            userId: currentUid,
            userName: currentUserName,
            text: '[ระบบ] เพิ่มป้ายกำกับ: $names',
            time: now,
          ));
        }
        if (removedLabels.isNotEmpty) {
          final names = removedLabels.map((id) {
            final label = board.labels.firstWhere((lbl) => lbl['id'] == id, orElse: () => {'name': id});
            return label['name'] ?? id;
          }).join(', ');
          systemComments.add(TaskComment(
            id: nextCommentId(),
            userId: currentUid,
            userName: currentUserName,
            text: '[ระบบ] ลบป้ายกำกับ: $names',
            time: now,
          ));
        }

        if (task.images.length > oldTask.images.length) {
          systemComments.add(TaskComment(
            id: nextCommentId(),
            userId: currentUid,
            userName: currentUserName,
            text: '[ระบบ] เพิ่มรูปภาพในงาน',
            time: now,
          ));
        } else if (task.images.length < oldTask.images.length) {
          systemComments.add(TaskComment(
            id: nextCommentId(),
            userId: currentUid,
            userName: currentUserName,
            text: '[ระบบ] ลบรูปภาพออกจากงาน',
            time: now,
          ));
        }
      }

      var updatedTask = task;
      if (systemComments.isNotEmpty) {
        final mergedComments = List<TaskComment>.from(task.comments)..addAll(systemComments);
        updatedTask = task.copyWith(comments: mergedComments);
      }

      if (board.type == 'personal') {
        if (!kIsWeb) await DbPersonalSqlite.instance.updateTask(updatedTask);
      } else {
        await ApiCloudflare.updateTask(updatedTask);
      }
      final withTs = updatedTask.copyWith(updatedAt: DateTime.now().millisecondsSinceEpoch);
      _injectSingleTask(board.id, withTs);
      _broadcastUpdate(board.id);
    } catch (e) { debugPrint('Error updating task: $e'); }
  }

  Future<void> updateTaskStatus(BoardModel board, TaskModel task, String newStatus) async {
    try {
      final now = DateTime.now();
      final currentUid = FirebaseAuth.instance.currentUser?.uid ?? 'system';
      final profile = _stateBoards?.getMemberProfile(currentUid);
      final currentUserName = profile?['name'] ?? 'Operative';

      String oldColName = task.status;
      String newColName = newStatus;
      if (board.columns.isNotEmpty) {
        final oldCol = board.columns.firstWhere((c) => c == task.status, orElse: () => task.status);
        final newCol = board.columns.firstWhere((c) => c == newStatus, orElse: () => newStatus);
        oldColName = oldCol;
        newColName = newCol;
      }

      final comment = TaskComment(
        id: '${now.millisecondsSinceEpoch}_sys_status',
        userId: currentUid,
        userName: currentUserName,
        text: '[ระบบ] ย้ายงานจากช่อง "$oldColName" ไปที่ "$newColName"',
        time: now,
      );
      final updatedComments = List<TaskComment>.from(task.comments)..add(comment);
      final updated = task.copyWith(
        status: newStatus,
        comments: updatedComments,
        updatedAt: now.millisecondsSinceEpoch,
      );

      if (board.type == 'personal') {
        if (!kIsWeb) await DbPersonalSqlite.instance.updateTask(updated);
      } else {
        await ApiCloudflare.updateTask(updated);
      }
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
    _descriptionRegenSub?.cancel();
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
