# STATUS — Contexto para retomar

Última sesión: spot_for_fun (develop @ 8213c65). Todo commiteado y pusheado a `origin/develop`.

## Estado de git
- `develop` sincronizado con `origin/develop` (`7726bc8..8213c65`, 24 commits).
- Working tree limpio salvo `assets/identity/estilo.png` (palette reference, intencionalmente sin trackear).
- Branch nueva `feat/profile-avatar` mergeada. Todas las features viven en `develop`.

## Features completadas en esta sesión

### Fixes (develop)
- `de41a5a` **fix(spots)**: propio spot CTA visible ("Eres el autor de este spot" en vez de `SizedBox.shrink`), `fetchVisiblePhotos` paralelo en lugar de JOIN `spot_photos(*)` (RLS no se aplicaba en JOIN), Hero entre thumb de gallery y fullscreen viewer.

### Admin
- `7168d2e` **feat(admin-moderation)**: migration `0013_admin_moderation_policies.sql` (admin SELECT + UPDATE en spot_ratings, admin UPDATE en spot_photos). AdminModerationService + Repository. `isAdminProvider` por email == admin@admin.com.
- `7915a02` **feat(admin-moderation)**: AdminModerationViewModel + AdminPendingScreen con TabBar (Reseñas / Fotos), approve/reject por card, error banner.

### Social
- `35d13ed` **feat(social)**: migration `0014_social_likes_favorites.sql` (tablas `spot_likes` / `spot_favorites` con PK compuesta, contadores denormalizados en `spots.likes_count` / `spots.favorites_count` mantenidos por triggers AFTER INSERT/DELETE, RLS user-scoped). DTOs + mappers + domain. SocialService + Repository con `myLikedSpotIdsProvider` / `myFavoritedSpotIdsProvider`. Spot: nuevos `likesCount`, `favoritesCount`, `isLiked`, `isFavorited`. spot_repository ahora hidrata las flags por spot.
- `f699a2b` **feat(social)**: SocialViewModel con toggleLike / toggleFavorite que invalidan todos los providers afectados. SpotListCard muestra heart + count. OpenSpotCard (ConsumerWidget) wirea los toggles. Profile > Favoritos tab reemplazó el placeholder "próximamente". SpotDetail > Reportar: 5 chips de categoría + campo de detalles opcional.

### Notifications
- `f78448f` **feat(notifications)**: migration `0015_in_app_notifications.sql` (tabla `notifications`, RLS user-scoped, agregada a `supabase_realtime` publication automáticamente, triggers AFTER UPDATE en spot_ratings + spot_photos que insertan filas en approved/rejected). NotificationKind enum con title + body. NotificationsService con fetch + markRead + watch (Realtime stream).
- `1427eae` **feat(notifications)**: `notificationsFeedProvider` (StreamProvider que combina initial fetch + Realtime). `NotificationsListener` widget en `MaterialApp.builder` con `scaffoldMessengerKey` global — diff de ids seen vs incoming dispara SnackBar.

### Map filters
- `4869482` **feat(map-filters)**: SpotFilter gained `bestTime: Set<BestTimeSlot>`; query usa `overlaps('best_time', [...])`. FiltersSheet: removidas secciones Servicios / Distancia máxima (eran local state sin efecto), agregada sección Mejor horario con 5 chips (sun/cloud/moon icons).

### Onboarding
- `9c9f597` **feat(onboarding)**: onboardingCompletedProvider (AsyncNotifier con SharedPreferences key `onboarding_seen_v1`). OnboardingScreen con 3 tip cards (Mapa / Agregar / Reseñar). Splash ahora chequea el flag antes del routing de auth.

### Profile avatar (feat/profile-avatar)
- `829c27f` **feat(profile)**: migration `0016_profile_avatar.sql` (bucket `avatars` público con RLS por folder = uid). ProfileService.uploadAvatar + clearAvatar.
- `a8bb035` **feat(profile)**: `_authorSelect` en spot_service / spot_rating_service / admin_moderation_service ahora trae `avatar_url`. Spot domain + DTO + mapper con `authorAvatarUrl`, service lo resuelve. Nuevo widget `UserAvatar` (CachedNetworkImage + initial-letter fallback con palette hasheada). ProfileScreen header usa UserAvatar. SpotListCard "Por @user" con avatar 18px.
- `8db1388` **feat(profile)**: EditProfileViewModel agrega `pendingAvatarBytes` / `pendingAvatarExt` / `removeAvatar`. submit() sube avatar ANTES de update del row (si falla el upload, no se renombra). EditProfileScreen: top-of-form avatar preview + picker (cámara/galería con bottom sheet) + "Quitar".
- `94f0c85` **feat(profile)**: reviewer avatar en cada rating card (SpotRatingDto + domain + mapper con `userAvatarUrl` extraído del join `author.avatar_url`). _RatingCard en spot detail + _MyReviewCard en profile + AdminRatingCard usan UserAvatar.
- `13a4aba` **fix(profile)**: avatar path usa `<uid>/avatar_<timestamp>.<ext>` (RLS check `(storage.foldername(name))[1] = uid` requería slash; timestamp evita cache CDN). clearAvatar parsea URL → path.

