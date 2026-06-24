abstract class AuthStorage {
  Future<String?> readToken();

  Future<void> writeToken(String token);

  Future<String?> readRefreshToken();

  Future<void> writeRefreshToken(String token);

  Future<String?> readUser();

  Future<void> writeUser(String userJson);

  Future<void> clear();
}
