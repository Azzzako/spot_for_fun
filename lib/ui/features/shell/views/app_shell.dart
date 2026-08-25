import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:spot_for_fun/ui/core/router/app_router.dart';

const Color _kBrandAccent = Color(0xFFF2C14E);

const int _placeholderIndex = 2;

int _destinationToBranch(int destinationIndex) {
  if (destinationIndex == _placeholderIndex) return destinationIndex;
  return destinationIndex > _placeholderIndex
      ? destinationIndex - 1
      : destinationIndex;
}

int _branchToDestination(int branchIndex) {
  return branchIndex >= _placeholderIndex
      ? branchIndex + 1
      : branchIndex;
}

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _goBranch(int destinationIndex) {
    if (destinationIndex == _placeholderIndex) return;
    final branchIndex = _destinationToBranch(destinationIndex);
    navigationShell.goBranch(
      branchIndex,
      initialLocation: destinationIndex ==
          _branchToDestination(navigationShell.currentIndex),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeInOutCubic,
        switchOutCurve: Curves.easeInOutCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        layoutBuilder: (currentChild, previousChildren) {
          return Stack(
            alignment: Alignment.topCenter,
            children: [
              ...previousChildren,
              ?currentChild,
            ],
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(navigationShell.currentIndex),
          child: navigationShell,
        ),
      ),
      floatingActionButton: Transform.translate(
        offset: const Offset(0, 28),
        child: FloatingActionButton(
          heroTag: 'create-spot',
          backgroundColor: _kBrandAccent,
          foregroundColor: Colors.black,
          elevation: 10,
          focusElevation: 12,
          hoverElevation: 12,
          onPressed: () => context.push(AppRoutes.spotCreate),
          child: const Icon(Icons.add, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _branchToDestination(navigationShell.currentIndex),
        onDestinationSelected: _goBranch,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Mapa',
          ),
          const NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Mis spots',
          ),
          const NavigationDestination(
            icon: SizedBox.shrink(),
            label: '',
          ),
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Tienda',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
