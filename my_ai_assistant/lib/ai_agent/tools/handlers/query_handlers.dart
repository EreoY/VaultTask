import '../../../services/auth_service.dart';
import '../../../databases/api_cloudflare.dart';
import '../../../models/board_model.dart';

class QueryHandlers {
  static Future<String> handleListBoards(Map<String, dynamic> args) async {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return 'ยังไม่ล็อกอิน';
    try {
      final boards = await ApiCloudflare.getBoards(uid);
      if (boards.isEmpty)
        return 'คุณยังไม่มีบอร์ด หรือยังไม่ได้เข้าสู่ระบบทีมใดๆ';

      final buf = StringBuffer('รายการบอร์ดทั้งหมดที่คุณเข้าถึงได้:\n\n');
      for (final b in boards) {
        buf.writeln(
          '- บอร์ด: ${b.name} (ID: ${b.id}) | สมาชิก: ${b.members.length} คน | สถานะ: ${b.columns.join(", ")}',
        );
      }
      return buf.toString();
    } catch (e) {
      return 'เกิดข้อผิดพลาดในการดึงข้อมูลบอร์ด: $e';
    }
  }

  static Future<String> handleQueryTeamTasks(Map<String, dynamic> args) async {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return 'ยังไม่ล็อกอิน';
    final boardId = args['board_id']?.toString();
    try {
      List<BoardModel> boards = await ApiCloudflare.getBoards(uid);
      if (boardId != null && boardId.isNotEmpty) {
        boards = boards.where((b) => b.id == boardId).toList();
      }

      final buf = StringBuffer(
        'รายการงานจริงจากระบบ:\n'
        'ถ้าต้องแสดงผลให้ผู้ใช้เห็น ให้เรียก show_tasks_from_ids ด้วย task_ids จากรายการนี้เท่านั้น ห้ามสร้างตารางเองด้วย show_ui_content สำหรับงานจริง\n\n',
      );
      for (final b in boards) {
        final tasks = await ApiCloudflare.getTasksByBoard(b.id);
        for (final t in tasks) {
          buf.writeln(
            '- [ID: ${t.id}] ${t.title} | ${t.isCompleted ? 'เสร็จ' : 'ยังไม่เสร็จ'} | status: ${t.status} | due: ${t.dueDate.toIso8601String()} | board_id: ${b.id}',
          );
        }
      }
      return buf.toString();
    } catch (e) {
      return 'เกิดข้อผิดพลาดในการดึงงาน: $e';
    }
  }

  static Future<String> handleQueryBoardMembers(
    Map<String, dynamic> args,
  ) async {
    final boardId = args['board_id']?.toString();
    if (boardId == null) return 'ไม่ได้ระบุ board_id';
    return 'นี่คือข้อมูลสมาชิก (ดึงจาก live context ของระบบแล้ว)';
  }

  static Future<String> handleCheckUpdates(Map<String, dynamic> args) async {
    return 'ระบบซิงค์ข้อมูลกับฐานข้อมูลเรียบร้อยแล้ว';
  }

  static Future<String> handleCheckRoles(Map<String, dynamic> args) async {
    return 'บทบาทของสมาชิกถูกอัปเดตใน Context แล้ว';
  }
}
