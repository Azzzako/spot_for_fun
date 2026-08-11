-- Limpia TODO lo del intento previo. Maneja estado parcial.
-- El orden correcto: drop functions cascade (mata sus triggers),
-- luego drop tables, luego drop types. trigger de auth.users aparte.

drop function if exists public.handle_new_user()           cascade;
drop function if exists public.recompute_spot_rating(uuid) cascade;
drop function if exists public.spot_ratings_aiud()         cascade;
drop function if exists public.touch_updated_at()          cascade;
drop function if exists public.is_admin()                  cascade;

drop table if exists public.spot_favorites  cascade;
drop table if exists public.spot_reports    cascade;
drop table if exists public.spot_ratings    cascade;
drop table if exists public.spot_likes      cascade;
drop table if exists public.spot_photos     cascade;
drop table if exists public.spots           cascade;
drop table if exists public.profiles        cascade;

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

do $$
declare
  rows text := '';
  tbls text[] := array['profiles','spots','spot_photos','spot_likes','spot_ratings','spot_reports','spot_favorites'];
  t text;
begin
  foreach t in array tbls loop
    if exists (
      select 1 from pg_class c join pg_namespace n on n.oid = c.relnamespace
      where n.nspname='public' and c.relname=t
    ) then
      execute format('select count(*)::text from public.%I', t) into rows;
      raise notice '%: % rows', t, rows;
    else
      raise notice '%: no existe (limpio)', t;
    end if;
  end loop;
end $$;
