/// Direccion guardada del usuario (favorita). Espeja el modelo del backend
/// (`GET/POST/DELETE /api/users/direcciones`): idDireccion, etiqueta, lat, lng,
/// texto, esFavorita.
class Direccion {
  const Direccion({
    required this.id,
    this.etiqueta,
    required this.lat,
    required this.lng,
    this.texto,
    this.esFavorita = true,
  });

  final int id;
  final String? etiqueta;
  final double lat;
  final double lng;
  final String? texto;
  final bool esFavorita;

  /// Nombre a mostrar: la etiqueta si existe, si no la direccion.
  String get titulo {
    if (etiqueta != null && etiqueta!.isNotEmpty) return etiqueta!;
    if (texto != null && texto!.isNotEmpty) return texto!;
    return 'Ubicacion guardada';
  }

  factory Direccion.fromJson(Map<String, dynamic> json) {
    return Direccion(
      id: (json['idDireccion'] ?? json['id'] ?? 0) is int
          ? (json['idDireccion'] ?? json['id'] ?? 0) as int
          : int.tryParse('${json['idDireccion'] ?? json['id']}') ?? 0,
      etiqueta: json['etiqueta'] as String?,
      lat: _toDouble(json['lat']),
      lng: _toDouble(json['lng']),
      texto: json['texto'] as String?,
      esFavorita: (json['esFavorita'] ?? true) == true,
    );
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }
}
