import '../domain/entities/trip.dart';
import '../domain/repositories/trip_repository.dart';
import '../../trip-searching/domain/entities/trip_location.dart';
import 'remote/trip_api.dart';

class TripRepositoryImpl implements TripRepository {
  TripRepositoryImpl(this._tripApi);

  final TripApi _tripApi;

  @override
  Future<Trip> createTrip({
    required int idMunicipio,
    required TripLocation origin,
    required TripLocation destination,
  }) async {
    final response = await _tripApi.createTrip(
      idMunicipio: idMunicipio,
      originLat: origin.latitude,
      originLng: origin.longitude,
      originAddress: origin.address,
      destinationLat: destination.latitude,
      destinationLng: destination.longitude,
      destinationAddress: destination.address,
    );

    return Trip.fromJson(response);
  }

  @override
  Future<Trip> getTripById(String tripId) async {
    final response = await _tripApi.getTripById(tripId);
    return Trip.fromJson(response);
  }

  @override
  Future<void> cancelTrip(String tripId) async {
    await _tripApi.cancelTrip(tripId);
  }
}
