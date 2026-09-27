-- =========================================================
-- 0018_spots_protect_columns.sql
-- spots_insert_auth / spots_update don't restrict columns, so an
-- author could insert or edit (while pending/rejected) their spot
-- with avg_rating = 5, ratings_count = 999, fake likes/favorites,
-- approved_by / approved_at. Those values survived approval.
--
-- This trigger pins the server-managed columns for regular API
-- callers (roles anon / authenticated that are not admin):
--   * insert: counters zeroed, moderation fields cleared, status pending.
--   * update: server-managed columns keep their previous value.
--
-- Counter/rating triggers run as security definer (see 0021), so
-- current_user is the function owner there and they pass through.
-- =========================================================

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
      new.created_at      := old.created_at;
    end if;

    return new;
  end $$;

drop trigger if exists spots_protect_columns on public.spots;
create trigger spots_protect_columns
  before insert or update on public.spots
  for each row execute function public.spots_protect_columns();
