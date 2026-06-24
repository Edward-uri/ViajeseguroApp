import 'dart:convert';

import '../../../core/http/api_exception.dart';
import '../../../core/storage/auth_storage.dart';
import '../../../shared/data/mappers/user_mapper.dart';
import '../../../shared/domain/entities/user.dart';
import '../domain/entities/register_params.dart';
import '../domain/repositories/auth_repository.dart';
import 'mappers/register_params_mapper.dart';
import 'remote/auth_api.dart';
import 'remote/dispositivos_api.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._api, this._storage, this._dispositivosApi);

  final AuthApi _api;
  final AuthStorage _storage;
  final DispositivosApi _dispositivosApi;

  @override
  Future<void> registerStart({required String correo, String rol = 'pasajero'}) async {
    await _api.registerStart(correo: correo, rol: rol);
  }

  @override
  Future<String> registerVerify({
    required String correo,
    required String codigo,
    String rol = 'pasajero',
  }) async {
    final response = await _api.registerVerify(
      correo: correo,
      codigo: codigo,
      rol: rol,
    );
    final token = response['registrationToken'];
    if (token is! String) {
      throw ApiException('Respuesta inesperada del servidor');
    }
    return token;
  }

  @override
  Future<User> registerComplete(RegisterParams params) async {
    final response = await _api.registerComplete(RegisterParamsMapper.toJson(params));
    return _persistAndParseSession(response);
  }

  @override
  Future<User> loginWithPassword({
    required String correo,
    required String contrasena,
    String? dispositivo,
  }) async {
    final response = await _api.loginWithPassword(
      correo: correo,
      contrasena: contrasena,
      dispositivo: dispositivo,
    );
    return _persistAndParseSession(response);
  }

  @override
  Future<void> logout({String? refreshToken}) async {
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await _api.logout(refreshToken: refreshToken);
      } catch (_) {}
    }
    await _storage.clear();
  }

  @override
  Future<bool> hasSession() async {
    final token = await _storage.readToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<User?> getCurrentUser() async {
    final userJson = await _storage.readUser();
    if (userJson == null || userJson.isEmpty) return null;
    try {
      final decoded = jsonDecode(userJson) as Map<String, dynamic>;
      return UserMapper.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> registrarDispositivo({
    required String plataforma,
    required String version,
    String? modelo,
    String? tokenPush,
  }) async {
    try {
      await _dispositivosApi.registrar(
        plataforma: plataforma,
        version: version,
        modelo: modelo,
        tokenPush: tokenPush,
      );
    } catch (_) {
    }
  }

  Future<User> _persistAndParseSession(Map<String, dynamic> response) async {
    final accessToken = response['accessToken'];
    final refreshToken = response['refreshToken'];
    final userJson = response['user'];
    if (accessToken is! String) {
      throw ApiException('Respuesta inesperada del servidor');
    }

    final User user;
    if (userJson is Map<String, dynamic>) {
      user = UserMapper.fromJson(userJson);
    } else {
      throw ApiException('Respuesta inesperada del servidor');
    }

    await _storage.writeToken(accessToken);
    if (refreshToken is String) {
      await _storage.writeRefreshToken(refreshToken);
    }
    await _storage.writeUser(jsonEncode(UserMapper.toJson(user)));
    return user;
  }
}
