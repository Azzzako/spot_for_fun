-- =========================================================
-- 0023_storage_hardening.sql
-- * Buckets accepted any file type and size: anyone signed in could
--   park videos, PDFs or huge files under their own folder.
--   Both buckets now take images only, up to 5 MB (the app sends
--   ~0.3-1.5 MB JPEGs after image_picker resizing).
-- * spot_photos_read (0001) let anyone, signed in or not, list the
--   whole spot-photos bucket, including photos of pending/rejected
--   spots and reviews. Listing is now limited to the uploader's own
--   folder and admins. Display is unaffected: the bucket is public,
--   so /object/public/ URLs keep working without a select policy.
--   Rejected photos stay reachable only by their exact (random UUID)
--   URL, which only the uploader and admins can read from spot_photos.
-- =========================================================

update storage.buckets
   set file_size_limit    = 5 * 1024 * 1024,
       allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp']
 where id = 'spot-photos';

update storage.buckets
   set file_size_limit    = 5 * 1024 * 1024,
       allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp', 'image/gif']
 where id = 'avatars';

drop policy if exists spot_photos_read on storage.objects;
create policy spot_photos_read on storage.objects
  for select using (
    bucket_id = 'spot-photos'
    and ((name like (auth.uid()::text || '/%')) or public.is_admin())
  );
