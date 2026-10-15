import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:spot_for_fun/data/repositories/auth_provider.dart';
import 'package:spot_for_fun/data/repositories/spot_rating_repository.dart';
import 'package:spot_for_fun/data/repositories/spot_repository.dart';
import 'package:spot_for_fun/domain/enums.dart';
import 'package:spot_for_fun/domain/models/profile.dart';
import 'package:spot_for_fun/domain/models/spot.dart';
import 'package:spot_for_fun/domain/models/spot_rating.dart';
import 'package:spot_for_fun/ui/core/router/app_router.dart';
import 'package:spot_for_fun/ui/core/theme/app_colors.dart';
import 'package:spot_for_fun/ui/core/theme/app_theme.dart';
import 'package:spot_for_fun/ui/features/social/view_models/social_view_model.dart';
import 'package:spot_for_fun/ui/shared/widgets/spot_photo_placeholder.dart';
import 'package:spot_for_fun/ui/shared/widgets/tape_label.dart';
import 'package:spot_for_fun/ui/shared/widgets/user_avatar.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final profile = profileAsync.valueOrNull;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: profile == null
            ? _ProfileLoadingOrError(
                async: profileAsync,
                onRetry: () => ref.invalidate(currentProfileProvider),
              )
            : DefaultTabController(
                length: 3,
                child: NestedScrollView(
                  headerSliverBuilder: (context, _) => [
                    SliverToBoxAdapter(child: _ProfileHeader(profile: profile)),
                    SliverOverlapAbsorber(
                      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                        context,
                      ),
                      sliver: SliverPersistentHeader(
                        pinned: true,
                        delegate: _TabsHeader(),
                      ),
                    ),
                  ],
                  body: const TabBarView(
                    children: [_MySpotsTab(), _FavoritesTab(), _ReviewsTab()],
                  ),
                ),
              ),
      ),
    );
  }
}

