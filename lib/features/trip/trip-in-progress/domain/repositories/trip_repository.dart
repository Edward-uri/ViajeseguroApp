import '../entities/estimacion_viaje.dart';
import '../entities/trip.dart';
import '../../../trip-searching/domain/entities/trip_location.dart';

abstract class TripRepository {
  Future<EstimacionViaje> estimarViaje({
    required int idMunicipio,
    required TripLocation origin,
    required TripLocation destination,
    int personas = 1,
  });

  Future<Trip> createTrip({
    required int idMunicipio,
    required TripLocation origin,
    required TripLocation destination,
    int personas = 1,
    int? idZonaDestino,
    double? tarifaEstimada,
    String tipoServicio = 'viaje',
  });

  Future<Trip> getTripById(String tripId);

  Future<Trip?> getActiveTrip();

  Future<void> cancelTrip(String tripId, {String? motivo});

  Future<void> rateTrip(String tripId, {required int calificacion, String? comentario});
}
