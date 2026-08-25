import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:spot_for_fun/ui/core/providers/theme_mode_pref_provider.dart';
import 'package:spot_for_fun/ui/core/router/app_router.dart';
import 'package:spot_for_fun/ui/core/theme/app_colors.dart';
import 'package:spot_for_fun/data/repositories/auth_provider.dart';
import 'package:spot_for_fun/data/repositories/spot_repository.dart';
import 'package:spot_for_fun/domain/models/spot.dart';
import 'package:spot_for_fun/ui/features/profile/widgets/profile_mock_data.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesion'),
        content: const Text(
          'Tendras que volver a iniciar sesion para usar la app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cerrar sesion'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    await ref.read(authRepositoryProvider).signOut();
    if (!context.mounted) return;
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeModePrefProvider);
    final profileAsync = ref.watch(currentProfileProvider);
    final mySpotsAsync = ref.watch(mySpotsProvider);
    final brightness = Theme.of(context).brightness;
    final background = brightness == Brightness.dark
        ? Theme.of(context).colorScheme.surface
        : AppColors.brandCream;

    final profile = profileAsync.valueOrNull;
    final mySpots = mySpotsAsync.valueOrNull ?? const <Spot>[];
    final header = profile == null
        ? ProfileHeader(
            username: 'Cargando...',
            userId: 'guest',
            spotsCount: 0,
            favoritesCount: 0,
            reviewsCount: 0,
          )
        : ProfileHeader(
            username: profile.username,
            userId: profile.id,
            spotsCount: mySpots.length,
            favoritesCount: 0,
            reviewsCount: 0,
          );

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: profile == null
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
          actions: [
            IconButton(
              tooltip: 'Notificaciones',
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sin notificaciones nuevas')),
                );
              },
            ),
            PopupMenuButton<_OverflowAction>(
              tooltip: 'Mas opciones',
              icon: const Icon(Icons.more_vert),
              onSelected: (action) async {
                switch (action) {
                  case _OverflowAction.theme:
                    final current = theme.mode;
                    final next = switch (current) {
                      ThemeModePref.system => ThemeModePref.light,
                      ThemeModePref.light => ThemeModePref.dark,
                      ThemeModePref.dark => ThemeModePref.system,
                    };
                    await theme.setMode(next);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Tema: ${_themeLabel(next)}')),
                      );
                    }
                    break;
                  case _OverflowAction.logout:
                    await _confirmLogout(context, ref);
                    break;
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: _OverflowAction.theme,
                  child: Row(
                    children: [
                      const Icon(Icons.brightness_6_outlined),
                      const SizedBox(width: 12),
                      Text('Tema: ${_themeLabel(theme.mode)}'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: _OverflowAction.logout,
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.redAccent),
                      SizedBox(width: 12),
                      Text('Cerrar sesion'),
                    ],
                  ),
                ),
              ],
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: AppColors.brandForest,
                unselectedLabelColor:
                    Theme.of(context).colorScheme.onSurfaceVariant,
                indicatorColor: AppColors.brandForest,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
                tabs: const [
                  Tab(text: 'Mis Spots'),
                  Tab(text: 'Favoritos'),
                  Tab(text: 'Resenas'),
                ],
              ),
            ),
          ),
        ),
        body: profile == null
            ? Center(
                child: profileAsync.isLoading
                    ? const CircularProgressIndicator()
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 48, color: Colors.redAccent),
                          const SizedBox(height: 12),
                          const Text('No se pudo cargar tu perfil'),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () =>
                                ref.invalidate(currentProfileProvider),
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
              )
            : Column(
                children: [
                  header,
                  Expanded(
                    child: TabBarView(
                      children: [
                        _MySpotsTab(
                          asyncSpots: mySpotsAsync,
                          spots: mySpots,
                          ref: ref,
                        ),
                        const _FavoritesTab(),
                        const _ReviewsTab(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _themeLabel(ThemeModePref pref) {
    switch (pref) {
      case ThemeModePref.system:
        return 'Auto';
      case ThemeModePref.light:
        return 'Claro';
      case ThemeModePref.dark:
        return 'Oscuro';
    }
  }
}

enum _OverflowAction { theme, logout }

class _MySpotsTab extends StatelessWidget {
  const _MySpotsTab({
    required this.asyncSpots,
    required this.spots,
    required this.ref,
  });

  final AsyncValue<List<Spot>> asyncSpots;
  final List<Spot> spots;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    if (asyncSpots.isLoading && spots.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (asyncSpots.hasError && spots.isEmpty) {
      return _ErrorTab(
        message: 'No se pudieron cargar tus spots',
        onRetry: () => ref.invalidate(mySpotsProvider),
      );
    }
    if (spots.isEmpty) {
      return const _EmptyTab(
        icon: Icons.add_location_alt_outlined,
        title: 'Aun no tienes spots',
        subtitle: 'Cuando agregues uno aparecera aqui.',
      );
    }
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(mySpotsProvider),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        itemCount: spots.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, i) => SpotListCard(spot: spots[i]),
      ),
    );
  }
}

class _FavoritesTab extends StatelessWidget {
  const _FavoritesTab();

  @override
  Widget build(BuildContext context) {
    return const _EmptyTab(
      icon: Icons.favorite_border,
      title: 'Favoritos proximamente',
      subtitle:
          'Pronto podras guardar tus spots favoritos aqui. '
          'La funcion llega en una proxima actualizacion.',
    );
  }
}

class _ReviewsTab extends StatelessWidget {
  const _ReviewsTab();

  @override
  Widget build(BuildContext context) {
    return const _EmptyTab(
      icon: Icons.rate_review_outlined,
      title: 'Aun no tienes resenas',
      subtitle: 'Cuando califiques un spot aparecera aqui.',
    );
  }
}

class _EmptyTab extends StatelessWidget {
  const _EmptyTab({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorTab extends StatelessWidget {
  const _ErrorTab({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(message),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}