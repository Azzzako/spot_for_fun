import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spot_for_fun/ui/core/providers/onboarding_provider.dart';
import 'package:spot_for_fun/ui/core/router/app_router.dart';
import 'package:spot_for_fun/data/repositories/auth_provider.dart';
import 'package:go_router/go_router.dart';

import 'package:spot_for_fun/ui/core/theme/app_colors.dart';
import 'package:spot_for_fun/ui/shared/widgets/brand_wordmark.dart';
import 'package:spot_for_fun/ui/shared/widgets/tape_label.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  /// Fades the tagline and loader out before the route transition, so
  /// the hand-off to the next screen reads as one continuous motion.
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    final onboarding = await ref.read(onboardingCompletedProvider.future);
    if (!mounted) return;
    final String target;
    if (!onboarding) {
      target = AppRoutes.onboarding;
    } else {
      final session = ref.read(authStateProvider).valueOrNull?.session;
      target = session == null ? AppRoutes.login : AppRoutes.map;
    }
    setState(() => _leaving = true);
    await Future<void>.delayed(const Duration(milliseconds: 320));
    if (!mounted) return;
    context.go(target);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.asphalt,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/identity/background.png',
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter,
            errorBuilder: (_, _, _) =>
                const ColoredBox(color: AppColors.asphalt),
          ),
          const ColoredBox(color: Color(0x66111111)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  const BrandWordmark(size: 64)
                      .animate()
                      .fadeIn(duration: 700.ms, curve: Curves.easeOutCubic)
                      .scale(
                        begin: const Offset(0.94, 0.94),
                        end: const Offset(1, 1),
                        duration: 900.ms,
                        curve: Curves.easeOutCubic,
                      ),
                  const SizedBox(height: 14),
                  AnimatedOpacity(
                    opacity: _leaving ? 0 : 1,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    child: const TapeLabel('Encuentra. Explora. Patina.')
                        .animate()
                        .fadeIn(
                          delay: 350.ms,
                          duration: 600.ms,
                          curve: Curves.easeOutCubic,
                        )
                        .slideY(
                          begin: 0.4,
                          end: 0,
                          delay: 350.ms,
                          duration: 600.ms,
                          curve: Curves.easeOutCubic,
                        ),
                  ),
                  const Spacer(flex: 4),
                  AnimatedOpacity(
                    opacity: _leaving ? 0 : 1,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    child: const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ).animate().fadeIn(delay: 700.ms, duration: 500.ms),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
