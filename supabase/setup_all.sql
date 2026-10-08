-- =====================================================================
-- MPIR Central Lab QMS – Supabase schema
-- วิธีใช้: Supabase Dashboard > SQL Editor > New query > วางทั้งไฟล์ > Run
-- (รันซ้ำได้ ไม่ทำให้ข้อมูลเดิมหาย)
-- =====================================================================

-- ---------- helper: อีเมลของผู้ที่ล็อกอิน ----------
create or replace function public.me_email() returns text
language sql stable as $$ select lower(coalesce(auth.jwt() ->> 'email', '')) $$;

-- ---------- ผู้ใช้งาน (อนุมัติโดย Admin) ----------
create table if not exists public.app_users (
  email      text primary key check (email = lower(email)),
  id         text not null unique,                         -- รหัสผู้ใช้ในแอป เช่น u1
  roles      text[] not null default '{VIEWER}',
  status     text not null default 'pending'
             check (status in ('pending','approved','rejected','suspended')),
  person_id  text,                                         -- เชื่อมกับทะเบียนบุคลากร
  perms      jsonb,                                        -- สิทธิ์รายบุคคล (null = ตามบทบาท)
  mods       jsonb,                                        -- หน้าที่เข้าถึงได้ (null = ทั้งหมด)
  profile    jsonb not null default '{}'::jsonb,           -- ชื่อ ตำแหน่ง หน่วยงาน การอบรม E-ลายเซ็น ใบรับรอง
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ผู้ใช้ที่อนุมัติแล้ว / เป็น Admin (security definer เพื่อไม่ให้ RLS วนซ้ำ)
create or replace function public.is_approved() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.app_users where email = public.me_email() and status = 'approved')
$$;
create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.app_users
                 where email = public.me_email() and status = 'approved' and 'SYSTEM_ADMIN' = any(roles))
$$;
-- ผู้ที่เขียนข้อมูลได้ (ไม่นับผู้ที่เป็น VIEWER อย่างเดียว)
create or replace function public.can_write() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.app_users
                 where email = public.me_email() and status = 'approved'
                   and roles && array['SYSTEM_ADMIN','LABORATORY_MANAGER','QM','TM','DC','LEAD_AUDITOR','AUDITOR','STAFF'])
$$;

-- กันผู้ใช้ทั่วไปแก้บทบาท/สถานะ/สิทธิ์ของตัวเอง
create or replace function public.protect_user_cols() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  new.updated_at := now();
  if not public.is_admin() then
    new.email := old.email; new.id := old.id; new.roles := old.roles; new.status := old.status;
    new.perms := old.perms; new.mods := old.mods; new.person_id := old.person_id;
  end if;
  return new;
end $$;
drop trigger if exists trg_protect_user_cols on public.app_users;
create trigger trg_protect_user_cols before update on public.app_users
  for each row execute function public.protect_user_cols();

alter table public.app_users enable row level security;
drop policy if exists users_select on public.app_users;
drop policy if exists users_insert on public.app_users;
drop policy if exists users_update on public.app_users;
drop policy if exists users_delete on public.app_users;
create policy users_select on public.app_users for select to authenticated
  using (public.is_approved() or email = public.me_email());
-- ใครก็ได้ที่ยืนยันอีเมลแล้ว ขอสิทธิ์ได้ "เฉพาะอีเมลของตนเอง" เป็นสถานะ pending / VIEWER เท่านั้น
create policy users_insert on public.app_users for insert to authenticated
  with check (public.is_admin() or (
    email = public.me_email() and status = 'pending' and roles = '{VIEWER}'
    and perms is null and mods is null and person_id is null));
create policy users_update on public.app_users for update to authenticated
  using (public.is_admin() or email = public.me_email())
  with check (public.is_admin() or email = public.me_email());
create policy users_delete on public.app_users for delete to authenticated
  using (public.is_admin());

