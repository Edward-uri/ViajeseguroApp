import '../../../../core/http/api_client.dart';
import '../../../../core/routes/routes.dart';
import '../../domain/entities/municipio.dart';

class MunicipiosApi {
  MunicipiosApi(this._api);

  final ApiClient _api;

  Future<List<Municipio>> fetchMunicipios() async {
    final response = await _api.get(ApiRoutes.municipios, auth: false);
    final data = response['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(Municipio.fromJson)
        .toList();
  }
}
