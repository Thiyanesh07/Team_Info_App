import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:team_info_app/core/constants/api_constants.dart';
import 'package:team_info_app/models/user_model.dart';
import 'package:team_info_app/services/api_service.dart';
import 'package:google_sign_in/google_sign_in.dart';

const String _googleWebClientId = String.fromEnvironment(
  'GOOGLE_WEB_CLIENT_ID',
);
const String _googleServerClientId = String.fromEnvironment(
  'GOOGLE_SERVER_CLIENT_ID',
);
const String _googleServerClientIdFallback =
    '638705857828-b3mamn6rlq4bcsi3bs9nki0gn5hu8i9c.apps.googleusercontent.com';

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
  final ApiService _api = ApiService();

  AuthNotifier() : super(const AuthState()) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final token = await _api.getToken();
    if (token == null) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }

    state = state.copyWith(status: AuthStatus.loading);
    final response = await _api.get(ApiConstants.me);
    if (response.success && response.data != null) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: UserModel.fromJson(response.data),
        token: token,
      );
    } else {
      await _api.deleteToken();
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> loginWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      // Initialize GoogleSignIn
      await GoogleSignIn.instance.initialize(
        clientId: kIsWeb && _googleWebClientId.isNotEmpty
            ? _googleWebClientId
            : null,
        serverClientId: _googleServerClientId.isNotEmpty
            ? _googleServerClientId
            : _googleServerClientIdFallback,
      );

      // Prompt user to sign in
      late final GoogleSignInAccount account;
      try {
        account = await GoogleSignIn.instance.authenticate(
          scopeHint: ['email'],
        );
      } catch (e) {
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

      // Send the ID token to our backend
      final response = await _api.post(
        ApiConstants.googleLogin,
        body: {'idToken': auth.idToken},
        withAuth: false,
      );

      if (response.success && response.data != null) {
        await _api.saveToken(response.data['token']);
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
      // Removed debug prints
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage:
            'Google Sign-In Error: ${error.toString().split("\n").first}',
      );
    }
  }

  Future<void> logout() async {
    await _api.deleteToken();
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> refreshUser() async {
    final response = await _api.get(ApiConstants.me);
    if (response.success && response.data != null) {
      state = state.copyWith(user: UserModel.fromJson(response.data));
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
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
