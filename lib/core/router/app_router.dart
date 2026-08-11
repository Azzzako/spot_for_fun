import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/admin_pending_screen.dart';
import '../../features/auth/data/auth_provider.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/map/presentation/map_screen.dart';
import '../../features/profile/presentation/favorites_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/spots/presentation/create/create_spot_screen.dart';
import '../../features/spots/presentation/detail/spot_detail_screen.dart';
import '../../features/spots/presentation/myspots/my_spots_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

class AppRoutes {
  AppRoutes._();
  static const login = '/login';
  static const register = '/register';
  static const map = '/';
  static const spotCreate = '/spots/create';
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
      GoRoute(
        path: AppRoutes.map,
        builder: (_, _) => const MapScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.spotCreate,
        builder: (_, _) => const CreateSpotScreen(),
      ),
      GoRoute(
        path: AppRoutes.mySpots,
        builder: (_, _) => const MySpotsScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (_, _) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.favorites,
        builder: (_, _) => const FavoritesScreen(),
      ),
      GoRoute(
        path: '/spots/:id',
        builder: (_, st) =>
            SpotDetailScreen(spotId: st.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.adminPending,
        builder: (_, _) => const AdminPendingScreen(),
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
