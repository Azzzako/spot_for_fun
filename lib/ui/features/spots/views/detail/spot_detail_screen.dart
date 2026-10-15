import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:spot_for_fun/data/repositories/auth_provider.dart';
import 'package:spot_for_fun/data/repositories/social_repository.dart';
import 'package:spot_for_fun/data/repositories/spot_rating_repository.dart';
import 'package:spot_for_fun/data/repositories/spot_repository.dart';
import 'package:spot_for_fun/domain/enums.dart';
import 'package:spot_for_fun/domain/models/spot.dart';
import 'package:spot_for_fun/domain/models/spot_rating.dart';
import 'package:spot_for_fun/ui/core/deeplinks/spot_links.dart';
import 'package:spot_for_fun/ui/core/theme/app_colors.dart';
import 'package:spot_for_fun/ui/core/theme/app_theme.dart';
import 'package:spot_for_fun/ui/features/map/view_models/map_view_model.dart';
import 'package:spot_for_fun/ui/features/social/view_models/social_view_model.dart';
import 'package:spot_for_fun/ui/features/spots/view_models/write_rating_view_model.dart';
import 'package:spot_for_fun/ui/features/spots/views/detail/spot_photo_viewer_screen.dart';
import 'package:spot_for_fun/ui/features/spots/widgets/add_spot_photo_sheet.dart';
import 'package:spot_for_fun/ui/features/spots/widgets/write_rating_sheet.dart';
import 'package:spot_for_fun/ui/shared/widgets/spot_photo_placeholder.dart';
import 'package:spot_for_fun/ui/shared/widgets/staggered_entrance.dart';
import 'package:spot_for_fun/ui/shared/widgets/tape_label.dart';
import 'package:spot_for_fun/ui/shared/widgets/urban_chip.dart';
import 'package:spot_for_fun/ui/shared/widgets/user_avatar.dart';

/// Fresh copy of the spot from the server. Doesn't depend on favorites:
/// toggling one must not download the spot again.
final spotByIdProvider = FutureProvider.family.autoDispose<Spot, String>((
  ref,
  id,
) {
  return ref.watch(spotRepositoryProvider).fetchById(id);
});

final visibleRatingsProvider = FutureProvider.family
    .autoDispose<List<SpotRating>, String>((ref, spotId) async {
      final repo = ref.watch(spotRatingRepositoryProvider);
      return repo.fetchVisibleForSpot(spotId);
    });

class SpotDetailScreen extends ConsumerWidget {
  const SpotDetailScreen({super.key, required this.spotId});

  final String spotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSpot = ref.watch(spotByIdProvider(spotId));
    // The map's copy, if it has one: the screen opens with it instantly
    // (and offline) while the fresh copy loads.
    final cached = ref.watch(
      spotCatalogProvider.select((catalog) {
        for (final s in catalog.spots) {
          if (s.id == spotId) return s;
        }
        return null;
      }),
    );
    // "Not found" means it's gone or no longer visible: don't keep
    // showing the stale copy then.
    final spot = asyncSpot.error is StateError
        ? null
        : asyncSpot.valueOrNull ?? cached;

