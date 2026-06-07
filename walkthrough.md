# Walkthrough: Infrastructure Setup and Git Migration (VaultTask)

We have successfully migrated the Calenda backend to a local execution environment (Miniflare / `wrangler dev`), integrated OpenRouter (using `google/gemma-4-26b-a4b-it`), and initialized a new GitHub repository for the upgraded version **VaultTask**.

## 🛠️ Infrastructure & Local Development (Miniflare)
- **Central Environment Config**: Created `env_config.dart` containing the configuration toggle `useLocalBackend`. This automatically resolves the correct endpoint URL depending on the platform (Web, Android emulator, or Native desktop/iOS).
- **Frontend Refactoring**:
  - `api_cloudflare.dart`: Updated to use dynamic `EnvConfig.backendUrl` and specified `google/gemma-4-26b-a4b-it` as the default model.
  - `auth_service.dart`: Updated user registration to point to the local worker instance.
  - `misty_agent.dart`: Updated misty chat requests to go through the local backend and set model ID to the target Gemma model.
- **Local Database Setup**: Configured SQLite for local D1 binding and synced schemas locally using `npx wrangler d1 execute`.

## 🤖 OpenRouter & AI Chat Completions Routing
- **Worker AI Proxy**: Updated `/api/ai/chat` in `cloudflare_worker.js` to redirect requests to OpenRouter's endpoint: `https://openrouter.ai/api/v1/chat/completions`.
- **API Key & Model ID**: Configured it to authenticate using the user's OpenRouter API key (with fallback) and forced the model ID to `google/gemma-4-26b-a4b-it` across both single-turn description generation and streaming chat completions.
- **Verification**: Verified using `curl` that both local database inserts and OpenRouter chat completions work seamlessly with the local backend.

## 🤖 Phase 97: Strict Chat Channel Separation & Sidebar UX
- **Decoupled Chat Contexts**: Completely separated global chat state and task chat state within `StateChat` to prevent leakage.
  - Global UI queries `messages` and `isTyping` from the global context.
  - Task dialog (`TaskEditModal`) queries `taskMessages` and `isTaskTyping` from the task context.
- **Task Session Initialization & Loading**: Fixed session loading in `StateChat.selectTaskSession` and updated the session name dynamically in Cloudflare D1 based on the task's title.
- **Task Discussion Streams**: Introduced `StateChat.sendTaskMessageToAI` specifically tailored for task discussion (no attachment logic/draft building overheads) using a separate task agent.
- **Verification**: Verified using static analysis that the code builds and runs correctly.

## 📦 GitHub Repository Migration (VaultTask)
- **Git Initialization**: Initialized a new local Git repository in the workspace.
- **Remote Linking**: Configured remote origin to link with `git@github.com:EreoY/VaultTask.git`.
- **Initial Push**: staged, committed, and successfully pushed the codebase to the `main` branch of EreoY/VaultTask.

## 📊 Phase 109: Dashboard Milestones Filtering and Web/WebP Upload Support
- **Upcoming Milestones Filter**: แก้ไขเงื่อนไขการกรองงานที่เสร็จแล้วในหน้า Dashboard (`dashboard_page.dart`) โดยใช้การตรวจสอบสถานะ `task.isCompleted` (Checkbox) แทนการเช็กด้วยชื่อคอลัมน์แบบเดิม เพื่อรองรับคอลัมน์แบบ Custom Name ของผู้ใช้งานได้อย่างสมบูรณ์
- **Web/.webp File Upload Support**: ปรับปรุงฟังก์ชันการเดาประเภทไฟล์ `_guessMimeType` ใน `state_chat.dart` โดยแมปไฟล์นามสกุล `.web` และ `.webp` ให้ส่งเป็น MIME type `image/jpeg` เพื่อความเข้ากันได้แบบ 100% กับ AI Vision API บน OpenRouter/Gemini ป้องกันปัญหาการปฏิเสธไฟล์รูปภาพ
- **Verification**: ตรวจสอบโครงสร้างโค้ดด้วยการรัน `flutter analyze` เรียบร้อย ไม่พบ Compile Error หรือข้อผิดพลาดใดๆ

