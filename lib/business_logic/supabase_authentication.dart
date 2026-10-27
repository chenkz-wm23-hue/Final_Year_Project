import 'package:supabase_flutter/supabase_flutter.dart';

import 'authentication.dart';

class SupabaseAuthentication implements Authentication {
  const SupabaseAuthentication(this.client);
  final SupabaseClient client;
  @override
  Future<void> signIn(String email, String password) async {
    await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> register(String name, String email, String password) async {
    await client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': name.trim()},
    );
  }

  @override
  Future<void> signOut() => client.auth.signOut(scope: SignOutScope.local);
}
