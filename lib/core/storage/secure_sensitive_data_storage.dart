import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'sensitive_data_storage.dart';


class SecureSensitiveDataStorage implements SensitiveDataStorage {
  SecureSensitiveDataStorage()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
        );

  final FlutterSecureStorage _storage;

  static const String _usernameKey = 'sensitive_username';
  static const String _emailKey = 'sensitive_email';
  static const String _phoneKey = 'sensitive_phone';
  static const String _sessionTokenKey = 'sensitive_session_token';
  static const String _userIdKey = 'sensitive_user_id';

  static const List<String> _allKeys = <String>[
    _usernameKey,
    _emailKey,
    _phoneKey,
    _sessionTokenKey,
    _userIdKey,
  ];

  @override
  Future<void> writeAll({
    required String username,
    required String email,
    required String phone,
    required String sessionToken,
    required String userId,
  }) async {
    await _storage.write(key: _usernameKey, value: username);
    await _storage.write(key: _emailKey, value: email);
    await _storage.write(key: _phoneKey, value: phone);
    await _storage.write(key: _sessionTokenKey, value: sessionToken);
    await _storage.write(key: _userIdKey, value: userId);
  }

  @override
  Future<String?> readUsername() => _storage.read(key: _usernameKey);

  @override
  Future<String?> readEmail() => _storage.read(key: _emailKey);

  @override
  Future<String?> readPhone() => _storage.read(key: _phoneKey);

  @override
  Future<String?> readSessionToken() => _storage.read(key: _sessionTokenKey);

  @override
  Future<String?> readUserId() => _storage.read(key: _userIdKey);

  @override
  Future<bool> isEmpty() async {
    final username = await _storage.read(key: _usernameKey);
    return username == null || username.isEmpty;
  }

  @override
  Future<void> clear() async {
    for (final key in _allKeys) {
      await _storage.delete(key: key);
    }
  }
}
