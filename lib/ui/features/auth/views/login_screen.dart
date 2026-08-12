import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:spot_for_fun/ui/core/router/app_router.dart';
import 'package:spot_for_fun/ui/features/auth/view_models/sign_in_view_model.dart';
import 'package:spot_for_fun/ui/shared/widgets/brand_logo.dart';

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
    final theme = Theme.of(context);

    ref.listen(signInViewModelProvider, (prev, next) {
      if (next.status == AuthFormStatus.error &&
          next.errorMessage != null &&
          prev?.errorMessage != next.errorMessage) {
        _showSnack(next.errorMessage!);
      }
    });

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/identity/login_bg.png',
              fit: BoxFit.cover,
              alignment: Alignment.centerLeft,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.45),
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.65),
                    Colors.black.withValues(alpha: 0.85),
                  ],
                  stops: const [0.0, 0.4, 0.8, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),
                        const Center(child: BrandLogo(size: 160)),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          style: TextStyle(color: theme.colorScheme.onSurface),
                          decoration: const InputDecoration(
                            labelText: 'Correo',
                            prefixIcon: Icon(Icons.alternate_email),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Requerido';
                            }
                            if (!v.contains('@')) return 'Correo inválido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passCtrl,
                          obscureText: true,
                          autofillHints: const [AutofillHints.password],
                          style: TextStyle(color: theme.colorScheme.onSurface),
                          decoration: const InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Requerido';
                            if (v.length < 6) return 'Mínimo 6 caracteres';
                            return null;
                          },
                          onFieldSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: loading ? null : _submit,
                          child: loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Entrar'),
                        ),
                        const SizedBox(height: 12),
                        const Row(
                          children: [
                            Expanded(child: Divider()),
                            Padding(
                              padding:
                                  EdgeInsets.symmetric(horizontal: 12),
                              child: Text('o'),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: loading ? null : _submit,
                          icon: const Icon(Icons.g_mobiledata, size: 28),
                          label: const Text('Continuar con Google'),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          // TODO: Apple Sign-In — habilitar cuando se configure la Apple Developer account.
                          onPressed: null,
                          icon: const Icon(Icons.apple, size: 22),
                          label: const Text(
                            'Continuar con Apple (próximamente)',
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextButton(
                          onPressed: loading
                              ? null
                              : () => context.push(AppRoutes.register),
                          child: const Text('¿No tienes cuenta? Crear una'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}