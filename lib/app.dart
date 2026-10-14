import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spot_for_fun/ui/core/deeplinks/deep_link_listener.dart';
import 'package:spot_for_fun/ui/core/router/app_router.dart';
import 'package:spot_for_fun/ui/core/theme/app_theme.dart';

class SpotForFunApp extends ConsumerWidget {
  const SpotForFunApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Spot For Fun',
      debugShowCheckedModeBanner: false,
      // Urban design is dark-only.
      theme: AppTheme.urban(),
      routerConfig: router,
      builder: (context, child) =>
          DeepLinkListener(child: child ?? const SizedBox.shrink()),
    );
  }
}
