import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import 'package:spot_for_fun/ui/core/router/app_router.dart';

const NavigationDestination _explorarDest = NavigationDestination(
  icon: Icon(Icons.explore_outlined),
  selectedIcon: Icon(Icons.explore),
  label: 'Explorar',
);

const NavigationDestination _perfilDest = NavigationDestination(
  icon: Icon(Icons.person_outline),
  selectedIcon: Icon(Icons.person),
  label: 'Perfil',
);

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  int get _selectedIndex {
    final branch = navigationShell.currentIndex;
    return branch >= 1 ? branch + 1 : branch;
  }

  void _goBranch(int destinationIndex) {
    final branchIndex =
        destinationIndex > 0 ? destinationIndex - 1 : destinationIndex;
    navigationShell.goBranch(
      branchIndex,
      initialLocation: destinationIndex == _selectedIndex,
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
      floatingActionButton: FloatingActionButton(
        heroTag: 'create-spot',
        onPressed: () => context.push(AppRoutes.spotCreate),
        elevation: 6,
        child: const Icon(Icons.add, size: 30),
      ).animate().scale(
            duration: 320.ms,
            begin: const Offset(0.6, 0.6),
            end: const Offset(1, 1),
            curve: Curves.easeOutBack,
          ).fadeIn(duration: 200.ms),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _goBranch,
        destinations: [
          _explorarDest,
          const NavigationDestination(
            icon: SizedBox.shrink(),
            label: '',
          ),
          _perfilDest,
        ],
      ),
    );
  }
}
