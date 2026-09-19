import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:spot_for_fun/ui/core/router/app_router.dart';
import 'package:spot_for_fun/data/repositories/auth_provider.dart';
import 'package:spot_for_fun/data/repositories/spot_rating_repository.dart';
import 'package:spot_for_fun/data/repositories/spot_repository.dart';
import 'package:spot_for_fun/domain/enums.dart';
import 'package:spot_for_fun/domain/models/spot.dart';
import 'package:spot_for_fun/domain/models/profile.dart';
import 'package:spot_for_fun/domain/models/spot_rating.dart';
import 'package:spot_for_fun/ui/features/spots/widgets/open_spot_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final mySpotsAsync = ref.watch(mySpotsProvider);

    final profile = profileAsync.valueOrNull;
    final mySpots = mySpotsAsync.valueOrNull ?? const <Spot>[];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              onSettings: () => context.push(AppRoutes.settings),
            ),
            Expanded(
              child: profile == null
                  ? _ProfileLoadingOrError(
                      async: profileAsync,
                      onRetry: () => ref.invalidate(currentProfileProvider),
                    )
                  : DefaultTabController(
                      length: 3,
                      child: Column(
                        children: [
                          _ProfileHeader(profile: profile, spotCount: mySpots.length),
                          const _TabsBar(),
                          Expanded(
                            child: TabBarView(
                              children: [
                                _MySpotsTab(
                                  asyncSpots: mySpotsAsync,
                                  spots: mySpots,
                                  ref: ref,
                                ),
                                const _FavoritesTab(),
                                const _ReviewsTab(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onSettings});
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            tooltip: 'Ajustes',
            icon: const Icon(Icons.settings_outlined),
            onPressed: onSettings,
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile, required this.spotCount});
  final Profile profile;
  final int spotCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.person_outline,
              size: 44,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            profile.displayName,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Ciudad de México',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatColumn(value: spotCount.toString(), label: 'Spots'),
              _StatDivider(),
              const _StatColumn(value: '0', label: 'Guardados'),
              _StatDivider(),
              const _StatColumn(value: '0', label: 'Reseñas'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: Theme.of(context).colorScheme.outline,
    );
  }
}

class _TabsBar extends StatelessWidget {
  const _TabsBar();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outline),
        ),
      ),
      child: TabBar(
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: theme.colorScheme.onSurface,
        unselectedLabelColor:
            theme.colorScheme.onSurface.withValues(alpha: 0.55),
        indicatorColor: theme.colorScheme.primary,
        indicatorWeight: 3,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
        tabs: const [
          Tab(text: 'Mis Spots'),
          Tab(text: 'Favoritos'),
          Tab(text: 'Reseñas'),
        ],
      ),
    );
  }
}

class _MySpotsTab extends StatelessWidget {
  const _MySpotsTab({
    required this.asyncSpots,
    required this.spots,
    required this.ref,
  });

  final AsyncValue<List<Spot>> asyncSpots;
  final List<Spot> spots;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    if (asyncSpots.isLoading && spots.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (asyncSpots.hasError && spots.isEmpty) {
      return _ErrorTab(
        message: 'No se pudieron cargar tus spots',
        onRetry: () => ref.invalidate(mySpotsProvider),
      );
    }
    if (spots.isEmpty) {
      return const _EmptyTab(
        icon: Icons.add_location_alt_outlined,
        title: 'Aún no tienes spots',
        subtitle: 'Cuando agregues uno aparecerá aquí.',
      );
    }
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(mySpotsProvider),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        itemCount: spots.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final s = spots[i];
          return OpenSpotCard(
            spot: s,
            liked: s.isLiked,
            bookmarked: s.isFavorited,
          );
        },
      ),
    );
  }
}

class _FavoritesTab extends ConsumerWidget {
  const _FavoritesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myFavoriteSpotsProvider);
    final spots = async.valueOrNull ?? const <Spot>[];

    if (async.isLoading && spots.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (async.hasError && spots.isEmpty) {
      return _ErrorTab(
        message: 'No se pudieron cargar tus favoritos',
        onRetry: () => ref.invalidate(myFavoriteSpotsProvider),
      );
    }
    if (spots.isEmpty) {
      return const _EmptyTab(
        icon: Icons.favorite_border,
        title: 'Aún no tienes favoritos',
        subtitle:
            'Toca el ícono de marcador en un spot para guardarlo aquí.',
      );
    }
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(myFavoriteSpotsProvider),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        itemCount: spots.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final s = spots[i];
          return OpenSpotCard(
            spot: s,
            liked: s.isLiked,
            bookmarked: s.isFavorited,
          );
        },
      ),
    );
  }
}

class _ReviewsTab extends ConsumerWidget {
  const _ReviewsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRatings = ref.watch(myRatingsProvider);
    final ratings = asyncRatings.valueOrNull ?? const <SpotRating>[];

    if (asyncRatings.isLoading && ratings.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (asyncRatings.hasError && ratings.isEmpty) {
      return _ErrorTab(
        message: 'No se pudieron cargar tus reseñas',
        onRetry: () => ref.invalidate(myRatingsProvider),
      );
    }
    if (ratings.isEmpty) {
      return const _EmptyTab(
        icon: Icons.rate_review_outlined,
        title: 'Aún no tienes reseñas',
        subtitle: 'Cuando califiques un spot aparecerá aquí.',
      );
    }
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(myRatingsProvider),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        itemCount: ratings.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _MyReviewCard(rating: ratings[i]),
      ),
    );
  }
}

class _MyReviewCard extends StatelessWidget {
  const _MyReviewCard({required this.rating});
  final SpotRating rating;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pending = rating.status == ReviewStatus.pending;
    final rejected = rating.status == ReviewStatus.rejected;
    final showBanner = pending || rejected;

    return Material(
      color: theme.colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(AppRoutes.spotDetail(rating.spotId)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          (rating.spotName ?? 'Spot').toUpperCase(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      _Stars(value: rating.rating),
                    ],
                  ),
                  if (rating.comment != null &&
                      rating.comment!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      rating.comment!.trim(),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        DateFormat.yMMMd().format(rating.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      if (rating.edited) ...[
                        const SizedBox(width: 8),
                        Text(
                          '· editada',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color:
                                theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (showBanner) _ReviewStatusBanner(rating: rating),
          ],
        ),
      ),
    );
  }
}

class _ReviewStatusBanner extends StatelessWidget {
  const _ReviewStatusBanner({required this.rating});
  final SpotRating rating;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRejected = rating.status == ReviewStatus.rejected;
    final color = isRejected
        ? theme.colorScheme.error
        : const Color(0xFFD32F2F);
    final IconData icon =
        isRejected ? Icons.cancel_outlined : Icons.hourglass_top;
    final title = isRejected ? 'Reseña rechazada' : 'Reseña en revisión';
    final subtitle = isRejected
        ? 'El equipo de moderación rechazó tu reseña.'
        : 'Nuestro equipo la está revisando. '
            'Una vez aprobada será visible para todos.';

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
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
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
          size: 18,
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

class _EmptyTab extends StatelessWidget {
  const _EmptyTab({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorTab extends StatelessWidget {
  const _ErrorTab({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(message),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

class _ProfileLoadingOrError extends StatelessWidget {
  const _ProfileLoadingOrError({required this.async, required this.onRetry});
  final AsyncValue<dynamic> async;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (async.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          const SizedBox(height: 12),
          const Text('No se pudo cargar tu perfil'),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
