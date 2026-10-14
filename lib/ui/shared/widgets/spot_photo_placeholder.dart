import 'package:flutter/material.dart';

import 'package:spot_for_fun/ui/core/theme/app_colors.dart';
import 'package:spot_for_fun/ui/core/theme/app_theme.dart';

/// Shown where a spot has no photo (or a photo fails to load), instead
/// of borrowing an unrelated sample image.
class SpotPhotoPlaceholder extends StatelessWidget {
  const SpotPhotoPlaceholder({super.key, this.compact = false});

  /// Icon only, for thumbnails.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.concreteHigh,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.no_photography_outlined,
              size: compact ? 22 : 40,
              color: AppColors.boneMuted,
            ),
            if (!compact) ...[
              const SizedBox(height: 8),
              Text(
                'SIN FOTOS',
                style: AppTheme.label(12, color: AppColors.boneMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
