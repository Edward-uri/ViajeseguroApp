abstract class SensitiveDataStorage {
  Future<void> writeAll({
    required String username,
    required String email,
    required String phone,
    required String sessionToken,
    required String userId,
  });

  Future<String?> readUsername();

  Future<String?> readEmail();

  Future<String?> readPhone();

  Future<String?> readSessionToken();

  Future<String?> readUserId();

  Future<bool> isEmpty();

  Future<void> clear();
}
