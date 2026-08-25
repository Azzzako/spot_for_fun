-- =========================================================
-- Spot For Fun — extend spot_type enum with Skatepark and Gap
-- Adds two new venue/feature categories.
-- =========================================================

alter type spot_type add value if not exists 'skatepark';
alter type spot_type add value if not exists 'gap';