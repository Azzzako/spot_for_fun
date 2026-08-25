import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:spot_for_fun/ui/features/admin/views/admin_pending_screen.dart';
import 'package:spot_for_fun/data/repositories/auth_provider.dart';
import 'package:spot_for_fun/ui/features/auth/views/login_screen.dart';
import 'package:spot_for_fun/ui/features/auth/views/register_screen.dart';
import 'package:spot_for_fun/ui/features/map/views/map_screen.dart';
import 'package:spot_for_fun/ui/features/profile/views/favorites_screen.dart';
import 'package:spot_for_fun/ui/features/profile/views/profile_screen.dart';
import 'package:spot_for_fun/ui/features/shell/views/app_shell.dart';
import 'package:spot_for_fun/ui/features/spots/views/create/create_spot_screen.dart';
import 'package:spot_for_fun/ui/features/spots/views/create/spot_location_picker_screen.dart';
import 'package:spot_for_fun/ui/features/spots/views/detail/spot_detail_screen.dart';
import 'package:spot_for_fun/ui/features/spots/views/myspots/my_spots_screen.dart';

const _kFadeThrough = Duration(milliseconds: 300);
const _kFadeThroughReverse = Duration(milliseconds: 250);

CustomTransitionPage<T> fadeThroughPage<T>({
  required Widget child,
  required GoRouterState state,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: _kFadeThrough,
    reverseTransitionDuration: _kFadeThroughReverse,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return AnimatedBuilder(
        animation: Listenable.merge([animation, secondaryAnimation]),
        builder: (context, _) {
          final incoming = Curves.easeInOutCubic.transform(animation.value);
          final outgoing =
              Curves.easeInOutCubic.transform(secondaryAnimation.value);
          final opacity = (incoming * (1.0 - outgoing)).clamp(0.0, 1.0);
          final scale = 0.92 + 0.08 * incoming;
          return Opacity(
            opacity: opacity,
            child: Transform.scale(scale: scale, child: child),
          );
        },
        child: child,
      );
    },
  );
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _mapaNavigatorKey = GlobalKey<NavigatorState>();
final _myspotsNavigatorKey = GlobalKey<NavigatorState>();
final _favoritesNavigatorKey = GlobalKey<NavigatorState>();
final _perfilNavigatorKey = GlobalKey<NavigatorState>();

class AppRoutes {
  AppRoutes._();
  static const login = '/login';
  static const register = '/register';
  static const map = '/';
  static const spotCreate = '/spots/create';
  static const spotPickLocation = '/spots/create/pick-location';
  static const mySpots = '/spots/mine';
  static const profile = '/profile';
  static const favorites = '/profile/favorites';
  static const adminPending = '/admin/pending';

  static String spotDetail(String id) => '/spots/$id';
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final authAsync = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.map,
    refreshListenable: _AuthListenable(ref),
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final session = authAsync.whenOrNull(data: (s) => s.session);
      final loc = state.matchedLocation;
      final loggingIn = loc == AppRoutes.login || loc == AppRoutes.register;

      if (session == null) return loggingIn ? null : AppRoutes.login;
      if (loggingIn) return AppRoutes.map;
      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _mapaNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.map,
                builder: (_, _) => const MapScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _myspotsNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.mySpots,
                builder: (_, _) => const MySpotsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _favoritesNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.favorites,
                builder: (_, _) => const FavoritesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _perfilNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.login,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => fadeThroughPage(
          state: state,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.register,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => fadeThroughPage(
          state: state,
          child: const RegisterScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.spotCreate,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => fadeThroughPage(
          state: state,
          child: const CreateSpotScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.spotPickLocation,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => fadeThroughPage(
          state: state,
          child: const SpotLocationPickerScreen(),
        ),
      ),
      GoRoute(
        path: '/spots/:id',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => fadeThroughPage(
          state: state,
          child: SpotDetailScreen(spotId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: AppRoutes.adminPending,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => fadeThroughPage(
          state: state,
          child: const AdminPendingScreen(),
        ),
      ),
    ],
  );
});

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(this.ref) {
    ref.listen(authStateProvider, (_, _) => notifyListeners());
  }
  final Ref ref;
}