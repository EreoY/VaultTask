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

final getActualImageTool = FunctionDeclaration(
  'get_actual_image',
  'ดึงข้อมูลรูปภาพจริง (Base64/URL) ของรูปภาพที่อ้างถึง เพื่อใช้ในการวิเคราะห์ด้วยตนเอง (Vision On Demand) เมื่อผู้ใช้หรือตัวคุณต้องการตรวจสอบรายละเอียดเชิงลึก',
  Schema.object(
    properties: {
      'name': Schema.string(description: 'ชื่อไฟล์รูปภาพหรือ ID ของรูปภาพที่อ้างถึง (เช่น image.png)'),
      'url': Schema.string(description: 'URL ของรูปภาพ (ถ้ามี)'),
    },
    requiredProperties: const ['name'],
  ),
);

final updateImageDescriptionTool = FunctionDeclaration(
  'update_image_description',
  'อัปเดตหรือกำหนดคำอธิบาย (AI Description) ให้กับรูปภาพที่ผู้ใช้อัปโหลดเข้ามาในแชทหรือรูปภาพในระบบ โดยคำอธิบายนี้คุณเขียนขึ้นมาเองจากการดูภาพ',
  Schema.object(
    properties: {
      'name': Schema.string(description: 'ชื่อไฟล์รูปภาพหรือ ID ของรูปภาพที่อ้างถึง'),
      'url': Schema.string(description: 'URL ของรูปภาพ (ถ้ามี)'),
      'description': Schema.string(description: 'คำอธิบายของรูปภาพภาษาไทยที่มีความถูกต้องและกระชับ (ความยาวประมาณ 1-2 ประโยค)'),
    },
    requiredProperties: const ['name', 'description'],
  ),
);
