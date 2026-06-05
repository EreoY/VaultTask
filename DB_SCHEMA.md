# Database Schema Overview

## Cloudflare D1 (ทีม / แชร์ข้ามอุปกรณ์)
- **team_boards**
  - `id` TEXT PK
  - `owner_uid` TEXT
  - `name` TEXT
  - `color` INTEGER
  - `members` TEXT (JSON array of uid)
  - `columns` TEXT (JSON array; default ["todo","doing","done"])
  - `labels` TEXT (JSON array)
  - `created_at` DATETIME
  - `updated_at` INTEGER (epoch ms)

- **team_tasks**
  - `id` INTEGER/TEXT PK
  - `board_id` TEXT (FK → team_boards.id)
  - `team_id` TEXT (legacy, same as board_id)
  - `author_uid` TEXT
  - `title` TEXT
  - `description` TEXT
  - `time` TEXT (ISO datetime)
  - `due_date` TEXT (ISO datetime, nullable)
  - `members` TEXT (JSON array of uid)
  - `label_ids` TEXT (JSON array)
  - `status` TEXT (column id — ชื่อคอลัมน์ เช่น todo/doing/done)
  - `is_completed` INTEGER (0=ยังไม่เสร็จ, 1=เสร็จแล้ว — แยกต่างหากจาก status)
  - `updated_at` INTEGER (epoch ms; สำหรับ delta/WS)

Realtime: Durable Object BoardHub กระจาย event `task_update` / `task_delete` ผ่าน WebSocket, client ดึง `/api/tasks_delta?board_id=...&since=...`.

Web Assets Fix: ตั้งค่า `<base href="/">` และจัดการ path `assets/FontManifest.json` ให้ถูกต้องเพื่อรองรับการรันบนเบราว์เซอร์และแสดงผลไอคอน/ฟอนต์ได้ 100%

## Local SQLite (งานส่วนตัว ออฟไลน์)
- **personal_boards**
  - `id` TEXT PK
  - `name` TEXT
  - `color` INTEGER
  - `columns` TEXT (JSON array)
  - `created_at` INTEGER

- **personal_tasks**
  - `id` TEXT PK
  - `board_id` TEXT (FK → personal_boards.id)
  - `title` TEXT
  - `description` TEXT
  - `time` INTEGER (epoch ms)
  - `due_date` INTEGER nullable
  - `members` TEXT (JSON array)
  - `label_ids` TEXT (JSON array)
  - `status` TEXT
  - `created_at` INTEGER

## Key Storage (ต่อผู้ใช้/อุปกรณ์)
- SharedPreferences key: `user_api_key` (Gemini per-user, local-only; ไม่ส่งขึ้นเซิร์ฟเวอร์)
