class TarifaZona {
  const TarifaZona({
    required this.idZona,
    required this.nombre,
    required this.precio,
  });

  final int idZona;
  final String nombre;
  final double precio;

  factory TarifaZona.fromJson(Map<String, dynamic> json) {
    return TarifaZona(
      idZona: (json['idZona'] as num?)?.toInt() ?? 0,
      nombre: (json['nombre'] ?? '').toString(),
      precio: (json['precio'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
