-- =========================================================
-- Seed initial admin
-- Reemplaza 'TU_EMAIL_AQUI@example.com' con tu email antes de ejecutar.
-- El usuario debe haberse registrado primero (Auth → Users).
-- =========================================================

update public.profiles
  set role = 'admin'
  where id = (
    select id from auth.users where email = 'TU_EMAIL_AQUI@example.com'
  );
