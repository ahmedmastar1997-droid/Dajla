-- شغّله بعد supabase.sql: مخزن ملفات PDF (حتى 50 م.ب للملف)
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('books','books',true,52428800,array['application/pdf'])
on conflict (id) do nothing;
create policy books_ins on storage.objects for insert to authenticated with check (bucket_id='books' and public.is_owner());
create policy books_upd on storage.objects for update to authenticated using (bucket_id='books' and public.is_owner());
create policy books_del on storage.objects for delete to authenticated using (bucket_id='books' and public.is_owner());
