# Architecture: High-Fidelity Infrastructure & Scoped Operations

## 1. ID-First Intelligence Layer
- **`Strict Mapping Protocol`**: AI จะเห็นและสื่อสารผ่าน **ID (UUID/Timestamp)** เป็นหลักในทุกระดับ (Board, Task, Label, User) เพื่อป้องกันปัญหาชื่อซ้ำ
    - **Context Inversion**: ใน `context_builder.dart` จะใช้ฟอร์แมต `[ID: {id}] {name}` เพื่อให้ AI แยกแยะข้อมูลได้ชัดเจน
- **`Lookup Table Strategy`**: `StateChat` จะเก็บ Cache ข้อมูลบอร์ดปัจจุบัน (Labels, Members) เพื่อใช้เป็น Map สำหรับแปลง ID จาก AI กลับเป็น Display Name ในหน้า UI ทันที

## 2. Universal UI Display Container (`show_ui_content`)
- **`The Fallback Solution`**: ออกแบบ Tool นี้ให้เป็น "Beautiful Container" รองรับ:
    - **`table`**: แสดงผลรายการงานแบบละเอียด [✅ | ชื่องาน | กำหนดส่ง | ป้ายกำกับ | คนรับผิดชอบ]
    - **`plan_review`**: ใช้เมื่อ AI เสนอแผนงานล่วงหน้าที่ยังไม่เป็นงานจริง (แสดงเป็น List/Timeline สวยงาม)
    - **`empty_state`**: ใช้เมื่อไม่มีข้อมูล หรือใช้โชว์ JSON เฉพาะทางที่ AI อยากให้ User เห็น (เช่น การวางแผน) แทนข้อความ JSON ดิบๆ
- **`Rendering Guard`**: หน้าแชท (`AssistantMessageBubble`) จะดักจับ Tool Call ผ่านตัวแปร `message.toolCalls` และทำการ Mapping เพื่อเรนเดอร์ UI เฉพาะทาง
- **`Post-Text Execution Flow`**: เพื่อความเป็นธรรมชาติ ระบบจะเรนเดอร์ข้อความแชท (Text) ให้เสร็จสิ้นก่อน แล้วจึงแสดงผล Tool Logs และ Result UI (ตาราง/การ์ด) ต่อท้ายด้านล่างสุดเสมอ

## 3. Board Social Features (Sharing & Joining)
- **`Identification Transparency`**: 
    - บนหน้า **Kanban Header** จะมีปุ่มไอคอน **"Share"** หรือ **"Info"** เพื่อเปิด Dialog แสดงรายละเอียดบอร์ด
    - **Board ID Visibility**: ภายใน Dialog จะโชว์รหัสบอร์ด (UUID) อย่างชัดเจน พร้อมปุ่ม **"Copy ID"** เพื่อส่งให้เพื่อน
- **`Join Mechanism`**: 
    - หน้า **Dashboard** (รายการบอร์ด) จะมีปุ่ม **"JOIN TEAM BOARD"** ที่เด่นชัด
    - **Join Dialog**: ผู้ใช้กรอกรหัสบอร์ดที่ได้รับจากเพื่อนเพื่อเข้าร่วมทีม
    - **AI Assistance**: AI สามารถรับรหัสบอร์ดจากแชทและดำเนินการ Join ให้ผ่าน Tool `join_team_board`
    - **`Security Logic`**: การ Join จะเป็นการเพิ่ม UID ของผู้ใช้ปัจจุบันเข้าไปในฟิลด์ `members` (JSON array) ของบอร์ดนั้นใน Cloudflare D1 ทันที
    - **`Member Management (Manual Only)`**:
        - **Owner Authority**: เฉพาะเจ้าของบอร์ด (`owner_uid`) เท่านั้นที่มีสิทธิ์ลบสมาชิกออกจากบอร์ด
        - **No AI Intervention**: ป้องกันข้อผิดพลาดโดยการไม่อนุญาตให้ AI เข้าถึงฟังก์ชันการลบสมาชิก ต้องทำผ่าน UI โดยผู้ใช้ที่เป็นเจ้าของเท่านั้น

    ## 5. Administrative Sovereignty & Entry Points
    - **`Universal Context Menu`**: ทุกจุดที่แสดงรายการบอร์ด (Dashboard, Board List) จะต้องมีเมนู "More Options" (3-dot) สำหรับเจ้าของ
    - **`In-Board Governance`**: หน้า Kanban Header จะมีเมนูหลักสำหรับจัดการบอร์ดโดยเฉพาะ (Rename, Manage Members, Delete Board)
    - **`Permission-Based UI`**: ปุ่มและเมนูสำหรับการตั้งค่าบอร์ดจะถูกซ่อน (Visibility: gone) สำหรับสมาชิกทั่วไปที่ไม่ใช่เจ้าของ เพื่อป้องกันความสับสน

