# Calenda — AI Executive Assistant

เป้าหมาย: แอปจัดการตารางงานส่วนตัวและทีม โดยแยกข้อมูล "ส่วนตัว" (เก็บในมือถือ) และ "งานทีม" (Cloudflare D1) ออกจากกันอย่างเด็ดขาด

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Dart) |
| Auth | Firebase Auth + Google Sign-In |
| AI | Gemini 1.5 Flash API (Tool Calling) |
| Local DB | SQLite (sqflite) — personal boards & tasks |
| Cloud DB | Cloudflare D1 + Worker — team boards & tasks |

---

## 📂 โครงสร้างโฟลเดอร์ (อัปเดต)

```
calenda_project/
├── cloudflare_backend/                ☁️ Cloud API + Realtime
│   ├── cloudflare_worker.js           REST + WebSocket (BoardHub DO, tasks_delta)
│   ├── d1_schema.sql                  สคีมาเริ่มต้น
│   ├── d1_migration.sql               คอลัมน์เพิ่ม/updated_at
│   ├── wrangler.toml                  binding D1/DO
│   └── node_modules/                  (local dev)
│
├── my_ai_assistant/                   📱 Flutter App
│   ├── assets/
│   │   └── fonts/MaterialIcons-Regular.otf
│   ├── .env                           (stub สำหรับ web)
│   └── lib/
│       ├── main.dart                  Entry + Providers + BottomNav
│       ├── firebase_options.dart
│       ├── models/
│       │   ├── board_model.dart
│       │   ├── task_model.dart
│       │   └── chat_model.dart
│       ├── databases/
│       │   ├── db_personal_sqlite.dart    SQLite (personal boards/tasks)
│       │   ├── api_cloudflare.dart        REST + delta fetch
│       │   └── api_cloudflare_delta_result.dart
│       ├── services/
│       │   └── auth_service.dart          Firebase Auth + upsert user to D1
│       ├── ai_agent/
│       │   ├── ai_core_router.dart
│       │   ├── tools_personal.dart
│       │   └── tools_team.dart
│       ├── state_managers/
│       │   ├── state_boards.dart
│       │   ├── state_tasks.dart           รวม WebSocket subscribe + delta sync
│       │   └── state_chat.dart
│       ├── ui/screens/
│       │   ├── screen_login.dart
│       │   ├── screen_boards.dart         (Home board list)
│       │   ├── screen_kanban.dart         (Kanban per board)
│       │   ├── screen_calendar.dart
│       │   ├── screen_chat.dart
│       │   ├── screen_profile.dart
│       │   └── screen_home.dart           (legacy/unused)
│       └── ui/widgets/
│           └── executive_nav_bar.dart     (legacy/unused)
│
├── executive_dashboard_fixed_icons/      (asset workspace)
├── timeline_calendar_fixed_icons/        (asset workspace)
└── stitch_generated_screen/              (asset workspace)
```

---

## 🗺️ Navigation Flow

```
Bottom Nav (4 tabs):
  🏠 Home (Boards)  →  กด Board Card  →  Kanban (sub-screen)
  📅 Calendar                           tasks ที่มี dueDate โชว์ที่นี่
  💬 Chat                               AI Assistant
  👤 Profile                            รูปโปรไฟล์ Google + Sign Out
```

---

## 🗄️ D1 SQL Schema (เพิ่มล่าสุด — ต้อง run ใน Cloudflare Dashboard)

```sql
-- Run ทีละ statement ใน D1 Console
CREATE TABLE IF NOT EXISTS team_boards (
  id TEXT PRIMARY KEY,
  owner_uid TEXT NOT NULL,
  name TEXT NOT NULL,
  color INTEGER DEFAULT 0,
  members TEXT DEFAULT '[]',
  columns TEXT DEFAULT '["todo","doing","done"]',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE team_tasks ADD COLUMN board_id TEXT;
ALTER TABLE team_tasks ADD COLUMN due_date TEXT;
```

---

## ✅ Feature Status

| Feature | Status |
|---|---|
| Google Sign-In (Firebase) | ✅ Done |
| Save user to D1 on login | ✅ Done |
| Board List (Home screen) | ✅ Done |
| Create Board (Personal / Team) | ✅ Done |
| Custom Kanban columns per board | ✅ Done |
| Assign members to task | ✅ Done |
| Due date picker (shows in Calendar) | ✅ Done |
| Move task between columns (drag) | ✅ Done |
| Delete task | ✅ Done |
| Delete board (cascade) | ✅ Done |
| Calendar — aggregate dueDate tasks | ✅ Done |
| Profile screen + Sign Out | ✅ Done |
| AI Chat integration (Gemini 2.5 Flash) | ✅ Done |
| Semantic Column Inference | ✅ Done |
| Task Description Preservation | ✅ Done |
| Web Icon & Asset Recovery | ✅ Done |
