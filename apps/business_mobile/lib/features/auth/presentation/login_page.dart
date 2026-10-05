import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool loading = false;
  String? error;

  Future<void> submit() async {
    FocusScope.of(context).unfocus();

    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        error = 'Email dan password wajib diisi.';
      });
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .login(email: email, password: password);

      if (!mounted) {
        return;
      }

      ref.invalidate(authStateProvider);

      context.go('/dashboard');
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        error = _loginErrorMessage(e);
      });

      debugPrint('LOGIN ERROR: $e');
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  String _loginErrorMessage(Object error) {
    final message = error.toString();

    if (message.contains('INVALID_CREDENTIALS')) {
      return 'Email atau password salah.';
    }

    if (message.contains('401')) {
      return 'Email atau password salah.';
    }

    if (message.contains('404')) {
      return 'Endpoint login tidak ditemukan.';
    }

    if (message.contains('Failed to fetch') ||
        message.contains('XMLHttpRequest') ||
        message.contains('Network')) {
      return 'Tidak dapat terhubung ke server.';
    }

    if (message.contains('CORS')) {
      return 'Koneksi browser diblokir oleh CORS.';
    }

    return 'Login gagal. Silakan coba lagi.';
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                elevation: 2,
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        height: 120,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.business_center_rounded,
                            size: 64,
                            color: scheme.primary,
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      Text(
                        'Selamat datang kembali',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'Kelola bisnis Anda dalam satu platform.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),

                      const SizedBox(height: 28),

                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [
                          AutofillHints.username,
                          AutofillHints.email,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onSubmitted: (_) {
                          if (!loading) {
                            submit();
                          }
                        },
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                      ),

                      if (error != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: scheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      FilledButton(
                        onPressed: loading ? null : submit,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: loading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'Masuk',
                                  style: TextStyle(fontWeight: FontWeight.w700),
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
      ),
    );
  }
}
