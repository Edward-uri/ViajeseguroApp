import '../../../trip-searching/domain/entities/trip_location.dart';
import '../../../trip-searching/domain/entities/trip_fare.dart';

enum TripStatus {
  solicitado,
  aceptado,
  enCurso,
  completado,
  cancelado,
}

class Trip {
  const Trip({
    required this.id,
    required this.origin,
    required this.destination,
    required this.fare,
    required this.status,
    this.driverName,
    this.driverPhone,
    this.vehicleInfo,
    this.tipoServicio = 'viaje',
    this.distanciaKm,
    this.createdAt,
  });

  final String id;
  final TripLocation origin;
  final TripLocation destination;
  final TripFare fare;
  final TripStatus status;
  final String? driverName;
  final String? driverPhone;
  final String? vehicleInfo;
  final String tipoServicio;
  final double? distanciaKm;
  final DateTime? createdAt;

  factory Trip.fromJson(Map<String, dynamic> json) {
    final origen = json['origen'] as Map<String, dynamic>? ?? {};
    final destino = json['destino'] as Map<String, dynamic>? ?? {};
    final tarifa = (json['tarifa'] as num?)?.toDouble() ?? 0.0;
    final distancia = (json['distanciaKm'] as num?)?.toDouble() ?? 0.0;

    return Trip(
      id: (json['idViaje'] ?? json['id'] ?? 0).toString(),
      origin: TripLocation(
        address: (origen['texto'] ?? 'Origen').toString(),
        latitude: (origen['lat'] as num?)?.toDouble() ?? 0.0,
        longitude: (origen['lng'] as num?)?.toDouble() ?? 0.0,
      ),
      destination: TripLocation(
        address: (destino['texto'] ?? 'Destino').toString(),
        latitude: (destino['lat'] as num?)?.toDouble() ?? 0.0,
        longitude: (destino['lng'] as num?)?.toDouble() ?? 0.0,
      ),
      fare: TripFare(
        baseFare: tarifa,
        distanceFare: 0,
        totalFare: tarifa,
        distance: distancia * 1000,
        duration: 0,
        currency: 'MXN',
      ),
      status: _parseStatus(json['estado'] as String? ?? 'solicitado'),
      tipoServicio: (json['tipoServicio'] ?? 'viaje').toString(),
      distanciaKm: distancia,
      driverName: json['driverName'] as String?,
      driverPhone: json['driverPhone'] as String?,
      vehicleInfo: json['vehicleInfo'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  static TripStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'solicitado':
        return TripStatus.solicitado;
      case 'aceptado':
        return TripStatus.aceptado;
      case 'en_curso':
      case 'encurso':
      case 'in_progress':
      case 'inprogress':
        return TripStatus.enCurso;
      case 'completado':
        return TripStatus.completado;
      case 'cancelado':
        return TripStatus.cancelado;
      default:
        return TripStatus.solicitado;
    }
  }

  Trip copyWith({
    TripStatus? status,
    String? driverName,
    String? driverPhone,
    String? vehicleInfo,
  }) {
    return Trip(
      id: id,
      origin: origin,
      destination: destination,
      fare: fare,
      status: status ?? this.status,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      vehicleInfo: vehicleInfo ?? this.vehicleInfo,
      tipoServicio: tipoServicio,
      distanciaKm: distanciaKm,
      createdAt: createdAt,
    );
  }
}