class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader({required this.profile});
  final Profile profile;

  static const _coverHeight = 150.0;
  static const _avatarSize = 96.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spotCount = ref.watch(mySpotsProvider).valueOrNull?.length;
    final favoriteCount = ref.watch(myFavoriteSpotsProvider).valueOrNull?.length;
    final ratingsCount = ref.watch(myRatingsProvider).valueOrNull?.length;

    final aka = profile.aka?.trim();
    // Show whichever name isn't already the big title.
    final secondary = profile.displayAs == DisplayAs.aka &&
            aka != null &&
            aka.isNotEmpty
        ? '@${profile.username}'
        : (aka != null && aka.isNotEmpty ? 'AKA $aka' : null);
    final instagram = profile.instagram?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _coverHeight + _avatarSize / 2 + 8,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: _coverHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/identity/background.png',
                      fit: BoxFit.cover,
                      alignment: const Alignment(0, 0.15),
                      errorBuilder: (_, _, _) =>
                          const ColoredBox(color: AppColors.concrete),
                    ),
                    const ColoredBox(color: Color(0x33111111)),
                  ],
                ),
              ),
              Positioned(
                right: 12,
                top: 12,
                child: _SquareIconButton(
                  tooltip: 'Ajustes',
                  icon: Icons.settings_outlined,
                  onPressed: () => context.push(AppRoutes.settings),
                ),
              ),
              Positioned(
                left: 20,
                top: _coverHeight - _avatarSize / 2,
                child: SizedBox(
                  width: _avatarSize + 8,
                  height: _avatarSize + 8,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        top: 0,
                        child: Transform.rotate(
                          angle: -3 * math.pi / 180,
                          child: Container(
                            width: _avatarSize + 6,
                            height: _avatarSize + 6,
                            color: AppColors.tape,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 3,
                        top: 3,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.asphalt,
                              width: 3,
                            ),
                          ),
                          child: UserAvatar(
                            url: profile.avatarUrl,
                            fallbackSeed: profile.username,
                            size: _avatarSize - 6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.displayName.toUpperCase(),
                style: AppTheme.display(40),
              ),
              if (secondary != null || (instagram?.isNotEmpty ?? false)) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 14,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (secondary != null)
                      Text(
                        secondary.toUpperCase(),
                        style: AppTheme.label(12, color: AppColors.boneMuted),
                      ),
                    if (instagram != null && instagram.isNotEmpty)
                      InkWell(
                        onTap: () => launchUrl(
                          Uri.parse('https://instagram.com/$instagram'),
                          mode: LaunchMode.externalApplication,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            '@${instagram.toUpperCase()}',
                            style: AppTheme.label(12, color: AppColors.tape),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              DecoratedBox(
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.line),
                    bottom: BorderSide(color: AppColors.line),
                  ),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(child: _Stat(value: spotCount, label: 'Spots')),
                      const VerticalDivider(width: 1, color: AppColors.line),
                      Expanded(
                        child: _Stat(
                          value: favoriteCount,
                          label: 'Favoritos',
                          inset: true,
                        ),
                      ),
                      const VerticalDivider(width: 1, color: AppColors.line),
                      Expanded(
                        child: _Stat(
                          value: ratingsCount,
                          label: 'Reseñas',
                          inset: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.inset = false});

  final int? value;
  final String label;
  final bool inset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(inset ? 16 : 0, 12, 0, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value?.toString() ?? '—', style: AppTheme.display(30)),
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

class _SquareIconButton extends StatelessWidget {
  const _SquareIconButton({
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

class _TabsHeader extends SliverPersistentHeaderDelegate {
  static const _height = 52.0;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    return Container(
      color: AppColors.asphalt,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.bottomLeft,
      child: const TabBar(
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        tabs: [
          Tab(text: 'MIS SPOTS'),
          Tab(text: 'FAVORITOS'),
          Tab(text: 'RESEÑAS'),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_TabsHeader oldDelegate) => false;
}

/// Scrollable tab body that sits correctly under the pinned tab bar.
class _TabBody extends StatelessWidget {
  const _TabBody({
    required this.storageKey,
    required this.onRefresh,
    required this.sliver,
  });

  final String storageKey;
  final Future<void> Function() onRefresh;
  final Widget sliver;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        key: PageStorageKey(storageKey),
        slivers: [
          SliverOverlapInjector(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            sliver: sliver,
          ),
        ],
      ),
    );
  }
}

class _SpotsTabContent extends StatelessWidget {
  const _SpotsTabContent({
    required this.storageKey,
    required this.async,
    required this.onRefresh,
    required this.empty,
    required this.errorMessage,
    required this.tileBuilder,
  });

  final String storageKey;
  final AsyncValue<List<Spot>> async;
  final Future<void> Function() onRefresh;
  final _EmptyTab empty;
  final String errorMessage;
  final Widget Function(Spot spot) tileBuilder;

  @override
  Widget build(BuildContext context) {
    final spots = async.valueOrNull ?? const <Spot>[];
    final Widget sliver;
    if (async.isLoading && spots.isEmpty) {
      sliver = const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (async.hasError && spots.isEmpty) {
      sliver = SliverFillRemaining(
        hasScrollBody: false,
        child: _ErrorTab(message: errorMessage, onRetry: onRefresh),
      );
    } else if (spots.isEmpty) {
      sliver = SliverFillRemaining(hasScrollBody: false, child: empty);
    } else {
      sliver = SliverGrid.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: 236,
        ),
        itemCount: spots.length,
        itemBuilder: (_, i) => tileBuilder(spots[i]),
      );
    }
    return _TabBody(storageKey: storageKey, onRefresh: onRefresh, sliver: sliver);
  }
}

class _MySpotsTab extends ConsumerWidget {
  const _MySpotsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SpotsTabContent(
      storageKey: 'my-spots',
      async: ref.watch(mySpotsProvider),
      onRefresh: () async => ref.invalidate(mySpotsProvider),
      errorMessage: 'No se pudieron cargar tus spots',
      empty: const _EmptyTab(
        icon: Icons.add_location_alt_outlined,
        title: 'Aún no tienes spots',
        subtitle: 'Toca el + amarillo para agregar el primero.',
      ),
      tileBuilder: (s) => _SpotTile(spot: s, showStatus: true),
    );
  }
}

class _FavoritesTab extends ConsumerWidget {
  const _FavoritesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SpotsTabContent(
      storageKey: 'favorites',
      async: ref.watch(myFavoriteSpotsProvider),
      onRefresh: () async => ref.invalidate(myFavoriteSpotsProvider),
      errorMessage: 'No se pudieron cargar tus favoritos',
      empty: const _EmptyTab(
        icon: Icons.bookmark_border,
        title: 'Aún no tienes favoritos',
        subtitle: 'Toca el ícono de guardar en un spot para tenerlo aquí.',
      ),
      tileBuilder: (s) => _SpotTile(spot: s, showSave: true),
    );
  }
}

class _SpotTile extends ConsumerWidget {
  const _SpotTile({
    required this.spot,
    this.showStatus = false,
    this.showSave = false,
  });

  final Spot spot;
  final bool showStatus;
  final bool showSave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photo = spot.thumbUrl;
    final (Color statusColor, Color statusText) = switch (spot.status) {
      SpotStatus.approved => (AppColors.moss, AppColors.asphalt),
      SpotStatus.pending => (AppColors.tape, AppColors.asphalt),
      SpotStatus.rejected => (AppColors.danger, AppColors.asphalt),
    };

    return Material(
      color: AppColors.concrete,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: const BorderSide(color: AppColors.line),
      ),
      child: InkWell(
        onTap: () => context.push(AppRoutes.spotDetail(spot.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 148,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (photo == null)
                    const SpotPhotoPlaceholder(compact: true)
                  else
                    CachedNetworkImage(
                      imageUrl: photo,
                      fit: BoxFit.cover,
                      placeholder: (_, _) =>
                          const ColoredBox(color: AppColors.concreteHigh),
                      errorWidget: (_, _, _) =>
                          const SpotPhotoPlaceholder(compact: true),
                    ),
                  if (showStatus)
                    Positioned(
                      left: 8,
                      top: 10,
                      child: TapeLabel(
                        spot.status.label,
                        fontSize: 10,
                        color: statusColor,
                        textColor: statusText,
                      ),
                    ),
                  if (showSave)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: _UnsaveButton(spot: spot),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spot.name.toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.display(18),
                    ),
                    const Spacer(),
                    Text(
                      '${spot.type.label} · ${spot.difficulty.label}'
                          .toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.label(10, color: AppColors.boneMuted),
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

class _UnsaveButton extends ConsumerWidget {
  const _UnsaveButton({required this.spot});
  final Spot spot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Tooltip(
      message: 'Quitar de favoritos',
      child: Material(
        color: AppColors.tape,
        borderRadius: BorderRadius.circular(3),
        child: InkWell(
          borderRadius: BorderRadius.circular(3),
          onTap: () async {
            final messenger = ScaffoldMessenger.of(context);
            final ok = await ref
                .read(socialViewModelProvider.notifier)
                .toggleFavorite(spotId: spot.id, currentlyFavorited: true);
            if (ok) return;
            messenger
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(
                  content: Text('No se pudo actualizar. Inténtalo de nuevo.'),
                ),
              );
          },
          child: const SizedBox(
            width: 36,
            height: 36,
            child: Icon(Icons.bookmark, size: 20, color: AppColors.asphalt),
          ),
        ),
      ),
    );
  }
}

class _ReviewsTab extends ConsumerWidget {
  const _ReviewsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myRatingsProvider);
    final ratings = async.valueOrNull ?? const <SpotRating>[];
    Future<void> refresh() async => ref.invalidate(myRatingsProvider);

    final Widget sliver;
    if (async.isLoading && ratings.isEmpty) {
      sliver = const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (async.hasError && ratings.isEmpty) {
      sliver = SliverFillRemaining(
        hasScrollBody: false,
        child: _ErrorTab(
          message: 'No se pudieron cargar tus reseñas',
          onRetry: refresh,
        ),
      );
    } else if (ratings.isEmpty) {
      sliver = const SliverFillRemaining(
        hasScrollBody: false,
        child: _EmptyTab(
          icon: Icons.rate_review_outlined,
          title: 'Aún no tienes reseñas',
          subtitle: 'Cuando califiques un spot aparecerá aquí.',
        ),
      );
    } else {
      sliver = SliverList.separated(
        itemCount: ratings.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _MyReviewCard(rating: ratings[i]),
      );
    }
    return _TabBody(storageKey: 'reviews', onRefresh: refresh, sliver: sliver);
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
    final date = DateFormat('d MMM y', 'es').format(rating.createdAt);

    return Material(
      color: AppColors.concrete,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: rejected ? AppColors.danger : AppColors.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () => context.push(AppRoutes.spotDetail(rating.spotId)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      (rating.spotName ?? 'Spot').toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.display(20),
                    ),
                  ),
                  if (pending || rejected) ...[
                    const SizedBox(width: 8),
                    TapeLabel(
                      rejected ? 'Rechazada' : 'En revisión',
                      fontSize: 10,
                      color: rejected ? AppColors.danger : AppColors.bone,
                      angleDegrees: 2,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  for (var i = 0; i < 5; i++)
                    Icon(
                      i < rating.rating ? Icons.star : Icons.star_border,
                      size: 15,
                      color: i < rating.rating
                          ? AppColors.tape
                          : AppColors.lineStrong,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    '${date.toUpperCase()}${rating.edited ? ' · EDITADA' : ''}',
                    style: AppTheme.label(10, color: AppColors.boneMuted),
                  ),
                ],
              ),
              if (rating.comment != null &&
                  rating.comment!.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  rating.comment!.trim(),
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                ),
              ],
              if (pending || rejected) ...[
                const SizedBox(height: 10),
                Text(
                  rejected
                      ? 'El equipo de moderación rechazó tu reseña.'
                      : 'La estamos revisando. Cuando se apruebe la verán todos.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: rejected
                        ? AppColors.danger
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: AppColors.boneMuted),
          const SizedBox(height: 12),
          Text(
            title.toUpperCase(),
            textAlign: TextAlign.center,
            style: AppTheme.display(24),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.boneMuted,
                ),
          ),
        ],
      ),
    );
  }
}

class _ErrorTab extends StatelessWidget {
  const _ErrorTab({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 40, color: AppColors.danger),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('REINTENTAR')),
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
          const Icon(Icons.error_outline, size: 40, color: AppColors.danger),
          const SizedBox(height: 12),
          const Text('No se pudo cargar tu perfil'),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('REINTENTAR')),
        ],
      ),
    );
  }
}
