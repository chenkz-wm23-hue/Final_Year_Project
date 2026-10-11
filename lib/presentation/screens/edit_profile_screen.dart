import 'package:flutter/material.dart';

import '../state/expense_store.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      email = TextEditingController(),
      phone = TextEditingController(),
      address = TextEditingController();
  bool loaded = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!loaded) {
      final s = ExpenseScope.of(context);
      name.text = s.name;
      email.text = s.email;
      phone.text = s.phone;
      address.text = s.address;
      loaded = true;
    }
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    phone.dispose();
    address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Edit Profile')),
    body: Form(
      key: form,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextFormField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Full name'),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Enter your name' : null,
          ),
          TextFormField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
            validator: (v) =>
                RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v?.trim() ?? '')
                ? null
                : 'Enter a valid email',
          ),
          TextFormField(
            controller: phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone number'),
          ),
          TextFormField(
            controller: address,
            decoration: const InputDecoration(labelText: 'Address'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                ExpenseScope.of(context).updateProfile(
                  name.text,
                  email.text,
                  phone.text,
                  address.text,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    ),
  );
}
