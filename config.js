// ตั้งค่าการเชื่อมต่อ Supabase  (Project Settings > API)
// - ปล่อยว่างไว้ = โหมดทดลอง (เก็บข้อมูลในเบราว์เซอร์เครื่องนั้นเท่านั้น)
// - anon key เป็นคีย์สาธารณะ ใส่ในเว็บได้ ความปลอดภัยอยู่ที่ Row Level Security ใน supabase/schema.sql
// - ห้ามใส่ service_role key ในไฟล์นี้เด็ดขาด
window.MPIR_CONFIG = {
  SUPABASE_URL: "https://gybplzddbnzqexubdrcz.supabase.co",
  SUPABASE_ANON_KEY: "sb_publishable_lbyGBAZkPbUXKSqIwdz7IA_sDIQWiQr"   // publishable (anon) key – เป็นคีย์สาธารณะ
};