## 🌐 Phase 110: Fix Chat Attachment File Picking on Web
- **Refactor GlassIconButton**: ปรับปรุงวิดเจ็ต `GlassIconButton` ใน `glass_widgets.dart` จากโครงสร้างที่ใช้ `GestureDetector` แบบเดิม ไปเป็นโครงสร้างที่ใช้ `ClipRRect` ครอบ `Material` และ `InkWell`
- **User Activation Compliance**: การใช้ `InkWell` ช่วยแปลง pointer events ของ Flutter Web ให้กลายเป็น Native Click gesture ของเบราว์เซอร์อย่างเสถียร ซึ่งสอดคล้องกับมาตรการความปลอดภัยของเว็บเบราว์เซอร์ในการอนุญาตเปิดหน้าต่างเลือกไฟล์ (User Activation/Gesture Policy) ป้องกันปัญหากดแนบไฟล์แล้วไม่มีการแสดงกล่องโต้ตอบการแนบไฟล์ขึ้นมาบนเว็บ
- **Verification**: ตรวจสอบโครงสร้างโค้ดด้วยการรัน `flutter analyze` เรียบร้อย ไม่พบข้อผิดพลาด

## 🌐 Phase 112: Fix Web User Activation for Chat File Uploads
- **Gesture-Safe Attachment Button**: ปรับแต่งวิดเจ็ต `_buildActionButton` ใน `chat_input.dart` เพื่อหลีกเลี่ยงการใช้ `GlassIconButton` (ซึ่งมี `BackdropFilter` อยู่ภายใน) บนหน้าจอควบคุมแชท และเลือกใช้โครงสร้าง `InkWell` ครอบ `Container` ที่มีสไตล์กึ่งโปร่งใสแทน เพื่อให้ Click Event ถูกส่งผ่านไปยังเว็บเบราว์เซอร์และฟังก์ชัน `FilePicker.pickFiles()` เป็นแบบ Synchronous โดยตรง ทำให้ระบบความปลอดภัยของเว็บเบราว์เซอร์ยอมรับ User Activation และอนุญาตให้เปิด Dialog แนบไฟล์ได้เสถียร
- **Debug UI Cleanup**: ลบคำสั่งเรียกแสดง SnackBar และ AlertDialog ออกจากโมดูล `pickFiles` ใน `state_chat.dart` คงไว้เพียงการทำ Log ข้อมูลและแสดงรายละเอียดข้อผิดพลาด/ความก้าวหน้าลงในคอนโซลของ Terminal (debugPrint) เพื่อให้ผู้ใช้สามารถติดตามข้อมูลได้สะดวกโดยไม่ถูกขัดจังหวะหน้าจอขณะใช้งานหน้าเว็บ
- **Verification**: ตรวจสอบโค้ดหลังแก้ไขเรียบร้อยด้วย `flutter analyze` ผ่านฉลุย ไม่มี Compile errors หรือปัญหาโครงสร้างทางไวยากรณ์ใดๆ

## 🌐 Phase 113: Implement Direct HTML Input Picker for Web Chat Attachments
- **Direct HTML Input File Picker (Web)**: พัฒนาตัวช่วยเลือกไฟล์เฉพาะสำหรับ Flutter Web (`web_file_picker_web.dart`) โดยการสร้าง `html.FileUploadInputElement` แบบ Dynamic ผ่าน `dart:html` เพื่อเลี่ยงปัญหาของแพ็กเกจ `file_picker` ที่มักเกิด focus-loss/cancellation bug บนเบราว์เซอร์ พร้อมทั้งแนบ input เข้ากับ DOM body (`html.document.body.append`) เพื่อป้องกันปัญหาระบบ Garbage Collection ทำลาย element ก่อนที่ผู้ใช้จะเลือกไฟล์เสร็จสิ้น
- **Native Platform Stub**: สร้าง stub file (`web_file_picker_stub.dart`) เพื่อป้องกันข้อผิดพลาดในการคอมไพล์สำหรับแพลตฟอร์ม Native (iOS/Android/Desktop) ที่ไม่สามารถใช้งานไลบรารี `dart:html` ได้
- **Chat Context Pending Files Route**: ปรับปรุงฟังก์ชัน `pickFiles` รวมถึง getter และตัวลบไฟล์ (`pendingFileMaps`, `removeFile`, `clearPendingFiles`) ใน `state_chat.dart` ให้เรียกใช้ Custom Web Picker เมื่ออยู่ในเว็บ และชี้ไปยังไฟล์พักรอแนบที่ถูกต้องตามบริบทห้องแชต (Global Chat vs Task Chat)
- **Verification**: รัน static analysis ผ่านเรียบร้อย ไม่พบ syntax errors หรือข้อผิดพลาดในการนำเข้าไลบรารีใดๆ

