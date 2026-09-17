import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:spot_for_fun/data/repositories/auth_provider.dart';
import 'package:spot_for_fun/ui/core/router/app_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        title: const Text('Configuración'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          const _SectionLabel('Cuenta'),
          _NavTile(
            icon: Icons.person_outline,
            label: 'Editar perfil',
            onTap: () => context.push(AppRoutes.settingsEditProfile),
          ),
          _NavTile(
            icon: Icons.shield_outlined,
            label: 'Privacidad',
            onTap: () => context.push(AppRoutes.settingsPrivacy),
          ),
          _NavTile(
            icon: Icons.notifications_none_outlined,
            label: 'Notificaciones',
            onTap: () => context.push(AppRoutes.settingsNotifications),
          ),
          const _SectionLabel('Preferencias'),
          const _ReadOnlyTile(
            icon: Icons.straighten_outlined,
            label: 'Unidades',
            value: 'km',
          ),
          const _ReadOnlyTile(
            icon: Icons.language_outlined,
            label: 'Idioma',
            value: 'Español',
          ),
          const _SectionLabel('Soporte'),
          _NavTile(
            icon: Icons.help_outline,
            label: 'Ayuda',
            onTap: () => context.push(AppRoutes.settingsHelp),
          ),
          _NavTile(
            icon: Icons.info_outline,
            label: 'Acerca de',
            onTap: () => context.push(AppRoutes.settingsAbout),
          ),
          const SizedBox(height: 8),
          const _Divider(),
          _LogoutTile(
            onTap: () => _confirmLogout(context, ref),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _ReadOnlyTile extends StatelessWidget {
  const _ReadOnlyTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () {},
    );
  }
}

class _LogoutTile extends StatelessWidget {
  const _LogoutTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.logout, color: Colors.redAccent),
      title: const Text(
        'Cerrar sesión',
        style: TextStyle(color: Colors.redAccent),
      ),
      onTap: onTap,
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Divider(
        color: Theme.of(context).colorScheme.outline,
        height: 1,
      ),
    );
  }
}
