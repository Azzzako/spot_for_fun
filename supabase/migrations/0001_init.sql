-- =========================================================
-- Spot For Fun — initial migration (safe re-run)
-- Limpia objetos previos antes de crear. Idempotente total.
-- =========================================================

create extension if not exists "pgcrypto";

-- ----- preflight: drop objects safely -----
drop function if exists public.handle_new_user()           cascade;
drop function if exists public.recompute_spot_rating(uuid) cascade;
drop function if exists public.spot_ratings_aiud()         cascade;
drop function if exists public.touch_updated_at()          cascade;
drop function if exists public.is_admin()                  cascade;

drop table if exists public.spot_favorites cascade;
drop table if exists public.spot_reports   cascade;
drop table if exists public.spot_ratings   cascade;
drop table if exists public.spot_likes     cascade;
drop table if exists public.spot_photos    cascade;
drop table if exists public.spots          cascade;
drop table if exists public.profiles       cascade;

drop type if exists user_role        cascade;
drop type if exists spot_type        cascade;
drop type if exists spot_difficulty  cascade;
drop type if exists best_time_slot   cascade;
drop type if exists spot_status      cascade;
drop type if exists report_status    cascade;

do $$
begin
  if exists (
    select 1 from pg_trigger t
    join pg_class c on c.oid = t.tgrelid
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'auth' and c.relname = 'users' and t.tgname = 'on_auth_user_created'
  ) then
    execute 'drop trigger on_auth_user_created on auth.users';
  end if;
end $$;

do $$
begin
  if exists (select 1 from storage.buckets where id = 'spot-photos') then
    perform storage.delete_bucket('spot-photos');
  end if;
end $$;

-- =========================================================
-- enums
-- =========================================================
create type user_role        as enum ('user', 'admin');
create type spot_type        as enum ('street', 'park', 'bowl', 'plaza', 'diy');
create type spot_difficulty  as enum ('beginner', 'intermediate', 'advanced');
create type best_time_slot   as enum ('morning', 'midday', 'afternoon', 'evening', 'night');
create type spot_status      as enum ('pending', 'approved', 'rejected');
create type report_status    as enum ('open', 'reviewed', 'dismissed');

-- =========================================================
-- tables
-- =========================================================
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null,
  avatar_url text,
  role user_role not null default 'user',
  fcm_token text,
  created_at timestamptz not null default now()
);

create index profiles_username_idx on public.profiles (username);

