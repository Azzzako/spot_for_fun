import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:spot_for_fun/ui/core/theme/app_colors.dart';
import 'package:spot_for_fun/ui/core/theme/app_theme.dart';

/// A strip of tape: uppercase label on a solid block, slightly rotated.
/// Used for spot type / level tags and status stamps.
class TapeLabel extends StatelessWidget {
  const TapeLabel(
    this.text, {
    super.key,
    this.color = AppColors.tape,
    this.textColor = AppColors.asphalt,
    this.angleDegrees = -2.5,
    this.fontSize = 12,
  });

  final String text;
  final Color color;
  final Color textColor;
  final double angleDegrees;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angleDegrees * math.pi / 180,
      child: Container(
        color: color,
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        child: Text(
          text.toUpperCase(),
          style: AppTheme.label(fontSize, color: textColor),
        ),
      ),
    );
  }
}
