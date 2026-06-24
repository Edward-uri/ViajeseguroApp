import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  const ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.codigoverse.space',
  );

  static const Duration requestTimeout = Duration(
    seconds: int.fromEnvironment('API_TIMEOUT_SECONDS', defaultValue: 15),
  );

  static String get mapboxToken =>
      dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';
}