create table public.spots (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  description text not null default '',
  lat double precision not null,
  lng double precision not null,
  type spot_type not null,
  difficulty spot_difficulty not null default 'beginner',
  best_time best_time_slot[] not null default '{}',
  safety_notes text,
  status spot_status not null default 'pending',
  reject_reason text,
  approved_by uuid references public.profiles(id),
  approved_at timestamptz,
  avg_rating numeric(2,1) not null default 0,
  ratings_count int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index spots_status_idx          on public.spots (status);
create index spots_author_idx         on public.spots (author_id);
create index spots_type_difficulty_idx on public.spots (type, difficulty);
create index spots_created_idx        on public.spots (created_at desc);

create table public.spot_photos (
  id uuid primary key default gen_random_uuid(),
  spot_id uuid not null references public.spots(id) on delete cascade,
  url text not null,
  position int not null default 0,
  created_at timestamptz not null default now()
);

create index spot_photos_spot_idx on public.spot_photos (spot_id, position);

create table public.spot_likes (
  user_id uuid not null references public.profiles(id) on delete cascade,
  spot_id uuid not null references public.spots(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, spot_id)
);

create index spot_likes_spot_idx on public.spot_likes (spot_id);

create table public.spot_ratings (
  id uuid primary key default gen_random_uuid(),
  spot_id uuid not null references public.spots(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  rating int not null check (rating between 1 and 5),
  comment text,
  created_at timestamptz not null default now(),
  unique (spot_id, user_id)
);

create index spot_ratings_spot_idx on public.spot_ratings (spot_id);

create table public.spot_reports (
  id uuid primary key default gen_random_uuid(),
  spot_id uuid not null references public.spots(id) on delete cascade,
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  reason text not null,
  status report_status not null default 'open',
  created_at timestamptz not null default now()
);

create index spot_reports_spot_idx on public.spot_reports (spot_id, status);

create table public.spot_favorites (
  user_id uuid not null references public.profiles(id) on delete cascade,
  spot_id uuid not null references public.spots(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, spot_id)
);

create index spot_favorites_user_idx on public.spot_favorites (user_id);

-- =========================================================
-- functions (after tables)
-- =========================================================
create or replace function public.touch_updated_at() returns trigger
  language plpgsql as $$
  begin
    new.updated_at = now();
    return new;
  end $$;

create or replace function public.is_admin() returns boolean
  language sql stable as $$
    select coalesce(
      (select role = 'admin'::user_role from public.profiles where id = auth.uid()),
      false
    );
  $$;

create or replace function public.recompute_spot_rating(p_spot_id uuid) returns void
  language plpgsql as $$
  declare
    v_avg numeric(2,1);
    v_count int;
  begin
    select count(*), coalesce(avg(rating), 0)
      into v_count, v_avg
      from public.spot_ratings
      where spot_id = p_spot_id;
    update public.spots
      set avg_rating = round(v_avg, 1),
          ratings_count = v_count
      where id = p_spot_id;
  end $$;

create or replace function public.spot_ratings_aiud() returns trigger
  language plpgsql as $$
  begin
    perform public.recompute_spot_rating(coalesce(new.spot_id, old.spot_id));
    return null;
  end $$;

create or replace function public.handle_new_user() returns trigger
  language plpgsql security definer set search_path = public as $$
  begin
    insert into public.profiles (id, username, avatar_url)
    values (
      new.id,
      coalesce(new.raw_user_meta_data->>'username', split_part(new.email, '@', 1)),
      new.raw_user_meta_data->>'avatar_url'
    );
    return new;
  end $$;

-- =========================================================
-- triggers
-- =========================================================
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

create trigger spots_touch_updated
  before update on public.spots
  for each row execute function public.touch_updated_at();

create trigger spot_ratings_recompute
  after insert or update or delete on public.spot_ratings
  for each row execute function public.spot_ratings_aiud();

-- =========================================================
-- RLS
-- =========================================================
alter table public.profiles        enable row level security;
alter table public.spots           enable row level security;
alter table public.spot_photos     enable row level security;
alter table public.spot_likes      enable row level security;
alter table public.spot_ratings    enable row level security;
alter table public.spot_reports    enable row level security;
alter table public.spot_favorites  enable row level security;

-- profiles
create policy profiles_select on public.profiles
  for select using (true);

create policy profiles_update_self on public.profiles
  for update using (auth.uid() = id)
  with check (auth.uid() = id and role = (select role from public.profiles where id = auth.uid()));

-- spots
create policy spots_select on public.spots
  for select using (
    status = 'approved'
    or author_id = auth.uid()
    or public.is_admin()
  );

create policy spots_insert_auth on public.spots
  for insert with check (
    auth.uid() = author_id
    and status = 'pending'
  );

create policy spots_update on public.spots
  for update using (
    (author_id = auth.uid() and status in ('pending', 'rejected'))
    or public.is_admin()
  )
  with check (
    (author_id = auth.uid() and status = 'pending')
    or public.is_admin()
  );

create policy spots_delete_admin on public.spots
  for delete using (public.is_admin());

-- spot_photos
create policy spot_photos_select on public.spot_photos
  for select using (
    exists (
      select 1 from public.spots s
      where s.id = spot_photos.spot_id
        and (s.status = 'approved' or s.author_id = auth.uid() or public.is_admin())
    )
  );

create policy spot_photos_insert_owner on public.spot_photos
  for insert with check (
    exists (
      select 1 from public.spots s
      where s.id = spot_photos.spot_id and s.author_id = auth.uid()
    )
  );

create policy spot_photos_delete_owner_or_admin on public.spot_photos
  for delete using (
    exists (
      select 1 from public.spots s
      where s.id = spot_photos.spot_id
        and (s.author_id = auth.uid() or public.is_admin())
    )
  );

-- spot_likes
create policy spot_likes_select on public.spot_likes for select using (auth.role() = 'authenticated');
create policy spot_likes_insert on public.spot_likes for insert with check (auth.uid() = user_id);
create policy spot_likes_delete on public.spot_likes for delete using (auth.uid() = user_id);

-- spot_ratings
create policy spot_ratings_select on public.spot_ratings for select using (auth.role() = 'authenticated');
create policy spot_ratings_insert on public.spot_ratings for insert with check (auth.uid() = user_id);
create policy spot_ratings_update on public.spot_ratings for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy spot_ratings_delete on public.spot_ratings for delete using (auth.uid() = user_id);

-- spot_reports
create policy spot_reports_insert       on public.spot_reports for insert with check (auth.uid() = reporter_id);
create policy spot_reports_select_admin on public.spot_reports for select using (public.is_admin());
create policy spot_reports_update_admin on public.spot_reports for update using (public.is_admin());

-- spot_favorites
create policy spot_favorites_select on public.spot_favorites for select using (auth.uid() = user_id);
create policy spot_favorites_insert on public.spot_favorites for insert with check (auth.uid() = user_id);
create policy spot_favorites_delete on public.spot_favorites for delete using (auth.uid() = user_id);

-- =========================================================
-- Storage bucket: spot-photos
-- Policies usan "name LIKE auth.uid()::text || '%'" en vez de
-- storage.foldername() (devuelve text[] en algunas versiones de Supabase).
-- =========================================================
insert into storage.buckets (id, name, public)
values ('spot-photos', 'spot-photos', true);

create policy spot_photos_read on storage.objects
  for select using (bucket_id = 'spot-photos');

create policy spot_photos_write on storage.objects
  for insert with check (
    bucket_id = 'spot-photos'
    and auth.role() = 'authenticated'
    and (name like (auth.uid()::text || '/%'))
  );

create policy spot_photos_update on storage.objects
  for update using (
    bucket_id = 'spot-photos'
    and (name like (auth.uid()::text || '/%'))
  );

create policy spot_photos_delete on storage.objects
  for delete using (
    bucket_id = 'spot-photos'
    and ((name like (auth.uid()::text || '/%')) or public.is_admin())
  );
