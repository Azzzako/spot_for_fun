import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:spot_for_fun/domain/enums.dart';
import 'package:spot_for_fun/domain/models/spot.dart';
import 'package:spot_for_fun/ui/core/theme/app_colors.dart';
import 'package:spot_for_fun/ui/shared/utils/compass.dart';

enum SpotKind {
  street,
  park,
  bowl,
  plaza,
  diy,
  ledge,
  skateshop,
  skatepark,
  gap,
}

SpotKind classifySpotKind(String type) {
  return switch (type) {
    'park' => SpotKind.park,
    'bowl' => SpotKind.bowl,
    'plaza' => SpotKind.plaza,
    'diy' => SpotKind.diy,
    'skateshop' => SpotKind.skateshop,
    'skatepark' => SpotKind.skatepark,
    'gap' => SpotKind.gap,
    _ => SpotKind.street,
  };
}

SpotKind resolveSpotKind(Spot spot) {
  final mk = spot.markerKind;
  if (mk != null) {
    return switch (mk) {
      MarkerKind.street => SpotKind.street,
      MarkerKind.park => SpotKind.park,
      MarkerKind.bowl => SpotKind.bowl,
      MarkerKind.ledge => SpotKind.ledge,
      MarkerKind.skateshop => SpotKind.skateshop,
    };
  }
  return classifySpotKind(spot.type.dbValue);
}

IconData spotIconFor(SpotKind kind) {
  return switch (kind) {
    SpotKind.street => Icons.stairs,
    SpotKind.park => Icons.skateboarding,
    SpotKind.bowl => Icons.stadium,
    SpotKind.plaza => Icons.square,
    SpotKind.diy => Icons.handyman,
    SpotKind.ledge => Icons.view_week,
    SpotKind.skateshop => Icons.storefront,
    SpotKind.skatepark => Icons.park,
    SpotKind.gap => Icons.swap_horiz,
  };
}

Color spotColorFor(SpotKind kind, Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  return switch (kind) {
    SpotKind.street => isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
    SpotKind.park => isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED),
    SpotKind.bowl => isDark ? const Color(0xFFF472B6) : const Color(0xFFDB2777),
    SpotKind.plaza => isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
    SpotKind.diy => isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
    SpotKind.ledge => isDark ? const Color(0xFF22D3EE) : const Color(0xFF0E7490),
    SpotKind.skateshop => isDark ? const Color(0xFF34D399) : const Color(0xFF047857),
    SpotKind.skatepark => isDark ? const Color(0xFFA3E635) : const Color(0xFF65A30D),
    SpotKind.gap => isDark ? const Color(0xFFFB923C) : const Color(0xFFC2410C),
  };
}

const double kSpotMarkerWidth = 110.0;
const double kSpotMarkerHeight = 64.0;
const double kSpotMarkerPinSize = 40.0;
const double kSpotMarkerLabelMaxWidth = 100.0;

/// Marker with circular pin (first spot photo as thumbnail when
/// available, kind-colored icon fallback otherwise) plus an optional
/// label below. Renders label only when [showLabel] is true (caller
/// wires the zoom threshold).
Widget spotMarkerWidget({
  required SpotKind kind,
  required Brightness brightness,
  String? photoUrl,
  String? label,
  bool showLabel = false,
}) {
  final color = spotColorFor(kind, brightness);
  final icon = spotIconFor(kind);

  return SizedBox(
    width: kSpotMarkerWidth,
    height: kSpotMarkerHeight,
    child: Stack(
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      children: [
        if (showLabel && label != null && label.isNotEmpty)
          Positioned(
            top: kSpotMarkerPinSize + 4,
            child: Container(
              constraints: const BoxConstraints(maxWidth: kSpotMarkerLabelMaxWidth),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF121212),
                  height: 1.1,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ),
        Positioned(
          top: 0,
          child: _CircularPin(
            color: color,
            icon: icon,
            photoUrl: photoUrl,
            size: kSpotMarkerPinSize,
          ),
        ),
      ],
    ),
  );
}

/// Compact pin (no label) for use in lists / pickers. Circular, photo
/// when available, colored icon fallback otherwise.
Widget spotMarkerPin({
  required SpotKind kind,
  required Brightness brightness,
  String? photoUrl,
  double size = 32,
}) {
  final color = spotColorFor(kind, brightness);
  return _CircularPin(
    color: color,
    icon: spotIconFor(kind),
    photoUrl: photoUrl,
    size: size,
  );
}

