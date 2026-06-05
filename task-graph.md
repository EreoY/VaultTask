## Phase 91: UI Resiliency & CORS Network Image Exception Hardening

> **Workflow Mandate:** อัปเดต Task Graph และ Re-Sync ทุกครั้งที่จบ 1 Task ย่อย (Rule 0 & V2.1 Protocol)
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