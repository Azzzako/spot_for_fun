import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Round avatar with a colored initial-letter fallback. Used in
/// profile headers, spot cards ("Publicado por @…") and any other
/// spot where we want to show who did the thing.
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
    final theme = Theme.of(context);
    final bg = _backgroundFor(fallbackSeed, theme);
    final initial = _initialFor(fallbackSeed);

    final bc = borderColor;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
        border: bc == null ? null : Border.all(color: bc, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: url == null || url!.isEmpty
          ? Text(
              initial,
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w800,
                fontSize: size * 0.42,
                letterSpacing: 0.5,
              ),
            )
          : CachedNetworkImage(
              imageUrl: url!,
              fit: BoxFit.cover,
              placeholder: (_, _) => Container(color: bg),
              errorWidget: (_, _, _) => Container(
                color: bg,
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: size * 0.42,
                  ),
                ),
              ),
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

  Color _backgroundFor(String seed, ThemeData theme) {
    final palette = <Color>[
      const Color(0xFF4F46E5),
      const Color(0xFF0EA5E9),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFFEC4899),
      const Color(0xFF8B5CF6),
      const Color(0xFF14B8A6),
    ];
    if (seed.isEmpty) return theme.colorScheme.primary;
    final hash = seed.codeUnits.fold<int>(0, (acc, c) => acc + c);
    return palette[hash % palette.length];
  }
}
