import '../../../../../core/http/api_client.dart';
import '../../../../../core/routes/routes.dart';

class TripApi {
  TripApi(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> createTrip({
    required int idMunicipio,
    required double originLat,
    required double originLng,
    required String originAddress,
    required double destinationLat,
    required double destinationLng,
    required String destinationAddress,
  }) =>
      _api.post(
        ApiRoutes.viajes,
        body: <String, dynamic>{
          'idMunicipio': idMunicipio,
          'origen': {
            'lat': originLat,
            'lng': originLng,
            'texto': originAddress,
          },
          'destino': {
            'lat': destinationLat,
            'lng': destinationLng,
            'texto': destinationAddress,
          },
        },
        auth: true,
      );

  Future<Map<String, dynamic>> getTripById(String tripId) =>
      _api.get('${ApiRoutes.viajes}/$tripId', auth: true);

  Future<void> cancelTrip(String tripId) =>
      _api.post('${ApiRoutes.viajes}/$tripId/cancelar', auth: true);
}
