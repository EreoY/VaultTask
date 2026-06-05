import 'dart:async';
import '../../../services/auth_service.dart';
import '../../../databases/api_cloudflare.dart';
import '../../../models/task_model.dart';

class TeamHandlers {
  static String _generateId() => DateTime.now().millisecondsSinceEpoch.toString();
  
  // 🔄 Broadcast stream to notify state managers when a board changes
  static final _boardChangeController = StreamController<String>.broadcast();
  static Stream<String> get onBoardChange => _boardChangeController.stream;
  
  static void _notifyBoardChange(String boardId) {
    _boardChangeController.add(boardId);
  }

  static Future<String> handleCreate(Map<String, dynamic> args) async {
    // 🛡️ ATOMIC SUPPORT: Check if this is a single flat task or legacy batch
    final tasksList = args['tasks'] as List?;
    final authUid = AuthService().currentUser?.uid;
    if (authUid == null) return 'กรุณาล็อกอินก่อนดำเนินการ';

    if (tasksList == null || tasksList.isEmpty) {
      // 🏗️ FLAT MODE (Atomic)
      final title = args['title']?.toString();
      if (title == null || title.isEmpty) return 'กรุณาระบุชื่องาน';

      final boardId = (args['board_id'] ?? args['team_id'])?.toString();
      if (boardId == null || boardId.isEmpty) return 'กรุณาระบุบอร์ด';

      final due = args['due_date'] != null ? DateTime.tryParse(args['due_date'] as String) : null;
      final tMembers = (args['members'] as List?)?.map((e) => e.toString()).toList() ?? [authUid];
      final tLabels = (args['label_ids'] as List?)?.map((e) => e.toString()).toList() ?? [];

      final task = TaskModel(
        id: _generateId(),
        boardId: boardId,
        title: title,
        description: (args['description'] ?? '').toString(),
        dueDate: due ?? DateTime.now(),
        type: 'team',
        members: tMembers,
        labelIds: tLabels,
        status: (args['status'] ?? 'todo').toString(),
        isCompleted: args['is_completed'] == true || args['is_completed'] == 1,
      );

      await ApiCloudflare.insertTask(authUid, task);
      _notifyBoardChange(boardId);
      return 'สร้างงาน "$title" เรียบร้อยแล้วครับ ✅';
    }

    // 🏗️ LEGACY BATCH MODE
    final board = (args['team_id'] ?? args['board_id']);
    if (board == null || board.toString().isEmpty) return 'กรุณาระบุบอร์ด';
    
    int count = 0;
    for (final t in tasksList) {
      final taskMap = t as Map<String, dynamic>;
      final title = taskMap['title']?.toString() ?? 'Untitled Task';
      final due = taskMap['due_date'] != null ? DateTime.tryParse(taskMap['due_date'] as String) : null;
      final tMembers = (taskMap['members'] as List?)?.map((e) => e.toString()).toList() ?? [authUid];
      final tLabels = (taskMap['label_ids'] as List?)?.map((e) => e.toString()).toList() ?? [];

      final task = TaskModel(
        id: _generateId(),
        boardId: board.toString(),
        title: title,
        description: (taskMap['description'] ?? '').toString(),
        dueDate: due ?? DateTime.now(),
        type: 'team',
        members: tMembers,
        labelIds: tLabels,
        status: (taskMap['status'] ?? 'todo').toString(),
        isCompleted: taskMap['is_completed'] == true || taskMap['is_completed'] == 1,
      );
      
      await ApiCloudflare.insertTask(authUid, task);
      count++;
    }
    _notifyBoardChange(board.toString());
    return 'เพิ่ม $count งาน ลงบอร์ดแล้วครับ ✅';
  }

