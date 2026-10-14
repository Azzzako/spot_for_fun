import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:spot_for_fun/ui/core/providers/onboarding_provider.dart';
import 'package:spot_for_fun/ui/core/router/app_router.dart';
import 'package:spot_for_fun/ui/core/theme/app_colors.dart';
import 'package:spot_for_fun/ui/core/theme/app_theme.dart';
import 'package:spot_for_fun/ui/shared/widgets/brand_wordmark.dart';
import 'package:spot_for_fun/ui/shared/widgets/tape_label.dart';
import 'package:spot_for_fun/ui/shared/widgets/staggered_entrance.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  static const _tips = <_OnboardingTip>[
    _OnboardingTip(
      icon: Icons.map_rounded,
      title: 'Explora el mapa',
      body:
          'Descubre spots cerca de ti: skateparks, gaps, skateshops y '
          'cualquier sitio digno de patinar.',
    ),
    _OnboardingTip(
      icon: Icons.add_location_alt_outlined,
      title: 'Agrega tus spots',
      body:
          '¿Conoces un lugar nuevo? Añádelo con nombre, tipo, dificultad '
          'y horario. La comunidad lo revisará.',
    ),
    _OnboardingTip(
      icon: Icons.rate_review_outlined,
      title: 'Reseña y comparte',
      body:
          'Califica los spots que visites y guarda tus favoritos. '
          'Tus aportes ayudan a toda la comunidad.',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const BrandWordmark(size: 32),
                  const SizedBox(height: 28),
                  Text(
                    'BIENVENIDO\nA LA CALLE',
                    style: theme.textTheme.displayMedium,
                  ),
                  const SizedBox(height: 14),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: TapeLabel('Encuentra. Explora. Patina.'),
                  ),
                ].staggeredEntrance(context),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < _tips.length; i++)
                      _TipCard(index: i + 1, tip: _tips[i]),
                  ].staggeredEntrance(
                    context,
                    delay: const Duration(milliseconds: 420),
                    interval: const Duration(milliseconds: 120),
                  ),
                ),
              ),
              ...[
                FilledButton(
                  onPressed: () async {
                    await ref
                        .read(onboardingCompletedProvider.notifier)
                        .markSeen();
                    if (!context.mounted) return;
                    // The router redirect sends signed-out users to login.
                    context.go(AppRoutes.map);
                  },
                  child: const Text('COMENZAR'),
                ),
              ].staggeredEntrance(
                context,
                delay: const Duration(milliseconds: 800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingTip {
  const _OnboardingTip({
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String body;
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.index, required this.tip});
  final int index;
  final _OnboardingTip tip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Text(
              index.toString().padLeft(2, '0'),
              style: AppTheme.display(30, color: AppColors.tape),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      tip.icon,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tip.title.toUpperCase(),
                      style: theme.textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  tip.body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
