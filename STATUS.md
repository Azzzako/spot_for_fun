# STATUS — Contexto para retomar

Última sesión: spot_for_fun (develop @ 7726bc8). Todo commiteado y pusheado a `origin/develop`.

## Features completadas (en develop)

1. **Configuración** — pantalla dedicada en `/settings` con secciones Cuenta / Preferencias / Soporte / Sesión. Reemplaza el bottom sheet anterior. 4 placeholders (Privacidad, Notificaciones, Ayuda, Acerca de) en `ComingSoonScreen`. Editar perfil → pantalla real.

2. **Editar perfil** — nombre, A.K.A, correo (con link de confirmación al nuevo), Instagram. Username UNIQUE (mig 0007). Toggle "Mostrar como" (Nombre / A.K.A) con displayAs enum (mig 0008). Display name del autor de spots usa la preferencia. Si elige A.K.A sin tener → fallback silencioso a username.

3. **Reseñas** — `WriteRatingViewModel` (autoDispose family por Spot) + `WriteRatingSheet` (bottom sheet). Estrellas 1-5 + comentario obligatorio 5-500 chars. Submit crea/actualiza; al editar vuelve a pending. Una sola edición (flag `edited` + trigger BEFORE UPDATE en mig 0009, corregido por mig 0011 para no pisar moderación). GPS ≤500m obligatorio (`kRatingMaxDistanceMeters`). `myRatingsProvider` lista reseñas del usuario en Perfil > Reseñas con banner de revisión (espejo del `_StatusBanner` de spots).

4. **Admin bypass** — mig 0010: trigger BEFORE INSERT en `auth.users` que auto-confirma `admin@admin.com` (case-insensitive). Saltarse verificación de email.

5. **Container transform en SpotListCard** — `OpenSpotCard` envuelve la card en `OpenContainer` con `ContainerTransitionType.fadeThrough` (350ms). Reduced motion → push normal sin animación.

6. **SpotDetail → push directo** — tap en marker del mapa abre `SpotDetailScreen` directo (sin peek card / modal sheet intermedio). Misma transición fade-through del router que desde Perfil.

7. **Fotos en reseñas y spot** — mig 0012: enum `photo_status`, columnas `user_id` (backfill) + `review_id` + `photo_status` en `spot_photos`. RLS permite a reviewer y autor del spot ver sus pending. `WriteRatingSheet`: máx 2 fotos por reseña, badge "En revisión" en las existentes pending, X para borrar. `AddSpotPhotoSheet`: máx 5 fotos extra para el autor del spot. Spot detail: action `add_a_photo` en SliverAppBar solo para autor; carrusel muestra badge "En revisión" sobre pending.

8. **Visualizador de fotos rediseñado** — glassmorphism con `BackdropFilter`, gradientes superior/inferior sobre `scheme.surface`, dot indicator animado (active se expande con `flutter_animate` easeOutBack), InteractiveViewer con `panAxis: PanAxis.aligned` (no rompe swipe horizontal del PageView). Tap en márgenes cierra.

## Decisiones pendientes para mañana

- **Botón de reseña que no aparece** — el `_RatingCta` ahora se hidrata al construirse y muestra `_ProximityHint` debajo. Si el usuario es el autor del spot → botón oculto (regla "no reseñar tu propio spot"). Pendiente: confirmar si el usuario en cuestión es el autor; si no, agregar log/UI para diagnosticar.

- **fetchApproved / fetchByAuthor / mapa** — siguen trayendo fotos con JOIN `spot_photos(*)`. La RLS no se aplica bien en JOIN de PostgREST, pero como esos lugares solo muestran spots approved + fotos approved (caso común), el bug es menos visible. Si se vuelve a reportar, separar a `fetchVisiblePhotos(spotId)` también ahí.

- **Foto gallery como Hero desde el thumb** — no implementado. El container transform del `OpenSpotCard` no enlaza con el visualizador. Si se quiere esa experiencia premium, agregar `Hero(tag: 'spot-photo-${spot.id}-${i}', ...)` en el thumb y en el visualizador.

## SQL migrations pendientes de correr en Supabase

Si todavía no se aplicaron, en este orden:
- `0009_spot_ratings_moderation.sql` — enum review_status, columnas edited + edited_at, trigger spot_ratings_audit, RLS.
- `0010_auto_confirm_admin_email.sql` — trigger antes de INSERT en auth.users para admin@admin.com.
- `0011_fix_rating_audit_trigger.sql` — el trigger de 0009 corregido para no resetear status en updates de moderación.
- `0012_spot_photo_moderation.sql` — enum photo_status, columnas en spot_photos, backfill de user_id, RLS.

Aprobar reseñas y fotos desde Supabase SQL / panel externo. La app no tiene UI de admin.

## Convenciones del repo

- Branch feature off `develop`: `feat/<scope>-<subject>`.
- Conventional Commits en español. Commit por feature, no mega-commits.
- Data flow: SQL → DTO → mapper → domain → service → repository → ViewModel → screen → router.
- No pushear sin OK explícito del usuario.

## Dudas / bugs reportados que necesitan revisión

- Si el botón "Dejar reseña" sigue sin aparecer para spots donde el usuario NO es el autor: hay que agregar fallback visible (texto "No puedes reseñar este spot" en vez de `SizedBox.shrink()`) para diagnosticar.
- Si approved del mapa muestra fotos pending del reviewer a todos: separar query como en `fetchById`.
