## Phase 117: Calendar Reference Visual Alignment

> **Architecture Mandate:** ปรับ Calendar ให้เข้าใกล้ reference screenshot มากขึ้น โดยลด visual treatment ที่เกินจากภาพต้นฉบับ, ทำ toolbar/tab underline เป็นเส้นเต็มแถว, ไม่ย้อมสีทั้งคอลัมน์ weekend, และทำ task row เป็นรายการบางพร้อมแถบสีบอร์ด

### Task 117.1: Register Reference Alignment Scope
- **Status:** [x] Done
- **Target Files:** `task-graph.md`
- **Action:** เพิ่ม Phase 117 เพื่อแก้ visual mismatch จาก reference ล่าสุด

### Task 117.2: Match Toolbar and Weekend Visuals to Reference
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/calendar/calendar_page.dart`
- **Action:** ทำ toolbar เป็นเส้นเต็มแถว, active underline ใต้ tab, และจำกัด weekend color ไว้ที่ header/date text ไม่ใช่พื้นทั้งช่อง

### Task 117.3: Flatten Calendar Task Rows
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/calendar/calendar_page.dart`
- **Action:** ปรับ task card ให้เป็น row เทาเข้มบาง ๆ พร้อมแถบสีบอร์ดและ workspace label แบบไม่หนาเกินภาพต้นฉบับ

### Task 117.4: Verify Analyzer and Visual Audit
- **Status:** [x] Done
- **Action:** รัน format/analyze และ audit ว่า task click ยังเปิด preview ก่อน ส่วน visual state ตรง requirement ล่าสุด

---

## Phase 116: Calendar Preview and Workspace Detail Correction

> **Architecture Mandate:** ปรับ Calendar ตาม feedback หลังตรวจ UI จริง โดยแก้เส้นใต้ Month/Day ให้เหมือน tab bar, ทำ weekend styling ให้ตรงคอลัมน์ใน grid, เปลี่ยนการกด task ใน month view ให้เปิดรายละเอียดก่อนแทนการเด้งบอร์ดทันที, และแสดง workspace source บน card/preview

### Task 116.1: Register Preview Correction Scope
- **Status:** [x] Done
- **Target Files:** `task-graph.md`
- **Action:** เพิ่ม Phase 116 เพื่อควบคุม correction รอบใหม่ของ Calendar

### Task 116.2: Fix Calendar Tab Underline and Weekend Mapping
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/calendar/calendar_page.dart`
- **Action:** ปรับ Month/Day underline ให้เป็นเส้นใต้ tab จริง และผูก weekend สีตามคอลัมน์ SAT/SUN

### Task 116.3: Restore Task Preview Before Board Navigation
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/calendar/calendar_page.dart`
- **Action:** กด task ใน month view แล้วเปิดรายละเอียดก่อน พร้อมปุ่ม navigate ไปบอร์ดใน modal

### Task 116.4: Surface Workspace Source in Calendar Cards and Preview
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/calendar/calendar_page.dart`, `my_ai_assistant/lib/ui/calendar/widgets/daily_timeline_view.dart`
- **Action:** แสดงชื่อ workspace ของ board ต้นทางใน task card และ preview metadata

### Task 116.5: Verify Analyzer and Calendar Audit
- **Status:** [x] Done
- **Action:** รัน format/analyze และ audit path ว่า task click เปิด preview ก่อน, workspace label แสดงได้, และ navigation ไปบอร์ดเกิดจากปุ่มใน preview

---

## Phase 115: Calendar Usability & Navigation Regression Fix

> **Architecture Mandate:** แก้ regression หลัง Calendar redesign ได้แก่ month view เลื่อนดูสัปดาห์ล่างไม่ได้, weekend ไม่แยกสี, task card ต้องใช้สีบอร์ดชัดเจน, Month/Day toggle ต้องมี underline แบบ tab, การกด task ไปบอร์ดต้องไม่ล้าง selected board, และต้องลดการเด้งกลับ Dashboard จาก selected board ถูก clear ระหว่าง refresh board state

### Task 115.1: Register Calendar Regression Fix Scope
- **Status:** [x] Done
- **Target Files:** `task-graph.md`
- **Action:** เพิ่ม Phase 115 เพื่อควบคุม bugfix หลัง redesign

### Task 115.2: Restore Month Scrolling, Weekend Styling, and Board-Colored Tasks
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/calendar/calendar_page.dart`
- **Action:** เปิด scroll month grid, ทำ Saturday/Sunday เป็นสีแยก, และปรับ task row ให้ใช้สีของบอร์ดเป็น chip/background ชัดขึ้น

### Task 115.3: Fix Board Navigation from Calendar Tasks
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/main.dart`, `my_ai_assistant/lib/ui/calendar/widgets/daily_timeline_view.dart`
- **Action:** ป้องกัน `onNavigate(1)` ล้าง selected board และแก้ lookup board จาก task ให้ไม่ fallback ไปบอร์ดแรกผิด ๆ

### Task 115.4: Stabilize Selected Board During Refresh
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/state_managers/state_boards.dart`
- **Action:** ไม่ clear selected board เมื่อ refresh boards ล้มเหลวหรือได้ list ว่างชั่วคราว เพื่อลดอาการเด้งกลับ Dashboard/Kanban หลุด

### Task 115.5: Verify Analyzer and Audit Regression Paths
- **Status:** [x] Done
- **Action:** รัน format/analyze และ audit keyword/flow สำหรับ Calendar scroll, board navigation, selected board refresh

---

## Phase 114: Read-Only Clean Calendar Redesign

> **Architecture Mandate:** ปรับหน้า Calendar ให้เป็น read-only temporal view ที่สะอาดขึ้นตาม reference โดยเหลือเฉพาะ 2 โหมดคือ Month และ Day, ลบ path การเพิ่ม task จาก Calendar, และคง data rule เดิมที่แสดงเฉพาะงานของผู้ใช้ปัจจุบันที่ยังไม่เสร็จ

### Task 114.1: Register Calendar Redesign Scope
- **Status:** [x] Done
- **Target Files:** `task-graph.md`
- **Action:** เพิ่ม Phase 114 เพื่อควบคุมงาน redesign Calendar แบบ read-only

### Task 114.2: Remove Calendar Task Creation Entry
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/calendar/calendar_page.dart`
- **Action:** ลบปุ่ม/handler/import ที่เปิด `TaskEditModal` จากหน้า Calendar เพื่อให้หน้านี้ใช้ดูข้อมูลเท่านั้น

### Task 114.3: Rebuild Clean Month and Day Chrome
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/calendar/calendar_page.dart`
- **Action:** ปรับ header, toolbar, month grid และ view switcher ให้ clean แบบ reference โดยเหลือ Month/Day เท่านั้น

### Task 114.4: Verify Calendar Read-Only Flow
- **Status:** [x] Done
- **Action:** รัน format/analyze และ audit ว่า Calendar ไม่มี add-task entry เหลืออยู่

---

## Phase 113: Cross-Tab Comment Read Refresh

> **Architecture Mandate:** แก้ปัญหา Dashboard แสดงคอมเมนต์ยังไม่อ่านหลังผู้ใช้กดอ่านจาก browser tab อื่น โดยบังคับ refresh read-comment state จาก D1 เมื่อกลับเข้า Dashboard หรือเมื่อ browser window ได้ focus กลับมา โดยไม่ต้อง refresh ทั้งหน้า

### Task 113.1: Add Force Refresh for Read Comment IDs
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/state_managers/state_tasks.dart`
- **Action:** เพิ่ม public method สำหรับ force refresh `readCommentIds` จาก D1 และ notify UI เฉพาะเมื่อค่ามีการเปลี่ยนแปลง

### Task 113.2: Refresh Reads on Dashboard Entry and Window Focus
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/main.dart`
- **Action:** เรียก refresh read-comments เมื่อเลือก Dashboard และเมื่อ Web browser tab/window ได้ focus กลับมา

### Task 113.3: Verify Analyzer and Audit Flow
- **Status:** [x] Done
- **Action:** รัน `flutter analyze` และ audit path ว่า Dashboard จะได้รับ read state ใหม่โดยไม่ต้อง reload

---

## Phase 112: Analyzer Gate, Comment Read Audit & Lazy Page Feed

> **Architecture Mandate:** ทำให้ `flutter analyze` ผ่านเป็น quality gate, ตรวจยืนยันระบบอ่านคอมเมนต์ว่าผูกสถานะอ่านกับผู้ใช้รายคนแบบประหยัดพื้นที่, และปรับข้อมูลหน้า Dashboard/Calendar/Kanban ให้โหลดตามหน้าที่ผู้ใช้เข้าใช้งานจริงแทนการโหลด task ทุกบอร์ดตั้งแต่เริ่มแอป

### Task 112.1: Register Analyzer & Lazy Feed Scope
- **Status:** [x] Done
- **Target Files:** `task-graph.md`
- **Action:** เพิ่ม Phase 112 เพื่อควบคุมงานแก้ analyzer, audit comment read, และ lazy feed ต่อหน้า

