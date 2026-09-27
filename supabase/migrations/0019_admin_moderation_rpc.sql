-- =========================================================
-- 0019_admin_moderation_rpc.sql
-- Server-side moderation API used by the admin web dashboard
-- (S4F_admin_dashboard) and, later, the in-app admin screen.
--
--   * admin_audit_log: who moderated what, when.
--   * admin_set_spot_status / admin_set_rating_status /
--     admin_set_photo_status / admin_set_report_status /
--     admin_delete_spot: security definer RPCs gated by is_admin().
--     Each one writes the change + audit row in one transaction.
--   * Notifications: new spot_approved / spot_rejected kinds, and the
--     notify triggers become security definer. notifications has no
--     insert policy, so the old invoker triggers made moderation from
--     the app fail with an RLS error.
--   * recompute_spot_rating: only counts approved reviews and runs as
--     security definer so it can update spots regardless of caller.
-- =========================================================

-- ----- notification kinds -----
alter type public.notification_kind add value if not exists 'spot_approved';
alter type public.notification_kind add value if not exists 'spot_rejected';

-- ----- audit log -----
create table if not exists public.admin_audit_log (
  id          uuid primary key default gen_random_uuid(),
  admin_id    uuid references public.profiles(id) on delete set null,
  action      text not null,
  target_type text not null,
  target_id   uuid not null,
  details     jsonb not null default '{}'::jsonb,
  created_at  timestamptz not null default now()
);

create index if not exists admin_audit_log_created_idx
  on public.admin_audit_log (created_at desc);
create index if not exists admin_audit_log_target_idx
  on public.admin_audit_log (target_type, target_id);

alter table public.admin_audit_log enable row level security;

drop policy if exists admin_audit_log_select_admin on public.admin_audit_log;
create policy admin_audit_log_select_admin on public.admin_audit_log
  for select using (public.is_admin());
-- No insert/update/delete policies: rows are only written by the RPCs.

-- ----- helpers -----
-- is_admin() is called from definer functions with search_path = '',
-- so every reference must be schema-qualified.
create or replace function public.is_admin() returns boolean
  language sql stable security definer set search_path = '' as $$
    select coalesce(
      (select role = 'admin'::public.user_role from public.profiles where id = auth.uid()),
      false
    );
  $$;

create or replace function public.assert_admin() returns void
  language plpgsql stable security definer set search_path = '' as $$
  begin
    if auth.uid() is null or not public.is_admin() then
      raise exception 'forbidden: admin only' using errcode = '42501';
    end if;
  end $$;

create or replace function public.log_admin_action(
  p_action text,
  p_target_type text,
  p_target_id uuid,
  p_details jsonb default '{}'::jsonb
) returns void
  language sql security definer set search_path = '' as $$
    insert into public.admin_audit_log (admin_id, action, target_type, target_id, details)
    values (auth.uid(), p_action, p_target_type, p_target_id, coalesce(p_details, '{}'::jsonb));
  $$;

-- ----- rating aggregate: approved only, definer -----
create or replace function public.recompute_spot_rating(p_spot_id uuid) returns void
  language plpgsql security definer set search_path = '' as $$
  declare
    v_avg numeric(2,1);
    v_count int;
  begin
    select count(*), coalesce(avg(rating), 0)
      into v_count, v_avg
      from public.spot_ratings
      where spot_id = p_spot_id
        and status = 'approved';
    update public.spots
      set avg_rating = round(v_avg, 1),
          ratings_count = v_count
      where id = p_spot_id;
  end $$;

-- The ratings trigger must run as owner too: EXECUTE on
-- recompute_spot_rating is revoked from API roles below.
create or replace function public.spot_ratings_aiud() returns trigger
  language plpgsql security definer set search_path = '' as $$
  begin
    perform public.recompute_spot_rating(coalesce(new.spot_id, old.spot_id));
    return null;
  end $$;

-- ----- notify triggers as definer -----
create or replace function public.spot_ratings_notify() returns trigger
  language plpgsql security definer set search_path = '' as $$
  begin
    if new.status is distinct from old.status
       and new.status in ('approved', 'rejected') then
      insert into public.notifications (user_id, kind, payload)
      values (
        new.user_id,
        case new.status
          when 'approved' then 'rating_approved'::public.notification_kind
          else 'rating_rejected'::public.notification_kind
        end,
        jsonb_build_object('rating_id', new.id, 'spot_id', new.spot_id, 'rating', new.rating)
      );
    end if;
    return new;
  end $$;

create or replace function public.spot_photos_notify() returns trigger
  language plpgsql security definer set search_path = '' as $$
  begin
    if new.photo_status is distinct from old.photo_status
       and new.photo_status in ('approved', 'rejected') then
      insert into public.notifications (user_id, kind, payload)
      values (
        new.user_id,
        case new.photo_status
          when 'approved' then 'photo_approved'::public.notification_kind
          else 'photo_rejected'::public.notification_kind
        end,
        jsonb_build_object('photo_id', new.id, 'spot_id', new.spot_id)
      );
    end if;
    return new;
  end $$;