## 4. Persistent UI State
- **`Scroll Anchor System`**: ปรับปรุงลอจิก Scroll ของ `ListView` (reverse: true) ให้เลื่อนลงล่างสุด (Index 0) เฉพาะเมื่อมีการส่งข้อความใหม่เท่านั้น
- **`Interactive Drafts`**: การเสนอสร้างงานจะผ่าน `ProposalDraft` state เสมอ เพื่อให้ User แก้ไขข้อมูล (Title, Desc, Date, Assignees) ได้ก่อน commit จริง
- **`Action-Specific Feedback`**: เมื่อกดยืนยัน Draft แล้ว การ์ดสรุปผล (`_ConfirmedActionCard`) จะต้องแสดงสีและข้อความตามประเภทของแอคชัน:
    - **Create/Move**: สีเขียว (`GlassColors.success`) - "STRATEGY EXECUTED"
    - **Update**: สีน้ำเงิน/ฟ้า (`GlassColors.primary`) - "STRATEGY UPDATED"
    - **Delete**: สีแดง (`GlassColors.error`) - "STRATEGY DELETED"

## 6. AI Transparency & Diagnostic Layer
- **`Function Call Logging`**: ทุกครั้งที่ AI เรียกใช้ Tool (ไม่ว่าจะเป็นเบื้องหลังหรือเบื้องหน้า) จะต้องมีการแสดงผล "Diagnostic Chip" ในสายแชทเสมอ (เช่น `[🔧 Executing: query_team_tasks]`)
- **`Debugging Visibility`**: เพื่อให้ผู้ใช้/ผู้พัฒนาตรวจสอบลำดับการคิดของ AI ได้ง่ายขึ้น (ง่ายต่อการ Debug)
- **`Minimalist Vision Log`**: เปลี่ยนจากการแสดงผล Vision Analysis เป็น Bubble ใหญ่ๆ ให้เหลือเพียง Log ว่ามีการวิเคราะห์รูปภาพแล้ว เพื่อลดความซ้ำซ้อนของข้อความ

## 8. Atomic & Granular Operations
- **`One Call, One Task`**: เพื่อเพิ่มความแม่นยำ 100% เครื่องมือสร้างและแก้ไขงานจะถูกปรับให้รับข้อมูลเพียง **1 งานต่อ 1 การเรียก (Tool Call)** เท่านั้น
- **`Sequential Orchestration`**: หากมีงานหลายชิ้น AI จะต้องทำการเรียก Tool ซ้ำๆ แยกกัน (Parallel/Sequential) แทนการยัด Array ขนาดใหญ่

## 9. Draft Aggregation Engine
- **`Synthetic Batching`**: ระบบหลังบ้านจะทำการรวบรวม (Aggregate) Tool Calls ที่เป็นการเปลี่ยนแปลงข้อมูลทุกประเภท (**Create, Update, Move, Delete**) เข้าเป็น "Synthetic Batch" เดียวกันเพื่อความสวยงาม
- **`Action-Aware Batching`**: แต่ละงานใน Batch จะจดจำประเภทคำสั่งดั้งเดิมของตัวเองไว้ เพื่อให้เวลาผู้ใช้กดยืนยัน ระบบสามารถส่งคำสั่งที่ถูกต้อง (เช่น ลบบางงาน ย้ายบางงาน) แยกชิ้นกลับไปที่ API ได้อย่างแม่นยำ
- **`Sequential Rendering Protocol`**: 
    1.  **Technical Logs (Top)**: แสดงชิป Log ของทุกเครื่องมือทันที
    2.  **Text Bubble**: แสดงข้อความสนทนา
    3.  **Result UI (Bottom)**: ค่อยๆ เรนเดอร์การ์ดร่างงานหรือตารางต่อท้าย

