import '../entities/trip_location.dart';

abstract class TripSearchRepository {
  Future<List<TripLocation>> searchAddress(String query);
  Future<TripLocation> reverseGeocode(double latitude, double longitude);
  Future<List<List<double>>> getRoute({
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
  });
}
