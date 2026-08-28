import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:spot_for_fun/ui/core/providers/theme_mode_pref_provider.dart';
import 'package:spot_for_fun/ui/core/router/app_router.dart';
import 'package:spot_for_fun/data/repositories/auth_provider.dart';
import 'package:spot_for_fun/data/repositories/spot_repository.dart';
import 'package:spot_for_fun/domain/models/spot.dart';
import 'package:spot_for_fun/domain/models/profile.dart';
import 'package:spot_for_fun/ui/features/profile/widgets/profile_mock_data.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text(
          'Tendrás que volver a iniciar sesión para usar la app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cerrar sesión'),
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

    final profile = profileAsync.valueOrNull;
    final mySpots = mySpotsAsync.valueOrNull ?? const <Spot>[];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              onSettings: () => _openSettings(context, ref, theme),
            ),
            Expanded(
              child: profile == null
                  ? _ProfileLoadingOrError(
                      async: profileAsync,
                      onRetry: () => ref.invalidate(currentProfileProvider),
                    )
                  : DefaultTabController(
                      length: 3,
                      child: Column(
                        children: [
                          _ProfileHeader(profile: profile, spotCount: mySpots.length),
                          const _TabsBar(),
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
            ),
          ],
        ),
      ),
    );
  }

  void _openSettings(
    BuildContext context,
    WidgetRef ref,
    ThemeModePrefNotifier theme,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.brightness_6_outlined),
              title: Text('Tema: ${_themeLabel(theme.mode)}'),
              onTap: () async {
                final next = switch (theme.mode) {
                  ThemeModePref.system => ThemeModePref.light,
                  ThemeModePref.light => ThemeModePref.dark,
                  ThemeModePref.dark => ThemeModePref.system,
                };
                await theme.setMode(next);
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Cerrar sesión',
                  style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.of(ctx).pop();
                _confirmLogout(context, ref);
              },
            ),
            const SizedBox(height: 12),
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

class _Header extends StatelessWidget {
  const _Header({required this.onSettings});
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            tooltip: 'Ajustes',
            icon: const Icon(Icons.settings_outlined),
            onPressed: onSettings,
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile, required this.spotCount});
  final Profile profile;
  final int spotCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.person_outline,
              size: 44,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            profile.username,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Ciudad de México',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatColumn(value: spotCount.toString(), label: 'Spots'),
              _StatDivider(),
              const _StatColumn(value: '0', label: 'Guardados'),
              _StatDivider(),
              const _StatColumn(value: '0', label: 'Reseñas'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: Theme.of(context).colorScheme.outline,
    );
  }
}

class _TabsBar extends StatelessWidget {
  const _TabsBar();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outline),
        ),
      ),
      child: TabBar(
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: theme.colorScheme.onSurface,
        unselectedLabelColor:
            theme.colorScheme.onSurface.withValues(alpha: 0.55),
        indicatorColor: theme.colorScheme.primary,
        indicatorWeight: 3,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
        tabs: const [
          Tab(text: 'Mis Spots'),
          Tab(text: 'Favoritos'),
          Tab(text: 'Reseñas'),
        ],
      ),
    );
  }
}

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
        title: 'Aún no tienes spots',
        subtitle: 'Cuando agregues uno aparecerá aquí.',
      );
    }
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(mySpotsProvider),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        itemCount: spots.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, i) => SpotListCard(
          spot: spots[i],
          onTap: () => context.push(AppRoutes.spotDetail(spots[i].id)),
        ),
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
      title: 'Favoritos próximamente',
      subtitle:
          'Pronto podrás guardar tus spots favoritos aquí. '
          'La función llega en una próxima actualización.',
    );
  }
}

class _ReviewsTab extends StatelessWidget {
  const _ReviewsTab();

  @override
  Widget build(BuildContext context) {
    return const _EmptyTab(
      icon: Icons.rate_review_outlined,
      title: 'Aún no tienes reseñas',
      subtitle: 'Cuando califiques un spot aparecerá aquí.',
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
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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

class _ProfileLoadingOrError extends StatelessWidget {
  const _ProfileLoadingOrError({required this.async, required this.onRetry});
  final AsyncValue<dynamic> async;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (async.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          const SizedBox(height: 12),
          const Text('No se pudo cargar tu perfil'),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
