import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/auth_service.dart';

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final UserModel? user;
  final String? errorMessage;

  AuthState({
    required this.isLoading,
    required this.isAuthenticated,
    this.user,
    this.errorMessage,
  });

  factory AuthState.initial() => AuthState(isLoading: true, isAuthenticated: false);
  factory AuthState.authenticated(UserModel user) => AuthState(isLoading: false, isAuthenticated: true, user: user);
  factory AuthState.unauthenticated([String? error]) => AuthState(isLoading: false, isAuthenticated: false, errorMessage: error);
  factory AuthState.loading() => AuthState(isLoading: true, isAuthenticated: false);
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState.initial()) {
    checkInitialSession();
  }

  Future<void> checkInitialSession() async {
    try {
      final user = await AuthService.getCurrentUser();
      if (user != null) {
        state = AuthState.authenticated(user);
      } else {
        state = AuthState.unauthenticated();
      }
    } catch (_) {
      state = AuthState.unauthenticated();
    }
  }

  Future<bool> login(String email, String password) async {
    state = AuthState.loading();
    try {
      final user = await AuthService.login(email: email, password: password);
      state = AuthState.authenticated(user);
      return true;
    } catch (e) {
      state = AuthState.unauthenticated(e.toString().replaceAll('ApiException: ', ''));
      return false;
    }
  }

  Future<bool> loginAsGuest() async {
    state = AuthState.loading();
    try {
      final user = await AuthService.loginAsGuest();
      state = AuthState.authenticated(user);
      return true;
    } catch (e) {
      state = AuthState.unauthenticated(e.toString().replaceAll('ApiException: ', ''));
      return false;
    }
  }

  Future<bool> register(String email, String password, String name) async {
    state = AuthState.loading();
    try {
      final user = await AuthService.register(email: email, password: password, fullName: name);
      state = AuthState.authenticated(user);
      return true;
    } catch (e) {
      state = AuthState.unauthenticated(e.toString().replaceAll('ApiException: ', ''));
      return false;
    }
  }

  Future<void> logout() async {
    await AuthService.logout();
    state = AuthState.unauthenticated();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