class _CircularPin extends StatelessWidget {
  const _CircularPin({
    required this.color,
    required this.icon,
    required this.photoUrl,
    required this.size,
  });

  final Color color;
  final IconData icon;
  final String? photoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    final theme = Theme.of(context);

    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: hasPhoto
            ? SizedBox.expand(
                child: CachedNetworkImage(
                  imageUrl: photoUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => ColoredBox(
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                  errorWidget: (_, _, _) => Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    alignment: Alignment.center,
                    child: Icon(icon, color: color, size: size * 0.5),
                  ),
                ),
              )
            : Container(
                color: color,
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: size * 0.5,
                ),
              ),
      ),
    );
  }
}

/// Urban map marker: a yellow rhombus, like a road-works sign. The
/// selected spot gets a bigger one.
class SpotRhombusMarker extends StatelessWidget {
  const SpotRhombusMarker({super.key, required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final side = selected ? 26.0 : 16.0;
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutBack,
        width: side,
        height: side,
        transform: Matrix4.rotationZ(math.pi / 4),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.tape,
          border: Border.all(
            color: AppColors.asphalt,
            width: selected ? 4 : 3,
          ),
          boxShadow: const [
            BoxShadow(color: AppColors.tape, spreadRadius: 1.5),
          ],
        ),
      ),
    );
  }
}

/// The user's position: bone dot ringed in yellow, with a translucent
/// yellow beam showing which way the phone points (like Google Maps).
/// The compass only runs while [showHeading] is true; phones without a
/// compass sensor just get the dot.
class UserLocationDot extends StatefulWidget {
  const UserLocationDot({super.key, this.showHeading = false});

  static const double size = 84;

  final bool showHeading;

  @override
  State<UserLocationDot> createState() => _UserLocationDotState();
}

class _UserLocationDotState extends State<UserLocationDot> {
  StreamSubscription<double>? _compass;

  /// Smoothed heading in degrees (0 = north), null until the first fix.
  double? _heading;

  @override
  void initState() {
    super.initState();
    _syncCompass();
  }

  @override
  void didUpdateWidget(UserLocationDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showHeading != widget.showHeading) _syncCompass();
  }

  @override
  void dispose() {
    _compass?.cancel();
    super.dispose();
  }

  void _syncCompass() {
    if (!widget.showHeading) {
      _compass?.cancel();
      _compass = null;
      return;
    }
    // A phone without a compass (or a platform without the channel)
    // just keeps showing the dot.
    _compass ??= Compass.headings.listen(_onCompass, onError: (Object _) {});
  }

  void _onCompass(double raw) {
    final current = _heading;
    if (current == null) {
      setState(() => _heading = raw % 360);
      return;
    }
    // Shortest way round (350° → 10° is +20°, not −340°), then ease a
    // quarter of the way there so the beam doesn't jitter.
    final delta = ((raw - current + 540) % 360) - 180;
    if (delta.abs() < 1.5) return;
    setState(() => _heading = (current + delta * 0.25) % 360);
  }

  @override
  Widget build(BuildContext context) {
    final heading = _heading;
    return SizedBox(
      width: UserLocationDot.size,
      height: UserLocationDot.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.showHeading && heading != null)
            Transform.rotate(
              angle: heading * math.pi / 180,
              child: const CustomPaint(
                size: Size.square(UserLocationDot.size),
                painter: _HeadingBeamPainter(),
              ),
            ),
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.bone,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.asphalt, width: 3),
              boxShadow: const [
                BoxShadow(color: AppColors.tape, spreadRadius: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A 70° wedge pointing up (north before rotation).
class _HeadingBeamPainter extends CustomPainter {
  const _HeadingBeamPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    const sweep = 70 * math.pi / 180;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(rect, -math.pi / 2 - sweep / 2, sweep, false)
      ..close();
    canvas.drawPath(
      path,
      Paint()..color = AppColors.tape.withValues(alpha: 0.32),
    );
  }

  @override
  bool shouldRepaint(_HeadingBeamPainter oldDelegate) => false;
}
