# 🛡️ PHUKEAT — Kiro CLI Sovereign Crew

ชุดเอเจนต์ (agent crew) สำหรับ **Kiro CLI** ที่ฝังมากับโปรเจกต์นี้ ทุกคนในทีมที่ clone repo แล้วเปิด Kiro CLI ที่ root ของโปรเจกต์จะได้ workflow เดียวกันทันที โดยไม่ต้องตั้งค่าอะไรเพิ่ม

> ทุกเอเจนต์ทำงานภายใต้ **Sovereign AI Operating Procedure (Universal Mandate V3.0)** — กฎพื้นฐานที่ถูกอ่านเข้า context **ทุกครั้งที่เปิด session** ผ่าน `agentSpawn` hook + `file://` resource

---

## 1. โครงสร้างไฟล์

```text
.kiro/
├── README.md                         # ไฟล์นี้ — คู่มือ workflow + setup
├── agents/                           # นิยามเอเจนต์ (Kiro native format)
│   ├── sovereign.json                # 👑 Manager (default agent) — สั่งงาน/แบ่งงาน
│   ├── planner.json                  # 🧭 วางแผน + task-graph.md (read-only + เขียน .md)
│   ├── backend_coder.json            # ⚙️  แก้โค้ดฝั่ง backend เท่านั้น (ไม่มี shell)
│   ├── frontend_coder.json           # 🎨 แก้โค้ดฝั่ง UI/presentation เท่านั้น (ไม่มี shell)
│   ├── executor.json                 # ▶️  รันคำสั่ง shell/build/test (แก้โค้ดไม่ได้)
│   └── qa.json                       # ✅ ตรวจสอบ/รัน test/lint (แก้โค้ดไม่ได้)
└── skills/
    └── sovereign-logic/
        └── SKILL.md                  # กฎพื้นฐาน V3.0 (อ่านทุก session)
```

---

## 2. บทบาทของแต่ละเอเจนต์ (Crew Roles)

| Role | หน้าที่ | ทูลที่มี | ข้อจำกัด |
|------|---------|----------|----------|
| **sovereign** (Manager) | ผู้ประสานงาน/ตัดสินใจ แบ่งงานให้ลูกทีมผ่านทูล `subagent` | ครบทุกทูล | — |
| **planner** | วิเคราะห์ requirement, สำรวจโค้ด, เขียน `task-graph.md` | read, grep, glob, write(`*.md` เท่านั้น) | ห้ามแก้ซอร์สโค้ด |
| **backend_coder** | แก้ไฟล์ backend (Workers logic, D1 schema, API, config) | read, grep, glob, write, code | ห้ามแตะ UI, ห้ามรัน shell |
| **frontend_coder** | แก้ไฟล์ UI/presentation (Flutter, HTML/CSS/JS, templates) | read, grep, glob, write, code | ห้ามแตะ backend, ห้ามรัน shell |
| **executor** | รัน shell: `wrangler`, `flutter`, `npm`, test, build | read, glob, shell | ห้ามแก้ซอร์สโค้ด |
| **qa** | ตรวจ syntax, รัน test/lint, audit โค้ด | read, grep, glob, shell, code | ห้ามแก้ซอร์สโค้ด |

---

## 3. Workflow การทำงาน

### 3.1 รูปแบบ pipeline มาตรฐาน (manager เรียก `subagent`)

```text
[planner]  ── วางแผน + task-graph.md
     │
     ▼
[backend_coder] ║ [frontend_coder]   ◀── รันขนานกัน (ไม่มี depends_on ระหว่างกัน)
     │                  │
     └────────┬─────────┘
              ▼
        [executor]  ── build / deploy / รัน script
              │
              ▼
          [qa]  ── รัน test / lint / audit → รายงานกลับ Manager
```

- **Parallel**: stage ที่ไม่มี `depends_on` จะรัน **พร้อมกัน** (เช่น backend + frontend)
- **Dependent**: stage ที่ต่อกันใส่ `depends_on` (เช่น qa ต้องรอ coder เสร็จก่อน)
- ทูล `subagent` ของ Manager เป็นแบบ **blocking** = Manager รอจนครบทุก stage

### 3.2 รูปแบบ background (คุยกับ AI ต่อได้ระหว่างงานรัน)

ถ้าต้องการให้งานรัน **เบื้องหลัง** แล้วคุย/วางแผนกับ AI ต่อแบบไม่ต้องรอ ให้ **ผู้ใช้พิมพ์เอง**:

```text
/spawn --name worker1 <รายละเอียดงาน>
```

- `/spawn` สร้าง session ใหม่รันขนานไปกับห้องแชทปัจจุบัน — คุยกับ AI ต่อได้ทันที
- กด **Ctrl+G** = Crew Monitor ดูว่าแต่ละ session/subagent กำลังทำอะไร (real-time)
- กด **Ctrl+X** = Activity Tray ดูคิวงาน/ความคืบหน้า และพิมพ์ข้อความถัดไปเข้าคิวได้

