import 'package:flutter/material.dart';

import 'package:spot_for_fun/ui/core/theme/app_colors.dart';
import 'package:spot_for_fun/ui/shared/constants/default_spot_images.dart';

class MockProfile {
  const MockProfile({
    required this.name,
    required this.city,
    required this.avatarSeed,
    required this.spotsCount,
    required this.favoritesCount,
    required this.reviewsCount,
  });

  final String name;
  final String city;
  final String avatarSeed;
  final int spotsCount;
  final int favoritesCount;
  final int reviewsCount;

  static const current = MockProfile(
    name: 'SkaterMX',
    city: 'Ciudad de Mexico',
    avatarSeed: 'skatermx',
    spotsCount: 12,
    favoritesCount: 48,
    reviewsCount: 36,
  );
}

class MockSpot {
  const MockSpot({
    required this.id,
    required this.name,
    required this.city,
    required this.state,
    required this.rating,
    required this.reviewCount,
    this.bookmarked = false,
  });

  final String id;
  final String name;
  final String city;
  final String state;
  final double rating;
  final int reviewCount;
  final bool bookmarked;

  String get location => '$city, $state';
}

const List<MockSpot> kMockMySpots = [
  MockSpot(
    id: 'mine-1',
    name: 'Plaza de la Juventud',
    city: 'CDMX',
    state: 'Mexico',
    rating: 4.6,
    reviewCount: 128,
    bookmarked: true,
  ),
  MockSpot(
    id: 'mine-2',
    name: 'Parque Hundido',
    city: 'CDMX',
    state: 'Mexico',
    rating: 4.4,
    reviewCount: 87,
  ),
  MockSpot(
    id: 'mine-3',
    name: 'Esquina Verde',
    city: 'CDMX',
    state: 'Mexico',
    rating: 4.2,
    reviewCount: 54,
  ),
];

const List<MockSpot> kMockFavoriteSpots = [
  MockSpot(
    id: 'fav-1',
    name: 'Lincoln Park',
    city: 'Monterrey',
    state: 'Mexico',
    rating: 4.7,
    reviewCount: 213,
    bookmarked: true,
  ),
  MockSpot(
    id: 'fav-2',
    name: 'Spot Secreto',
    city: 'Guadalajara',
    state: 'Mexico',
    rating: 4.2,
    reviewCount: 41,
    bookmarked: true,
  ),
  MockSpot(
    id: 'fav-3',
    name: 'Plaza de la Juventud',
    city: 'CDMX',
    state: 'Mexico',
    rating: 4.6,
    reviewCount: 128,
  ),
];

class SpotListCard extends StatelessWidget {
  const SpotListCard({
    super.key,
    required this.spot,
    this.onTap,
    this.onBookmarkToggle,
  });

  final MockSpot spot;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onBookmarkToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: Image.asset(
                    defaultSpotImageFor(spot.id),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: theme.colorScheme.onSurfaceVariant,
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
                      spot.location,
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
                          spot.rating.toStringAsFixed(1),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${spot.reviewCount} resenas',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onBookmarkToggle != null)
                IconButton(
                  tooltip: spot.bookmarked ? 'Quitar favorito' : 'Agregar favorito',
                  icon: Icon(
                    spot.bookmarked
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    color: spot.bookmarked
                        ? AppColors.brandGold
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () => onBookmarkToggle?.call(!spot.bookmarked),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.profile});

  final MockProfile profile;

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
                defaultSpotImageFor(profile.avatarSeed),
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
                    _OverlayStatColumn(
                      value: profile.spotsCount.toString(),
                      label: 'Spots',
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                    _OverlayStatColumn(
                      value: profile.favoritesCount.toString(),
                      label: 'Favoritos',
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                    _OverlayStatColumn(
                      value: profile.reviewsCount.toString(),
                      label: 'Resenas',
                    ),
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
                profile.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                profile.city,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
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