## 10. State-Preserving Partial Updates
- **`Minimal Requirements`**: การสร้างงานใหม่ต้องการเพียง `title` เป็นฟิลด์บังคับขั้นต่ำสุด ส่วนฟิลด์อื่นหากไม่มีข้อมูลให้ปล่อยเป็น Null/ค่าเดิมในฐานข้อมูล
- **`Data Preservation`**: ระบบ Handler จะไม่ทำการเขียนทับข้อมูลเดิมด้วยค่าว่าง หากพารามิเตอร์ที่ส่งมาเป็นค่าว่างหรือไม่ได้ระบุมา (Partial Update)

## 11. Task-to-Operative Ratio (1:1 Principle)
- **`Maximum Focus`**: การสร้างงานย่อย (Sub-tasks) ที่มีประสิทธิภาพสูงสุดคือการระบุผู้รับผิดชอบที่ชัดเจนเพียง **1 คนต่อ 1 งาน** (สูงสุดไม่เกิน 2 คน) เพื่อความรวดเร็วในการดำเนินงาน

## 12. Diff-based Persistence Layer
- **`Delta Update Strategy`**: ระบบจะตรวจสอบส่วนต่าง (Diff) ระหว่างสถานะดั้งเดิมและสถานะที่แก้ไขบน UI และส่งเฉพาะข้อมูลที่เปลี่ยนแปลงจริง
- **`Robust UI Rendering`**: ทุกคอมโพเนนต์การแสดงผล (Widgets) จะต้องใช้ระบบ Null-safety ขั้นสูงสุด:
    - ห้ามเข้าถึงสมาชิกใน List โดยใช้ `.first` หรือ index ตรงๆ หากไม่มีการตรวจสอบความว่างเปล่า (Empty check)
    - ใช้ `firstWhereOrNull` หรือการตรวจสอบเงื่อนไขล่วงหน้าเพื่อป้องกัน App Crash ในกรณีที่ข้อมูลจากฐานข้อมูลไม่สมบูรณ์

## 13. Distributed Draft Persistence
- **`Message-Bound State`**: เพื่อความเสถียรสูงสุด สถานะของดราฟต์ (`ProposalDraft`) จะไม่ถูกเก็บไว้ที่ระดับ Global เพียงที่เดียว แต่จะถูกผูกติด (Attached) ไว้กับ `ChatMessage` แต่ละใบโดยตรง
- **`Historical Integrity`**: การกระทำนี้ช่วยให้ผู้ใช้สามารถย้อนดูดราฟต์เก่าๆ ในประวัติแชทได้โดยที่ข้อมูลไม่หายไป แม้จะมีดราฟต์ใหม่เกิดขึ้นมาแทนที่
- **`Async-Safe Rendering`**: หน้าแชทจะเรนเดอร์ข้อมูลจากตัว Message เอง ทำให้ลดปัญหา Race Condition ระหว่างการโหลดข้อมูลจากฐานข้อมูลและการแสดงผล UI

## 15. Specialized Action UIs
- **`Dual-Mode Checkbox Logic`**: วนระบบช่องติ๊ก (Checkbox) บนการ์ดร่างงานให้ทำงานตามประเภทของคำสั่ง:
    - **Deletion Mode**: ช่องติ๊กทำหน้าที่เป็น `isSelected` เพื่อเลือกว่าจะ "ยืนยันการลบ" รายการนั้นหรือไม่
    - **Operational Mode (Create, Update, Move)**: ช่องติ๊กทำหน้าที่เป็น `isCompleted` เพื่อให้ผู้ใช้กำหนดสถานะงานได้ด้วยตนเอง
