import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:team_info_app/models/user_model.dart';
import 'package:team_info_app/repositories/auth_repository.dart';
import 'package:google_sign_in/google_sign_in.dart';

const String _googleWebClientId = String.fromEnvironment(
  'GOOGLE_WEB_CLIENT_ID',
);
const String _googleServerClientId = String.fromEnvironment(
  'GOOGLE_SERVER_CLIENT_ID',
);
const String _googleServerClientIdFallback =
    '638705857828-3r7ammk6lbimalqlcb5spbaesma7tse4.apps.googleusercontent.com';

// ─── Auth State ──────────────────────────────
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? token;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.token,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? token,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      token: token ?? this.token,
      errorMessage: errorMessage,
    );
  }
}

// ─── Auth Notifier ───────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AuthState()) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final token = await _repo.getToken();
    if (token == null) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }

    state = state.copyWith(status: AuthStatus.loading);
    final user = await _repo.getMe();
    if (user != null) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        token: token,
      );
    } else {
      // Avoid deleting a freshly-updated token if a stale startup check finishes late.
      final latestToken = await _repo.getToken();
      if (latestToken != token) return;
      await _repo.deleteToken();
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> loginWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      // Initialize GoogleSignIn
      await GoogleSignIn.instance
          .initialize(
            clientId: kIsWeb && _googleWebClientId.isNotEmpty
                ? _googleWebClientId
                : null,
            serverClientId: _googleServerClientId.isNotEmpty
                ? _googleServerClientId
                : _googleServerClientIdFallback,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException(
              'Google Sign-In initialization timed out',
            ),
          );

      // Prompt user to sign in
      late final GoogleSignInAccount account;
      try {
        account = await GoogleSignIn.instance
            .authenticate(scopeHint: ['email'])
            .timeout(
              const Duration(seconds: 45),
              onTimeout: () =>
                  throw TimeoutException('Google account selection timed out'),
            );
      } catch (e) {
        if (e is TimeoutException) {
          state = state.copyWith(
            status: AuthStatus.error,
            errorMessage: 'Google Sign-In timed out. Please try again.',
          );
          return;
        }
        // User canceled the sign-in flow
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: null,
        );
        return;
      }

      // Get authentication tokens
      final GoogleSignInAuthentication auth = account.authentication;

      if (auth.idToken == null) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Failed to retrieve Google ID token',
        );
        return;
      }

      // Render free instances can be cold; ping health once before auth request.
      try {
        await _repo.healthCheck().timeout(const Duration(seconds: 25));
      } catch (_) {}

      // Send the ID token to our backend
      final response = await _repo.loginWithGoogle(auth.idToken!);

      if (response.success && response.data != null) {
        await _repo.saveToken(response.data['token']);
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: UserModel.fromJson(response.data['user']),
          token: response.data['token'],
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: response.message ?? 'Login failed',
        );
      }
    } catch (error) {
      if (error is TimeoutException) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Sign-In timed out. Check your internet and try again.',
        );
        return;
      }
      // Removed debug prints
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage:
            'Google Sign-In Error: ${error.toString().split("\n").first}',
      );
    }
  }

  Future<void> logout() async {
    await _repo.deleteToken();
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> refreshUser() async {
    final user = await _repo.getMe();
    if (user != null) {
      state = state.copyWith(user: user);
    }
  }

  void clearError() {
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      errorMessage: null,
    );
  }
}

// ─── Providers ───────────────────────────────
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
);

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});
