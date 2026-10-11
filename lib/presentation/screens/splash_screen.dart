import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'login_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5B4EF2), Color(0xFF2D70D8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 3),
            const Text('🐷', style: TextStyle(fontSize: 96)),
            const SizedBox(height: 18),
            const Text(
              'Smart\nExpense Tracker',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 31,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Manage your money smarter',
              style: TextStyle(color: Color(0xFFE9E7FF), fontSize: 15),
            ),
            const Spacer(flex: 3),
            Padding(
              padding: const EdgeInsets.all(28),
              child: SizedBox(
                width: 56,
                child: Divider(
                  color: Colors.white.withValues(alpha: .8),
                  thickness: 4,
                ),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: appIndigo,
                minimumSize: const Size(160, 48),
              ),
              child: const Text('Get started'),
            ),
            const SizedBox(height: 34),
          ],
        ),
      ),
    ),
  );
}
