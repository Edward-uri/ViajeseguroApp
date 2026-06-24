import '../../../../core/http/api_client.dart';
import '../../../../core/routes/routes.dart';

class DispositivosApi {
  DispositivosApi(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> registrar({
    required String plataforma,
    required String version,
    String? modelo,
    String? tokenPush,
  }) =>
      _api.post(
        ApiRoutes.dispositivos,
        body: <String, dynamic>{
          'plataforma': plataforma,
          'version': version,
          if (modelo != null) 'modelo': modelo,
          if (tokenPush != null) 'tokenPush': tokenPush,
        },
        auth: true,
      );
}
