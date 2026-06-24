import '../entities/trip.dart';
import '../../../trip-searching/domain/entities/trip_location.dart';

abstract class TripRepository {
  Future<Trip> createTrip({
    required int idMunicipio,
    required TripLocation origin,
    required TripLocation destination,
  });

  Future<Trip> getTripById(String tripId);

  Future<void> cancelTrip(String tripId);
}
