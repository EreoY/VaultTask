import 'package:google_generative_ai/google_generative_ai.dart';

// ─── Create Team Task ───────────────────────────────────────────────────────
final createTeamTaskTool = FunctionDeclaration(
  'create_team_task',
  'สร้างงานใหม่ 1 งานลงบอร์ดทีม ใช้เมื่อผู้ใช้สั่งสร้างงาน นัดหมองาน หรือเพิ่มงานใหม่ '
  '**ห้ามสร้างเป็นก้อนใหญ่ หากมีหลายงานให้เรียกเครื่องมือนี้ซ้ำๆ แยกกัน (Sequential Calls) เพื่อความแม่นยำสูงสุด**',
  Schema.object(
    properties: {
      'title': Schema.string(description: 'ชื่องานแบบสั้นกระชับ (ไม่ควรใส่ยาวเกินไป)'),
      'description': Schema.string(description: 'รายละเอียดเพิ่มเติม หรือเนื้อหายาวๆ ของงาน (แนะนำให้ใส่ถ้ารายละเอียดเยอะ)'),
      'due_date': Schema.string(description: 'วันกำหนดส่งหรือเวลานัดหมาย ISO8601 (ต้องดึงจากสิ่งที่เห็นในรูปหรือข้อความเท่านั้น หากผู้ใช้ไม่ระบุให้ใช้วันที่ปัจจุบัน)'),
      'status': Schema.string(
          description: 'คอลัมน์ที่งานนี้ควรอยู่ — ให้ตัดสินใจเชิงความหมายว่าเนื้อหางานนี้เหมาะกับคอลัมน์ไหน '
              'โดยดูจากชื่อคอลัมน์ของบอร์ดที่ระบุในบริบท (ห้ามเดาชื่อเอง ต้องใช้ชื่อที่มีอยู่จริงเท่านั้น)'),
      'label_ids': Schema.array(
        items: Schema.string(),
        description: 'รายการ ID ของป้ายกำกับ (Label) ที่เหมาะสมกับงานนี้ (ดูจาก labels ที่มีในบอร์ดปัจจุบัน)',
      ),
      'members': Schema.array(
        items: Schema.string(),
        description: 'รายชื่อผู้รับผิดชอบงานนี้ (ต้องวิเคราะห์จากรูปภาพหรือข้อความและใส่มาให้ครบทุกคนที่เกี่ยวข้อง ห้ามเว้นว่างหากมีข้อมูลสมาชิกปรากฏ)',
      ),
      'board_id': Schema.string(
          description: 'ID ของบอร์ดเป้าหมาย (ดูจาก Context)'),
    },
    requiredProperties: const ['title', 'due_date', 'description', 'members', 'label_ids', 'board_id'],
  ),
);

// ─── Update Team Task ─────────────────────────────────────────────────────────
final updateTeamTaskTool = FunctionDeclaration(
  'update_team_task',
  'แก้ไขข้อมูลงานที่มีอยู่แล้วในระบบ ใช้เมื่อผู้ใช้สั่งแก้ไขชื่องาน รายละเอียด วันกำหนดส่ง ผู้รับผิดชอบ หรือติ๊กเสร็จ ต้องรู้ task id ก่อน '
      '**ห้ามใช้เครื่องมือนี้แก้ไขงานที่เพิ่งเสนอสร้างและยังไม่ได้กดยืนยัน! ให้เรียก create_team_task ใหม่แทน**',
  Schema.object(
    properties: {
      'id': Schema.string(description: 'ID ของงานที่จะแก้ไข (ใช้ id หรือ ids อย่างใดอย่างหนึ่ง)'),
      'ids': Schema.array(
        items: Schema.string(),
        description: 'รายการ ID ของงานที่จะแก้ข้อมูลเดียวกันพร้อมกันหลายอัน (batch update)',
      ),
      'title': Schema.string(description: 'ชื่องานใหม่แบบสั้นกระชับ (ถ้าต้องการแก้)'),
      'description': Schema.string(description: 'รายละเอียดใหม่ที่เป็นเนื้อหายาวๆ (ถ้าต้องการแก้)'),
      'due_date': Schema.string(description: 'วันกำหนดส่งหรือเวลานัดหมายใหม่ ISO8601 (ถ้าต้องการแก้)'),
      'status': Schema.string(description: 'สถานะคอลัมน์ใหม่ (ต้องอิงตามชื่อจริงใน Board Context เท่านั้น) (ถ้าต้องการแก้)'),
      'is_completed': Schema.boolean(description: 'ถ้าต้องการติ๊กถูกให้งานนี้เสร็จสมบูรณ์ส่งผ่าน true, ถ้ายังไม่เสร็จ false (ถ้าต้องการแก้)'),
      'label_ids': Schema.array(
        items: Schema.string(),
        description: 'อัปเดตรายการป้ายกำกับ (Label IDs) (ถ้าต้องการแก้)',
      ),
      'members': Schema.array(
        items: Schema.string(),
        description: 'รายชื่อผู้เข้าร่วมใหม่ (ถ้าต้องการแก้ ถ้าไม่แก้ไม่ต้องส่ง)',
      ),
    },
    requiredProperties: const [],
  ),
);