    return Scaffold(
      body: spot != null
          ? _DetailBody(spot: spot)
          : asyncSpot.hasError
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 44,
                      color: AppColors.danger,
                    ),
                    const SizedBox(height: 12),
                    Text('NO SE PUDO CARGAR', style: AppTheme.display(26)),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () => ref.invalidate(spotByIdProvider(spotId)),
                      child: const Text('REINTENTAR'),
                    ),
                  ],
                ),
              ),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.spot});
  final Spot spot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Photos are fetched separately so Supabase applies the
    // spot_photos RLS (the embedded select in fetchById doesn't).
    final photosAsync = ref.watch(spotPhotosVisibleProvider(spot.id));
    // Until they arrive, the cover (already cached by the map card).
    final photos =
        photosAsync.valueOrNull ??
        [
          if (spot.coverUrl != null)
            SpotPhoto(
              id: 'cover',
              spotId: spot.id,
              url: spot.coverUrl!,
              position: 0,
              photoStatus: PhotoStatus.approved,
            ),
        ];
    final isOwner = ref.watch(currentUserIdProvider) == spot.authorId;
    final hasSafety =
        spot.safetyNotes != null && spot.safetyNotes!.trim().isNotEmpty;
    final hasReject =
        spot.rejectReason != null && spot.rejectReason!.trim().isNotEmpty;
    // Only approved spots are public, so only those can be shared.
    final shareLink = spot.status == SpotStatus.approved
        ? SpotLinks.forSpot(spot.id)
        : null;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 400,
          pinned: true,
          backgroundColor: AppColors.asphalt,
          automaticallyImplyLeading: false,
          leading: Padding(
            padding: const EdgeInsets.all(6),
            child: _HeroButton(
              tooltip: 'Volver',
              icon: Icons.arrow_back,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          actions: [
            if (shareLink != null)
              Padding(
                padding: const EdgeInsets.all(6),
                child: _HeroButton(
                  tooltip: 'Compartir',
                  icon: Icons.ios_share,
                  onPressed: () => _share(context, shareLink),
                ),
              ),
            if (isOwner)
              Padding(
                padding: const EdgeInsets.all(6),
                child: _HeroButton(
                  tooltip: 'Agregar fotos',
                  icon: Icons.add_a_photo_outlined,
                  onPressed: () async {
                    final ok = await AddSpotPhotoSheet.show(context, spot);
                    if (ok == true && context.mounted) {
                      ref.invalidate(spotByIdProvider(spot.id));
                      ref.invalidate(spotPhotosVisibleProvider(spot.id));
                    }
                  },
                ),
              ),
            const SizedBox(width: 6),
          ],
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            background: Stack(
              fit: StackFit.expand,
              children: [
                _PhotoGallery(photos: photos, spotId: spot.id),
                Positioned(
                  left: 20,
                  bottom: 18,
                  child: IgnorePointer(
                    child: Row(
                      children: [
                        TapeLabel(spot.type.label, angleDegrees: -3),
                        const SizedBox(width: 8),
                        TapeLabel(
                          spot.difficulty.label,
                          color: AppColors.bone,
                          angleDegrees: 2,
                        ),
                        if (spot.status != SpotStatus.approved) ...[
                          const SizedBox(width: 8),
                          TapeLabel(
                            spot.status.label,
                            color: spot.status == SpotStatus.rejected
                                ? AppColors.danger
                                : AppColors.boneMuted,
                            angleDegrees: -1.5,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate.fixed(
              [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        spot.name.toUpperCase(),
                        style: theme.textTheme.displayMedium,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _FavoriteButton(spot: spot),
                  ],
                ),
                if (spot.authorDisplayName != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'POR @${spot.authorDisplayName!.toUpperCase()}',
                    style: AppTheme.label(12, color: AppColors.boneMuted),
                  ),
                ],
                const SizedBox(height: 18),
                _StatsRow(spot: spot),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () => _openDirections(context, spot),
                  icon: const Icon(Icons.navigation_outlined),
                  label: const Text('CÓMO LLEGAR'),
                ),
                const SizedBox(height: 10),
                _RatingCta(spot: spot),
                if (spot.description.trim().isNotEmpty)
                  _Section(
                    title: 'La línea',
                    child: Text(
                      spot.description.trim(),
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                    ),
                  ),
                if (spot.bestTime.isNotEmpty)
                  _Section(
                    title: 'Mejor hora',
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final t in spot.bestTime)
                          _StaticTag(label: t.label),
                      ],
                    ),
                  ),
                if (hasSafety)
                  _Section(
                    title: 'Seguridad',
                    child: _Notice(
                      icon: Icons.warning_amber_rounded,
                      color: AppColors.tape,
                      text: spot.safetyNotes!.trim(),
                    ),
                  ),
                if (hasReject)
                  _Section(
                    title: 'Motivo de rechazo',
                    child: _Notice(
                      icon: Icons.block,
                      color: AppColors.danger,
                      text: spot.rejectReason!.trim(),
                    ),
                  ),
                _Section(
                  title: 'Reseñas',
                  child: _RatingsSection(spotId: spot.id),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text(
                      'DESDE ${DateFormat('d MMM y', 'es').format(spot.createdAt).toUpperCase()}',
                      style: AppTheme.label(11, color: AppColors.boneMuted),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _openReportModal(context),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.boneMuted,
                      ),
                      icon: const Icon(Icons.flag_outlined, size: 18),
                      label: const Text('Reportar spot'),
                    ),
                  ],
                ),
              ].staggeredEntrance(context, delay: Duration.zero),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _share(BuildContext context, Uri link) async {
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text:
            'Mira este spot en Spot4Fun: ${spot.name} '
            '(${spot.type.label} · ${spot.difficulty.label})\n$link',
        subject: spot.name,
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  Future<void> _openDirections(BuildContext context, Spot spot) async {
    final lat = spot.lat.toStringAsFixed(6);
    final lng = spot.lng.toStringAsFixed(6);
    final encodedName = Uri.encodeComponent(spot.name);
    final geo = Uri.parse('geo:$lat,$lng?q=$lat,$lng($encodedName)');
    final web = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    final messenger = ScaffoldMessenger.of(context);
    if (await canLaunchUrl(geo)) {
      await launchUrl(geo, mode: LaunchMode.externalApplication);
      return;
    }
    if (await canLaunchUrl(web)) {
      await launchUrl(web, mode: LaunchMode.externalApplication);
      return;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el mapa.')),
      );
  }

  void _openReportModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _ReportSheet(spotId: spot.id, parentContext: context),
    );
  }
}

