import 'package:supabase_flutter/supabase_flutter.dart';

import 'authentication.dart';

class SupabaseAuthentication implements Authentication {
  SupabaseAuthentication(this.client);
  final SupabaseClient client;
  bool registrationRequiresLogin = false;
  bool confirmationRequired = false;
  @override
  Future<void> signIn(String email, String password) async {
    registrationRequiresLogin = false;
    await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> register(String name, String email, String password) async {
    registrationRequiresLogin = true;
    final result = await client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': name.trim(), 'onboarding_required': true},
    );
    confirmationRequired = result.session == null;
    // Even projects with auto-confirm enabled must return to explicit Login.
    if (result.session != null) await signOut();
  }

  @override
  Future<void> signOut() => client.auth.signOut(scope: SignOutScope.local);
}
