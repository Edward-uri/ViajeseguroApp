import '../../../../core/http/api_client.dart';
import '../../../../core/routes/routes.dart';

class DispositivosApi {
  DispositivosApi(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> registrar({
    required String plataforma,
    required String tokenFcm,
  }) =>
      _api.post(
        ApiRoutes.dispositivos,
        body: <String, dynamic>{
          'plataforma': plataforma,
          'tokenFcm': tokenFcm,
        },
        auth: true,
      );
}