- **`Status Visibility in Deletion`**: แม้จะอยู่ในโหมดการลบ ระบบจะแสดงสถานะความสำเร็จของงาน (Done/Pending) อย่างชัดเจนภายในเนื้อหาการ์ด เพื่อช่วยประกอบการตัดสินใจก่อนยืนยันการลบ
- **`Manual Status Override`**: ในโหมดการย้ายงาน (Move) ผู้ใช้สามารถติ๊ก "เสร็จสิ้น" ควบคู่ไปกับการย้ายได้ทันที ระบบจะทำการประมวลผลการเปลี่ยนแปลงทั้งสองส่วนในคำสั่งเดียว

## 16. Integrated Execution Feedback
- **`Embedded Summary Card`**: ระบบจะไม่สร้างข้อความแชทใหม่สำหรับรายงานสรุป แต่จะทำการอัปเดตการ์ดร่างงานเดิมให้กลายเป็น **Confirmed Card** ที่มีรายละเอียดครบถ้วนภายในตัว:
    - แสดงรายการการกระทำรายรายการ (Action Logs) ภายใต้หัวข้อ "STRATEGY EXECUTED"
    - ใช้สัญลักษณ์สื่อสารที่ชัดเจน (✅, 🚚, 🗑️, 🚫)
- **`Synchronous Persistence Guarantee`**: ทุกฟังก์ชัน Handler (Create, Move, Update) จะต้องรองรับพารามิเตอร์ `is_completed` แบบข้ามฟังก์ชัน เพื่อให้การ Manual Override ของผู้ใช้ถูกบันทึกอย่างสมบูรณ์แบบ

## 17. Ubiquitous Floating Assistant
- **`Draggable Chat Head`**: ระบบปุ่มลอย (Floating Button) ที่ปรากฏทุกหน้า:
    - **Right-Side Default**: เริ่มต้นการแสดงผลที่ขอบหน้าจอด้านขวาเสมอ
    - **Persistence**: ปุ่มจะคงอยู่บนหน้าจอถาวร ไม่สามารถลากออกเพื่อปิดการใช้งานได้
- **`Resizable Floating Panel`**: หน้าต่างแชทลอยตัวที่ยืดหยุ่นสูง:
    - **User-Controlled Scaling**: ผู้ใช้สามารถลากที่มุมหรือขอบหน้าต่างเพื่อปรับความกว้างและความสูงได้เอง
    - **Compact Aesthetic**: ลดความหนาของขอบและขนาดปุ่มเพื่อให้กินพื้นที่หน้าจอน้อยที่สุด (Lean Design)

## 18. Zero-Redundancy Reuse Architecture
- **`Core Component Extraction`**: เพื่อป้องกันการเขียนโค้ดซ้ำซ้อน เนื้อหาหลักของหน้าแชท (Chat Engine + UI Bubbles) จะถูกสกัดออกมาเป็น **`AetherChatView`**:
    - `AetherChatView` จะเป็นศูนย์กลางลอจิกเดียวที่ทั้งหน้าจอ `ChatPage` (แบบเต็มจอ) และ `FloatingPanel` (แบบลอยตัว) เรียกใช้งาน
- **`State Synchronization`**: ทั้งสองมุมมองจะผูกติดกับ `StateChat` (Provider) ตัวเดียวกัน ทำให้การคุยค้างไว้ในแบบลอยตัว จะไปปรากฏในแบบเต็มจอทันทีอย่างไร้รอยต่อ

## 19. Ephemeral Session Management
- **`Session Reset Protocol`**: ระบบมีปุ่มสำหรับล้างประวัติการสนทนาในรอบปัจจุบัน (Local Reset) เพื่อเริ่มต้นการทำงานใหม่:
    - ล้างรายการข้อความ (`_messages`) ใน `StateChat`
    - รีเซ็ตประวัติในหน่วยความจำของ AI (`MistyAgent._history`)
- **`Privacy by Design`**: เนื่องจากไม่มีการบันทึกประวัติลงฐานข้อมูลถาวร การรีเซ็ตจะคืนค่าพื้นที่หน่วยความจำและทำให้ AI ลืมบริบทเก่าทั้งหมดเพื่อความแม่นยำในหัวข้อใหม่

