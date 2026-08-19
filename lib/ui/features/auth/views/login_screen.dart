import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:spot_for_fun/ui/core/router/app_router.dart';
import 'package:spot_for_fun/ui/features/auth/view_models/sign_in_view_model.dart';

const Color _kBrand = Color(0xFF8FA661);
const Color _kInputFill = Color(0x1AFFFFFF);
const Color _kInputBorder = Color(0x3DFFFFFF);

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

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signInViewModelProvider);
    final loading = state.status == AuthFormStatus.loading;

    ref.listen(signInViewModelProvider, (prev, next) {
      if (next.status == AuthFormStatus.error &&
          next.errorMessage != null &&
          prev?.errorMessage != next.errorMessage) {
        _showSnack(next.errorMessage!);
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/identity/background.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x00000000),
                  Color(0x4D000000),
                  Color(0xA6000000),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Image.asset(
                                  'assets/identity/logo.png',
                                  height: 104,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(height: 12),
                               
                                const SizedBox(height: 24),
                                _EmailField(
                                  controller: _emailCtrl,
                                  compact: true,
                                ),
                                const SizedBox(height: 10),
                                _PasswordField(
                                  controller: _passCtrl,
                                  onSubmitted: (_) => _submit(),
                                  compact: true,
                                ),
                                const SizedBox(height: 18),
                                _PrimaryButton(
                                  label: 'Entrar',
                                  loading: loading,
                                  onPressed: _submit,
                                  compact: true,
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    const Expanded(
                                      child:
                                          Divider(color: _kInputBorder),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Text(
                                        'o',
                                        style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.5),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const Expanded(
                                      child:
                                          Divider(color: _kInputBorder),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                _SocialOutlineButton(
                                  icon: Icons.g_mobiledata_rounded,
                                  label: 'Continuar con Google',
                                  enabled: !loading,
                                  onPressed: _submit,
                                  compact: true,
                                ),
                                const SizedBox(height: 8),
                                _SocialOutlineButton(
                                  icon: Icons.apple,
                                  label: 'Continuar con Apple (próximamente)',
                                  enabled: false,
                                  onPressed: null,
                                  compact: true,
                                ),
                                const SizedBox(height: 12),
                                Center(
                                  child: TextButton(
                                    onPressed: loading
                                        ? null
                                        : () =>
                                            context.push(AppRoutes.register),
                                    child: RichText(
                                      text: TextSpan(
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13.5,
                                        ),
                                        children: [
                                          const TextSpan(
                                            text: '¿No tienes cuenta? ',
                                          ),
                                          TextSpan(
                                            text: 'Crear una',
                                            style: TextStyle(
                                              color: _kBrand,
                                              fontWeight: FontWeight.w700,
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
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmailField extends StatelessWidget {
  const _EmailField({required this.controller, this.compact = false});
  final TextEditingController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
      style: const TextStyle(color: Colors.white),
      cursorColor: _kBrand,
      decoration: _inputDecoration(
        label: 'Correo',
        icon: Icons.alternate_email,
        compact: compact,
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Requerido';
        if (!v.contains('@')) return 'Correo inválido';
        return null;
      },
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.onSubmitted,
    this.compact = false,
  });
  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      autofillHints: const [AutofillHints.password],
      style: const TextStyle(color: Colors.white),
      cursorColor: _kBrand,
      onFieldSubmitted: onSubmitted,
      decoration: _inputDecoration(
        label: 'Contraseña',
        icon: Icons.lock_outline,
        compact: compact,
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Requerido';
        if (v.length < 6) return 'Mínimo 6 caracteres';
        return null;
      },
    );
  }
}

InputDecoration _inputDecoration({
  required String label,
  required IconData icon,
  bool compact = false,
}) {
  const labelStyle = TextStyle(color: Colors.white70);
  return InputDecoration(
    labelText: label,
    labelStyle: labelStyle,
    floatingLabelBehavior: FloatingLabelBehavior.auto,
    floatingLabelStyle: const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w600,
    ),
    prefixIcon: Icon(icon, color: Colors.white60),
    filled: true,
    fillColor: _kInputFill,
    contentPadding: EdgeInsets.symmetric(
      horizontal: 16,
      vertical: compact ? 14 : 18,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _kInputBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _kInputBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _kBrand, width: 1.6),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.6),
    ),
    errorStyle: const TextStyle(color: Color(0xFFFF7A7A)),
  );
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.loading,
    required this.onPressed,
    this.compact = false,
  });
  final String label;
  final bool loading;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? 46 : 52,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: _kBrand,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _kBrand.withValues(alpha: 0.55),
          disabledForegroundColor: Colors.white70,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: loading ? null : onPressed,
        child: loading
            ? SizedBox(
                height: compact ? 18 : 22,
                width: compact ? 18 : 22,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  fontSize: compact ? 15 : 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
      ),
    );
  }
}

class _SocialOutlineButton extends StatelessWidget {
  const _SocialOutlineButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onPressed,
    this.compact = false,
  });
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback? onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final borderColor = Colors.white.withValues(alpha: 0.55);
    final textColor = enabled ? Colors.white : Colors.white38;
    final iconColor = enabled ? Colors.white : Colors.white38;
    return SizedBox(
      height: compact ? 44 : 52,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor,
          side: BorderSide(
            color: borderColor,
            width: 1.2,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 16,
            vertical: compact ? 8 : 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: compact ? 20 : 22, color: iconColor),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: compact ? 14 : 15,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
