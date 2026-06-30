class EstimacionViaje {
  const EstimacionViaje({
    required this.distanciaKm,
    required this.duracionMin,
    required this.personas,
    required this.tarifaPorPersona,
    required this.tarifa,
    required this.tarifaEstimada,
    required this.idZonaDestino,
    required this.ruta,
  });

  final double distanciaKm;
  final double duracionMin;
  final int personas;
  final double tarifaPorPersona;
  final double tarifa;
  final bool tarifaEstimada;
  final int? idZonaDestino;
  final List<List<double>>? ruta;

  factory EstimacionViaje.fromJson(Map<String, dynamic> json) {
    final ruta = json['ruta'] as Map<String, dynamic>?;
    List<List<double>>? coords;
    if (ruta != null) {
      final rawCoords = ruta['coordinates'] as List?;
      if (rawCoords != null) {
        coords = rawCoords
            .map((c) => (c as List)
                .map((v) => (v as num).toDouble())
                .toList())
            .toList();
      }
    }

    return EstimacionViaje(
      distanciaKm: (json['distanciaKm'] as num?)?.toDouble() ?? 0.0,
      duracionMin: (json['duracionMin'] as num?)?.toDouble() ?? 0.0,
      personas: (json['personas'] as num?)?.toInt() ?? 1,
      tarifaPorPersona: (json['tarifaPorPersona'] as num?)?.toDouble() ?? 0.0,
      tarifa: (json['tarifa'] as num?)?.toDouble() ?? 0.0,
      tarifaEstimada: (json['tarifaEstimada'] as bool?) ?? false,
      idZonaDestino: (json['idZonaDestino'] as num?)?.toInt(),
      ruta: coords,
    );
  }
}
