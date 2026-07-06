## Phase 193: Image Text Extraction (PNG/JPEG) for Meetings & Docs

> **Architecture Mandate:** ขยาย pipeline การแกะข้อความจากไฟล์แนบเดิม (PDF→Gemini, DOCX→client) ให้รองรับการแกะข้อความจากรูปภาพ PNG/JPEG ผ่าน Gemini Vision ทั้งในหน้า Meetings และ Docs โดยเป็นการเพิ่มความสามารถแบบ Additive เท่านั้น (Risk: LOW):
> 1. เพิ่ม `extractImageText()` และ helper `_imageMimeFor()` ใน `ApiCloudflare` พร้อมเพิ่ม image branch ใน `extractAttachmentText()`
> 2. ขยาย `_isExtractableFile()` ในหน้า Meetings และ Docs ให้รองรับ .png/.jpg/.jpeg
> 3. ไม่แตะต้อง Cloudflare Worker — เป็นการแก้ไขฝั่ง Flutter client เท่านั้น และ path PDF/DOCX เดิมต้องไม่เปลี่ยนแปลง (regression-safe)

### Task 193.1: Register Phase 193 Scope in task-graph.md
- **Status:** [x] Done
- **Target Files:** `task-graph.md`
- **Action:** ลงทะเบียนขอบเขตงานและภารกิจของ Phase 193 ลงใน task-graph.md
- **Why:** เพื่อบันทึกประวัติการพัฒนาและสอดคล้องกับนโยบายสถาปัตยกรรม Sovereign
- **Verification:** **[AUTONOMOUS]** ตรวจสอบว่าโครงสร้าง task-graph.md ถูกต้องตาม 5-part schema

### Task 193.2: Implement extractImageText() + _imageMimeFor() and Image Branch in extractAttachmentText()
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/databases/api_cloudflare.dart`
- **Action:** เพิ่ม static `extractImageText(fileUrl, filename, mimeType)` ใน `ApiCloudflare`: ตรวจสอบ auth, ดาวน์โหลด bytes จาก R2 ผ่าน `http.get(EnvConfig.sanitizeUrl(url))`, ปฏิเสธรูปภาพที่ใหญ่เกิน 10MB (`10*1024*1024`) โดยคืน `''` พร้อม log `[extractImageText][Warn]`, base64-encode, ส่ง multimodal request ไปยัง `/api/ai/chat` ด้วย content type `image_url` รูปแบบ `data:$mime;base64,$b64`, model `google/gemini-3.1-flash-lite`, max_tokens 4000, timeout 30s, prompt ภาษาไทยให้แกะข้อความที่มองเห็นทั้งหมดโดยรักษาโครงสร้าง, parse `result.choices[0].message.content`, trim และ truncate เหลือ 12000 chars, คืน `''` เมื่อ fail พร้อม log `[extractImageText][Error]`. เพิ่ม helper `_imageMimeFor(lowerName, lowerMime)` คืน `'image/png'` / `'image/jpeg'` / `null` และเพิ่ม image branch ใน `extractAttachmentText()` หลัง docx branch ที่เรียก `extractImageText` เมื่อ `_imageMimeFor != null`
- **Why:** เพื่อให้ AI สามารถอ่านข้อความจากรูปภาพได้ โดยต่อยอดจาก pipeline การแกะไฟล์เดิมอย่างสอดคล้อง (Owner: backend_coder)
- **Verification:** **[AUTONOMOUS]** รัน `flutter analyze` ผ่านสำหรับไฟล์ service โดยไม่มี error ใหม่

### Task 193.3: Extend _isExtractableFile() in meetings_board_sheet.dart for PNG/JPEG
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/meetings/meetings_board_sheet.dart`
- **Action:** ขยาย `_isExtractableFile()` ให้คืน `true` สำหรับ .png/.jpg/.jpeg ผ่านช่องทาง name/url/mime (สอดคล้องกับเงื่อนไข OR ของ pdf/docx เดิม)
- **Why:** เพื่อให้หน้า Meetings ตรวจจับรูปภาพเป็นไฟล์ที่แกะข้อความได้ (Owner: frontend_coder)
- **Verification:** **[AUTONOMOUS]** รัน `flutter analyze`