class _HeroButton extends StatelessWidget {
  const _HeroButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.asphalt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppColors.lineStrong, width: 1.5),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: AppColors.bone, size: 22),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.only(top: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title.toUpperCase(),
            style: AppTheme.label(12, color: AppColors.boneMuted),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _StaticTag extends StatelessWidget {
  const _StaticTag({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: AppColors.lineStrong, width: 1.5),
      ),
      child: Text(label.toUpperCase(), style: AppTheme.label(12)),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.concrete,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _ReportCategory {
  const _ReportCategory(this.label, this.value);
  final String label;
  final String value;
}

const _reportCategories = <_ReportCategory>[
  _ReportCategory('Spam / publicidad', 'spam'),
  _ReportCategory('Información incorrecta', 'wrong_info'),
  _ReportCategory('Contenido ofensivo', 'offensive'),
  _ReportCategory('Ya no existe', 'gone'),
  _ReportCategory('Otro', 'other'),
];

class _ReportSheet extends StatefulWidget {
  const _ReportSheet({required this.spotId, required this.parentContext});
  final String spotId;
  final BuildContext parentContext;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  final _detailsCtrl = TextEditingController();
  _ReportCategory? _selected;
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _detailsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('REPORTAR SPOT', style: AppTheme.display(28)),
          const SizedBox(height: 6),
          Text(
            'Elige un motivo. Opcionalmente añade detalles.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 6,
            runSpacing: 8,
            children: [
              for (final c in _reportCategories)
                UrbanChip(
                  label: c.label,
                  selected: c == _selected,
                  onTap: () => setState(() => _selected = c),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _detailsCtrl,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Detalles (opcional)'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _selected == null || _sending ? null : _submit,
            child: Text(_sending ? 'ENVIANDO…' : 'ENVIAR REPORTE'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final cat = _selected;
    if (cat == null) return;
    final details = _detailsCtrl.text.trim();
    final reason = details.isEmpty ? cat.label : '${cat.label}: $details';
    final repo = ProviderScope.containerOf(
      context,
    ).read(spotRepositoryProvider);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(widget.parentContext);
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await repo.reportSpot(spotId: widget.spotId, reason: reason);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = 'No se pudo enviar el reporte. Inténtalo de nuevo.';
      });
      return;
    }
    navigator.pop();
    messenger.showSnackBar(
      const SnackBar(content: Text('Reporte enviado. Gracias.')),
    );
  }
}

/// RATING · RESEÑAS · DISTANCIA (or the first best time when the user's
/// position is unknown).
class _StatsRow extends ConsumerWidget {
  const _StatsRow({required this.spot});
  final Spot spot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final map = ref.watch(mapViewModelProvider);
    final from = map.hasRealLocation ? map.currentLocation : null;

    final String thirdValue;
    final String thirdLabel;
    if (from != null) {
      final meters = const Distance().as(
        LengthUnit.Meter,
        from,
        LatLng(spot.lat, spot.lng),
      );
      thirdValue = meters < 1000
          ? '${meters.round()} M'
          : '${(meters / 1000).toStringAsFixed(1)} KM';
      thirdLabel = 'Distancia';
    } else if (spot.bestTime.isNotEmpty) {
      thirdValue = spot.bestTime.first.label.toUpperCase();
      thirdLabel = 'Mejor hora';
    } else {
      thirdValue = '—';
      thirdLabel = 'Distancia';
    }

    return Row(
      children: [
        Expanded(
          child: _StatBox(
            value: spot.ratingsCount == 0
                ? '—'
                : NumberFormat('0.0').format(spot.avgRating),
            label: 'Rating',
            highlight: spot.ratingsCount > 0,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatBox(
            value: spot.ratingsCount.toString(),
            label: 'Reseñas',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatBox(value: thirdValue, label: thirdLabel),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.value,
    required this.label,
    this.highlight = false,
  });

  final String value;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTheme.display(
                28,
                color: highlight ? AppColors.tape : AppColors.bone,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: AppTheme.label(10, color: AppColors.boneMuted),
          ),
        ],
      ),
    );
  }
}

class _FavoriteButton extends ConsumerWidget {
  const _FavoriteButton({required this.spot});
  final Spot spot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved =
        ref.watch(myFavoritedSpotIdsProvider).valueOrNull?.contains(spot.id) ??
        spot.isFavorited;
    return Tooltip(
      message: saved ? 'Quitar de favoritos' : 'Guardar en favoritos',
      child: Material(
        color: saved ? AppColors.tape : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppColors.tape, width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () => _reportSocialResult(
            ScaffoldMessenger.of(context),
            ref
                .read(socialViewModelProvider.notifier)
                .toggleFavorite(spotId: spot.id, currentlyFavorited: saved),
          ),
          child: SizedBox(
            width: 52,
            height: 52,
            child: Icon(
              saved ? Icons.bookmark : Icons.bookmark_border,
              color: saved ? AppColors.asphalt : AppColors.tape,
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _reportSocialResult(
  ScaffoldMessengerState messenger,
  Future<bool> result,
) async {
  if (await result) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(
        content: Text('No se pudo actualizar. Inténtalo de nuevo.'),
      ),
    );
}

class _PhotoGallery extends StatefulWidget {
  const _PhotoGallery({required this.photos, required this.spotId});
  final List<SpotPhoto> photos;
  final String spotId;

  static String heroTag(String spotId, int index) =>
      'spot-photo-$spotId-$index';

  @override
  State<_PhotoGallery> createState() => _PhotoGalleryState();
}

class _PhotoGalleryState extends State<_PhotoGallery> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;
    if (photos.isEmpty) return const SpotPhotoPlaceholder();
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: photos.length,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (_, i) {
            final photo = photos[i];
            return GestureDetector(
              onTap: () => _openFullscreen(context, i),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: _PhotoGallery.heroTag(widget.spotId, i),
                    child: CachedNetworkImage(
                      imageUrl: photo.url,
                      fit: BoxFit.cover,
                      placeholder: (_, _) =>
                          const ColoredBox(color: AppColors.concreteHigh),
                      errorWidget: (_, _, _) => const SpotPhotoPlaceholder(),
                    ),
                  ),
                  if (photo.photoStatus == PhotoStatus.pending)
                    const Positioned(
                      right: 16,
                      bottom: 18,
                      child: TapeLabel(
                        'En revisión',
                        color: AppColors.bone,
                        angleDegrees: 2,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        if (photos.length > 1)
          Positioned(
            left: 20,
            right: 20,
            bottom: 60,
            child: IgnorePointer(
              child: Row(
                children: [
                  for (var i = 0; i < photos.length; i++) ...[
                    if (i > 0) const SizedBox(width: 4),
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        height: 3,
                        color: i == _page
                            ? AppColors.tape
                            : AppColors.bone.withValues(alpha: 0.35),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _openFullscreen(BuildContext context, int index) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black87,
        barrierDismissible: true,
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, _, _) => SpotPhotoViewerScreen(
          photos: widget.photos,
          initialIndex: index,
          spotId: widget.spotId,
        ),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }
}

class _RatingCta extends ConsumerStatefulWidget {
  const _RatingCta({required this.spot});
  final Spot spot;

  @override
  ConsumerState<_RatingCta> createState() => _RatingCtaState();
}

class _RatingCtaState extends ConsumerState<_RatingCta> {
  // The view model family is keyed by the Spot instance, and the screen
  // swaps the cached copy for the fresh one; stick to the first so the
  // review state isn't loaded twice (or left unloaded).
  late final Spot _spot = widget.spot;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(writeRatingViewModelProvider(_spot).notifier).hydrate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final spot = _spot;
    final uid = ref.watch(currentUserIdProvider);
    if (uid == null) return const SizedBox.shrink();
    final state = ref.watch(writeRatingViewModelProvider(spot));
    if (!state.hydrated) {
      return const SizedBox(
        height: 52,
        child: Center(
          child: SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
        ),
      );
    }

    if (state.isOwnSpot) {
      return Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.line, width: 1.5),
        ),
        child: Text(
          'ERES EL AUTOR DE ESTE SPOT',
          style: AppTheme.label(12, color: AppColors.boneMuted),
        ),
      );
    }

    final hasReview = state.hasExisting;
    final locked = hasReview && !state.canEdit;

    final String label;
    final IconData icon;
    if (locked) {
      label = 'RESEÑA PUBLICADA';
      icon = Icons.check_circle_outline;
    } else if (hasReview) {
      label = 'EDITAR TU RESEÑA';
      icon = Icons.edit_outlined;
    } else {
      label = 'DEJAR RESEÑA';
      icon = Icons.rate_review_outlined;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: () async {
            final ok = await WriteRatingSheet.show(context, spot);
            if (ok == true) {
              ref.invalidate(visibleRatingsProvider(spot.id));
            }
          },
          icon: Icon(icon),
          label: Text(label),
          style: locked
              ? OutlinedButton.styleFrom(foregroundColor: AppColors.boneMuted)
              : null,
        ),
        const SizedBox(height: 6),
        _ProximityHint(state: state),
      ],
    );
  }
}

class _ProximityHint extends StatelessWidget {
  const _ProximityHint({required this.state});
  final WriteRatingState state;

  @override
  Widget build(BuildContext context) {
    if (state.isOwnSpot) return const SizedBox.shrink();
    if (state.hasExisting && !state.canEdit) return const SizedBox.shrink();

    final theme = Theme.of(context);
    String? text;
    Color? color;

    switch (state.locationStatus) {
      case RatingLocationStatus.denied:
        text = 'Activa el permiso de ubicación para poder dejar una reseña.';
        color = theme.colorScheme.error;
      case RatingLocationStatus.serviceOff:
        text = 'Enciende tu GPS para poder dejar una reseña.';
        color = theme.colorScheme.error;
      case RatingLocationStatus.error:
        text = 'No pudimos obtener tu ubicación. Inténtalo más tarde.';
        color = theme.colorScheme.error;
      case RatingLocationStatus.unknown:
        return const SizedBox.shrink();
      case RatingLocationStatus.granted:
        final d = state.distanceMeters;
        if (d == null) return const SizedBox.shrink();
        final meters = d.round();
        if (state.isNearEnough) {
          text = 'Estás a $meters m del spot · listo para reseñar.';
          color = AppColors.moss;
        } else {
          text =
              'Estás a $meters m. Acércate a menos de ${kRatingMaxDistanceMeters.toInt()} m para dejar reseña.';
          color = theme.colorScheme.onSurfaceVariant;
        }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(color: color),
      ),
    );
  }
}

class _RatingsSection extends ConsumerWidget {
  const _RatingsSection({required this.spotId});
  final String spotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(visibleRatingsProvider(spotId));
    final visible = async.valueOrNull ?? const <SpotRating>[];

    if (async.isLoading && visible.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (visible.isEmpty) {
      return Text(
        'Aún no hay reseñas. ¡Sé el primero en dejar una!',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final r in visible)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _RatingCard(rating: r),
          ),
      ],
    );
  }
}

class _RatingCard extends StatelessWidget {
  const _RatingCard({required this.rating});
  final SpotRating rating;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPending = rating.status == ReviewStatus.pending;
    final isRejected = rating.status == ReviewStatus.rejected;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.concrete,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isRejected ? AppColors.danger : AppColors.line,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                url: rating.userAvatarUrl,
                fallbackSeed: rating.authorDisplayName,
                size: 36,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '@${rating.authorDisplayName}',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _Stars(value: rating.rating),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat(
                            'd MMM y',
                            'es',
                          ).format(rating.createdAt).toUpperCase(),
                          style: AppTheme.label(10, color: AppColors.boneMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isPending || isRejected)
                TapeLabel(
                  rating.status.label,
                  fontSize: 10,
                  color: isRejected ? AppColors.danger : AppColors.bone,
                  angleDegrees: 2,
                ),
            ],
          ),
          if (rating.comment != null && rating.comment!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              rating.comment!.trim(),
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.value});
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++)
          Icon(
            i < value ? Icons.star : Icons.star_border,
            size: 15,
            color: i < value ? AppColors.tape : AppColors.lineStrong,
          ),
      ],
    );
  }
}
