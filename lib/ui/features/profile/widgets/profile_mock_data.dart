import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:spot_for_fun/domain/enums.dart';
import 'package:spot_for_fun/domain/models/spot.dart';
import 'package:spot_for_fun/ui/shared/constants/default_spot_images.dart';

class SpotListCard extends StatelessWidget {
  const SpotListCard({
    super.key,
    required this.spot,
    this.onTap,
    this.onBookmarkToggle,
    this.bookmarked = false,
  });

  final Spot spot;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onBookmarkToggle;
  final bool bookmarked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final thumbUrl = spot.photos.isNotEmpty ? spot.photos.first.url : null;
    final showBanner = spot.status != SpotStatus.approved;

    final fallback = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        defaultSpotImageFor(spot.id),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          color: theme.colorScheme.surfaceContainerHigh,
          alignment: Alignment.center,
          child: Icon(
            Icons.image_not_supported_outlined,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ),
    );

    return Material(
      color: theme.colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: thumbUrl != null
                          ? CachedNetworkImage(
                              imageUrl: thumbUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, _) => Container(
                                color: theme.colorScheme.surfaceContainerHigh,
                              ),
                              errorWidget: (_, _, _) => fallback,
                            )
                          : fallback,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          spot.name.toUpperCase(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            textStyle:
                                theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          spot.type.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 18,
                              color: Color(0xFFFBBF24),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              spot.ratingsCount == 0
                                  ? 'Sin reseñas'
                                  : spot.avgRating.toStringAsFixed(1),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (spot.ratingsCount > 0) ...[
                              const SizedBox(width: 6),
                              Text(
                                '(${spot.ratingsCount})',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.55),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (onBookmarkToggle != null)
                    IconButton(
                      tooltip: bookmarked
                          ? 'Quitar favorito'
                          : 'Agregar favorito',
                      icon: Icon(
                        bookmarked
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        color: bookmarked
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                      ),
                      onPressed: () =>
                          onBookmarkToggle?.call(!bookmarked),
                    ),
                ],
              ),
            ),
            if (showBanner) _StatusBanner(spot: spot),
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.spot});
  final Spot spot;

  @override
  Widget build(BuildContext context) {
    final isRejected = spot.status == SpotStatus.rejected;
    final color = isRejected
        ? Theme.of(context).colorScheme.error
        : const Color(0xFFD32F2F);
    final IconData icon =
        isRejected ? Icons.cancel_outlined : Icons.hourglass_top;
    final title = isRejected
        ? 'Spot rechazado'
        : 'En proceso de revisión';
    final String subtitle;
    if (isRejected) {
      final reason = spot.rejectReason;
      subtitle = (reason != null && reason.isNotEmpty)
          ? reason
          : 'Tu spot no fue aprobado.';
    } else {
      subtitle =
          'Nuestro equipo lo está revisando. Te avisaremos cuando esté visible.';
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: Border(
          top: BorderSide(color: color.withValues(alpha: 0.35)),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
