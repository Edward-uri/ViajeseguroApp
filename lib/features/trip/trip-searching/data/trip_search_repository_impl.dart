import '../domain/entities/trip_location.dart';
import '../domain/repositories/trip_search_repository.dart';
import 'remote/mapbox_api.dart';

class TripSearchRepositoryImpl implements TripSearchRepository {
  TripSearchRepositoryImpl(this._mapboxApi);

  final MapboxApi _mapboxApi;

  @override
  Future<List<TripLocation>> searchAddress(String query) async {
    final response = await _mapboxApi.searchAddress(query);
    final features = response['features'] as List<dynamic>? ?? const [];

    return features.map((feature) {
      final map = feature as Map<String, dynamic>;
      final geometry = map['geometry'] as Map<String, dynamic>?;
      final coordinates = geometry?['coordinates'] as List<dynamic>?;
      final placeName = map['place_name'] as String? ?? '';
      final text = map['text'] as String? ?? '';

      final lat = coordinates != null && coordinates.length >= 2
          ? (coordinates[1] as num).toDouble()
          : 0.0;
      final lng = coordinates != null && coordinates.isNotEmpty
          ? (coordinates[0] as num).toDouble()
          : 0.0;

      return TripLocation(
        address: placeName.isNotEmpty ? placeName : text,
        latitude: lat,
        longitude: lng,
        placeName: placeName,
      );
    }).toList();
  }

  @override
  Future<TripLocation> reverseGeocode(double latitude, double longitude) async {
    final response = await _mapboxApi.reverseGeocode(latitude, longitude);
    final features = response['features'] as List<dynamic>? ?? const [];

    if (features.isEmpty) {
      return TripLocation(
        address: 'Ubicacion actual',
        latitude: latitude,
        longitude: longitude,
      );
    }

    final feature = features.first as Map<String, dynamic>;
    final placeName = feature['place_name'] as String? ?? '';
    final text = feature['text'] as String? ?? '';

    return TripLocation(
      address: placeName.isNotEmpty ? placeName : text,
      latitude: latitude,
      longitude: longitude,
      placeName: placeName,
    );
  }

  @override
  Future<List<List<double>>> getRoute({
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
  }) {
    return _mapboxApi.getRoute(
      originLat: originLat,
      originLng: originLng,
      destinationLat: destinationLat,
      destinationLng: destinationLng,
    );
  }
}
