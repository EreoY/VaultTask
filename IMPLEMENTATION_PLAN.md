# Implementation Plan: Exact Stitch Design Integration

เป้าหมาย: ปรับปรุงแอปพลิเคชัน Calenda ให้ตรงตามดีไซน์ "Misty AI" จาก Stitch 100% โดยใช้ธีมมืด (Midnight Ocean Moon) เพียงธีมเดียว และยกเลิกการบังคับแสดงแชทด้านซ้าย

## ระยะที่ 1: วางรากฐาน (Theme & Typography)
1. **Refactor `glass_theme.dart`**:
   - ลบตัวแปรและตรรกะทั้งหมดที่เกี่ยวกับ `Light Mode` ออก
   - อัปเดตสีหลัก (`--bg-deep`, `--bg-card`, `--gold`, `--navy`) ตามค่า Hex จาก Stitch HTML
   - นำฟอนต์ `Playfair Display` (สำหรับ Header) และ `Inter` (สำหรับ Body) เข้ามาใช้ใน `GlassText`

## ระยะที่ 2: ปรับโครงสร้างหน้าจอหลัก (Layout & Structure)
1. **Refactor `main.dart`**:
   - ลบโครงสร้าง `Row` ที่ล็อคความกว้างแชท (`ScreenChat`) ไว้ที่ `380px` ด้านซ้ายของจอคอมพิวเตอร์
   - ปรับให้แอปแสดงผลเต็มจอ (Fluid Shell) ในทุกหน้าจอ
   - ปรับปรุงแถบเมนูด้านล่าง (Bottom Navigation) ให้เข้าถึงหน้า Chat ได้สะดวกขึ้น (เพิ่มแท็บ Chat หรือใช้ Floating Button)

## ระยะที่ 3: ปรับแต่ง Components ระดับลึก (Polishing)
1. **Chat Interface (`screen_chat.dart` และ `chat_widgets`)**:
   - ปรับแชทฝั่ง User ให้เป็นสี Navy, มุมขวาบนแหลม (`4px`), โค้งจุดอื่น `16px`
   - ปรับแชทฝั่ง AI ให้เป็นสี Card (`#11284D`), มุมซ้ายบนแหลม (`4px`), มีเส้นขอบบาง
2. **Buttons & Cards**:
   - ปรับปุ่ม Primary ให้ใช้ Linear Gradient ของ Navy
   - ปรับปุ่ม CTA ให้ใช้ Linear Gradient ของ Gold
   - ปรับแต่งเงาของหน้า Kanban และ Calendar ให้เรียบหรู ไม่ฟุ้งเกินไป

## ระยะที่ 4: การทดสอบและการนำขึ้นระบบจริง (Deploy)
1. ตรวจสอบการแสดงผลบน Desktop และ Mobile ว่าตรงตามสเปคของ Stitch 
2. รัน `flutter build web` เพื่อตรวจสอบข้อผิดพลาด
3. นำขึ้นระบบจริง (Cloudflare Pages) ทันที
