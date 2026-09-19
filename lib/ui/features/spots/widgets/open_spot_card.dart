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
class OpenSpotCard extends ConsumerWidget {
  const OpenSpotCard({
    super.key,
    required this.spot,
    this.bookmarked = false,
    this.liked = false,
    this.onBookmarkToggle,
    this.onLikeToggle,
  });

  final Spot spot;
  final bool bookmarked;
  final bool liked;
  final ValueChanged<bool>? onBookmarkToggle;
  final ValueChanged<bool>? onLikeToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final reducedMotion = MediaQuery.of(context).disableAnimations;

    void openDetail() {
      GoRouter.of(context).push(AppRoutes.spotDetail(spot.id));
    }

    final card = SpotListCard(
      spot: spot,
      onTap: reducedMotion ? openDetail : null,
      liked: liked,
      bookmarked: bookmarked,
      onLikeToggle: onLikeToggle,
      onBookmarkToggle: onBookmarkToggle,
    );

    if (reducedMotion) return card;

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
      closedBuilder: (context, action) {
        // For the open-container path the card's onTap is wired to the
        // OpenContainer action. The like/favorite handlers still need
        // access to the VM, so route them through the outer widget.
        return SpotListCard(
          spot: spot,
          onTap: action,
          liked: liked,
          bookmarked: bookmarked,
          onLikeToggle: (newVal) {
            ref
                .read(socialViewModelProvider.notifier)
                .toggleLike(spotId: spot.id, currentlyLiked: liked);
            onLikeToggle?.call(newVal);
          },
          onBookmarkToggle: (newVal) {
            ref
                .read(socialViewModelProvider.notifier)
                .toggleFavorite(
                  spotId: spot.id,
                  currentlyFavorited: bookmarked,
                );
            onBookmarkToggle?.call(newVal);
          },
        );
      },
    );
  }
}
