# รายงานฉบับสมบูรณ์: ระบบ AI Executive Assistant (Calenda)
## สถาปัตยกรรมระดับสูง การจัดการฐานข้อมูล และการทำงานแบบ Agentic ด้วย Gemini 2.5 Flash

---

### 1. บทนำ (Introduction)
**Calenda** คือระบบผู้ช่วยบริหารจัดการงาน (Executive Assistant) ที่ออกแบบมาเพื่อแก้ปัญหาความยุ่งยากในการจัดการตารางวานทั้งในระดับบุคคล (Personal) และทีม (Team) โดยใช้เทคโนโลยี AI ขั้นสูงในการประมวลผลคำสั่งที่เป็นภาษาธรรมชาติ (Natural Language) ให้กลายเป็นแอ็คชั่นในระบบฐานข้อมูลโดยอัตโนมัติ

จุดเด่นของ Calenda คือการแยก Layer ของข้อมูลอย่างชัดเจนระหว่างข้อมูลส่วนตัวที่เน้นความเป็นส่วนตัว (Offline-first) และข้อมูลงานทีมที่เน้นความเรียลไทม์ (Cloud-native) โดยมี AI เป็นตัวกลางในการเชื่อมโยงและจัดการข้อมูลเหล่านั้น

---

### 2. เทคโนโลยีที่ใช้ (Detailed Tech Stack)

| เลเยอร์ (Layer) | เทคโนโลยีที่ใช้ (Technology) | รายละเอียด (Description) |
|---|---|---|
| **Frontend** | Flutter (Dart) | รองรับ Multi-platform (Android, iOS, Web) |
| **Auth** | Firebase Auth | การยืนยันตัวตนผ่าน Google Sign-In |
| **AI Engine** | **Gemini 2.5 Flash** | โมเดลภาษาขนาดใหญ่ที่เน้นความเร็วและ Tool Calling |
| **Local Database** | SQLite (sqflite) | เก็บข้อมูลส่วนตัว (Personal) บนเครื่องผู้ใช้เท่านั้น |
| **Cloud Database** | **Cloudflare D1** | ฐานข้อมูล SQL บน Edge สำหรับข้อมูลทีม (Team) |
| **Real-time Server**| Cloudflare Workers | Serverless API และ Durable Objects (WebSocket) |
| **State Management**| Provider / ChangeNotifier | จัดการความลื่นไหลของ UI และข้อมูลแชท |

---

### 3. โครงสร้างฐานข้อมูล (Database Schema)
ระบบมีการออกแบบ Schema ให้รองรับทั้งการทำงานแบบเดี่ยวและกลุ่ม โดยแบ่งออกเป็น 2 ส่วนหลัก:

#### 3.1 Cloudflare D1 (สำหรับข้อมูลทีม/แชร์ข้ามอุปกรณ์)
- **team_boards**: เก็บข้อมูลบอร์ดงานกลุ่ม (ID, เจ้าของ, สมาชิก, สี, คอลัมน์ Kanban)
- **team_tasks**: เก็บรายละเอียดงาน (Board ID, ชื่อสมาชิกที่รับผิดชอบ, หัวข้อ, รายละเอียด, วันกำหนดส่ง, สถานะ)
- **Real-time Engine**: ใช้ **Durable Objects (BoardHub)** ในการกระจาย Event `task_update` ผ่าน WebSocket ทำให้ทุกเครื่องเห็นการเปลี่ยนแปลงพร้อมกันทันที

#### 3.2 Local SQLite (สำหรับงานส่วนตัว/ออฟไลน์)
- **personal_boards**: ข้อมูลบอร์ดส่วนตัว เก็บในเครื่องผู้ใช้ 100%
- **personal_tasks**: ข้อมูลงานส่วนตัว รองรับการทำงานแบบออฟไลน์

---

### 4. การเปลี่ยน LLM ให้กลายเป็น Agent (The Agentic Workflow)

การทำให้ LLM ทั่วไปทำงานแบบ **Agent** ในโปรเจค Calenda เราไม่ได้แค่ให้มัน "คุย" แต่เราให้มัน "ควบคุม" ระบบผ่านกระบวนการดังนี้:

#### 4.1 System Instructions (เข็มทิศของ Agent)
เรากำหนดบทบาทให้ Gemini 2.5 Flash เป็น "Executive Assistant" ที่มีความรอบคอบ โดยมีคำสั่งระดับระบบ (System Prompt) ที่ระบุว่า:
1. ต้องวิเคราะห์เจตนา (Intent) ของผู้ใช้ว่าเป็นการ เพิ่ม/แก้ไข/ลบ หรือสอบถามข้อมูล
2. ต้องตรวจสอบบริบทของบอร์ดปัจจุบัน (Current Board Context) เสมอ
3. หากข้อมูลไม่ครบ ต้องถามเพิ่ม (Iterative Interaction)

#### 4.2 Tool Calling & Function Calling (เครื่องมือของ Agent)
หัวใจสำคัญของการเป็น Agent คือการเรียกใช้ **Tools** ซึ่งในระบบเราได้เตรียมคำสั่งโปรแกรม (Functions) ให้ AI เรียกใช้ได้เอง ตัวอย่างโครงสร้าง JSON ที่ AI ใช้สื่อสารกับระบบ:

