import '../domain/entities/municipio.dart';
import '../domain/entities/tarifa_zona.dart';
import '../domain/repositories/municipios_repository.dart';
import 'remote/municipios_api.dart';

class MunicipiosRepositoryImpl implements MunicipiosRepository {
  MunicipiosRepositoryImpl(this._api);

  final MunicipiosApi _api;
  List<Municipio>? _cache;

  @override
  Future<List<Municipio>> getMunicipios() async {
    if (_cache != null) return _cache!;
    _cache = await _api.fetchMunicipios();
    return _cache!;
  }

  @override
  Future<List<TarifaZona>> getTarifas(int idMunicipio) {
    return _api.fetchTarifas(idMunicipio);
  }
}
