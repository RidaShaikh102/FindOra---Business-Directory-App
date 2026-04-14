import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provider for SharedPreferences instance
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be initialized');
});

// Provider for onboarding completion state
final onboardingCompletedProvider = StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return OnboardingNotifier(prefs);
});

class OnboardingNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;

  OnboardingNotifier(this._prefs) : super(_prefs.getBool('onboardingCompleted') ?? false);

  Future<void> completeOnboarding() async {
    await _prefs.setBool('onboardingCompleted', true);
    state = true;
  }
}

// Provider that creates the onboarding notifier with prefs
final onboardingProvider = FutureProvider.family<OnboardingNotifier, SharedPreferences>((ref, prefs) async {
  return OnboardingNotifier(prefs);
});