### Map markers
- `c8605f2` **feat(map)**: SpotMarkerShape eliminado, todo circular (`BoxShape.circle`). `photoUrl?` opcional: CachedNetworkImage con BoxFit.cover si hay foto, icono coloreado como fallback. kSpotMarkerPinSize 32→40, container 110×64. map_screen y spot_detail pasan `s.photos.firstOrNull?.url`.
- `ff123fc` **fix(map)**: pin era 3 círculos concéntricos (color ring + white border + photo) — colored background como background causaba bleed.
- `95dc739` **fix(map)**: ClipOval + SizedBox.expand wrapping CachedNetworkImage para forzar fill con BoxFit.cover.
- `276d357` **fix(map)**: drop colored ring → solo white border.
- `8213c65` **fix(map)**: drop white border → solo imagen redonda.

### Spot creation
- `7a3803b` **feat(spots)**: foto obligatoria al crear spot (mín 1, máx 3). CreateSpotViewModel valida `photos.isEmpty`. PhotoPickerGrid maxPhotos: 3. Submit button disabled hasta tener foto. Header "Mínimo 1 · máximo 3".

## Decisiones / preguntas abiertas

### 1. GIFs en spots (PENDIENTE — usuario lo está pensando)
3 interpretaciones posibles:
- **A) GIFs animados como la foto misma** (Recommended): image_picker ya los soporta, falta widget `AnimatedNetworkImage` (Image.network directo + cache custom) y migración para `mime_type` / `is_animated`. Marcador del mapa quedaría estático (primer frame).
- **B) Overlay de GIFs / stickers**: integración Tenor/Giphy API, schema nuevo.
- **C) GIFs como reacciones**: picker en rating sheet, schema `spot_reactions`.

Tradeoffs comunes: storage (GIFs 5-10× JPEG), batería en listas, moderación (files más grandes). Pendiente confirmar: scope, opt-in vs auto-detect, max size.

### 2. Spots existentes sin foto
Decidido: dejarlos con icono (no se fuerza foto al editar).

### 3. Spots viejos con `spot_photos(*)` JOIN
Decidido: ya resuelto en `de41a5a` — `fetchVisiblePhotos` se llama en paralelo.

### 4. SpotDetail → push directo
Decidido: implementado en sesión previa (sin peek card intermedio).

## SQL migrations aplicadas / pendientes

Aplicadas (verificadas o aplicadas por el user):
- 0007 (aka, instagram)
- 0008 (display_as)
- 0009 (rating moderation)
- 0010 (admin auto-confirm) — aplicada por el usuario durante esta sesión
- 0011 (fix rating audit trigger)
- 0012 (photo moderation)

Pendientes de aplicar en Supabase SQL editor (en orden):
- `0013_admin_moderation_policies.sql`
- `0014_social_likes_favorites.sql`
- `0015_in_app_notifications.sql`
- `0016_profile_avatar.sql`

## Convenciones del repo
- Branch feature off `develop`: `feat/<scope>-<subject>`.
- Conventional Commits en español. Commit por feature, no mega-commits.
- Data flow: SQL → DTO → mapper → domain → service → repository → ViewModel → screen → router.
- `dart analyze` debe quedar limpio antes de commit.
- Push solo con OK explícito del usuario.

## Archivos clave para retomar

- `lib/ui/shared/widgets/spot_marker.dart` — `_CircularPin` con ClipOval + SizedBox.expand + CachedNetworkImage (futuro: AnimatedNetworkImage para GIFs).
- `lib/ui/shared/widgets/user_avatar.dart` — avatar reutilizable (CachedNetworkImage + initial fallback).
- `lib/data/services/profile_service.dart` — `uploadAvatar` (path `<uid>/avatar_<ts>.<ext>`).
- `lib/data/repositories/spot_repository.dart` — `_hydrate` con `likedIds` + `favoritedIds` (stamps isLiked/isFavorited).
- `lib/data/repositories/admin_moderation_repository.dart` — `pendingRatingsProvider` / `pendingPhotosProvider`.
- `lib/ui/features/admin/views/admin_pending_screen.dart` — TabBar moderación.
- `lib/ui/core/widgets/notifications_listener.dart` — diff SnackBar via MaterialApp.builder.
- `lib/ui/features/onboarding/` — splash → onboarding → auth routing.
- `supabase/migrations/` — 0013/0014/0015/0016 pendientes en Supabase.
