import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spot_for_fun/data/repositories/auth_provider.dart';
import 'package:spot_for_fun/domain/enums.dart';
import 'package:spot_for_fun/domain/models/profile.dart';

enum EditProfileStatus { idle, saving, success, error }

@immutable
class EditProfileState {
  const EditProfileState({
    this.username = '',
    this.aka = '',
    this.email = '',
    this.instagram = '',
    this.displayAs = DisplayAs.username,
    this.originalUsername = '',
    this.originalEmail = '',
    this.originalAka = '',
    this.originalInstagram = '',
    this.originalDisplayAs = DisplayAs.username,
    this.hydrated = false,
    this.status = EditProfileStatus.idle,
    this.errorMessage,
    this.emailConfirmSent = false,
  });

  final String username;
  final String aka;
  final String email;
  final String instagram;
  final DisplayAs displayAs;

  final String originalUsername;
  final String originalEmail;
  final String originalAka;
  final String originalInstagram;
  final DisplayAs originalDisplayAs;

  final bool hydrated;
  final EditProfileStatus status;
  final String? errorMessage;
  final bool emailConfirmSent;

  bool get hasProfileChanges =>
      username.trim() != originalUsername.trim() ||
      aka.trim() != originalAka.trim() ||
      instagram.trim() != originalInstagram.trim() ||
      displayAs != originalDisplayAs;

  bool get hasEmailChange =>
      email.trim().toLowerCase() != originalEmail.trim().toLowerCase();

  bool get hasAnyChange => hasProfileChanges || hasEmailChange;

  bool get isSaving => status == EditProfileStatus.saving;

  EditProfileState copyWith({
    String? username,
    String? aka,
    String? email,
    String? instagram,
    DisplayAs? displayAs,
    String? originalUsername,
    String? originalEmail,
    String? originalAka,
    String? originalInstagram,
    DisplayAs? originalDisplayAs,
    bool? hydrated,
    EditProfileStatus? status,
    String? errorMessage,
    bool? emailConfirmSent,
    bool clearError = false,
  }) {
    return EditProfileState(
      username: username ?? this.username,
      aka: aka ?? this.aka,
      email: email ?? this.email,
      instagram: instagram ?? this.instagram,
      displayAs: displayAs ?? this.displayAs,
      originalUsername: originalUsername ?? this.originalUsername,
      originalEmail: originalEmail ?? this.originalEmail,
      originalAka: originalAka ?? this.originalAka,
      originalInstagram: originalInstagram ?? this.originalInstagram,
      originalDisplayAs: originalDisplayAs ?? this.originalDisplayAs,
      hydrated: hydrated ?? this.hydrated,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      emailConfirmSent: emailConfirmSent ?? this.emailConfirmSent,
    );
  }
}

final usernameRegex = RegExp(r'^[A-Za-z0-9_]{3,20}$');
final instagramRegex = RegExp(r'^[A-Za-z0-9._]{1,30}$');
final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

class EditProfileViewModel extends AutoDisposeNotifier<EditProfileState> {
  @override
  EditProfileState build() => const EditProfileState();

  void hydrate({required Profile profile, required String currentEmail}) {
    if (state.hydrated) return;
    state = state.copyWith(
      username: profile.username,
      aka: profile.aka ?? '',
      instagram: profile.instagram ?? '',
      email: currentEmail,
      displayAs: profile.displayAs,
      originalUsername: profile.username,
      originalEmail: currentEmail,
      originalAka: profile.aka ?? '',
      originalInstagram: profile.instagram ?? '',
      originalDisplayAs: profile.displayAs,
      hydrated: true,
      clearError: true,
    );
  }

  void setUsername(String v) =>
      state = state.copyWith(username: v, clearError: true);
  void setAka(String v) => state = state.copyWith(aka: v, clearError: true);
  void setEmail(String v) => state = state.copyWith(email: v, clearError: true);
  void setInstagram(String v) =>
      state = state.copyWith(instagram: v, clearError: true);
  void setDisplayAs(DisplayAs v) =>
      state = state.copyWith(displayAs: v, clearError: true);

  String? _validate() {
    final s = state;
    if (!usernameRegex.hasMatch(s.username.trim())) {
      return 'Nombre: 3 a 20 caracteres (letras, números o _)';
    }
    if (s.aka.trim().isNotEmpty && s.aka.trim().length > 20) {
      return 'A.K.A: máximo 20 caracteres';
    }
    if (!emailRegex.hasMatch(s.email.trim())) {
      return 'Correo inválido';
    }
    if (s.instagram.trim().isNotEmpty &&
        !instagramRegex.hasMatch(s.instagram.trim())) {
      return 'Instagram: solo letras, números, . o _ (1 a 30 caracteres)';
    }
    return null;
  }

  Future<EditProfileState> submit() async {
    final validation = _validate();
    if (validation != null) {
      state = state.copyWith(
        status: EditProfileStatus.error,
        errorMessage: validation,
      );
      return state;
    }
    if (!state.hasAnyChange) {
      return state;
    }

    state = state.copyWith(
      status: EditProfileStatus.saving,
      clearError: true,
      emailConfirmSent: false,
    );

    final uid = ref.read(currentUserIdProvider);
    if (uid == null) {
      state = state.copyWith(
        status: EditProfileStatus.error,
        errorMessage: 'Sesión expirada. Vuelve a iniciar sesión.',
      );
      return state;
    }

    var emailSent = false;
    String? profileError;
    String? emailError;

    if (state.hasProfileChanges) {
      try {
        final service = ref.read(profileServiceProvider);
        await service.update(
          uid: uid,
          username: state.username.trim(),
          aka: _nullable(state.aka),
          instagram: _nullable(state.instagram),
          displayAs: state.displayAs,
        );
        ref.invalidate(currentProfileProvider);
        state = state.copyWith(
          originalUsername: state.username.trim(),
          originalAka: state.aka.trim(),
          originalInstagram: state.instagram.trim(),
          originalDisplayAs: state.displayAs,
        );
      } catch (e) {
        final msg = e.toString();
        if (msg.contains('duplicate key') ||
            msg.contains('profiles_username_key')) {
          profileError = 'Ese nombre de usuario ya está en uso.';
        } else {
          profileError = msg;
        }
      }
    }

    if (state.hasEmailChange && profileError == null) {
      try {
        await ref.read(authRepositoryProvider).updateEmail(state.email.trim());
        emailSent = true;
      } catch (e) {
        emailError = e.toString();
      }
    }

    if (profileError != null || emailError != null) {
      state = state.copyWith(
        status: EditProfileStatus.error,
        errorMessage: profileError ?? emailError,
      );
      return state;
    }

    state = state.copyWith(
      status: EditProfileStatus.success,
      originalEmail: state.email.trim(),
      emailConfirmSent: emailSent,
      clearError: true,
    );
    return state;
  }
}

final editProfileViewModelProvider =
    NotifierProvider.autoDispose<EditProfileViewModel, EditProfileState>(
        EditProfileViewModel.new);

String? _nullable(String v) {
  final t = v.trim();
  return t.isEmpty ? null : t;
}
