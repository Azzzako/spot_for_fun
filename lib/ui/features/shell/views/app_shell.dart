import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:spot_for_fun/ui/core/deeplinks/spot_links.dart';
import 'package:spot_for_fun/ui/core/router/app_router.dart';
import 'package:spot_for_fun/ui/core/theme/app_colors.dart';
import 'package:spot_for_fun/ui/core/theme/app_theme.dart';

/// Bottom bar: MAPA · [+] · PERFIL. The yellow square in the middle
/// opens "Agregar spot" from either tab. Also opens a shared spot link
/// that arrived before the user was signed in (see DeepLinkListener).
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  StatefulNavigationShell get navigationShell => widget.navigationShell;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openPendingLink());
  }

  void _openPendingLink() {
    final spotId = ref.read(pendingSpotLinkProvider);
    if (spotId == null || !mounted) return;
    ref.read(pendingSpotLinkProvider.notifier).state = null;
    context.push(AppRoutes.spotDetail(spotId));
  }

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(pendingSpotLinkProvider, (_, next) {
      if (next != null) _openPendingLink();
    });
    final current = navigationShell.currentIndex;
    return Scaffold(
      body: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 420),
        reverse: false,
        transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
          return FadeThroughTransition(
            animation: primaryAnimation,
            secondaryAnimation: secondaryAnimation,
            fillColor: Colors.transparent,
            child: child,
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(current),
          child: navigationShell,
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.navBar,
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 72,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.map_outlined,
                  label: 'Mapa',
                  selected: current == 0,
                  onTap: () => _goBranch(0),
                ),
                Tooltip(
                  message: 'Agregar spot',
                  child: Material(
                    color: AppColors.tape,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(6)),
                    ),
                    child: InkWell(
                      customBorder: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(6)),
                      ),
                      onTap: () => context.push(AppRoutes.spotCreate),
                      child: const SizedBox(
                        width: 54,
                        height: 54,
                        child: Icon(
                          Icons.add,
                          size: 30,
                          color: AppColors.asphalt,
                          semanticLabel: 'Agregar spot',
                        ),
                      ),
                    ),
                  ),
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  label: 'Perfil',
                  selected: current == 1,
                  onTap: () => _goBranch(1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.tape : AppColors.boneMuted;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 88,
          height: 56,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 4),
              Text(
                label.toUpperCase(),
                style: AppTheme.label(10, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