## 🔔 Phase 114: Task Comments Read State Tracking & Dashboard Notification Badge
- **StateTasks Comment Read Tracking**: เพิ่มฟังก์ชันการติดตามสถานะการอ่านความคิดเห็น (Comment Read State) โดยบันทึกเวลาที่อ่านล่าสุดในหน่วยความจำแยกตาม `taskId` และจัดเตรียม getter `getUnreadCommentsCount(taskId)` เพื่อคำนวณจำนวนความคิดเห็นที่ยังไม่ได้อ่าน
- **Mark Comments as Read on Load/Update**: ปรับปรุง `TaskEditModal` ให้ระบุเวลาเปิดอ่าน/อัปเดตความคิดเห็น โดยเรียกใช้ `stateTasks.markTaskCommentsAsRead(taskId)` ทันทีที่โหลดข้อมูลเสร็จหรือมีข้อความ/คำอภิปรายเข้ามาใหม่ เพื่อให้สถานะเปลี่ยนเป็นอ่านแล้วแบบเรียลไทม์
- **Dashboard Notification Badge**: ปรับแต่งวิดเจ็ตแสดงไอคอนกระดิ่งแจ้งเตือนบนหน้า Dashboard (`DashboardPage`) ให้ดึงจำนวนความเห็นที่ยังไม่ได้อ่านจาก `StateTasks` พร้อมทั้งแสดงตัวเลขแจ้งเตือน (Badge) สีแดงสวยงามอย่างถูกต้อง และเมื่อคลิกเข้าไปอ่านใน TaskEditModal แล้ว เลขแจ้งเตือนจะลดลงทันที
- **Verification**: ตรวจสอบโค้ดโดยรัน `flutter analyze` เรียบร้อย ไม่พบ Compile error หรือข้อผิดพลาดทางด้าน Syntax
## 🌐 Phase 115: Restore FilePicker and Stabilize Tab Switching via IndexedStack
- **FilePicker Restoration (Task 115.1)**: เปลี่ยนวิธีการเลือกไฟล์กลับมาใช้ `FilePicker.pickFiles()` ที่เรียบง่ายและเป็นมาตรฐาน พร้อมทั้งใส่การพิมพ์ประวัติและ debugPrint ข้อมูลประเภทไฟล์ ขนาด และขีดจำกัดอย่างละเอียด ทำให้ระบบตรวจจับและอัปโหลดไฟล์ทำงานได้อย่างถูกต้องและตรวจสอบได้ง่ายขึ้น
- **Smooth Navigation & State Preservation (Task 115.2)**: เปลี่ยนโครงสร้างการเปลี่ยนหน้าใน `AppShell` จากการใช้ `AnimatedSwitcher` ที่จะทำลายและสร้างหน้าใหม่ขึ้นมาใหม่ทุกครั้งที่สลับแท็บ ไปเป็น `IndexedStack` ซึ่งจะรักษาสถานะ (State) ของทุกหน้าไว้ในหน่วยความจำและไม่ทำให้หน้าแชทหรือหน้าอื่นๆ รีโหลด/กระพริบเมื่อสลับหน้าจอไปมา
- **Notification Mark-Read Fix**: แก้ไขบั๊กการอ่านแจ้งเตือนโดยลบ `markAllCommentsAsReadForTask()` ออกจาก `TaskEditModal` เพื่อไม่ให้การเปิดดูรายละเอียดงานเป็นการทำเครื่องหมาย "อ่านแล้ว" ให้กับคอมเมนต์ทั้งหมดโดยอัตโนมัติ ส่งผลให้คอมเมนต์จะถูกทำเครื่องหมายว่าอ่านแล้วก็ต่อเมื่อผู้ใช้กดเลือกเฉพาะคอมเมนต์นั้น ๆ ในหน้า Dashboard เท่านั้น
- **Robust Web FilePicker Implementation**: แก้ไขปัญหา `FilePicker` บนเว็บเบราว์เซอร์คืนค่าเป็น `null` เนื่องจากกลไกความปลอดภัยของเบราว์เซอร์และการแย่งโฟกัสของหน้าจอ CanvasKit โดยเปลี่ยนมาใช้ Custom File Picker (`web_file_picker_web.dart`) ที่เรียกใช้ `<input type="file">` ของ HTML ตรง ๆ ผ่าน `dart:html` ร่วมกับระบบ event listener แบบซิงโครนัสเพื่อหลีกเลี่ยงข้อผิดพลาดในการดักจับโฟกัส พร้อมใช้ conditional imports เพื่อป้องกัน compile error บนแพลตฟอร์มอื่น ๆ
- **Verification**: รันตรวจสอบ syntax ด้วยคำสั่ง `flutter analyze` เรียบร้อย ไม่พบ Compile Error หรือข้อผิดพลาดใด ๆ บนโปรเจกต์

