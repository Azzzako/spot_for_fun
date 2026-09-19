-- =========================================================
-- 0013_admin_moderation_policies.sql
-- Lets the admin (see public.is_admin()) list and moderate pending
-- reviews + photos from inside the app. The audit trigger from
-- 0011 already passes status-only updates through untouched, so we
-- only need to widen the RLS policies.
-- =========================================================

-- ----- spot_ratings -----

drop policy if exists spot_ratings_select on public.spot_ratings;
create policy spot_ratings_select on public.spot_ratings
  for select using (
    status = 'approved'
    or auth.uid() = user_id
    or exists (
      select 1 from public.spots s
      where s.id = spot_ratings.spot_id and s.author_id = auth.uid()
    )
    or public.is_admin()
  );

drop policy if exists spot_ratings_update on public.spot_ratings;
create policy spot_ratings_update on public.spot_ratings
  for update using (
    (
      auth.uid() = user_id
      and status in ('pending', 'rejected')
      and edited = false
    )
    or public.is_admin()
  )
  with check (
    (
      auth.uid() = user_id
      and rating between 1 and 5
      and length(trim(coalesce(comment, ''))) >= 5
      and status = 'pending'
    )
    or public.is_admin()
  );

-- ----- spot_photos -----

drop policy if exists spot_photos_select on public.spot_photos;
create policy spot_photos_select on public.spot_photos
  for select using (
    photo_status = 'approved'
    or user_id = auth.uid()
    or exists (
      select 1 from public.spot_ratings r
      where r.id = spot_photos.review_id and r.user_id = auth.uid()
    )
    or exists (
      select 1 from public.spots s
      where s.id = spot_photos.spot_id and s.author_id = auth.uid()
    )
    or public.is_admin()
  );

drop policy if exists spot_photos_update_admin on public.spot_photos;
create policy spot_photos_update_admin on public.spot_photos
  for update using (public.is_admin())
  with check (public.is_admin());
