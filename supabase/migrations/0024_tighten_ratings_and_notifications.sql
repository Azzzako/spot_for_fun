-- =========================================================
-- 0024_tighten_ratings_and_notifications.sql
-- spot_ratings: the author update policy only checks the final row
-- (own, valid rating/comment, status pending), so an author could:
--   * move a review to another spot (spot_id) or rewrite created_at;
--   * flip a rejected review back to 'pending' without editing it,
--     re-queueing the same rejected content for moderation forever.
-- The audit trigger now pins every column except rating/comment for
-- non-admin API callers and keeps the old status unless the content
-- changed (the policy then rejects the status-only update).
-- Admin paths (admin_set_rating_status RPC, admin direct UPDATE) are
-- unaffected.
--
-- notifications: the app no longer reads or updates notifications
-- (in-app feed removed). The update policy let users rewrite any
-- column of their rows; drop it. Push will add what it needs.
-- =========================================================

create or replace function public.spot_ratings_audit() returns trigger
  language plpgsql as $$
  begin
    if current_user in ('anon', 'authenticated') and not public.is_admin() then
      new.id         := old.id;
      new.spot_id    := old.spot_id;
      new.user_id    := old.user_id;
      new.created_at := old.created_at;
      new.edited     := old.edited;
      new.edited_at  := old.edited_at;
      if new.rating is not distinct from old.rating
         and new.comment is not distinct from old.comment then
        new.status := old.status;
      end if;
    end if;

    -- Re-lock the review only when the rating or the comment changes.
    -- Status-only changes (admin moderation) pass through untouched.
    if new.rating is distinct from old.rating
       or new.comment is distinct from old.comment then
      new.edited    := true;
      new.edited_at := now();
      new.status    := 'pending';
    end if;
    return new;
  end $$;

drop policy if exists notifications_update_self on public.notifications;
