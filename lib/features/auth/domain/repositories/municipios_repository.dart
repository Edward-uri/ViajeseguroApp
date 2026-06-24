import '../entities/municipio.dart';

abstract class MunicipiosRepository {
  Future<List<Municipio>> getMunicipios();
}