### Task 193.4: Extend _isExtractableFile() in docs_board_sheet.dart for PNG/JPEG
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/docs/docs_board_sheet.dart`
- **Action:** ขยาย `_isExtractableFile()` ให้คืน `true` สำหรับ .png/.jpg/.jpeg ผ่านช่องทาง name/url/mime (สอดคล้องกับเงื่อนไข OR ของ pdf/docx เดิม)
- **Why:** เพื่อให้หน้า Docs ตรวจจับรูปภาพเป็นไฟล์ที่แกะข้อความได้ (Owner: frontend_coder)
- **Verification:** **[AUTONOMOUS]** รัน `flutter analyze`

### Task 193.5: Autonomous Verification & PDF/DOCX Regression Check
- **Status:** [x] Done
- **Target Files:** None
- **Action:** รัน `flutter analyze` และยืนยันว่าไม่มี error ใหม่ พร้อมตรวจสอบด้วย manual/grep ว่า path การแกะ PDF/DOCX เดิมยังคงอยู่ครบและไม่ถูกแก้ไข
- **Why:** รับประกันว่าฟีเจอร์ใหม่เป็นแบบ Additive และไม่ทำให้ฟังก์ชันการแกะ PDF/DOCX เดิมเกิด regression (Owner: qa/executor)
- **Verification:** **[AUTONOMOUS]** `flutter analyze` clean + grep ยืนยัน pdf/docx branches ยังคงสภาพเดิม

## Phase 192: Workspace Table Columns Reordering

### Task 192.1: Register Phase 192 Scope in task-graph.md
- **Status:** [x] Done
- **Target Files:** `task-graph.md`
- **Action:** บันทึกโครงสร้างภารกิจของ Phase 192 ลงใน task-graph.md
- **Why:** เพื่อบันทึกประวัติการพัฒนาและสอดคล้องกับนโยบายสถาปัตยกรรม Sovereign

### Task 192.2: Reorder Workspace Projects Table Columns
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/boards/widgets/projects_table.dart`
- **Action:** ปรับเปลี่ยนลำดับของคอลัมน์ในตารางโปรเจกต์ (Projects Table) ในส่วนของ header และ row ให้เป็น: Project Name (flex 3), Members (flex 2), Open Kanban (flex 3), Docs (flex 2), Meetings (flex 2), Actions (flex 1)
- **Why:** ปรับปรุงความชัดเจนและเรียงลำดับการเข้าถึงเนื้อหาที่สำคัญตาม UX
- **Verification:** **[AUTONOMOUS]** รัน `flutter analyze --no-pub` หรือ manual review โครงสร้าง

### Task 192.3: Verify and Test Projects Table Layout
- **Status:** [x] Done
- **Target Files:** None
- **Action:** ตรวจสอบการรันและหน้าตาคอลัมน์ของตารางโครงการ
- **Why:** ยืนยันความสวยงามและไม่เกิดปัญหา UI overflow หลังจัดเรียง
- **Verification:** **[AUTONOMOUS]** ตรวจสอบผ่านการ compile หรือ manual analysis

## Phase 189: Diagnostics and Command Execution Bootstrap

### Task 189.1: Verify the Environment
- **Status:** [x] Done
- **Target Files:** `task-graph.md`, `architecture.md`, `skill-instructions.md`
- **Action:** Verify existence of the three anchor files.
- **Why:** To bootstrap the Sovereign AI workflow.

### Task 189.2: Execute Terminal Command
- **Status:** [x] Done
- **Target Files:** None
- **Action:** Execute `python3 -c "print('Hello from Executor')"`
- **Why:** To verify terminal command execution capabilities.

### Task 189.3: Check stdout
- **Status:** [x] Done
- **Target Files:** None
- **Action:** Check stdout of the python execution.
- **Why:** To verify output feedback correctness.

## Phase 188: Bulk Board Member Selection UI Redesign

> **Architecture Mandate:** ปรับปรุงระบบจัดการสมาชิกบอร์ด (Manage Board Members) เพื่อให้รองรับการเลือกและเพิ่มสมาชิกบอร์ดแบบทีละหลายคน (Bulk Selection) จากสมาชิกของพื้นที่ทำงาน (Workspace) แทนการเลือกทีละคนผ่าน Dropdown:
> 1. ปรับปรุง `showManageMembersDialog` ใน `boards_dialogs.dart` ให้เปลี่ยนจากการเลือกสมาชิกผ่าน Dropdown ทีละคน ไปเป็นการเลือกแบบ Bulk Multi-select (เช่น ใช้ตาราง/รายการที่แต่ละคนมี Checkbox)
> 2. พัฒนากลไกการจัดการสถานะภายใน Dialog เพื่อบันทึกการเลือกสมาชิกหลายคนพร้อมกัน และทำการเพิ่มสมาชิกในคราวเดียวเมื่อกดปุ่มบันทึก
> 3. ปรับปรุง State Manager `state_boards.dart` หรือ API/ฟังก์ชันที่เกี่ยวข้องเพื่อรองรับการเพิ่มสมาชิกแบบเป็นชุด (Bulk Add) หรือรับประกันว่าการเพิ่มทีละหลายคนทำงานได้อย่างเสถียรและราบรื่น