> ⚠️ ข้อจำกัดจริง: ทูล `subagent` (ที่ AI เรียกเอง) ยัง **ไม่มีโหมด background** — เป็น blocking อย่างเดียว ส่วนโหมด background ต้องใช้ `/spawn` ซึ่ง **ผู้ใช้เป็นคนสั่ง** AI สั่ง `/spawn` แทนไม่ได้

---

## 4. กฎพื้นฐาน (Sovereign Mandate V3.0)

อ่านฉบับเต็มได้ที่ `.kiro/skills/sovereign-logic/SKILL.md` หัวใจสำคัญ:

0. **Infrastructure Protocol** — ต้องมี `task-graph.md`, `architecture.md`, `skill-instructions.md`; อัปเดต `[x]` ทันทีที่ทำเสร็จแต่ละ task แล้วอ่านไฟล์ anchor ซ้ำ
1. **Approval Gate** — งานซับซ้อนต้องเสนอ Diagnostic Report และรอ "Approve/Proceed" ก่อนแก้ไฟล์
2. **Task Graph Schema** — ทุก checkbox ต้องมีครบ 5 ส่วน (File / Logic-Target / Why / Verification)
3. **High-Verbosity Logging** — ใส่ log prefix `[Process]`, `[Database]`, `[Error]` ฯลฯ
4. **Autonomous Verification** — ต้องพิสูจน์เองว่า "ใช้งานได้จริง" ไม่ใช่แค่ "compile ผ่าน"
5. **Architectural Cleanliness** — ไฟล์ไม่เกิน 500–700 บรรทัด, แก้แบบ surgical
6. **Structural Evolution** — อัปเดต `architecture.md` / `skill-instructions.md` เมื่อโครงสร้างเปลี่ยน

---

## 5. การติดตั้งสำหรับเพื่อนร่วมทีม (Team Setup)

### ข้อกำหนดเบื้องต้น
- ติดตั้ง **Kiro CLI** (`kiro-cli`)

### ขั้นตอน
1. Clone repo นี้ตามปกติ — โฟลเดอร์ `.kiro/` ติดมาด้วยอยู่แล้ว
2. เปิด terminal ที่ **root ของโปรเจกต์** (โฟลเดอร์ที่มี `.kiro/`)
3. ตั้งให้ session ใหม่ใช้เอเจนต์ `sovereign` เป็น default:
   ```bash
   kiro-cli settings chat.defaultAgent sovereign
   ```
   (หรือเปิดแบบเจาะจงครั้งเดียว: `kiro-cli chat --agent sovereign`)
4. ตรวจว่าเอเจนต์ทั้งหมดถูกพบ:
   ```bash
   kiro-cli agent list
   ```
   ควรเห็น `sovereign, planner, backend_coder, frontend_coder, executor, qa` เป็น **Workspace**
5. (ถ้าต้องการ) validate config:
   ```bash
   for a in sovereign planner backend_coder frontend_coder executor qa; do
     kiro-cli agent validate --path ".kiro/agents/$a.json"
   done
   ```

### เริ่มใช้งาน
- เปิดแชท → เอเจนต์ `sovereign` (Manager) จะอ่านกฎ V3.0 อัตโนมัติ และพร้อมแบ่งงานให้ crew
- งานหนัก/ขนาน: ให้ Manager จัด pipeline ผ่าน `subagent`
- งาน background + คุยสด: พิมพ์ `/spawn ...` เอง แล้วกด `Ctrl+G` ติดตาม

---

## 6. หมายเหตุ / ข้อจำกัดที่ทราบ (Known Caveats)

- **Tool sandbox ของ subagent**: จากการทดสอบ พบว่าตอนสปาวผ่านทูล `subagent` ลูกทีมอาจได้ทูลชุดเต็ม (ไม่ถูกจำกัดตามฟิลด์ `tools` ที่ตั้งไว้เป๊ะ ๆ) ขอบเขตบทบาทจึงควรพึ่ง "คำสั่งใน prompt" ของแต่ละเอเจนต์ร่วมด้วย ไม่ใช่พึ่ง sandbox อย่างเดียว
- **`/spawn` ต้องสั่งโดยผู้ใช้** — AI เรียกแทนไม่ได้
- **subagent สปาวซ้อนไม่ได้** — มีแค่ Manager (ระดับบนสุด) ที่สปาว crew ได้
- **Global vs Workspace**: ถ้าในเครื่องมีเอเจนต์ชื่อซ้ำใน `~/.kiro/agents/` จะขึ้น warning ว่า "Using workspace version" ซึ่งถูกต้องแล้ว — ตัวใน repo นี้ (workspace) จะถูกใช้เสมอ

---

## 7. การปรับแก้

- แก้กฎพื้นฐาน → `.kiro/skills/sovereign-logic/SKILL.md`
- แก้บทบาท/ทูลของเอเจนต์ → `.kiro/agents/<role>.json` (อย่าลืม `kiro-cli agent validate` หลังแก้)
- เพิ่มบทบาทใหม่ → สร้าง `.kiro/agents/<new_role>.json` แล้วเพิ่มชื่อใน `sovereign.json` ที่ `toolsSettings.crew.availableAgents` และ `trustedAgents`
