import 'package:flutter/material.dart';

import 'package:spot_for_fun/ui/core/theme/app_colors.dart';
import 'package:spot_for_fun/ui/core/theme/app_theme.dart';

/// Uppercase filter chip: outlined when off, solid yellow when on.
class UrbanChip extends StatelessWidget {
  const UrbanChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.asphalt : AppColors.bone;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.tape : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3),
          side: BorderSide(
            color: selected ? AppColors.tape : AppColors.lineStrong,
            width: 1.5,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(3),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            // No alignment here: it would make the chip fill the whole
            // row inside a Wrap.
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: fg),
                  const SizedBox(width: 6),
                ],
                Text(label.toUpperCase(), style: AppTheme.label(12, color: fg)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
