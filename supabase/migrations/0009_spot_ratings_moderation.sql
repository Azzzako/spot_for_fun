-- =========================================================
-- 0009_spot_ratings_moderation.sql
-- Adds moderation to spot_ratings: status (pending/approved/rejected)
-- and a one-shot edit gate. A new review enters 'pending' and must
-- be approved externally (no admin UI in the app) before becoming
-- public. The author can edit it at most once, only while the
-- review is still pending or rejected; editing flips it back to
-- pending and locks further edits.
-- =========================================================

create type review_status as enum ('pending', 'approved', 'rejected');

alter table public.spot_ratings
  add column if not exists status review_status not null default 'pending',
  add column if not exists edited boolean not null default false,
  add column if not exists edited_at timestamptz;

-- Before update: force edited=true, edited_at=now, status='pending'.
-- Combined with the update policy that requires edited=false, this
-- makes the edit truly one-shot.
create or replace function public.spot_ratings_audit() returns trigger
  language plpgsql as $$
  begin
    new.edited := true;
    new.edited_at := now();
    new.status := 'pending';
    return new;
  end $$;

drop trigger if exists spot_ratings_audit on public.spot_ratings;
create trigger spot_ratings_audit
  before update on public.spot_ratings
  for each row execute function public.spot_ratings_audit();

-- Policies: tighten insert + update; broaden select so authors can see
-- pending/rejected reviews of their own spots.
drop policy if exists spot_ratings_select on public.spot_ratings;
create policy spot_ratings_select on public.spot_ratings
  for select using (
    status = 'approved'
    or auth.uid() = user_id
    or exists (
      select 1 from public.spots s
      where s.id = spot_ratings.spot_id and s.author_id = auth.uid()
    )
  );

drop policy if exists spot_ratings_insert on public.spot_ratings;
create policy spot_ratings_insert on public.spot_ratings
  for insert with check (
    auth.uid() = user_id
    and rating between 1 and 5
    and length(trim(coalesce(comment, ''))) >= 5
    and status = 'pending'
  );

drop policy if exists spot_ratings_update on public.spot_ratings;
create policy spot_ratings_update on public.spot_ratings
  for update using (
    auth.uid() = user_id
    and status in ('pending', 'rejected')
    and edited = false
  )
  with check (
    auth.uid() = user_id
    and rating between 1 and 5
    and length(trim(coalesce(comment, ''))) >= 5
    and status = 'pending'
  );

drop policy if exists spot_ratings_delete on public.spot_ratings;
create policy spot_ratings_delete on public.spot_ratings
  for delete using (
    auth.uid() = user_id
    and status in ('pending', 'rejected')
  );
