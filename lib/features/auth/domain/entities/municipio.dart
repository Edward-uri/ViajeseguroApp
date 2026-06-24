class Municipio {
  const Municipio({
    required this.idMunicipio,
    required this.nombre,
    required this.estado,
  });

  final int idMunicipio;
  final String nombre;
  final String estado;

  String get displayName => '$nombre, $estado';

  factory Municipio.fromJson(Map<String, dynamic> json) {
    return Municipio(
      idMunicipio: json['idMunicipio'] as int,
      nombre: json['nombre'] as String,
      estado: json['estado'] as String,
    );
  }
}
