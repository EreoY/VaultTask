import 'package:flutter/foundation.dart';
import '../../../databases/db_personal_sqlite.dart';
import '../../../models/board_model.dart';
import '../../../models/task_model.dart';

class PersonalHandlers {
  static String _generateId() => DateTime.now().millisecondsSinceEpoch.toString();

  static Future<String> handleCreate(Map<String, dynamic> args) async {
    final tasksList = args['tasks'] as List?;
    if (tasksList == null || tasksList.isEmpty) return 'ไม่มีข้อมูลงานให้สร้าง';
    
    List<BoardModel> pBoards = [];
    if (!kIsWeb) {
      try {
        pBoards = await DbPersonalSqlite.instance.getAllBoards();
        if (pBoards.isEmpty) {
          final defBoard = BoardModel(
            id: 'personal_default',
            name: 'Personal Tasks',
            type: 'personal',
          );
          await DbPersonalSqlite.instance.insertBoard(defBoard);
          pBoards.add(defBoard);
        }
      } catch (e) {
        debugPrint('Error getting personal boards: $e');
      }
    }
    final pBoardId = pBoards.isNotEmpty ? pBoards.first.id : 'personal_default';
    
    int count = 0;
    for (final t in tasksList) {
      final taskMap = t as Map<String, dynamic>;
      final due = taskMap['due_date'] != null ? DateTime.tryParse(taskMap['due_date'] as String) : null;
      final task = TaskModel(
        id: _generateId(),
        boardId: pBoardId,
        title: taskMap['title'] as String,
        description: (taskMap['description'] ?? '') as String,
        dueDate: due ?? DateTime.parse(taskMap['due_date'] as String),
        type: 'personal',
        status: 'todo',
      );
      if (!kIsWeb) await DbPersonalSqlite.instance.insertTask(task);
      count++;
    }
    return 'บันทึก $count งาน ลงตารางส่วนตัวเรียบร้อยครับ';
  }

  static Future<String> handleList(Map<String, dynamic> args) async {
    if (kIsWeb) return 'งานส่วนตัวไม่รองรับบน Web';
    try {
      final pTasks = await DbPersonalSqlite.instance.getAllTasks();
      if (pTasks.isEmpty) return 'ไม่พบงานส่วนตัว';
      
      final buf = StringBuffer('งานส่วนตัวของคุณ (${pTasks.length} งาน):\n\n');
      for (final t in pTasks) {
        buf.writeln('- [ID: ${t.id}] ${t.title} | ${t.isCompleted ? 'เสร็จ' : 'ยังไม่เสร็จ'} | ${t.dueDate}');
      }
      return buf.toString();
    } catch (e) {
      return 'ดึงงานส่วนตัวไม่ได้: $e';
    }
  }
}
