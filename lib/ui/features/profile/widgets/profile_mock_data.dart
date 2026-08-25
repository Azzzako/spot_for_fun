import 'package:flutter/material.dart';

import 'package:spot_for_fun/domain/enums.dart';
import 'package:spot_for_fun/domain/models/spot.dart';
import 'package:spot_for_fun/ui/core/theme/app_colors.dart';
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
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: thumbUrl != null
                          ? Image.network(
                              thumbUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Image.asset(
                                defaultSpotImageFor(spot.id),
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  color: theme
                                      .colorScheme.surfaceContainerHighest,
                                  child: Icon(
                                    Icons.image_not_supported_outlined,
                                    color:
                                        theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            )
                          : Image.asset(
                              defaultSpotImageFor(spot.id),
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                color: theme
                                    .colorScheme.surfaceContainerHighest,
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  color:
                                      theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          spot.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          spot.type.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 18,
                              color: AppColors.brandGold,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              spot.ratingsCount == 0
                                  ? 'Sin resenas'
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
                                  color:
                                      theme.colorScheme.onSurfaceVariant,
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
                            ? AppColors.brandGold
                            : theme.colorScheme.onSurfaceVariant,
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
        : 'En proceso de revision';
    final String subtitle;
    if (isRejected) {
      final reason = spot.rejectReason;
      subtitle = (reason != null && reason.isNotEmpty)
          ? reason
          : 'Tu spot no fue aprobado.';
    } else {
      subtitle =
          'Nuestro equipo lo esta revisando. Te avisaremos cuando este visible.';
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

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.username,
    required this.userId,
    required this.spotsCount,
    required this.favoritesCount,
    required this.reviewsCount,
  });

  final String username;
  final String userId;
  final int spotsCount;
  final int favoritesCount;
  final int reviewsCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 140,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                defaultSpotImageFor(userId),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.person,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x00000000),
                      Color(0x99000000),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _OverlayStatColumn(value: spotsCount.toString(), label: 'Spots'),
                    Container(
                      width: 1,
                      height: 28,
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                    _OverlayStatColumn(
                        value: favoritesCount.toString(),
                        label: 'Favoritos'),
                    Container(
                      width: 1,
                      height: 28,
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                    _OverlayStatColumn(
                        value: reviewsCount.toString(),
                        label: 'Resenas'),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                username,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OverlayStatColumn extends StatelessWidget {
  const _OverlayStatColumn({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}