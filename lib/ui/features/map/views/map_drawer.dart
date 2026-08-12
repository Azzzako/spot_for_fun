import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:spot_for_fun/ui/core/router/app_router.dart';
import 'package:spot_for_fun/data/repositories/auth_provider.dart';
import 'package:spot_for_fun/ui/features/map/view_models/map_view_model.dart';
import 'package:spot_for_fun/ui/shared/widgets/brand_logo.dart';

class MapDrawer extends ConsumerWidget {
  const MapDrawer({super.key, required this.onOpenFilters});

  final VoidCallback onOpenFilters;

  Future<void> _closeThen(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    Navigator.of(context).pop();
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!context.mounted) return;
    await action();
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
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

    Navigator.of(context).pop();
    await ref.read(mapViewModelProvider.notifier).stopTracking();
    await ref.read(authRepositoryProvider).signOut();
    if (!context.mounted) return;
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(currentProfileProvider);
    final username = profileAsync.maybeWhen(
      data: (p) => p?.username,
      orElse: () => null,
    );

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BrandLogo(size: 96),
                  const SizedBox(height: 12),
                  Text(
                    username == null ? 'Bienvenido' : 'Hola, @$username',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Perfil'),
              onTap: () => _closeThen(
                context,
                () async => context.push(AppRoutes.profile),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.favorite_outline),
              title: const Text('Mis favoritos'),
              onTap: () => _closeThen(
                context,
                () async => context.push(AppRoutes.favorites),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.list_alt_outlined),
              title: const Text('Mis spots'),
              onTap: () => _closeThen(
                context,
                () async => context.push(AppRoutes.mySpots),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.filter_alt_outlined),
              title: const Text('Filtros'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).pop();
                Future<void>.delayed(
                  const Duration(milliseconds: 180),
                  () => onOpenFilters(),
                );
              },
            ),
            const Spacer(),
            const Divider(height: 1),
            ListTile(
              leading: Icon(
                Icons.logout,
                color: theme.colorScheme.error,
              ),
              title: Text(
                'Cerrar sesion',
                style: TextStyle(color: theme.colorScheme.error),
              ),
              onTap: () => _logout(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}
