import 'package:flutter/material.dart';

import 'package:spot_for_fun/ui/core/theme/app_colors.dart';
import 'package:spot_for_fun/ui/core/theme/app_theme.dart';

/// "SPOT4FUN" in Anton with the 4 in safety-tape yellow. The app is
/// called Spot For Fun; this is how the name is drawn in the UI.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Spot For Fun',
      child: ExcludeSemantics(
        child: Text.rich(
          TextSpan(
            style: AppTheme.display(size),
            children: const [
              TextSpan(text: 'SPOT'),
              TextSpan(
                text: '4',
                style: TextStyle(color: AppColors.tape),
              ),
              TextSpan(text: 'FUN'),
            ],
          ),
        ),
      ),
    );
  }
}
