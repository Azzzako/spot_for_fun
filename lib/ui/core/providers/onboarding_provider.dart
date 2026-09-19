import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// True once the first-run welcome screen has been dismissed. Stored
/// in SharedPreferences so it survives updates and reinstalls on the
/// same device. Bump the key suffix if the copy changes materially.
final onboardingCompletedProvider =
    AsyncNotifierProvider<OnboardingCompletedNotifier, bool>(
  OnboardingCompletedNotifier.new,
);

class OnboardingCompletedNotifier extends AsyncNotifier<bool> {
  static const _key = 'onboarding_seen_v1';

  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
    state = AsyncData(true);
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    state = const AsyncData(false);
  }
}
