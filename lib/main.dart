import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/app_bootstrap.dart';
import 'core/providers/supabase_client_provider.dart';
import 'core/providers/theme_mode_pref_provider.dart';

Future<void> main() async {
  final result = await AppBootstrap.init();

  final overrides = <Override>[
    themeModePrefProvider.overrideWith(
      (ref) => ThemeModePrefNotifier(result.prefs),
    ),
  ];

  if (result.supabaseReady) {
    final client = Supabase.instance.client;
    overrides.add(supabaseClientProvider.overrideWithValue(client));
  }

  runApp(
    ProviderScope(
      overrides: overrides,
      child: result.supabaseReady
          ? const SpotForFunApp()
          : const _SupabaseSetupRequired(),
    ),
  );
}

class _SupabaseSetupRequired extends StatelessWidget {
  const _SupabaseSetupRequired();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.settings_remote, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Supabase no configurado',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Compila la app con:\n'
                  'flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=...',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
