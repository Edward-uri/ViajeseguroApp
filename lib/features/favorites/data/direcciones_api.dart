import '../../../core/http/api_client.dart';
import '../../../core/routes/api_routes.dart';

/// Cliente del CRUD de direcciones guardadas del backend
/// (`/api/users/direcciones`, autenticado).
class DireccionesApi {
  DireccionesApi(this._api);

  final ApiClient _api;

  Future<List<Map<String, dynamic>>> listar() async {
    final response = await _api.get(ApiRoutes.usersDirecciones, auth: true);
    final data = response['data'] ?? response['direcciones'] ?? response['results'];
    if (data is! List) return const [];
    return data.whereType<Map<String, dynamic>>().toList();
  }

  Future<void> crear({
    String? etiqueta,
    required double lat,
    required double lng,
    String? texto,
    bool esFavorita = true,
  }) async {
    await _api.post(
      ApiRoutes.usersDirecciones,
      body: <String, dynamic>{
        if (etiqueta != null && etiqueta.isNotEmpty) 'etiqueta': etiqueta,
        'lat': lat,
        'lng': lng,
        if (texto != null && texto.isNotEmpty) 'texto': texto,
        'esFavorita': esFavorita,
      },
      auth: true,
    );
  }

  Future<void> eliminar(int id) =>
      _api.delete('${ApiRoutes.usersDirecciones}/$id', auth: true);
}
