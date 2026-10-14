-- =========================================================
-- 0021_handle_new_user_unique_username.sql
-- handle_new_user (0001) copied the chosen username, or the email
-- prefix for Google sign-ins, straight into profiles.username, which
-- is unique (0007). A second "juan@…" therefore failed the whole
-- signup with "Database error saving new user", and prefixes like
-- "juan.perez" didn't match the app's username rule.
--
-- Now the username is sanitized to the app's rule
-- (^[A-Za-z0-9_]{3,20}$) and, if taken, gets a _NNNN suffix.
-- =========================================================

create or replace function public.handle_new_user() returns trigger
  language plpgsql security definer set search_path = '' as $$
  declare
    base      text;
    candidate text;
    attempts  int := 0;
  begin
    base := regexp_replace(
      coalesce(
        nullif(trim(new.raw_user_meta_data->>'username'), ''),
        split_part(new.email, '@', 1)
      ),
      '[^A-Za-z0-9_]', '_', 'g'
    );
    if length(base) < 3 then
      base := 'skater';
    end if;

    candidate := left(base, 20);
    while exists (select 1 from public.profiles where username = candidate) loop
      attempts := attempts + 1;
      candidate := left(base, 15) || '_' || case
        when attempts <= 20 then (1000 + floor(random() * 9000))::int::text
        else left(md5(new.id::text), 4)
      end;
    end loop;

    insert into public.profiles (id, username, avatar_url)
    values (new.id, candidate, new.raw_user_meta_data->>'avatar_url');
    return new;
  end $$;
