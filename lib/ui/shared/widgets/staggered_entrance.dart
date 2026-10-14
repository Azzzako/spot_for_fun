import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

extension StaggeredEntrance on List<Widget> {
  /// Fades and lifts each widget in, one after another, once the page's
  /// own transition is under way. Skipped when the system asks for
  /// reduced motion.
  List<Widget> staggeredEntrance(
    BuildContext context, {
    Duration delay = const Duration(milliseconds: 160),
    Duration interval = const Duration(milliseconds: 45),
  }) {
    if (MediaQuery.of(context).disableAnimations) return this;
    return animate(delay: delay, interval: interval)
        .fadeIn(duration: 480.ms, curve: Curves.easeOutCubic)
        .slideY(
          begin: 0.08,
          end: 0,
          duration: 480.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
