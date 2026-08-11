import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/theme_mode_pref_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class SpotForFunApp extends ConsumerWidget {
  const SpotForFunApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeModePrefProvider);
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Spot For Fun',
      debugShowCheckedModeBanner: false,
      themeMode: theme.toMaterialMode(),
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: router,
    );
  }
}