### Task 112.2: Make Flutter Analyze Pass
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/analysis_options.yaml`, `my_ai_assistant/lib/**`, `my_ai_assistant/test/**`
- **Action:** แก้หรือจัดการ analyzer warnings/lints ที่ทำให้ `flutter analyze` exit 1 โดยไม่เปลี่ยน behavior ธุรกิจ

### Task 112.3: Audit Comment Read Persistence
- **Status:** [x] Done
- **Target Files:** `cloudflare_backend/d1_schema.sql`, `cloudflare_backend/cloudflare_worker.js`, `my_ai_assistant/lib/state_managers/state_tasks.dart`, `my_ai_assistant/lib/ui/dashboard/dashboard_page.dart`
- **Action:** ยืนยันว่า read state ของคอมเมนต์เก็บต่อ user และ Dashboard ใช้ข้อมูลนี้ตัดสิน unread/read

### Task 112.4: Implement Lazy Page Feed
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/main.dart`, `my_ai_assistant/lib/ui/dashboard/dashboard_page.dart`, `my_ai_assistant/lib/ui/calendar/calendar_page.dart`, `my_ai_assistant/lib/state_managers/state_tasks.dart`
- **Action:** เปลี่ยนจากโหลด task ทุกบอร์ดตอนเริ่มแอปเป็นโหลดข้อมูลตามหน้าที่ถูกเปิด และ cache เพื่อไม่โหลดซ้ำโดยไม่จำเป็น

### Task 112.5: Verify Analyzer & Data Flow
- **Status:** [x] Done
- **Action:** รัน `flutter analyze`, audit จุด comment read และ lazy fetch เพื่อยืนยันว่า behavior ตรงตาม requirement

---

## Phase 111: Navigation Load Stabilization & Flicker Reduction

> **Architecture Mandate:** ลดอาการหน้าจอกระพริบและโหลดไม่ทันเมื่อสลับหน้าเร็วๆ โดยรวมศูนย์การโหลดข้อมูลเริ่มต้นให้อยู่ที่ AppShell, ยกเลิก duplicated fetch จากหน้าใน IndexedStack, ทำ silent task fetch ให้ไม่ยิง global rebuild ระหว่าง batch, และบีบขอบเขต Provider watch ให้สอดคล้องกับ Delta Performance Mandate

### Task 111.1: Register Navigation Fetch Ownership Plan
- **Status:** [x] Done
- **Target Files:** `task-graph.md`
- **Action:** เพิ่ม Phase 111 พร้อม micro-tasks และ testing phase ก่อนเริ่มแก้โค้ดจริง

### Task 111.2: Centralize Initial Fetch in AppShell
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/main.dart`, `my_ai_assistant/lib/ui/dashboard/dashboard_page.dart`, `my_ai_assistant/lib/ui/calendar/calendar_page.dart`, `my_ai_assistant/lib/ui/boards/boards_page.dart`
- **Action:** รวมการโหลดข้อมูลหลักไว้ที่ `AppShell` และลบ duplicated startup fetch จากหน้าที่ถูกสร้างใน `IndexedStack`

### Task 111.3: Make Silent Task Fetch Truly Silent
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/state_managers/state_tasks.dart`
- **Action:** ปรับ `fetchTasksForBoard(silent: true)` ไม่ให้ `notifyListeners()` ท้ายทุกบอร์ดระหว่าง batch fetch เพื่อลด rebuild storm

### Task 111.4: Scope Heavy Provider Watchers
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/main.dart`, `my_ai_assistant/lib/ui/common/aether_side_nav.dart`, `my_ai_assistant/lib/ui/calendar/calendar_page.dart`
- **Action:** ใช้ `context.select`/`Selector` เฉพาะค่าที่จำเป็น ลดการ rebuild ของ shell/navigation/calendar ทั้งหน้าเมื่อ state อื่นเปลี่ยน

### Task 111.5: Tune Navigation Transition Boundary
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/main.dart`
- **Action:** จำกัด `AnimatedSwitcher` ให้ทำงานเฉพาะการเข้า/ออก Kanban board และไม่ cross-fade `IndexedStack` ระหว่างสลับ tab ปกติ

### Task 111.6: Verify Navigation Stability
- **Status:** [x] Done
- **Action:** รัน `flutter analyze` และ forensic audit จุด fetch/rebuild เพื่อยืนยันว่าไม่มี duplicated startup fetch และไม่มี syntax regression

---

## Phase 110: AI Chat UI Sync Optimization & Reactivity Hardening

> **Architecture Mandate:** ปรับปรุงการซิงค์ข้อมูลรูปภาพและคำบรรยาย AI ในหน้าแชทหลักให้สะท้อนบน UI ทันทีโดยไม่มีดีเลย์ (Reactivity Hardening) ผ่านการแปลง Message List Selector ให้ดึงค่า Signature ที่ครบถ้วน, ตรวจสุขภาพการทำ message sanitization ป้องกันข้อมูลสำคัญสูญหาย, และอัปเกรด CollapsibleDescription ให้ตอบสนองทันทีแบบ Auto-expand

### Task 110.1: Optimize Message List Selector
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/chat/widgets/aether_chat_view.dart`
- **Action:** เปลี่ยน Selector ใน _MessageList ให้ทำงานแบบ Signature-based เปรียบเทียบครอบคลุม attachments, text, id และ isTyping ของทุกข้อความ

### Task 110.2: Safely Sanitize Messages
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/state_managers/state_chat.dart`
- **Action:** แก้ไข _sanitizeLoadedMessages ให้ใช้ m.copyWith ในการล้าง base64 รูปภาพแนบเพื่อไม่ให้ทำฟิลด์ draft และอื่นๆ ตกหล่นสูญหาย

### Task 110.3: Collapsible Description Auto-Expansion
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/chat/widgets/chat_bubbles.dart`
- **Action:** แก้ไข CollapsibleDescription ให้กางคำอธิบายออกทันทีที่อัปเดตข้อมูลเสร็จสิ้น

### Task 110.4: Verify & Audit Compilation
- **Status:** [x] Done
- **Action:** รันตรวจความผิดพลาดการคอมไพล์และทดสอบระบบ E2E ในแอปจริง

---

## Phase 109: OpenRouter Native Integration & D1 Persistence OVERHAUL

> **Architecture Mandate:** ยกเลิก Custom Retry Loop ใน Cloudflare Worker เพื่อกลับไปพึ่งพาระบบ Native Auto-Routing ของ OpenRouter เต็มตัวเพื่อฟื้นฟูความเร็วในการตอบสนอง (Latency) ในเทิร์นการเรียกใช้งานครั้งแรก พร้อมทั้งเชื่อมระบบ D1 SQLite writeback สำหรับผู้ช่วย และทำความสะอาด Log ในฝั่งเซิร์ฟเวอร์ให้อ่านง่ายเป็นบล็อกสำคัญ

### Task 109.1: Remove Retry Loop & Simplify Fetch to OpenRouter
- **Status:** [x] Done
- **Target Files:** `cloudflare_backend/cloudflare_worker.js`
- **Action:** ลบ `while(attempts < maxAttempts)`, `ignoredProviders` และเงื่อนไข ignore ทั้งหมด ให้เหลือเพียงการยิง fetch ไปยัง OpenRouter รอบเดียวตรงๆ

### Task 109.2: Complete D1 Persistence for Assistant Response
- **Status:** [x] Done
- **Target Files:** `cloudflare_backend/cloudflare_worker.js`
- **Action:** ในฝั่ง Worker หากได้รับการตอบกลับที่สำเร็จและไม่ใช่ stream ให้แปลงและบันทึกข้อความหรือ tool calls ของผู้ช่วยลงฐานข้อมูล D1 SQLite `chat_messages` ทันทีด้วย `INSERT OR REPLACE` เพื่อรองรับกรณี Client รีเฟรชหน้าระหว่างการสตรีมหรือหลังตอบเสร็จ

### Task 109.3: Simplify Server Log Blocks (High-Impact Logging)
- **Status:** [x] Done
- **Target Files:** `cloudflare_backend/cloudflare_worker.js`
- **Action:** แทนที่การพิมพ์ raw JSON ที่ยาวเหยียดด้วยล็อกข้อมูลแบบสรุป แสดงภาพรวมการคุย (พิกัดแชท, รูปภาพที่พบ, โทเค็นที่ใช้, ค่าใช้จ่ายโดยประมาณเป็น USD และรหัสตอบกลับ)

### Task 109.4: Forensic Audit & End-to-End Verification
- **Status:** [x] Done
- **Action:** สั่งรันและทดสอบส่งข้อความแชทและอัปโหลดรูปภาพเพื่อยืนยันความเร็วในการตอบสนอง ข้อมูลลงฐานข้อมูลครบถ้วน และ Log คลีนสวยงาม

---

## Phase 108: Single Agent Image Description Pipeline & Collapsible UI

> **Architecture Mandate:** ปรับปรุงการจัดการรูปภาพแนบในประวัติแชทให้ประมวลผลผ่าน Agent เพียงตัวเดียว (Single Agent Execution) โดยตัวหลักจะวิเคราะห์ภาพแล้วเรียกใช้เครื่องมือ `update_image_description` เพื่อทำการบันทึกและพยากรณ์ข้อมูลในเทิร์นเดียวกันโดยไม่มีกระบวนการเรียกซ้ำซ้อนในพื้นหลัง พร้อมทั้งปรับแต่งหน้าตาคำอธิบายภาพในแชทให้ซ่อนอยู่ใน Widget Dropdown พับเก็บได้เพื่อลดความรกรุงรังของหน้าจอ

### Task 108.1: Define and register updateImageDescriptionTool
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ai_agent/tools/definitions/vision_defs.dart`, `my_ai_assistant/lib/ai_agent/tools/registry.dart`
- **Action:** เพิ่มคำนิยามและการลงทะเบียนของเครื่องมือ `update_image_description` สำหรับการเซฟคำบรรยายของภาพโดยตรง

### Task 108.2: Implement update_image_description execution handler
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ai_agent/core/misty_agent.dart`
- **Action:** เพิ่มฟังก์ชันในการจับคู่ Tool และส่งพารามิเตอร์ของรูปภาพกับคำบรรยายที่ Agent สร้างเองไปยังคอลแบ็ก `onUpdateImageDescription`

### Task 108.3: Remove parallel background image description task
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/state_managers/state_chat.dart`
- **Action:** ลบเมธอด `_generateChatImageDescriptionInBackground` และจุดเรียกใช้งานทั้งหมดออกไปอย่างถาวร

### Task 108.4: Update system rules in skill_vision.dart
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ai_agent/skills/skill_vision.dart`
- **Action:** เพิ่มกฎการทำงานของ Skill Vision เพื่อให้ Agent เรียกใช้เครื่องมือบันทึกคำอธิบายรูปภาพเสมอเมื่ออัปโหลดภาพครั้งแรก

### Task 108.5: Build CollapsibleDescription widget in chat bubbles
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/chat/widgets/chat_bubbles.dart`
- **Action:** สร้าง Widget ตัวใหม่เพื่อเก็บเนื้อหาคำบรรยายภาพพับได้ และแสดงเฉพาะชื่อภาพเป็นหลักในประวัติแชท

### Task 108.6: Validate compilation with flutter analyze
- **Status:** [x] Done
- **Action:** ตรวจสอบความถูกต้องและทดสอบระบบในแอปพลิเคชันจริง

---

## Phase 107: Resolve 500 Chat Message Errors & Strip Base64 on Save

> **Architecture Mandate:** ป้องกันการเกิดข้อผิดพลาด D1_ERROR (SQLITE_TOOBIG) / 500 Internal Server Error เมื่อทำการบันทึกข้อความแชทที่มีภาพแนบขนาดใหญ่ โดยการกรอง (strip) ฟิลด์ `b64` ออกจากอาร์เรย์ `attachments` ก่อนจะส่งไปบันทึกยัง Cloudflare D1 Database และ Local SQLite Database โดยในหน้าระดับ Memory จะยังคงมีข้อมูล base64 เพื่อใช้ในการแสดงผลและส่ง AI ในรอบแรกได้อย่างราบรื่น

### Task 107.1: Strip b64 field in ApiCloudflare.insertChatMessage
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/databases/api_cloudflare.dart`
- **Action:** กรองฟิลด์ `b64` ออกจาก `attachments` แต่ละตัว ก่อนทำการส่ง POST ไปยัง Cloudflare `/api/chat/messages`

### Task 107.2: Strip b64 field in LocalSqlite.insertChatMessage
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/databases/db_personal_sqlite.dart`
- **Action:** กรองฟิลด์ `b64` ออกจาก `attachments` แต่ละตัว ก่อนบันทึกเข้าสู่ local SQLite database

### Task 107.3: Verify using Node Integration Test Script
- **Status:** [x] Done
- **Action:** ทดสอบยิง payload รูปภาพขนาดใหญ่ (>3MB) ไปยัง API เพื่อตรวจสอบว่าการขจัด base64 ป้องกัน error SQLITE_TOOBIG สำเร็จ

### Task 107.4: Verify in Browser & Compile Integrity
- **Status:** [x] Done
- **Action:** ตรวจสอบด้วย `flutter analyze` และทดลองอัปโหลดรูปภาพผ่าน UI ให้ AI วิเคราะห์ว่าไม่เกิด 500 Internal Server Error อีกต่อไป

---

## Phase 106: Non-blocking Task Image Uploads & Chat Media Visual Cache Sync

> **Architecture Mandate:** แยก name และ aiDescription ออกจากกันใน TaskImage, ทำขั้นตอนคำนวณคำอธิบายรูปภาพผ่าน AI ให้เป็นแบบ Non-blocking (Asynchronous Background Generation) ทั้งใน Task Modal และหน้าแชทหลัก โดยประวัติแชทจะเห็นภาพทันที และใช้คำอธิบายในการคุยรอบถัดไปเพื่อประหยัด Token

### Task 106.1: Add name Field to TaskImage Model
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/models/task_model.dart`
- **Action:** เพิ่มฟิลด์ `name` เพื่อแยกชื่อไฟล์ภาพออกมาจาก `aiDescription` โดยยังรักษาระบบ JSON serialization แบบย้อนกลับได้ (backwards-compatible)

### Task 106.2: Refactor Task Modal Image Upload to Non-blocking
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/kanban/widgets/task_edit_modal.dart`
- **Action:** ย้ายการเรียก AI Description ไปทำงานใน Background, อัปเดตรูปภาพขึ้น UI และสั่ง Auto-save ทันทีเมื่ออัปโหลด R2 เสร็จสิ้น, ปรับปรุง TextField แสดงชื่อไฟล์และ Subtitle คำอธิบายภาพ

### Task 106.3: Refactor Chat Page Image Upload to Non-blocking & Separate Layout
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/state_managers/state_chat.dart`, `my_ai_assistant/lib/ui/chat/widgets/chat_bubbles.dart`
- **Action:** อัปโหลด R2 แล้วส่งข้อความพร้อม base64 ไปหา AI ทันทีในเทิร์นแรกโดยไม่ต้องรอคิว AI Description, ย้าย AI Description ไปทำงานใน Background และทำการอัปเดตประวัติแชท/ฐานข้อมูลพร้อมรีซิงก์ประวัติประมวลผลของโมเดลเมื่อคำอธิบายถูกสร้างเสร็จ, ปรับปรุงดีไซน์ประวัติแชทให้แยกชื่อภาพและคำอธิบายอย่างสวยงาม

### Task 106.4: Validate Code Compiler Integrity
- **Status:** [x] Done
- **Action:** ตรวจสอบด้วย `flutter analyze` และสั่งรัน unit test `test_image_flow.dart` สำเร็จครบถ้วน 100%

---

## Phase 105: Chat Image Upload — R2-First Blocking Pattern & Code Cleanup

> **Architecture Mandate:** Refactor chat image upload ให้เป็น blocking R2-first pattern เหมือน Kanban, ลบ split Phase 1/Phase 2 flow ที่รกและมี bug

### Task 105.1: Fix _handleSend for File-Only Sends
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/chat/widgets/aether_chat_view.dart`
- **Action:** แก้ `_handleSend` ให้ส่งได้แม้ text ว่างแต่มีไฟล์แนบ

### Task 105.2: Refactor sendMessageToAI — R2-First Blocking Upload
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/state_managers/state_chat.dart`
- **Action:** Refactor จาก ~210 บรรทัด → ~110 บรรทัด: Upload R2 ก่อน (blocking) → สร้าง message ครั้งเดียวด้วย URL จริง → ส่ง AI / fail → แจ้งเตือนทันที

### Task 105.3: Remove Hardcoded CORS-Blocked Avatar URL
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/chat/widgets/chat_widgets.dart`
- **Action:** ลบ hardcoded Google avatar URL ที่ CORS block เปลี่ยนเป็น emoji icon

### Task 105.4: Verify with flutter analyze
- **Status:** [x] Done
- **Action:** `flutter analyze` — 0 errors, 0 new warnings

---

## Phase 104: Critical Performance Fix — Timer Rebuild Loop, Base64 Cache, Unmounted Context

> **Workflow Mandate:** อัปเดต Task Graph และ Re-Sync ทุกครั้งที่จบ 1 Task ย่อย (Rule 0 & V2.1 Protocol)
> **Architecture Mandate:** แก้ไขปัญหาแอปค้างทุกหน้า เกิดจาก Timer.periodic(1s) + IndexedStack rebuild ทั้ง widget tree ทุกวินาที, base64Decode sync ใน build(), และ unmounted context access

### Task 104.1: Replace Timer.periodic with Scoped StreamBuilders
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/calendar/widgets/daily_timeline_view.dart`
- **Action:** ลบ `Timer.periodic(1s)` ที่ rebuild ทั้ง CalendarPage ทุกวินาที เปลี่ยนเป็น `StreamBuilder` เฉพาะ clock text (1s) และ minute indicator (10s) เท่านั้น

### Task 104.2: Cache base64Decode in Chat Bubbles
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/chat/widgets/chat_bubbles.dart`
- **Action:** เพิ่ม `static _b64Cache` cache สำหรับ `base64Decode` ป้องกัน decode ซ้ำทุก build + skip Image.network เมื่อ URL ว่าง/error

### Task 104.3: Fix Unmounted Context in CalendarPage
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/calendar/calendar_page.dart`
- **Action:** เพิ่ม `if (!mounted) return;` หลัง `await boardState.fetchAllBoards()` ก่อนเข้าถึง `context`

### Task 104.4: Verify with flutter analyze
- **Status:** [x] Done
- **Action:** `flutter analyze` — 0 errors, 0 new warnings

---

## Phase 103: Bypass Image Spinner, Handle Failed/Empty URLs, and History Context Cleanup

> **Workflow Mandate:** อัปเดต Task Graph และ Re-Sync ทุกครั้งที่จบ 1 Task ย่อย (Rule 0 & V2.1 Protocol)
> **Architecture Mandate:** ยกเลิกการแสดง Spinner (CircularProgressIndicator) ในหน้าแชทเมื่อรูปภาพไม่มี URL (ให้แสดงสถานะ Failed ทันที) และกรองรูปภาพที่ล้มเหลวออกจากการแปลงประวัติแชทเพื่อป้องกันการส่ง Base64 ซ้ำซ้อนไปยังโมเดล AI

### Task 103.1: Update Chat Bubble States to Bypass Spinner
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/chat/widgets/chat_bubbles.dart`
- **Action:** เปลี่ยนเงื่อนไข `isFailed` เป็น `url == 'error' || url.isEmpty` และลบเงื่อนไข `isUploading` พร้อมตัวหมุน CircularProgressIndicator ทั้งหมดออก

### Task 103.2: Filter out Failed/Empty Attachments in History Conversion
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/state_managers/state_chat.dart`
- **Action:** อัปเดตฟังก์ชัน `_convertMessagesToAgentHistory` ข้ามภาพที่มี `url == 'error'` หรือ `url.isEmpty` เพื่อไม่ให้ Base64 ไปค้างในบริบทแชทถัดไป

### Task 103.3: Verify via Tests & Flutter Analyze
- **Status:** [x] Done
- **Action:** ตรวจสอบความถูกต้องด้วยคำสั่ง `flutter test test/test_image_flow.dart` และ `flutter analyze`

---

## Phase 102: AI Image Description Cache, Token Optimization, and Vision Tools

> **Workflow Mandate:** อัปเดต Task Graph และ Re-Sync ทุกครั้งที่จบ 1 Task ย่อย (Rule 0 & V2.1 Protocol)
> **Architecture Mandate:** สร้างคำอธิบายรูปภาพอัตโนมัติเมื่ออัปโหลด, บันทึก metadata คำอธิบายเพื่อทำ cache ประหยัด token, สลับมาใช้คำอธิบายแทน base64 ใน turn ถัดๆ ไป, และสร้างเครื่องมือให้ agent ดึงภาพจริงเมื่อต้องการ

### Task 102.1: Define and Register Vision Agent Tools
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ai_agent/tools/definitions/vision_defs.dart`, `my_ai_assistant/lib/ai_agent/tools/registry.dart`
- **Action:** กำหนดและลงทะเบียนเครื่องมือ get_actual_image และ regenerate_image_description

### Task 102.2: Add AI Description Generation on Chat Image Upload
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/state_managers/state_chat.dart`
- **Action:** เรียกใช้ generateAiDescription ตอนอัปโหลดรูปภาพใน sendMessageToAI และเก็บลง 'description' ใน attachments

### Task 102.3: Add AI Description Generation on Kanban Image Upload
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/kanban/widgets/task_edit_modal.dart`
- **Action:** เรียกใช้ generateAiDescription ตอนอัปโหลดรูปภาพใน _pickAndUploadImage และเซฟเข้า aiDescription ของ TaskImage

### Task 102.4: Optimize Chat History Token Consumption
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/state_managers/state_chat.dart`
- **Action:** ใน _convertMessagesToAgentHistory ปรับให้ใช้ text description แทน base64 image_url block ใน turn ย้อนหลัง

### Task 102.5: Implement State Callbacks for MistyAgent
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/state_managers/state_chat.dart`, `my_ai_assistant/lib/state_managers/state_tasks.dart`
- **Action:** นิยามและส่ง callback สำหรับดึง base64 (onGetImageB64) และอัปเดตคำอธิบายรูปภาพ (onUpdateImageDescription) รวมถึง sync ลง Kanban

### Task 102.6: Handle New Tool Execution in MistyAgent
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ai_agent/core/misty_agent.dart`
- **Action:** ประมวลผล get_actual_image และ regenerate_image_description ใน MistyAgent โดยแทรก multimodal user message เมื่อดึงรูปจริง

### Task 102.7: E2E Verification & Flutter Analyze
- **Status:** [x] Done
- **Action:** รัน flutter analyze และรันเครื่องเพื่อทดสอบฟังก์ชันการวิเคราะห์รูปภาพ

---

## Phase 101: Fix AI Chat Image Attachments & OpenRouter Delivery

> **Workflow Mandate:** อัปเดต Task Graph และ Re-Sync ทุกครั้งที่จบ 1 Task ย่อย (Rule 0 & V2.1 Protocol)
> **Architecture Mandate:** ปรับปรุงความสามารถในการพรีวิวรูปภาพก่อนส่ง, อัปเดตข้อมูลไฟล์แนบเข้าตารางแชท และลบ tool_calls จากประวัติการแชทก่อนเรียกใช้งาน OpenRouter API

### Task 101.1: Update D1 Chat Messages Mutation to INSERT OR REPLACE
- **Status:** [x] Done
- **Target Files:** `cloudflare_backend/cloudflare_worker.js`
- **Action:** เปลี่ยน INSERT INTO เป็น INSERT OR REPLACE INTO สำหรับ Endpoint บันทึกข้อความแชท

### Task 101.2: Refactor Chat Input File Chips to Support PlatformFile Previews
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/chat/widgets/chat_input.dart`
- **Action:** เปลี่ยนประเภทพารามิเตอร์ pendingFiles เป็น List<PlatformFile> และใช้ Image.memory / Image.file เพื่อแสดงพรีวิวภาพ

### Task 101.3: Refactor StateChat Properties and Stream Mapping
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/state_managers/state_chat.dart`
- **Action:** อัปเดต pendingFileMaps ให้ส่งคืน List<PlatformFile> ตรงๆ เพื่อรักษา bytes/path

### Task 101.4: Update User Message attachments post R2 Upload
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/state_managers/state_chat.dart`
- **Action:** แทนที่ attachments ของ userMsg ด้วย R2 URL และ Base64 และบันทึกลง D1 ฐานข้อมูลหลังจากอัปโหลดเสร็จสิ้น

### Task 101.5: Strip tool_calls from history for OpenRouter payload compatibility
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/state_managers/state_chat.dart`
- **Action:** ล้างข้อมูล tool_calls ออกจากประวัติผู้ช่วย (assistant) ใน _convertMessagesToAgentHistory

### Task 101.6: E2E Verification & Flutter Analyze
- **Status:** [x] Done
- **Action:** รันตรวจไวยากรณ์ด้วย flutter analyze และเปิดรันเครื่องเพื่อทดสอบ E2E

---

## Phase 100: Web File Picker Gesture Fix & Stale Process Cleanup

> **Workflow Mandate:** อัปเดต Task Graph และ Re-Sync ทุกครั้งที่จบ 1 Task ย่อย (Rule 0 & V2.1 Protocol)
> **Architecture Mandate:** ย้าย FilePicker.pickFiles() จาก StateChat (async ChangeNotifier) ไปเรียกตรงใน UI gesture callback เพื่อไม่ให้ browser block dialog, พร้อมเพิ่ม cleanup stale processes ใน run_local.sh

### Task 100.1: Add addPendingFiles() to StateChat
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/state_managers/state_chat.dart`
- **Action:** แทนที่ `pickFiles()` ด้วย `addPendingFiles(List<PlatformFile>)` ที่รับไฟล์จาก UI layer

### Task 100.2: Refactor AetherChatInput to call FilePicker directly
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/chat/widgets/chat_input.dart`
- **Action:** เปลี่ยน `onPickFile` เป็น `onFilesPicked`, เรียก `FilePicker.pickFiles()` ตรงใน `onTap` gesture

### Task 100.3: Wire onFilesPicked in AetherChatView
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/chat/widgets/aether_chat_view.dart`
- **Action:** อัปเดต callback เป็น `onFilesPicked` → `chatState.addPendingFiles(files)`

### Task 100.4: Remove debug print spam
- **Status:** [x] Done
- **Target Files:** `chat_input.dart`, `aether_chat_view.dart`
- **Action:** ลบ debugPrint จาก selector, builder, และ build method

### Task 100.5: Add stale process cleanup to run_local.sh
- **Status:** [x] Done
- **Target Files:** `run_local.sh`
- **Action:** เพิ่ม `pkill -f "wrangler dev"` และ `pkill -f "miniflare"` ก่อนเริ่ม backend

### Task 100.6: Verify with flutter analyze
- **Status:** [x] Done
- **Action:** รัน `flutter analyze` → 0 errors, 489 info/warnings (pre-existing withOpacity deprecations)

---

## Phase 97: Strict D1-based Chat Channel Separation & Sidebar UX

> **Workflow Mandate:** อัปเดต Task Graph และ Re-Sync ทุกครั้งที่จบ 1 Task ย่อย (Rule 0 & V2.1 Protocol)
> **Architecture Mandate:** ปรับปรุงและบันทึกข้อมูลการสนทนา AI ขึ้น Cloudflare D1 แทน Local SQLite พร้อมพัฒนาสตรีมข้อความแยกและแยกการนำความจำไปใช้แบบอิสระใน StateChat เพื่อแยกความจำ AI สองฝั่ง 100% และปิด Sidebar อัตโนมัติ

### Task 97.1: Add Chat Tables to D1 SQL Schema
- **Status:** [x] Done
- **Target Files:**
    - `cloudflare_backend/d1_schema.sql`
- **Action:** เพิ่มคำสั่งสร้างตาราง `chat_sessions` และ `chat_messages` ใน Schema
- **Why:** เพื่อเพิ่มตารางในฐานข้อมูลส่วนกลางสำหรับรองรับประวัติแชท

### Task 97.2: Implement Chat REST API Endpoints in Cloudflare Worker
- **Status:** [x] Done
- **Target Files:**
    - `cloudflare_backend/cloudflare_worker.js`
- **Action:** เพิ่ม HTTP API Endpoints สำหรับการเรียกดูและสร้าง Sessions/Messages ของการแชท
- **Why:** ให้ฝั่ง Frontend สามารถบันทึกและดึงข้อมูลแชทผ่านเครือข่ายได้

### Task 97.3: Implement Chat Network Services in ApiCloudflare
- **Status:** [x] Done
- **Target Files:**
    - `my_ai_assistant/lib/databases/api_cloudflare.dart`
- **Action:** เขียนฟังก์ชันส่ง HTTP request ไปยัง API ของ Cloudflare Worker
- **Why:** เป็นส่วนติดต่อรับส่งข้อมูลระยะไกล

### Task 97.4: Develop Separated Global and Task Chat Streams in StateChat
- **Status:** [x] Done
- **Target Files:**
    - `my_ai_assistant/lib/state_managers/state_chat.dart`
- **Action:** ปรับปรุง StateChat ให้ใช้ D1 APIs และแยกสตรีมประวัติตัวแปรของแชททั่วไปและแชทราย Task
- **Why:** เพื่อให้ความคุยไม่ซ้อนทับและเก็บประวัติได้เรียบร้อย

### Task 97.5: Update AetherChatView UI Context
- **Status:** [x] Done
- **Target Files:**
    - `my_ai_assistant/lib/ui/chat/widgets/aether_chat_view.dart`
- **Action:** ปรับปรุงให้เฝ้าดูและดึงข้อมูลจากตัวแปรสตรีม Global Chat
- **Why:** ป้องกันการสลับข้อมูลเมื่อเปิดหน้าแชทหลัก

### Task 97.6: Update TaskEditModal UI Context
- **Status:** [x] Done
- **Target Files:**
    - `my_ai_assistant/lib/ui/kanban/widgets/task_edit_modal.dart`
- **Action:** ปรับปรุงให้ดึงข้อมูลจากตัวแปรสตรีม Task Chat
- **Why:** เพื่อแสดงประวัติแชทราย Task ที่ถูกต้อง

### Task 97.7: Update ChatPage UI Context
- **Status:** [x] Done
- **Target Files:**
    - `my_ai_assistant/lib/ui/chat/chat_page.dart`
- **Action:** เปลี่ยนค่าเริ่มต้นให้ปิด Sidebar (`_showSidebar = false`) และสั่งรีเซ็ต Global Context
- **Why:** ตอบสนองความต้องการด้านความสะอาดของ UI และการดึงข้อมูลประวัติ

### Task 97.8: Database Migration & Local Verification
- **Status:** [x] Done
- **Action:** รันอัปเดต Schema ในเครื่อง และทดสอบการทำงานของแชทพร้อมวิเคราะห์ความถูกต้องด้วย `flutter analyze`
- **Why:** เพื่อการันตีคุณภาพและความถูกต้องของระบบทั้งหมด

---

## Phase 99: Desktop Modal Ergonomics, Overflow Prevention, and Concurrent Board Load Optimization

> **Workflow Mandate:** อัปเดต Task Graph และ Re-Sync ทุกครั้งที่จบ 1 Task ย่อย (Rule 0 & V2.1 Protocol)
> **Architecture Mandate:** ปรับโครงสร้างระบบโหลดบอร์ดพร้อมกันด้วย Completer ใน StateBoards, ปรับปรุงการแสดงผลโมดอลงานเป็น Centered Dialog บนหน้าจอกว้าง, ปรับแท็บคอลัมน์ขวาเป็น Wrap เพื่อแก้บัค Overflow และเพิ่มระบบ Bento Card Pagination บนหน้า Dashboard


### Task 99.1: Implement Completer lock in StateBoards.fetchAllBoards()
- **Status:** [x] Done
- **Target Files:**
    - `my_ai_assistant/lib/state_managers/state_boards.dart`
- **Action:** เพิ่ม `Completer<void>? _fetchCompleter` เพื่อแชร์ Future การโหลดบอร์ดพร้อมกัน
- **Why:** เพื่อแก้ปัญหาสายเรียกซ้อนของหน้าจอบอร์ดสรุปงาน ส่งผลให้ไม่แสดงประวัติแจ้งเตือนและงานทันที

### Task 99.2: Implement responsive Dialog helper show() in TaskEditModal
- **Status:** [x] Done
- **Target Files:**
    - `my_ai_assistant/lib/ui/kanban/widgets/task_edit_modal.dart`
- **Action:** พัฒนา static method `show()` ใน `TaskEditModal` ให้เรียก `showDialog` บน desktop และ `showModalBottomSheet` บน mobile
- **Why:** เพื่อย้ายการครอบความกว้างบน desktop ให้เป็น Centered Dialog

### Task 99.3: Refactor layout and headers in TaskEditModal
- **Status:** [x] Done
- **Target Files:**
    - `my_ai_assistant/lib/ui/kanban/widgets/task_edit_modal.dart`
- **Action:** เปลี่ยน `Row` เป็น `Wrap` ในแถบสลับแท็บ และจัดสัดส่วน Flex 5:4 และถอด SingleChildScrollView หน้า desktop ออกเพื่อให้ส่วนแชทและคอมเม้นเลื่อนแยกกัน
- **Why:** เพื่อแก้ปัญหา UI Overflow และอำนวยความสะดวกในการใช้งาน desktop

### Task 99.4: Update modal call sites in KanbanPage, CalendarPage, and DashboardPage
- **Status:** [x] Done
- **Target Files:**
    - `my_ai_assistant/lib/ui/kanban/kanban_page.dart`
    - `my_ai_assistant/lib/ui/calendar/calendar_page.dart`
    - `my_ai_assistant/lib/ui/dashboard/dashboard_page.dart`
- **Action:** เปลี่ยนการใช้ `showModalBottomSheet` เป็น `TaskEditModal.show`
- **Why:** เพื่อส่งต่อความรับผิดชอบการเลือกรูปแบบการแสดงผลที่ตอบสนอง (Responsive) ไปยัง Modal

### Task 99.5: Implement dynamic pagination limits in DashboardPage
- **Status:** [x] Done
- **Target Files:**
    - `my_ai_assistant/lib/ui/dashboard/dashboard_page.dart`
- **Action:** เพิ่มตัวแปร limits และปุ่ม "+ LOAD MORE" แบบกระจายข้อมูลเพิ่มงานทีละ 5 และประวัติแจ้งเตือนทีละ 10 รายการ
- **Why:** ตามความต้องการของผู้ใช้ในเรื่องปริมาณและการจำกัดข้อมูลในหน้าแรก

### Task 99.6: Verify implementation with flutter analyze
- **Status:** [x] Done
- **Action:** รันการตรวจสอบ Static Analysis เพื่อการันตีความเรียบร้อย
- **Why:** หลีกเลี่ยงข้อผิดพลาดในการรันแอปพลิเคชัน

---

## Phase 98: Task Modal Splitscreen & Multi-Session Chat Manager

> **Workflow Mandate:** อัปเดต Task Graph และ Re-Sync ทุกครั้งที่จบ 1 Task ย่อย (Rule 0 & V2.1 Protocol)
> **Architecture Mandate:** ปรับปรุงโครงสร้าง Task Details Modal เป็น Splitscreen (2 คอลัมน์) บนหน้าจอกว้าง พร้อมจัดวางแถบสลับ 2 แท็บ (Comments & Chat) และพัฒนาระบบ Session Persistence ใน SQLite สำหรับเก็บแชทภายนอกและแชทราย Task

### Task 98.1: Update Task Graph and Context Sync
- **Status:** [x] Done
- **Target Files:**
    - `task-graph.md`
- **Action:** กำหนดแผนงาน Phase 98 และบันทึกลงใน Task Graph
- **Why:** เพื่อจัดเตรียมขั้นตอนและติดตามความก้าวหน้าตามกฎของระบบ

### Task 98.2: Upgrade SQLite Database Schema (db_personal_sqlite.dart) to Version 11 for Chat Sessions/Messages
- **Status:** [x] Done
- **Target Files:**
    - `my_ai_assistant/lib/databases/db_personal_sqlite.dart`
- **Action:** อัปเกรดฐานข้อมูลภายใน SQLite เป็นเวอร์ชัน 11 และรันคำสั่ง SQL สร้างตาราง `chat_sessions` และ `chat_messages`
- **Why:** เพื่อจัดเก็บประวัติการสนทนาอย่างต่อเนื่อง

### Task 98.3: Implement Session-based Chat State Manager (state_chat.dart)
- **Status:** [x] Done
- **Target Files:**
    - `my_ai_assistant/lib/state_managers/state_chat.dart`
- **Action:** พัฒนาตัวจัดการสถานะสำหรับการโหลด Session การสร้าง Session ใหม่ การเปลี่ยนชื่อ และการลบ Session ทั้งแชทภายนอกและราย Task
- **Why:** เพื่อเชื่อมต่ออินเตอร์เฟสกับข้อมูลแชทที่ถูกจัดเก็บใน SQLite

### Task 98.4: Inject Task Context to Misty Agent (misty_agent.dart & context_builder.dart)
- **Status:** [x] Done
- **Target Files:**
    - `my_ai_assistant/lib/ai_agent/core/misty_agent.dart`
    - `my_ai_assistant/lib/ai_agent/memory/context_builder.dart`
- **Action:** ปรับปรุง MistyAgent และ ContextBuilder ให้ยอมรับข้อมูล `activeTask` เพื่อดึงข้อมูลชื่องานและเนื้อหามาเสริมเป็นข้อมูลคำสั่งระบบสำหรับ AI
- **Why:** เพื่อให้คำตอบของ AI สอดคล้องกับหัวข้อที่คุยในภารกิจนั้นๆ

### Task 98.5: Redesign Task Edit Modal UI to Desktop Splitscreen with Comments/Chat Tabs (task_edit_modal.dart)
- **Status:** [x] Done
- **Target Files:**
    - `my_ai_assistant/lib/ui/kanban/widgets/task_edit_modal.dart`
- **Action:** ปรับอินเตอร์เฟสให้รองรับการแยก 2 คอลัมน์บนหน้าจอกว้าง โดยคอลัมน์ขวามี 2 แท็บ (Comments & Chat)
- **Why:** เพื่อสร้างการออกแบบที่สวยงามและใช้งานร่วมกับระบบแชทราย Task

### Task 98.6: Implement Sidebar Session List in Global Chat Page (chat_page.dart & aether_chat_view.dart)
- **Status:** [x] Done
- **Target Files:**
    - `my_ai_assistant/lib/ui/chat/chat_page.dart`
    - `my_ai_assistant/lib/ui/chat/widgets/aether_chat_view.dart`
- **Action:** เพิ่มตัวจัดการ Session หน้าแชทหลักด้านนอก (Misty AI)
- **Why:** เพื่ออำนวยความสะดวกในการจัดหมวดหมู่การสนทนาของยูเซอร์

### Task 98.7: Run flutter analyze & verification
- **Status:** [x] Done
- **Action:** รัน `flutter analyze` ตรวจสอบความถูกต้องและทดสอบความเสถียร
- **Why:** การันตีความเรียบร้อยและปราศจากข้อผิดพลาดของระบบ

---

## Phase 97: Resolve RenderFlex Unbounded Constraints in DailyTimeline

> **Workflow Mandate:** อัปเดต Task Graph และ Re-Sync ทุกครั้งที่จบ 1 Task ย่อย (Rule 0 & V2.1 Protocol)
> **Architecture Mandate:** แก้ไขข้อผิดพลาดของ RenderFlex และ Unbounded width constraints ในหน้าปฏิทิน (DailyTimeline) โดยปรับการจัดวางองค์ประกอบให้รับขนาดความกว้างตามความกว้างธรรมชาติแทนการบังคับ Flex ใน Row ที่ไม่โดนครอบ

### Task 97.1: Update Task Graph & Context Sync
- **Status:** [x] Done
- **Target Files:**
    - `task-graph.md`
- **Action:** กำหนดแผนงาน Phase 97 และทำ Context Re-Sync
- **Why:** เพื่อรักษาความสม่ำเสมอของประวัติโครงการ

### Task 97.2: Fix RenderFlex constraints in daily_timeline_view.dart
- **Status:** [x] Done
- **Target Files:**
    - `my_ai_assistant/lib/ui/calendar/widgets/daily_timeline_view.dart`
- **Action:** แก้ไขโครงสร้าง `_buildPreviewMetadataItem` โดยการถอด `Flexible` ออกจาก `Text`
- **Why:** เพื่อขจัดขอบเขตเงื่อนไข Flex ที่ทับซ้อนกันและทำให้เกิดข้อผิดพลาดรันไทม์

### Task 97.3: Run flutter analyze and verify
- **Status:** [x] Done
- **Action:** รัน `flutter analyze` เพื่อตรวจสอบความสมบูรณ์เชิงไวยากรณ์
- **Why:** การันตีความเรียบร้อยและไม่มีข้อผิดพลาดเหลืออยู่

---

## Phase 96: Resolve compilation errors in StateTasks & negative margin in DailyTimeline

> **Workflow Mandate:** อัปเดต Task Graph และ Re-Sync ทุกครั้งที่จบ 1 Task ย่อย (Rule 0 & V2.1 Protocol)
> **Architecture Mandate:** แก้ไขข้อผิดพลาดของประเภทข้อมูลในการอ้างอิง `board.columns` (ซึ่งเป็น `List<String>`) ใน `state_tasks.dart` และเปลี่ยนการจัดวาง Avatar Stack ใน `daily_timeline_view.dart` เพื่อลบมาร์จิ้นติดลบที่ส่งผลให้เกิดการขัดข้องทางไวยากรณ์

### Task 96.1: Update Task Graph & Context Sync
- **Status:** [x] Done
- **Target Files:**
    - `task-graph.md`
- **Action:** กำหนดแผนงาน Phase 96 และทำ Context Re-Sync
- **Why:** เพื่อรักษาความสม่ำเสมอของประวัติโครงการ

### Task 96.2: Correct Column Query Types in StateTasks
- **Status:** [x] Done
- **Target Files:**
    - `my_ai_assistant/lib/state_managers/state_tasks.dart`
- **Action:** แก้ไขฟังก์ชันการเข้าถึง `board.columns` จากการใช้งานเสมือน Map เป็นการจัดการข้อมูลตามประเภท `String` โดยตรงใน line 280-281 และ 426-427
- **Why:** เพื่อแก้ไขปัญหาที่คอมไพล์โค้ดไม่ผ่าน (A value of type 'String' can't be assigned...)

### Task 96.3: Refactor DailyTimeline Avatar Stack
- **Status:** [x] Done
- **Target Files:**
    - `my_ai_assistant/lib/ui/calendar/widgets/daily_timeline_view.dart`
- **Action:** แก้ไขโครงสร้าง `_buildAvatarStack(List<String> uids)` ให้ใช้ `Stack` และ `Positioned` แทนมาร์จิ้นติดลบของ Container ใน Row
- **Why:** เพื่อป้องกันการเกิด Assertion failed: margin == null || margin.isNonNegative ในวิดเจ็ตคอนเทนเนอร์

### Task 96.4: Empirical Testing & Code Verification
- **Status:** [x] Done
- **Action:** รัน `flutter analyze` เพื่อยืนยันว่าไม่มีข้อผิดพลาดทางไวยากรณ์เหลืออยู่
- **Why:** การันตีความเรียบร้อยและเสถียรภาพของแอปพลิเคชัน

---

## Phase 95: Task Database Sync, Solid Edit Modal & Focus Loop Fix

> **Workflow Mandate:** อัปเดต Task Graph และ Re-Sync ทุกครั้งที่จบ 1 Task ย่อย (Rule 0 & V2.1 Protocol)
> **Architecture Mandate:** ปรับปรุงความเสถียรและความสอดคล้องของการบันทึกงานระหว่าง D1 Database กับโครงสร้าง Schema จริง, ปรับความทึบของกล่องสร้างงานเพื่อความชัดเจน และแก้ไขลูปแย่งโฟกัสของช่องกรอกรายละเอียด

### Task 95.1: Update Task Graph & Context Sync
- **Status:** [x] Done
- **Target Files:**
    - `task-graph.md`
- **Action:** บันทึกแผนงานและขั้นตอนย่อยของ Phase 95 ลงในเอกสารและเริ่มดำเนินการซิงค์ข้อมูล
- **Why:** เพื่อบันทึกประวัติการพัฒนาและคงสมานฉันท์ของสถาปัตยกรรม

### Task 95.2: Align SQLite Queries in Cloudflare Backend
- **Status:** [x] Done
- **Target Files:**
    - `cloudflare_backend/cloudflare_worker.js`
- **Action:** ลบการอ้างอิงและ Bind parameters สำหรับ `team_id` และ `time` ออกจาก SQL queries ฝั่ง POST และ PUT ของ `/api/tasks`
- **Why:** เพื่อแก้ปัญหาระบบเซฟงานไม่ลงเนื่องจาก Schema ไม่ตรงกับ SQLite Table

### Task 95.3: Update Task Edit Modal Card Background
- **Status:** [x] Done
- **Target Files:**
    - `my_ai_assistant/lib/ui/kanban/widgets/task_edit_modal.dart`
- **Action:** เปลี่ยนการใช้ `GlassDecorations.surface` เป็น `GlassDecorations.solidSurface(radius: 32, hasShadow: true)`
- **Why:** เพื่อป้องกันการมองเห็นทะลุผ่านและเพิ่มการอ่านง่ายของข้อความ

### Task 95.4: Resolve IME Safe Text Field Focus Fight Loop
- **Status:** [x] Done
- **Target Files:**
    - `my_ai_assistant/lib/ui/common/ime_safe_text_field.dart`
- **Action:** ตรวจสอบ `FocusManager.instance.primaryFocus` หากโฟกัสย้ายไปช่องกรอกอื่นให้เปลี่ยนสถานะ `_wasFocused = false` เพื่อไม่ให้เกิดลูปกะพริบแย่งโฟกัส
- **Why:** เพื่อแก้ไขความขัดแย้งของ Focus Node บน Flutter Web

### Task 95.5: Static Code Verification
- **Status:** [x] Done
- **Action:** ตรวจสอบความสมบูรณ์ของไวยากรณ์ด้วย `flutter analyze`
- **Why:** เพื่อยืนยันว่าการแก้ไขทั้งหมดไม่มีข้อผิดพลาดทางโค้ด

---

## Phase 94: Revert Dashboard Bottom Layout to Mockup Style
> **Architecture Mandate:** ปรับเปลี่ยนการแสดงผลในส่วนล่างของหน้าแดชบอร์ดให้ตรงตามภาพร่างการออกแบบ (Mockup) ของผู้ใช้ ได้แก่ ปุ่มเข้าร่วม Workspace, ข้อความหัวเรื่อง, ป้ายบอร์ดโครงการ และความหนาพร้อมการวางวันส่งของแถบรายการ Milestones และการแจ้งเตือน โดยยังคงหน้าตา Header ด้านบน (Strategic Hub) ที่ได้รับการอนุมัติแล้วไว้

### Task 94.1: Update Task Graph
- **Status:** [x] Done
- **Target Files:**
    - `task-graph.md`
- **Action:** กำหนดแผนงาน Phase 94 และบันทึกลงในเอกสารระบุขั้นตอน
- **Why:** เพื่อควบคุมประวัติโครงการและบันทึกความคืบหน้าให้มีคุณภาพสูงสุด

### Task 94.2: Revert Workspaces UI Layout
- **Status:** [x] Done
- **Target Files:**
    - `my_ai_assistant/lib/ui/dashboard/dashboard_page.dart`
- **Action:**
    - ปรับโครงสร้างส่วนหัวของ Workspaces: ซ่อน text label `:: ACTIVE WORKSPACES`
    - แสดงไอคอน `Icons.assignment_outlined` ข้างหัวข้อ `Active Workspaces (count)` โดยให้แสดงตัวเลขในวงเล็บ (ไม่มีการแยก badge card)
    - เปลี่ยนปุ่ม join ด้านขวาเป็นรูปแบบ outline ด้วยข้อความ `+ JOIN WORKSPACE`
    - เปลี่ยน badge `TEAM` / `PERSONAL` ให้ใช้พื้นหลังเทาและตัวหนังสือขาวจาง
    - เปลี่ยน project board tags จากสีพื้นทั้งอัน ให้กลายเป็นขอบมนแคปซูลสีจางที่มีจุดสีระบุบอร์ดด้านซ้าย

### Task 94.3: Revert Upcoming Milestones Layout
- **Status:** [x] Done
- **Target Files:**
    - `my_ai_assistant/lib/ui/dashboard/dashboard_page.dart`
- **Action:**
    - คืนค่าโครงสร้าง ListView.separated ภายในส่วนของ Milestones ให้หัวข้อของ Task อยู่ด้านซ้ายและตัวบอกวันครบกำหนด Due status อยู่ด้านขวาในบรรทัดเดียวกัน

### Task 94.4: Revert Discussion Updates Layout
- **Status:** [x] Done
- **Target Files:**
    - `my_ai_assistant/lib/ui/dashboard/dashboard_page.dart`
- **Action:**
    - คืนค่าโครงสร้างแถบ ListView ภายใน Discussion Updates ให้ชื่อผู้คอมเมนต์อยู่ด้านซ้ายและเวลาคอมเมนต์อยู่ด้านขวาในบรรทัดเดียวกัน

### Task 94.5: Code Verification
- **Status:** [x] Done
- **Action:** ตรวจสอบความถูกต้องผ่าน `flutter analyze` และการคอมไพล์

### Task 94.6: Manual Verification
- **Status:** [/] In Progress
- **Action:** ผู้ใช้อัปเดตและยืนยันการแสดงผลบนหน้าจอจริง

---

## Phase 93: Startup Stability, Workspace Dashboard Correctness, and Workspace Management Updates

> **Workflow Mandate:** อัปเดต Task Graph และ Re-Sync ทุกครั้งที่จบ 1 Task ย่อย (Rule 0 & V2.1 Protocol)
> **Architecture Mandate:** ปรับปรุงความเสถียรของแอปพลิเคชันในช่วงเริ่มต้นโหลด (ลดการกะพริบและ redirect) ปรับปรุงหน้าจอ Active Workspaces บนแดชบอร์ดให้แสดงผล Workspace จริงพร้อมรายชื่อโปรเจกต์ภายในอย่างมินิมอล และเพิ่มการทำงานแก้ไขชื่อ Workspace และการคัดลอกรหัส Workspace (Workspace ID) ในส่วนหัวของหน้าบอร์ดโครงการ

### Task 93.1: Startup Stability & Auth Guard Safety Delay
- **Status:** [x] Done
- **Target Files:**
    - `my_ai_assistant/lib/main.dart`
- **Action:** เพิ่มระยะเวลาหน่วงเพื่อความปลอดภัย (Safety Delay) 800ms ในขั้นตอนเช็คสิทธิ์ผู้ใช้ของ StartupGuard บน Web/App เพื่อป้องกันเพจเปลี่ยนสถานะกะพริบก่อนโหลด Firebase Auth Token เสร็จสิ้น
- **Why:** เพื่อแก้ปัญหาระบบหลุดไปหน้า Login แล้วเด้งกลับเข้าหน้าหลักเมื่อเริ่มเปิดแอป

### Task 93.2: StateBoards Workspace Management Update
- **Status:** [x] Done
- **Target Files:**
    - `my_ai_assistant/lib/state_managers/state_boards.dart`
- **Action:** เพิ่มฟังก์ชัน `updateWorkspaceName(WorkspaceModel workspace, String newName)` ที่รองรับการบันทึกลง SQLite (ถ้าเป็น personal) และเซฟลง Cloudflare (ถ้าเป็น team)
- **Why:** เพื่อเพิ่มความสามารถในการแก้ไขชื่อและซิงค์ข้อมูลกับ backend ได้อย่างราบรื่น

### Task 93.3: Dashboard Workspace Overview Redesign & Tab Integration
- **Status:** [x] Done
- **Target Files:**
    - `my_ai_assistant/lib/ui/dashboard/dashboard_page.dart`
    - `my_ai_assistant/lib/main.dart`
- **Action:**
    - ดึงรายการ `workspaces` และ `boards` มารวมรวบแสดงใน Active Workspaces ในรูปมินิมอลแสดงรายการโปรเจ็กต์ย่อยด้านในแยกตาม Workspace
    - เชื่อมต่อ `onNavigate` เพื่อให้เมื่อผู้ใช้คลิกเลือกบอร์ดในหน้าแดชบอร์ด จะตั้งค่าเป็น Selected Workspace และนำทางเข้าสู่หน้ารายการบอร์ด (Boards Page) ทันที
- **Why:** เพื่อแก้ไขพฤติกรรมการแสดงผลผิดพลาดที่ก่อนหน้านี้แสดงบอร์ดแทน Workspace และสร้าง UX การสลับแท็บที่ดี

### Task 93.4: Boards Page Header Updates
- **Status:** [x] Done
- **Target Files:**
    - `my_ai_assistant/lib/ui/boards/boards_page.dart`
- **Action:**
    - เพิ่มปุ่มแก้ไขชื่อ (Rename) และปุ่มคัดลอก (Copy Workspace ID) ลงในแถบ Breadcrumbs/Header ของบอร์ดงานที่เลือก
    - นำเสนอหน้าต่าง Dialog กรอกข้อมูลให้เสร็จสิ้นและแสดง SnackBar แจ้งเตือนหลังเซฟ
- **Why:** เพื่อรองรับความสามารถการแก้ไขชื่อและการคัดลอก ID ในระดับผู้บริหารอย่างสะดวกสบาย

### Task 93.5: Final Polish & Static Code Analysis
- **Status:** [x] Done
- **Action:**
    - รันการวิเคราะห์และตรวจสอบความสมบูรณ์ผ่าน `flutter analyze`
- **Why:** เพื่อยืนยันคุณภาพและความพร้อมก่อนส่งมอบงาน

## Phase 92: Dashboard Clean Redesign & Comments Integration

> **Workflow Mandate:** อัปเดต Task Graph และ Re-Sync ทุกครั้งที่จบ 1 Task ย่อย (Rule 0 & V2.1 Protocol)
> **Architecture Mandate:** ปรับปรุงหน้าแดชบอร์ดให้มีความสะอาดตาและพรีเมียม แสดงจำนวนและรายการ Workspace ทั้งหมด แสดงงานที่ใกล้ถึงกำหนดส่งจากบอร์ดทั้งหมด และพัฒนาระบบคอมเมนต์ฝังลงตารางงานเดิม (SQLite + Cloudflare D1) เพื่อดึงฟีดกิจกรรมการคอมเมนต์ล่าสุดมาทำหน้าที่เป็นฟีดแจ้งเตือนที่เอเจนท์สามารถอ่านได้

### Task 92.1: Update Documentation & Project SOP Sync
- **Status:** [x] Done
- **Target Files:**
    - `task-graph.md`
    - `my_ai_assistant/lib/ui/dashboard/dashboard_page.dart`
- **Action:** สร้างและบันทึกผังความรับผิดชอบ Phase 92 และเตรียมตัวเขียนโค้ด
- **Why:** เพื่อให้สอดคล้องกับกฎเหล็กในการทำงานของ AI และการควบคุมประวัติโครงการอย่างชัดเจน

### Task 92.2: Cloudflare Backend D1 Database Migration
- **Status:** [x] Done
- **Target Files:**
    - `cloudflare_backend/cloudflare_worker.js`
- **Action:**
    - เพิ่มขั้นตอน Migration คอลัมน์ `comments TEXT DEFAULT '[]'` ไปยังตาราง `team_tasks` ในฟังก์ชัน `ensureSchema`
    - ปรับปรุงการสืบค้น `INSERT` และ `UPDATE` ใน worker ให้รองรับการอ่านเขียนฟิลด์ `comments` ลงฐานข้อมูล D1
- **Why:** เพื่อให้ฐานข้อมูลบน Cloudflare D1 เก็บและส่งข้อมูลการคอมเมนต์แบบทีมได้อย่างสมบูรณ์

### Task 92.3: SQLite Database Migration
- **Status:** [x] Done
- **Target Files:**
    - `my_ai_assistant/lib/databases/db_personal_sqlite.dart`
- **Action:**
    - ขยับรุ่นฐานข้อมูล (version) เป็น `10`
    - เพิ่มคำสั่งสร้างคอลัมน์ `comments TEXT DEFAULT '[]'` ใน `_createDB` และใน `_upgradeDB` สำหรับตาราง `personal_tasks`
    - ปรับปรุงฟังก์ชัน `insertTask`, `getTasksByBoard`, `getAllTasks` และ `updateTask` เพื่อดึงและบันทึกคอมเมนต์แบบมีโครงสร้าง JSON string
- **Why:** เพื่อให้การเก็บคอมเมนต์ทำงานได้เสถียรบน Local Database (SQLite) กรณีใช้งานแบบออฟไลน์/ส่วนตัว

### Task 92.4: Dashboard Clean UI & Activity Feed Implementation
- **Status:** [x] Done
- **Target Files:**
    - `my_ai_assistant/lib/ui/dashboard/dashboard_page.dart`
- **Action:**
    - รีดีไซน์หน้าจอแดชบอร์ดใหม่ทั้งหมด ให้มีความคลีน หรูหรา ไร้บล็อกรกสายตา
    - แสดง Workspace Overview (จำนวน Workspace ทั้งหมด พร้อมการ์ดลิสต์มินิมอล)
    - แสดงงานที่จะต้องส่งในระยะเวลาอันใกล้ (Due Soon Tasks) จากทุก Workspace/Board กรองเฉพาะงานที่ยังไม่เสร็จ (`!isCompleted`) เรียงตามกำหนดส่ง
    - แสดง Recent Comments Feed รวบรวมคอมเมนต์จากทุกงานมาเรียงลำดับล่าสุดเพื่อเป็น Activity/Notification Feed
- **Why:** เพื่อยกระดับ UX ให้ดูเป็นระบบพรีเมียม สะอาดตา และเพิ่มช่องทางให้ผู้ใช้และ AI รับทราบความคืบหน้าผ่านคอมเมนต์

### Task 92.5: UI Polish & Forensic Static Analysis
- **Status:** [x] Done
- **Action:**
    - ตรวจสอบการคอมไพล์และคอมเม้นท์บน Emulator/Browser
    - รันการตรวจสอบแบบสแตติก `flutter analyze` เพื่อยืนยันว่าไม่มีจุดผิดพลาดหรือ Syntax Error
- **Why:** เพื่อรับประกันความมั่นคงและคุณภาพของซอร์สโค้ดก่อนส่งงาน

## Phase 91: UI Resiliency & CORS Network Image Exception Hardening> **Workflow Mandate:** อัปเดต Task Graph และ Re-Sync ทุกครั้งที่จบ 1 Task ย่อย (Rule 0 & V2.1 Protocol)
> **Architecture Mandate:** ปรับปรุงและป้องกันข้อผิดพลาดการโหลดรูปภาพผ่านเครือข่าย (CORS Exceptions) บนเบราว์เซอร์ โดยเปลี่ยนจากการใช้ NetworkImage หรือ DecorationImage ตรงๆ ไปเป็นโครงสร้าง Image.network ที่มีการติดตั้ง errorBuilder และ CircleAvatar ที่ติดตั้ง foregroundImage + onForegroundImageError เพื่อความเสถียรของแอปพลิเคชัน

### Task 91.1: Refactor User Profiles
- **Status:** [x] Done
- **Target Files:**
    - `my_ai_assistant/lib/ui/profile/profile_page.dart`
    - `my_ai_assistant/lib/ui/common/aether_side_nav.dart`
- **Action:** แทนที่การเรนเดอร์รูปภาพโปรไฟล์ผ่าน BoxDecoration image ด้วยระบบ ClipOval ครอบ Image.network พร้อมตัวควบคุม errorBuilder เพื่อแสดงผลป้ายอักษรย่อหรือไอคอนเมื่อโหลดไม่สำเร็จ
- **Why:** เพื่อดักจับข้อผิดพลาด CORS หรือรูปโปรไฟล์ใช้งานไม่ได้ และตัดข้อผิดพลาด NetworkImage ใน Console บนเว็บเบราว์เซอร์

### Task 91.2: Refactor Workspace Boards & Daily Timelines
- **Status:** [x] Done
- **Target Files:**
    - `my_ai_assistant/lib/ui/boards/boards_page.dart`
    - `my_ai_assistant/lib/ui/calendar/widgets/daily_timeline_view.dart`
- **Action:**
    - ปรับปรุง `_buildMemberAvatar` ในหน้าบอร์ด ให้ใช้งาน ClipOval และ Image.network ร่วมกับ errorBuilder
    - ปรับปรุง daily timeline cover image, asset preview image และ avatar stack ให้มีกลไก Safe Image Loading
- **Why:** เพื่อป้องกันภาพปกและไอคอนสมาชิกที่โหลดจากโดเมนภายนอกล้มเหลวและทริกเกอร์ Uncaught Exception

### Task 91.3: Refactor Chat Widgets & Drafts
- **Status:** [x] Done
- **Target Files:**
    - `my_ai_assistant/lib/ui/chat/widgets/chat_widgets.dart`
    - `my_ai_assistant/lib/ui/chat/widgets/draft_cards.dart`
- **Action:**
    - ปรับปรุง Avatar ของบอท Aether (ChatAI) และสมาชิกผู้ใช้ (ChatUser) ให้มี fallback ไปเป็นไอคอนกรณีโหลดภาพล้มเหลว
    - ปรับปรุง Avatar ในหน้า Drafts และส่วนการเลือกสมาชิกให้ใช้ระบบ Safe Loading
- **Why:** เพื่อดักจับภาพบอทและภาพสมาชิกที่แสดงในแแชทและแถบดราฟท์ให้มีทางเลือกภาพจำลองที่สวยงาม

### Task 91.4: Refactor Kanban Boards & Roles Modals
- **Status:** [x] Done
- **Target Files:**
    - `my_ai_assistant/lib/ui/kanban/widgets/member_role_modal.dart`
    - `my_ai_assistant/lib/ui/kanban/widgets/task_edit_modal.dart`
    - `my_ai_assistant/lib/ui/kanban/widgets/kanban_card.dart`
- **Action:**
    - อัปเดต CircleAvatar ทุกจุดบนบอร์ดคันบังและ modal จัดการตำแหน่งสมาชิกให้ใช้งาน foregroundImage และ onForegroundImageError
    - อัปเดตภาพหน้าปกและภาพแนบบนการ์ดคันบังให้ใช้งาน ClipRRect และ Image.network ร่วมกับ errorBuilder แผงข้อความขัดข้องแบบกลาสมอร์ฟิก
- **Why:** เพื่อให้สอดคล้องกับโครงสร้างและสุนทรียศาสตร์ของบอร์ด Kanban และป้อนตัวเลือก fallback ที่เสถียร

### Task 91.5: Quality Assurance & Code Analysis
- **Status:** [x] Done
- **Action:** รันการวิเคราะห์โค้ด `flutter analyze` เพื่อตรวจสอบ Syntax และความสมบูรณ์ในการรันบนเบราว์เซอร์
- **Why:** เพื่อยืนยันว่าไม่มีข้อผิดพลาดเชิงโครงสร้างหรือ Syntax หลุดรอด

## Phase 90: Workspace Sorting & Join Workspace Refactoring

- **Status:** [x] Done
- **Target Files:**
    - `cloudflare_backend/cloudflare_worker.js`
    - `my_ai_assistant/lib/databases/api_cloudflare.dart`
    - `my_ai_assistant/lib/state_managers/state_boards.dart`
    - `my_ai_assistant/lib/ui/boards/boards_page.dart`
- **Action:** เพิ่ม API `/api/workspaces_join`, ปรับปรุงและเรียงลำดับ Workspace เริ่มต้นให้อยู่ด้านบนสุด, รีแฟคเตอร์หน้าจอการกด Join Board ให้เปลี่ยนเป็น Join Workspace
- **Why:** เพื่อการทำงานและความลื่นไหลในการจัดการทีมตาม Workspace-First Architecture

## Phase 89: Notion-Style Minimalist Projects Table & Infinite Rebuild Stabilization

> **Workflow Mandate:** อัปเดต Task Graph และ Re-Sync ทุกครั้งที่จบ 1 Task ย่อย (Rule 0 & V2.1 Protocol)
> **Architecture Mandate:** ปรับปรุงตารางโครงงานในหน้าเวิร์คสเปซ (Boards Page) ให้แสดงผลแบบ Notion Minimalist ไร้การเลื่อนด้านข้าง จัดสัดส่วนพื้นที่ด้วย Flex และสถาปัตยกรรมตัวแปรหน้าจอที่เสถียร รวมถึงการแก้บั๊ก Infinite Loop การประมวลผลซ้ำของระบบ

### Task 89.1: Fix Infinite Rebuild Loop
- **Status:** [x] Done
- **Target Files:**
    - `my_ai_assistant/lib/main.dart`
    - `my_ai_assistant/lib/state_managers/state_boards.dart`
- **Action:**
    - ย้ายรายการเพจ `_screens` ใน `_AppShellState` ไปเป็นตัวแปรแบบ `late final` และเตรียมใน `initState` แทนการใช้ Getter
    - ใส่ Loading Guard (`if (_isLoading) return;`) ที่หัวของฟังก์ชัน `fetchAllBoards()` ใน `state_boards.dart`
- **Why:** เพื่อหยุดกระบวนการสร้างและเมานต์ widget ซ้ำๆ ทุกรอบที่สถานะอัปเดต และลดการดึงข้อมูลและข้อผิดพลาด 429 ของเครือข่าย

### Task 89.2: Notion-Style Minimalist Table Layout
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/boards/boards_page.dart`
- **Action:**
    - เอา `SingleChildScrollView(scrollDirection: Axis.horizontal)` ออก
    - นำโครงสร้างตารางเดิมออก และปรับเป็นคอลัมน์ของแถวที่ใช้ `Row` ร่วมกับ `Expanded` เพื่อควบคุม Flex Ratio ที่พอดีกับจอเดสก์ท็อป โดยไม่มี Scrollbar
- **Why:** เพื่อให้ตารางเป็นแบบมินิมอลตามดีไซน์ของ Notion ตามคำขอของลูกค้า

### Task 89.3: Refine Row Components
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/boards/boards_page.dart`
- **Action:**
    - ปรับปรุงการออกแบบแถวของแต่ละโครงงาน:
        - คอลัมน์ Project: แสดงจุดสีประเภทบอร์ด + ชื่อโครงงานแบบคลิกข้ามได้ พร้อมปุ่ม `OPEN` ขนาดเล็ก
        - คอลัมน์ Stage: แสดงประเภทเป็นแคปซูลเล็ก
        - คอลัมน์ Members: แสดง Avatar Stack ขนาดเล็ก และปุ่มจัดการสมาชิกสำหรับโปรเจ็กต์ทีม
        - คอลัมน์ Docs: แสดงรายการไฟล์เป็นป้ายขนาดเล็ก พร้อมปุ่มอัปโหลด
    - คั่นระหว่างแถวด้วยเส้นใยบางเบา `GlassColors.outlineVariant.withOpacity(0.15)`
- **Why:** เพื่อความกระชับ หรูหรา ไร้รอยต่อ และเป็นระเบียบของตารางข้อมูล

### Task 89.4: Breadcrumbs, Header & "+ New project" Text Row
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/boards/boards_page.dart`
- **Action:**
    - เพิ่ม Breadcrumbs ดำเนินการที่ด้านบนสุด เช่น `Workspace HQ / Projects`
    - ปรับแต่งฟอนต์หัวข้อหลักให้ใหญ่ หนา และมีอีโมจิ `🎯`
    - เพิ่มแถวตัวเลือกจำลองและเมนูปุ่มจำลองด้านบนขวา
    - เพิ่มปุ่มแถวท้ายตาราง `+ New project` เพื่อกดสร้างบอร์ดได้ทันที
- **Why:** เพื่อจำลอง UX/UI และพฤติกรรมโครงสร้างตารางของ Notion ได้อย่างสมบูรณ์แบบ

### Task 89.5: Linter & Compilation Check
- **Status:** [x] Done
- **Action:**
    - รัน `flutter analyze`
- **Why:** ยืนยันความปลอดภัยและความถูกต้องทางโครงสร้างซอฟต์แวร์

## Phase 88: Workspace Board Table View, Document Attachment, Sidebar Nesting & SQL Fix

> **Workflow Mandate:** อัปเดต Task Graph และ Re-Sync ทุกครั้งที่จบ 1 Task ย่อย (Rule 0 & V2.1 Protocol)
> **Architecture Mandate:** ปรับปรุงหน้ารายการบอร์ดของพื้นที่ทำงานให้แสดงผลแบบตาราง (Table View) ที่รองรับการจัดการเอกสาร/ข้อบังคับแนบโครงการ ปรับปรุงการนำบอร์ดโครงการย่อยกลับมาแสดงใน Sidebar ปรับเมนูบอร์ดหลักออก และแก้ไข D1 SQL order_index คอลัมน์ที่ขาดหายไป

### Task 88.1: Database Schema Migration & Worker Support
- **Status:** [x] Done
- **Target Files:**
    - `cloudflare_backend/d1_schema.sql`
    - `cloudflare_backend/cloudflare_worker.js`
    - `my_ai_assistant/lib/databases/db_personal_sqlite.dart`
- **Action:**
    - เพิ่ม `order_index` ใน `team_tasks` และ `documents` ใน `team_boards` ใน `d1_schema.sql`
    - เพิ่มโค้ด ALTER TABLE ไมเกรชันใน `ensureSchema` ของ `cloudflare_worker.js`
    - อัปเดต POST/PUT `/api/boards` ใน `cloudflare_worker.js`
    - อัปเดต `db_personal_sqlite.dart` (เวอร์ชัน 9 + ไมเกรชันสำหรับ `documents` ใน `personal_boards`)
- **Why:** เพื่อรองรับการเก็บลิสต์เอกสารและการจัดเรียงการ์ดภารกิจที่มั่นคง ไม่ทำให้ API เกิด SQL 500 error

### Task 88.2: Expand BoardModel with Documents Support
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/models/board_model.dart`
- **Action:**
    - เพิ่มฟิลด์ `documents` ใน `BoardModel` พร้อมอัปเดตฟังก์ชันแปลงข้อมูลเข้า/ออกจาก JSON/SQLite Map
- **Why:** เพื่อให้โมเดลของบอร์ดในแอปสามารถพึ่งพาระบบเอกสารแนบส่วนตัวและทีมได้สำเร็จ

### Task 88.3: Sidebar Menu Navigation Adjustments
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/common/aether_side_nav.dart`
- **Action:**
    - ลบปุ่มนำทางหลัก 'Boards' ออก
    - นำรายการบอร์ดโครงการย่อย (Nested list) กลับมาใส่ใต้หัวข้อ Workspace แต่ละตัว โดยแสดงจุด Bullet เพื่อคลิกสลับเข้าบอร์ดโดยตรง
- **Why:** เพื่อรักษาความคลีน และช่วยให้กระโดดข้ามไปยังบอร์ดต่าง ๆ ได้อย่างสะดวกผ่าน Sidebar

### Task 88.4: Develop Premium Workspace Boards Table View
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/boards/boards_page.dart`
- **Action:**
    - เปลี่ยนการแสดงผลจากการ์ด Grid ไปเป็น Glassy Table Row ประกอบด้วยข้อมูล Project, Members, Documents และ Actions
    - มีปุ่มอัปโหลดเอกสารข้อบังคับและการจัดการสมาชิกของบอร์ดนั้น ๆ
- **Why:** เพื่อเพิ่มพื้นที่และมิติข้อมูลให้มองเห็นรายละเอียดโปรเจ็กต์ สมาชิก และแนบเอกสารกฎเกณฑ์ประจำโปรเจ็กต์ได้ทันที

### Task 88.5: Verification & Production Compilation
- **Status:** [x] Done
- **Action:** รัน `flutter analyze` เพื่อตรวจสอบความถูกต้องทั้งหมด
- **Why:** เพื่อความปลอดภัยและเสถียรภาพสูงสุดของผลิตภัณฑ์

## Phase 87: Solid Popups, High-Contrast Submit Buttons & Sidebar Cleanup

> **Workflow Mandate:** อัปเดต Task Graph และ Re-Sync ทุกครั้งที่จบ 1 Task ย่อย (Rule 0 & V2.1 Protocol)
> **Architecture Mandate:** ปรับแต่ง Popups/Dialogs ให้เป็นสีทึบเพื่อความอ่านง่าย, เพิ่ม Contrast ให้กับปุ่ม Submit และทำความสะอาดเมนูบอร์ดโครงการใน Sidebar

### Task 87.1: Update Theme Decorations
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/theme/glass_theme.dart`
- **Action:**
    - เพิ่ม `GlassDecorations.solidSurface` เพื่อสร้าง BoxDecoration สีทึบ (GlassColors.surface)
- **Why:** เพื่อเป็นฐานอ้างอิงให้ Dialog/Modal ทั่วทั้งแอปปรับเป็นสีทึบพรีเมียมได้แบบรวมศูนย์

### Task 87.2: Sidebar Cleanup & Solid Dialogs
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/common/aether_side_nav.dart`
- **Action:**
    - ลบ Nested Boards/Projects List (ลูปเรนเดอร์บอร์ดโครงการย่อย) ออก
    - ปรับ `_showAddWorkspaceDialog` และ `_showDeleteWorkspaceConfirmDialog` ให้ใช้ `solidSurface`
    - แก้ไขสีปุ่ม ElevatedButton ของ CREATE และ DELETE ให้มี Contrast สูงและตัวหนา
- **Why:** เพื่อให้ Sidebar คลีน และการพิมพ์และจัดการ Workspace ในป๊อปอัปเด่นชัดอ่านง่าย

### Task 87.3: Boards Page Solid Dialogs
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/boards/boards_page.dart`
- **Action:**
    - ปรับ `_showJoinBoardDialog` ให้ใช้ `solidSurface`
    - เปลี่ยนสีข้อความปุ่ม ElevatedButton ของ JOIN BOARD ให้เป็น `GlassColors.onPrimary` และตัวหนา
- **Why:** เพื่อให้ป๊อปอัปเข้าร่วมบอร์ดเป็นสีทึบและตัวอักษรบนปุ่ม Contrast ชัดเจน

### Task 87.4: Board Edit Modal Solid Decoration
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/boards/widgets/board_edit_modal.dart`
- **Action:**
    - ปรับกล่อง Container หลักให้ใช้ `solidSurface`
    - ปรับ `_buildGhostButton` สำหรับปุ่มหลัก `isPrimary = true` ให้เป็นสีพื้นทองทึบ `GlassColors.gold` และข้อความสีดำตัวหนา พร้อม BoxShadow
- **Why:** เพื่อให้โมดัลสร้างบอร์ดเป็นสีทึบ และปุ่มสร้างบอร์ดเห็นเด่นชัดและคลิกง่าย

### Task 87.5: Code Verification
- **Status:** [x] Done
- **Action:** รัน `flutter analyze` เพื่อตรวจสอบความเสถียรและคุณภาพโค้ด
- **Why:** เพื่อให้มั่นใจว่าระบบไม่มีข้อผิดพลาดการคอมไพล์หรือลินเตอร์

## Phase 86: Notion-Style Minimalist Design Adaptation

> **Workflow Mandate:** อัปเดต Task Graph และ Re-Sync ทุกครั้งที่จบ 1 Task ย่อย (Rule 0 & V2.1 Protocol)
> **Architecture Mandate:** ปรับปรุง Theme, Typography และ Decorator ใน GlassTheme และ GlassWidgets ให้เปลี่ยนเป็น Notion Minimalist Light Theme

### Task 86.1: Update Theme Colors and Typography Definitions
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/theme/glass_theme.dart`
- **Action:**
    - Update `GlassColors` to light palette.
    - Set font loading to `GoogleFonts.inter` for displays/headlines/body.
    - Setup `GoogleFonts.jetbrainsMono` for monospace tags.
    - Update card, button, elevated container decoration shapes and borders.

### Task 86.2: Refactor GlassContainer and GlassButton
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/common/glass_widgets.dart`
- **Action:**
    - Disable BackdropFilter dynamically in `GlassContainer` if light mode.
    - Adjust `GlassButton` to use white text/icon contrast on solid backgrounds.

### Task 86.3: Shift MaterialApp to Brightness.light
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/main.dart`
- **Action:**
    - Change global brightness theme to `Brightness.light`.

### Task 86.4: Update AetherSideNav Sidebar Colors
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/common/aether_side_nav.dart`
- **Action:**
    - Remove opacity blur on sidebar background, styling it with warm-gray surface.
    - Customize active navigation list items to align with Notion styles.

### Task 86.5: Verify Project Compilation and Screen Designs
- **Status:** [x] Done
- **Target File:** Multi-file
- **Action:**
    - Run `flutter analyze` and verify styling changes compile and render correctly.

## Phase 85: AI-to-Kanban Real-time Sync via Supabase Broadcast

> **Workflow Mandate:** อัปเดต Task Graph และ Re-Sync ทุกครั้งที่จบ 1 Task ย่อย (Rule 0 & V2.1 Protocol)
> **Architecture Mandate:** ใช้ `_broadcastUpdate` (Supabase Realtime) ที่มีอยู่แล้วในหน้า Kanban ให้ AI ในหน้า Chat ก็ trigger ได้เหมือนกัน

### Task 85.1: Revert StateTasks to Supabase Realtime (Remove WebSocket)
- **Status:** [x] Done
- **Target File:** `lib/state_managers/state_tasks.dart`
- **Action:**
    - [x] ลบ `web_socket_channel` import ออก
    - [x] กลับไปใช้ `Supabase.instance.client.channel('board_${board.id}')` + `onBroadcast(event: 'update')`
    - [x] เก็บ `_broadcastUpdate(String boardId)` ไว้สำหรับส่ง broadcast บอกคนอื่น
    - [x] ลบ polling logic ออกทั้งหมด
- **Why:** ใช้ของที่มีอยู่แล้ว (Supabase Broadcast) แทน WebSocket ผ่าน Worker ที่เคยทำให้ติด limit

### Task 85.2: Add TeamHandlers Broadcast Stream
- **Status:** [x] Done
- **Target File:** `lib/ai_agent/tools/handlers/team_handlers.dart`
- **Action:**
    - [x] เพิ่ม `StreamController<String>.broadcast()` ชื่อ `_boardChangeController`
    - [x] เพิ่ม `_notifyBoardChange(String boardId)` ที่ emit stream หลัง `ApiCloudflare.insertTask/updateTask/deleteTask`
    - [x] เรียก `_notifyBoardChange()` ใน `handleCreate`, `handleUpdate`, `handleDelete`, `handleMove`
- **Why:** เมื่อ AI (MistyAgent) สร้าง/แก้/ลบ task สำเร็จ → ต้องมีสัญญาณบอก StateTasks ให้ fetch ใหม่ + broadcast บอกคนอื่น

### Task 85.3: Wire StateTasks to TeamHandlers Stream
- **Status:** [x] Done
- **Target File:** `lib/state_managers/state_tasks.dart`
- **Action:**
    - [x] ใน constructor `StateTasks()` ฟัง `TeamHandlers.onBoardChange`
    - [x] เมื่อได้รับ event → `fetchTasksForBoard(board, silent: true)`
    - [x] หลัง fetch เสร็จ → เรียก `_broadcastUpdate(boardId)` เพื่อบอก client อื่นๆ ผ่าน Supabase
- **Why:** คนที่คุยกับ AI เห็นงานใหม่ทันที + คนอื่นบน board เดียวกันก็ได้รับ broadcast (ถ้าเปิดหน้า Kanban อยู่)

### Task 85.4: Build & Deploy
- **Status:** [x] Done
- **Action:** `flutter build web --release` + `wrangler pages deploy`
- **Frontend:** https://c02488a0.calenda-app-web.pages.dev
- **Goal:** Frontend deploy สำเร็จ พร้อมระบบ AI sync ผ่าน Supabase Broadcast

### Task 85.5: Hotfix — AI Task Not Refreshing + Web IME Focus Loss
- **Status:** [x] Done
- **Target Files:**
    - `lib/state_managers/state_tasks.dart`
    - `lib/ui/common/ime_safe_text_field.dart`
    - `lib/ui/chat/widgets/aether_chat_view.dart`
- **Action:**
    - [x] แก้ stream listener ใน `StateTasks` ให้ไม่พึ่ง `_stateBoards` (ที่อาจเป็น null ตอน AI สร้าง task)
    - [x] เพิ่ม Timer-based focus restoration ใน `ImeSafeTextField` (จับ focus loss โดยตรง ไม่ใช่แค่ parent rebuild)
    - [x] รื้อโครงสร้าง `AetherChatView` ให้ใช้ `Selector` แทน `context.watch<StateChat>()` — input area ไม่ rebuild ตอน isTyping เปลี่ยน
- **Why:**
    - AI สร้าง task แล้ว board ไม่อัปเดต → `_stateBoards` เป็น null ตอน stream event มาถึง → fetch ไม่ทำงาน
    - Focus หลุดตอนสลับภาษา → `AetherChatView` rebuild ทั้งหน้าทุกครั้งที่ `StateChat.notifyListeners()` เรียก (รวมตอน isTyping)

### Task 85.6: Cross-Page Sync Fixes (Kanban, Calendar, Task Edit)
- **Status:** [x] Done
- **Target Files:**
    - `lib/ui/kanban/kanban_page.dart`
    - `lib/ui/kanban/widgets/task_edit_modal.dart`
    - `lib/ui/calendar/calendar_page.dart`
- **Action:**
    - [x] `kanban_page.dart`: เอา `_taskStateRef?.unsubscribeBoard()` ออกจาก `dispose()` → channel ค้างไว้เพื่อให้ chat ส่ง broadcast ได้
    - [x] `task_edit_modal.dart`: เพิ่ม `_refreshTaskData()` ใน `initState` → fetch งานล่าสุดจาก API ก่อนเปิด popup
    - [x] `calendar_page.dart`: เพิ่ม `fetchAllTasks()` ใน `initState` → ดึงข้อมูลงานใหม่ตลอดตอนเข้าหน้าปฏิทิน
- **Why:**
    - ย้ายคอลัมน์/แก้ไขการ์ด/ลบงาน → broadcast ไม่ถึงคนอื่นเพราะ channel ถูก unsubscribe ตอนออกจาก Kanban
    - เปิด edit popup → ข้อมูลการ์ดเป็น stale (คนอื่นแก้ไปแล้วแต่ไม่เห็น)
    - เปิดหน้าปฏิทิน → งานไม่อัปเดตเพราะไม่มีการ fetch

## Phase 82: Universal File Upload & Input Focus Sovereignty

> **Workflow Mandate:** อัปเดต Task Graph และ Re-Sync ทุกครั้งที่จบ 1 Task ย่อย (Rule 0 & V2.1 Protocol)
> **Architecture Mandate:** รองรับไฟล์ทุกประเภท (Multimodal) และรักษา Focus ช่องพิมพ์บน Desktop/Web

### Task 82.1: Codebase Exploration (Upload & Input Focus)
- **Status:** [x] Done
- **Action:** สำรวจ `state_chat.dart`, `chat_input.dart`, `misty_agent.dart`, `chat_bubbles.dart`, `api_cloudflare.dart`
- **Findings:**
    - `pickFiles()` ใช้ `ImagePicker().pickMultiImage()` จำกัดแค่รูปภาพ
    - `uploadImage()` endpoint เป็น Multipart generic รองรับทุกไฟล์อยู่แล้ว
    - `misty_agent.dart` กรอง attachments แค่ `image/` ส่งเป็น `image_url`
    - `chat_bubbles.dart` แสดง attachments เป็น `Image.network` ทั้งหมด
    - `AetherChatView` / `AetherChatInput` ไม่มี `FocusNode` ทำให้สลับภาษาแล้ว focus หลุดบน Web
- **Why:** วิเคราะห์ root cause ก่อนแก้ไขเพื่อไม่ให้พลาด

### Task 82.2: State & Backend - Universal File Picker & Upload Pipeline
- **Status:** [x] Done
- **Target File:** `lib/state_managers/state_chat.dart`
- **Action:**
    - [ ] เปลี่ยน `_pendingFiles` จาก `List<XFile>` เป็น `List<PlatformFile>` (file_picker)
    - [ ] แก้ `pickFiles()` ให้ใช้ `FilePicker.platform.pickFiles(allowMultiple: true, withData: true, type: FileType.any)`
    - [ ] แก้ `sendMessageToAI()` ให้อ่าน bytes จาก `PlatformFile.bytes` แทน `XFile.readAsBytes()`
    - [ ] อัปเดต MIME type lookup จาก file extension สำหรับไฟล์ที่ไม่มี mimeType
- **Why:** ปลดล็อกให้ผู้ใช้เลือกไฟล์ทุกประเภท (PDF, Audio, Video, ฯลฯ)

### Task 82.3: AI Agent - Multimodal Attachment Processing
- **Status:** [ ] To Do
- **Target File:** `lib/ai_agent/core/misty_agent.dart`
- **Action:**
    - [ ] แก้ `processMessage` ให้ส่งรูปภาพเป็น `image_url` + base64 เหมือนเดิม
    - [ ] ส่งไฟล์อื่นๆ (PDF, Audio, ฯลฯ) เป็น `image_url` + data URI พร้อม MIME type ที่ถูกต้อง
    - [ ] เพิ่มข้อความอธิบายไฟล์แนบใน text content เพื่อความชัดเจน
- **Why:** ให้ AI รับรู้และวิเคราะห์ไฟล์ทุกประเภทที่โมเดลรองรับ

### Task 82.4: UI - Focus Retention & File Type Icons
- **Status:** [x] Done
- **Target File:** `lib/ui/chat/widgets/aether_chat_view.dart`, `lib/ui/chat/widgets/chat_input.dart`, `lib/ui/chat/widgets/chat_bubbles.dart`
- **Action:**
    - [ ] `aether_chat_view.dart`: เพิ่ม `FocusNode` ใน `_AetherChatViewState` และส่งลง `AetherChatInput`
    - [ ] `chat_input.dart`: รับ `FocusNode`, ใช้กับ `TextField`, แสดง Icon ตามประเภทไฟล์ (pdf, audio, etc.)
    - [ ] `chat_bubbles.dart`: แก้ `UserMessageBubble._buildAttachments` ให้แสดงไฟล์ไม่ใช่รูปเป็น Icon + ชื่อไฟล์
- **Why:** แก้ปัญหา focus หลุดตอนสลับภาษาบน Desktop และแสดงไฟล์แนบทุกประเภทอย่างถูกต้อง

### Task 82.5: Forensic Audit & Production Build
- **Status:** [x] Done
- **Action:** รัน `flutter analyze` ตรวจสอบ 5 ไฟล์ที่แก้ไข
- **Result:** ไม่พบ Error ใหม่ (0 errors) มีเฉพาะ Warnings/Info ที่เป็น Technical Debt เดิมของโปรเจกต์
- **Goal:** ระบบอัปโหลดไฟล์ครบวงจรและช่องพิมพ์เสถียรบน Web

## Phase 83: Audio Transcription & IME Focus Fix (Hotfix)

> **Workflow Mandate:** อัปเดต Task Graph และ Re-Sync ทุกครั้งที่จบ 1 Task ย่อย

### Task 83.1: Audio Transcription Support
- **Status:** [x] Done
- **Target File:** `lib/ai_agent/core/misty_agent.dart`
- **Action:** เปลี่ยนการส่งไฟล์จาก "Text URL Reference" เป็น "Inline Data URI (base64)" สำหรับทุกประเภท (Image, Audio, Video, PDF)
- **Why:** Gemini API รองรับ Audio Input ผ่าน `inline_data` / `image_url` ด้วย data URI แต่ไม่สามารถเข้าถึง external URL ได้โดยตรง การส่งแค่ `[File: name | URL: ...]` ทำให้ AI มองไม่เห็นเนื้อหาเสียง

### Task 83.2: IME Focus Loss Fix (Web)
- **Status:** [x] Done
- **Target File:** `lib/ui/chat/widgets/chat_input.dart`
- **Action:** แปลง `AetherChatInput` จาก `StatelessWidget` เป็น `StatefulWidget` พร้อม `AutomaticKeepAliveClientMixin`
- **Why:** StatelessWidget ถูกสร้างใหม่ทุกครั้งที่ Parent rebuild จาก `StateChat` ทำให้ TextField สูญเสีย Focus ขณะใช้ IME (สลับภาษา) บน Web

### Task 83.3: Deploy Hotfix
- **Status:** [x] Done
- **Action:** Deploy Backend Worker + Build/Deploy Frontend Pages
- **Backend:** https://calenda-api-worker.jitkhon1979.workers.dev
- **Frontend:** https://39d0df70.calenda-app-web.pages.dev

## Phase 84: Deep Common Architecture (ImeSafeTextField)

> **Workflow Mandate:** อัปเดต Task Graph และ Re-Sync ทุกครั้งที่จบ 1 Task ย่อย

### Task 84.1: Create Common ImeSafeTextField Widget
- **Status:** [x] Done
- **Target File (New):** `lib/ui/common/ime_safe_text_field.dart`
- **Action:** สร้าง `StatefulWidget` พร้อม `AutomaticKeepAliveClientMixin` ที่ wrap `TextField` ทุก property
- **Why:** แก้ปัญหา Focus หลุดบน Web ให้กับ TextField ทุกจุดในแอป โดยไม่ต้องแก้ซ้ำในแต่ละไฟล์

### Task 84.2: Replace All TextFields with ImeSafeTextField
- **Status:** [x] Done
- **Target Files:** 10 ไฟล์ทั่วแอป
- **Action:** แทนที่ `TextField` เป็น `ImeSafeTextField` ในทุกหน้า (Chat, Kanban, Boards, Dashboard, Drafts, Task Edit, Column Edit, Board Edit, Member Role)
- **Why:** ทุกช่องพิมพ์ในแอปได้รับการป้องกัน Focus หลุดบน Web โดยอัตโนมัติ

### Task 84.3: Production Build & Deploy
- **Status:** [x] Done
- **Action:** `flutter build web --release` + `wrangler pages deploy`
- **Frontend:** https://e5b63881.calenda-app-web.pages.dev
- **Action:** รัน `flutter analyze` และตรวจสอบ syntax ทุกไฟล์ที่แก้ไข
- **Goal:** ระบบอัปโหลดไฟล์ครบวงจรและช่องพิมพ์เสถียรบน Web
# Task Graph: Final Strategic Refinement & Bulk Operations

## Phase 56: Hyper-Modular Kanban Architecture (Zero-Failure)

### Task 56.1: Architectural Scaffolding & Monolith Destruction
- **Status:** [x] Done

- **Target File:** `lib/ui/kanban/kanban_page.dart`
- **Actions:**
    - [x] รื้อไลบรารี `AppFlowyBoard` และ Controller เก่าทิ้งทั้งหมด
    - [x] ออกแบบ `kanban_page.dart` ให้เหลือแค่โครงสร้างหลัก: Header, แถบเครื่องมือ Bulk, และ `ListView.builder(scrollDirection: Axis.horizontal)`
    - [x] ติดตั้ง `Scrollbar` แนวนอนที่ควบคุม `ListView` นี้
- **Reason:** ควบคุมให้ไฟล์หลักทำหน้าที่แค่ "คอนเทนเนอร์" เพื่อไม่ให้โค้ดบวม และแก้ปัญหาบาร์เลื่อนแนวนอนแต่เนิ่นๆ

### Task 56.2: Create Standalone Kanban Column (`kanban_column.dart`)
- **Status:** [x] Done
- **Target File (New):** `lib/ui/kanban/widgets/kanban_column.dart`
- **Actions:**
    - [x] สร้างไฟล์ใหม่เพื่อรับผิดชอบการวาด 1 คอลัมน์โดยเฉพาะ
    - [x] สร้างคลาส `KanbanColumnWidget` หุ้มด้วย `DragTarget<TaskModel>` เพื่อรับการ์ดที่ถูกลากมา
    - [x] ภายในคอลัมน์ใช้ `Consumer<StateTasks>` เพื่อดึงเฉพาะงานของคอลัมน์นี้มาวาดเป็น `ListView.builder` แนวตั้ง
- **Reason:** การแยกไฟล์ตั้งแต่แรกรับประกันว่าโค้ดจะไม่รก และทำให้การอัปเดตงานในคอลัมน์หนึ่ง ไม่ไปกระเทือนการวาดของคอลัมน์อื่น (Zero Scroll Jump)

### Task 56.3: Create Standalone Task Card (`kanban_card.dart`)
- **Status:** [x] Done
- **Target File (New):** `lib/ui/kanban/widgets/kanban_card.dart`
- **Actions:**
    - [x] ย้ายโค้ด `KanbanTaskCard` จากไฟล์รวมมาไว้ในไฟล์ของตัวเอง
    - [x] หุ้มการ์ดด้วย `LongPressDraggable<TaskModel>` เพื่อให้ลากได้ พร้อมสร้าง UI ขณะลาก (Ghost card)
    - [x] จัดระเบียบ Z-Index ของ Checkbox ให้กดติดเสมอ
- **Reason:** แยกความซับซ้อนของ UI การ์ด (ที่มีทั้งลาเบล, รูปคน, เช็คบ็อกซ์) ออกมา เพื่อการจัดการ (Maintainability) ที่ง่ายที่สุด

### Task 56.4: Assembly, Interaction Sync & Clean up
- **Status:** [x] Done
- **Target File:** หลายไฟล์ (Clean up)
- **Actions:**
    - [x] ประกอบ `KanbanColumnWidget` เข้าไปในหน้าหลัก และเสียบ `KanbanTaskCard` เข้าไปในคอลัมน์
    - [x] ยืนยันการทำงานของระบบ Bulk Select (การเลือกหลายชิ้น) ข้ามคอลัมน์
    - [x] ลบโค้ดที่ไม่ได้ใช้แล้วออกจาก `kanban_widgets.dart` เดิม
- **Reason:** นำชิ้นส่วนที่สร้างไว้มาประกอบกันให้สมบูรณ์

### Task 56.5: Production Build Validation
- **Status:** [x] Done
- **Action:** `flutter build web --release`
- **Goal:** ยืนยันว่าโครงสร้างใหม่คอมไพล์ผ่าน ไม่มี Syntax error และทำงานได้เสถียรจริง

## Phase 57: Absolute Sync & Aesthetic Restoration (Emergency Fix)

### Task 57.1: Foundation - Fix API CORS & Connection Issues
- **Status:** [x] Done
- **Target File:** `cloudflare_backend/cloudflare_worker.js` (หากจำเป็นต้องแก้ CORS headers) หรือตรวจสอบ URL ใน `lib/databases/api_cloudflare.dart`
- **Function/Action:** 
    - [x] ตรวจสอบฟังก์ชันดึงภาพ/ข้อมูลที่ทำให้เกิด `CORS policy: No 'Access-Control-Allow-Origin'`
    - [x] ยืนยัน URL ของ WebSocket `wss://calenda-api-worker...` ว่าทำงานถูกต้อง และจัดการ Connection Error (`Uncaught Error`)
- **Reason:** การเชื่อมต่อ API พื้นฐานต้องผ่านก่อน ลอจิก Real-time ถึงจะทำงานได้

### Task 57.2: State - Board Structural Real-time Sync (เพิ่ม/ลบคอลัมน์)
- **Status:** [x] Done
- **Target File:** `lib/state_managers/state_tasks.dart` และ `lib/ui/kanban/kanban_page.dart`
- **Function/Action:** 
    - [x] ใน `state_tasks.dart`: ตรวจสอบ Event `board_update` ใน WebSocket Listener ว่าสั่งรีเฟรชบอร์ดสำเร็จหรือไม่
    - [x] ใน `kanban_page.dart`: หุ้ม `ListView.builder` ที่วาดคอลัมน์ด้วย `Consumer<StateBoards>` เพื่อให้ UI วาดคอลัมน์ใหม่ทันทีที่ StateBoards ถูกอัปเดตจาก WebSocket
- **Reason:** เพื่อแก้ปัญหาที่เพื่อนเพิ่ม/ลบคอลัมน์แล้วหน้าจอของเราไม่เห็นจนกว่าจะรีเฟรช

### Task 57.3: State - Task Content Real-time Sync (แก้ไขรายละเอียดงาน)
- **Status:** [x] Done
- **Target File:** `lib/state_managers/state_tasks.dart`
- **Function/Action:** 
    - [x] ใน `subscribeBoard`: เมื่อได้รับ Event ใดๆ (เช่น `task_update`) ต้องแน่ใจว่าฟังก์ชัน `fetchTasksForBoard(board, silent: true)` ถูกเรียกอย่างถูกต้องและส่งผลให้ `_tasksByBoard` อัปเดต
    - [x] ตรวจสอบให้แน่ใจว่า `notifyListeners()` ถูกเรียกเพื่อส่งสัญญาณไปที่ `Consumer<StateTasks>` ในการ์ดงาน
- **Reason:** เพื่อให้การแก้ไข Text ภายในการ์ด (เช่น อัปเดต Description) ไปโผล่ที่หน้าจอของเพื่อนทันที

### Task 57.4: Persistence - Reorder Order Saving (ลากสลับตำแหน่ง)
- **Status:** [x] Done
- **Target File:** `lib/state_managers/state_tasks.dart` และ `lib/databases/api_cloudflare.dart`
- **Function/Action:** 
    - [x] ใน `state_tasks.dart -> reorderWithinColumn`: เพิ่มการยิง API `ApiCloudflare.updateTaskOrder(...)` บันทึกลำดับลง Database
    - [x] เพิ่มลอจิกวนลูปประกอบ `updates` รายการไอดีและลำดับ
- **Reason:** เพื่อแก้ปัญหา "ลากสลับที่แล้วพอกระพริบก็เด้งกลับไปที่เดิม"

### Task 57.5: Aesthetics - Restore Premium Card Design
- **Status:** [x] Done
- **Target File:** `lib/ui/kanban/widgets/kanban_card.dart`
- **Function/Action:** 
    - [x] ใน `KanbanTaskCard.build`: ปรับแก้ TextStyle ของ `task.title` ให้ใช้ `GlassText.headlineLG()`
    - [x] ปรับ Padding รอบการ์ดให้กว้างขึ้น ดูโปร่งสบาย
    - [x] ปรับแก้สี `decoration` และฟอนต์ขณะลาก
- **Reason:** กู้คืนสุนทรียภาพ (UX/UI) ที่ขาดหายไประหว่างการแยกระบบใน Phase 56 ให้กลับมาสวยเหมือนเดิม

## Phase 58: Kanban Restoration & Real-time Perfection (Audited)

> **Workflow Mandate:** หลังจบทุก Task ย่อย ผมจะทำการ 1) อัปเดต Task Graph 2) อ่านไฟล์ 3 ไฟล์หลักเพื่อ Re-sync ความจำทุกครั้ง
> **Architecture Mandate:** ห้ามใช้ Plan Mode เสนอแผนผ่านไฟล์ .md เท่านั้น

### Task 58.1: Structural Restoration - Unblock Drag & Drop
- **Status:** [x] Done
- **Target File:** `lib/ui/kanban/widgets/kanban_card.dart`
- **Function:** `KanbanTaskCard.build`
- **Action:** 
    - [x] ย้าย `LongPressDraggable` จากไฟล์คอลัมน์มาไว้ในไฟล์การ์ด และหุ้มไว้ที่เลเยอร์บนสุดของ `Stack`
    - [x] ปรับแก้ `feedback` ให้เป็น Ghost Card ที่มีขนาดและเงาพรีเมียม
- **Why:** สาเหตุที่ลากไม่ได้เป็นเพราะ `InkWell` ในการ์ดไปแย่งจับสัญญาณสัมผัส ทำให้ `Draggable` ที่อยู่ด้านนอกไม่ทำงาน

### Task 58.2: Database Persistence - Secure Ordering & Sync
- **Status:** [x] Done
- **Target File:** `lib/state_managers/state_tasks.dart`
- **Function:** `reorderWithinColumn`
- **Action:** 
    - [x] บังคับให้วนลูปยิง API `updateTaskOrder` ทันทีที่สลับตำแหน่ง เพื่อให้ลำดับงานนิ่งสนิทข้ามเครื่อง
- **Why:** ป้องกันอาการการ์ด "เด้งกลับ" เมื่อเกิดการซิงค์ข้อมูล WebSocket


### Task 58.3: State Atomic Sync - Fix Content Non-Update
- **Status:** [x] Done
- **Target File:** `lib/state_managers/state_tasks.dart`
- **Action:** 
    - [x] ใน WebSocket Listener: เปลี่ยนจาก "โหลดใหม่ยกแผง" เป็น "Atomic Update" (อัปเดตเฉพาะงานที่ได้รับแจ้งมา)
- **Why:** แก้ไขปัญหา "แก้รายละเอียดงานแล้วเพื่อนไม่เห็น" และลดอาการกระตุกของหน้าจอ

### Task 58.4: Aesthetic Restoration - The Premium Feel
- **Status:** [x] Done
- **Target File:** `lib/ui/kanban/widgets/kanban_card.dart`
- **Action:** 
    - [x] คืนค่า `GlassText.headlineLG()` ตัวหนา w900 สำหรับชื่องาน
    - [x] ขยาย Padding รอบการ์ดเป็น 24px และปรับสไตล์ตอนงาน "Done" ให้สวยงาม
- **Why:** กู้คืนสุนทรียภาพระดับพรีเมียมให้กลับมา 100%

## Phase 59: Nuclear Connectivity & Gesture Restoration (The Final Fix)

> **Workflow Mandate:** หลังจบทุก Task ย่อย ผมจะทำการ 1) อัปเดต Task Graph 2) อ่านไฟล์ 3 ไฟล์หลักเพื่อ Re-sync ความจำทุกครั้ง
> **Architecture Mandate:** ห้ามใช้ Plan Mode เสนอแผนผ่านไฟล์ .md เท่านั้น

### Task 59.1: WebSocket Nuclear Fix (Handshake & Stability)
- **Status:** [x] Done
- **Target File:** `cloudflare_backend/cloudflare_worker.js`
- **Action:** 
    - [x] ปรับการเช็ค Header `Upgrade` ให้เป็น `.toLowerCase() === 'websocket'` เพื่อรองรับทุก Browser
    - [x] ตรวจสอบการส่งกลับ Header `Sec-WebSocket-Accept` ให้แม่นยำตามมาตรฐาน DO
- **Target File:** `lib/state_managers/state_tasks.dart`
- **Action:** 
    - [x] หุ้ม `WebSocketChannel.connect` ด้วย `try-catch` ที่ครอบคลุมถึงระดับ Listener
    - [x] ปรับลอจิก `_scheduleReconnect` ให้มีระบบ Delay ที่เสถียรขึ้น (Exponential Backoff) ป้องกันอาการ `Uncaught Error` วนลูป
- **Why:** เพื่อแก้ปัญหา "เชื่อมต่อ WebSocket ไม่ติด" ทำให้ระบบไม่เรียลไทม์

### Task 59.2: Drag & Drop Gesture Fix (Unblock the Card)
- **Status:** [x] Done
- **Target File:** `lib/ui/kanban/widgets/kanban_card.dart`
- **Action:** 
    - [x] ย้าย `Draggable` มาเป็น Wrapper ชั้นนอกสุด
    - [x] ปรับลอจิกการรับสัญญาณสัมผัสให้ลากได้จริง 100% โดยไม่โดนปุ่มกดในเครื่องขวาง
- **Why:** เพื่อแก้ปัญหา "ลากการ์ดไม่ได้"
### Task 59.3: Structural Real-time assembly (Column Sync)
- **Status:** [x] Done
- **Target File:** `lib/ui/kanban/kanban_page.dart`
- **Action:** 
    - [x] หุ้ม `ListView.builder` (แนวนอน) ด้วย `Consumer<StateBoards>` เพื่อรับสัญญาณ `board_update` และอัปเดตจำนวนคอลัมน์ทันที
- **Why:** เพื่อให้การเปลี่ยนแปลงโครงสร้างบอร์ดจากเพื่อนร่วมทีมโผล่ขึ้นมาทันที

### Task 59.4: Global Verified Build & Stress Test
- **Status:** [x] Done
- **Action:** `flutter build web` -> Deploy -> ทดสอบลากวางข้ามเครื่อง
- **Goal:** ปิดตำนานปัญหาหน้า Kanban พังถาวร

## Phase 60: Instant Performance & Sovereign Gesture (Speed Fix)

> **Workflow Mandate:** หลังจบทุก Task ย่อย ผมจะทำการ 1) อัปเดต Task Graph 2) อ่านไฟล์ 3 ไฟล์หลักเพื่อ Re-sync ความจำทุกครั้ง
> **Architecture Mandate:** ห้ามใช้ Plan Mode เสนอแผนผ่านไฟล์ .md เท่านั้น

### Task 60.1: Backend - Rich Payload Broadcast
- **Status:** [x] Done
- **Target File:** `cloudflare_backend/cloudflare_worker.js`
- **Action:** 
    - [x] ปรับปรุงฟังก์ชัน `notifyBoard` ให้ส่ง Object ของงานที่ถูกแก้ไปพร้อมสัญญาณ WebSocket
    - [x] อัปเดตจุดที่เรียกใช้ `notifyBoard` ทั้งหมดใน API (Create, Update, Order, Status) ให้แนบข้อมูลงาน
- **Why:** เพื่อให้แอปเครื่องอื่นอัปเดตได้ทันทีจากข้อมูลในสัญญาณ ไม่ต้องเสียเวลาไปยิง API Fetch โหลดใหม่ทั้งบอร์ด

### Task 60.2: Frontend - Direct Injection Sync
- **Status:** [x] Done
- **Target File:** `lib/state_managers/state_tasks.dart`
- **Action:** 
    - [x] แก้ไข WebSocket Listener: เมื่อได้รับข้อมูลงานมาใน Payload ให้ทำการเขียนทับ (Inject) ลงใน `_tasksByBoard` ทันที
    - [x] เรียก `notifyListeners()` เฉพาะจุด เพื่อให้หน้าจอวาดใหม่แบบสายฟ้าแลบ (Instant Update)
- **Why:** แก้ปัญหาความหน่วง (Latency) ของ Real-time ให้เร็วขึ้นกว่าเดิม 5-10 เท่า

### Task 60.3: Structural Assembly - Sovereign Drag Handle
- **Status:** [x] Done
- **Target File:** `lib/ui/kanban/widgets/kanban_card.dart`
- **Action:** 
    - [x] เพิ่มไอคอน "ลาก" (เช่น `Icons.drag_indicator`) ไว้ที่มุมการ์ด
    - [x] หุ้มเฉพาะไอคอนนี้ด้วย `Draggable` เพื่อให้การลาก "ทำงานได้แน่นอน" ไม่ตีกับปุ่มกดอื่น
- **Why:** เพื่อแก้ปัญหา "ลากการ์ดไม่ออก" ให้หายขาดถาวร โดยมีจุดจับสัมผัสที่ชัดเจน

### Task 60.4: Production Stress Test & Handshake Verify
- **Status:** [x] Done
- **Action:** ตรวจสอบลอจิก Handshake อีกครั้งผ่าน Browser Console และทดสอบความเร็วการซิงค์

## Phase 61: The Final Structural Integrity (Kanban Fix)

> **Workflow Mandate:** หลังจบทุก Task ย่อย ผมจะทำการ 1) อัปเดต Task Graph 2) อ่านไฟล์ 3 ไฟล์หลักเพื่อ Re-sync ความจำทุกครั้ง
> **Architecture Mandate:** ห้ามใช้ Plan Mode เสนอแผนผ่านไฟล์ .md เท่านั้น

### Task 61.1: Sovereign Scrollbar Fix (ล็อคบาร์เลื่อน)
- **Status:** [x] Done
- **Target File:** `lib/ui/kanban/kanban_page.dart`
- **Action:** 
    - [x] ย้าย `Scrollbar` และ `ScrollController` ออกไปอยู่นอกขอบเขตของ `Consumer<StateBoards>`
    - [x] บังคับให้บาร์เลื่อนแนวนอนแสดงผลถาวร (Always Shown)
- **Why:** เพื่อไม่ให้บาร์เลื่อนหายไปเวลาหน้าจอ Rebuild จากการอัปเดตข้อมูล Real-time

### Task 61.2: Cross-Provider WebSocket Sync (แก้คอลัมน์ไม่อัปเดต)
- **Status:** [x] Done
- **Target File:** `lib/state_managers/state_tasks.dart`
- **Action:** 
    - [x] ใน WebSocket Listener: เมื่อได้รับ `board_update` ให้สั่งเรียก `_stateBoards?.fetchAllBoards()` และรอจนเสร็จ (Await)
- **Why:** แก้ปัญหาเพื่อนเพิ่ม/ลบคอลัมน์แล้วหน้าจอของเราไม่อัปเดตตามทันที

### Task 61.3: Robust WebSocket Handshake & Worker Clean-up
- **Status:** [x] Done
- **Target File:** `cloudflare_backend/cloudflare_worker.js`
- **Action:** 
    - [x] ปรับปรุงการตอบกลับ 101 Switching Protocols ให้รองรับทุก Browser (CORS headers)
    - [x] ลดภาระ Database โดยการใช้ข้อมูลที่ส่งมาประกอบ Payload ทันที
- **Why:** แก้ปัญหาความหน่วงและทำให้ระบบ Real-time กลับมาไวระดับมิลลิวินาที

## Phase 62: Total Resilience & Hybrid Sync (The UX Finality)

> **Workflow Mandate:** หลังจบทุก Task ย่อย ผมจะทำการ 1) อัปเดต Task Graph 2) อ่านไฟล์ 3 ไฟล์หลักเพื่อ Re-sync ความจำทุกครั้ง
> **Architecture Mandate:** ห้ามใช้ Plan Mode เสนอแผนผ่านไฟล์ .md เท่านั้น

### Task 62.1: Hybrid Polling Implementation (แก้คอลัมน์ไม่ขึ้น)
- **Status:** [x] Done
- **Target File:** `lib/state_managers/state_tasks.dart`
- **Action:** 
    - [x] ในฟังก์ชัน `_startPolling`: เพิ่มคำสั่ง `await _stateBoards?.fetchAllBoards()` นอกเหนือจากดึงข้อมูลงาน
- **Why:** เพื่อให้แม้ในกรณีที่ WebSocket เชื่อมต่อไม่ติด (Polling mode) โครงสร้างคอลัมน์ก็จะยังอัปเดตทุก 10 วินาที แก้ปัญหา "เพื่อนเพิ่มคอลัมน์แล้วเราไม่เห็น"

### Task 62.2: Scrollbar Physics Restoration (กู้ชีพแถบเลื่อน Web)
- **Status:** [x] Done
- **Target File:** `lib/ui/kanban/kanban_page.dart`
- **Action:** 
    - [x] ใส่ `physics: const AlwaysScrollableScrollPhysics()` ให้กับ `ListView.builder` แนวนอน
    - [x] เพิ่ม `Key` เฉพาะเจาะจงให้ `Scrollbar` เพื่อให้ระบบจดจำสถานะได้แม่นยำขึ้น
- **Why:** แก้ปัญหาแถบเลื่อนแนวนอนหายไปบน Browser เมื่อมีการ Rebuild หน้าจอ

### Task 62.3: Native Universal Handshake (Worker Fix)
- **Status:** [x] Done
- **Target File:** `cloudflare_backend/cloudflare_worker.js`
- **Action:** 
    - [x] ปรับลอจิกการตอบกลับ 101 ให้ "เรียบง่ายที่สุด" (Native DO pattern) เพื่อป้องกัน Browser Security บล็อกสัญญาณ
- **Why:** เพื่อพยายามกู้คืน WebSocket ให้กลับมาต่อติด 100%

### Task 62.4: Forensic State Refresh & Build
- **Status:** [x] Done
- **Action:** `flutter build web` -> Deploy -> ทดสอบการเพิ่มคอลัมน์ในโหมดจำลองเน็ตหลุด

## Phase 63: Structural Core Correction (Nuclear Logic Fix)

> **Workflow Mandate:** หลังจบทุก Task ย่อย ผมจะทำการ 1) อัปเดต Task Graph 2) อ่านไฟล์ 3 ไฟล์หลักเพื่อ Re-sync ความจำ 3) **รีเช็คโค้ดที่แก้ไปว่าตรงตามแผนจริงไหม**
> **Architecture Mandate:** ห้ามใช้ Plan Mode เสนอแผนผ่านไฟล์ .md เท่านั้น

### Task 63.1: Deep Metadata Sync (แก้คอลัมน์เด้ง/ไม่อัปเดต)
- **Status:** [x] Done
- **Target File:** `lib/state_managers/state_tasks.dart`
- **Action:** 
    - [x] ปรับฟังก์ชัน `fetchTasksForBoard` ให้ Lookup หาบอร์ดล่าสุดจาก `StateBoards` แทนการใช้ Parameter เก่า
    - [x] หุ้ม WebSocket Listener ด้วยระบบดักจับ Error ที่รัดกุมกว่าเดิมเพื่อหยุด `Uncaught Error`
- **Why:** เพื่อแก้ปัญหา `Status mismatch` ที่เกิดจากแอปถือโครงสร้างบอร์ดเก่า ทำให้งานเด้งไปผิดคอลัมน์

### Task 63.2: Universal Scroll Signal (กู้ชีพบาร์เลื่อน Web)
- **Status:** [x] Done
- **Target File:** `lib/ui/kanban/kanban_page.dart`
- **Action:** 
    - [x] เปลี่ยน `notificationPredicate` ของ `Scrollbar` ให้เป็น `(_) => true` (รับสัญญาณจากทุกระดับความลึก)
- **Why:** เพื่อให้แถบเลื่อนแนวนอนบน Web เห็นสัญญาณการเลื่อนที่ส่งมาจาก `ListView` ภายใต้ `Consumer`

### Task 63.3: Minimalist Cloudflare DO Handshake
- **Status:** [x] Done
- **Target File:** `cloudflare_backend/cloudflare_worker.js`
- **Action:** 
    - [x] รื้อ Headers การตอบกลับ 101 ให้เหลือเพียงค่าที่จำเป็นสูงสุด เพื่อป้องกัน Browser ปฏิเสธการเชื่อมต่อ
- **Why:** เพื่อกู้คืน WebSocket ให้กลับมาใช้งานได้จริงถาวร (เลิกใช้ Polling)

## Phase 64: High-Velocity Delta Engine (Efficiency Overhaul)

> **Workflow Mandate:** หลังจบทุก Task ย่อย ผมจะทำการ 1) อัปเดต Task Graph 2) อ่านไฟล์ 3 ไฟล์หลักเพื่อ Re-sync ความจำ 3) **รีเช็คโค้ดที่แก้ไปว่าตรงตามแผนจริงไหม**
> **Architecture Mandate:** ห้ามใช้ Plan Mode เสนอแผนผ่านไฟล์ .md เท่านั้น

### Task 64.1: Backend - Zero-Latency Rich Broadcast
- **Status:** [x] Done
- **Target File:** `cloudflare_backend/cloudflare_worker.js`
- **Action:** 
    - [x] ปรับปรุงจุดส่ง `notifyBoard` ทั้งหมดให้เลิกใช้ `SELECT` จาก Database ซ้ำซ้อน
    - [x] ใช้ข้อมูลจาก Request Body มาประกอบร่างเป็น JSON Payload ทันทีเพื่อส่งออก WebSocket
- **Why:** ลดความหน่วง (Latency) ฝั่ง Server ลง 100-200ms และลดภาระ Database

### Task 64.2: State - Surgical ID-Subscription Engine
- **Status:** [x] Done
- **Target File:** `lib/state_managers/state_tasks.dart`
- **Action:** 
    - [x] เพิ่ม `Map<String, ValueNotifier<TaskModel>> _taskNotifiers` สำหรับเก็บตัวนำสัญญาณแยกราย ID
    - [x] แก้ไข WebSocket Listener ให้สะกิด Notifier เฉพาะ ID ที่ได้รับข้อมูลมา แทนการเรียก `notifyListeners()` ทั้งบอร์ด
- **Why:** เปลี่ยนจากการวาดบอร์ดใหม่ยกแผง (Heavy Rebuild) เป็นการวาดใหม่แค่ 1 การ์ด (Instant UI)

### Task 64.3: UI - Reactive Card Refactor
- **Status:** [x] Done
- **Target File:** `lib/ui/kanban/widgets/kanban_card.dart`
- **Action:** 
    - [x] ปรับให้รับค่า Notifier จาก State และใช้ `ValueListenableBuilder` หุ้มเนื้อหาการ์ด
- **Why:** เพื่อให้แอนิเมชันการอัปเดตลื่นไหลเหมือนใช้ไลบรารีสำเร็จรูป

### Task 64.4: Metadata Isolation (Bandwidth Saving)
- **Status:** [x] Done
- **Target File:** `lib/state_managers/state_boards.dart`
- **Action:** 
    - [x] เพิ่มฟังก์ชัน `fetchSingleBoard(id)` เพื่อโหลดเฉพาะโครงสร้างบอร์ดที่เปลี่ยน
    - [x] แก้ไขแอปให้เลิกใช้ `fetchAllBoards()` ในจังหวะซิงค์ Real-time
- **Why:** ประหยัด Bandwidth 90% และทำให้บอร์ดอัปเดตโครงสร้างได้ไวขึ้น

## Phase 65: Forensic Alignment & Sync Recovery (The Final Fix)

> **Workflow Mandate:** หลังจบทุก Task ย่อย ผมจะทำการ 1) อัปเดต Task Graph 2) อ่านไฟล์ 3 ไฟล์หลักเพื่อ Re-sync ความจำ 3) **รีเช็คโค้ดที่แก้ไปว่าตรงตามแผนจริงไหม**
> **Architecture Mandate:** ห้ามใช้ Plan Mode เสนอแผนผ่านไฟล์ .md เท่านั้น

### Task 65.1: Backend Payload Normalization
- **Status:** [x] Done
- **Target File:** `cloudflare_backend/cloudflare_worker.js`
- **Action:** 
    - [x] ยกเลิก `JSON.stringify` ภายใน Object `task` ที่ส่งออก WebSocket (ส่งเป็น Native Array แทน)
- **Why:** เพื่อแก้ปัญหา Type Mismatch ที่ทำให้แอปแกะข้อมูลไม่ได้

### Task 65.2: Model Robustness (กันตาย 100%)
- **Status:** [x] Done
- **Target File:** `lib/models/task_model.dart`
- **Action:** 
    - [x] ปรับปรุง `fromJson` ให้รองรับข้อมูลทุกรูปแบบ (List, String-encoded List, int, bool)
- **Why:** เพื่อให้แอปยังทำงานได้แม้ระบบหลังบ้านจะส่งข้อมูลรูปแบบแปลกๆ มา
### Task 65.3: State Lifecycle Management
- **Status:** [x] Done
- **Target File:** `lib/state_managers/state_tasks.dart`
- **Action:** 
    - [x] รีเช็คลอจิก `_injectSingleTask` และเพิ่มระบบล้าง Notifier เมื่อลบงาน
- **Why:** ป้องกันอาการข้อมูลค้าง (Stale State) และ Memory Leak

## Phase 66: Aesthetic Notification Unification (Premium UI)

> **Workflow Mandate:** หลังจบทุก Task ย่อย ผมจะทำการ 1) อัปเดต Task Graph 2) อ่านไฟล์ 3 ไฟล์หลักเพื่อ Re-sync ความจำ 3) **รีเช็คโค้ดที่แก้ไปว่าตรงตามแผนจริงไหม**

### Task 66.1: Unified SnackBar Styling & Bulk Copy
- **Status:** [x] Done
- **Target File:** `lib/ui/kanban/kanban_page.dart`
- **Action:** 
    - [x] เปลี่ยนการแจ้งเตือนทั้งหมดในหน้า Kanban ให้เป็นสไตล์ Gold Floating SnackBar (เหมือนรีเซ็ตแชท)
    - [x] ใช้ข้อความ Uppercase และสีทองพรีเมียม (Width: 200-320 ตามเนื้อหา)
- **Why:** เพื่อความสวยงามพรีเมียมและความสอดคล้อง (Consistency) ของระบบ UI ทั้งแอป ตามที่ผู้ใช้ต้องการ

### Task 66.2: Markdown Customization & Feature Removal
- **Status:** [x] Done
- **Target File:** `lib/ui/kanban/kanban_page.dart`
- **Action:** 
    - [x] ปรับรูปแบบ Export Markdown: เปลี่ยน "Status" เป็น "Task Category" และเพิ่มฟิลด์ "Labels"
    - [x] ลบฟีเจอร์ "COPY TO" ออกจากแถบเครื่องมือ Bulk ตามความต้องการของผู้ใช้
- **Why:** ปรับแต่งรูปแบบการส่งออกข้อมูลให้ตรงตามลักษณะงาน และรักษาความคลีนของเครื่องมือ

## Phase 67: Strategic Reordering & Visual Feedback (High-Fidelity UX)

> **Workflow Mandate:** หลังจบทุก Task ย่อย ผมจะทำการ 1) อัปเดต Task Graph 2) อ่านไฟล์ 3 ไฟล์หลักเพื่อ Re-sync ความจำ 3) **รีเช็คโค้ดที่แก้ไปว่าตรงตามแผนจริงไหม**
> **Architecture Mandate:** ห้ามใช้ Plan Mode เสนอแผนผ่านไฟล์ .md เท่านั้น

### Task 67.1: Draggable Strategic Phases (Column Reordering)
- **Status:** [x] Done
- **Target File:** `lib/ui/kanban/kanban_page.dart`
- **Action:** 
    - [x] หุ้ม `KanbanColumnWidget` ด้วย `LongPressDraggable<int>` และ `DragTarget<int>`
    - [x] เมื่อมีการลากสลับคอลัมน์ ให้ทำการอัปเดต `board.columns` และสั่ง `ApiCloudflare.updateBoard` ทันที
- **Why:** เพื่อให้ผู้ใช้สามารถปรับเปลี่ยนลำดับความสำคัญของ Phase งานได้ตามสถานการณ์จริง

### Task 67.2: Visual Drop Indicators (Card Hover Feedback)
- **Status:** [x] Done
- **Target File:** `lib/ui/kanban/widgets/kanban_column.dart`
- **Action:** 
    - [x] ปรับปรุงลอจิก `DragTarget` ในรายการงานให้แสดงผล "Dashed Ghost Slot" เมื่อมีการลากงานมาจ่อ
    - [x] ใส่แอนิเมชันขยายตัว (AnimatedSize) เล็กน้อยเพื่อให้ดูพรีเมียม
- **Why:** เพื่อให้ผู้ใช้เห็นจุดที่จะวางงานได้อย่างแม่นยำ ลดความผิดพลาดและเพิ่มความมั่นใจในการใช้งาน (Visual Confirmation)

### Task 67.3: Production Stability Build
- **Status:** [x] Done
- **Action:** `flutter build web` -> Deploy -> ทดสอบการลากสลับคอลัมน์ข้ามเครื่อง
- **Goal:** ปิดท้ายความสมบูรณ์แบบของ UX หน้า Kanban

## Phase 68: Sovereign Column Reordering & Gap Feedback (The Fix)

> **Workflow Mandate:** หลังจบทุก Task ย่อย ผมจะทำการ 1) อัปเดต Task Graph 2) อ่านไฟล์ 3 ไฟล์หลักเพื่อ Re-sync ความจำ 3) **รีเช็คโค้ดที่แก้ไปว่าตรงตามแผนจริงไหม**

### Task 68.1: Structural Fix - Column Drag Handles
- **Status:** [x] Done
- **Target File:** `lib/ui/kanban/widgets/kanban_column.dart`
- **Action:** 
    - [x] เพิ่มไอคอน `Icons.drag_indicator_rounded` ใน `KanbanColumnHeader`
    - [x] ติดตั้งระบบ `dragHandle` ให้กับคอลัมน์เพื่อความแม่นยำสูงสุด
- **Why:** เพื่อแก้ปัญหา "ลากคอลัมน์ไม่ได้" เพราะ `LongPress` บนพื้นที่ขนาดใหญ่ตีกับ Scroll สัญญาณสัมผัส

### Task 68.2: Visual Fix - Column Target Gap
- **Status:** [x] Done
- **Target File:** `lib/ui/kanban/kanban_page.dart`
- **Action:** 
    - [x] ปรับปรุง `DragTarget<int>` ใน `ListView.builder`
    - [x] เมื่อมีคอลัมน์มาจ่อ ให้แสดง **Vertical Gold Dashed Zone** (กว้าง 120px) พร้อมข้อความ "INSERT PHASE"
- **Why:** เพื่อให้ผู้ใช้เห็น "จุดหมาย" ของการย้ายคอลัมน์ได้อย่างชัดเจน (ตามความต้องการเรื่องกันตาลาย)

### Task 68.3: Universal Sync Build & Verify
- **Status:** [x] Done
- **Action:** `flutter build web` -> Deploy -> ทดสอบลากสลับคอลัมน์จริง
- **Goal:** ปิดท้ายความสมบูรณ์แบบของ UX หน้า Kanban

## Phase 69: Responsive UI Transformation (Mobile & Tablet)

> **Workflow Mandate:** หลังจบทุก Task ย่อย ผมจะทำการ 1) อัปเดต Task Graph 2) อ่านไฟล์ 3 ไฟล์หลักเพื่อ Re-sync ความจำ 3) **รีเช็คโค้ดที่แก้ไปว่าตรงตามแผนจริงไหม**
> **Architecture Mandate:** ห้ามใช้ Plan Mode เสนอแผนผ่านไฟล์ .md เท่านั้น
> **UX Mandate:** รักษา Desktop Design ให้เหมือนเดิม 100% แต่ปรับตัวให้เข้ากับ Mobile/Tablet อย่างสวยงาม

### Task 69.1: Create Responsive Utility (`responsive_layout.dart`)
- **Status:** [x] Done
- **Target File (New):** `lib/ui/common/responsive_layout.dart`
- **Action:** 
    - สร้างคลาส `Responsive` ที่มีฟังก์ชัน `isMobile`, `isTablet`, `isDesktop`
    - เพิ่ม Widget `ResponsiveLayout` ที่รับ `mobile`, `tablet`, `desktop` builders
- **Why:** เพื่อให้มีจุดจัดการลอจิกขนาดหน้าจอศูนย์กลาง ไม่ต้องเขียน `MediaQuery` ซ้ำซ้อนในหลายไฟล์

### Task 69.2: Refactor AppShell for Navigation Adaptation
- **Status:** [x] Done
- **Target File:** `lib/main.dart`
- **Action:** 
    - ใช้ `ResponsiveLayout` ใน `AppShell.build`
    - **Desktop**: ใช้ `Row` กับ `AetherSideNav` (เหมือนเดิม)
    - **Mobile/Tablet**: ใช้ `Scaffold` ที่มี `Drawer` (ใส่เนื้อหา SideNav) และ `BottomNavigationBar` เพื่อการเข้าถึงที่ง่าย
- **Why:** หน้าจอเล็กต้องการพื้นที่แนวขวางคืนมา การซ่อนเมนูใน Drawer หรือ Bottom Bar เป็นมาตรฐานที่ถูกต้อง

### Task 69.3: Dashboard Grid Responsiveness
- **Status:** [x] Done
- **Target File:** `lib/ui/dashboard/dashboard_page.dart`
- **Action:** 
    - ปรับ `crossAxisCount` ของ Grid ในหน้า Dashboard ให้เปลี่ยนตามขนาดหน้าจอ (Desktop: 3-4, Tablet: 2, Mobile: 1)
- **Why:** ป้องกันการ์ด Dashboard บีบอัดจนอ่านไม่ได้บนมือถือ

### Task 69.4: Kanban Board Adaptation
- **Status:** [x] Done
- **Target File:** `lib/ui/kanban/kanban_page.dart`
- **Action:** 
    - ปรับขนาดความกว้างของคอลัมน์ (Column Width) ให้แคบลงเล็กน้อยบนมือถือ
    - ตรวจสอบให้แน่ใจว่า Scrollbar แนวนอนยังทำงานได้ดีบน Touch Screen
- **Why:** เพิ่มพื้นที่การมองเห็นบนหน้าจอแนวตั้ง

## Phase 71: Deep Mobile UI Overhaul (Total Reconstruction)

> **Workflow Mandate:** หลังจบทุก Task ย่อย ผมทำการ 1) อัปเดต Task Graph 2) อ่านไฟล์ 3 ไฟล์หลัก 3) ทำ Forensic Audit
> **Architecture Mandate:** รักษา Desktop 100% แก้ไข Mobile ให้ใช้งานได้จริง (Functional & Beautiful)

### Task 71.1: Adaptive Spacing Foundation
- **Status:** [x] Done
- **Target File:** `lib/ui/theme/glass_theme.dart`
- **Action:** เปลี่ยน `ExecutiveSpacing` จากค่าคงที่เป็น dynamic methods รับ `context` เพื่อลด Padding บนมือถืออัตโนมัติ
- **Why:** เพื่อแก้ต้นเหตุของอาการ "เบี้ยว" ที่เกิดจาก Padding กว้างเกินหน้าจอมือถือ

### Task 71.2: Full-Screen Chat Transformation
- **Status:** [x] Done
- **Target File:** `lib/ui/common/floating_assistant_shell.dart`
- **Action:** เปลี่ยน Chat Head ให้ขยายเต็มหน้าจอ (Positioned.fill) และปิดระบบ Drag/Resize บนมือถือ
- **Why:** เพื่อความสะดวกในการพิมพ์และอ่านบนหน้าจอแนวตั้ง

### Task 71.3: Calendar Monthly Grid Redesign
- **Status:** [x] Done
- **Target File:** `lib/ui/calendar/calendar_page.dart`
- **Action:** ปรับ Grid ตารางเดือนให้ยืดหยุ่น ยุบข้อมูล Task เหลือเพียงจุดสี (Indicator) และลด Header Padding
- **Why:** เพื่อให้ตารางไม่เบี้ยวและอ่านวันที่ได้ครบถ้วนบนมือถือ

### Task 71.4: Daily Timeline Adaptation
- **Status:** [x] Done
- **Target File:** `lib/ui/calendar/widgets/daily_timeline_view.dart`
- **Action:** ลดความกว้าง Time Column และปรับเลย์เอาต์การ์ดงานให้เป็นแนวตั้งที่กระชับ
- **Why:** เพิ่มพื้นที่แสดงข้อมูลงานในหน้าจอที่แคบ

## Phase 73: UX Precision & Safety Overhaul (Final Polish)

> **Workflow Mandate:** หลังจบทุก Task ย่อย ผมทำการ 1) อัปเดต Task Graph 2) อ่านไฟล์ 3 ไฟล์หลัก 3) ทำ Forensic Audit
> **Architecture Mandate:** เน้นความปลอดภัยในการโต้ตอบ (Interaction Safety) และความแม่นยำของเวลา

### Task 73.1: Safe Kanban Reordering
- **Status:** [x] Done
- **Target File:** `lib/ui/kanban/widgets/kanban_column.dart`
- **Action:** ย้ายลอจิก `Draggable` จากทั้งคอลัมน์ไปไว้ที่ไอคอน **Drag Handle** เท่านั้น
- **Why:** เพื่อป้องกันการพลาดไปสลับลำดับคอลัมน์ขณะที่ผู้ใช้เพียงต้องการกดดูการ์ดหรือเลื่อนบอร์ดปกติบนมือถือ

### Task 73.2: Precise Timeline Auto-Scroll
- **Status:** [x] Done
- **Target File:** `lib/ui/calendar/widgets/daily_timeline_view.dart`
- **Action:** แก้ไข `_scrollToCurrentHour` โดยเพิ่ม `Future.delayed` และคำนวณ Offset ตาม Hour Height จริง
- **Why:** เพื่อแก้บัคแอปเด้งไปล่างสุด และให้แอปเลื่อนมาที่เวลาปัจจุบันทุกครั้งที่เปิดหน้ารายวัน

### Task 73.3: Digital Pulse Restoration (Seconds)
- **Status:** [x] Done
- **Target File:** `lib/ui/calendar/widgets/daily_timeline_view.dart`
- **Action:** ใส่โค้ดเรนเดอร์ตัวเลขรายวินาที (3-row layout) กลับมาในชั่วโมงปัจจุบัน
- **Why:** เพื่อความแม่นยำในการติดตามเวลาแบบ Real-time ตามความต้องการของผู้ใช้

### Task 73.4: Messenger UI V2 (Pinned & Peek)
- **Status:** [x] Done
- **Target File:** `lib/ui/common/floating_assistant_shell.dart`
- **Action:** เพิ่มลอจิกเคลื่อนที่ไอคอนไปที่มุมขวาบนเมื่อขยายแชท และเพิ่มระบบ Background Peek
- **Why:** ยกระดับความพรีเมียมและความลื่นไหลของ AI Assistant ให้ทัดเทียมแอปแชทมาตรฐาน

### Task 73.5: Forensic Audit & Production Build
- **Status:** [x] Done
- **Action:** รัน `flutter analyze` และดีพลอยขึ้น Cloudflare Pages (Success)
- **Goal:** ส่งมอบ Calenda AI ที่สมบูรณ์แบบและปลอดภัยในทุกมิติ

## Phase 75: Strategic Operative Filter & Read-Only Logic

> **Workflow Mandate:** อัปเดต Task Graph และ Re-Sync ทุกครั้งที่จบ 1 Task ย่อย (V2 Protocol)
> **Architecture Mandate:** แยก UI Filter ออกจาก Data Flow หลักเพื่อความปลอดภัย

### Task 75.1: Operative Filter UI Strip
- **Status:** [x] Done
- **Target File:** `lib/ui/kanban/kanban_page.dart`
- **Action:** เพิ่มสถานะ `_activeOperativeId` และสร้างแถบเลือกสมาชิกทีมด้านบนบอร์ด
- **Why:** เพื่อให้ Commander เลือกดูภาระงานรายบุคคลได้ทันที

### Task 75.2: Conditional Draggability Lock
- **Status:** [x] Done
- **Target File:** `lib/ui/kanban/widgets/kanban_card.dart`
- **Action:** เพิ่ม Property `isDraggable` และล็อกระบบลากการ์ดเมื่อมีการใช้ฟิลเตอร์
- **Why:** เพื่อรักษาความสมบูรณ์ของลำดับงาน (Order Integrity) เมื่อไม่ได้ดูภาพรวมทั้งบอร์ด

### Task 75.3: Column Stability Security
- **Status:** [x] Done
- **Target File:** `lib/ui/kanban/widgets/kanban_column.dart`
- **Action:** ปิดระบบลากสลับคอลัมน์และเพิ่มลอจิกกรองการ์ดงานตาม Operative ID
- **Why:** เพื่อให้การแสดงผลรายบุคคลมีความแม่นยำและปลอดภัยสูงสุด

### Task 75.4: Production Verification & Deploy
- **Status:** [x] Done
- **Action:** รัน `flutter analyze` และดีพลอยระบบเวอร์ชันสมบูรณ์ (V2)
- **Goal:** ปลดล็อกขีดความสามารถการบริหารจัดการทีมอย่างมืออาชีพ

## Phase 76: Strategic Space & Zoom Refinement (Eagle Eye View)

> **Workflow Mandate:** อัปเดต Task Graph และ Re-Sync ทุกครั้งที่จบ 1 Task ย่อย (V2 Protocol)
> **Architecture Mandate:** รักษา "Abyssal Minimal" สุนทรียภาพเดิม แต่เพิ่มความยืดหยุ่นของสเกล

### Task 76.1: Context & Graph Update
- **Status:** [x] Done
- **Target File:** `task-graph.md`
- **Action:** บันทึกโครงงาน Phase 76 และ Re-Sync บริบทกฎเหล็ก
- **Why:** เพื่อรักษาความโปร่งใสและวินัยในการทำงานตาม Sovereign Protocol V2

### Task 76.2: Space Recovery - Filter & Scrollbar
- **Status:** [x] Done
- **Target File:** `lib/ui/kanban/kanban_page.dart`
- **Action:** 
    - ย้ายปุ่ม Operative Filter เข้าไปอยู่ในไอคอนปุ่มใน Header
    - นำ Widget `Scrollbar` ออกจากระบบ (ซ่อนแถบเลื่อน) เพื่อคืนพื้นที่สายตา
- **Why:** คืนพื้นที่บอร์ดให้กว้างขวางที่สุดตามหลัก Minimalist

### Task 76.3: Tactical Zoom Engine (Focus vs Overview)
- **Status:** [x] Done
- **Target File:** `lib/ui/kanban/kanban_page.dart` และ `lib/ui/kanban/widgets/kanban_column.dart`
- **Action:** 
    - เพิ่มสถานะ `_isOverviewMode` และปุ่ม Trigger ที่ Header
    - ใช้ระบบ **Dynamic Scaling**: เมื่อซูมออก ให้ปรับความกว้างคอลัมน์ (360 -> 260) และลด Padding ลงอัตโนมัติ
- **Why:** เพื่อให้ Commander สามารถเลือกดูงานแบบ "เจาะลึก" หรือ "ภาพรวมทั้งบอร์ด" ได้ในปุ่มเดียว

### Task 76.4: Forensic Audit & Web Deploy
- **Status:** [x] Done
- **Action:** รัน `flutter analyze` และดีพลอยเพื่อทดสอบความสะดวกบนอุปกรณ์จริง
- **Goal:** ระบบบอร์ดที่ "ลื่นไหล" และ "มองเห็นครอบคลุม" ที่สุด

## Phase 77: Unified Board Governance UI (Tools Consolidation)

> **Workflow Mandate:** อัปเดต Task Graph และ Re-Sync ทุกครั้งที่จบ 1 Task ย่อย (V2 Protocol)
> **Architecture Mandate:** รวมศูนย์เครื่องมือ (Centralization) เพื่อรักษาความสะอาดของ Header

### Task 77.1: Context & Graph Update
- **Status:** [x] Done
- **Target File:** `task-graph.md`
- **Action:** บันทึกโครงงาน Phase 77 และ Re-Sync บริบทกฎเหล็ก
- **Why:** เพื่อรักษาความโปร่งใสและวินัยในการทำงานตาม Sovereign Protocol V2

### Task 77.2: Universal Board Menu Integration
- **Status:** [x] Done
- **Target File:** `lib/ui/kanban/kanban_page.dart`
- **Action:** 
    - ลบปุ่ม Zoom และ Filter แยกชิ้นออกจาก Header
    - สร้าง `_buildUnifiedBoardMenu` ที่รวม [Toggle Zoom, Filter Members, Board Info] เข้าไว้ด้วยกัน
    - เปิดให้สมาชิกทุกคนเข้าถึงเมนูนี้ได้ (แต่จำกัดปุ่ม Rename/Delete ไว้เฉพาะเจ้าของ)
    - เพิ่ม Badge แจ้งเตือนสถานะบนไอคอนเมนูเมื่อมีการซูมหรือฟิลเตอร์ค้างไว้
- **Why:** เพื่อลดความแออัดของ UI และทำให้ Header ดูพรีเมียม สบายตาในทุกขนาดหน้าจอ

### Task 77.3: Forensic Audit & Web Deploy
- **Status:** [x] Done
- **Action:** รัน `flutter analyze` และดีพลอยเพื่อทดสอบความสมบูรณ์
- **Goal:** Header ที่คลีนที่สุดและเข้าถึงเครื่องมือได้ง่ายที่สุด

## Phase 80: Universal Fluid Scrolling (Desktop Mouse-Drag)

> **Workflow Mandate:** อัปเดต Task Graph และ Re-Sync ทุกครั้งที่จบ 1 Task ย่อย (Rule 0 & V2.1 Protocol)
> **Architecture Mandate:** ปลดล็อก Mouse Drag-to-Scroll เพื่อความลื่นไหลระดับเดียวกับ Mobile

### Task 80.1: Context & Graph Update
- **Status:** [x] Done
- **Target File:** `task-graph.md`
- **Action:** บันทึกโครงงาน Phase 80 และ Re-Sync บริบทกฎเหล็ก V2.1
- **Why:** เพื่อรักษาความโปร่งใสและวินัยในการทำงานตาม Sovereign Protocol V2.1

### Task 80.2: Custom Global Scroll Behavior
- **Status:** [x] Done
- **Target File:** `lib/main.dart`
- **Action:** 
    - สร้างคลาส `AppScrollBehavior` ที่ทำการ override `dragDevices`
    - นำไปใช้ใน `MaterialApp.scrollBehavior`
- **Why:** เพื่อให้เมาส์สามารถคลิกลากเลื่อน (Horizontal Drag) ได้เหมือนการใช้นิ้วบนมือถือ

### Task 80.3: Staged Testing (UI Precision Check)
- **Status:** [x] Done
- **Action:** ทดสอบการลากบอร์ดในหน้า Kanban และปฏิทินด้วยเมาส์ (ห้ามกวนกับ Task Dragging)
- **Why:** ตรวจสอบว่า `LongPressDraggable` ยังทำงานแยกจาก `ScrollBehavior` ได้ถูกต้อง

### Task 80.4: Forensic Audit & Web Deploy
- **Status:** [x] Done
- **Action:** รัน `flutter analyze` และดีพลอยเพื่อทดสอบความลื่นไหลบนเว็บจริง
- **Goal:** ประสบการณ์การใช้งานที่ Seamless ที่สุดในทุกอุปกรณ์

## Phase 81: Version Integrity & Startup Recovery (Emergency)

> **Workflow Mandate:** อัปเดต Task Graph และ Re-Sync ทุกครั้งที่จบ 1 Task ย่อย (Rule 0 & V2.1 Protocol)
> **Architecture Mandate:** ตรวจสอบความถูกต้องของ Deployment และกู้คืนระบบเริ่มต้น (Initialization)

### Task 81.1: Context & Graph Update
- **Status:** [x] Done
- **Target File:** `task-graph.md`
- **Action:** บันทึกโครงงาน Phase 81 และ Re-Sync บริบท
- **Why:** เพื่อรักษาความโปร่งใสและวินัยในการทำงานตาม Sovereign Protocol V2.1

### Task 81.2: Startup Logic Fortification
- **Status:** [ ] To Do
- **Target File:** `lib/main.dart`
- **Action:** 
    - เพิ่มระบบ Timeout ให้กับหน้า Loading (หมุนนานเกิน 10 วิให้ขึ้นปุ่ม Retry)
    - เพิ่มการเช็ค `snapshot.hasError` ใน Auth Stream
- **Why:** เพื่อแก้ปัญหา "แอปหมุนค้าง" และช่วยให้ทราบสาเหตุหากการเชื่อมต่อ Firebase พลาด

### Task 81.3: Clean Production Force-Deploy
- **Status:** [ ] To Do
- **Action:** ลบโฟลเดอร์ `build/` และรัน `flutter build web --release` ใหม่ทั้งหมด และดีพลอยซ้ำ
- **Why:** เพื่อแก้ปัญหา "เวอร์ชันย้อนกลับ (Rollback)" ที่อาจเกิดจาก Cache หรือการ Build ไม่สมบูรณ์
- **Staged Testing:** ตรวจสอบ URL ล่าสุดว่ามีปุ่มฟิลเตอร์แยกออกมา (Phase 78) และลากเมาส์เลื่อนบอร์ดได้ (Phase 80) หรือไม่

### Task 81.4: Forensic Audit & Final Report
- **Status:** [ ] To Do
- **Action:** สรุปผลการกู้คืนและยืนยันสถานะความสมบูรณ์




## Phase 78: Header Spatial Optimization (Avatar Capping & Tool Relocation)

> **Workflow Mandate:** อัปเดต Task Graph และ Re-Sync ทุกครั้งที่จบ 1 Task ย่อย (V2 Protocol)
> **Architecture Mandate:** จัดสมดุลพื้นที่ Header เพื่อป้องกันปุ่มล้นบนมือถือ

### Task 78.1: Context & Graph Update
- **Status:** [x] Done
- **Target File:** `task-graph.md`
- **Action:** บันทึกโครงงาน Phase 78 และ Re-Sync บริบทกฎเหล็ก
- **Why:** เพื่อรักษาความโปร่งใสและวินัยในการทำงานตาม Sovereign Protocol V2

### Task 78.2: Smart Avatar Stack (Max 3 + Counter)
- **Status:** [x] Done
- **Target File:** `lib/ui/kanban/kanban_page.dart`
- **Action:** แก้ไข `_buildClusterOperatives` ให้แสดงผลไอคอนสมาชิกสูงสุด 3 คน หากเกินให้แสดง `+N`
- **Why:** เพื่อประหยัดพื้นที่แนวนอนและรักษาความคลีนของหัวบอร์ด

### Task 78.3: Unified Governance Block Relocation
- **Status:** [x] Done
- **Target File:** `lib/ui/kanban/kanban_page.dart`
- **Action:** 
    - ดึงปุ่ม Filter ออกจากเมนูเฟือง
    - ย้ายปุ่ม Filter และ Gear (Settings) ไปต่อท้ายแถว Avatars (ฝั่งซ้าย)
    - ปรับปรุง Header ให้เหลือเฉพาะปุ่ม Action (Add/Bulk) ที่ฝั่งขวา
- **Why:** เพื่อป้องกันปุ่มล้นหน้าจอมือถือ และจัดกลุ่มเครื่องมือตามบริบท "ทีมและมุมมอง"

### Task 78.4: Forensic Audit & Web Deploy
- **Status:** [x] Done
- **Action:** รัน `flutter analyze` และดีพลอยเพื่อทดสอบสมดุล UI บนอุปกรณ์จริง
- **Goal:** Header ที่สมดุลที่สุด ไม่รก และใช้งานได้จริงทุกหน้าจอ

## Phase 79: WebSocket Syntax Migration & Billing Audit

> **Workflow Mandate:** อัปเดต Task Graph และ Re-Sync ทุกครั้งที่จบ 1 Task ย่อย (V2 Protocol)
> **Architecture Mandate:** รักษามาตรฐาน Durable Object ให้รองรับ SQLite Storage แบบใหม่

### Task 79.1: Context & Graph Update
- **Status:** [x] Done
- **Target File:** `task-graph.md`
- **Action:** บันทึกโครงงาน Phase 79 และเตรียมการแก้ไข
- **Why:** เพื่อรักษาความโปร่งใสและวินัยในการทำงานตาม Sovereign Protocol V2

### Task 79.2: SQLite Durable Object Syntax Migration
- **Status:** [x] Done
- **Target File:** `cloudflare_backend/cloudflare_worker.js`
- **Action:** 
    - นำเข้า `DurableObject` จาก `cloudflare:workers`
    - ปรับคลาส `BoardHub` ให้ `extends DurableObject` และรับ Parameter `(ctx, env)`
- **Why:** เพื่อให้สอดคล้องกับโครงสร้างใหม่ที่กำหนดไว้ใน `wrangler.toml` (`new_sqlite_classes`) และแก้ปัญหา 500 Internal Server Error

### Task 79.3: Forensic Audit & Web Deploy
- **Status:** [x] Done
- **Action:** รัน `wrangler deploy` และทดสอบยิง WebSocket Request
- **Goal:** คืนชีพการเชื่อมต่อ WebSocket กลับมา (แม้ในปัจจุบันจะติดลิมิต Free Tier)

### Task 79.4: Flutter Uncaught Error Graceful Degradation
- **Status:** [x] Done
- **Target File:** `lib/state_managers/state_tasks.dart`
- **Action:** เพิ่ม `channel.ready.catchError((_) {});` เพื่อดักจับ Unhandled Future Exception เมื่อ WebSocket ต่อไม่ติด
- **Why:** เพื่อป้องกันอาการ App Crash (Uncaught Error) เมื่อเจอ Error 500 จาก Cloudflare และให้ระบบถอยกลับไปใช้ Polling Mode ได้อย่างราบรื่น

### Task 79.5: Massive Connection Leak & Quota Drain Fix
- **Status:** [x] Done
- **Target File:** `lib/ui/calendar/calendar_page.dart` และ `lib/ui/kanban/kanban_page.dart`
- **Action:** 
    - เพิ่มคำสั่ง `_taskStateRef!.unsubscribeBoard(id)` ลงในฟังก์ชัน `dispose()` ของทั้งสองหน้าจอ
- **Why:** เพื่อแก้ปัญหา "เปิดแช่ไว้ตลอดเวลา" เพราะโค้ดเดิมไม่มีการสั่งปิด WebSocket เลยเมื่อเปลี่ยนหน้าหรือออกจากระบบ ทำให้เชื่อมต่อค้างไว้และผลาญโควต้า Durable Objects (100,000 GB-seconds) จนหมดเกลี้ยง

### Task 79.6: WebSocket Precision Scoping (Kanban Only)
- **Status:** [x] Done
- **Target File:** `lib/ui/calendar/calendar_page.dart`
- **Action:** 
    - ลบโค้ด `taskState.subscribeBoard(b)` ออกจากหน้า Calendar ทั้งหมด
- **Why:** เพื่อควบคุมให้มีการเปิดท่อ WebSocket เฉพาะหน้าที่จำเป็นจริงๆ เท่านั้น (หน้า Kanban 1 เส้น) ลดการกินโควต้า GB-seconds ของ Cloudflare แบบสูญเปล่า

### Task 79.7: Strategic Pivot to Polling Mode (Free Tier Mastery)
- **Status:** [x] Done
- **Target File:** `lib/state_managers/state_tasks.dart`
- **Action:** 
    - ปิดการทำงานของ `WebSocketChannel.connect` อย่างถาวร
    - บังคับให้ระบบข้ามไปเรียกฟังก์ชัน `_startPolling(board)` ทันทีเมื่อเข้าหน้า Kanban
    - ปรับแก้ `unsubscribeBoard` ให้ทำการ Cancel Timer ของ Polling ด้วย
- **Why:** เพื่อให้สอดคล้องกับความต้องการของผู้ใช้ที่ไม่ต้องการเสียค่าใช้จ่าย $5/เดือน และยอมรับการดึงข้อมูลแบบ Soft Real-time (ทุก 10 วินาที) ได้ ซึ่งจะทำให้ผู้ใช้ไม่ต้องกังวลเรื่องโควต้า Durable Objects อีกต่อไปตลอดชีวิต

### Task 79.8: Polling Interval Optimization
- **Status:** [x] Done
- **Target File:** `lib/state_managers/state_tasks.dart`
- **Action:** 
    - ปรับแก้เวลาใน `Timer.periodic` ของ `_startPolling` จาก 10 วินาที เป็น 5 วินาที
- **Why:** เพื่อตอบสนองต่อคำขอของผู้ใช้ที่ต้องการให้ซิงค์ข้อมูลเร็วขึ้นในขณะที่ยังใช้แบบ Polling (Soft Real-time) อยู่

## Phase 82: Workspace Hierarchy & Dark Theme Reversion

> **Workflow Mandate:** อัปเดต Task Graph และ Re-Sync ทุกครั้งที่จบ 1 Task ย่อย (Rule 0 & V2.1 Protocol)
> **Architecture Mandate:** ปรับเลย์เอาต์ระบบเป็น Workspace & Projects พร้อมกู้คืนสี Dark Glass Theme

### Task 82.1: Context & Graph Update
- **Status:** [x] Done
- **Target File:** `task-graph.md`
- **Action:** บันทึกโครงงาน Phase 82 และตั้งผังการดำเนินงานย่อยในระบบภาษาไทย
- **Why:** เพื่อแสดงจุดยืนเชิงโครงสร้างและความถูกต้องตามข้อกำหนด Sovereign Protocol

### Task 82.2: Restoration of Dark Glass Theme Colors
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/theme/glass_theme.dart` และ `my_ai_assistant/lib/main.dart`
- **Action:** คืนค่าสีตัวแปรของ GlassColors กลับเป็น Abyssal Minimal และอัปเดต MaterialApp theme เป็น Brightness.dark
- **Why:** เพื่อแก้ปัญหาสีสว่างกวนสายตาและกู้ระบบธีมสีดาร์กชาร์ดกลับตามความต้องการของผู้ใช้

### Task 82.3: Workspace Model Implementation
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/models/workspace_model.dart` และ `my_ai_assistant/lib/models/board_model.dart`
- **Action:** สร้างโมเดล Workspace และผูก workspaceId เข้ากับ BoardModel
- **Why:** เพื่อให้เกิดโครงสร้างข้อมูล Project บอร์ดย่อยเชื่อมโยงกับ Workspace ได้อย่างถูกต้อง

### Task 82.4: Local SQLite Schema Migration (v8)
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/databases/db_personal_sqlite.dart`
- **Action:** สร้างตาราง personal_workspaces และเพิ่มคอลัมน์ workspace_id ใน SQLite
- **Why:** เพื่อการจัดเก็บ Workspace และ Project แบบ Offline บนคอมพิวเตอร์ของผู้ใช้

### Task 82.5: Cloudflare Worker API & D1 Schema Update
- **Status:** [x] Done
- **Target File:** `cloudflare_backend/d1_schema.sql` และ `cloudflare_backend/cloudflare_worker.js`
- **Action:** อัปเดตตารางทีมบนฐานข้อมูล D1, เพิ่ม Endpoint API `/api/workspaces` และติดตั้ง Auto-alter
- **Why:** เพื่อจัดเตรียม Endpoint และ Schema ฝั่ง Cloud สำหรับ Workspace & Project แบบทีม

### Task 82.6: State Managers Workspace Business Logic
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/state_managers/state_boards.dart`
- **Action:** เพิ่มฟังก์ชัน CRUD Workspace และเมธอด Auto-Migration สำหรับบอร์ดเก่าใน StateBoards
- **Why:** เพื่อให้แอปพลิเคชันคุมความเรียบร้อยของข้อมูล และย้ายบอร์ดเก่าเข้า Default Workspace อัตโนมัติ

### Task 82.7: Sidebar & Navigation UI Restructuring
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/common/aether_side_nav.dart`
- **Action:** ปรับ Sidebar Menu ให้สามารถสร้าง Workspace และเรนเดอร์บอร์ดโครงการย่อยเข้าโครงสร้างต้นไม้ได้
- **Why:** เพื่อมอบสุนทรียศาสตร์และการใช้งานที่ลื่นไหลในการควบคุม Workspace จากบานหน้าต่างด้านข้าง

### Task 82.8: Projects Grid & Workspace Tabs on BoardsPage
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/boards/boards_page.dart`
- **Action:** ปรับปรุงหน้าบอร์ดให้แสดงผล Workspace Tabs ด้านบนและกรองเฉพาะ Projects ของ Workspace นั้นๆ ด้านล่าง
- **Why:** เพื่อให้การนำทางและการเข้าถึงโครงการย่อยในแต่ละ Workspace คลีนและสะดวกยิ่งขึ้น

### Task 82.9: Empirical Proof & Code Audit
- **Status:** [x] Done
- **Action:** รันลินเตอร์ตรวจสอบโค้ดและดีพลอยผ่าน run_local.sh เพื่อทดสอบระบบหน้าจอ E2E
- **Why:** เพื่อรับรองคุณภาพผลลัพธ์และความสมบูรณ์ของระบบ

## Phase 83: Premium Gold Cards, Custom Toast Notifications & Minimal Dashboard

> **Workflow Mandate:** อัปเดต Task Graph และ Re-Sync ทุกครั้งที่จบ 1 Task ย่อย (Rule 0 & V2.1 Protocol)
> **Architecture Mandate:** ปรับแผงหน้าแดชบอร์ดให้มินิมอลตามแบบรูปภาพ, ปรับแจ้งเตือนกลางให้เป็น Custom Overlay และการ์ดยืนยันให้เป็นสีทองขอบทอง

### Task 83.1: Context & Graph Update
- **Status:** [x] Done
- **Target File:** `task-graph.md`
- **Action:** บันทึกโครงงาน Phase 83 และตั้งผังการดำเนินงานย่อยในระบบภาษาไทย
- **Why:** เพื่อจัดเตรียมแผนและอนุมัติผังงานตาม Sovereign Protocol V2

### Task 83.2: Custom Overlay-based Toast Implementation
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/common/glass_widgets.dart`
- **Action:** แก้ไขเมธอด `GlassNotifications.show` ให้สร้าง `OverlayEntry` แบบมีเอนิเมชัน สไลด์และเฟด จำกดยางและความกว้าง พร้อมปรับแต่งสไตล์ขอบสีทองและข้อความให้ออกมาสวยงามพรีเมียม
- **Why:** เพื่อให้การแจ้งเตือนกลาง (คัดลอก/สำเร็จ/ลบ) มีความมินิมอล ไม่ขยายยืดเต็มหน้าจอในโหมดเดสก์ท็อป และดูสวยล้ำยุค

### Task 83.3: Proposal & Confirmed Cards Gold Styling
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/chat/widgets/draft_cards.dart`
- **Action:** ปรับรูปแบบของการ์ดแบบร่าง (`ProposalDraftCard`) และการ์ดผลลัพธ์การกระทำ (`ConfirmedActionCard`) ในช่องแชท ให้ใช้สไตล์สีทอง (`GlassColors.gold`) ทั้งขอบด้านนอกและตัวอักษรเพื่อให้อ่านง่ายขึ้น
- **Why:** เพื่อความสวยงามพรีเมียมและความเปรียบต่างสี (Contrast) ที่เหมาะสม อ่านง่ายบนพื้นหลัง Dark Glass

### Task 83.4: Minimalist Dashboard Alignment & Style Update
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/dashboard/dashboard_page.dart` และ `my_ai_assistant/lib/ui/dashboard/widgets/dashboard_widgets.dart`
- **Action:** ปรับเปลี่ยนเลย์เอาต์หน้าแดชบอร์ดตามแบบ Image 1:
    - สลับหัวข้อ "STRATEGIC HUB" ไว้บนสุดตัวหนาใหญ่และย้ายวันที่ลงมาด้านล่าง (พิมพ์ใหญ่-เล็กตามปกติ)
    - เพิ่ม Workspace Count Pill Badge และไอคอนแจ้งเตือนในแถวหัวข้อหลัก
    - ปรับปรุง Active Workspaces Header ให้มี Badge บอกจำนวน และปรับปรุงปุ่ม Join Workspace
    - ปรับปรุงให้แท็กโครงการ (Board chip) ใช้สีพื้นหลังแบบทึบ (Solid board color) พร้อมตัวหนังสือและจุดสีขาว
    - ปรับปรุง `DashboardBentoCard` ให้มีหัวข้อตัวหนาสะดุดตา และอัปเดตไอคอนของการ์ด Milestone เป็นไอคอนธง
    - [x] Task 83.4.1: ปรับแก้ `./run_local.sh` เพื่อจัดการความขัดแย้งของ Port 8787
    - [x] Task 83.4.2: เพิ่มฟังก์ชัน `ApiCloudflare.registerUser`
    - [x] Task 83.4.3: เรียกใช้งาน `registerUser` ตอนเริ่มต้นใน `StateBoards`
    - [x] Task 83.4.4: ปรับขนาดตัวอักษรของ "Active Workspaces" ให้เท่ากับหัวข้อ Bento Card
- **Why:** เพื่อจัดลำดับสายตาและสไตล์ของหน้าแดชบอร์ดให้ตรงกับต้นแบบ Image 1 ที่มีความหรูหรา มินิมอล และเป็นสากลสูงสุด

### Task 83.5: Empirical Proof & Code Audit
- **Status:** [x] Done
- **Action:** รันลินเตอร์วิเคราะห์โค้ดและตรวจสอบ Syntax ด้วย linter / manual audit
- **Why:** เพื่อการันตีคุณภาพและความเสถียรของแอปพลิเคชันหลังทำการอัปเดตสไตล์และแจ้งเตือนใหม่

## Phase 84: Avatar Stack & System Comments

> **Workflow Mandate:** อัปเดต Task Graph และ Re-Sync ทุกครั้งที่จบ 1 Task ย่อย (Rule 0 & V2.1 Protocol)

### Task 84.1: ปรับแก้ Avatar Stack ใน `kanban_card.dart`
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/kanban/widgets/kanban_card.dart`
- **Action:** เปลี่ยนมาใช้โครงสร้าง `Stack` และ `Positioned` แทนมาร์จิ้นติดลบของ `Row`
- **Why:** เพื่อแก้ปัญหารูปลื่นไหลล้มเหลวขัดข้อง (isNonNegative Crash) ใน Flutter

### Task 84.2: ติดตั้งระบบบันทึกความเห็นการเปลี่ยนแปลงใน `StateTasks`
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/state_managers/state_tasks.dart`
- **Action:** เปรียบเทียบค่าความต่างของข้อมูลเพื่อบันทึกประวัติการทำกิจกรรมอัตโนมัติเป็นภาษาไทยลงประวัติตารางความเห็น
- **Why:** เพื่อป้อนข้อมูลการอัปเดตงานทั้งหมดไปยัง Discussion Feed บนแดชบอร์ด

### Task 84.3: การทดสอบและการตรวจสอบเชิงประจักษ์ (Empirical Testing)
- **Status:** [x] Done
- **Action:** รันคำสั่ง `flutter analyze` ตรวจสอบความถูกต้องและทดลองใช้งานแอปพลิเคชัน
- **Why:** รับประกันคุณภาพและยืนยันการแก้ปัญหาอย่างแท้จริง

## Phase 102: Split-Pane Modal Layout & StateChat Integration

> **Workflow Mandate:** อัปเดต Task Graph และ Re-Sync ทุกครั้งที่จบ 1 Task ย่อย (Rule 0 & V2.1 Protocol)

### Task 102.1: Context & Graph Update
- **Status:** [x] Done
- **Target File:** `task-graph.md`
- **Action:** บันทึกโครงงาน Phase 102 และตั้งผังการดำเนินงานย่อยในระบบภาษาไทย
- **Why:** เพื่อแสดงจุดยืนเชิงโครงสร้างและความถูกต้องตามข้อกำหนด Sovereign Protocol

### Task 102.2: Add taskSessions State to StateChat
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/state_managers/state_chat.dart`
- **Action:** เพิ่มฟิลด์ `_taskSessions` และพฤติกรรมดึงรายการประวัติสนทนาใน `selectTaskSession` พร้อมเมธอด `switchTaskSession`
- **Why:** เพื่อป้อนประวัติเซสชันแชททั้งหมดให้โมดอลรายละเอียดงานแสดงในแถบเมนู

### Task 102.3: Set Initial Tab to Chat in TaskEditModal
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/kanban/widgets/task_edit_modal.dart`
- **Action:** กำหนด `_activeTab = 1` เพื่อเปิดหน้าแชท (Chat) เป็นหน้าหลักเสมอเมื่อเข้าสู่หน้ารายละเอียดงาน
- **Why:** เพื่อให้สอดคล้องกับพฤติกรรมการเปิดการแชทก่อนของแอปพลิเคชัน

### Task 102.4: Build Icon-Only Glassmorphic Toggle and Dynamic Sidebar Header
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/kanban/widgets/task_edit_modal.dart`
- **Action:** สร้างปุ่ม Toggle ที่แสดงไอคอนเท่านั้น และสลับหัวข้อ dynamic ระหว่าง "Agent QA Discussion" และ "ประวัติคอมเม้น" บนขอบแถบแชทขวา
- **Why:** ปรับโครงสร้างและการนำทางให้รวดเร็วและเป็นระเบียบตามความต้องการ

### Task 102.5: Restructure Left Column Header Layout
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/kanban/widgets/task_edit_modal.dart`
- **Action:** ปรับเลย์เอาต์ Header ฝั่งซ้ายให้แสดง Checkbox ติ๊กถูกสำหรับ `isCompleted`, Status Badge ของคอลัมน์ และปุ่ม "ลบการ์ด" (ไม่มีปุ่มแก้ไข)
- **Why:** เพื่อจัดวางองค์ประกอบให้ประณีตและปรับปรุงขีดความสามารถการทำเครื่องหมายเสร็จสิ้นจากภายในโมดอล

### Task 102.6: Design Darker Right Sidebar Panel & Close Button
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/kanban/widgets/task_edit_modal.dart`
- **Action:** เพิ่มสไตล์สีพื้นหลังของ Sidebar ขวาให้มีความเข้มเด่นชัด (เช่น `Colors.black.withOpacity(0.18)` หรือออกเทาเข้ม) พร้อมติดตั้งปุ่มปิด `X` ขวาสุดของ Header คอลัมน์ขวา
- **Why:** เพื่อให้เกิด visual separation ที่ดีระหว่างฟอร์มข้อมูลและการพูดคุย

### Task 102.7: Click Outside to Close & Dimensional Update
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/kanban/widgets/task_edit_modal.dart`
- **Action:** หุ้ม Desktop Container ด้วย GestureDetector ทั่วทั้ง Backdrop เพื่อปิดหน้าต่างเมื่อแตะนอกกรอบ พร้อมขยายความกว้างสูงสุดเป็น 1250
- **Why:** เพิ่มมิติความเรียบง่ายและใช้งานสะดวกตามมาตรฐาน Desktop UX

### Task 102.8: Empirical Verification
- **Status:** [x] Done
- **Action:** รันคำสั่ง `flutter analyze` เพื่อตรวจสอบ Syntax และตรวจสอบความถูกต้องของ layout
- **Why:** รับประกันความเสถียรและความถูกต้องของซอร์สโค้ดทั้งหมด

## Phase 103: Task Edit Modal Layout Polish & Crash Prevention

> **Workflow Mandate:** อัปเดต Task Graph และ Re-Sync ทุกครั้งที่จบ 1 Task ย่อย (Rule 0 & V2.1 Protocol)
> **Architecture Mandate:** จัดระเบียบเลย์เอาต์ Task Edit Modal ตามที่ผู้ใช้ระบุ พร้อมแก้ไขบั๊ก Dropdown ล่มแบบ Surgical Update (ValueNotifier)

### Task 103.1: Bulletproof Dropdown Value Check
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/kanban/widgets/task_edit_modal.dart`
- **Action:** ป้องกันแอปพังช่วง Pop/Disposal Transition โดยแปลง `value` ของ DropdownButton เป็น `sessions.any((s) => s.id == activeSessionId) ? activeSessionId : null`
- **Why:** เพื่อแก้ปัญหา `Assertion failed: items == null || items.isEmpty || value == null || items.where((DropdownMenuItem<T> item) { return item.value == value; }).length == 1`

### Task 103.2: Refactor Left Column Header & Title Layout
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/kanban/widgets/task_edit_modal.dart`
- **Action:** 
    - ปรับปรุง `_buildHeader()` ลบคำว่า `STRATEGIC TASK` (สตาติสติกทาร์ค) และ Checkbox ตัวเดิมออก เหลือเฉพาะ Column Badge ปุ่มลบ และปุ่มปิด
    - ปรับปรุงการแสดงผลหัวข้อในเนื้อหาหลัก: สร้าง `Row` ล้อมรอบ Task Title โดยใช้ `ValueListenableBuilder<TaskModel>` สวมครอบ Checkbox ขนาดใหญ่ (Transform.scale) เพื่อให้อัปเดตสถานะแบบเรียลไทม์ทันทีในป็อปอัป
- **Why:** เพื่อตอบสนองต่อเลย์เอาต์ที่คลีน สะอาดตา ตามความต้องการของผู้ใช้ และแก้ไขปัญหาปุ่มติ๊กไม่อัปเดตสถานะในป็อปอัปโดยตรง

### Task 103.3: Empirical Verification
- **Status:** [x] Done
- **Action:** รันคำสั่ง `flutter analyze` เพื่อตรวจสอบความสมบูรณ์และไม่มีข้อผิดพลาดของซอร์สโค้ด
- **Why:** เพื่อรับรองคุณภาพและความเสถียรของแอปพลิเคชันหลังทำการอัปเดตสไตล์และแก้ไขบั๊กทั้งหมด

## Phase 104: Split Layout for Task Edit Modal & Premium Dropdown Menu

> **Workflow Mandate:** อัปเดต Task Graph และ Re-Sync ทุกครั้งที่จบ 1 Task ย่อย (Rule 0 & V2.1 Protocol)
> **Architecture Mandate:** ปรับดีไซน์ Right Column ของ Task Edit Modal ให้เป็นแบบ Split-Screen พื้นหลังแยกสี แทนการใช้ Card-in-Card ซ้อนทับ และออกแบบ Dropdown สำหรับ Session Selector ให้มินิมอลและพรีเมียมยิ่งขึ้น

### Task 104.1: Refactor Task Modal Desktop Layout to Split Screen
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/kanban/widgets/task_edit_modal.dart`
- **Action:**
  - ย้าย `Padding` ของ `mainBody` เข้าไปใน Left Column และ Right Column
  - กำหนดให้ `Row` ฝั่ง Desktop มี `crossAxisAlignment: CrossAxisAlignment.stretch`
  - ปรับปรุงการออกแบบ Container ของ Right Column ให้ขยายสุดขอบและมีขอบโค้งมนเฉพาะมุมขวาบน/ขวาแยกสีพื้นหลังเด่นชัด
- **Why:** เพื่อกำจัดการซ้อนการ์ด (Card inside Card) ที่ดูอึดอัด และแบ่งพาร์ทป็อปอัปครึ่งต่อครึ่งแบบสะอาดตาและสวยงามตามดีไซน์หลัก

### Task 104.2: Replace Default Dropdown with Modern PopupMenuButton
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/kanban/widgets/task_edit_modal.dart`
- **Action:**
  - แปลง `DropdownButton` เป็น `PopupMenuButton<String>`
  - ตกแต่งสไตล์ของ Toggle Button ให้ดูมินิมอลด้วยกรอบจางและลูกศรเรียบง่าย
  - ปรับสไตล์ลิสต์เมนูย่อยของเซสชันให้น่าอ่านและไฮไลท์เซสชันที่แอคทีฟด้วยสีแบรนด์และไอคอนติ๊กถูก
- **Why:** เพื่อยกระดับความพรีเมียม (Premium Aesthetics) และความใช้งานง่ายตามเป้าหมายของ Calenda

### Task 104.3: Verification and Build Validation
- **Status:** [x] Done
- **Action:** รันคำสั่ง `flutter analyze` เพื่อตรวจสอบความถูกต้องของสไตล์ลิสต์และโครงสร้างภาษา
- **Why:** รับประกันความเสถียร 100% ปราศจาก Compile errors หรือข้อผิดพลาดทางเลย์เอาต์

## Phase 105: Layout Adjustments & Exception Fix
- **Goal:** แก้ไขข้อผิดพลาด "Looking up a deactivated widget's ancestor is unsafe" ใน dispose และปรับขนาดข้อความชื่อคอลลั้มฝั่งซ้ายบนให้ชัดเจนยิ่งขึ้น

### Task 105.1: Store StateChat Reference in didChangeDependencies
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/kanban/widgets/task_edit_modal.dart`
- **Action:**
  - เพิ่มตัวแปร `late StateChat _stateChat` ในสถานะคลาส `_TaskEditModalState`
  - ทำการเซฟค่าอ้างอิง `_stateChat = context.read<StateChat>()` หรือ `Provider.of<StateChat>(context, listen: false)` ใน `didChangeDependencies()`
  - อัปเดต `dispose()` ให้เรียกใช้ `_stateChat.switchToGlobalContext()` หลีกเลี่ยงการใช้งาน `context`
- **Why:** ป้องกันการเกิดข้อยกเว้นตอนปิดป๊อปอัป เนื่องจาก widget ถูก deactivated ไปแล้ว

### Task 105.2: Enlarge Column Name Badge in _buildHeader
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/kanban/widgets/task_edit_modal.dart`
- **Action:**
  - ปรับดีไซน์ของ Badge ชื่อคอลลั้มมุมซ้ายบนให้ใหญ่ขึ้น ชัดเจนขึ้น และใช้คู่สีแบรนด์
- **Why:** ทำให้อ่านหัวข้อของการ์ดระบุคอลลั้มได้ง่ายและชัดเจนขึ้นตามความต้องการของผู้ใช้

### Task 105.3: Verification and Build Validation
- **Status:** [x] Done
- **Action:** รันคำสั่ง `flutter analyze` ตรวจสอบความถูกต้องและทดสอบระบบ
- **Why:** มั่นใจในเสถียรภาพและคุณภาพระดับสูงของโปรเจกต์ Calenda

## Phase 106: Task Title Wrapping in Edit Popup
- **Goal:** ปรับปรุงช่องกรอกหัวข้อการ์ดงาน (Task Title) ในป๊อปอัปให้แสดงผลและแก้ไขแบบขึ้นบรรทัดใหม่ (Wrap) ได้เมื่อข้อความยาวเกินไป

### Task 106.1: Allow multi-line title input in task_edit_modal.dart
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/kanban/widgets/task_edit_modal.dart`
- **Action:**
  - เปลี่ยนพารามิเตอร์ `maxLines` ใน `_buildTextField` เป็น nullable (`int? maxLines`)
  - อัปเดต `_buildTitleSection` ให้ส่ง `maxLines: null` และ `textInputAction: TextInputAction.done` เพื่อให้หัวข้อการ์ดสามารถตัดคำขึ้นบรรทัดใหม่ได้แบบไม่จำกัดบรรทัด และยังคงส่งคำสั่ง Done คีย์บอร์ดได้ปกติ
- **Why:** ช่วยให้การแก้ไขหัวข้อที่มีข้อความยาวๆ เป็นไปอย่างสะดวกและอ่านง่ายขึ้น

### Task 106.2: Run analysis and verify build status
- **Status:** [x] Done
- **Action:** รันคำสั่ง `flutter analyze` ตรวจสอบและทดสอบการรันเครื่องมือ
- **Why:** มั่นใจในเสถียรภาพและความสมบูรณ์ของโค้ดที่แก้ไขใหม่

## Phase 107: Solid Opaque Overlays for Improved Readability

> **Workflow Mandate:** อัปเดต Task Graph และ Re-Sync ทุกครั้งที่จบ 1 Task ย่อย (Rule 0 & V2.1 Protocol)
> **Architecture Mandate:** ปรับเปลี่ยนพื้นหลังของ Popups, Dialogs, Dropdown Pickers, และ Bottom Sheets จากแบบ Glassmorphic (กึ่งโปร่งใส) เป็นแบบ Solid Opaque (ทึบแสง) เพื่อเพิ่มความชัดเจน คอนทราสต์ และความง่ายในการอ่าน ป้องกันไม่ให้ข้อความพื้นหลังแสดงทะลุขึ้นมาซ้อนทับกัน

### Task 107.1: Convert Task Edit Modal Pickers to Opaque
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/kanban/widgets/task_edit_modal.dart`
- **Action:** อัปเดต `_showFullImage`, `_pickStatus`, `_pickLabels`, และ `_pickMembers` โดยเปลี่ยนการใช้ `GlassDecorations.surface` เป็น `GlassDecorations.solidSurface`
- **Why:** เพื่อแก้ปัญหารายการตัวเลือกและรูปภาพที่ซ้อนทับอยู่ด้านบนมีความโปร่งแสง ทำให้อ่านยาก

### Task 107.2: Convert Kanban Page Menus/Dialogs to Opaque
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/kanban/kanban_page.dart`
- **Action:** อัปเดต `_showOperativeFilterMenu`, `_showMoveMenu`, และ `_BoardInfoDialog` ให้ใช้ `GlassDecorations.solidSurface`
- **Why:** เพื่อปรับปรุงความคมชัดและการแบ่งสัดส่วนเลเยอร์ให้ดียิ่งขึ้น

### Task 107.3: Convert Column and Member Modals to Opaque
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/kanban/widgets/column_edit_modal.dart`, `my_ai_assistant/lib/ui/kanban/widgets/member_role_modal.dart`
- **Action:** เปลี่ยนพื้นหลังของคอนเทนเนอร์หลักจาก `GlassDecorations.surface` เป็น `GlassDecorations.solidSurface`
- **Why:** หน้าต่างแก้ไขคอลัมน์และจัดการบทบาทสมาชิกต้องมีความทึบแสงและชัดเจนเมื่อเปิดซ้อนทับบน Kanban board

### Task 107.4: Convert Calendar Preview to Opaque
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/calendar/widgets/daily_timeline_view.dart`
- **Action:** อัปเดต `_showStrategicPreview` ให้ใช้ `GlassDecorations.solidSurface`
- **Why:** แก้ไขปัญหารายการพรีวิวของวันที่บนปฏิทินแสดงทะลุไปเห็นเส้นตารางเวลาและกล่องกิจกรรมด้านหลัง

### Task 107.5: Convert Chat Draft Card Pickers to Opaque
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/chat/widgets/draft_cards.dart`
- **Action:** ปรับเปลี่ยน `_showColumnPicker`, `_showMemberPicker`, และ `_showLabelPicker` ให้ใช้ `GlassDecorations.solidSurface`
- **Why:** ป้องกันไม่ให้แชทบับเบิ้ลและประวัติแชทด้านหลังทะลุมาแย่งสายตากับรายการปุ่มกดในดรอปดาวน์/บอตทอมชีตของแชทการ์ดร่าง

### Task 107.6: Convert Dashboard Workspace Dialogs to Opaque
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/dashboard/dashboard_page.dart`
- **Action:** อัปเดต `_showJoinWorkspaceDialog` และ `_showRenameWorkspaceDialog` ให้ใช้ `GlassDecorations.solidSurface`
- **Why:** ปรับปรุง UI การเข้าร่วมและเปลี่ยนชื่อเวิร์กสเปซให้น่าอ่านและคมเข้มขึ้น

### Task 107.7: Verification and Build Validation
- **Status:** [x] Done
- **Action:** รันคำสั่ง `flutter analyze` เพื่อตรวจสอบความสมบูรณ์และเสถียรภาพของโค้ด
- **Why:** ตรวจสอบให้มั่นใจว่าไม่มี Compile errors หรือ Syntax issue จากการแก้ไขตกแต่งสไตล์ครั้งนี้

## Phase 108: Multi-Platform Chat File Upload Infrastructure
- **Goal:** แก้ไขระบบการอัปโหลดไฟล์ในหน้าแชทให้ใช้งานได้บน Native Platforms ด้วยการดึงไบต์ไฟล์ผ่านทางพาธในเครื่องเป็นตัวเลือกสำรอง (Fallback)

### Task 108.1: Support file bytes fallback reading on Native Platforms
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/state_managers/state_chat.dart`
- **Action:**
  - นำเข้า `dart:io` และ `package:flutter/foundation.dart`
  - ปรับ R2 Upload Pipeline ในเมธอด `sendMessageToAI` ให้ดึงข้อมูลไบต์จาก `file.path` บน Native (non-web) เมื่อ `file.bytes` เป็น null
- **Why:** เพื่อให้การอัปโหลดเอกสาร/รูปภาพบนมือถือและเดสก์ท็อปสามารถทำงานได้อย่างสมบูรณ์

### Task 108.2: Run analysis and verify build status
- **Status:** [x] Done
- **Action:** รันคำสั่ง `flutter analyze` เพื่อตรวจสอบข้อผิดพลาดทางไวยากรณ์และความเข้ากันได้ของโค้ด
- **Why:** มั่นใจในเสถียรภาพและคุณภาพระดับสูงของโปรเจกต์ Calenda

## Phase 109: Dashboard Milestones Filtering and Web/WebP Upload Support
- **Goal:** ปรับปรุงการกรองงานเสร็จแล้วใน Dashboard ตามการติ๊กถูก และรองรับการอัปโหลดไฟล์สกุล `.web`/`.webp` ให้เข้ากันได้กับระบบ AI Vision

### Task 109.1: Fix Upcoming Milestones Task Completion Filter
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/dashboard/dashboard_page.dart`
- **Action:** เปลี่ยนเงื่อนไขบรรทัดที่ 96 จากการเช็กชื่อคอลัมน์ `status` มาเป็นใช้ `!task.isCompleted` แทน
- **Why:** เนื่องจากผู้ใช้สามารถเปลี่ยนชื่อคอลัมน์ Kanban ได้เองอย่างอิสระ การตรวจสอบด้วย checkbox `isCompleted` จะมีความแม่นยำสูงสุด

### Task 109.2: Map `.web`/`.webp` Extensions to Safe MIME Type
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/state_managers/state_chat.dart`
- **Action:** อัปเดตฟังก์ชัน `_guessMimeType` ให้แมปตัวเลือก `'web': 'image/jpeg'` และแก้ตัวเลือก `'webp': 'image/jpeg'`
- **Why:** เพื่อให้มีประเภทไฟล์รูปภาพที่ยอมรับอย่างกว้างขวาง ป้องกันไม่ให้ AI Vision API ของ OpenRouter ปฏิเสธรูปภาพเมื่อพบ MIME type ที่ไม่รู้จัก

### Task 109.3: Run Build Verification and Static Analysis
- **Status:** [x] Done
- **Action:** รันคำสั่ง `flutter analyze` เพื่อตรวจสอบความสมบูรณ์และเสถียรภาพของโค้ด
- **Why:** มั่นใจในคุณภาพโค้ดที่อัปเดตใหม่ว่าจะทำงานได้อย่างถูกต้องสมบูรณ์

## Phase 110: Fix Chat Attachment File Picking on Web
- **Goal:** แก้ไขปุ่มแนบไฟล์ของห้องแชตให้รองรับการเปิดหน้าต่าง File Picker บนเว็บเบราว์เซอร์อย่างเสถียร

### Task 110.1: Refactor GlassIconButton to use Material/InkWell
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/common/glass_widgets.dart`
- **Action:** ปรับเปลี่ยนการทำ Button Event จาก `GestureDetector` ไปใช้ `Material` + `InkWell` เพื่อแปลง pointer events ให้กลายเป็น User Activation ที่เบราว์เซอร์ยอมรับ
- **Why:** แก้ไขปัญหาระบบเบราว์เซอร์บล็อกหน้าต่างเลือกไฟล์ (User Activation Policy)

### Task 110.2: Run Build Verification and Static Analysis
- **Status:** [x] Done
- **Action:** รันคำสั่ง `flutter analyze` เพื่อตรวจสอบความสมบูรณ์และเสถียรภาพของโค้ด
- **Why:** มั่นใจในคุณภาพโค้ดที่อัปเดตใหม่ว่าจะทำงานได้อย่างถูกต้องสมบูรณ์

## Phase 111: Chat Attachment Diagnostics and Detailed Logging
- **Goal:** วางระบบตรวจจับและแจ้งเตือน Log ของปุ่มแนบไฟล์แชตเพื่อให้วิเคราะห์หาสาเหตุการทำงานผิดพลาดของปุ่มบน Web

### Task 111.1: Add logs to GlassIconButton
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/common/glass_widgets.dart`
- **Action:** เพิ่ม `debugPrint` ในการกด `InkWell` ภายใน `GlassIconButton`
- **Why:** ตรวจสอบว่า Event มาถึงระดับ UI Button หรือไม่

### Task 111.2: Add logs to AetherChatInput
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/chat/widgets/chat_input.dart`
- **Action:** เพิ่ม `debugPrint` ในตัวตรวจรับเหตุการณ์ปุ่ม action
- **Why:** ตรวจสอบการผ่าน Callback จาก Action Button ไปยัง Input Widget

### Task 111.3: Add logs to _ChatInputArea inside aether_chat_view.dart
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/chat/widgets/aether_chat_view.dart`
- **Action:** เพิ่ม `debugPrint` ในตัวสั่งการเรียก `StateChat.pickFiles`
- **Why:** ตรวจสอบว่า Callback ของหน้าควบคุมแชตได้รับ Event หรือไม่

### Task 111.4: Add logs, try-catch, and Toast/SnackBar to StateChat.pickFiles()
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/state_managers/state_chat.dart`
- **Action:** เพิ่ม try-catch พร้อม log stack trace เต็มรูปแบบ, แสดงผลทางหน้าจอผ่าน SnackBar/Toast หรือ System Dialog เมื่อกดปุ่มแนบไฟล์สำเร็จ
- **Why:** หาสาเหตุการผิดพลาดในระดับ State Logic หรือข้อผิดพลาดที่เกิดขึ้นจริงใน File Picker ของเบราว์เซอร์

### Task 111.5: Run Build Verification and Static Analysis
- **Status:** [x] Done
- **Action:** รันคำสั่ง `flutter analyze` เพื่อตรวจสอบความสมบูรณ์ของโค้ด
- **Why:** ตรวจสอบข้อผิดพลาดทางด้าน Syntax ของโค้ดใหม่ทั้งหมด

## Phase 112: Fix Web User Activation for Chat File Uploads
- **Goal:** แก้ไขปัญหาระบบเบราว์เซอร์บล็อกการแนบไฟล์เนื่องจากสูญเสีย User Activation จาก BackdropFilter

### Task 112.1: Implement Gesture-Safe InkWell inside AetherChatInput
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/chat/widgets/chat_input.dart`
- **Action:** แก้ไขฟังก์ชัน `_buildActionButton` เพื่อไม่ให้เรียกใช้ `GlassIconButton` ซึ่งมี `BackdropFilter` อยู่ในลำดับ Element แต่ใช้ `InkWell` หุ้ม `Container` ที่มีสไตล์กึ่งโปร่งใสแทน เพื่อให้ Click Event ถูกส่งต่อไปยัง `FilePicker` โดยตรง
- **Why:** รักษาสถานะ Synchronous User Activation ของเว็บเบราว์เซอร์ในการเรียกใช้ File Selector

### Task 112.2: Clean Debug UI elements from StateChat.pickFiles()
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/state_managers/state_chat.dart`
- **Action:** ลบการเรียกใช้งาน `ScaffoldMessenger.showSnackBar` และ `showDialog(AlertDialog)` ทั้งหมดในฟังก์ชัน `pickFiles` เพื่อลบหน้าต่างดีบัคกวนสายตาบนเว็บเบราว์เซอร์ตามที่ผู้ใช้ร้องขอ และคงเฉพาะ `debugPrint` ลงคอนโซล Terminal
- **Why:** ทำการซ่อนดีบัคหน้าจอบนเว็บให้แสดงผลเฉพาะในคอนโซลของนักพัฒนา

### Task 112.3: Run Verification and Build Status
- **Status:** [x] Done
- **Action:** รันคำสั่ง `flutter analyze` เพื่อตรวจสอบความสมบูรณ์ของระบบ
- **Why:** ยืนยันว่าไม่มี Compile errors หรือประเด็นทาง Syntax จากการแก้ไขครั้งนี้

## Phase 113: Implement Direct HTML Input Picker for Web Chat Attachments

> **Workflow Mandate:** อัปเดต Task Graph และ Re-Sync ทุกครั้งที่จบ 1 Task ย่อย (Rule 0 & V2.1 Protocol)
> **Architecture Mandate:** ป้องกันปัญหา Browser Focus-Loss/Cancellation Bug บน Flutter Web โดยการทำ Custom HTML File Input Picker ที่ดึงไฟล์แบบ Direct/Synchronous แทนการเรียกผ่านแพ็กเกจ file_picker บน Web

### Task 113.1: Create Stub Helper File
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/utils/web_file_picker_stub.dart`
- **Action:** สร้างฟังก์ชัน stub `pickFilesWeb()` สำหรับคอมไพล์บน Native Platforms
- **Why:** ป้องกันปัญหาคอมไพเลอร์ฟ้องหาไลบรารี `dart:html` บนแพลตฟอร์มที่ไม่ใช่เว็บ

### Task 113.2: Create Web Helper File
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/utils/web_file_picker_web.dart`
- **Action:** สร้างฟังก์ชัน `pickFilesWeb()` โดยการใช้ `dart:html.FileUploadInputElement` ร่วมกับ `FileReader` และแนบ input เข้ากับ DOM body (`html.document.body.append`) เพื่อป้องกันปัญหาระบบ Garbage Collection ทำลาย element ก่อนผู้ใช้เลือกไฟล์เสร็จสิ้น พร้อมทั้งทำความสะอาด input ตัวเก่าเพื่อป้องกัน memory leak
- **Why:** เพื่อดึงข้อมูลไฟล์จากเบราว์เซอร์อย่างเสถียรและป้องกันการสูญหายของ event ในบางเบราว์เซอร์

### Task 113.3: Integrates Web Picker inside StateChat
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/state_managers/state_chat.dart`
- **Action:** ทำ Conditional Import ไปยัง Helper ทั้งสอง และเรียกใช้ `pickFilesWeb` เมื่อตรวจสอบพบว่าอยู่ใน Web Platform และอัปเดตไฟล์แนบตาม context ห้องแชต
- **Why:** สลับการแนบไฟล์บนเว็บเบราว์เซอร์ให้ไปใช้ Direct HTML input ทันที และเก็บไฟล์แนบแยกกันตามห้องแชตให้ถูกต้อง

### Task 113.4: Verification and Static Analysis
- **Status:** [x] Done
- **Action:** รันคำสั่ง `flutter analyze`
- **Why:** มั่นใจในเสถียรภาพและคุณภาพการคอมไพล์ว่าไม่มี syntax compile errors บนแพลตฟอร์มต่างๆ

### Task 113.5: Update System Walkthrough and Documentation
- **Status:** [x] Done
- **Target File:** `walkthrough.md`
- **Action:** บันทึกการแก้ไขปัญหาระบบอัปโหลดไฟล์เว็บในแบบ Direct HTML Input
- **Why:** ยืนยันความสมบูรณ์ของงานและรักษาสภาพความชัดเจนของประวัติการออกแบบสถาปัตยกรรมแอปพลิเคชัน

## Phase 114: Global Notification & Read Sync

> **Workflow Mandate:** อัปเดต Task Graph และ Re-Sync ทุกครั้งที่จบ 1 Task ย่อย (Rule 0 & V2.1 Protocol)
> **Architecture Mandate:** ย้ายสถานะการอ่านความคิดเห็น (Comment Read Status) ไปไว้ใน StateTasks เพื่อแชร์การอ่านทั่วทั้งแอปพลิเคชันและบันทึกลง SharedPreferences พร้อมเพิ่ม Badge แจ้งเตือนแสดงจำนวนที่ยังไม่อ่านบนกระดิ่ง Dashboard

### Task 114.1: Update StateTasks with comment read tracking and unread comments count
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/state_managers/state_tasks.dart`
- **Action:** เพิ่มตัวแปร `_readCommentIds`, โหลดและบันทึกลง SharedPreferences และสร้าง `unreadCommentsCount`
- **Why:** เพื่อให้มีแหล่งเก็บสถานะการอ่านคอมเม้นที่อัปเดตและซิงก์กันได้ทั่วทั้งแอป

### Task 114.2: Update TaskEditModal to mark task comments as read on load and updates
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/kanban/widgets/task_edit_modal.dart`
- **Action:** เรียกใช้เมธอดทำเครื่องหมายว่าอ่านแล้วเมื่อแสดงโมดอลหรือเมื่อรับคอมเม้นใหม่ในหน้า Task
- **Why:** เพื่อให้คอมเม้นใน Task นั้นๆ ถูกทำเครื่องหมายว่าอ่านแล้วทันทีที่ผู้ใช้เปิดดูรายละเอียดงาน

### Task 114.3: Refactor DashboardPage to consume comments read state globally and display the unread notification badge
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/dashboard/dashboard_page.dart`
- **Action:** ดึงข้อมูลการอ่านคอมเม้นจาก StateTasks และตกแต่งแถบหัวเรื่องด้วยกระดิ่งที่มี Badge จำนวนงานที่ยังไม่ได้อ่าน
- **Why:** แสดงตัวเลขแจ้งเตือนแบบเรียลไทม์และลดความซับซ้อนของสถานะแอปพลิเคชัน

### Task 114.4: Verification and static analysis with flutter analyze
- **Status:** [x] Done
- **Action:** รันการตรวจสอบ Static Analysis เพื่อการันตีความเรียบร้อย
- **Why:** ป้องกันไม่ให้มี compile error หรือ type mismatch หลังจากการแก้ไขโครงสร้างของระบบการแจ้งเตือน

## Phase 115: File Picker Optimization & Page State Caching

> **Workflow Mandate:** อัปเดต Task Graph และ Re-Sync ทุกครั้งที่จบ 1 Task ย่อย (Rule 0 & V2.1 Protocol)
> **Architecture Mandate:** รักษามาตรฐานการจัดเก็บข้อมูลและการรักษาความต่อเนื่องของแอปพลิเคชันอย่างสมบูรณ์ ปรับปรุงการใช้ FilePicker และเปลี่ยน Tab Navigation ไปใช้ IndexedStack

### Task 115.1: Integrate robust logging and optimize file picking method
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/state_managers/state_chat.dart`
- **Action:** เปลี่ยนการเรียกใช้ FilePicker ไปเป็น `FilePicker.platform.pickFiles` และเพิ่ม debugPrint ข้อผิดพลาดและข้อมูลของไฟล์ที่เลือกอย่างครบถ้วน
- **Why:** เพื่อตรวจสอบและระบุสาเหตุที่แท้จริงของการอัปโหลดไฟล์/การเลือกไฟล์ไม่ได้บน Web Platform

### Task 115.2: Change tab switching to IndexedStack in AppShell
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/main.dart`
- **Action:** เปลี่ยนการใช้ AnimatedSwitcher ไปเป็น IndexedStack เพื่อไม่ให้หน้าแชทและหน้าอื่นๆ รีเซ็ต/กระพริบระหว่างสลับแท็บ
- **Why:** แก้ไขการรีโหลดของแชทโกลบอลและรักษาความต่อเนื่องของอินเทอร์เฟซผู้ใช้

### Task 115.3: Static analysis verification
- **Status:** [x] Done
- **Action:** รันคำสั่ง `flutter analyze` เพื่อป้องกันไม่ให้มี compile error หรือ type mismatch
- **Why:** ยืนยันความพร้อมของซอร์สโค้ดก่อนส่งมอบงานให้ผู้ใช้ทดสอบจริง

## Phase 116: Notification Interaction Logic Refinement & Custom HTML Web FilePicker

> **Workflow Mandate:** อัปเดต Task Graph และ Re-Sync ทุกครั้งที่จบ 1 Task ย่อย (Rule 0 & V2.1 Protocol)
> **Architecture Mandate:** ปรับปรุงความถูกต้องของ Notification Flow และการแนบไฟล์ผ่าน Browser Engine

### Task 116.1: Correct aggressive notification mark-read behavior
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/kanban/widgets/task_edit_modal.dart`
- **Action:** ลบ `markAllCommentsAsReadForTask` ออกจาก initState, _onTaskUpdated และ _refreshTaskData
- **Why:** เพื่อให้การกดอ่านแจ้งเตือนเป็นแบบทีละอัน (granular) ไม่ใช้หน้าต่างข้อมูลล้างประวัติการแจ้งเตือนทั้งหมด

### Task 116.2: Implement direct HTML FilePicker for Web CanvasKit
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/state_managers/web_file_picker_web.dart`, `my_ai_assistant/lib/state_managers/web_file_picker_stub.dart`, `my_ai_assistant/lib/state_managers/state_chat.dart`
- **Action:** สร้าง input element แนบเข้ากับ DOM body, ใช้ onChange synchronous handler เพื่อหลีกเลี่ยง focus cancellation และดึงข้อมูล ByteBuffer แปลงเป็น Uint8List เพื่อส่งกลับเป็น PlatformFile
- **Why:** แก้ไขบั๊ก file_picker package คืนค่า null บน Web CanvasKit เนื่องจาก event loop/focus mismatch

### Task 116.3: Static analysis verification
- **Status:** [x] Done
- **Action:** รันการตรวจสอบ Static Analysis เพื่อการันตีความเรียบร้อยของโค้ดใหม่
- **Why:** มั่นใจว่าโครงสร้าง conditional import และการประกาศประเภทตัวแปร (List<File> vs FileList) ทำงานร่วมกันได้ถูกต้องโดยไม่มีข้อผิดพลาดค้างอยู่

## Phase 117: Diagnostics and Verification of File Picker UI State

> **Workflow Mandate:** อัปเดต Task Graph และ Re-Sync ทุกครั้งที่จบ 1 Task ย่อย (Rule 0 & V2.1 Protocol)
> **Architecture Mandate:** ตรวจสอบและแก้ไขระบบแสดงผลของไฟล์ที่เลือกใน Chat Input (File Chips) เพื่อให้ปรากฏบนเว็บเบราว์เซอร์อย่างถูกต้อง

### Task 117.1: Add diagnostic logging to StateChat, AetherChatView, and AetherChatInput
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/state_managers/state_chat.dart`, `my_ai_assistant/lib/ui/chat/widgets/aether_chat_view.dart`, `my_ai_assistant/lib/ui/chat/widgets/chat_input.dart`
- **Action:** เพิ่ม print statements เพื่อพิมพ์สถานะเมื่อเรียกใช้ pickFiles, คืนค่าจาก FilePicker, อัปเดตลิสต์, รีบิลด์ Selector, และรับ pendingFiles
- **Why:** ค้นหาจุดที่ทำให้ไฟล์ที่เลือกแล้วไม่ยอมแสดงผลขึ้นมาในหน้าจอของแชท

### Task 117.2: Analyze debug log results and apply fix
- **Status:** [x] Done
- **Action:** สร้าง custom_file_picker.dart, custom_file_picker_stub.dart, และ custom_file_picker_web.dart เพื่อหลีกเลี่ยง focus loss bug ของแพ็กเกจ file_picker บนเว็บ โดยไม่ใช้ focus listener ในการยกเลิก จากนั้นนำไปเรียกใช้ใน StateChat
- **Why:** แก้ปัญหาที่ผู้ใช้คลิกปุ่มเลือกไฟล์แล้ว file_picker ส่งคืนค่าเป็น null ทันทีเนื่องจาก focus event บน Chrome (Linux/Wayland) ทำงานเร็วเกินไป

## Phase 118: Web File Picker Gesture Fix & Stale Process Cleanup

> **Workflow Mandate:** อัปเดต Task Graph และ Re-Sync ทุกครั้งที่จบ 1 Task ย่อย (Rule 0 & V2.1 Protocol)
> **Architecture Mandate:** ดึงข้อมูลไฟล์แบบ Synchronous จากการกระทำของผู้ใช้ (User Gesture) เพื่อให้เบราว์เซอร์อนุญาตให้เลือกไฟล์ตามนโยบายความปลอดภัย

### Task 118.1: StateChat Restructuring
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/state_managers/state_chat.dart`
- **Action:** เพิ่มฟังก์ชัน `addPendingFiles(List<PlatformFile>)` เพื่อรับไฟล์ที่เลือกได้โดยตรงจาก UI layer
- **Why:** เพื่อแก้ปัญหานโยบายความปลอดภัย (User Activation Policy) ของเว็บเบราว์เซอร์

### Task 118.2: AetherChatInput Direct Selection
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/chat/widgets/chat_input.dart`
- **Action:** ย้าย `FilePicker.pickFiles()` ไปรันตรงใต้ปุ่มคลิกเพื่อให้ทำงานแบบ synchronous จาก gesture ของผู้ใช้
- **Why:** เพื่อหลีกเลี่ยง focus loss และข้อจำกัดความปลอดภัยของเบราว์เซอร์

### Task 118.3: AetherChatView Wiring
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/chat/widgets/aether_chat_view.dart`
- **Action:** เชื่อมต่อปุ่มเลือกไฟล์ให้นำส่งไฟล์ไปยัง `stateChat.addPendingFiles(files)`
- **Why:** นำส่งไฟล์ที่เลือกได้สำเร็จเข้าสู่ StateChat

### Task 118.4: Cleaned Code & Removed Debug Spam
- **Status:** [x] Done
- **Action:** ลบ log สแปมและโค้ดขยะ คืนค่าดีไซน์ความเบลอของ Glassmorphism
- **Why:** รักษาความสะอาดและประสิทธิภาพของซอร์สโค้ดตาม Sovereign SOP

### Task 118.5: Stale Process Cleanup
- **Status:** [x] Done
- **Target File:** `run_local.sh`
- **Action:** ฆ่าพอร์ตชนตกค้างของ wrangler dev และ miniflare ก่อนเริ่มทำงาน
- **Why:** ป้องกันปัญหาพอร์ตชนตอนรัน local backend

### Task 118.6: Static Analysis
- **Status:** [x] Done
- **Action:** รัน `flutter analyze --no-pub` ตรวจสอบไวยากรณ์
- **Why:** ยืนยันความสมบูรณ์ของระบบ

## Phase 119: UI Overflow Fix & R2 Image Loading Stabilization

> **Workflow Mandate:** อัปเดต Task Graph และ Re-Sync ทุกครั้งที่จบ 1 Task ย่อย (Rule 0 & V2.1 Protocol)
> **Architecture Mandate:** ปรับปรุงความยืดหยุ่นของ UI ในหัวข้อบอร์ด Bento และใช้การวิเคราะห์ URL แบบ Dynamic และ Fallback ในการดึงรูปภาพ R2 Local

### Task 119.1: Fix Bento Card Header Overflow
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/dashboard/widgets/dashboard_widgets.dart`
- **Action:** นำวิดเจ็ต `Expanded` มาครอบ `Text(title.toUpperCase())` ในส่วนหัวของ `DashboardBentoCard` พร้อมกำหนด `overflow: TextOverflow.ellipsis` และ `maxLines: 1`
- **Why:** แก้ไขปัญหากรอบแสดงผลล้น 21 พิกเซลในหน้า Dashboard

### Task 119.2: Dynamic URL Protocol in Cloudflare Worker
- **Status:** [x] Done
- **Target File:** `cloudflare_backend/cloudflare_worker.js`
- **Action:** ปรับปรุงการคืนค่า `absoluteUrl` ใน endpoint `/api/upload` ให้ใช้ `url.protocol` แทนการฮาร์ดโค้ด `https://`
- **Why:** ป้องกันไม่ให้แอปดึงรูปภาพด้วย `https://localhost:8787` ซึ่งไม่มีอยู่จริงตอนทดสอบโลคอล

### Task 119.3: Add URL Sanitization in EnvConfig
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/config/env_config.dart`
- **Action:** เพิ่มฟังก์ชัน `sanitizeUrl(String url)` เพื่อแปลง `https://localhost`, `https://127.0.0.1`, `https://10.0.2.2` เป็น `http://` แบบอัตโนมัติ
- **Why:** ใช้กู้คืนลิงก์รูปภาพในฐานข้อมูล D1 ที่ถูกบันทึกเป็น `https` ไปแล้วก่อนหน้านี้ให้สามารถโหลดได้ถูกต้อง

### Task 119.4: Integrate URL Sanitizer in Image Widgets
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/kanban/widgets/kanban_card.dart`, `my_ai_assistant/lib/ui/calendar/widgets/daily_timeline_view.dart`, `my_ai_assistant/lib/ui/kanban/widgets/task_edit_modal.dart`
- **Action:** เรียกใช้ `EnvConfig.sanitizeUrl(url)` ก่อนนำลิงก์ไปส่งให้ `Image.network` แสดงผลรูปหน้าปกและรูปภาพแนบในหน้าบอร์ดต่าง ๆ
- **Why:** ยืนยันว่าหน้าบอร์ดและปฏิทินแสดงรูปภาพแนบทั้งหมดได้อย่างสมบูรณ์

### Task 119.5: Static Analysis Verification
- **Status:** [x] Done
- **Action:** รันคำสั่ง `flutter analyze` เพื่อตรวจสอบความสมบูรณ์และคอมไพล์ของโปรเจกต์
- **Why:** ยืนยันว่าระบบทั้งหมดปลอดภัย ไม่มี Compile Error หรือปัญหาทางสุนทรียศาสตร์

## Phase 120: Upload Notifications, Progress Overlays & Permanent Storage

> **Workflow Mandate:** อัปเดต Task Graph และ Re-Sync ทุกครั้งที่จบ 1 Task ย่อย (Rule 0 & V2.1 Protocol)
> **Architecture Mandate:** เพิ่มการส่งแจ้งเตือนผลการอัปโหลดผ่านสตรีมเพื่อแสดง Toast บน UI, ซ้อน Progress Loader แสดงสถานะขณะส่งรูปภาพ, และบันทึกข้อมูลแนบลงโฟลเดอร์ chats ถาวรใน R2

### Task 120.1: Add Broadcast Stream and Status Logging to StateChat
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/state_managers/state_chat.dart`
- **Action:** เพิ่ม static StreamControllers `onUploadError` และ `onUploadSuccess` และเปลี่ยน R2 Path เป็น 'chats' พร้อมส่ง event
- **Why:** ช่วยให้ UI รับทราบสถานะและประวัติแชทถูกเก็บอย่างปลอดภัยถาวร

### Task 120.2: Add Upload Progress Overlay to Chat Bubble Attachments
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/chat/widgets/chat_bubbles.dart`
- **Action:** ซ้อน CircularProgressIndicator บนภาพแนบที่ค่า url ยังเป็นค่าว่าง (isUploading)
- **Why:** เพื่อให้เกิด visual feedback ที่พรีเมียมและสวยงามระหว่างที่ไฟล์กำลังส่ง

### Task 120.3: Wire Stream Notifications in AetherChatView
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/chat/widgets/aether_chat_view.dart`
- **Action:** สมัครรับสตรีม `StateChat.onUploadSuccess` และ `onUploadError` และแสดง GlassNotifications.show
- **Why:** ให้ผู้ใช้ปลายทางทราบสถานะการอัปโหลดแบบ real-time บนหน้าจอแชท

### Task 120.4: E2E Verification & Static Analysis
- **Status:** [x] Done
- **Action:** รันตรวจไวยากรณ์ด้วย flutter analyze และรัน test suite test_image_flow.dart
- **Why:** ยืนยันว่าการส่งรูปภาพ, ระบบแจ้งเตือน และโครงสร้างโค้ดทั้งหมดทำงานได้อย่างสมบูรณ์

---

## Phase 121: Handle Image Upload Failures & Infinite Spinner Resolution

> **Workflow Mandate:** อัปเดต Task Graph และ Re-Sync ทุกครั้งที่จบ 1 Task ย่อย (Rule 0 & V2.1 Protocol)
> **Architecture Mandate:** แก้ไขปัญหารูปภาพแนบหมุนค้างตลอดกาลเมื่อเกิดข้อผิดพลาดในการอัปโหลด โดยอัปเดตสถานะด้วย 'url': 'error' เพื่อปิด Spinner และแสดงรูปแจ้งเตือนความผิดพลาด พร้อมทั้งทำการล้าง URL และตรวจจับความถูกต้องผ่าน EnvConfig

### Task 121.1: Catch Upload Failures and Set 'url': 'error'
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/state_managers/state_chat.dart`
- **Action:** อัปเดตลูป R2 Pipeline ให้บันทึกสถานะ 'url': 'error' ทั้งในกรณีที่หาข้อมูลไบต์ไม่ได้ หรือ API ล้มเหลว/โยนข้อผิดพลาดออกมา เพื่อส่งสัญญาณแจ้งเตือนไปยัง UI
- **Why:** เพื่อเปลี่ยนสถานะแนบไฟล์ให้เป็นอิสระจากการหมุนโหลดค้าง (Infinite Spinner Loop)

### Task 121.2: Sanitize URLs and Add Red Error Indicator in Bubble
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/chat/widgets/chat_bubbles.dart`
- **Action:** สรรค์สร้าง UI Overlay สีแดงเตือน "Failed" ทับบนการแสดงผลแนบไฟล์รูปภาพที่การอัปโหลดขัดข้อง (`url == 'error'`) พร้อมแปลง URL โลคอลผ่าน `EnvConfig.sanitizeUrl(url)`
- **Why:** เพื่อให้เกิดการตอบสนองเชิงภาพ (Visual Feedback) ที่ชัดเจนและสมบูรณ์แบบแก่ผู้ใช้งานเมื่อระบบขัดข้อง

### Task 121.3: Run Tests and Verify
- **Status:** [x] Done
- **Action:** ตรวจสอบความถูกต้องด้วยการรัน `flutter test test/test_image_flow.dart` และ `flutter analyze`
- **Why:** ป้องกันไม่ให้เกิดปัญหาถดถอย (Regression) และรักษาคุณภาพความเรียบร้อยของสุนทรียศาสตร์โครงสร้างโค้ด

---

## Phase 122: Multimodal AI Vision Pipeline Optimization

> **Workflow Mandate:** อัปเดต Task Graph และ Re-Sync ทุกครั้งที่จบ 1 Task ย่อย (Rule 0 & V2.1 Protocol)
> **Architecture Mandate:** ลด Latency ของโมเดลโดยใช้ Sliding Window สำหรับประวัติการสนทนา ล้อมรั้วความเสถียรด้วย Retry Loop และบันทึกคำตอบของ AI ลงฐานข้อมูล D1 โดยตรงจากระบบหลังบ้านเพื่อความปลอดภัยของข้อมูล

### Task 122.1: Context Window Truncation (Sliding Window)
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/state_managers/state_chat.dart`
- **Action:** ปรับลดประวัติการสนทนาที่ส่งให้ AI เหลือเพียง 14 ข้อความล่าสุด
- **Why:** เพื่อลด Token bloat และยกระดับความเร็วในการตอบสนองให้เป็นระดับ Premium

### Task 122.2: ID Propagation in MistyAgent
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ai_agent/core/misty_agent.dart`
- **Action:** เพิ่มพารามิเตอร์ `sessionId` และ `assistantMessageId` ในการยิง Request ไปยัง Cloudflare Backend Worker
- **Why:** เพื่อให้ Backend มีข้อมูลสำหรับอ้างอิงและบันทึกข้อความอย่างมีประสิทธิภาพ

### Task 122.3: StateChat Integration for ID Passing
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/state_managers/state_chat.dart`
- **Action:** อัปเดตส่วนควบคุมการส่งข้อความ (`sendMessageToAI`) เพื่อสร้างและส่งต่อไอดีของข้อความ/เซสชันไปหา AI Agent
- **Why:** ส่งต่อไอดีต้นทางให้ Backend เก็บข้อมูลใน SQLite D1 ได้อย่างเสถียร

### Task 122.4: Worker Provider Fallback Retry Loop & Direct Persistence
- **Status:** [x] Done
- **Target File:** `cloudflare_backend/cloudflare_worker.js`
- **Action:** พัฒนาระบบสำรองคิว (3-attempt retry loop) ข้ามผู้ให้บริการที่ล้มเหลว และรัน Query บันทึกคำตอบ AI ลง D1 SQLite โดยตรงก่อน Response คืนสู่ไคลเอนต์
- **Why:** เพื่อปกป้องความถูกต้องและความครบถ้วนของข้อมูลประวัติการทำธุรกรรม (Data Atomicity)

### Task 122.5: Build Verification and Test Suite Execution
- **Status:** [x] Done
- **Action:** ยืนยันความสมบูรณ์และเสถียรภาพโดยผ่านการตรวจสอบด้วย `flutter analyze` และการรัน unit tests ทั้งหมด รวมถึง TC-08 สำหรับ Sliding Window บน `test_image_flow.dart`
- **Why:** มั่นใจในคุณภาพโค้ดระดับสุดยอดของ Calenda AI

---

## Phase 123: AI Chat Vision Latency Optimization & Logging Hardening

> **Workflow Mandate:** อัปเดต Task Graph และ Re-Sync ทุกครั้งที่จบ 1 Task ย่อย (Rule 0 & V2.1 Protocol)
> **Architecture Mandate:** ลด Latency ในการวิเคราะห์รูปภาพด้วย AI ให้ตอบสนองในรอบเดียว (Single-Turn) และขยายระบบการบันทึก Log ใน Cloudflare Worker เพื่อการดีบัคที่ง่ายดาย

### Task 123.1: Cloudflare Worker Logging Hardening
- **Status:** [x] Done
- **Target File:** `cloudflare_backend/cloudflare_worker.js`
- **Action:** ปรับแก้การจัดหน้า Log ของ Worker ให้สามารถแสดงคำถามผู้ใช้ล่าสุด และคำตอบหรือการเรียกเครื่องมือฉบับเต็มของ AI เพื่อเพิ่มความสามารถในการตรวจสอบและดีบัคผ่าน Terminal
- **Why:** ให้ผู้ใช้ตรวจสอบสถานะการทำงานของโมเดลและการตอบกลับจริงได้อย่างมีประสิทธิภาพ

### Task 123.2: MistyAgent Single-Turn Skip & Metadata Injection
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ai_agent/core/misty_agent.dart`
- **Action:** ใส่ข้อมูล Metadata ของไฟล์แนบ (ชื่อและ URL) ใน Prompt แรกเพื่อเชื่อมโยงกับรูปภาพ Base64 และสร้างตรรกะ `canSkipSecondCall` เพื่อปิดระบบ sequential call หากมีเพียง Side-effect tools
- **Why:** สิ้นสุดปัญหาความล่าช้าสะสมและประหยัด Token การส่งรูปภาพ Base64 ซ้ำสองรอบ

### Task 123.3: StateChat History Convert Image Metadata
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/state_managers/state_chat.dart`
- **Action:** ปรับตรรกะแปลงประวัติการสนทนาใน `_convertMessagesToAgentHistory` เพื่อให้รวมข้อมูลชื่อและ URL ภาพล่าสุดที่ยังไม่มี Description
- **Why:** รักษาความต่อเนื่องและความเสถียรของประวัติการถามคำถามแบบต่อยอด

### Task 123.4: Synchronous History Cache Refresh
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/state_managers/state_chat.dart`
- **Action:** แก้ไขฟังก์ชัน `_initImageDescriptionListener` ให้โหลดและสั่ง Re-Sync ประวัติการสนทนาเข้าสู่ตัวแปร `_globalAgent` และ `_taskAgent` ทันทีเมื่ออัปเดตคำอธิบายภาพสำเร็จ
- **Why:** ป้องกันไม่ให้โมเดลไม่รู้ตัวถึงการเปลี่ยนแปลงคำบรรยายภาพล่าสุดเมื่อมีข้อความถัดไปเข้ามาทันที

### Task 123.5: Redundant Vision Tools Deprecation
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ai_agent/tools/registry.dart`
- **Action:** นำเอา `analyzeUploadedImageTool` และ `getActualImageTool` ออกจากรายการ `allAiTools`
- **Why:** บังคับให้ AI ใช้ความสามารถ Native Vision มองภาพจากเนื้อความโดยตรง ป้องกันข้อผิดพลาดจากการประมวลผลเครื่องมือซ้ำซ้อน

### Task 123.6: Verify and Build Analysis
- **Status:** [x] Done
- **Action:** รันการตรวจสอบความถูกต้องด้วย `flutter analyze` และการรัน unit tests บน `test_image_flow.dart`
- **Why:** ยืนยันความเสถียรและความพร้อมใช้งานระดับพรีเมียมของระบบ

## Phase 124: Image Stabilization and Single-Turn Response Optimization

### Task 124.1: Background AI Description Generation
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/state_managers/state_chat.dart`
- **Action:** เพิ่ม `_generateDescriptionInBg` และเรียกใช้เมื่ออัปโหลดรูปภาพใน `sendMessageToAI`
- **Why:** ทำให้คำบรรยายภาพทำงานในพื้นหลังทันทีเมื่ออัปโหลด ป้องกันปัญหาโหลดค้าง

### Task 124.2: SkillVision Rules Prompt Tuning
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ai_agent/skills/skill_vision.dart`
- **Action:** อัปเดต `rules` ให้บอกโมเดลว่าคำบรรยายภาพทำอัตโนมัติ ไม่ต้องสั่ง `update_image_description` รอบแรก
- **Why:** เพื่อให้โมเดลตอบกลับในรอบเดียว (Single-Turn) และประหยัด Token / ลดความช้า

### Task 124.3: UserMessageBubble ValueKey Injection
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/chat/widgets/chat_bubbles.dart`
- **Action:** ใส่ `key: ValueKey(sanitizedUrl)` ที่ `Image.network`
- **Why:** เพื่อให้เกิดการวาดรูปภาพใหม่เมื่อมี URL ป้องกันปัญหาแคช element ของ Flutter

### Task 124.4: Complete Flow Verification
- **Status:** [x] Done
- **Action:** รัน `flutter analyze` เพื่อตรวจสอบการคอมไพล์และเช็คระบบโดยรวม
- **Why:** เพื่อความพร้อมใช้งานระดับพรีเมียมตามมาตรฐานของ Calenda

## Phase 125: Fix Port Binding and Local Storage Session Persistence

### Task 125.1: Modify run_local.sh
- **Status:** [x] Done

- **Target File:** `run_local.sh`
- **Action:** เพิ่มอาร์กิวเมนต์ `--web-port=8080` ให้คำสั่ง `flutter run`
- **Why:** เพื่อกำหนดพอร์ตคงที่ ป้องกันความสับสนของ Origin ในเบราเซอร์ และช่วยให้ Local Storage/SQLite สามารถแชร์ข้อมูลกันได้สมบูรณ์

### Task 125.2: Test Local Execution
- **Status:** [x] Done
- **Action:** รัน `./run_local.sh` เพื่อตรวจสอบการจับคู่พอร์ต 8080 และโหลดหน้าแอป/รูปภาพบน Chrome หลัก
- **Why:** ยืนยันว่าหน้าเว็บและภาพถูกดึงจาก Origin เดียวกันได้โดยสมบูรณ์

### Task 125.3: Update Documentation & Sync
- **Status:** [x] Done
- **Action:** ปรับปรุงเอกสารโครงการและบันทึกสถานะการทำภารกิจ
- **Why:** รักษาระบบฐานข้อมูลความรู้ให้สอดคล้องกันตาม Sovereign Protocol

### Task 125.4: Use web-server Device in run_local.sh
- **Status:** [x] Done
- **Target File:** `run_local.sh`
- **Action:** เปลี่ยนจาก `-d chrome` เป็น `-d web-server`
- **Why:** เพื่อไม่ให้เซสชันของ Flutter ดับลงเมื่อผู้ใช้ปิดหรือเปิดเบราเซอร์ ช่วยให้เซิร์ฟเวอร์รันอยู่ตลอดกาลอย่างมั่นคง

### Task 125.5: Verify stability of web-server
- **Status:** [x] Done
- **Action:** ตรวจสอบความเสถียรของการรันด้วยอุปกรณ์ `web-server`
- **Why:** เพื่อให้มั่นใจได้ว่าเซิร์ฟเวอร์รันตลอดชีพและ Chrome ปกติสามารถโหลดภาพและใช้งานได้โดยไม่สะดุด

## Phase 126: Kanban Operative Filter Toggle

### Task 126.1: Setup & State Definition
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/kanban/kanban_page.dart`
- **Action:** ประกาศตัวแปร enum `OperativeFilterMode` และเพิ่ม state สำหรับ `_filterMode` และ `_selectedOperativeId`
- **Why:** เพื่อใช้เก็บสถานะและระบุตัวกรองที่เลือกสำหรับโหมดตัวกรองแบบ 3 สถานะ

### Task 126.2: UI Component Construction
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/kanban/kanban_page.dart`
- **Action:** สร้าง UI ของตัวควบคุม segmented control แบบ glassmorphic สำหรับโหมดตัวกรอง และแทนที่ปุ่มไอคอนตัวกรองเดิม
- **Why:** เพื่อปรับปรุงการสลับสถานะของตัวกรองให้เข้าถึงได้ง่ายและรวดเร็วแบบเรียลไทม์

### Task 126.3: Selection Menu Sync
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/kanban/kanban_page.dart`
- **Action:** อัปเดตฟังก์ชัน `_showOperativeFilterMenu` ให้ซิงค์กับสถานะตัวกรอง 3 โหมดที่สร้างใหม่
- **Why:** เพื่อให้การเลือกผู้ใช้งานในโหมดแมนนวลทำงานร่วมกับตัวเลือกบน Toggle ได้ถูกต้อง

### Task 126.4: Verification
- **Status:** [x] Done
- **Action:** รันการตรวจสอบความถูกต้องด้วย `flutter analyze` และทดสอบฟังก์ชันการทำงานบนเบราว์เซอร์
- **Why:** ยืนยันความสมบูรณ์และประสิทธิภาพของตัวกรองใหม่

## Phase 127: Kanban Calendar Integration

### Task 127.1: Add State & Imports
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/kanban/kanban_page.dart`
- **Action:** เพิ่ม `import 'package:intl/intl.dart';` และประกาศตัวแปร `bool _isCalendarMode = false;` และ `DateTime _calendarMonth = DateTime.now();` ใน `_KanbanPageState`
- **Why:** เพื่อรองรับโครงสร้างข้อมูลที่จำเป็นสำหรับมุมมองปฏิทินและการแสดงวันเดือนปี

### Task 127.2: Implement View Switcher Toggle
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/kanban/kanban_page.dart`
- **Action:** ปรับแต่ง `_buildHeader` ให้รองรับการกดเพื่อสลับมุมมองระหว่าง Kanban และ Calendar ทั้งใน Desktop และ Mobile
- **Why:** เพื่อให้ผู้ใช้งานสลับมุมมองไปมาได้รวดเร็วตามความต้องการ

### Task 127.3: Build Monthly Calendar Grid Widget
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/kanban/kanban_page.dart`
- **Action:** พัฒนาฟังก์ชัน `_buildCalendarView`, `_buildCalendarGrid`, และ `_buildCalendarTaskCard` โดยเซลล์วันที่ใช้ `DragTarget<TaskModel>` เพื่อให้ลากงานมาปล่อยเปลี่ยนวันได้
- **Why:** สร้างระบบปฏิทินรายเดือนแบบตอบสนองพร้อมการลากวางวันที่ทำงานร่วมกับ State Management

### Task 127.4: Build Unscheduled Task Bucket
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/kanban/kanban_page.dart`
- **Action:** พัฒนาฟังก์ชัน `_buildUnscheduledBucket` และ `_buildBucketTaskCard` โดยเชื่อมต่อ `DragTarget<TaskModel>` เพื่อยกเลิกกำหนดวันของงานให้เป็น Epoch 0 เมื่อนำมาวาง
- **Why:** เพื่อแยกจัดการงานที่ยังไม่ได้กำหนดวันให้เป็นระเบียบและเอื้อต่อการจัดสรรเวลาทีหลัง

### Task 127.5: Verification
- **Status:** [x] Done
- **Action:** ทดสอบการคอมไพล์และวิเคราะห์ประสิทธิภาพของหน้าปฏิทิน การลากวาง และการซิงค์ข้อมูลกับ Backend D1
- **Why:** ยืนยันความเสถียรและความถูกต้องในการอัปเดตข้อมูลการทำแผนของแอป

## Phase 128: Kanban Layout Refinement + Calendar Real-time Fix + D1 Bug

### Task 128.1: Fix D1 Migration Bug
- **Status:** [x] Done
- **Target File:** `cloudflare_backend/cloudflare_worker.js`
- **Action:** เพิ่มวงเล็บปิด `)` ใน CREATE TABLE `chat_messages` ที่ขาดหายไป
- **Why:** แก้ SQLITE_ERROR: incomplete input ที่ทำให้ migration ล้มเหลว

### Task 128.2: Fix Calendar Real-time Update
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/kanban/kanban_page.dart`
- **Action:** ย้าย calendar view ออกจาก `Consumer<StateBoards>` เพื่อให้ rebuild เมื่อ `_calendarMonth` เปลี่ยนผ่าน setState
- **Why:** แก้บั๊กที่ UI ปฏิทินไม่อัปเดตเมื่อเลื่อนเดือน

### Task 128.3: Add Column Dividers & Header Border
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/kanban/widgets/kanban_column.dart`
- **Action:** เพิ่มเส้นคั่นแนวตั้งระหว่างคอลัมน์ + เส้นใต้ header เพื่อให้ดูเหมือนตาราง
- **Why:** ปรับ layout ให้อ่านง่ายขึ้นตามที่ผู้ใช้ร้องขอ

### Task 128.4: Move View Switcher to Content Area
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/kanban/kanban_page.dart`
- **Action:** ย้ายปุ่ม Calendar/Kanban toggle จาก header หลักมาอยู่เหนือ content area
- **Why:** ให้ผู้ใช้เข้าถึงปุ่มสลับมุมมองได้ง่ายขึ้น

### Task 128.5: Verification
- **Status:** [x] Done
- **Action:** `flutter analyze` + ตรวจ SQL syntax + ทดสอบ UI

## Phase 129: Unified Kanban Control Strip & Header Layout Reorganization

### Task 129.1: Header Layout Cleanup & Settings Relocation
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/kanban/kanban_page.dart`
- **Action:** ลบเมนูจัดการเดิมออกจาก `_buildHeader` และย้ายปุ่มรูปเฟืองไปต่อท้ายชื่อบอร์ด
- **Why:** เพื่อจัดระเบียบให้พื้นที่ด้านบนสะอาดตาและวางเฟืองให้สังเกตง่าย

### Task 129.2: Create Compact Member Avatar Stack Widget
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/kanban/kanban_page.dart`
- **Action:** สร้าง `_buildAvatarStack` สำหรับการจัดเรียงรูปสมาชิกในแนวนอนที่ความสูง 32-36px
- **Why:** เพื่อแสดงรายการสมาชิกในบอร์ดในแนวตั้งแถบเดียวกับโหมดสลับและฟิลเตอร์

### Task 129.3: Redesign View Switcher Strip Layout
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/kanban/kanban_page.dart`
- **Action:** ปรับ `_buildViewSwitcherStrip` โดยใส่ Switcher, Filter, และ Avatar Stack ในแถบซ้าย ( scrollable ) และยึดปุ่มจัดการเดิมในแถบขวา
- **Why:** รวมศูนย์ฟังก์ชันการทำงาน และรองรับ Responsive ป้องกัน Pixel Overflow

### Task 129.4: Standardize Buttons & Icons Size to Switcher Height
- **Status:** [x] Done
- **Target File:** `my_ai_assistant/lib/ui/kanban/kanban_page.dart`
- **Action:** ปรับขนาดและ Padding ของ `_buildGhostButton` และ `_buildActionIcon` ให้เหมาะสมที่ความสูง 32-36px
- **Why:** สร้างเอกภาพและรักษา Premium Aesthetics ในหน้าจอ

### Task 129.5: E2E Verification & Analysis
- **Status:** [x] Done
- **Action:** รัน `flutter analyze` เพื่อตรวจสอบความเรียบร้อยของโค้ดและการคอมไพล์ทั้งหมด
- **Why:** เพื่อรับประกันความเสถียร 100% ปราศจากบั๊กและสไตล์มีเดียที่ถูกต้อง
