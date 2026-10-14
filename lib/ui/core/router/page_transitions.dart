import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// One transition for the whole app: a slow fade-through. The page
/// that leaves fades out during the first third; the page that arrives
/// fades in over the rest while settling from 97% to full size. Pages
/// never overlap at full opacity, so the dark screens don't double up.
const kPageTransition = Duration(milliseconds: 520);
const kPageTransitionReverse = Duration(milliseconds: 420);

const _outInterval = Interval(0.0, 0.35, curve: Curves.easeOutCubic);
const _inInterval = Interval(0.30, 1.0, curve: Curves.easeOutCubic);

Widget smoothTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  if (MediaQuery.of(context).disableAnimations) return child;
  return AnimatedBuilder(
    animation: Listenable.merge([animation, secondaryAnimation]),
    child: child,
    builder: (context, child) {
      final incoming = _inInterval.transform(animation.value);
      final outgoing = _outInterval.transform(secondaryAnimation.value);
      return Opacity(
        opacity: (incoming * (1.0 - outgoing)).clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.97 + 0.03 * incoming, child: child),
      );
    },
  );
}

CustomTransitionPage<T> smoothPage<T>({
  required Widget child,
  required GoRouterState state,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: kPageTransition,
    reverseTransitionDuration: kPageTransitionReverse,
    transitionsBuilder: smoothTransition,
  );
}

/// Same transition for routes pushed with Navigator/MaterialPageRoute.
class SmoothPageTransitionsBuilder extends PageTransitionsBuilder {
  const SmoothPageTransitionsBuilder();

  @override
  Duration get transitionDuration => kPageTransition;

  @override
  Duration get reverseTransitionDuration => kPageTransitionReverse;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return smoothTransition(context, animation, secondaryAnimation, child);
  }
}
