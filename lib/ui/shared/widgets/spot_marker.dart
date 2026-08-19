import 'package:flutter/material.dart';

import 'package:spot_for_fun/domain/enums.dart';
import 'package:spot_for_fun/domain/models/spot.dart';

enum SpotKind { street, park, bowl, plaza, diy, ledge, skateshop }

SpotKind classifySpotKind(String type) {
  return switch (type) {
    'park' => SpotKind.park,
    'bowl' => SpotKind.bowl,
    'plaza' => SpotKind.plaza,
    'diy' => SpotKind.diy,
    'skateshop' => SpotKind.skateshop,
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
    SpotKind.street => Icons.location_on,
    SpotKind.park => Icons.skateboarding,
    SpotKind.bowl => Icons.stadium,
    SpotKind.plaza => Icons.square,
    SpotKind.diy => Icons.handyman,
    SpotKind.ledge => Icons.view_week,
    SpotKind.skateshop => Icons.storefront,
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
  };
}

Widget spotMarkerWidget({
  required Color color,
  required IconData icon,
}) {
  return Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 3),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Icon(icon, color: Colors.white, size: 22),
  );
}

MarkerKind? markerKindForSpotKind(SpotKind kind) {
  return switch (kind) {
    SpotKind.street => MarkerKind.street,
    SpotKind.park => MarkerKind.park,
    SpotKind.bowl => MarkerKind.bowl,
    SpotKind.plaza => null,
    SpotKind.diy => null,
    SpotKind.ledge => MarkerKind.ledge,
    SpotKind.skateshop => MarkerKind.skateshop,
  };
}

SpotKind spotKindForMarkerKind(MarkerKind kind) {
  return switch (kind) {
    MarkerKind.street => SpotKind.street,
    MarkerKind.park => SpotKind.park,
    MarkerKind.bowl => SpotKind.bowl,
    MarkerKind.ledge => SpotKind.ledge,
    MarkerKind.skateshop => SpotKind.skateshop,
  };
}

IconData spotIconForMarkerKind(MarkerKind kind) =>
    spotIconFor(spotKindForMarkerKind(kind));
