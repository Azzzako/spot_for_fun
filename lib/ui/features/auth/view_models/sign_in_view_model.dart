import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spot_for_fun/data/repositories/auth_repository.dart';

enum AuthFormStatus { idle, loading, success, error }

@immutable
class SignInState {
  const SignInState({
    this.status = AuthFormStatus.idle,
    this.errorMessage,
  });

  final AuthFormStatus status;
  final String? errorMessage;

  SignInState copyWith({
    AuthFormStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SignInState(
      status: status ?? this.status,
      errorMessage:
          clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class SignInViewModel extends AutoDisposeNotifier<SignInState> {
  @override
  SignInState build() => const SignInState();

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(
      status: AuthFormStatus.loading,
      clearError: true,
    );
    try {
      await ref.read(authRepositoryProvider).signIn(
            email: email,
            password: password,
          );
      state = state.copyWith(status: AuthFormStatus.success);
      return true;
    } on AppAuthException catch (e) {
      state = state.copyWith(
        status: AuthFormStatus.error,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthFormStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  void reset() {
    state = const SignInState();
  }
}

final signInViewModelProvider =
    AutoDisposeNotifierProvider<SignInViewModel, SignInState>(
  SignInViewModel.new,
);
