import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spot_for_fun/data/repositories/admin_moderation_repository.dart';
import 'package:spot_for_fun/domain/models/spot.dart';
import 'package:spot_for_fun/domain/models/spot_rating.dart';
import 'package:spot_for_fun/ui/features/admin/view_models/admin_moderation_view_model.dart';
import 'package:spot_for_fun/ui/shared/widgets/user_avatar.dart';

class AdminPendingScreen extends ConsumerWidget {
  const AdminPendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminModeratorProvider);
    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Moderación')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Acceso restringido. Esta sección es solo para administradores.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Moderación'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.rate_review_outlined), text: 'Reseñas'),
              Tab(icon: Icon(Icons.image_outlined), text: 'Fotos'),
            ],
          ),
        ),
        body: Column(
          children: [
            const _ErrorBanner(),
            Expanded(
              child: TabBarView(
                children: const [
                  _RatingsTab(),
                  _PhotosTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends ConsumerWidget {
  const _ErrorBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final error = ref.watch(
      adminModerationViewModelProvider.select((s) => s.errorMessage),
    );
    if (error == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: scheme.errorContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(
        error,
        style: TextStyle(color: scheme.onErrorContainer),
      ),
    );
  }
}

class _RatingsTab extends ConsumerWidget {
  const _RatingsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pendingRatingsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorRetry(
        message: 'No pudimos cargar las reseñas pendientes.',
        onRetry: () => ref.invalidate(pendingRatingsProvider),
      ),
      data: (ratings) {
        if (ratings.isEmpty) return const _EmptyState('Sin reseñas pendientes.');
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(pendingRatingsProvider),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: ratings.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _RatingCard(rating: ratings[i]),
          ),
        );
      },
    );
  }
}

class _RatingCard extends ConsumerWidget {
  const _RatingCard({required this.rating});
  final SpotRating rating;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final state = ref.watch(adminModerationViewModelProvider);
    final busy = state.isBusy(rating.id);
    final author = rating.authorDisplayName;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(
                  url: rating.userAvatarUrl,
                  fallbackSeed: author,
                  size: 36,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    rating.spotName ?? 'Spot',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _StarRow(rating: rating.rating),
              ],
            ),
            if (rating.comment != null && rating.comment!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(rating.comment!, style: theme.textTheme.bodyMedium),
            ],
            const SizedBox(height: 12),
            Text(
              author,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: busy
                        ? null
                        : () => ref
                            .read(adminModerationViewModelProvider.notifier)
                            .moderateRating(
                              rating.id,
                              ModerationAction.reject,
                            ),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Rechazar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: scheme.error,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: busy
                        ? null
                        : () => ref
                            .read(adminModerationViewModelProvider.notifier)
                            .moderateRating(
                              rating.id,
                              ModerationAction.approve,
                            ),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Aprobar'),
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

class _StarRow extends StatelessWidget {
  const _StarRow({required this.rating});
  final int rating;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < rating;
        return Icon(
          filled ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 18,
          color: filled ? scheme.primary : scheme.onSurface.withValues(alpha: 0.3),
        );
      }),
    );
  }
}

class _PhotosTab extends ConsumerWidget {
  const _PhotosTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pendingPhotosProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorRetry(
        message: 'No pudimos cargar las fotos pendientes.',
        onRetry: () => ref.invalidate(pendingPhotosProvider),
      ),
      data: (photos) {
        if (photos.isEmpty) return const _EmptyState('Sin fotos pendientes.');
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(pendingPhotosProvider),
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.78,
            ),
            itemCount: photos.length,
            itemBuilder: (_, i) => _PhotoCard(photo: photos[i]),
          ),
        );
      },
    );
  }
}

class _PhotoCard extends ConsumerWidget {
  const _PhotoCard({required this.photo});
  final SpotPhoto photo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final state = ref.watch(adminModerationViewModelProvider);
    final busy = state.isBusy(photo.id);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: CachedNetworkImage(
              imageUrl: photo.url,
              fit: BoxFit.cover,
              placeholder: (_, _) => Container(color: Colors.black12),
              errorWidget: (_, _, _) => Container(
                color: scheme.surfaceContainerHighest,
                child: Icon(
                  Icons.broken_image_outlined,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Foto',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: IconButton(
                        onPressed: busy
                            ? null
                            : () => ref
                                .read(adminModerationViewModelProvider.notifier)
                                .moderatePhoto(
                                  photo.id,
                                  ModerationAction.reject,
                                ),
                        icon: Icon(Icons.close_rounded,
                            color: scheme.error),
                        style: IconButton.styleFrom(
                          backgroundColor: scheme.surfaceContainerHighest,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: IconButton(
                        onPressed: busy
                            ? null
                            : () => ref
                                .read(adminModerationViewModelProvider.notifier)
                                .moderatePhoto(
                                  photo.id,
                                  ModerationAction.approve,
                                ),
                        icon: Icon(Icons.check_rounded,
                            color: scheme.onPrimary),
                        style: IconButton.styleFrom(
                          backgroundColor: scheme.primary,
                          foregroundColor: scheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 56,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
