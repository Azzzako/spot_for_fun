-- =========================================================
-- 0011_fix_rating_audit_trigger.sql
-- The audit trigger from migration 0009 reset status='pending' on
-- EVERY update, including admin moderation. That made it impossible
-- to approve or reject a review (the change was immediately
-- reverted). Now the trigger only resets when rating or comment
-- actually changes, leaving status-only updates (moderation)
-- untouched.
-- =========================================================

create or replace function public.spot_ratings_audit() returns trigger
  language plpgsql as $$
  begin
    -- Re-lock the review only when the user edits the rating or the
    -- comment. Status-only changes (admin moderation) pass through
    -- untouched, so approving / rejecting actually sticks.
    if new.rating is distinct from old.rating
       or new.comment is distinct from old.comment then
      new.edited := true;
      new.edited_at := now();
      new.status := 'pending';
    end if;
    return new;
  end $$;

drop trigger if exists spot_ratings_audit on public.spot_ratings;
create trigger spot_ratings_audit
  before update on public.spot_ratings
  for each row execute function public.spot_ratings_audit();
