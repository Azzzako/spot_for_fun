-- =========================================================
-- 0015_in_app_notifications.sql
-- Per-user notification log + the two triggers that fire when an
-- admin approves a review or a photo. The Flutter app watches this
-- table via Supabase Realtime and shows a snackbar; a future
-- iteration can layer FCM/APNs on top.
-- =========================================================

create type notification_kind as enum (
  'rating_approved',
  'rating_rejected',
  'photo_approved',
  'photo_rejected'
);

create table if not exists public.notifications (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles(id) on delete cascade,
  kind        notification_kind not null,
  payload     jsonb not null default '{}'::jsonb,
  read_at     timestamptz,
  created_at  timestamptz not null default now()
);

create index if not exists notifications_user_unread_idx
  on public.notifications (user_id, read_at, created_at desc);

alter table public.notifications enable row level security;

drop policy if exists notifications_select_self on public.notifications;
create policy notifications_select_self on public.notifications
  for select using (auth.uid() = user_id);

drop policy if exists notifications_update_self on public.notifications;
create policy notifications_update_self on public.notifications
  for update using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Supabase Realtime needs the publication to include this table.
-- The default `supabase_realtime` publication covers all tables; if
-- it's been pruned, run:  alter publication supabase_realtime add table public.notifications;
do $$
begin
  if exists (
    select 1 from pg_publication where pubname = 'supabase_realtime'
  ) then
    -- Only add if not already there.
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'notifications'
    ) then
      alter publication supabase_realtime add table public.notifications;
    end if;
  end if;
end $$;

-- Rating moderation → notification.
create or replace function public.spot_ratings_notify() returns trigger
  language plpgsql as $$
  declare
    kind notification_kind;
  begin
    if new.status is distinct from old.status
       and new.status in ('approved', 'rejected') then
      kind := case new.status
                 when 'approved' then 'rating_approved'::notification_kind
                 when 'rejected' then 'rating_rejected'::notification_kind
               end;
      insert into public.notifications (user_id, kind, payload)
      values (
        new.user_id,
        kind,
        jsonb_build_object(
          'rating_id', new.id,
          'spot_id', new.spot_id,
          'rating', new.rating
        )
      );
    end if;
    return new;
  end $$;

drop trigger if exists spot_ratings_notify on public.spot_ratings;
create trigger spot_ratings_notify
  after update on public.spot_ratings
  for each row execute function public.spot_ratings_notify();

-- Photo moderation → notification. Only fires on real moderation
-- updates; the audit trigger on spot_ratings is unrelated here.
create or replace function public.spot_photos_notify() returns trigger
  language plpgsql as $$
  declare
    kind notification_kind;
  begin
    if new.photo_status is distinct from old.photo_status
       and new.photo_status in ('approved', 'rejected') then
      kind := case new.photo_status
                 when 'approved' then 'photo_approved'::notification_kind
                 when 'rejected' then 'photo_rejected'::notification_kind
               end;
      insert into public.notifications (user_id, kind, payload)
      values (
        new.user_id,
        kind,
        jsonb_build_object(
          'photo_id', new.id,
          'spot_id', new.spot_id
        )
      );
    end if;
    return new;
  end $$;

drop trigger if exists spot_photos_notify on public.spot_photos;
create trigger spot_photos_notify
  after update on public.spot_photos
  for each row execute function public.spot_photos_notify();
