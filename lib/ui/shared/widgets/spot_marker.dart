import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:spot_for_fun/domain/enums.dart';
import 'package:spot_for_fun/domain/models/spot.dart';

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
                style: GoogleFonts.poppins(
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF121212),
                    height: 1.1,
                    letterSpacing: 0.1,
                  ),
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

    // Layered stack so the photo fully covers the inner circle:
    //   outer  = kind-colored ring (4 px)
    //   middle = white border (2 px)
    //   inner  = photo (or icon fallback) clipped to a circle
    // The colored layer is never used as a background, so it can't
    // bleed through gaps while the photo loads.
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        padding: const EdgeInsets.all(2),
        clipBehavior: Clip.antiAlias,
        alignment: Alignment.center,
        child: hasPhoto
            ? CachedNetworkImage(
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
              )
            : Icon(
                icon,
                color: Colors.white,
                size: size * 0.5,
              ),
      ),
    );
  }
}
