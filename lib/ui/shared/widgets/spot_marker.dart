import 'package:flutter/material.dart';

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

enum SpotMarkerShape { circle, roundedSquare, stadium }

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

SpotMarkerShape shapeForSpotKind(SpotKind kind) {
  return switch (kind) {
    SpotKind.street => SpotMarkerShape.circle,
    SpotKind.park => SpotMarkerShape.roundedSquare,
    SpotKind.bowl => SpotMarkerShape.circle,
    SpotKind.plaza => SpotMarkerShape.roundedSquare,
    SpotKind.diy => SpotMarkerShape.circle,
    SpotKind.ledge => SpotMarkerShape.stadium,
    SpotKind.skateshop => SpotMarkerShape.roundedSquare,
    SpotKind.skatepark => SpotMarkerShape.roundedSquare,
    SpotKind.gap => SpotMarkerShape.stadium,
  };
}

IconData spotIconFor(SpotKind kind) {
  return switch (kind) {
    SpotKind.street => Icons.location_on,
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

BorderRadius _radiusFor(SpotMarkerShape shape) {
  return switch (shape) {
    SpotMarkerShape.circle => BorderRadius.circular(16),
    SpotMarkerShape.roundedSquare => BorderRadius.circular(6),
    SpotMarkerShape.stadium => BorderRadius.circular(16),
  };
}

Widget spotMarkerWidget({
  required SpotKind kind,
  required Brightness brightness,
}) {
  return Container(
    width: 32,
    height: 32,
    decoration: BoxDecoration(
      color: spotColorFor(kind, brightness),
      borderRadius: _radiusFor(shapeForSpotKind(kind)),
      border: Border.all(color: Colors.white, width: 2),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Icon(
      spotIconFor(kind),
      color: Colors.white,
      size: kind == SpotKind.ledge ? 18 : 14,
    ),
  );
}