  static Future<String> handleUpdate(Map<String, dynamic> args) async {
    final id = args['id']?.toString();
    if (id == null) return 'ไม่พบ task id';
    
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return 'ยังไม่ล็อกอิน';
    
    // We need the existing task to perform a merge (Partial Update)
    // First, find which board this task belongs to if not provided
    String? boardId = args['board_id']?.toString();
    TaskModel? existing;

    if (boardId != null && boardId.isNotEmpty) {
       final tasks = await ApiCloudflare.getTasksByBoard(boardId);
       existing = tasks.where((t) => t.id == id).firstOrNull;
    } else {
       final boards = await ApiCloudflare.getBoards(uid);
       for (final b in boards) {
         final tasks = await ApiCloudflare.getTasksByBoard(b.id);
         existing = tasks.where((t) => t.id == id).firstOrNull;
         if (existing != null) {
           boardId = b.id;
           break;
         }
       }
    }

    if (existing == null) return 'ไม่พบงานที่ต้องการแก้ไข (ID: $id)';

    // 🛡️ PARTIAL MERGE LOGIC: Only update fields that are explicitly provided in args
    final updated = existing.copyWith(
      title: args.containsKey('title') ? args['title']?.toString() : existing.title,
      description: args.containsKey('description') ? args['description']?.toString() : existing.description,
      dueDate: args.containsKey('due_date') 
          ? (DateTime.tryParse(args['due_date'].toString()) ?? existing.dueDate) 
          : existing.dueDate,
      status: args.containsKey('status') ? args['status']?.toString() : existing.status,
      isCompleted: args.containsKey('is_completed') ? (args['is_completed'] as bool? ?? existing.isCompleted) : existing.isCompleted,
      members: args.containsKey('members') 
          ? (args['members'] as List?)?.map((e) => e.toString()).toList() 
          : existing.members,
      labelIds: args.containsKey('label_ids') 
          ? (args['label_ids'] as List?)?.map((e) => e.toString()).toList() 
          : existing.labelIds,
    );
    
    await ApiCloudflare.updateTask(updated);
    _notifyBoardChange(updated.boardId);
    return 'อัปเดตงาน "${updated.title}" เรียบร้อยแล้วครับ ✅';
  }

  static Future<String> handleDelete(Map<String, dynamic> args) async {
    final id = args['id']?.toString();
    if (id == null || id.isEmpty) return 'ไม่พบ task id';
    // Find boardId before deleting so we can notify
    String? boardId;
    final uid = AuthService().currentUser?.uid;
    if (uid != null) {
      final boards = await ApiCloudflare.getBoards(uid);
      for (final b in boards) {
        final tasks = await ApiCloudflare.getTasksByBoard(b.id);
        if (tasks.any((t) => t.id == id)) {
          boardId = b.id;
          break;
        }
      }
    }
    await ApiCloudflare.deleteTask(id);
    if (boardId != null) _notifyBoardChange(boardId);
    return 'ลบงานเรียบร้อยแล้ว 🗑️';
  }

  static Future<String> handleMove(Map<String, dynamic> args) async {
    final status = args['status']?.toString();
    final id = args['id']?.toString();
    if (status == null || status.isEmpty) return 'ไม่ได้ระบุ column ปลายทาง';
    if (id == null || id.isEmpty) return 'ไม่พบ task id';
    
    // 🚀 Task 64.1 compatibility: Find board_id for zero-latency sync
    String? boardId = args['board_id']?.toString();
    if (boardId == null || boardId.isEmpty) {
      final uid = AuthService().currentUser?.uid;
      if (uid != null) {
        final boards = await ApiCloudflare.getBoards(uid);
        for (final b in boards) {
          final tasks = await ApiCloudflare.getTasksByBoard(b.id);
          if (tasks.any((t) => t.id == id)) {
            boardId = b.id;
            break;
          }
        }
      }
    }

    if (boardId == null) return 'ไม่พบข้อมูลบอร์ดสำหรับงานนี้';

    // Check if we also need to update completion status (Manual Override)
    if (args.containsKey('is_completed')) {
       return await handleUpdate({...args, 'board_id': boardId});
    }
    
    await ApiCloudflare.updateTaskStatus(id, status, boardId);
    _notifyBoardChange(boardId);
    return 'ย้ายงานไปยัง column "$status" แล้วครับ ✅';
  }

  static Future<String> handleJoin(Map<String, dynamic> args) async {
    final boardId = args['board_id']?.toString();
    if (boardId == null || boardId.isEmpty) return 'กรุณาระบุ Board ID ที่ต้องการเข้าร่วม';
    
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return 'กรุณาล็อกอินก่อนดำเนินการ';
    
    try {
      await ApiCloudflare.joinBoard(uid, boardId);
      return 'เข้าร่วมบอร์ดสำเร็จแล้วครับ! 🤝 ตอนนี้คุณสามารถดูและจัดการงานในบอร์ด "$boardId" ได้แล้ว';
    } catch (e) {
      return 'ไม่สามารถเข้าร่วมบอร์ดได้: ${e.toString()}';
    }
  }
}