## 🌐 Phase 117: Diagnostics and Custom Focus-Immune Web FilePicker Implementation
- **Diagnostic Logging (Task 117.1)**: เพิ่มการบันทึก Log ในหน้าจอและสเตตของแชท (`StateChat`, `AetherChatView`, และ `AetherChatInput`) เพื่อตรวจหาสาเหตุที่การเลือกไฟล์คืนค่าเป็น `null` ทันทีหลังจากคลิกปุ่มเลือกไฟล์
- **Focus-Immune Custom File Picker (Task 117.2)**: ออกแบบและพัฒนาตัวช่วยเลือกไฟล์สำหรับ Web (`custom_file_picker_web.dart`, `custom_file_picker_stub.dart`, และ `custom_file_picker.dart`) โดยสร้าง `html.InputElement` และอ่านข้อมูลไฟล์ด้วย `FileReader` ของ HTML5 ผ่านการดักฟังเฉพาะเหตุการณ์ `onChange` เพียงอย่างเดียว (ไม่ดักฟัง `focus`/`blur` event เหมือนในแพ็กเกจ `file_picker` เพื่อป้องกันปัญหาการยกเลิกการเลือกไฟล์ก่อนผู้ใช้จะกดเลือกสำเร็จบน Chrome Linux/Wayland) พร้อมนำเข้ามาสลับใช้งานบน `StateChat` ผ่านระบบ conditional imports อย่างถูกต้องและปลอดภัย
- **Verification**: ตรวจสอบความสมบูรณ์และทดสอบการคอมไพล์ผ่าน `flutter analyze` เรียบร้อย ไม่พบ Compile Error หรือ Syntax Error ใดๆ ในโค้ดใหม่

## 🌐 Phase 118: Web File Picker Gesture Fix & Stale Process Cleanup
- **StateChat Restructuring (Task 118.1)**: เพิ่มฟังก์ชัน `addPendingFiles(List<PlatformFile>)` ใน `StateChat` เพื่ออนุญาตให้ UI layer นำส่งไฟล์ที่เลือกได้โดยตรงหลังจากการกดปุ่ม (Gesture callback) บนเบราว์เซอร์ ซึ่งเป็นการหลีกเลี่ยงข้อจำกัดความปลอดภัย (User Activation Policy) ของเว็บเบราว์เซอร์ที่บล็อกการเปิด dialog หากทำผ่าน asynchronous call ใน state manager
- **AetherChatInput Direct Selection (Task 118.2)**: เปลี่ยน callback จาก `onPickFile` เป็น `onFilesPicked` ใน `chat_input.dart` และย้ายการทำงานของ `FilePicker.pickFiles()` ไปเรียกตรงใน `onTap`/`onPressed` ของปุ่มคลิกเลือกไฟล์ เพื่อให้ทำงานใน Context ของการทำงานแบบซิงโครนัสจากแรงกดของผู้ใช้
- **AetherChatView Wiring (Task 118.3)**: เชื่อมต่อปุ่มเลือกไฟล์ใน `aether_chat_view.dart` ให้นำส่งไฟล์ไปยัง `stateChat.addPendingFiles(files)` หลังจากการดึงไฟล์เสร็จสมบูรณ์
- **Cleaned Code & Removed Debug Spam (Task 118.4)**: ลบประวัติ debugPrint ที่สแปมหน้าจอ และลบเมธอดขยะหรือ unused imports ออกอย่างหมดจด คืนค่าสไตล์ blur ของ Glassmorphism ในกล่องอินพุตให้สวยงามหรูหราเช่นเดิม
- **Stale Process Cleanup (Task 118.5)**: เพิ่มคำสั่งล้างและฆ่าโปรเซสตกค้าง (`wrangler dev` และ `miniflare`) ในสคริปต์ `run_local.sh` เพื่อป้องกันปัญหาการชนพอร์ต (Port Conflict) และปัญหาการแคชไฟล์เดิมของระบบหลังบ้าน
- **Verification (Task 118.6)**: รัน `flutter analyze --no-pub` ตรวจสอบไวยากรณ์ผ่านฉลุย ปราศจาก Compile Error หรือ Warning ในส่วนไฟล์ที่แก้ไขทั้งหมด

