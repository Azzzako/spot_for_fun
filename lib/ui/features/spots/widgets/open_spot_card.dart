import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:spot_for_fun/domain/models/spot.dart';
import 'package:spot_for_fun/ui/core/router/app_router.dart';
import 'package:spot_for_fun/ui/features/profile/widgets/profile_mock_data.dart';
import 'package:spot_for_fun/ui/features/social/view_models/social_view_model.dart';
import 'package:spot_for_fun/ui/features/spots/views/detail/spot_detail_screen.dart';

/// Wraps [SpotListCard] in an [OpenContainer] so the card expands into
/// the spot detail with a Material 3 fade-through container transform.
///
/// Falls back to a plain push when the platform reports reduced motion
/// (MediaQuery.disableAnimations), so the experience stays accessible.
///
/// Favorite state comes from [Spot.isFavorited] and the toggle goes
/// through [SocialViewModel].
class OpenSpotCard extends ConsumerWidget {
  const OpenSpotCard({
    super.key,
    required this.spot,
    this.showStatusBadge = false,
  });

  final Spot spot;
  final bool showStatusBadge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final reducedMotion = MediaQuery.of(context).disableAnimations;
    final social = ref.read(socialViewModelProvider.notifier);

    void openDetail() {
      GoRouter.of(context).push(AppRoutes.spotDetail(spot.id));
    }

    Future<void> report(Future<bool> result) async {
      final messenger = ScaffoldMessenger.of(context);
      if (await result) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('No se pudo actualizar. Inténtalo de nuevo.'),
          ),
        );
    }

    Widget buildCard(VoidCallback? onTap) => SpotListCard(
          spot: spot,
          onTap: onTap,
          bookmarked: spot.isFavorited,
          showLike: false,
          showStatusBadge: showStatusBadge,
          onBookmarkToggle: (_) => report(
            social.toggleFavorite(
              spotId: spot.id,
              currentlyFavorited: spot.isFavorited,
            ),
          ),
        );

    if (reducedMotion) return buildCard(openDetail);

    return OpenContainer<void>(
      transitionType: ContainerTransitionType.fadeThrough,
      transitionDuration: const Duration(milliseconds: 350),
      openColor: theme.colorScheme.surface,
      closedColor: theme.colorScheme.surfaceContainer,
      middleColor: theme.colorScheme.surface,
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      closedElevation: 0,
      openElevation: 0,
      openBuilder: (context, _) => SpotDetailScreen(spotId: spot.id),
      closedBuilder: (context, action) => buildCard(action),
    );
  }
}
