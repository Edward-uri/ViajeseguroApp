import '../entities/municipio.dart';
import '../entities/tarifa_zona.dart';

abstract class MunicipiosRepository {
  Future<List<Municipio>> getMunicipios();
  Future<List<TarifaZona>> getTarifas(int idMunicipio);
}
