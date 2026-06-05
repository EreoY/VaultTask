import 'package:google_generative_ai/google_generative_ai.dart';

// ─── Create Personal Task ──────────────────────────────────────────────────
final createPersonalTaskTool = FunctionDeclaration(
  'create_personal_task',
  'สร้างงานส่วนตัว บันทึกลงตารางงานของตัวเอง (ไม่เกี่ยวกับทีม) (รองรับการสร้างหลายงานพร้อมกัน)',
  Schema.object(
    properties: {
      'tasks': Schema.array(
        description: 'รายการงานที่ต้องการสร้าง',
        items: Schema.object(
          properties: {
            'title': Schema.string(description: 'ชื่องาน หรือสิ่งที่ต้องทำแบบสั้นกระชับ (ไม่ควรใส่ยาวเกินไป)'),
            'time': Schema.string(description: 'เวลาที่ต้องทำงานนี้ เป็นรูปแบบ ISO8601 string'),
            'description': Schema.string(description: 'รายละเอียดเพิ่มเติม หรือเนื้อหายาวๆ ของงาน (แนะนำให้ใส่ถ้ารายละเอียดเยอะ)'),
            'due_date': Schema.string(description: 'วันกำหนดส่ง ISO8601 (บังคับใส่ให้เหมือนกับ time เสมอ หากผู้ใช้ระบุเวลามา)'),
          },
          requiredProperties: const ['title', 'time', 'description'],
        ),
      ),
    },
    requiredProperties: const ['tasks'],
  ),
);

// ─── List Personal Tasks ───────────────────────────────────────────────────
final listPersonalTasksTool = FunctionDeclaration(
  'list_personal_tasks',
  'ดูรายการงานส่วนตัวของผู้ใช้ (ใช้ก่อน update/delete เพื่อหา id)',
  Schema.object(
    properties: {
      'timeframe': Schema.string(
          description: 'ช่วงเวลา: today, tomorrow, next_7_days, next_30_days, overdue, all (default: all)'),
      'status': Schema.string(
          description: 'กรองตามสถานะคอลัมน์ (ต้องอิงตามชื่อจริงใน Board Context) เว้นว่าง = ทั้งหมด'),
      'has_deadline': Schema.boolean(
          description: 'กรองแค่งานที่มี/ไม่มี deadline (เว้นว่าง = เอาทั้งหมด)'),
      'is_completed': Schema.boolean(
          description: 'กรองงานเสร็จแล้ว (true) หรือยังไม่เสร็จ (false) เว้นว่าง = ทั้งหมด'),
    },
    requiredProperties: const [],
  ),
);
