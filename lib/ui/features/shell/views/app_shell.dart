import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import 'package:spot_for_fun/ui/core/router/app_router.dart';

const Color _kBrandAccent = Color(0xFFF2C14E);

const NavigationDestination _mapaDest = NavigationDestination(
  icon: Icon(Icons.map_outlined),
  selectedIcon: Icon(Icons.map),
  label: 'Mapa',
);

const NavigationDestination _misSpotsDest = NavigationDestination(
  icon: Icon(Icons.list_alt_outlined),
  selectedIcon: Icon(Icons.list_alt),
  label: 'Mis spots',
);

const NavigationDestination _tiendaDest = NavigationDestination(
  icon: Icon(Icons.storefront_outlined),
  selectedIcon: Icon(Icons.storefront),
  label: 'Tienda',
);

const NavigationDestination _perfilDest = NavigationDestination(
  icon: Icon(Icons.person_outline),
  selectedIcon: Icon(Icons.person),
  label: 'Perfil',
);

const NavigationDestination _placeholderDest = NavigationDestination(
  icon: SizedBox.shrink(),
  label: '',
);

const List<NavigationDestination> _destinations4 = [
  _mapaDest,
  _misSpotsDest,
  _tiendaDest,
  _perfilDest,
];

const List<NavigationDestination> _destinations5 = [
  _mapaDest,
  _misSpotsDest,
  _placeholderDest,
  _tiendaDest,
  _perfilDest,
];

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  bool get _isOnMapa => navigationShell.currentIndex == 0;

  int get _selectedDestinationIndex {
    final branch = navigationShell.currentIndex;
    if (_isOnMapa) {
      return branch >= 2 ? branch + 1 : branch;
    }
    return branch;
  }

  void _goBranch(int destinationIndex) {
    final branchIndex = (_isOnMapa && destinationIndex > 2)
        ? destinationIndex - 1
        : destinationIndex;
    navigationShell.goBranch(
      branchIndex,
      initialLocation: destinationIndex == _selectedDestinationIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 280),
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
          key: ValueKey<int>(navigationShell.currentIndex),
          child: navigationShell,
        ),
      ),
      floatingActionButton: IgnorePointer(
        ignoring: !_isOnMapa,
        child: FloatingActionButton.large(
          heroTag: 'create-spot',
          backgroundColor: _kBrandAccent,
          foregroundColor: Colors.black,
          elevation: 12,
          focusElevation: 14,
          hoverElevation: 14,
          onPressed: () => context.push(AppRoutes.spotCreate),
          child: const Icon(Icons.add, size: 36),
        )
            .animate(target: _isOnMapa ? 1.0 : 0.0)
            .scale(
              duration: 380.ms,
              begin: const Offset(0, 0),
              end: const Offset(1, 1),
              curve: Curves.elasticOut,
            )
            .fade(duration: 240.ms, curve: Curves.easeInCubic)
            .rotate(
              duration: 380.ms,
              begin: 0.15,
              end: 0.0,
              curve: Curves.easeOutBack,
            ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AnimatedCrossFade(
        duration: const Duration(milliseconds: 320),
        firstCurve: Curves.easeInOutCubic,
        secondCurve: Curves.easeInOutCubic,
        crossFadeState:
            _isOnMapa ? CrossFadeState.showFirst : CrossFadeState.showSecond,
        firstChild: NavigationBar(
          key: const ValueKey('shell-nav-mapa'),
          selectedIndex: _selectedDestinationIndex,
          onDestinationSelected: _goBranch,
          destinations: _destinations5,
        ),
        secondChild: NavigationBar(
          key: const ValueKey('shell-nav-rest'),
          selectedIndex: _selectedDestinationIndex,
          onDestinationSelected: _goBranch,
          destinations: _destinations4,
        ),
      ),
    );
  }
}