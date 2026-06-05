# Final Design Strategy: Misty AI (Single Theme)

เอกสารฉบับนี้คือแผนการปรับโครงสร้าง UI และ Design System ของแอป Calenda (Misty AI) โดยยึดตามเทมเพลตต้นฉบับจาก Stitch แบบ 100%

## 1. กลยุทธ์หลัก (Core Strategy)
*   **Single Dark Theme (Midnight Ocean Moon):** ตัด Light Mode ทิ้งทั้งหมด เพื่อลดความซับซ้อนของโค้ด และให้ได้ดีไซน์ที่สวย เนี๊ยบ ตรงตามต้นฉบับที่สุด
*   **ยกเลิก Layout แบบ Split-Pane (แชทซ้ายมือตายตัว):** ยกเลิกการบังคับแสดงหน้าแชทไว้ด้านซ้ายของจอคอมพิวเตอร์ โดยจะให้ Chat เป็นหน้าของตัวเอง (Dedicated Screen) หรือใช้วิธีเปิดทับ (Overlay/Drawer) ตามความเหมาะสม เพื่อให้แต่ละหน้า (เช่น Kanban, Calendar) มีพื้นที่แสดงผลเต็มที่ตามดีไซน์ของมัน
*   **Adaptation:** สำหรับหน้าไหนที่ไม่มีในดีไซน์ต้นฉบับ จะใช้ Component และ Theme System จากเทมเพลตมาประกอบกันให้ล้อไปในทิศทางเดียวกัน

## 2. ระบบสี (Color Palette)
จะทำการลบ `GlassColors` เดิมที่ซับซ้อนทิ้ง และแทนที่ด้วยค่าสีแบบตายตัวตามนี้:
*   **Background Deep (`#101A2C`):** พื้นหลังหลักของแอป
*   **Background Card (`#11284D`):** พื้นหลังของการ์ด, Sidebar
*   **Background Elevated (`#142a52`):** เมื่อ Hover หรือเป็น Layer ที่ลอยขึ้นมา
*   **Text Primary (`#F4EFDF`):** ข้อความหลัก
*   **Text Secondary (`#8A9BB3`):** ข้อความรอง
*   **Text Muted (`#5a6d8a`):** ข้อความจางๆ
*   **Gold (`#D5B370`):** สีเน้น (Accent), Badge สำคัญ, Header
*   **Navy (`#264B6F`):** สีหลักของปุ่ม, Chat Bubble ฝั่ง User

## 3. ระบบตัวอักษร (Typography)
*   **Display / Header (`Playfair Display`):** ใช้สำหรับ Page Title, ชื่อบอท (Misty), Section Header
*   **Body (`Inter`):** ใช้สำหรับเนื้อหาทั่วไป, ปุ่ม, ป้ายกำกับ (Badge)
*   **ภาษาไทย (`Noto Sans Thai`):** ตั้งเป็น Fallback ให้อ่านง่ายและสวยงาม
*   **สีอักษร:** เลิกใช้สีดำ/ขาวล้วน แต่ใช้สี `Text Primary / Secondary` ตามเทมเพลต

## 4. โครงสร้าง UI Components หลัก
*   **Cards:** กรอบแบบมีขอบบางๆ (`border: 1px solid rgba(212, 220, 236, 0.08)`) รัศมีความโค้ง (Border-radius) `16px` และใช้เงาเฉพาะเท่าที่จำเป็น
*   **Buttons:**
    *   *Primary (Navy):* ไล่สี Navy gradient + เงาสี Navy โทนโปร่งแสง
    *   *CTA (Gold):* ไล่สี Gold gradient ตัวหนังสือสีพื้นหลัง
*   **Chat Bubbles:**
    *   *User:* พื้นสี Navy, โค้ง `16px` แต่มุมขวาบนแหลม (`4px`), มีเงา
    *   *Misty:* พื้นสี Card (`#11284D`), โค้ง `16px` แต่มุมซ้ายบนแหลม (`4px`), มีเส้นขอบบางๆ ไม่มีเงา
*   **Badges/Tags:** ใช้พื้นหลังแบบโปร่งแสง (Opacity 8%) ผสมกับสี Gold หรือ Muted

## 5. แผนการลงมือทำ (Implementation Steps)
1.  **Refactor `glass_theme.dart`:** ลบ Light theme, ลบ Legacy components, เซ็ตตัวแปรสีและฟอนต์ใหม่ทั้งหมด
2.  **Refactor `main.dart` (Layout):** รื้อโครงสร้าง `Row` ที่บังคับแสดง `ScreenChat` ด้านซ้ายออก เปลี่ยนเป็น Navigation ตามปกติ (อาจจะใช้ Bottom Navigation หรือ Sidebar ที่หดได้ ขึ้นอยู่กับขนาดจอ)
3.  **Refactor `screen_chat.dart`:** ปรับโครงสร้าง Chat Bubbles ให้ตรงตามสเปกของ Misty (มุมแหลม, สี Navy/Card)
4.  **Refactor `screen_kanban.dart` และ `screen_calendar.dart`:** ปรับสีการ์ด, ปรับฟอนต์ Header ให้เป็น Playfair Display, และปรับปุ่มต่างๆ ให้เป็นแบบใหม่
5.  **Build & Deploy:** ทดสอบการแสดงผล Web Version และอัปเดตขึ้น Cloudflare
