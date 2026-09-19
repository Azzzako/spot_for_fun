import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:spot_for_fun/ui/core/providers/onboarding_provider.dart';
import 'package:spot_for_fun/ui/core/router/app_router.dart';

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
          'Califica los spots que visites, deja tu like y guarda tus '
          'favoritos. Tus aportes ayudan a todos.',
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
              const SizedBox(height: 8),
              Text(
                'Bienvenido a Spot For Fun',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Encuentra. Explora. Patina.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _tips
                      .map(
                        (t) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: _TipCard(tip: t),
                        ),
                      )
                      .toList(),
                ),
              ),
              FilledButton(
                onPressed: () async {
                  await ref
                      .read(onboardingCompletedProvider.notifier)
                      .markSeen();
                  if (!context.mounted) return;
                  context.go(AppRoutes.splash);
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Comenzar'),
                ),
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
  const _TipCard({required this.tip});
  final _OnboardingTip tip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Icon(
            tip.icon,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tip.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tip.body,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
