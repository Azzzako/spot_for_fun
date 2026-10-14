-- =========================================================
-- 0022_drop_profiles_fcm_token.sql
-- profiles_select is `using (true)`: every column of every profile is
-- readable by anyone, signed in or not. fcm_token was never written,
-- but once push lands it would have exposed each user's device token.
--
-- Push notifications will keep tokens in their own table with
-- owner-only RLS and one row per device. Older app builds only read
-- the column as nullable, so dropping it is backward compatible.
-- =========================================================

alter table public.profiles drop column if exists fcm_token;
