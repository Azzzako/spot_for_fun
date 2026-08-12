-- =========================================================
-- Spot For Fun — marker_kind palette
-- Optional override for the spot marker visual.
-- NULL means "fall back to the type-based icon".
-- =========================================================

create type marker_kind as enum (
  'street',
  'park',
  'bowl',
  'ledge',
  'skateshop'
);

alter table public.spots
  add column marker_kind marker_kind default null;

create index if not exists spots_marker_kind_idx on public.spots (marker_kind);
