-- สร้างผู้ดูแลระบบคนแรก (รันครั้งเดียวหลัง schema.sql)
insert into public.app_users (email, id, roles, status, profile)
values (lower('thidarati@mitrphol.com'), 'u1', '{SYSTEM_ADMIN,QM}', 'approved',
        jsonb_build_object('name', 'ธิดารัตน์ อินต๊ะคำ', 'fn', 'ธิดารัตน์', 'ln', 'อินต๊ะคำ', 'pos', 'QM', 'at', now()))
on conflict (email) do update set roles = excluded.roles, status = 'approved';