-- ---------- ข้อมูลหลักของแอป (รายการ audit/NC/CAR/ความเสี่ยง, แผน, บุคลากร ฯลฯ) ----------
create table if not exists public.app_docs (
  seq        bigint generated always as identity unique,
  kind       text not null check (kind in ('rec','people','lplan','tplan','train','assign','comp')),
  id         text not null,
  data       jsonb not null,
  version    integer not null default 1,
  updated_by text,
  updated_at timestamptz not null default now(),
  primary key (kind, id)
);

create or replace function public.touch_doc() returns trigger
language plpgsql as $$
begin
  new.updated_at := now();
  new.updated_by := public.me_email();
  return new;
end $$;
drop trigger if exists trg_touch_doc on public.app_docs;
create trigger trg_touch_doc before insert or update on public.app_docs
  for each row execute function public.touch_doc();

alter table public.app_docs enable row level security;
drop policy if exists docs_select on public.app_docs;
drop policy if exists docs_insert on public.app_docs;
drop policy if exists docs_update on public.app_docs;
drop policy if exists docs_delete on public.app_docs;
create policy docs_select on public.app_docs for select to authenticated using (public.is_approved());
create policy docs_insert on public.app_docs for insert to authenticated with check (public.can_write());
create policy docs_update on public.app_docs for update to authenticated
  using (public.can_write()) with check (public.can_write());
create policy docs_delete on public.app_docs for delete to authenticated using (public.can_write());

-- ---------- บันทึกการใช้งาน (ใครทำอะไร) – เพิ่มได้อย่างเดียว ----------
create table if not exists public.app_log (
  seq      bigint generated always as identity primary key,
  at       timestamptz not null default now(),
  by_email text not null,
  by_name  text,
  a        text,
  no       text,
  r        text,
  data     jsonb
);
alter table public.app_log enable row level security;
drop policy if exists log_select on public.app_log;
drop policy if exists log_insert on public.app_log;
create policy log_select on public.app_log for select to authenticated using (public.is_approved());
create policy log_insert on public.app_log for insert to authenticated
  with check (public.can_write() and by_email = public.me_email());

-- ---------- ไฟล์แนบ (Storage) ----------
insert into storage.buckets (id, name, public, file_size_limit)
values ('attachments', 'attachments', false, 20971520)
on conflict (id) do update set public = false, file_size_limit = 20971520;

drop policy if exists att_select on storage.objects;
drop policy if exists att_insert on storage.objects;
drop policy if exists att_delete on storage.objects;
create policy att_select on storage.objects for select to authenticated
  using (bucket_id = 'attachments' and public.is_approved());
create policy att_insert on storage.objects for insert to authenticated
  with check (bucket_id = 'attachments' and public.can_write());
create policy att_delete on storage.objects for delete to authenticated
  using (bucket_id = 'attachments' and public.can_write());

-- ---------- Realtime (ให้หน้าจอของทุกคนอัปเดตทันที) ----------
do $$
declare t text;
begin
  foreach t in array array['app_docs','app_users','app_log'] loop
    begin
      execute format('alter publication supabase_realtime add table public.%I', t);
    exception when duplicate_object then null;
    end;
  end loop;
end $$;

grant usage on schema public to authenticated;
grant select, insert, update, delete on public.app_users, public.app_docs to authenticated;
grant select, insert on public.app_log to authenticated;


-- ===== ผู้ดูแลระบบคนแรก =====
-- สร้างผู้ดูแลระบบคนแรก (รันครั้งเดียวหลัง schema.sql)
insert into public.app_users (email, id, roles, status, profile)
values (lower('thidarati@mitrphol.com'), 'u1', '{SYSTEM_ADMIN,QM}', 'approved',
        jsonb_build_object('name', 'ธิดารัตน์ อินต๊ะคำ', 'fn', 'ธิดารัตน์', 'ln', 'อินต๊ะคำ', 'pos', 'QM', 'at', now()))
on conflict (email) do update set roles = excluded.roles, status = 'approved';
