import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/local_storage_service.dart';
import '../services/auth_service.dart';

/// AsyncNotifier for businesses - handles loading visible businesses based on user role/email
class BusinessesNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    final role = await AuthService().getCurrentUserRole();
    final email = await AuthService().getCurrentUserEmail();
    return ref
        .read(storageServiceProvider)
        .getVisibleBusinesses(role: role, email: email);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final businessesProvider =
    AsyncNotifierProvider<BusinessesNotifier, List<Map<String, dynamic>>>(
      () => BusinessesNotifier(),
    );

/// Saved businesses IDs
class SavedNotifier extends StateNotifier<Set<String>> {
  SavedNotifier() : super(<String>{});

  Future<void> load() async {
    final ids = await LocalStorageService().getSavedBusinesses();
    state = ids.toSet();
  }

  Future<void> toggle(String id) async {
    if (state.contains(id)) {
      await LocalStorageService().removeSavedBusiness(id);
      state = {...state}..remove(id);
    } else {
      await LocalStorageService().saveSavedBusiness(id);
      state = {...state, id};
    }
  }

  Future<void> refresh() => load();
}

final savedBusinessesProvider =
    StateNotifierProvider<SavedNotifier, Set<String>>(
      (ref) => SavedNotifier()..load(),
    );

/// Current user email
final currentUserEmailProvider = FutureProvider<String?>((ref) async {
  return AuthService().getCurrentUserEmail();
});

final currentUserRoleProvider = FutureProvider<String?>((ref) async {
  return AuthService().getCurrentUserRole();
});

// Service providers (singleton wrap)
final storageServiceProvider = Provider<LocalStorageService>(
  (ref) => LocalStorageService(),
);
final authServiceProvider = Provider<AuthService>((ref) => AuthService());