### Task 188.1: Register Phase 188 Scope in task-graph.md
- **Status:** [x] Done
- **Target Files:** `task-graph.md`
- **Action:** บันทึกโครงสร้างภารกิจของ Phase 188 ลงใน task-graph.md
- **Why:** เพื่อบันทึกประวัติและสอดคล้องกับนโยบายสถาปัตยกรรม Sovereign

### Task 188.2: Redesign showManageMembersDialog UI for Multi-Selection
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/boards/widgets/boards_dialogs.dart`
- **Action:** แก้ไข Dialog จัดการสมาชิกให้แสดงรายชื่อสมาชิกใน Workspace ที่มีคุณสมบัติพร้อมจะถูกดึงเข้าบอร์ด (availableMembers) ในรูปแบบของรายการที่มี Checkbox
- **Why:** เพื่อเปลี่ยนจาก Single Selection Dropdown เป็น Multi-Selection UI ที่ใช้งานง่ายและตรงตามความต้องการผู้ใช้งาน

### Task 188.3: Implement Bulk Addition State & Logic in Dialog
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/boards/widgets/boards_dialogs.dart`
- **Action:** สร้างตัวแปรเก็บเซ็ตของ UID ที่ถูกเลือกชั่วคราว และเมื่อกดปุ่ม ADD ให้ส่งรายการ UID ทั้งหมดที่เลือกในคราวเดียวโดยทำการเรียกคำสั่งเพื่อเพิ่มสมาชิกเข้าบอร์ด
- **Why:** จัดการ State การเลือกและส่งข้อมูลไปยัง Backend/State Manager อย่างราบรื่นในครั้งเดียว

### Task 188.4: Validate and Verify Bulk Member Addition Flow
- **Status:** [x] Done
- **Target Files:** None
- **Action:** ทดสอบการเลือกสมาชิกหลายคนพร้อมกันและกดบันทึก ยืนยันว่าสมาชิกทั้งหมดได้รับการอัปเดตและแสดงผลถูกต้องใน UI บอร์ด
- **Why:** รับประกันความเสถียรและความถูกต้องของการแก้ไขสิทธิ์และการแสดงผลสมาชิกในระบบ

## Phase 187: Workspace Board Visibility & Access Authorization Fix

> **Architecture Mandate:** แก้ไขการดึงข้อมูลบอร์ด (GET /api/boards) เพื่อให้ผู้ใช้ทุกคนในทีมที่เป็นสมาชิกของพื้นที่ทำงาน (Workspace) สามารถมองเห็นบอร์ดทั้งหมดในพื้นที่ทำงานนั้นๆ ได้:
> 1. ปรับปรุง Query ในส่วนการดึงข้อมูลบอร์ดของ Cloudflare Worker Backend จากเดิมที่เช็คเฉพาะสิทธิ์ความเป็นเจ้าของบอร์ดหรือเป็นสมาชิกบอร์ดโดยตรง (`owner_uid` หรือ `members`) ให้ครอบคลุมไปถึงสิทธิ์การเข้าใช้พื้นที่ทำงาน (`workspace_id`) ที่ผู้ใช้คนนั้นเป็นเจ้าของหรือเป็นสมาชิกด้วย
> 2. พัฒนาระบบให้ทำงานร่วมกันย้อนหลังได้ (Backward Compatible) สำหรับบอร์ดที่ไม่มีความเกี่ยวข้องกับพื้นที่ทำงานใดๆ

### Task 187.1: Register Phase 187 Scope in task-graph.md
- **Status:** [x] Done
- **Target Files:** `task-graph.md`
- **Action:** ลงทะเบียนขอบเขตงานและภารกิจของ Phase 187 ใน task-graph.md
- **Why:** เพื่อบันทึกประวัติการพัฒนาและสอดคล้องกับนโยบายสถาปัตยกรรม Sovereign

### Task 187.2: Update Board Retrieval SQL Query in cloudflare_worker.js
- **Status:** [x] Done
- **Target Files:** `cloudflare_backend/cloudflare_worker.js`
- **Action:** แก้ไข `GET /api/boards` โดยปรับปรุง SQL query ให้ตรวจสอบสิทธิ์เข้าถึงบอร์ดผ่านความสัมพันธ์ของ `workspace_id` ด้วย
- **Why:** เพื่อให้สิทธิ์การมองเห็นบอร์ดถ่ายทอดจากระดับพื้นที่ทำงานไปยังผู้ใช้ปลายทางโดยอัตโนมัติ

