-- =========================================================
-- 0010_auto_confirm_admin_email.sql
-- Auto-confirms the email of the dev admin account so it skips
-- Supabase's email verification flow (used for testing).
-- Only applies to the exact address admin@admin.com.
-- =========================================================

create or replace function public.auto_confirm_admin_email() returns trigger
  language plpgsql security definer set search_path = auth, public as $$
  begin
    if lower(coalesce(new.email, '')) = 'admin@admin.com' then
      new.email_confirmed_at := now();
      new.confirmed_at := coalesce(new.confirmed_at, now());
    end if;
    return new;
  end $$;

drop trigger if exists on_auth_user_created_auto_confirm on auth.users;
create trigger on_auth_user_created_auto_confirm
  before insert on auth.users
  for each row execute function public.auto_confirm_admin_email();
