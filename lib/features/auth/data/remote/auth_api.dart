import '../../../../core/http/api_client.dart';


class AuthApi {
  AuthApi(this._api);

  final ApiClient _api;

  static const String _registerPath = '/api/auth/register';
  static const String _loginPath = '/api/auth/login';

  Future<Map<String, dynamic>> register(Map<String, dynamic> body) =>
      _api.post(_registerPath, body: body);

  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) =>
      _api.post(_loginPath, body: <String, dynamic>{
        'identifier': identifier,
        'password': password,
      });
}
