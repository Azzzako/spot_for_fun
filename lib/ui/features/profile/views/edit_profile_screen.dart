import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:spot_for_fun/data/repositories/auth_provider.dart';
import 'package:spot_for_fun/domain/enums.dart';
import 'package:spot_for_fun/ui/features/profile/view_models/edit_profile_view_model.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _akaCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();

  bool _hydrated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final profileAsync = ref.read(currentProfileProvider);
      final email = ref.read(currentUserEmailProvider) ?? '';
      final profile = profileAsync.valueOrNull;
      if (profile != null) {
        ref
            .read(editProfileViewModelProvider.notifier)
            .hydrate(profile: profile, currentEmail: email);
        _usernameCtrl.text = profile.username;
        _akaCtrl.text = profile.aka ?? '';
        _emailCtrl.text = email;
        _instagramCtrl.text = profile.instagram ?? '';
      }
      if (mounted) setState(() => _hydrated = true);
    });
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _akaCtrl.dispose();
    _emailCtrl.dispose();
    _instagramCtrl.dispose();
    super.dispose();
  }

  void _syncControllers(EditProfileState s) {
    if (_usernameCtrl.text != s.username) _usernameCtrl.text = s.username;
    if (_akaCtrl.text != s.aka) _akaCtrl.text = s.aka;
    if (_emailCtrl.text != s.email) _emailCtrl.text = s.email;
    if (_instagramCtrl.text != s.instagram) {
      _instagramCtrl.text = s.instagram;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final vm = ref.read(editProfileViewModelProvider.notifier);
    final result = await vm.submit();
    if (!mounted) return;
    if (result.status == EditProfileStatus.success) {
      _snack(_successMessage(result));
      if (!result.hasEmailChange || result.emailConfirmSent) {
        if (Navigator.of(context).canPop()) {
          context.pop();
        }
      }
    } else if (result.status == EditProfileStatus.error &&
        result.errorMessage != null) {
      _snack(result.errorMessage!);
    }
  }

  String _successMessage(EditProfileState s) {
    if (s.hasEmailChange && s.hasProfileChanges) {
      return 'Perfil actualizado. Te enviamos un link al nuevo correo.';
    }
    if (s.hasEmailChange) {
      return 'Te enviamos un link al nuevo correo para confirmarlo.';
    }
    return 'Perfil actualizado';
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(editProfileViewModelProvider);
    _syncControllers(state);

    if (!_hydrated) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          backgroundColor: theme.colorScheme.surface,
          title: const Text('Editar perfil'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final akaMissing = state.aka.trim().isEmpty;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        title: const Text('Editar perfil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Label('Nombre'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _usernameCtrl,
                decoration: const InputDecoration(
                  hintText: 'Cómo te identifican en la app',
                ),
                maxLength: 20,
                textInputAction: TextInputAction.next,
                onChanged: (v) => ref
                    .read(editProfileViewModelProvider.notifier)
                    .setUsername(v),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requerido';
                  if (!usernameRegex.hasMatch(v.trim())) {
                    return '3 a 20 caracteres (letras, números o _)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _Label('A.K.A'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _akaCtrl,
                decoration: const InputDecoration(
                  hintText: 'Tu apodo o nombre artístico (opcional)',
                ),
                maxLength: 20,
                textInputAction: TextInputAction.next,
                onChanged: (v) =>
                    ref.read(editProfileViewModelProvider.notifier).setAka(v),
                validator: (v) {
                  if (v == null) return null;
                  final t = v.trim();
                  if (t.isEmpty) return null;
                  if (t.length > 20) return 'Máximo 20 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _Label('Correo'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  hintText: 'tu@correo.com',
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onChanged: (v) =>
                    ref.read(editProfileViewModelProvider.notifier).setEmail(v),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requerido';
                  if (!emailRegex.hasMatch(v.trim())) return 'Correo inválido';
                  return null;
                },
              ),
              if (state.hasEmailChange)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Te enviaremos un link al nuevo correo para confirmarlo.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              _Label('Instagram'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _instagramCtrl,
                decoration: const InputDecoration(
                  hintText: 'usuario (sin @)',
                ),
                maxLength: 30,
                textInputAction: TextInputAction.done,
                onChanged: (v) => ref
                    .read(editProfileViewModelProvider.notifier)
                    .setInstagram(v),
                validator: (v) {
                  if (v == null) return null;
                  final t = v.trim();
                  if (t.isEmpty) return null;
                  if (!instagramRegex.hasMatch(t)) {
                    return 'Solo letras, números, . o _';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _Label('Mostrar como'),
              const SizedBox(height: 8),
              SegmentedButton<DisplayAs>(
                segments: const [
                  ButtonSegment(
                    value: DisplayAs.username,
                    label: Text('Nombre'),
                    icon: Icon(Icons.person_outline),
                  ),
                  ButtonSegment(
                    value: DisplayAs.aka,
                    label: Text('A.K.A'),
                    icon: Icon(Icons.alternate_email),
                  ),
                ],
                selected: {state.displayAs},
                onSelectionChanged: (set) {
                  ref
                      .read(editProfileViewModelProvider.notifier)
                      .setDisplayAs(set.first);
                },
              ),
              if (state.displayAs == DisplayAs.aka && akaMissing)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Sin A.K.A guardado: se mostrará tu nombre hasta que lo llenes.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                ),
              if (state.errorMessage != null &&
                  state.status == EditProfileStatus.error)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _Banner(
                    icon: Icons.error_outline,
                    text: state.errorMessage!,
                  ),
                ),
              const SizedBox(height: 20),
              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed:
                      state.isSaving ? null : () => _submit(),
                  child: state.isSaving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Guardar cambios'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
