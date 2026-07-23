import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../../core/env/api_config.dart';

class MapboxApi {
  MapboxApi(this._client);

  final http.Client _client;

  static const String _geocodingBase =
      'https://api.mapbox.com/geocoding/v5/mapbox.places';
  static const String _directionsBase =
      'https://api.mapbox.com/directions/v5/mapbox/driving';

  Future<Map<String, dynamic>> searchAddress(
    String query, {
    double? proximityLat,
    double? proximityLng,
  }) async {
    final token = ApiConfig.mapboxToken;
    if (token.isEmpty) {
      return {'features': const []};
    }
    final encoded = Uri.encodeQueryComponent(query);
    // proximity sesga los resultados hacia la ubicacion del pasajero (su
    // municipio primero), en vez de direcciones de otros estados.
    final proximity = (proximityLat != null && proximityLng != null)
        ? '&proximity=$proximityLng,$proximityLat'
        : '';
    final url = Uri.parse(
      '$_geocodingBase/$encoded.json?access_token=$token&limit=5&language=es&country=mx$proximity',
    );
    final response = await _client.get(url);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return {'features': const []};
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> reverseGeocode(double latitude, double longitude) async {
    final token = ApiConfig.mapboxToken;
    if (token.isEmpty) {
      return {'features': const []};
    }
    final url = Uri.parse(
      '$_geocodingBase/$longitude,$latitude.json?access_token=$token&limit=1&language=es&country=mx',
    );
    final response = await _client.get(url);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return {'features': const []};
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<List<double>>> getRoute({
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
  }) async {
    final token = ApiConfig.mapboxToken;
    if (token.isEmpty) return const [];

    final url = Uri.parse(
      '$_directionsBase/$originLng,$originLat;$destinationLng,$destinationLat'
      '?geometries=geojson&overview=full&steps=false&access_token=$token',
    );
    final response = await _client.get(url);
    if (response.statusCode < 200 || response.statusCode >= 300) return const [];

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final routes = decoded['routes'] as List<dynamic>?;
    if (routes == null || routes.isEmpty) return const [];

    final geometry = routes[0]['geometry'] as Map<String, dynamic>?;
    final coordinates = geometry?['coordinates'] as List<dynamic>?;
    if (coordinates == null) return const [];

    return coordinates
        .map((coord) => (coord as List<dynamic>)
            .map((v) => (v as num).toDouble())
            .toList())
        .toList();
  }
}
