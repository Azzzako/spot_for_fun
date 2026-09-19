import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:spot_for_fun/data/repositories/auth_provider.dart';
import 'package:spot_for_fun/data/repositories/spot_rating_repository.dart';
import 'package:spot_for_fun/data/repositories/spot_repository.dart';
import 'package:spot_for_fun/domain/enums.dart';
import 'package:spot_for_fun/domain/models/spot.dart';
import 'package:spot_for_fun/domain/models/spot_rating.dart';
import 'package:spot_for_fun/ui/features/spots/view_models/write_rating_view_model.dart';
import 'package:spot_for_fun/ui/features/spots/views/detail/spot_photo_viewer_screen.dart';
import 'package:spot_for_fun/ui/features/spots/widgets/add_spot_photo_sheet.dart';
import 'package:spot_for_fun/ui/features/spots/widgets/write_rating_sheet.dart';
import 'package:spot_for_fun/ui/shared/constants/default_spot_images.dart';
import 'package:spot_for_fun/ui/shared/widgets/spot_marker.dart';

final spotByIdProvider =
    FutureProvider.family.autoDispose<Spot, String>((ref, id) async {
  final repo = ref.watch(spotRepositoryProvider);
  return repo.fetchById(id);
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

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: asyncSpot.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 8),
                const Text('No se pudo cargar el spot.'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(spotByIdProvider(spotId)),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
        data: (spot) => _DetailBody(spot: spot),
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.spot});
  final Spot spot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final canSeePrivate = spot.status != SpotStatus.approved;
    // Photos are fetched separately so Supabase applies the
    // spot_photos RLS (the embedded select in fetchById doesn't).
    final photosAsync = ref.watch(spotPhotosVisibleProvider(spot.id));
    final photos = photosAsync.valueOrNull ?? const <SpotPhoto>[];

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: Colors.white,
          leading: Padding(
            padding: const EdgeInsets.all(8),
            child: Material(
              color: Colors.black.withValues(alpha: 0.45),
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
          actions: [
            if (canSeePrivate)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Chip(
                  label: Text(spot.status.label),
                  backgroundColor: spot.status == SpotStatus.rejected
                      ? theme.colorScheme.errorContainer
                      : theme.colorScheme.tertiaryContainer,
                ),
              ),
            if (_isOwner(ref, spot))
              Padding(
                padding: const EdgeInsets.all(8),
                child: Material(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: 'Agregar fotos',
                    icon: const Icon(Icons.add_a_photo_outlined,
                        color: Colors.white),
                    onPressed: () async {
                      final ok = await AddSpotPhotoSheet.show(context, spot);
                      if (ok == true && context.mounted) {
                        ref.invalidate(spotByIdProvider(spot.id));
                      }
                    },
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Material(
                color: Colors.black.withValues(alpha: 0.45),
                shape: const CircleBorder(),
                child: IconButton(
                  icon: const Icon(Icons.ios_share_rounded,
                      color: Colors.white),
                  onPressed: () => _stubAction(context, 'Compartir'),
                ),
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: _PhotoGallery(photos: photos, spotId: spot.id),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    spotMarkerPin(
                      kind: resolveSpotKind(spot),
                      brightness: theme.brightness,
                      size: 40,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            spot.name.toUpperCase(),
                            style: GoogleFonts.poppins(
                              textStyle:
                                  theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          if (spot.authorDisplayName != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Por @${spot.authorDisplayName}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                spot.type.label,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.65),
                                ),
                              ),
                              Text(
                                '  ·  ',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  'Ciudad de México',
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.65),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _FavoriteButton(),
                  ],
                ),
                const SizedBox(height: 20),
                _StatsRow(spot: spot),
                const SizedBox(height: 18),
                _ActionRow(spot: spot),
                const SizedBox(height: 18),
                _RatingCta(spot: spot),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate.fixed([
              _RatingsSection(spotId: spot.id),
              if (spot.description.isNotEmpty) ...[
                Text('Descripción', style: theme.textTheme.titleSmall),
                const SizedBox(height: 6),
                Text(spot.description),
                const SizedBox(height: 20),
              ],
              if (spot.bestTime.isNotEmpty) ...[
                Text('Mejor horario', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: spot.bestTime
                      .map((t) => _ChipText(label: t.label))
                      .toList(),
                ),
                const SizedBox(height: 20),
              ],
              if (spot.safetyNotes != null && spot.safetyNotes!.isNotEmpty) ...[
                Text('Notas de seguridad',
                    style: theme.textTheme.titleSmall),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer
                        .withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: theme.colorScheme.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(spot.safetyNotes!)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              if (spot.rejectReason != null &&
                  spot.rejectReason!.isNotEmpty) ...[
                Text('Motivo de rechazo',
                    style: theme.textTheme.titleSmall),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(spot.rejectReason!),
                ),
                const SizedBox(height: 20),
              ],
              _MetaRow(spot: spot),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _openReportModal(context, ref),
                icon: const Icon(Icons.flag_outlined),
                label: const Text('Reportar spot'),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  void _stubAction(BuildContext context, String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('$label · próximamente')),
      );
  }

  bool _isOwner(WidgetRef ref, Spot spot) {
    final uid = ref.read(currentUserIdProvider);
    return uid != null && uid == spot.authorId;
  }

  void _openReportModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _ReportSheet(spotId: spot.id, parentContext: context),
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
          Text(
            'Reportar este spot',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Elige un motivo. Opcionalmente añade detalles.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _reportCategories.map((c) {
              final isSel = c == _selected;
              return ChoiceChip(
                label: Text(c.label),
                selected: isSel,
                onSelected: (_) => setState(() => _selected = c),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _detailsCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Detalles (opcional)',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _selected == null ? null : _submit,
            child: const Text('Enviar reporte'),
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
    final repo = ProviderScope.containerOf(context).read(spotRepositoryProvider);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(widget.parentContext);
    await repo.reportSpot(spotId: widget.spotId, reason: reason);
    navigator.pop();
    messenger.showSnackBar(
      const SnackBar(content: Text('Reporte enviado. Gracias.')),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.spot});
  final Spot spot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = NumberFormat('0.0');
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatColumn(
              value: spot.ratingsCount == 0
                  ? '—'
                  : fmt.format(spot.avgRating),
              label: 'Calificación',
              icon: Icons.star_rounded,
              iconColor: const Color(0xFFFBBF24),
            ),
          ),
          _Divider(),
          Expanded(
            child: _StatColumn(
              value: spot.ratingsCount.toString(),
              label: 'Reseñas',
              icon: Icons.rate_review_rounded,
            ),
          ),
          _Divider(),
          Expanded(
            child: _StatColumn(
              value: '1.2 km',
              label: 'Distancia',
              icon: Icons.place_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.value,
    required this.label,
    required this.icon,
    this.iconColor,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: iconColor ?? theme.colorScheme.onSurface),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.6),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.spot});
  final Spot spot;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.bookmark_border_rounded,
            label: 'Guardar',
            onTap: () => _stub(context, 'Guardar'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionButton(
            icon: Icons.directions_rounded,
            label: 'Cómo llegar',
            onTap: () => _stub(context, 'Cómo llegar'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionButton(
            icon: Icons.ios_share_rounded,
            label: 'Compartir',
            onTap: () => _stub(context, 'Compartir'),
          ),
        ),
      ],
    );
  }

  void _stub(BuildContext context, String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('$label · próximamente')),
      );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteButton extends StatefulWidget {
  @override
  State<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<_FavoriteButton> {
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      onPressed: () {
        setState(() => _saved = !_saved);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(_saved ? 'Guardado' : 'Quitado'),
              duration: const Duration(seconds: 1),
            ),
          );
      },
      icon: Icon(
        _saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
        color: _saved ? theme.colorScheme.primary : null,
      ),
    );
  }
}

