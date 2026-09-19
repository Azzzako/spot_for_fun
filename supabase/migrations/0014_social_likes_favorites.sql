-- =========================================================
-- 0014_social_likes_favorites.sql
-- Engagement tables: spot_likes (one-tap like) + spot_favorites
-- (saved spots). Denormalized counters on spots keep the map
-- marker cards cheap to render. Triggers keep the counters in
-- sync; RLS keeps the rows user-scoped.
-- =========================================================

create table if not exists public.spot_likes (
  spot_id    uuid not null references public.spots(id) on delete cascade,
  user_id    uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (spot_id, user_id)
);

create index if not exists spot_likes_user_idx
  on public.spot_likes (user_id, created_at desc);

create table if not exists public.spot_favorites (
  spot_id    uuid not null references public.spots(id) on delete cascade,
  user_id    uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (spot_id, user_id)
);

create index if not exists spot_favorites_user_idx
  on public.spot_favorites (user_id, created_at desc);

-- Counter columns on spots. Default 0 so existing rows stay valid.
alter table public.spots
  add column if not exists likes_count int not null default 0,
  add column if not exists favorites_count int not null default 0;

-- Keep likes_count in sync.
create or replace function public.spot_likes_count_sync() returns trigger
  language plpgsql as $$
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

drop trigger if exists spot_likes_count_sync on public.spot_likes;
create trigger spot_likes_count_sync
  after insert or delete on public.spot_likes
  for each row execute function public.spot_likes_count_sync();

-- Keep favorites_count in sync.
create or replace function public.spot_favorites_count_sync() returns trigger
  language plpgsql as $$
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

drop trigger if exists spot_favorites_count_sync on public.spot_favorites;
create trigger spot_favorites_count_sync
  after insert or delete on public.spot_favorites
  for each row execute function public.spot_favorites_count_sync();

-- RLS ----------------------------------------------------------------
alter table public.spot_likes     enable row level security;
alter table public.spot_favorites enable row level security;

-- Likes: anyone can see the count via spots.likes_count; the rows
-- themselves are visible only to the user that owns them.
drop policy if exists spot_likes_select_self on public.spot_likes;
create policy spot_likes_select_self on public.spot_likes
  for select using (auth.uid() = user_id);

drop policy if exists spot_likes_insert_self on public.spot_likes;
create policy spot_likes_insert_self on public.spot_likes
  for insert with check (auth.uid() = user_id);

drop policy if exists spot_likes_delete_self on public.spot_likes;
create policy spot_likes_delete_self on public.spot_likes
  for delete using (auth.uid() = user_id);

-- Same shape for favorites.
drop policy if exists spot_favorites_select_self on public.spot_favorites;
create policy spot_favorites_select_self on public.spot_favorites
  for select using (auth.uid() = user_id);

drop policy if exists spot_favorites_insert_self on public.spot_favorites;
create policy spot_favorites_insert_self on public.spot_favorites
  for insert with check (auth.uid() = user_id);

drop policy if exists spot_favorites_delete_self on public.spot_favorites;
create policy spot_favorites_delete_self on public.spot_favorites
  for delete using (auth.uid() = user_id);
