# Sovereign AI Operating Procedure (SOP): High-Fidelity Development V2.1

## 0. The Mandatory Infrastructure Protocol (Rule 0)
- **IF MISSING**: ต้องสร้าง `task-graph.md`, `architecture.md`, และ `skill-instructions.md` ทันที ห้ามลักไก่
- **REAL-TIME SYNC**: ติ๊ก `[x] Done` และ Re-read 3 ไฟล์หลัก **ทุกครั้งที่จบ 1 Task ย่อย** ห้ามข้าม ห้ามรวบยอด
- **PLANNED VERIFICATION**: ต้องระบุช่วงเวลาเทส (Testing Phase) ไว้ใน Task Graph ตั้งแต่แรก ห้ามเทสแค่ตอนจบ

## 1. Strategic Diagnostic Mandate (การวิเคราะห์และขออนุมัติ)
ก่อนเริ่มดำเนินการแก้ไขโค้ดทุกครั้ง AI จะต้องนำเสนอ "รายงานวิเคราะห์เชิงยุทธศาสตร์" และ **หยุดรอ (PAUSE)** จนกว่าผู้ใช้จะพิมพ์ "อนุมัติ" หรือ "ดำเนินการ":
1. **Problem Diagnosis**: วิเคราะห์ความต้องการหรือปัญหาที่ได้รับให้ชัดเจน
2. **Root Cause Analysis**: สาเหตุทางเทคนิคหรือเหตุผลที่ต้องเปลี่ยนแปลงโครงสร้าง
3. **Architectural Solution**: ยุทธศาสตร์การแก้ปัญหาที่เหมาะสมกับโครงสร้างโปรเจกต์
4. **Task Graph Proposal**: รายการ Micro-tasks ที่จะทำ (Checkbox list)

## 2. The Atomic Context Re-Sync (กฎการยึดโยงและสร้างบริบทระดับอะตอม)
*   ต้องกลับมาอ่านไฟล์ `.md` สำคัญ (`task-graph.md`, `architecture.md`, `skill-instructions.md`) และกฎใน `GEMINI.md` **ทุกครั้งที่เสร็จสิ้น 1 Checkbox (Task ย่อย)** ห้ามรวบยอดอ่านทีเดียวตอนจบเฟส
*   ต้องอัปเดตสถานะ `[x] Done` ใน `task-graph.md` ทันทีหลังจบงานย่อย 1 งาน เพื่อป้องกันความจำคลาดเคลื่อน ห้ามทำรวดเดียวตอนจบเด็ดขาด

## 3. Universal Empirical Validation (การยืนยันผลจริงแบบสากล)
การส่งมอบงานต้องมี "หลักฐานเชิงประจักษ์" โดยเลือกใช้วิธีที่เหมาะสมที่สุดกับโปรเจกต์:
- **Ecosystem Tools**: รันคำสั่งตรวจสอบที่มี (เช่น `flutter analyze`, `flutter test`, `npm test`, ฯลฯ)
- **Forensic Audit**: หากไม่มีเครื่องมืออัตโนมัติ ต้องใช้ `read_file` อ่านโค้ดกลับมาตรวจสอบ Syntax และลอจิกด้วยตา 100%

## 4. Pulse Check Notification (การรายงานสถานะทุก Turn)
ในทุกการตอบโต้ระหว่างดำเนินการ AI ต้องปิดท้ายด้วย "Status Snapshot" เสมอ:
- **[✅ DONE]**: รายการงานที่เสร็จแล้ว (ระบุไฟล์ที่แก้)
- **[⏳ NEXT]**: งานที่จะทำต่อทันที
- **[📋 REMAINING]**: รายการงานที่เหลือทั้งหมด

## 5. Requirement Decomposition (การแตกงานละเอียดสูง)
แตกงานใน `task-graph.md` ตามรูปแบบมาตรฐาน:
- **Status**: `[ ] To Do` หรือ `[x] Done`
- **Target File**: ระบุ Path ไฟล์ที่จะแก้ให้ชัดเจน
- **Action**: อธิบายสิ่งที่ต้องทำเป็นข้อๆ (Bullet points)
- **Why**: ระบุความจำเป็นทางเทคนิคหรือสถาปัตยกรรม

## 6. Anti-Bloat Mandate (กฎต้านไฟล์บวม)
- **Strict Limit**: ไฟล์ Dart หนึ่งไฟล์ห้ามเกิน **600-700 บรรทัด**
- **Proactive Extraction**: หากเห็นว่าไฟล์เริ่มใหญ่ ให้แยกไฟล์ย่อยลงในโฟลเดอร์ `widgets/` ทันที

## 7. Performance & Bandwidth Strategy
- **Delta Sync Only**: ใช้ระบบ **Surgical Update (ValueNotifier/ID-Subscription)**
- **Rich Payload Broadcast**: ส่งข้อมูลงานไปกับ WebSocket เสมอ (Zero-Round-Trip)
- **Scoped Refreshes**: ดึงข้อมูลเฉพาะจุดที่เปลี่ยน

---
**สถานะการทำงาน:** "วิเคราะห์ก่อนทำ - ซิงค์ทุกก้าว - ยืนยันด้วยผล - ส่งมอบด้วยใจ"
