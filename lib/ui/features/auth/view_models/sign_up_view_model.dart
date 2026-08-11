import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spot_for_fun/data/repositories/auth_repository.dart';

enum AuthFormStatus { idle, loading, success, needsEmailConfirmation, error }

@immutable
class SignUpState {
  const SignUpState({
    this.status = AuthFormStatus.idle,
    this.errorMessage,
  });

  final AuthFormStatus status;
  final String? errorMessage;

  SignUpState copyWith({
    AuthFormStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SignUpState(
      status: status ?? this.status,
      errorMessage:
          clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class SignUpViewModel extends AutoDisposeNotifier<SignUpState> {
  @override
  SignUpState build() => const SignUpState();

  Future<({bool ok, bool needsEmailConfirmation})> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    state = state.copyWith(
      status: AuthFormStatus.loading,
      clearError: true,
    );
    try {
      final result = await ref.read(authRepositoryProvider).signUp(
            email: email,
            password: password,
            username: username,
          );
      final status = result.needsEmailConfirmation
          ? AuthFormStatus.needsEmailConfirmation
          : AuthFormStatus.success;
      state = state.copyWith(status: status);
      return (ok: true, needsEmailConfirmation: result.needsEmailConfirmation);
    } on AppAuthException catch (e) {
      state = state.copyWith(
        status: AuthFormStatus.error,
        errorMessage: e.message,
      );
      return (ok: false, needsEmailConfirmation: false);
    } catch (e) {
      state = state.copyWith(
        status: AuthFormStatus.error,
        errorMessage: e.toString(),
      );
      return (ok: false, needsEmailConfirmation: false);
    }
  }

  void reset() {
    state = const SignUpState();
  }
}

final signUpViewModelProvider =
    AutoDisposeNotifierProvider<SignUpViewModel, SignUpState>(
  SignUpViewModel.new,
);
