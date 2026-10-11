/// Contract for a future authentication implementation.
/// Login currently remains a demo entry flow, not credential verification.
abstract interface class Authentication {
  Future<void> signIn(String email, String password);
  Future<void> register(String name, String email, String password);
  Future<void> signOut();
}
