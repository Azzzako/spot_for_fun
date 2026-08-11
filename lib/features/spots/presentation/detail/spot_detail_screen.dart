import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/models/enums.dart';
import '../../../../shared/models/spot.dart';
import '../../../../shared/models/spot_photo.dart';
import '../../data/spot_repository.dart';

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
          expandedHeight: 260,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: _PhotoGallery(photos: spot.photos),
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
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate.fixed([
              Row(
                children: [
                  Expanded(
                    child: Text(
                      spot.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _RatingBadge(
                    avg: spot.avgRating,
                    count: spot.ratingsCount,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _ChipText(label: spot.type.label),
                  const SizedBox(width: 6),
                  _ChipText(label: spot.difficulty.label),
                ],
              ),
              const SizedBox(height: 16),
              if (spot.bestTime.isNotEmpty) ...[
                Text('Mejor horario',
                    style: theme.textTheme.titleSmall),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: spot.bestTime
                      .map((t) => _ChipText(label: t.label))
                      .toList(),
                ),
                const SizedBox(height: 16),
              ],
              if (spot.description.isNotEmpty) ...[
                Text('Descripción', style: theme.textTheme.titleSmall),
                const SizedBox(height: 6),
                Text(spot.description),
                const SizedBox(height: 16),
              ],
              if (spot.safetyNotes != null && spot.safetyNotes!.isNotEmpty) ...[
                Text('Notas de seguridad',
                    style: theme.textTheme.titleSmall),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withValues(alpha: 0.4),
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
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),
              ],
              _MetaRow(spot: spot),
              const SizedBox(height: 24),
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

class _PhotoGallery extends StatelessWidget {
  const _PhotoGallery({required this.photos});
  final List<SpotPhoto> photos;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return PageView.builder(
      itemCount: photos.length,
      itemBuilder: (_, i) => CachedNetworkImage(
        imageUrl: photos[i].url,
        fit: BoxFit.cover,
        placeholder: (_, _) => Container(color: Colors.black12),
        errorWidget: (_, _, _) => Container(
          color: Colors.black26,
          child: const Icon(Icons.broken_image, color: Colors.white54),
        ),
      ),
    );
  }
}

class _ChipText extends StatelessWidget {
  const _ChipText({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.avg, required this.count});
  final double avg;
  final int count;

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return Text(
        'Sin reseñas',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      );
    }
    final fmt = NumberFormat('0.0');
    return Row(
      children: [
        const Icon(Icons.star_rounded, size: 18, color: Colors.amber),
        const SizedBox(width: 2),
        Text(fmt.format(avg)),
        const SizedBox(width: 4),
        Text('($count)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )),
      ],
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
            size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text('Creado $created',
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
