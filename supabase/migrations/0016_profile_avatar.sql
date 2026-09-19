-- =========================================================
-- 0016_profile_avatar.sql
-- Storage bucket + RLS so each user can upload exactly one avatar
-- (filename pinned to <uid>.jpg). The Flutter app uploads via
-- ProfileService.uploadAvatar and writes the public URL into
-- profiles.avatar_url (already present from 0001).
-- =========================================================

insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do update set public = excluded.public;

-- Owners can read + write + delete their own avatar.
drop policy if exists avatars_select_own_or_public on storage.objects;
create policy avatars_select_own_or_public on storage.objects
  for select using (
    bucket_id = 'avatars'
    and (
      (storage.foldername(name))[1] = auth.uid()::text
      or public.is_admin()
    )
  );

drop policy if exists avatars_insert_self on storage.objects;
create policy avatars_insert_self on storage.objects
  for insert with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists avatars_update_self on storage.objects;
create policy avatars_update_self on storage.objects
  for update using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists avatars_delete_self on storage.objects;
create policy avatars_delete_self on storage.objects
  for delete using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
