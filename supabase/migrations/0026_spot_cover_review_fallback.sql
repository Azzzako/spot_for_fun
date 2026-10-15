-- =========================================================
-- 0026_spot_cover_review_fallback.sql
-- 0025 only took the spot's own photos (review_id is null) as cover,
-- so a spot whose only approved photos came with reviews had none,
-- while its detail gallery did show them. The cover is now the first
-- approved photo of the spot itself, falling back to the first
-- approved review photo.
-- =========================================================

create or replace function public.refresh_spot_cover(p_spot_id uuid) returns void
  language plpgsql security definer set search_path = '' as $$
  declare
    v_url text;
  begin
    select p.url into v_url
      from public.spot_photos p
     where p.spot_id = p_spot_id
       and p.photo_status = 'approved'
     order by (p.review_id is not null), p.position, p.created_at
     limit 1;

    update public.spots s
       set cover_url = v_url
     where s.id = p_spot_id
       and s.cover_url is distinct from v_url;
  end $$;

revoke all on function public.refresh_spot_cover(uuid) from public, anon, authenticated;

-- Backfill (runs as the SQL editor owner, so the protect trigger lets it through).
select public.refresh_spot_cover(id) from public.spots;
