import '../../../core/http/api_exception.dart';
import '../../../core/storage/auth_storage.dart';
import '../../../shared/data/mappers/user_mapper.dart';
import '../../../shared/domain/entities/user.dart';
import '../domain/entities/register_params.dart';
import '../domain/repositories/auth_repository.dart';
import 'mappers/register_params_mapper.dart';
import 'remote/auth_api.dart';


class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._api, this._storage);

  final AuthApi _api;
  final AuthStorage _storage;

  @override
  Future<User> login({
    required String identifier,
    required String password,
  }) async {
    final response = await _api.login(
      identifier: identifier,
      password: password,
    );
    return _persistAndParse(response);
  }

  @override
  Future<User> register(RegisterParams params) async {
    final response = await _api.register(RegisterParamsMapper.toJson(params));
    return _persistAndParse(response);
  }

  @override
  Future<void> logout() => _storage.clear();

  @override
  Future<bool> hasSession() async {
    final token = await _storage.readToken();
    return token != null && token.isNotEmpty;
  }


  Future<User> _persistAndParse(Map<String, dynamic> response) async {
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw ApiException('Respuesta inesperada del servidor');
    }
    final token = data['token'];
    final userJson = data['user'];
    if (token is! String || userJson is! Map<String, dynamic>) {
      throw ApiException('Respuesta inesperada del servidor');
    }
    await _storage.writeToken(token);
    return UserMapper.fromJson(userJson);
  }
}
