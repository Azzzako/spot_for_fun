import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:spot_for_fun/domain/enums.dart';
import 'package:spot_for_fun/domain/models/spot.dart';
import 'package:spot_for_fun/data/repositories/spot_repository.dart';
import 'package:spot_for_fun/ui/features/spots/views/detail/spot_photo_viewer_screen.dart';
import 'package:spot_for_fun/ui/shared/constants/default_spot_images.dart';
import 'package:spot_for_fun/ui/shared/widgets/spot_marker.dart';

final spotByIdProvider =
    FutureProvider.family.autoDispose<Spot, String>((ref, id) async {
  final repo = ref.watch(spotRepositoryProvider);
  return repo.fetchById(id);
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
            background: _PhotoGallery(photos: spot.photos, spotId: spot.id),
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
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate.fixed([
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

  void _openReportModal(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
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
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            const Text(
              'Cuéntale al equipo por qué este spot no debería estar visible.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Motivo',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                if (ctrl.text.trim().isEmpty) return;
                await ref.read(spotRepositoryProvider).reportSpot(
                      spotId: spot.id,
                      reason: ctrl.text.trim(),
                    );
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reporte enviado. Gracias.')),
                  );
                }
              },
              child: const Text('Enviar reporte'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
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
      );
    }
    return PageView.builder(
      itemCount: photos.length,
      itemBuilder: (_, i) => GestureDetector(
        onTap: () => _openFullscreen(context, i),
        child: CachedNetworkImage(
          imageUrl: photos[i].url,
          fit: BoxFit.cover,
          placeholder: (_, _) => Container(color: Colors.black12),
          errorWidget: (_, _, _) => Image.asset(
            defaultSpotImageFor('$spotId,$i'),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  void _openFullscreen(BuildContext context, int index) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      barrierDismissible: true,
      builder: (_) => SpotPhotoViewerScreen(
        photos: photos,
        initialIndex: index,
        spotId: spotId,
      ),
    );
  }
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
