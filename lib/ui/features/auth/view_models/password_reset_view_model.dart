import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spot_for_fun/data/repositories/auth_repository.dart';
import 'package:spot_for_fun/ui/features/auth/view_models/sign_in_view_model.dart';

@immutable
class PasswordResetState {
  const PasswordResetState({
    this.status = AuthFormStatus.idle,
    this.errorMessage,
  });

  final AuthFormStatus status;
  final String? errorMessage;
}

/// Both halves of "forgot password": requesting the recovery email from
/// the login screen and setting the new password after the deep link.
class PasswordResetViewModel extends AutoDisposeNotifier<PasswordResetState> {
  @override
  PasswordResetState build() => const PasswordResetState();

  Future<bool> sendResetEmail(String email) =>
      _run(() => ref.read(authRepositoryProvider).sendPasswordReset(email));

  Future<bool> updatePassword(String newPassword) => _run(
        () => ref.read(authRepositoryProvider).updatePassword(newPassword),
      );

  Future<void> cancelRecovery() => ref.read(authRepositoryProvider).signOut();

  Future<bool> _run(Future<void> Function() action) async {
    state = const PasswordResetState(status: AuthFormStatus.loading);
    try {
      await action();
      state = const PasswordResetState(status: AuthFormStatus.success);
      return true;
    } on AppAuthException catch (e) {
      state = PasswordResetState(
        status: AuthFormStatus.error,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      debugPrint('password reset failed: $e');
      state = const PasswordResetState(
        status: AuthFormStatus.error,
        errorMessage: 'No se pudo completar. Revisa tu conexión.',
      );
      return false;
    }
  }
}

final passwordResetViewModelProvider =
    AutoDisposeNotifierProvider<PasswordResetViewModel, PasswordResetState>(
  PasswordResetViewModel.new,
);
