import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:spot_for_fun/ui/core/providers/theme_mode_pref_provider.dart';
import 'package:spot_for_fun/ui/core/router/app_router.dart';
import 'package:spot_for_fun/ui/core/theme/app_colors.dart';
import 'package:spot_for_fun/data/repositories/auth_provider.dart';
import 'package:spot_for_fun/ui/features/profile/widgets/profile_mock_data.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const _tabs = [
    _TabSpec(label: 'Mis Spots', spots: kMockMySpots),
    _TabSpec(label: 'Favoritos', spots: kMockFavoriteSpots),
    _TabSpec(label: 'Resenas', spots: []),
  ];

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
    final profile = MockProfile.current;
    final brightness = Theme.of(context).brightness;
    final background = brightness == Brightness.dark
        ? Theme.of(context).colorScheme.surface
        : AppColors.brandCream;

    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
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
                tabs: _tabs
                    .map((t) => Tab(text: t.label))
                    .toList(growable: false),
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            ProfileHeader(profile: profile),
            Expanded(
              child: TabBarView(
                children: [
                  _SpotListTab(spots: _tabs[0].spots),
                  _SpotListTab(spots: _tabs[1].spots),
                  const _EmptyTab(
                    icon: Icons.rate_review_outlined,
                    title: 'Aun no tienes resenas',
                    subtitle:
                        'Cuando califiques un spot aparecera aqui.',
                  ),
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

class _TabSpec {
  const _TabSpec({required this.label, required this.spots});
  final String label;
  final List<MockSpot> spots;
}

enum _OverflowAction { theme, logout }

class _SpotListTab extends StatelessWidget {
  const _SpotListTab({required this.spots});
  final List<MockSpot> spots;

  @override
  Widget build(BuildContext context) {
    if (spots.isEmpty) {
      return const _EmptyTab(
        icon: Icons.bookmark_border,
        title: 'Sin spots todavia',
        subtitle: 'Cuando agregues uno aparecera aqui.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: spots.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) => SpotListCard(spot: spots[i]),
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