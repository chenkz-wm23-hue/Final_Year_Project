import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../state/auth_scope.dart';
import '../widgets/async_button.dart';
import 'register_screen.dart';

class AuthFormScreen extends StatefulWidget {
  const AuthFormScreen({
    super.key,
    this.register = false,
    this.initialEmail = '',
    this.initialNotice,
  });
  final bool register;
  final String initialEmail;
  final String? initialNotice;
  @override
  State<AuthFormScreen> createState() => _AuthFormScreenState();
}

class _AuthFormScreenState extends State<AuthFormScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      email = TextEditingController(),
      password = TextEditingController(),
      confirm = TextEditingController();
  bool hidden = true;
  String? notice;
  String? loginError;
  void clearLoginError(String _) {
    if (loginError != null) setState(() => loginError = null);
  }

  @override
  void initState() {
    super.initState();
    email.text = widget.initialEmail;
    notice = widget.initialNotice;
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.maybeOf(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(
                      child: CircleAvatar(
                        radius: 48,
                        child: Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 48,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      widget.register ? 'Create Account' : 'Welcome Back!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (widget.register) ...[
                      TextFormField(
                        controller: name,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Enter your name'
                            : null,
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: email,
                      forceErrorText: loginError,
                      onChanged: clearLoginError,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline),
                        border: OutlineInputBorder(),
                        errorMaxLines: 3,
                      ),
                      validator: (v) =>
                          RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                              .hasMatch(v?.trim() ?? '')
                          ? null
                          : 'Enter a valid email',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: password,
                      onChanged: clearLoginError,
                      obscureText: hidden,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: hidden ? 'Show password' : 'Hide password',
                          onPressed: () => setState(() => hidden = !hidden),
                          icon: Icon(
                            hidden
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Enter your password'
                          : widget.register && v.length < 8
                          ? 'Use at least 8 characters'
                          : null,
                    ),
                    if (widget.register) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: confirm,
                        obscureText: hidden,
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: const InputDecoration(
                          labelText: 'Confirm Password',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v != password.text
                            ? 'Passwords do not match'
                            : null,
                      ),
                    ],
                    if (notice != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          notice!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    AsyncButton(
                      label: widget.register ? 'Register' : 'Login',
                      onPressed: () async {
                        if (!form.currentState!.validate()) return;
                        if (auth == null) {
                          setState(
                            () => notice = 'Authentication is unavailable in this preview.',
                          );
                          return;
                        }
                        if (widget.register) {
                          await auth.register(
                            name.text,
                            email.text,
                            password.text,
                          );
                          if (context.mounted) {
                            final registeredEmail = email.text.trim();
                            final needsConfirmation = auth.confirmationRequired;
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => AuthFormScreen(
                                  initialEmail: registeredEmail,
                                  initialNotice: needsConfirmation
                                      ? 'Registration submitted. Check your email to confirm your account, then log in. If already registered, use your existing password.'
                                      : 'Registration successful. Please log in to set up your account.',
                                ),
                              ),
                              (_) => false,
                            );
                          }
                        } else {
                          final submittedEmail = email.text;
                          final submittedPassword = password.text;
                          try {
                            await auth.signIn(
                              submittedEmail,
                              submittedPassword,
                            );
                          } on AuthException catch (error) {
                            if (error.code != 'invalid_credentials') rethrow;
                            if (mounted &&
                                email.text == submittedEmail &&
                                password.text == submittedPassword) {
                              setState(
                                () => loginError = 'Invalid email or password. Check your details or register a new account.',
                              );
                            }
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        if (widget.register) {
                          Navigator.pop(context);
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          );
                        }
                      },
                      child: Text(
                        widget.register
                            ? 'Already have an account? Login'
                            : 'Don’t have an account? Register',
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