## 20. Client-Side UI Persistence
- **`Geometry Memory`**: ระบบจะบันทึกพิกัดและขนาดหน้าต่างแชท (Width, Height, Offset) ที่ผู้ใช้ปรับแต่งไว้ลงใน Local Storage:
    - ข้อมูลจะถูกดึงกลับมาใช้โดยอัตโนมัติเมื่อเปิดแอปหรือเปลี่ยนหน้า
    - ช่วยลดภาระของผู้ใช้ในการปรับขนาดหน้าต่างซ้ำๆ (Frictionless Experience)

## 21. Action Accessibility & Header Hierarchy
- **`Layering Protocol`**: ปุ่มคำสั่งสำคัญ (เช่น Reset) จะต้องถูกวางไว้ใน Layer สูงสุดของ `Stack` เสมอ เพื่อประกันความสามารถในการกด (Hit-test availability)
- **`Header Refinement`**: หน้าจอหลักจะรักษาความคลีนโดยการรวมศูนย์ปุ่มคำสั่งไว้ที่จุดเดียว:
    - ลบปุ่มเสริม (Search, Tune) ที่ไม่ได้ใช้งานจริงออก
    - แทนที่ด้วยปุ่มควบคุมสถานะ (Reset Session) ที่ชัดเจนและมีผลทั้งระบบ
- **`Feedback Parity`**: ทุกปุ่มคำสั่งสำคัญต้องมีการตอบสนอง (Feedback) ที่เหมือนกันในทุกหน้าจอ:
    - **Visual**: มี Hover effect และ Splash animation เมื่อกด
    - **System**: แสดง SnackBar แจ้งเตือนสถานะเมื่อดำเนินการเสร็จสิ้น

## 22. Personalized Strategic Calendar
- **`Zero-Noise Filtering`**: แสดงผลเฉพาะงานที่เกี่ยวข้องกับผู้ใช้ปัจจุบัน (Assignee) และซ่อนงานที่เสร็จแล้ว
- **`Visual Board Affinity (V3)`**: การ์ดงานรายเดือนใช้สีตามบอร์ด พร้อมตัวอักษรสีขาวคอนทราสต์สูง
- **`Temporal Watchface Sentinel`**: ตัวบอกเวลาปัจจุบันในรายวันจะอัปเดตแบบ Real-time (HH/mm/ss)
- **`Vinyl Needle head`**: ปลายเส้นสีแดง (Sentinel Line) จะมีลักษณะเป็น "หัวเข็ม" (Stylized Tip) ที่ชี้ไปยังพิกัดเวลาปัจจุบันอย่างชัดเจน
- **`Gapless Vertical Pulse`**: เส้นนำสายตาแนวตั้งระหว่างชั่วโมงจะเป็นจุดประที่หนาแน่น (Dense Dots) และเชื่อมต่อกันแบบ 100% ไร้รอยต่อ
- **`Expandable Unity Protocol`**: แถวชั่วโมงขยายความสูงได้ไม่จำกัด และเส้นนำสายตาขยายตัวตามอัตโนมัติ
- **`Centered Temporal Markers`**: ตัวเลขบอกเวลาทุกรายการจะถูกจัดวางไว้กึ่งกลางของแถวชั่วโมงเสมอ
- **`Executive Strategic Void`**: พื้นที่ว่างจะใช้เลเอาต์ที่กว้างขวาง พร้อมข้อความ "NO STRATEGIC TASKS"

## 23. Custom Modular Kanban Architecture
- **`Decoupled Column Rendering`**: ละทิ้งการใช้ Monolithic Board Controller และเปลี่ยนมาใช้ระบบคอลัมน์อิสระที่มี `Consumer<StateTasks>` ของตัวเอง
- **`Native Drag & Drop Persistence`**: การลากสลับตำแหน่งภายในคอลัมน์ (Intra-column) ต้องมีการบันทึกสถานะลง Database ทันทีเพื่อป้องกันข้อมูลเด้งกลับ
- **`Aesthetic High-Fidelity`**: การ์ดงานต้องรักษามาตรฐานความงามระดับพรีเมียม:
    - ใช้ฟอนต์ Headline ตัวใหญ่หนาพิเศษ (w900) สำหรับชื่องาน
    - ใช้ระบบ Padding ที่โปร่งสบาย (24px+) และเงาที่นุ่มนวล
