import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'auth_storage.dart';


class SecureAuthStorage implements AuthStorage {
  SecureAuthStorage()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
        );

  final FlutterSecureStorage _storage;

  static const String _tokenKey = 'jwt';

  @override
  Future<String?> readToken() => _storage.read(key: _tokenKey);

  @override
  Future<void> writeToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  @override
  Future<void> clear() => _storage.delete(key: _tokenKey);
}
