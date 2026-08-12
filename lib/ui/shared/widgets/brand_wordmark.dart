import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class BrandWordmark extends StatelessWidget {
  const BrandWordmark({
    super.key,
    this.size = 56,
    this.dark = false,
  });

  final double size;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final spotColor = dark ? AppColors.cream : AppColors.ink;
    final forFunColor = AppColors.forest;
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        children: [
          TextSpan(
            text: 'spot',
            style: TextStyle(
              color: spotColor,
              fontSize: size,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.5,
              fontStyle: FontStyle.normal,
              height: 1.0,
            ),
          ),
          const WidgetSpan(child: SizedBox(width: 10)),
          TextSpan(
            text: 'for fun',
            style: TextStyle(
              color: forFunColor,
              fontSize: size * 0.42,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
              letterSpacing: -0.5,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
