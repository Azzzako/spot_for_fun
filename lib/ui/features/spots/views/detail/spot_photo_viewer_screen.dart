import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:spot_for_fun/domain/enums.dart';
import 'package:spot_for_fun/domain/models/spot.dart';
import 'package:spot_for_fun/ui/shared/constants/default_spot_images.dart';

class SpotPhotoViewerScreen extends StatefulWidget {
  const SpotPhotoViewerScreen({
    super.key,
    required this.photos,
    required this.initialIndex,
    required this.spotId,
  });

  final List<SpotPhoto> photos;
  final int initialIndex;
  final String spotId;

  @override
  State<SpotPhotoViewerScreen> createState() => _SpotPhotoViewerScreenState();
}

class _SpotPhotoViewerScreenState extends State<SpotPhotoViewerScreen> {
  late final PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasMultiple = widget.photos.length > 1;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Stack(
        children: [
          // Photo pager. Tap on the empty sides (where the gesture
          // detector wraps the InteractiveViewer) closes the viewer.
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.photos.length,
                onPageChanged: (i) => setState(() => _currentIndex = i),
                itemBuilder: (_, i) {
                  final photo = widget.photos[i];
                  return _PhotoPage(
                    photo: photo,
                    spotId: widget.spotId,
                    index: i,
                    heroTag: i == widget.initialIndex
                        ? 'spot-photo-${widget.spotId}-${widget.initialIndex}'
                        : null,
                  );
                },
              ),
            ),
          ),

          // Top gradient backdrop (decorative, no input).
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 120,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      scheme.surface.withValues(alpha: 0.85),
                      scheme.surface.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom gradient backdrop (decorative, no input).
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 160,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      scheme.surface.withValues(alpha: 0.7),
                      scheme.surface.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Header: close button + counter.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    _HeaderButton(
                      icon: Icons.close_rounded,
                      tooltip: 'Cerrar',
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    if (hasMultiple)
                      _Counter(
                        current: _currentIndex + 1,
                        total: widget.photos.length,
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom: dots + hint.
          if (hasMultiple)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _DotIndicator(
                        count: widget.photos.length,
                        current: _currentIndex,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Pellizca para hacer zoom',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PhotoPage extends StatelessWidget {
  const _PhotoPage({
    required this.photo,
    required this.spotId,
    required this.index,
    this.heroTag,
  });

  final SpotPhoto photo;
  final String spotId;
  final int index;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pending = photo.photoStatus == PhotoStatus.pending;

    final image = CachedNetworkImage(
      imageUrl: photo.url,
      fit: BoxFit.contain,
      placeholder: (_, _) => const Center(
        child: CircularProgressIndicator(strokeWidth: 2.4),
      ),
      errorWidget: (_, _, _) => Image.asset(
        defaultSpotImageFor('$spotId,$index'),
        fit: BoxFit.contain,
      ),
    );

    final heroWrapped = heroTag != null
        ? Hero(tag: heroTag!, child: image)
        : image;

    // InteractiveViewer constrained to horizontal axis so the parent
    // PageView can keep panning between photos while the user can
    // still pinch-zoom and pan inside the current photo.
    return InteractiveViewer(
      minScale: 1,
      maxScale: 4,
      panAxis: PanAxis.aligned,
      panEnabled: true,
      scaleEnabled: true,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: scheme.surface),
          Center(child: heroWrapped),
          if (pending)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 96),
                child: _PendingBadge(),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Material(
            color: scheme.surface.withValues(alpha: 0.55),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(icon, size: 22, color: scheme.onSurface),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: scheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            '$current / $total',
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );
  }
}

class _DotIndicator extends StatelessWidget {
  const _DotIndicator({required this.count, required this.current});
  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == current;
        final dot = AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          width: isActive ? 22 : 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: isActive
                ? scheme.primary
                : scheme.onSurface.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(3),
          ),
        );
        if (isActive) {
          return dot.animate().scale(
                begin: const Offset(0.85, 0.85),
                end: const Offset(1, 1),
                duration: 260.ms,
                curve: Curves.easeOutBack,
              );
        }
        return dot;
      }),
    );
  }
}

class _PendingBadge extends StatelessWidget {
  const _PendingBadge();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.hourglass_top, size: 14, color: scheme.onTertiaryContainer),
          const SizedBox(width: 6),
          Text(
            'En revisión',
            style: TextStyle(
              color: scheme.onTertiaryContainer,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
