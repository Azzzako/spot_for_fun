-- =========================================================
-- Spot For Fun — extend spot_type enum with Skateshop
-- Adds a new value to the existing spot_type enum so
-- spots can be tagged as 'skateshop' (shops selling gear).
-- =========================================================

alter type spot_type add value if not exists 'skateshop';
