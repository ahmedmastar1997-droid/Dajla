-- شغّل هذا الملف كاملًا في Supabase > SQL Editor
create table if not exists public.owners(user_id uuid primary key references auth.users(id) on delete cascade);
alter table public.owners enable row level security; -- بلا سياسات: لا وصول مباشر

create or replace function public.is_owner() returns boolean
language sql security definer set search_path=public stable as
$$ select exists(select 1 from public.owners where user_id=auth.uid()) $$;
revoke all on function public.is_owner() from public;
grant execute on function public.is_owner() to anon, authenticated;

create table if not exists public.kv(
  key text primary key, data jsonb not null default '{}'::jsonb, updated_at timestamptz default now());
alter table public.kv enable row level security;
-- الجميع يقرأ المحتوى العام فقط؛ سجل الإعارات للمالك وحده
create policy kv_read on public.kv for select using (key='pub' or public.is_owner());
create policy kv_ins  on public.kv for insert with check (public.is_owner());
create policy kv_upd  on public.kv for update using (public.is_owner()) with check (public.is_owner());
create policy kv_del  on public.kv for delete using (public.is_owner());

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('media','media',true,8388608,array['image/jpeg','image/png','image/webp','image/gif'])
on conflict (id) do nothing;
create policy media_ins on storage.objects for insert to authenticated with check (bucket_id='media' and public.is_owner());
create policy media_upd on storage.objects for update to authenticated using (bucket_id='media' and public.is_owner());
create policy media_del on storage.objects for delete to authenticated using (bucket_id='media' and public.is_owner());

-- بعد إنشاء مستخدم المالك من Authentication > Users، شغّل (غيّر البريد):
-- insert into public.owners select id from auth.users where email='owner@example.com';
