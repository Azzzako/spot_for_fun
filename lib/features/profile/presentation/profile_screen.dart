import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/theme_mode_pref_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeModePrefProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          Text('Tema', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<ThemeModePref>(
            segments: const [
              ButtonSegment(value: ThemeModePref.system, label: Text('Auto')),
              ButtonSegment(value: ThemeModePref.light, label: Text('Claro')),
              ButtonSegment(value: ThemeModePref.dark, label: Text('Oscuro')),
            ],
            selected: {theme.mode},
            onSelectionChanged: (set) => theme.setMode(set.first),
          ),
        ],
      ),
    );
  }
}
