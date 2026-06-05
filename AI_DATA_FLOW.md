# AI Data Flow & Key Storage (Calenda)

## ภาพรวมโครงสร้าง (ข้อความ)
```
User (Chat tab)
  └─ Bottom sheet "AI Settings" → ใส่ Gemini API Key
       → StateChat.updateApiKey(key)
         └─ AuthService.saveUserApiKey(key)  // SharedPreferences (local-only)
         └─ AiCoreRouter(apiKeyOverride=key)

แชท (ระบบโต้ตอบอัจฉริยะ)
  └─ StateChat.sendMessageToAI(text)
       ├─ add user message → UI
       ├─ AI Analysis Phase:
       │    ├─ Gemini 3.1 Flash lite + Advanced System Instructions
       │    ├─ Semantic Reasoning: บอทวิเคราะห์คอลัมน์จากบริบทจริงของบอร์ด
       │    └─ Context Injection: ส่งรายชื่อสมาชิกและคอลัมน์ปัจจุบันเข้าไปใน Prompt
       ├─ Tool Calling (Implemented):
       │    - create_team_task / create_personal_task
       │    - update_task (แก้ไขทุกฟิลด์ในคำสั่งเดียว)
       │    - delete_task (ลบรายตัวหรือ Batch)
       │    - query_team_tasks (ดึงข้อมูลมาวิเคราะห์ก่อนแก้)
       │    - query_board_members (ดึงสมาชิกบอร์ด)
       ├─ Draft State Merge (Description Preservation):
       │    └─ หากบอทเสนอแก้สมาชิก แต่รายละเอียดงานหาย ระบบจะดึงจาก Draft เดิมมาเติมให้อัตโนมัติ
       ├─ UI Proposal: แสดงการ์ดให้ผู้ใช้กดยืนยัน ( ✅ ยืนยัน / ❌ ยกเลิก)
       └─ Final Execution: เมื่อกดยืนยัน → ยิง Cloudflare API + กระจาย Real-time ผ่าน WebSocket

Tasks/Boards
  - personal: DbPersonalSqlite (ออฟไลน์)
  - team: ApiCloudflare → Worker/D1 (มี WebSocket แจ้งเปลี่ยนแปลง)
```

## Key Storage & Environment
- **Private Key Storage:** `user_api_key` เก็บใน SharedPreferences (เก็บบนเครื่องผู้ใช้ 100% ไม่ส่งขึ้น Server)
- **Web Asset Fix:** การโหลด `.env` และไอคอนแยกตามแพลตฟอร์ม (kIsWeb) เพื่อแก้ปัญหา 404 บนเบราว์เซอร์

## ฟีเจอร์เด่นด้าน LLM (Presentation Highlights)
1. **Dynamic Semantic Inference:** บอทสามารถ "เดา" คอลัมน์ที่เหมาะสมจากชื่อคอลัมน์ที่ผู้ใช้ตั้งเองได้ (เช่น บอร์ดมีช่อง "รอดำเนินการ" บอทจะรู้ว่างานใหม่ควรลงที่นี่)
2. **Flexible Member Assignment:** รองรับคำสั่ง "มอบหมายให้คนอื่นที่ไม่ใช่ผม" หรือ "ยกเว้น [ชื่อ]" โดยบอทจะ Map กับ UID จริงให้ทันที
3. **Iterative Creation:** สามารถสั่ง "เพิ่มงาน..." แล้วสั่งต่อว่า "และแก้หัวข้อเป็น..." โดยที่รายละเอียดเดิมไม่หาย (State Merging)

## UX Workflow (Confirm-before-Action)
1) AI ประมวลผลและส่ง "Proposal" กลับมา
2) ระบบเปรียบเทียบ State กับงานเดิม (ถ้าเป็นการแก้)
3) แสดงผลแบบ Interactive Card ในช่องแชท
4) เมื่อยืนยัน ระบบจะทำ Delta Sync ทันที ทำให้ทุกเครื่องที่เปิดบอร์ดนั้นอยู่เห็นการเปลี่ยนแปลงพร้อมกัน
