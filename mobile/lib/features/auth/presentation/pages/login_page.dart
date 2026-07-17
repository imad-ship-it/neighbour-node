import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/validators.dart';
import '../bloc/auth_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    context.read<AuthBloc>().add(
          LoginSubmitted(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: BlocConsumer<AuthBloc, AuthState>(
                listener: (context, state) {
                  // Field-level errors render under inputs; anything else
                  // (bad credentials, network) surfaces as a snackbar.
                  if (state is AuthError && state.fieldErrors.isEmpty) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(content: Text(state.message)));
                  }
                },
                builder: (context, state) {
                  final loading = state is AuthLoading;
                  final error = state is AuthError ? state : null;
                  return Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(Icons.holiday_village_rounded,
                            size: 56, color: scheme.primary),
                        const SizedBox(height: 16),
                        Text(
                          'Welcome back',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sign in to keep sharing with your neighbourhood',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 32),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _emailController,
                                  enabled: !loading,
                                  keyboardType: TextInputType.emailAddress,
                                  autofillHints: const [AutofillHints.email],
                                  validator: Validators.email,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: const Icon(Icons.alternate_email),
                                    errorText: error?.fieldError('email'),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _passwordController,
                                  enabled: !loading,
                                  obscureText: _obscurePassword,
                                  autofillHints: const [AutofillHints.password],
                                  validator: Validators.password,
                                  onFieldSubmitted: (_) => _submit(),
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    errorText: error?.fieldError('password'),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined),
                                      onPressed: () => setState(() =>
                                          _obscurePassword = !_obscurePassword),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                FilledButton(
                                  onPressed: loading ? null : _submit,
                                  child: loading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2.4),
                                        )
                                      : const Text('Sign in'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextButton(
                          onPressed:
                              loading ? null : () => context.go('/register'),
                          child: const Text('New here? Create an account'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
