import 'package:flutter/material.dart';

import '../state/expense_store.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final store = ExpenseScope.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Center(
          child: CircleAvatar(radius: 45, child: Icon(Icons.person, size: 48)),
        ),
        const SizedBox(height: 16),
        Text(
          store.name,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(store.email, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        ListTile(
          leading: const Icon(Icons.edit_outlined),
          title: const Text('Edit Profile'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EditProfileScreen()),
          ),
        ),
        if (store.phone.isNotEmpty)
          ListTile(
            leading: const Icon(Icons.phone_outlined),
            title: Text(store.phone),
          ),
        if (store.address.isNotEmpty)
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: Text(store.address),
          ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('About this app'),
          onTap: () => showAboutDialog(
            context: context,
            applicationName: 'Smart Expense Tracker',
            applicationVersion: '1.0',
            children: [
              const Text(
                'A local demo for tracking income, spending and budgets. Changes are kept only while the app is running.',
              ),
            ],
          ),
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Logout'),
          onTap: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Leave the demo?'),
                content: const Text(
                  'Your temporary entries will remain until the app closes.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Logout'),
                  ),
                ],
              ),
            );
            if (confirmed == true && context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            }
          },
        ),
      ],
    );
  }
}
