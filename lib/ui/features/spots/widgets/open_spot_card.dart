import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:spot_for_fun/domain/models/spot.dart';
import 'package:spot_for_fun/ui/core/router/app_router.dart';
import 'package:spot_for_fun/ui/features/profile/widgets/profile_mock_data.dart';
import 'package:spot_for_fun/ui/features/spots/views/detail/spot_detail_screen.dart';

/// Wraps [SpotListCard] in an [OpenContainer] so the card expands into
/// the spot detail with a Material 3 fade-through container transform.
///
/// Falls back to a plain push when the platform reports reduced motion
/// (MediaQuery.disableAnimations), so the experience stays accessible.
class OpenSpotCard extends StatelessWidget {
  const OpenSpotCard({
    super.key,
    required this.spot,
    this.bookmarked = false,
    this.onBookmarkToggle,
  });

  final Spot spot;
  final bool bookmarked;
  final ValueChanged<bool>? onBookmarkToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reducedMotion = MediaQuery.of(context).disableAnimations;

    void openDetail() {
      GoRouter.of(context).push(AppRoutes.spotDetail(spot.id));
    }

    if (reducedMotion) {
      return SpotListCard(
        spot: spot,
        onTap: openDetail,
        bookmarked: bookmarked,
        onBookmarkToggle: onBookmarkToggle,
      );
    }

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
      closedBuilder: (context, action) => SpotListCard(
        spot: spot,
        onTap: action,
        bookmarked: bookmarked,
        onBookmarkToggle: onBookmarkToggle,
      ),
    );
  }
}
