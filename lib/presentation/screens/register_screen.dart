import 'package:flutter/material.dart';

import '../widgets/auth_frame.dart';
import '../widgets/app_field.dart';
import '../app_shell.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});
  @override
  Widget build(BuildContext context) => AuthFrame(
    illustration: '👜',
    title: 'Create Account',
    subtitle: 'Sign up to get started',
    fields: const [
      AppField(
        label: 'Full Name',
        hint: 'Enter your full name',
        icon: Icons.person_outline,
      ),
      AppField(
        label: 'Email',
        hint: 'Enter your email',
        icon: Icons.mail_outline,
      ),
      AppField(
        label: 'Password',
        hint: 'Create a password',
        icon: Icons.lock_outline,
        obscure: true,
      ),
      AppField(
        label: 'Confirm Password',
        hint: 'Confirm your password',
        icon: Icons.lock_outline,
        obscure: true,
      ),
    ],
    action: 'Register',
    onAction: () => Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AppShell()),
      (_) => false,
    ),
    footer: 'Already have an account?',
    link: ' Login',
    onLink: (c) => Navigator.pop(c),
  );
}
