import '../../services/auth_service.dart';
import '../../databases/api_cloudflare.dart';

class ContextBuilder {
  static Future<String> buildLiveContext() async {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return '';
    try {
      final boards = await ApiCloudflare.getBoards(uid);
      final user = AuthService().currentUser;
      final myName = user?.displayName ?? 'Your Name';
      
      if (boards.isNotEmpty) {
        final buf = StringBuffer('[ข้อมูลบริบทปัจจุบัน (Real-time Live Context):]\n');
        buf.writeln('- ตัวคุณคือ: $myName [UID: $uid]');
        buf.writeln('- บอร์ดของคุณและรายการงานปัจจุบัน:');
        for (final b in boards) {
          final memberNames = await ApiCloudflare.getUsersByUids(b.members);
          buf.writeln('  ▸ บอร์ด: ${b.name} [ID: ${b.id}]');
          buf.writeln('    คอลัมน์ที่มี: [${b.columns.join(', ')}]');
          
          // Inject labels
          if (b.labels.isNotEmpty) {
            final labelsStr = b.labels.map((l) => '${l['name']} [ID: ${l['id']}]').join(', ');
            buf.writeln('    ป้ายกำกับ (Labels): $labelsStr');
          }

          buf.writeln('    สมาชิกในบอร์ด:');
          for (final mUid in b.members) {
            final mName = memberNames[mUid]?['name'] ?? mUid;
            final mRole = b.memberRoles[mUid]?.isNotEmpty == true ? b.memberRoles[mUid] : 'General Member';
            buf.writeln('      - $mName [UID: $mUid] | Role: $mRole');
          }
          
          // Inject live tasks
          buf.writeln('    รายการงานในบอร์ดนี้ (พึ่งพา ID เหล่านี้เท่านั้น):');
          final tasks = await ApiCloudflare.getTasksByBoard(b.id);
          if (tasks.isEmpty) {
            buf.writeln('      - (ยังไม่มีงาน)');
          } else {
            for (final t in tasks) {
              final statusStr = t.isCompleted ? 'เสร็จแล้ว' : 'ยังไม่เสร็จ';
              // Convert member UIDs to names for AI convenience in text, but keep ID for tool logic
              final tMemberNames = t.members.map((muid) => memberNames[muid]?['name'] ?? muid).join(', ');
              buf.writeln('      - [ID: ${t.id}] "${t.title}" | สถานะ: ${t.status} ($statusStr) | ผู้รับผิดชอบ: $tMemberNames');
            }
          }
        }
        return '${buf.toString()}\n\n';
      }
    } catch (_) {}
    return '';
  }
}
