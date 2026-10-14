-- =========================================================
-- 0020_social_counters_definer.sql
-- spots.likes_count / favorites_count never moved for regular users:
--   * the 0014 count triggers ran as the caller, so the UPDATE on
--     spots was filtered by RLS (only authors of pending spots and
--     admins may update a spot);
--   * even when RLS let it through, spots_protect_columns (0018)
--     pinned the counters back to their old value for API roles.
--
-- Run both sync functions as security definer (same pattern as the
-- rating triggers in 0019) so current_user is the owner and both
-- checks pass, then rebuild the counters from the real rows.
-- =========================================================

create or replace function public.spot_likes_count_sync() returns trigger
  language plpgsql security definer set search_path = '' as $$
  begin
    if tg_op = 'INSERT' then
      update public.spots set likes_count = likes_count + 1
        where id = new.spot_id;
      return new;
    elsif tg_op = 'DELETE' then
      update public.spots set likes_count = greatest(0, likes_count - 1)
        where id = old.spot_id;
      return old;
    end if;
    return null;
  end $$;

create or replace function public.spot_favorites_count_sync() returns trigger
  language plpgsql security definer set search_path = '' as $$
  begin
    if tg_op = 'INSERT' then
      update public.spots set favorites_count = favorites_count + 1
        where id = new.spot_id;
      return new;
    elsif tg_op = 'DELETE' then
      update public.spots set favorites_count = greatest(0, favorites_count - 1)
        where id = old.spot_id;
      return old;
    end if;
    return null;
  end $$;

-- ----- backfill -----
-- Runs as the SQL editor owner, so spots_protect_columns lets it through.
update public.spots s set
  likes_count     = (select count(*) from public.spot_likes     l where l.spot_id = s.id),
  favorites_count = (select count(*) from public.spot_favorites f where f.spot_id = s.id);
