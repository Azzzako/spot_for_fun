import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:spot_for_fun/ui/core/theme/app_colors.dart';
import 'package:spot_for_fun/ui/core/theme/app_theme.dart';

/// Square avatar (urban style) with a yellow initial on concrete as the
/// fallback. Used in the profile header, reviews and anywhere we show
/// who did something.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.url,
    required this.fallbackSeed,
    this.size = 40,
    this.borderColor,
  });

  final String? url;
  final String fallbackSeed;
  final double size;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final initial = Text(
      _initialFor(fallbackSeed),
      style: AppTheme.display(size * 0.5, color: AppColors.tape),
    );
    final bc = borderColor;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.concreteHigh,
        borderRadius: BorderRadius.circular(size >= 64 ? 4 : 3),
        border: bc == null ? null : Border.all(color: bc, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: url == null || url!.isEmpty
          ? initial
          : CachedNetworkImage(
              imageUrl: url!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              placeholder: (_, _) =>
                  const ColoredBox(color: AppColors.concreteHigh),
              errorWidget: (_, _, _) => Center(child: initial),
            ),
    );
  }

  String _initialFor(String seed) {
    final s = seed.trim();
    if (s.isEmpty) return '?';
    // Use the first alphanumeric char so "@asael" -> "A".
    for (final ch in s.split('')) {
      if (RegExp(r'[A-Za-z0-9]').hasMatch(ch)) {
        return ch.toUpperCase();
      }
    }
    return s.characters.first.toUpperCase();
  }
}
