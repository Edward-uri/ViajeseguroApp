import '../../../../../core/http/api_client.dart';
import '../../../../../core/routes/routes.dart';

class TripHistoryApi {
  TripHistoryApi(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> getTripHistory() =>
      _api.get(ApiRoutes.viajesMios, auth: true);
}
