# MPIR Central Lab QMS – รุ่นต่อ Supabase

ระบบบริหารคุณภาพห้องปฏิบัติการ (ISO/IEC 17025:2017) แบบหน้าเว็บ static + ฐานข้อมูล Supabase
(ล็อกอินด้วยอีเมล, ข้อมูลร่วมกันทุกคน, อัปเดตแบบ Realtime, ไฟล์แนบเก็บใน Supabase Storage)

```
index.html            ตัวแอป (ไฟล์เดียว)
config.js             ใส่ SUPABASE_URL และ SUPABASE_ANON_KEY
supabase/schema.sql   ตาราง + Row Level Security + Storage + Realtime
supabase/seed_admin.sql  สร้างผู้ดูแลระบบคนแรก
.github/workflows/pages.yml  (ตัวเลือก) deploy GitHub Pages อัตโนมัติ
```

## ค่าที่ตั้งไว้ให้แล้วสำหรับโปรเจกต์นี้

- Supabase project: `gybplzddbnzqexubdrcz` (URL และ publishable key ใส่ใน `config.js` แล้ว)
- ผู้ดูแลระบบคนแรก: `thidarati@mitrphol.com` (อยู่ใน `supabase/seed_admin.sql`)
- GitHub repo: `MPIRCentralLab/QMS-MPIR-Central-Lab`
- ที่อยู่เว็บเมื่อเปิด Pages: `https://mpircentrallab.github.io/QMS-MPIR-Central-Lab/`

ขั้นตอนที่เหลือ (ทำครั้งเดียว):
1. Supabase → SQL Editor → วาง `supabase/setup_all.sql` ทั้งไฟล์ → Run (รวม schema + ผู้ดูแลระบบคนแรก)
2. Supabase → Authentication → URL Configuration → Site URL และ Redirect URLs = `https://mpircentrallab.github.io/QMS-MPIR-Central-Lab/`
3. Push ไฟล์ทั้งหมดขึ้น repo แล้วเปิด Settings → Pages (ดูหัวข้อ 6 ด้านล่าง)

---

## ขั้นตอน (ทำครั้งเดียว)

### 1) สร้างโปรเจกต์ Supabase
supabase.com → New project (เลือก region ใกล้ไทย เช่น Singapore) แล้วรอให้สร้างเสร็จ

### 2) สร้างตารางและสิทธิ์
Dashboard → **SQL Editor → New query** → วางเนื้อหา `supabase/schema.sql` ทั้งไฟล์ → **Run**
(รันซ้ำได้ ข้อมูลเดิมไม่หาย)

### 3) สร้างผู้ดูแลระบบคนแรก
เปิด `supabase/seed_admin.sql` แก้ `YOUR-EMAIL@example.com` และชื่อเป็นของคุณ แล้ว Run ใน SQL Editor
(คนอื่น ๆ ให้ล็อกอินแล้ว "ขอสิทธิ์" ผู้ดูแลระบบอนุมัติในหน้า Administration → ผู้ใช้งาน)

### 4) ตั้งค่า Authentication
Dashboard → **Authentication → URL Configuration**
- **Site URL** = `https://<ชื่อผู้ใช้>.github.io/<ชื่อ repo>/`
- **Redirect URLs** เพิ่มที่อยู่เดียวกัน (ถ้าทดสอบในเครื่อง เพิ่ม `http://localhost:8000/` ด้วย)

Authentication → Providers → **Email** เปิดไว้ (ค่าเริ่มต้นเปิดอยู่) ระบบใช้ลิงก์ในอีเมล (magic link) ไม่ใช้รหัสผ่าน

> อีเมลที่ Supabase ส่งให้ฟรีมีโควตาจำกัดมาก (ราว 2–4 ฉบับ/ชั่วโมง) ถ้าใช้งานจริงหลายคน
> ให้ตั้ง Custom SMTP (Authentication → SMTP Settings) เช่น Gmail Workspace, SendGrid, Resend

### 5) ใส่คีย์ใน config.js
Project Settings → **API** → คัดลอก **Project URL** และ **anon public key** ไปใส่ใน `config.js`
(อย่าใส่ service_role key)

### 6) Deploy ขึ้น GitHub Pages
อัปโหลดทุกไฟล์ในโฟลเดอร์นี้ไป repo → Settings → Pages
- วิธี A: *Deploy from a branch* → `main` / `(root)` (ลบโฟลเดอร์ `.github` ออก) หรือ
- วิธี B: Source = *GitHub Actions* (ใช้ `pages.yml`)

