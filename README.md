# Calenda - Hybrid Productivity Platform (Web & Native)

Calenda คือแอปพลิเคชันสำหรับจัดการตารางงาน (Executive Assistant) ที่รองรับทั้งการใช้งานผ่าน Web และ Native Desktop (Linux/Windows) โดยมีระบบ AI ผู้ช่วยที่ช่วยจัดการงานให้โดยอัตโนมัติ

## 🏗️ สถาปัตยกรรม (Architecture)

โปรเจกต์นี้แบ่งออกเป็น 3 ส่วนหลัก:

1.  **`/my_ai_assistant` (Frontend)**: พัฒนาด้วย Flutter รองรับ PWA และ Native (SQLite FFI)
2.  **`/cloudflare_backend` (Backend)**: Cloudflare Worker และ D1 Database ทำหน้าที่เป็น API และแหล่งเก็บข้อมูลงาน/ไฟล์ติดตั้งแอป
3.  **`/scripts` (Utilities)**: สคริปต์สำหรับบิ้วและจัดการระบบ เช่น การอัปโหลดแอปตัวเต็มแบบ Chunked ลง D1

---

## 🚀 วิธีการ Deployment

### 1. Backend (D1 & Worker)
รันในโฟลเดอร์ `cloudflare_backend`:
```bash
cd cloudflare_backend
# 1.1 ใช้ Migrations (ถ้ามีอัปเดต Schema)
npx wrangler d1 migrations apply calenda-db --remote

# 1.2 ดีพลอย Worker
npx wrangler deploy
```

### 2. Frontend (Web App)
รันในโฟลเดอร์ `my_ai_assistant`:
```bash
cd my_ai_assistant
# 2.1 โหลด Dependencies
flutter pub get

# 2.2 บิ้วสำหรับ Web
flutter build web --release --no-wasm-dry-run

# 2.3 ดีพลอยขึ้น Cloudflare Pages
npx wrangler pages deploy build/web --project-name calenda-app-web
```

### 3. Native App Distribution (สำหรับ Linux)
รันที่โฟลเดอร์หลักของโปรเจกต์:
```bash
# บิ้ว หั่นไฟล์กระจายลง D1 เพื่อให้โหลดผ่านหน้าเว็บได้
python scripts/publish_app.py --platform linux
```

---

## 🛠️ การตั้งค่าเครื่องสำหรับการบิ้ว Native
หากพบปัญหา Linker Error (ld) ขณะบิ้ว Linux ให้ติดตั้งเครื่องมือเหล่านี้:
```bash
sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev
```

---

## ✨ ฟีเจอร์ที่น่าสนใจ
- **Local-First SQLite**: ข้อมูลส่วนตัวเก็บลงเครื่องโดยตรงบน Native
- **AI Core Router**: ระบบดักจับคำสั่งภาษาคนเพื่อจัดการงานในบอร์ด
- **Native Binary Hosting**: แจกจ่ายตัวแอปผ่าน Cloudflare D1 ช่วยลดค่าใช้จ่าย R2
