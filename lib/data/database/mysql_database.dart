/// Architecture placeholder only. No connection, credentials or MySQL driver.
/// A future backend should own MySQL access and expose an authenticated API;
/// the mobile application should never contain database credentials.
abstract interface class MySqlDatabase {
  Future<void> connect();
  Future<void> close();
}
