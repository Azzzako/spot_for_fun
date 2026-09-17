-- =========================================================
-- 0012_spot_photo_moderation.sql
-- Lets reviewers upload photos tied to their review, and lets the
-- spot author upload extra photos directly. Every new photo enters
-- 'pending' and is moderated externally (same flow as reviews).
-- The author and reviewer see their own pending photos on the
-- spot detail; everyone else only sees 'approved' ones.
-- =========================================================

create type photo_status as enum ('pending', 'approved', 'rejected');

alter table public.spot_photos
  add column if not exists user_id uuid references public.profiles(id) on delete set null,
  add column if not exists review_id uuid references public.spot_ratings(id) on delete cascade,
  add column if not exists photo_status photo_status not null default 'approved';

-- Backfill: existing photos belong to the spot's author.
update public.spot_photos sp
set user_id = s.author_id
from public.spots s
where s.id = sp.spot_id and sp.user_id is null;

alter table public.spot_photos alter column user_id set not null;

create index if not exists spot_photos_review_idx
  on public.spot_photos (review_id);
create index if not exists spot_photos_status_idx
  on public.spot_photos (spot_id, photo_status, position);

-- Replace prior policies so reviewers can also upload and users can
-- delete their own pending uploads.
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
  );

drop policy if exists spot_photos_insert_owner on public.spot_photos;
drop policy if exists spot_photos_delete_owner_or_admin on public.spot_photos;

create policy spot_photos_insert_self on public.spot_photos
  for insert with check (auth.uid() = user_id);

create policy spot_photos_delete_self_pending on public.spot_photos
  for delete using (
    auth.uid() = user_id
    and photo_status = 'pending'
  );
