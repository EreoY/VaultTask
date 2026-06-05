import 'package:google_generative_ai/google_generative_ai.dart';

// ─── On-demand query tools ────────────────────────────────────────────────
final queryBoardsOverviewTool = FunctionDeclaration(
  'list_team_boards',
  'สรุปรายการบอร์ดทีมของผู้ใช้ (ใช้เมื่อต้องการรู้ว่ามีบอร์ดอะไรบ้าง)',
  Schema.object(properties: const {}),
);

final queryTeamTasksTool = FunctionDeclaration(
  'query_team_tasks',
  'ดึงรายการงานทีม (Team Tasks) ตามเงื่อนไขที่คุณต้องการวิเคราะห์ เช่น วันนี้, พรุ่งนี้, งานที่ค้าง (overdue), หรือกรองตามบอร์ดและสถานะคอลัมน์',
  Schema.object(
    properties: {
      'timeframe': Schema.string(
        description: 'ช่วงเวลาที่ต้องการดู: today, tomorrow, next_7_days, next_30_days, overdue, all',
      ),
      'board_id': Schema.string(
        description: 'ระบุ ID ของบอร์ดที่ต้องการเจาะจง (ถ้าไม่ระบุจะค้นหาจากทุกบอร์ดที่คุณเข้าถึงได้)',
      ),
      'status': Schema.string(
        description: 'ชื่อคอลัมน์ที่ต้องการกรอง (ต้องอิงตามชื่อจริงใน Board Context เช่น "เสร็จแล้ว", "กำลังทำ") เว้นว่างได้ถ้าจะเอาทั้งหมด',
      ),
      'has_deadline': Schema.boolean(
        description: 'กรองเฉพาะงานที่มีกำหนดส่ง (true) หรือไม่มี (false) เว้นว่างเพื่อเอาทั้งหมด',
      ),
      'is_completed': Schema.boolean(
        description: 'กรองงานที่ติ๊กเสร็จแล้ว (true) หรือยังไม่เสร็จ (false) — สำคัญมากในการเช็คงานค้าง',
      ),
      'limit': Schema.integer(
        description: 'จำนวนรายการสูงสุดที่ต้องการให้แสดง (แนะนำที่ 30-50)',
      ),
    },
    requiredProperties: const ['timeframe'],
  ),
);

final queryBoardMembersTool = FunctionDeclaration(
  'query_board_members',
  'ดูรายชื่อสมาชิกในบอร์ด (ใช้เมื่อต้องการมอบหมายงานให้คนอื่น)',
  Schema.object(
    properties: {
      'board_id': Schema.string(description: 'ID ของบอร์ด (จำเป็น)'),
    },
    requiredProperties: const ['board_id'],
  ),
);

final checkBoardUpdatesTool = FunctionDeclaration(
  'check_board_updates',
  'ตรวจสอบความเปลี่ยนแปลงล่าสุดของบอร์ด (ใช้เพื่อซิงค์ข้อมูลให้เป็นปัจจุบันที่สุด)',
  Schema.object(properties: {'board_id': Schema.string()}),
);

final checkMemberRolesTool = FunctionDeclaration(
  'check_member_roles',
  'ตรวจสอบบทบาทและความรับผิดชอบของสมาชิกในทีม (Role/Expertise)',
  Schema.object(properties: {'board_id': Schema.string()}),
);

final checkConflictTool = FunctionDeclaration(
  'check_conflict',
  'ตรวจสอบความขัดแย้งของข้อมูลหรือการสั่งงานซ้ำซ้อน',
  Schema.object(properties: {'task_id': Schema.string()}),
);
