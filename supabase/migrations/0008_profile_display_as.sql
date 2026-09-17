-- =========================================================
-- 0008_profile_display_as.sql
-- Adds a per-profile preference for how the author name is
-- rendered across the app (spot detail, peek card, list
-- cards). Optional aka remains a separate column; if the
-- user picks 'aka' but has none, the app falls back to
-- username.
-- =========================================================

create type display_as as enum ('username', 'aka');

alter table public.profiles
  add column if not exists display_as display_as not null default 'username';
