import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:spot_for_fun/ui/core/providers/supabase_client_provider.dart';

class AuthResult {
  AuthResult({required this.user, required this.needsEmailConfirmation});
  final User user;
  final bool needsEmailConfirmation;
}

class AppAuthException implements Exception {
  AppAuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;
  GoogleSignIn? _google;

  GoogleSignIn _ensureGoogle() => _google ??= GoogleSignIn(
        scopes: const ['email', 'profile'],
      );

  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final res = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
      );
      final user = res.user;
      if (user == null) {
        throw AppAuthException('No se pudo crear la cuenta.');
      }
      final needsConfirm = res.session == null;
      return AuthResult(user: user, needsEmailConfirmation: needsConfirm);
    } on AuthException catch (e) {
      throw AppAuthException(_mapError(e));
    }
  }

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = res.user;
      if (user == null || res.session == null) {
        throw AppAuthException('Credenciales inválidas.');
      }
      return AuthResult(user: user, needsEmailConfirmation: false);
    } on AuthException catch (e) {
      throw AppAuthException(_mapError(e));
    }
  }

  Future<AuthResult> signInWithGoogle() async {
    final google = _ensureGoogle();
    final GoogleSignInAccount googleUser;
    try {
      final account = await google.signIn();
      if (account == null) {
        throw AppAuthException('Inicio cancelado.');
      }
      googleUser = account;
    } on AppAuthException {
      rethrow;
    } catch (e) {
      throw AppAuthException('Google sign-in falló: $e');
    }
    final auth = await googleUser.authentication;
    final idToken = auth.idToken;
    if (idToken == null) {
      throw AppAuthException('Google no devolvió token.');
    }
    try {
      final res = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
      final user = res.user;
      if (user == null || res.session == null) {
        throw AppAuthException('Google sign-in falló.');
      }
      return AuthResult(user: user, needsEmailConfirmation: false);
    } on AuthException catch (e) {
      throw AppAuthException(_mapError(e));
    }
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<void> resendConfirmation(String email) async {
    try {
      await _client.auth.resend(
        type: OtpType.email,
        email: email,
      );
    } on AuthException catch (e) {
      throw AppAuthException(_mapError(e));
    }
  }

  String _mapError(AuthException e) {
    final m = e.message.toLowerCase();
    if (m.contains('email not confirmed')) {
      return 'Confirma tu correo antes de entrar.';
    }
    if (m.contains('invalid login') || m.contains('invalid credentials')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (m.contains('already') && m.contains('registered')) {
      return 'Ese correo ya está registrado.';
    }
    if (m.contains('password')) return 'La contraseña no cumple los requisitos.';
    if (m.contains('email')) return 'Correo inválido.';
    return e.message;
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthRepository(client);
});