- **`Structural Sync Protocol`**: ระบบ WebSocket จะสั่งให้รีโหลดโครงสร้างบอร์ด (คอลัมน์) เฉพาะเมื่อมีการเปลี่ยนแปลงโครงสร้างเท่านั้น (Structural Delta)

## 24. High-Stability State Synchronization
- **`Syntax Integrity Mandate`**: การแก้ไขไฟล์ที่มีโครงสร้างซับซ้อน (เช่น Kanban) จะต้องใช้การตรวจสอบวงเล็บและลำดับฟังก์ชันอย่างเคร่งครัด
- **`Hybrid Polling Resilience`**: เมื่อระบบ WebSocket ล้มเหลว (Fallback) ระบบจะต้องทำการซิงค์ทั้ง **ข้อมูลงาน (Tasks)** และ **โครงสร้างบอร์ด (Board Metadata)** ทุกรอบการ Polling เพื่อป้องกันอาการคอลัมน์ไม่อัปเดต
- **`Secure WebSocket Handshake`**: ระบบหลังบ้าน (Worker) ต้องใช้มาตรฐานการตอบกลับ 101 ที่เรียบง่ายที่สุดสำหรับ Cloudflare DO เพื่อหลีกเลี่ยงความขัดแย้งของ Header ใน Browser
- **`Persistent Scroll Physics`**: บาร์เลื่อนแนวนอนต้องใช้ `AlwaysScrollableScrollPhysics` เพื่อบังคับให้แสดงผลบน Web ตลอดเวลา แม้ในช่วงจังหวะที่มีการ Rebuild หน้าจอ
- **`Atomic Card Sync`**: เพื่อความนิ่งสูงสุด (Zero-Jump) การ์ดงานแต่ละใบจะอัปเดตตัวเองผ่าน `Consumer<StateTasks>`
- **`True Horizontal Navigation`**: บาร์เลื่อนแนวขวางต้องปรากฏที่ขอบล่างของหน้าจอถาวร

## 26. Rich Payload Sync Protocol (Instant Performance)
- **`Data-In-Signal`**: เพื่อลด Latency ในการอัปเดตระบบ Real-time ข้อความ WebSocket จะไม่เป็นเพียงสัญญาณแจ้งเตือน แต่จะต้องบรรจุข้อมูลงาน (Task Payload) ชุดล่าสุดมาด้วย
- **`Direct Injection`**: เมื่อได้รับข้อความ WebSocket แอปจะนำข้อมูลใน Payload ไปเขียนทับ (Inject) ในหน่วยความจำโดยตรงและสั่งวาดหน้าจอใหม่ทันที โดยข้ามขั้นตอนการยิง API Fetch เพื่อความรวดเร็วสูงสุด

## 27. Gesture Sovereignty (Zero-Conflict Drag)
- **`Dedicated Drag Handle`**: เพื่อป้องกันการแย่งสัญญาณสัมผัสระหว่างการกดปุ่ม (Tap) และการลาก (Drag) การ์ดงานจะเพิ่ม "จุดสัมผัสสำหรับลาก" (Drag Handle) ที่ชัดเจน
- **`Pointer Interception`**: การใช้ Drag Handle จะช่วยประกันว่าผู้ใช้สามารถลากงานได้ 100% แม้การ์ดจะมีปุ่มกดจำนวนมากอยู่ภายในก็ตาม

## 28. Surgical State Management (Card-Level Controllers)
- **`ID-Subscription Protocol`**: เพื่อประสิทธิภาพสูงสุด (High FPS) การ์ดงานแต่ละใบจะเฝ้าฟังการอัปเดตแยกตาม ID ของตัวเอง (Surgical Rebuild)
- **`Value-Based Notifications`**: หลีกเลี่ยงการใช้ `notifyListeners()` ที่ระดับ Global บอร์ด แต่ให้ใช้ตัวนำสัญญาณเฉพาะจุด (เช่น `ValueNotifier`) เพื่อวาดเฉพาะการ์ดที่เปลี่ยนข้อมูลจริงๆ

