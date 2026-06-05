import 'package:google_generative_ai/google_generative_ai.dart';

final analyzeUploadedImageTool = FunctionDeclaration(
  'analyze_uploaded_image',
  'วิเคราะห์รูปภาพที่ผู้ใช้อัปโหลดมา เพื่อดึงข้อมูลสำคัญ เช่น วันที่ เวลา รายละเอียดงาน หรือรายชื่อบุคคล (Vision On Demand)',
  Schema.object(
    properties: {
      'url': Schema.string(description: 'URL ของรูปภาพที่ต้องการวิเคราะห์ (นำมาจาก Context ที่ระบบแจ้งไว้)'),
      'question': Schema.string(description: 'สิ่งที่คุณต้องการให้วิเคราะห์จากรูปภาพ เช่น "มีกำหนดส่งวันที่เท่าไหร่" หรือ "สรุปรายละเอียดงานทั้งหมด"'),
    },
    requiredProperties: const ['url', 'question'],
  ),
);
