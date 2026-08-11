export 'package:spot_for_fun/data/services/auth_service.dart'
    show AppAuthException, AuthResult;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spot_for_fun/data/services/auth_service.dart';
import 'package:spot_for_fun/ui/core/providers/supabase_client_provider.dart';

class AuthRepository {
  AuthRepository(this._service);
  final AuthService _service;

  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String username,
  }) =>
      _service.signUp(
        email: email,
        password: password,
        username: username,
      );

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) =>
      _service.signIn(email: email, password: password);

  Future<AuthResult> signInWithGoogle() => _service.signInWithGoogle();

  Future<void> signOut() => _service.signOut();

  Future<void> resendConfirmation(String email) =>
      _service.resendConfirmation(email);
}

final authServiceProvider = Provider<AuthService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthService(client);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(authServiceProvider));
});
