# Spot For Fun

App de mapa con spots para skaters. Flutter + Supabase + OpenStreetMap.

## Stack
- Flutter (Android + iOS)
- Supabase (Postgres + Storage + Auth + RLS)
- flutter_map + latlong2 (OpenStreetMap)
- flutter_riverpod, go_router
- geolocator, image_picker, google_sign_in (email+Google Sign-In)
- shared_preferences (theme persistence)

## Setup

### 1. Supabase (manual, una sola vez)
1. Crear proyecto en https://supabase.com/dashboard (region recomendada: South America / US East, Free tier).
2. Settings → API: copiar `Project URL` y `anon public` key.
3. Authentication → Providers:
   - Email: enabled (recomendado: confirm email ON en prod).
   - Google: pegar OAuth Client ID/Secret de Google Cloud (ver más abajo).
4. Authentication → URL Configuration: añadir el scheme de tu app en Redirect URLs.
5. SQL Editor → New query → pegar `supabase/migrations/0001_init.sql` y ejecutar.
6. Registrarse una primera vez en la app (o via Supabase Auth → Add user).
7. SQL Editor → editar `supabase/migrations/0002_seed_admin.sql` con tu email y ejecutar.

### 2. Google Cloud (para Google Sign-In)
1. https://console.cloud.google.com → nuevo proyecto.
2. APIs & Services → OAuth consent screen → External → Testing → agregar tu email.
3. Credentials → Create OAuth client ID:
   - **Web application** (para Supabase callback).
   - **iOS application** (con tu bundle ID).
   - **Android application** (con SHA-1 de debug/release keystore).
4. Pegar Web client ID + secret en Supabase → Auth → Providers → Google.

### 3. App
```bash
flutter pub get

flutter run \
  --dart-define=SUPABASE_URL=https://TU_PROYECTO.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxx...
```

## Estructura
```
lib/
  main.dart, app.dart
  core/
    config/    env + bootstrap
    providers/ Riverpod
    router/    go_router
    theme/     light/dark (M3 minimal)
  features/
    auth/      login, register, splash
    map/       home con mapa
    spots/     create, detail, my_spots
    profile/   perfil + favoritos
    admin/     aprobación de spots
  shared/
    models/    Profile, Spot, enums
    widgets/
supabase/
  migrations/  SQL schema + RLS + storage
```

## Roadmap (fases)
1. Setup ✅
2. Auth (email + Google)
3. Mapa + detail skeleton
4. Crear spot (GPS, multi-foto, pending)
5. My spots (edit + resubmit)
6. Admin panel
7. Social (likes, ratings, comments, favorites, reports)
8. Push notifications (FCM + Edge Function)
9. Polish (filtros, empty states, errores)
