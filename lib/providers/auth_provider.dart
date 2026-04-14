import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:findora/services/auth_service.dart';

enum AuthState { checking, authenticated, unauthenticated }

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(AuthState.checking) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      state = isLoggedIn ? AuthState.authenticated : AuthState.unauthenticated;
    } catch (e) {
      state = AuthState.unauthenticated;
    }
  }

  Future<void> refreshAuthStatus() async {
    state = AuthState.checking;
    await _checkAuthStatus();
  }

  Future<void> logout() async {
    await _authService.logout();
    state = AuthState.unauthenticated;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = AuthService(); // AuthService is already a singleton
  return AuthNotifier(authService);
});
