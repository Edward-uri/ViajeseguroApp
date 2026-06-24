import '../../../../core/http/api_client.dart';
import '../../../../core/routes/routes.dart';

class AuthApi {
  AuthApi(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> registerStart({
    required String correo,
    String rol = UserRole.defaultRole,
  }) =>
      _api.post(ApiRoutes.registerStart, body: <String, dynamic>{
        'correo': correo,
        'rol': rol,
      });

  Future<Map<String, dynamic>> registerVerify({
    required String correo,
    required String codigo,
    String rol = UserRole.defaultRole,
  }) =>
      _api.post(ApiRoutes.registerVerify, body: <String, dynamic>{
        'correo': correo,
        'codigo': codigo,
        'rol': rol,
      });

  Future<Map<String, dynamic>> registerComplete(Map<String, dynamic> body) =>
      _api.post(ApiRoutes.registerComplete, body: body);

  Future<Map<String, dynamic>> loginWithPassword({
    required String correo,
    required String contrasena,
    String? dispositivo,
  }) =>
      _api.post(ApiRoutes.loginPassword, body: <String, dynamic>{
        'correo': correo,
        'password': contrasena,
        if (dispositivo != null) 'dispositivo': dispositivo,
      });

  Future<Map<String, dynamic>> refresh({required String refreshToken}) =>
      _api.post(ApiRoutes.refresh, body: <String, dynamic>{
        'refreshToken': refreshToken,
      });

  Future<Map<String, dynamic>> logout({required String refreshToken}) =>
      _api.post(ApiRoutes.logout, body: <String, dynamic>{
        'refreshToken': refreshToken,
      });
}
