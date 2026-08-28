import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:spot_for_fun/domain/enums.dart';
import 'package:spot_for_fun/domain/models/spot.dart';
import 'package:spot_for_fun/ui/shared/constants/default_spot_images.dart';

class SpotPeekCard extends StatelessWidget {
  const SpotPeekCard({
    super.key,
    required this.spot,
    required this.onClose,
    required this.onViewDetail,
  });

  final Spot spot;
  final VoidCallback onClose;
  final VoidCallback onViewDetail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Thumbnail(
                  photos: spot.photos,
                  spotId: spot.id,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        spot.name.toUpperCase(),
                        style: GoogleFonts.poppins(
                          textStyle:
                              theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _Chip(label: spot.type.label),
                          _Chip(label: spot.difficulty.label),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _RatingBadge(
                        avg: spot.avgRating,
                        count: spot.ratingsCount,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onClose,
                    child: const Text('Cerrar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.read_more),
                    label: const Text('Ver detalle'),
                    onPressed: onViewDetail,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({
    required this.photos,
    required this.spotId,
  });

  final List<SpotPhoto> photos;
  final String spotId;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fallback = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 80,
        height: 80,
        child: Image.asset(
          defaultSpotImageFor(spotId),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            color: scheme.surfaceContainerHigh,
            child: Icon(
              Icons.image_not_supported_outlined,
              size: 32,
              color: scheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );

    if (photos.isEmpty) return fallback;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 80,
        height: 80,
        child: CachedNetworkImage(
          imageUrl: photos.first.url,
          fit: BoxFit.cover,
          placeholder: (_, _) => Container(color: scheme.surfaceContainerHigh),
          errorWidget: (_, _, _) => fallback,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

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
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium,
      ),
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
              color: Theme.of(context).colorScheme.onSurface
                  .withValues(alpha: 0.55),
            ),
      );
    }
    final fmt = NumberFormat('0.0');
    return Row(
      children: [
        const Icon(Icons.star_rounded, size: 18, color: Color(0xFFFBBF24)),
        const SizedBox(width: 2),
        Text(fmt.format(avg)),
        const SizedBox(width: 4),
        Text(
          '($count)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface
                    .withValues(alpha: 0.55),
              ),
        ),
      ],
    );
  }
}
