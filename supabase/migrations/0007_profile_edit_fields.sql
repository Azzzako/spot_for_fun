-- =========================================================
-- 0007_profile_edit_fields.sql
-- Adds aka + instagram columns to public.profiles and makes
-- username unique. Required by the Edit Profile screen.
-- =========================================================

alter table public.profiles
  add column if not exists aka text,
  add column if not exists instagram text;

-- Enforce username uniqueness (currently only indexed).
alter table public.profiles
  add constraint profiles_username_key unique (username);