// ─── Delete Team Task ─────────────────────────────────────────────────────────
final deleteTeamTaskTool = FunctionDeclaration(
  'delete_team_task',
  'ลบงานที่มีอยู่แล้วออกจากระบบ ใช้เมื่อผู้ใช้สั่งลบงาน ต้องรู้ task id ก่อน '
      '**ห้ามใช้เครื่องมือนี้ยกเลิกงานที่เพิ่งเสนอสร้างแต่ยังไม่มีในระบบจริง! ให้ตอบผู้ใช้ว่ายกเลิกให้แล้วเท่านั้น**',
  Schema.object(
    properties: {
      'id': Schema.string(description: 'ID ของงานที่ต้องการลบ (เว้นว่างได้ถ้าใช้ ids)'),
      'ids': Schema.array(
        items: Schema.string(),
        description: 'รายการ ID ของงานที่ต้องการลบพร้อมกัน (array of string)',
      ),
      'titles': Schema.array(
        items: Schema.string(),
        description: 'ชื่องานที่ต้องการลบ (array of string ตรงกับ ids) เพื่อแสดงชื่อใน UI แทน ID',
      ),
    },
    requiredProperties: const [],
  ),
);

// ─── Move Team Task ───────────────────────────────────────────────────────────
final moveTeamTaskTool = FunctionDeclaration(
  'move_team_task',
  'ย้ายงานไปยัง column อื่นโดยไม่แก้ไขข้อมูลอื่น ใช้เมื่อผู้ใช้สั่งย้ายงานระหว่างคอลัมน์ เช่น "ย้ายไป Doing" หรือ "เลื่อนไป Done" '
      'ถ้าต้องการย้ายคอลัมน์ พร้อมแก้ไขข้อมูลอื่น (เช่นติ๊กเสร็จ) ให้ใช้ update_team_task แทน',
  Schema.object(
    properties: {
      'id': Schema.string(description: 'ID ของงานที่ต้องการย้าย (ถ้าย้ายอันเดียว)'),
      'ids': Schema.array(
        items: Schema.string(),
        description: 'รายการ ID ของงานที่ต้องการย้ายพร้อมกันหลายอัน (batch move) ใช้แทน id เมื่อย้ายหลายอัน',
      ),
      'status': Schema.string(
          description: 'ชื่อคอลัมน์ปลายทาง (ต้องอิงตามชื่อจริงใน Board Context เท่านั้น)'),
    },
    requiredProperties: const ['status'],
  ),
);

// ─── Join Team Board ──────────────────────────────────────────────────────────
final joinTeamBoardTool = FunctionDeclaration(
  'join_team_board',
  'เข้าร่วมบอร์ดทีมใหม่โดยใช้ ID ที่ผู้ใช้ระบุ ใช้เมื่อผู้ใช้บอกรหัสบอร์ดหรือขอย้ายเข้าบอร์ดเพื่อน',
  Schema.object(
    properties: {
      'board_id': Schema.string(description: 'ID ของบอร์ดที่ต้องการเข้าร่วม (UUID หรือ Timestamp string)'),
    },
    requiredProperties: const ['board_id'],
  ),
);
