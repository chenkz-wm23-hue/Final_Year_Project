import 'package:flutter/material.dart';

import '../widgets/auth_frame.dart';
import '../widgets/app_field.dart';
import '../app_shell.dart';
import 'register_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) => AuthFrame(
    illustration: '💼',
    title: 'Welcome Back!',
    subtitle: 'Login to continue',
    fields: const [
      AppField(
        label: 'Email',
        hint: 'Enter your email',
        icon: Icons.mail_outline,
      ),
      AppField(
        label: 'Password',
        hint: 'Enter your password',
        icon: Icons.lock_outline,
        obscure: true,
      ),
    ],
    action: 'Login',
    onAction: () => Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => const AppShell())),
    footer: 'Don’t have an account?',
    link: ' Register',
    onLink: (c) => Navigator.push(
      c,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    ),
  );
}
