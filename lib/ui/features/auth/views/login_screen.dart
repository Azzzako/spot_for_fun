import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:spot_for_fun/ui/core/router/app_router.dart';
import 'package:spot_for_fun/ui/core/theme/app_colors.dart';
import 'package:spot_for_fun/ui/features/auth/view_models/password_reset_view_model.dart';
import 'package:spot_for_fun/ui/features/auth/view_models/sign_in_view_model.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(signInViewModelProvider.notifier).signIn(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );
    if (!mounted) return;
    if (ok) {
      context.go(AppRoutes.map);
    }
  }

  Future<void> _signInWithGoogle() async {
    final ok =
        await ref.read(signInViewModelProvider.notifier).signInWithGoogle();
    if (!mounted) return;
    if (ok) context.go(AppRoutes.map);
  }

  void _openForgotPassword() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) =>
          _ForgotPasswordSheet(initialEmail: _emailCtrl.text.trim()),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signInViewModelProvider);
    final loading = state.status == AuthFormStatus.loading;
    final theme = Theme.of(context);

    ref.listen(signInViewModelProvider, (prev, next) {
      if (next.status == AuthFormStatus.error &&
          next.errorMessage != null &&
          prev?.errorMessage != next.errorMessage) {
        _showSnack(next.errorMessage!);
      }
    });

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 32),
                    Center(
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: AppColors.brandInk,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.skateboarding,
                          color: Colors.white,
                          size: 44,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'SPOT FOR FUN',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      'Bienvenido de vuelta',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Inicia sesión para continuar',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 28),
                    _AuthField(
                      controller: _emailCtrl,
                      label: 'Correo electrónico',
                      icon: Icons.alternate_email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Requerido';
                        }
                        if (!v.contains('@')) return 'Correo inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _AuthField(
                      controller: _passCtrl,
                      label: 'Contraseña',
                      icon: Icons.lock_outline,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requerido';
                        if (v.length < 6) return 'Mínimo 6 caracteres';
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: loading ? null : _openForgotPassword,
                        child: const Text('¿Olvidaste tu contraseña?'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 54,
                      child: FilledButton(
                        onPressed: loading ? null : _submit,
                        child: loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Iniciar sesión'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color:
                                theme.colorScheme.outline.withValues(alpha: 0.7),
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'o continuar con',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color:
                                theme.colorScheme.outline.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _SocialButton(
                      icon: Icons.g_mobiledata_rounded,
                      label: 'Continuar con Google',
                      enabled: !loading,
                      onPressed: _signInWithGoogle,
                    ),
                    const SizedBox(height: 10),
                    _SocialButton(
                      icon: Icons.apple,
                      label: 'Continuar con Apple (próximamente)',
                      enabled: false,
                      onPressed: null,
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: TextButton(
                        onPressed: loading
                            ? null
                            : () => context.push(AppRoutes.register),
                        child: RichText(
                          text: TextSpan(
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.7),
                            ),
                            children: const [
                              TextSpan(text: '¿No tienes cuenta? '),
                              TextSpan(
                                text: 'Regístrate',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ForgotPasswordSheet extends ConsumerStatefulWidget {
  const _ForgotPasswordSheet({required this.initialEmail});
  final String initialEmail;

  @override
  ConsumerState<_ForgotPasswordSheet> createState() =>
      _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends ConsumerState<_ForgotPasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _emailCtrl = TextEditingController(text: widget.initialEmail);

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(passwordResetViewModelProvider.notifier)
        .sendResetEmail(_emailCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(passwordResetViewModelProvider);
    final loading = state.status == AuthFormStatus.loading;
    final sent = state.status == AuthFormStatus.success;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 8,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              sent ? 'Revisa tu correo' : 'Recuperar contraseña',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              sent
                  ? 'Si hay una cuenta con ese correo, te enviamos un enlace '
                      'para cambiar la contraseña.'
                  : 'Te enviaremos un enlace para elegir una contraseña nueva.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.smartphone_rounded,
                    size: 20,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Abre el enlace desde este teléfono. Si lo abres en '
                      'una computadora no funcionará y tendrás que pedir '
                      'otro.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!sent) ...[
              const SizedBox(height: 16),
              _AuthField(
                controller: _emailCtrl,
                label: 'Correo electrónico',
                icon: Icons.alternate_email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requerido';
                  if (!v.contains('@')) return 'Correo inválido';
                  return null;
                },
              ),
            ],
            if (state.status == AuthFormStatus.error &&
                state.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                state.errorMessage!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: loading
                  ? null
                  : sent
                      ? () => Navigator.of(context).pop()
                      : _send,
              child: Text(
                loading
                    ? 'Enviando…'
                    : sent
                        ? 'Entendido'
                        : 'Enviar enlace',
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.autofillHints,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final FormFieldValidator<String> validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      autofillHints: autofillHints,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      style: theme.textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
      ),
      validator: validator,
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = enabled
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurface.withValues(alpha: 0.4);
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: fg,
          side: BorderSide(
            color: theme.colorScheme.outline,
            width: 1.2,
          ),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 22, color: fg),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: fg,
          ),
        ),
      ),
    );
  }
}
