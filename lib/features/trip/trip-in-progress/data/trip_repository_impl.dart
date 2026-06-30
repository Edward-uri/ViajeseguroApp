import '../domain/entities/estimacion_viaje.dart';
import '../domain/entities/trip.dart';
import '../domain/repositories/trip_repository.dart';
import '../../trip-searching/domain/entities/trip_location.dart';
import 'remote/trip_api.dart';

class TripRepositoryImpl implements TripRepository {
  TripRepositoryImpl(this._tripApi);

  final TripApi _tripApi;

  @override
  Future<EstimacionViaje> estimarViaje({
    required int idMunicipio,
    required TripLocation origin,
    required TripLocation destination,
    int personas = 1,
  }) async {
    final response = await _tripApi.estimarViaje(
      idMunicipio: idMunicipio,
      originLat: origin.latitude,
      originLng: origin.longitude,
      originAddress: origin.address,
      destinationLat: destination.latitude,
      destinationLng: destination.longitude,
      destinationAddress: destination.address,
      personas: personas,
    );
    return EstimacionViaje.fromJson(response);
  }

  @override
  Future<Trip> createTrip({
    required int idMunicipio,
    required TripLocation origin,
    required TripLocation destination,
    int personas = 1,
    int? idZonaDestino,
    double? tarifaEstimada,
  }) async {
    final response = await _tripApi.createTrip(
      idMunicipio: idMunicipio,
      originLat: origin.latitude,
      originLng: origin.longitude,
      originAddress: origin.address,
      destinationLat: destination.latitude,
      destinationLng: destination.longitude,
      destinationAddress: destination.address,
      personas: personas,
      idZonaDestino: idZonaDestino,
      tarifaEstimada: tarifaEstimada,
    );

    return Trip.fromJson(response);
  }

  @override
  Future<Trip> getTripById(String tripId) async {
    final response = await _tripApi.getTripById(tripId);
    return Trip.fromJson(response);
  }

  @override
  Future<Trip?> getActiveTrip() async {
    final response = await _tripApi.getActiveTrip();
    if (response == null) return null;
    return Trip.fromJson(response);
  }

  @override
  Future<void> cancelTrip(String tripId, {String? motivo}) async {
    await _tripApi.cancelTrip(tripId, motivo: motivo);
  }

  @override
  Future<void> rateTrip(String tripId, {required int calificacion, String? comentario}) async {
    await _tripApi.rateTrip(tripId, calificacion: calificacion, comentario: comentario);
  }
}