create or replace function public.spots_notify() returns trigger
  language plpgsql security definer set search_path = '' as $$
  begin
    if new.status is distinct from old.status
       and new.status in ('approved', 'rejected') then
      insert into public.notifications (user_id, kind, payload)
      values (
        new.author_id,
        case new.status
          when 'approved' then 'spot_approved'::public.notification_kind
          else 'spot_rejected'::public.notification_kind
        end,
        jsonb_build_object('spot_id', new.id, 'spot_name', new.name, 'reason', new.reject_reason)
      );
    end if;
    return new;
  end $$;

drop trigger if exists spots_notify on public.spots;
create trigger spots_notify
  after update on public.spots
  for each row execute function public.spots_notify();

-- ----- moderation RPCs -----
create or replace function public.admin_set_spot_status(
  p_spot_id uuid,
  p_status public.spot_status,
  p_reason text default null
) returns void
  language plpgsql security definer set search_path = '' as $$
  begin
    perform public.assert_admin();

    if p_status = 'rejected' and length(trim(coalesce(p_reason, ''))) < 3 then
      raise exception 'reject reason required' using errcode = '22023';
    end if;

    update public.spots
      set status        = p_status,
          reject_reason = case when p_status = 'rejected' then trim(p_reason) else null end,
          approved_by   = case when p_status = 'approved' then auth.uid() else null end,
          approved_at   = case when p_status = 'approved' then now() else null end
      where id = p_spot_id;

    if not found then
      raise exception 'spot not found' using errcode = 'P0002';
    end if;

    perform public.log_admin_action(
      'spot.' || p_status::text, 'spot', p_spot_id,
      jsonb_build_object('reason', p_reason)
    );
  end $$;

create or replace function public.admin_set_rating_status(
  p_rating_id uuid,
  p_status public.review_status
) returns void
  language plpgsql security definer set search_path = '' as $$
  declare
    v_spot_id uuid;
  begin
    perform public.assert_admin();

    update public.spot_ratings
      set status = p_status
      where id = p_rating_id
      returning spot_id into v_spot_id;

    if v_spot_id is null then
      raise exception 'rating not found' using errcode = 'P0002';
    end if;

    -- spot_ratings_recompute trigger refreshes the spot aggregate.
    perform public.log_admin_action('rating.' || p_status::text, 'rating', p_rating_id);
  end $$;

create or replace function public.admin_set_photo_status(
  p_photo_id uuid,
  p_status public.photo_status
) returns void
  language plpgsql security definer set search_path = '' as $$
  begin
    perform public.assert_admin();

    update public.spot_photos
      set photo_status = p_status
      where id = p_photo_id;

    if not found then
      raise exception 'photo not found' using errcode = 'P0002';
    end if;

    perform public.log_admin_action('photo.' || p_status::text, 'photo', p_photo_id);
  end $$;

create or replace function public.admin_set_report_status(
  p_report_id uuid,
  p_status public.report_status
) returns void
  language plpgsql security definer set search_path = '' as $$
  begin
    perform public.assert_admin();

    update public.spot_reports
      set status = p_status
      where id = p_report_id;

    if not found then
      raise exception 'report not found' using errcode = 'P0002';
    end if;

    perform public.log_admin_action('report.' || p_status::text, 'report', p_report_id);
  end $$;

create or replace function public.admin_delete_spot(
  p_spot_id uuid,
  p_reason text default null
) returns void
  language plpgsql security definer set search_path = '' as $$
  declare
    v_name text;
  begin
    perform public.assert_admin();

    delete from public.spots where id = p_spot_id returning name into v_name;

    if v_name is null then
      raise exception 'spot not found' using errcode = 'P0002';
    end if;

    perform public.log_admin_action(
      'spot.deleted', 'spot', p_spot_id,
      jsonb_build_object('name', v_name, 'reason', p_reason)
    );
  end $$;

-- ----- execute grants -----
-- Postgres grants EXECUTE to PUBLIC by default; lock internals down.
revoke all on function public.assert_admin()                                   from public, anon, authenticated;
revoke all on function public.log_admin_action(text, text, uuid, jsonb)        from public, anon, authenticated;
revoke all on function public.recompute_spot_rating(uuid)                      from public, anon, authenticated;
revoke all on function public.admin_set_spot_status(uuid, public.spot_status, text)      from public, anon;
revoke all on function public.admin_set_rating_status(uuid, public.review_status)        from public, anon;
revoke all on function public.admin_set_photo_status(uuid, public.photo_status)          from public, anon;
revoke all on function public.admin_set_report_status(uuid, public.report_status)        from public, anon;
revoke all on function public.admin_delete_spot(uuid, text)                              from public, anon;

grant execute on function public.admin_set_spot_status(uuid, public.spot_status, text)   to authenticated;
grant execute on function public.admin_set_rating_status(uuid, public.review_status)     to authenticated;
grant execute on function public.admin_set_photo_status(uuid, public.photo_status)       to authenticated;
grant execute on function public.admin_set_report_status(uuid, public.report_status)     to authenticated;
grant execute on function public.admin_delete_spot(uuid, text)                           to authenticated;

-- ----- backfill: averages now only count approved reviews -----
do $$
declare
  r record;
begin
  for r in select id from public.spots loop
    perform public.recompute_spot_rating(r.id);
  end loop;
end $$;
