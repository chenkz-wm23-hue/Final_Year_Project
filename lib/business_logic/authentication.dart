/// Contract for account registration and authenticated sessions.
abstract interface class Authentication {
  Future<void> signIn(String email, String password);
  Future<void> register(String name, String email, String password);
  Future<void> signOut();
}
