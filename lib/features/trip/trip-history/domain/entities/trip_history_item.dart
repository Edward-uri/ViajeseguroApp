enum TripHistoryStatus { completado, cancelado, solicitado, aceptado, enCurso }

class TripHistoryItem {
  const TripHistoryItem({
    required this.id,
    required this.fecha,
    required this.tipo,
    required this.estado,
    required this.originAddress,
    required this.destinationAddress,
    required this.tarifa,
    required this.metodoPago,
  });

  final String id;
  final DateTime fecha;
  final String tipo;
  final TripHistoryStatus estado;
  final String originAddress;
  final String destinationAddress;
  final double tarifa;
  final String metodoPago;

  String get estadoLabel {
    switch (estado) {
      case TripHistoryStatus.completado:
        return 'Completado';
      case TripHistoryStatus.cancelado:
        return 'Cancelado';
      case TripHistoryStatus.solicitado:
        return 'Solicitado';
      case TripHistoryStatus.aceptado:
        return 'Aceptado';
      case TripHistoryStatus.enCurso:
        return 'En curso';
    }
  }

  bool get isCompletado => estado == TripHistoryStatus.completado;
  bool get isCancelado => estado == TripHistoryStatus.cancelado;

  String get tipoLabel {
    if (tipo == 'envio') return 'Envio de paquete';
    return 'Mototaxi';
  }

  factory TripHistoryItem.fromJson(Map<String, dynamic> json) {
    final origen = json['origen'] as Map<String, dynamic>? ?? {};
    final destino = json['destino'] as Map<String, dynamic>? ?? {};

    final fechaStr = json['createdAt'] ??
        json['fechaSolicitud'] ??
        json['fecha'] ??
        json['created_at'] ??
        json['fechaCreacion'] ??
        '';

    return TripHistoryItem(
      id: (json['idViaje'] ?? json['id'] ?? 0).toString(),
      fecha: DateTime.tryParse(fechaStr.toString()) ?? DateTime.now(),
      tipo: (json['tipoServicio'] ?? 'viaje').toString(),
      estado: _parseEstado(json['estado'] ?? 'solicitado'),
      originAddress: (origen['texto'] ?? 'Origen').toString(),
      destinationAddress: (destino['texto'] ?? 'Destino').toString(),
      tarifa: _parseDouble(json['tarifa'] ?? 0),
      metodoPago: 'Efectivo',
    );
  }

  static TripHistoryStatus _parseEstado(dynamic estado) {
    final s = estado.toString().toLowerCase();
    if (s.contains('cancel')) return TripHistoryStatus.cancelado;
    if (s.contains('complet')) return TripHistoryStatus.completado;
    if (s.contains('acept')) return TripHistoryStatus.aceptado;
    if (s.contains('curso') || s.contains('progress')) return TripHistoryStatus.enCurso;
    return TripHistoryStatus.solicitado;
  }

  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}
