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
    this.idPasajero,
    this.idConductor,
    this.idVehiculo,
    this.idMunicipio,
    this.tipoServicio = 'viaje',
    this.distanciaKm,
    this.tarifaEstimada = false,
    this.numPasajeros = 1,
    this.driverName,
    this.driverPhone,
    this.vehicleInfo,
    this.fechaSolicitud,
    this.fechaAceptacion,
    this.fechaInicio,
    this.fechaFin,
    this.canceladoPor,
    this.motivoCancelacion,
  });

  final String id;
  final TripLocation origin;
  final TripLocation destination;
  final TripFare fare;
  final TripStatus status;
  final int? idPasajero;
  final int? idConductor;
  final int? idVehiculo;
  final int? idMunicipio;
  final String tipoServicio;
  final double? distanciaKm;
  final bool tarifaEstimada;
  final int numPasajeros;
  final String? driverName;
  final String? driverPhone;
  final String? vehicleInfo;
  final DateTime? fechaSolicitud;
  final DateTime? fechaAceptacion;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final String? canceladoPor;
  final String? motivoCancelacion;

  factory Trip.fromJson(Map<String, dynamic> json) {
    final origen = json['origen'] as Map<String, dynamic>? ?? {};
    final destino = json['destino'] as Map<String, dynamic>? ?? {};
    final tarifa = (json['tarifa'] as num?)?.toDouble() ?? 0.0;
    final distancia = (json['distanciaKm'] as num?)?.toDouble() ?? 0.0;

    return Trip(
      id: (json['idViaje'] ?? json['id'] ?? 0).toString(),
      idPasajero: (json['idPasajero'] as num?)?.toInt(),
      idConductor: (json['idConductor'] as num?)?.toInt(),
      idVehiculo: (json['idVehiculo'] as num?)?.toInt(),
      idMunicipio: (json['idMunicipio'] as num?)?.toInt(),
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
      tarifaEstimada: (json['tarifaEstimada'] as bool?) ?? false,
      numPasajeros: (json['numPasajeros'] as num?)?.toInt() ?? 1,
      driverName: json['driverName'] as String?,
      driverPhone: json['driverPhone'] as String?,
      vehicleInfo: json['vehicleInfo'] as String?,
      fechaSolicitud: _parseDate(json['fechaSolicitud']),
      fechaAceptacion: _parseDate(json['fechaAceptacion']),
      fechaInicio: _parseDate(json['fechaInicio']),
      fechaFin: _parseDate(json['fechaFin']),
      canceladoPor: json['canceladoPor'] as String?,
      motivoCancelacion: json['motivoCancelacion'] as String?,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
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

  /// Parser público para usar desde ViewModels.
  static TripStatus parseStatus(String status) => _parseStatus(status);

  Trip copyWith({
    TripStatus? status,
    int? idConductor,
    int? idVehiculo,
    int? numPasajeros,
    String? driverName,
    String? driverPhone,
    String? vehicleInfo,
    DateTime? fechaAceptacion,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? canceladoPor,
    String? motivoCancelacion,
  }) {
    return Trip(
      id: id,
      origin: origin,
      destination: destination,
      fare: fare,
      status: status ?? this.status,
      idPasajero: idPasajero,
      idConductor: idConductor ?? this.idConductor,
      idVehiculo: idVehiculo ?? this.idVehiculo,
      idMunicipio: idMunicipio,
      tipoServicio: tipoServicio,
      distanciaKm: distanciaKm,
      tarifaEstimada: tarifaEstimada,
      numPasajeros: numPasajeros ?? this.numPasajeros,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      vehicleInfo: vehicleInfo ?? this.vehicleInfo,
      fechaSolicitud: fechaSolicitud,
      fechaAceptacion: fechaAceptacion ?? this.fechaAceptacion,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      canceladoPor: canceladoPor ?? this.canceladoPor,
      motivoCancelacion: motivoCancelacion ?? this.motivoCancelacion,
    );
  }
}