## 29. Isolated Metadata Sync
- **`Context-Scoped Fetching`**: เมื่อมีการเปลี่ยนแปลงโครงสร้างบอร์ด แอปจะดึงข้อมูล Metadata เฉพาะบอร์ดที่ "กำลังแสดงผลอยู่" (Active Board) เท่านั้น
- **`Bandwidth Conservation`**: ห้ามสั่งโหลดรายการบอร์ดทั้งหมด (`fetchAllBoards`) เพื่อตอบสนองต่อ Event ของบอร์ดใบเดียว

## 30. Authoritative WebSocket Truth
- **`Zero-Round-Trip Rule`**: ข้อมูลที่ส่งมาใน Rich Payload ของ WebSocket ให้ถือว่าเป็น "ความจริงสูงสุด" 
- **`Immediate Commitment`**: แอปต้องทำการอัปเดต UI ทันทีจาก Payload นั้นโดยไม่ต้องทำการ Fetch API ซ้ำเพื่อยืนยันข้อมูล (ลด Network Overhead 100%)

## 31. Visual Drag Feedback Protocol
- **`Predictive Slot Indicator`**: ในขณะที่ผู้ใช้กำลังลากการ์ดงาน ระบบจะต้องแสดง "ช่องว่างจำลอง" (Dashed Ghost Slot) ในตำแหน่งที่การ์ดจะถูกวางจริง เพื่อลดความสับสนและเพิ่มความแม่นยำในการจัดลำดับ
- **`Structural Motion`**: การลากสลับคอลัมน์ (Column Reordering) จะต้องมีการอัปเดตลำดับในฐานข้อมูลทันที เพื่อให้โครงสร้างบอร์ดซิงค์ตรงกันทั้งทีม

## 32. Sovereign Column Reordering
- **`Header Drag Handle`**: เพื่อป้องกันการขัดแย้งระหว่างการเลื่อนบอร์ด (Horizontal Scroll) และการย้ายคอลัมน์ ระบบจะเพิ่ม "จุดจับลาก" (Drag Handle) ไว้ที่ส่วนหัวของคอลัมน์เท่านั้น
- **`Target Gap Indicator`**: เมื่อมีการลากคอลัมน์ ระบบจะแสดง "เส้นประสีทองแนวตั้ง" (Vertical Gap) ระหว่างคอลัมน์เพื่อบอกจุดหมายที่คอลัมน์นั้นจะไปแทรกอยู่จริง
- **`Delayed Drag Activation`**: ใช้ระบบ `delay` 200-300ms ในการเริ่มลาก เพื่อให้ระบบยังสามารถแยกแยะการ Tap ปกติและการลากได้อย่างแม่นยำ

## 25. Architectural File Size Mandate (Anti-Bloat)
- **`Strict Size Limit`**: ห้ามให้ไฟล์ Dart ใดๆ มีขนาดเกิน 600-700 บรรทัดโดยเด็ดขาด 
- **`Proactive Component Extraction`**: ผู้ออกแบบและแก้ไขระบบต้องประเมินขนาดไฟล์ล่วงหน้า หากพบว่าแนวโน้มไฟล์จะบวม (เช่น การใส่ UI คอลัมน์และ UI การ์ดไว้ในไฟล์เดียว) จะต้องทำการ Extract คลาสหรือวิดเจ็ตนั้นๆ ออกไปเป็นไฟล์ใหม่ในโฟลเดอร์ย่อย (เช่น `widgets/kanban_column.dart`, `widgets/kanban_card.dart`) ตั้งแต่เริ่มต้นการพัฒนา



## 7. Modular UI Component Architecture
- **`Atomic Decomposition`**: เพื่อรักษาความสะอาดของโค้ด (Clean Code) คอมโพเนนต์ที่ซับซ้อนในหน้าแชทจะถูกแยกออกเป็นไฟล์ย่อย:
    - `chat_bubbles.dart`: คลาสหลักสำหรับจัดการการจัดวางข้อความ User/Assistant
    - `draft_cards.dart`: จัดการการ์ดร่างงาน (Proposals) และการยืนยันผล (Confirmation)
    - `structured_ui_bubbles.dart`: จัดการการแสดงผลตาราง แผนงาน และสถานะว่าง (Empty State)
    - `technical_logs.dart`: จัดการการแสดงผล Log การทำงานของ AI
