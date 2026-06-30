import '../../../../../core/http/api_client.dart';
import '../../../../../core/routes/routes.dart';

class TripApi {
  TripApi(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> estimarViaje({
    required int idMunicipio,
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
    String? originAddress,
    String? destinationAddress,
    int personas = 1,
    int? idZonaDestino,
  }) =>
      _api.post(
        ApiRoutes.viajesEstimar,
        body: <String, dynamic>{
          'idMunicipio': idMunicipio,
          'origen': {
            'lat': originLat,
            'lng': originLng,
            if (originAddress != null) 'texto': originAddress,
          },
          'destino': {
            'lat': destinationLat,
            'lng': destinationLng,
            if (destinationAddress != null) 'texto': destinationAddress,
          },
          if (idZonaDestino != null) 'idZonaDestino': idZonaDestino,
          'personas': personas,
        },
        auth: true,
      );

  Future<Map<String, dynamic>> createTrip({
    required int idMunicipio,
    required double originLat,
    required double originLng,
    required String originAddress,
    required double destinationLat,
    required double destinationLng,
    required String destinationAddress,
    int personas = 1,
    int? idZonaDestino,
    double? tarifaEstimada,
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
          if (idZonaDestino != null) 'idZonaDestino': idZonaDestino,
          'personas': personas,
          if (tarifaEstimada != null) 'tarifaEstimada': tarifaEstimada,
        },
        auth: true,
      );

  Future<Map<String, dynamic>> getTripById(String tripId) =>
      _api.get('${ApiRoutes.viajes}/$tripId', auth: true);

  Future<Map<String, dynamic>?> getActiveTrip() async {
    final response = await _api.get(ApiRoutes.viajesActivo, auth: true);
    final data = response['data'];
    if (data == null || data is! Map<String, dynamic>) return null;
    return data;
  }

  Future<void> cancelTrip(String tripId, {String? motivo}) =>
      _api.post(
        '${ApiRoutes.viajes}/$tripId/cancelar',
        body: motivo != null ? {'motivo': motivo} : null,
        auth: true,
      );
}