class _PhotoGallery extends StatelessWidget {
  const _PhotoGallery({required this.photos, required this.spotId});
  final List<SpotPhoto> photos;
  final String spotId;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return GestureDetector(
        onTap: () => _openFullscreen(context, 0),
        child: Hero(
          tag: _heroTag(spotId, 0),
          child: Image.asset(
            defaultSpotImageFor(spotId),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Center(
                child: Icon(
                  Icons.image_not_supported_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return PageView.builder(
      itemCount: photos.length,
      itemBuilder: (_, i) {
        final photo = photos[i];
        final pending = photo.photoStatus == PhotoStatus.pending;
        return GestureDetector(
          onTap: () => _openFullscreen(context, i),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Hero(
                tag: _heroTag(spotId, i),
                child: CachedNetworkImage(
                  imageUrl: photo.url,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Container(color: Colors.black12),
                  errorWidget: (_, _, _) => Image.asset(
                    defaultSpotImageFor('$spotId,$i'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              if (pending)
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.hourglass_top,
                            size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'En revisión',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
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
          photos: photos,
          initialIndex: index,
          spotId: spotId,
        ),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  static String _heroTag(String spotId, int index) =>
      'spot-photo-$spotId-$index';
}

class _ChipText extends StatelessWidget {
  const _ChipText({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.spot});
  final Spot spot;

  @override
  Widget build(BuildContext context) {
    final created = DateFormat.yMMMd().format(spot.createdAt);
    return Row(
      children: [
        Icon(Icons.access_time,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text('Creado $created',
            style: Theme.of(context).textTheme.bodySmall),
      ],
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(writeRatingViewModelProvider(widget.spot).notifier).hydrate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spot = widget.spot;
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
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.edit_note_outlined,
              size: 20,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 8),
            Text(
              'Eres el autor de este spot',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    final hasReview = state.hasExisting;
    final locked = hasReview && !state.canEdit;

    final String label;
    final IconData icon;
    if (locked) {
      label = 'Reseña publicada';
      icon = Icons.check_circle_outline;
    } else if (hasReview) {
      label = 'Editar tu reseña';
      icon = Icons.edit_outlined;
    } else {
      label = 'Dejar reseña';
      icon = Icons.rate_review_outlined;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: () async {
              final ok = await WriteRatingSheet.show(context, spot);
              if (ok == true) {
                ref.invalidate(visibleRatingsProvider(spot.id));
              }
            },
            icon: Icon(icon),
            label: Text(label),
            style: FilledButton.styleFrom(
              backgroundColor: locked
                  ? theme.colorScheme.surfaceContainerHigh
                  : null,
              foregroundColor: locked
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
                  : null,
            ),
          ),
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
        if (state.isNearEnough) {
          final meters = d.round();
          text = 'Estás a $meters m del spot · listo para reseñar.';
        } else {
          final meters = d.round();
          text =
              'Estás a $meters m. Acércate a menos de ${kRatingMaxDistanceMeters.toInt()} m para dejar reseña.';
        }
        color = state.isNearEnough
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface.withValues(alpha: 0.7);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
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
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'Aún no hay reseñas. ¡Sé el primero en dejar una!',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Reseñas (${visible.length})',
            style: theme.textTheme.titleSmall),
        const SizedBox(height: 12),
        ...visible.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RatingCard(rating: r),
            )),
        const SizedBox(height: 8),
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
    final accent = isPending
        ? theme.colorScheme.tertiaryContainer
        : isRejected
            ? theme.colorScheme.errorContainer
            : null;
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: accent != null ? Border.all(color: accent) : null,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.surfaceContainerHigh,
                child: Icon(
                  Icons.person_outline,
                  size: 18,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '@${rating.authorDisplayName}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Row(
                      children: [
                        _Stars(value: rating.rating),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat.yMMMd().format(rating.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isPending || isRejected)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    rating.status.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          if (rating.comment != null && rating.comment!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(rating.comment!.trim()),
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
      children: List.generate(5, (i) {
        final filled = i < value;
        return Icon(
          filled ? Icons.star_rounded : Icons.star_border_rounded,
          size: 16,
          color: filled
              ? const Color(0xFFFBBF24)
              : Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.3),
        );
      }),
    );
  }
}
