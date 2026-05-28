abstract class AuthStorage {
  Future<String?> readToken();

  Future<void> writeToken(String token);

  Future<void> clear();
}
