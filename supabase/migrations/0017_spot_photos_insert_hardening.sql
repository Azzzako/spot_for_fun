-- =========================================================
-- 0017_spot_photos_insert_hardening.sql
-- Closes the moderation bypass left by 0012: spot_photos_insert_self
-- only checked user_id, so any signed-in user could insert a row with
-- photo_status = 'approved', attach it to someone else's spot/review,
-- or point url at an arbitrary external host.
--
-- New rules for non-admins:
--   * url must be a public URL of an object in the spot-photos bucket
--     that the caller uploaded under <uid>/<spot_id>/<file>.
--   * review_id null  -> caller must be the spot author (extra photos).
--   * review_id set   -> review must belong to caller and to that spot.
--   * photo_status 'approved' only allowed while creating a spot:
--     own spot, spot still 'pending', no review. Those photos are
--     moderated together with the spot. Everything else is 'pending'.
-- =========================================================

-- Extracts the bucket-relative object name from a public URL and
-- checks the object exists, lives under <uid>/<spot_id>/ and belongs
-- to the caller. security definer so it does not depend on the
-- storage.objects select policies (tightened in a later step).
create or replace function public.spot_photo_url_is_valid(
  p_url text,
  p_spot_id uuid
) returns boolean
  language plpgsql stable security definer set search_path = '' as $$
  declare
    v_name text;
  begin
    if p_url is null
       or p_url !~ '^https://[a-z0-9]+\.supabase\.co/storage/v1/object/public/spot-photos/[^?#]+$' then
      return false;
    end if;

    v_name := substring(p_url from '/storage/v1/object/public/spot-photos/([^?#]+)$');

    if v_name is null
       or v_name not like (auth.uid()::text || '/' || p_spot_id::text || '/%') then
      return false;
    end if;

    return exists (
      select 1 from storage.objects o
      where o.bucket_id = 'spot-photos'
        and o.name = v_name
        and o.owner_id = auth.uid()::text
    );
  end $$;

revoke all on function public.spot_photo_url_is_valid(text, uuid) from public, anon;
grant execute on function public.spot_photo_url_is_valid(text, uuid) to authenticated;

drop policy if exists spot_photos_insert_self on public.spot_photos;
create policy spot_photos_insert_self on public.spot_photos
  for insert with check (
    public.is_admin()
    or (
      auth.uid() = user_id
      and public.spot_photo_url_is_valid(url, spot_id)
      and (
        -- Spot author adding photos (no review attached).
        (
          review_id is null
          and exists (
            select 1 from public.spots s
            where s.id = spot_photos.spot_id and s.author_id = auth.uid()
          )
        )
        or
        -- Reviewer attaching photos to their own review of this spot.
        (
          review_id is not null
          and exists (
            select 1 from public.spot_ratings r
            where r.id = spot_photos.review_id
              and r.user_id = auth.uid()
              and r.spot_id = spot_photos.spot_id
          )
        )
      )
      and (
        photo_status = 'pending'
        or (
          photo_status = 'approved'
          and review_id is null
          and exists (
            select 1 from public.spots s
            where s.id = spot_photos.spot_id
              and s.author_id = auth.uid()
              and s.status = 'pending'
          )
        )
      )
    )
  );