```json
{
  "function_call": {
    "name": "update_team_task",
    "arguments": {
      "task_id": "12345",
      "board_id": "team_board_01",
      "status": "doing",
      "members": ["uid_kim", "uid_top"]
    }
  }
}
```

**Gemini 2.5 Flash** จะทำหน้าที่เป็นสมองในการเลือก Tool ที่เหมาะสมที่สุดตามประโยคที่ผู้ใช้แชทมา โดยรองรับการทำ **Parallel Tool Calling** (สั่งงานหลายอย่างในประโยคเดียว)

---

### 5. กระบวนการไหลของข้อมูล (AI Data Flow & CRUD)

เมื่อผู้ใช้ส่งข้อความว่า *"ช่วยย้ายงาน 'ล้างรถ' ไปที่ช่อง 'เสร็จแล้ว' และแอด @Kim เข้ามาช่วยหน่อย"* กระบวนการจะทำงานดังนี้:

1.  **Context Injection Phase**: ระบบส่งข้อความผู้ใช้ไปหา AI พร้อมกับ "บริบทปัจจุบัน" ได้แก่ รายชื่อคอลัมน์ของบอร์ดนี้และรายชื่อสมาชิก เช่น:
    - *Columns:* `["รอดำเนินการ", "กำลังทำ", "เสร็จแล้ว"]`
    - *Members:* `[{"name": "Kim", "uid": "k1"}, {"name": "Bot", "uid": "b1"}]`
2.  **Semantic Reasoning Phase**: 
    - AI วิเคราะห์ว่า 'ล้างรถ' ตรงกับ Task ID ไหนในรายการงานปัจจุบัน
    - วิเคราะห์ว่า 'เสร็จแล้ว' ตรงกับคอลัมน์ลำดับที่ 3 ในฐานข้อมูล
    - วิเคราะห์ว่า @Kim คือ UID `k1`
3.  **Proposal Pattern (ความปลอดภัยสูงสุด)**: แทนที่ AI จะแก้ DB ทันที ระบบจะให้ AI ส่ง "ข้อเสนอ (Proposal)" กลับมาแสดงผลบน UI เป็นการ์ดแชทที่มีปุ่มยืนยันชัดเจน
4.  **Final Execution**: เมื่อผู้ใช้กด ✅ ยืนยัน ระบบถึงจะยิง API (REST) ไปยัง **Cloudflare Worker** เพื่อทำการ Update ลง **D1 Database** จริงๆ

---

### 6. ตรรกะขั้นสูงและความละเอียดของระบบ (Advanced Logic)

#### 6.1 Semantic Column Inference (การเดาตามบริบท)
AI ของเรามีความสามารถในการ "เข้าใจความหมาย" ของชื่อคอลัมน์ที่ผู้ใช้ตั้งเอง (Custom Kanban Columns)
- *Input:* "ช่วยเลื่อนงานนี้ไปช่องที่ทำเสร็จแล้วหน่อย"
- *Board Context:* คอลัมน์คือ `["Backlog", "In Progress", "Completed"]`
- *AI Logic:* AI จะ Map คำว่า "ทำเสร็จแล้ว" เข้ากับ "Completed" โดยอัตโนมัติผ่านการทำ Semantic Mapping ของ Gemini 2.5 Flash

#### 6.2 Description Preservation (การรักษาข้อมูลเดิม)
ปัญหาของ AI ทั่วไปคือเวลาสั่งแก้งาน มักจะส่งข้อมูลใหม่มาทับข้อมูลเดิมทั้งหมดทำให้รายละเอียด (Description) หายไป
- **Solution:** เราใช้เทคนิค **Draft State Merge** โดยระบบจะทำการเปรียบเทียบ (Diff) ข้อมูลที่ AI เสนอมา กับข้อมูลเดิมใน Database หากฟิลด์ไหน AI ไม่ได้ระบุมาใหม่ (เช่น AI ส่งมาแค่แก้ Status) ระบบจะดึง Description เดิมมาเติมให้โดยอัตโนมัติก่อน Patch ลง DB

#### 6.3 Security & API Key (Privacy-First)
- **Local Key Management:** Gemini API Key ของผู้ใช้ถูกเก็บใน **SharedPreferences** (Android/iOS) หรือ **LocalStorage** (Web) บนเครื่องผู้ใช้ 100% ไม่มีการผ่าน Server ของเรา
- **Direct Link:** ตัวแอป Flutter จะเรียกใช้ Google AI SDK เพื่อคุยกับ Gemini โดยตรง (Client-side API call) เพื่อลด latency และเพิ่มความเป็นส่วนตัว

---

### 7. บทสรุป (Conclusion)
การนำ **Gemini 2.5 Flash** มาประยุกต์ใช้ในโปรเจค Calenda นี้ พิสูจน์ให้เห็นว่าความสามารถของ LLM ในปัจจุบันไม่ได้มีไว้แค่เพียงการตอบคำถาม แต่สามารถทำหน้าที่เป็น **Autonomous Agent** ที่จัดการโครงสร้างข้อมูลที่ซับซ้อน (Complex Data Structures) ทั้งบน Client (SQLite) และ Cloud (D1) ได้อย่างแม่นยำ พร้อมทั้งมีระบบความปลอดภัยแบบ Proposal Pattern ที่ช่วยให้ผู้ใช้ยังคงเป็นผู้ตัดสินใจขั้นสุดท้าย (Human-in-the-loop)

---
*จัดทำโดย: ทีมพัฒนา Calenda AI Assistant*
