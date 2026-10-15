-- =========================================================
-- 0025_spots_cover_and_radius.sql
-- The map used to download every approved spot and then run two
-- spot_photos queries per spot just to show one thumbnail.
--
-- * spots.cover_url: the first approved, non-review photo (by
--   position), kept up to date by a trigger on spot_photos. Changing it
--   bumps spots.updated_at through touch_updated_at.
-- * spots_in_radius(lat, lng, radius_m): approved spots inside a
--   circle, nearest first, so the app only loads the area the user is
--   looking at. Plain lat/lng + haversine, no PostGIS.
-- * cover_url joins the server-managed columns pinned by
--   spots_protect_columns (0018) so nobody can set a fake cover.
-- =========================================================

alter table public.spots add column if not exists cover_url text;

create or replace function public.refresh_spot_cover(p_spot_id uuid) returns void
  language plpgsql security definer set search_path = '' as $$
  declare
    v_url text;
  begin
    select p.url into v_url
      from public.spot_photos p
     where p.spot_id = p_spot_id
       and p.photo_status = 'approved'
       and p.review_id is null
     order by p.position, p.created_at
     limit 1;

    update public.spots s
       set cover_url = v_url
     where s.id = p_spot_id
       and s.cover_url is distinct from v_url;
  end $$;

revoke all on function public.refresh_spot_cover(uuid) from public, anon, authenticated;

create or replace function public.spot_photos_refresh_cover() returns trigger
  language plpgsql security definer set search_path = '' as $$
  begin
    perform public.refresh_spot_cover(coalesce(new.spot_id, old.spot_id));
    if tg_op = 'UPDATE' and new.spot_id is distinct from old.spot_id then
      perform public.refresh_spot_cover(old.spot_id);
    end if;
    return null;
  end $$;

drop trigger if exists spot_photos_refresh_cover on public.spot_photos;
create trigger spot_photos_refresh_cover
  after insert or delete or update of photo_status, position, spot_id, review_id
  on public.spot_photos
  for each row execute function public.spot_photos_refresh_cover();

-- Same function as 0018, plus cover_url.
create or replace function public.spots_protect_columns() returns trigger
  language plpgsql as $$
  begin
    if current_user not in ('anon', 'authenticated') or public.is_admin() then
      return new;
    end if;

    if tg_op = 'INSERT' then
      new.status          := 'pending';
      new.avg_rating      := 0;
      new.ratings_count   := 0;
      new.likes_count     := 0;
      new.favorites_count := 0;
      new.approved_by     := null;
      new.approved_at     := null;
      new.reject_reason   := null;
      new.cover_url       := null;
      new.created_at      := now();
    else
      new.id              := old.id;
      new.author_id       := old.author_id;
      new.avg_rating      := old.avg_rating;
      new.ratings_count   := old.ratings_count;
      new.likes_count     := old.likes_count;
      new.favorites_count := old.favorites_count;
      new.approved_by     := old.approved_by;
      new.approved_at     := old.approved_at;
      new.reject_reason   := old.reject_reason;
      new.cover_url       := old.cover_url;
      new.created_at      := old.created_at;
    end if;

    return new;
  end $$;

-- Backfill (runs as the SQL editor owner, so the protect trigger lets it through).
select public.refresh_spot_cover(id) from public.spots;

create index if not exists spots_approved_lat_lng_idx
  on public.spots (lat, lng) where status = 'approved';

-- Great-circle distance in metres.
create or replace function public.haversine_m(
  lat1 double precision, lng1 double precision,
  lat2 double precision, lng2 double precision
) returns double precision
  language sql immutable parallel safe set search_path = '' as $$
  select 2 * 6371000 * asin(sqrt(
    power(sin(radians(lat2 - lat1) / 2), 2) +
    cos(radians(lat1)) * cos(radians(lat2)) *
    power(sin(radians(lng2 - lng1) / 2), 2)
  ));
$$;

create or replace function public.spots_in_radius(
  p_lat double precision,
  p_lng double precision,
  p_radius_m double precision
) returns setof public.spots
  language plpgsql stable security invoker set search_path = '' as $$
  declare
    -- 500 km tops; the limit below already bounds what comes back.
    r double precision := least(greatest(p_radius_m, 50), 500000);
    dlat double precision := r / 111320.0;
    dlng double precision := r / (111320.0 * greatest(cos(radians(p_lat)), 0.01));
  begin
    -- The bounding box uses spots_approved_lat_lng_idx; haversine trims
    -- it to the actual circle.
    return query
      select s.*
        from public.spots s
       where s.status = 'approved'
         and s.lat between p_lat - dlat and p_lat + dlat
         and s.lng between p_lng - dlng and p_lng + dlng
         and public.haversine_m(p_lat, p_lng, s.lat, s.lng) <= r
       order by public.haversine_m(p_lat, p_lng, s.lat, s.lng)
       limit 500;
  end $$;

grant execute on function public.spots_in_radius(double precision, double precision, double precision)
  to anon, authenticated;