### Task 187.3: Deploy Updated Backend Worker
- **Status:** [x] Done
- **Target Files:** None
- **Action:** ดีพลอย Cloudflare Worker Backend เวอร์ชันใหม่ขึ้นไปทำงานบน Cloudflare
- **Why:** เพื่อเปิดใช้งานการดึงข้อมูลที่แก้ไขสิทธิ์แล้วในระดับระบบจริง

### Task 187.4: Verify Board Visibility for Non-Owners
- **Status:** [x] Done
- **Target Files:** None
- **Action:** ทดสอบการดึงข้อมูลและยืนยันว่าผู้ใช้คนอื่นๆ สามารถมองเห็นบอร์ดในพื้นที่ทำงานได้ตามปกติหลังจากเข้าร่วมพื้นที่ทำงาน
- **Why:** รับประกันพฤติกรรมการใช้งานที่ถูกต้องตามสถาปัตยกรรมของแอปพลิเคชัน

## Phase 186: Split Environment Configuration Setup

> **Architecture Mandate:** แยกไฟล์กำหนดค่าสภาพแวดล้อม (Environment Configuration) เพื่อรองรับการสลับระหว่าง Local Development และ Production โดยไม่ต้องสลับแบบ Manual:
> 1. สร้าง `assets/env.development` และ `assets/env.production` ภายใต้โฟลเดอร์ `my_ai_assistant/assets/`
> 2. แก้ไขให้ `my_ai_assistant/lib/main.dart` โหลด `assets/env` เสมอในทุกแพลตฟอร์มเพื่อแก้ไขปัญหาการโหลดพาร์ทบนเว็บ
> 3. ปรับปรุง `run_local.sh` ให้สลับมาใช้คอนฟิกพัฒนาขณะทำงานแบบ Local และกู้คืนคอนฟิกโปรดักชันเมื่อปิดสคริปต์ เพื่อป้องกันการสับสนและ Git pollution

### Task 186.1: Register Phase 186 Scope in task-graph.md
- **Status:** [x] Done
- **Target Files:** `task-graph.md`
- **Action:** บันทึกโครงสร้างภารกิจของ Phase 186 ลงใน task-graph.md
- **Why:** เพื่อติดตามและตรวจสอบความคืบหน้าของเฟสตามสถาปัตยกรรม Sovereign

### Task 186.2: Create Split Env Files
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/assets/env.development`, `my_ai_assistant/assets/env.production`, `my_ai_assistant/assets/env`
- **Action:** คัดลอกและสร้างไฟล์ env.development, env.production และเซ็ตไฟล์ env หลักเป็นแบบโปรดักชัน
- **Why:** เพื่อเป็นแหล่งข้อมูลที่ถูกต้องสำหรับแต่ละสภาพแวดล้อม

### Task 186.3: Unify Web Asset Path in lib/main.dart
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/main.dart`
- **Action:** ปรับเปลี่ยนค่า `envPath` ในฟังก์ชัน `main()` ให้เป็น `assets/env` เสมอ
- **Why:** เพื่อแก้ไขความผิดพลาดของการโหลด env บน Flutter Web

### Task 186.4: Automate Environment Copying in run_local.sh
- **Status:** [x] Done
- **Target Files:** `run_local.sh`
- **Action:** เพิ่มคำสั่งการคัดลอกไฟล์ `env.development` ตอนเริ่มทำงาน และกู้คืน `env.production` เมื่อจบการทำงาน (ผ่าน `cleanup()` trap)
- **Why:** ปรับแต่งกระบวนการทำงานให้เป็นอัตโนมัติ 100% ป้องกันความเสี่ยงจากการคอมมิตค่าพัฒนา

### Task 186.5: Verify Local and Production Builds
- **Status:** [x] Done
- **Target Files:** None
- **Action:** รันและตรวจสอบระบบในพื้นที่โลคัลเพื่อทดสอบความถูกต้องของสคริปต์
- **Why:** รับประกันความมั่นคงและการกู้คืนไฟล์ 100%


## 📦 Archived Phases Index
Older phases moved to `docs/task-graph-archive/` to keep this file lean.
- [Part 1: Phase 185 → 154 (30 phases)](docs/task-graph-archive/phases-part01-185-154.md)
- [Part 2: Phase 153 → 124 (30 phases)](docs/task-graph-archive/phases-part02-153-124.md)
- [Part 3: Phase 123 → 95 (30 phases)](docs/task-graph-archive/phases-part03-123-95.md)
- [Part 4: Phase 94 → 75 (30 phases)](docs/task-graph-archive/phases-part04-94-75.md)
- [Part 5: Phase 76 → 122 (30 phases)](docs/task-graph-archive/phases-part05-76-122.md)
- [Part 6: Phase 123 → 200 (28 phases)](docs/task-graph-archive/phases-part06-123-200.md)