เปิด `https://<ชื่อผู้ใช้>.github.io/<ชื่อ repo>/` → กรอกอีเมลผู้ดูแล → กดลิงก์ในอีเมล → เข้าระบบ

### 7) (ทางเลือก) ข้อมูลตัวอย่าง
ผู้ดูแลระบบกดปุ่ม **นำเข้าข้อมูลตัวอย่าง** ที่แถบด้านข้าง (ทำได้เฉพาะเมื่อฐานข้อมูลยังว่าง) จะได้แผน ISO,
บุคลากร และรายการตัวอย่าง ไม่แตะบัญชีผู้ใช้จริง

## วิธีทำงาน

| เรื่อง | การทำงาน |
|---|---|
| ล็อกอิน | magic link ทางอีเมล (Supabase Auth) ยืนยันความเป็นเจ้าของอีเมลจริง |
| ผู้ใช้ใหม่ | ล็อกอินได้แต่เห็นเฉพาะหน้า "ขอสิทธิ์" จนกว่า Admin อนุมัติ |
| ข้อมูล | ตาราง `app_docs` (รายการ audit/NC/CAR/ความเสี่ยง, แผน, บุคลากร) เก็บเป็น JSON ต่อรายการ + เลขเวอร์ชัน |
| แก้พร้อมกัน | บันทึกด้วยเลขเวอร์ชัน ถ้ามีคนแก้ก่อนจะโหลดฉบับล่าสุดมาและแจ้งเตือน ไม่เขียนทับเงียบ ๆ |
| Realtime | คนอื่นเพิ่ม/แก้/ลบ หน้าจอเรา (ที่ไม่ได้กำลังพิมพ์) อัปเดตเอง |
| ไฟล์แนบ | bucket `attachments` (private) เปิดผ่านลิงก์ชั่วคราว 1 ชั่วโมง; PDF รูปภาพ วิดีโอ ข้อความ/CSV ไม่เกิน 20 MB |
| บันทึกการใช้งาน | ตาราง `app_log` เพิ่มได้อย่างเดียว (แก้/ลบไม่ได้) |

## ความปลอดภัย – ควรรู้
- ฐานข้อมูลบังคับ: ต้องล็อกอิน + ได้รับอนุมัติจึงอ่านได้ · ผู้ที่เป็น VIEWER อย่างเดียวเขียนไม่ได้ ·
  เฉพาะ SYSTEM_ADMIN จัดการผู้ใช้/บทบาท · ผู้ใช้เปลี่ยนบทบาท/สถานะของตัวเองไม่ได้ · log แก้ไม่ได้ · ไฟล์เป็น private
- **สิทธิ์ละเอียดตามขั้นตอน** (เช่น ใครกด Accept / ปิด CAR ได้) ตรวจที่ฝั่งเบราว์เซอร์ ผู้ใช้ที่ได้รับอนุมัติและมีความรู้ทางเทคนิค
  สามารถเรียก API ข้ามกติกาเหล่านี้ได้ ถ้าต้องการเข้มงวดระดับ audit ภายนอก ควรเพิ่ม RLS/ฟังก์ชันฝั่งฐานข้อมูลรายโมดูล
- เลขที่เอกสาร (เช่น CAR 69/003) คำนวณฝั่งเบราว์เซอร์ ถ้าสองคนสร้างพร้อมกันภายในเสี้ยววินาทีอาจได้เลขซ้ำ
- ควรตั้ง Database backup (Project Settings → Database → Backups) และเก็บสำเนาส่งออกเป็นระยะ

## ตรวจสอบหลัง deploy (smoke test)
1. เปิดเว็บ → เห็นหน้า "ส่งลิงก์เข้าสู่ระบบ" · กรอกอีเมลผู้ดูแล → ได้อีเมล → กดลิงก์ → เข้า Dashboard
2. Administration → ผู้ใช้งาน → เห็นตัวเอง (QM + Admin)
3. เปิดเว็บอีกเครื่อง/เบราว์เซอร์ล็อกอินอีเมลอื่น → "ขอสิทธิ์" → กลับมาที่ผู้ดูแล เห็นคำขอ → อนุมัติ
4. สร้างรายการในเครื่องหนึ่ง → อีกเครื่องเห็นเอง (Realtime)
5. แนบไฟล์ PDF ในรายการ → กดเปิดไฟล์ได้
