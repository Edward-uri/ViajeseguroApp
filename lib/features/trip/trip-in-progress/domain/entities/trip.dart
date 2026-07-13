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
    this.idZonaDestino,
    this.tipoServicio = 'viaje',
    this.distanciaKm,
    this.tarifaEstimada = false,
    this.numPasajeros = 1,
    this.driverName,
    this.driverPhone,
    this.driverRating,
    this.driverPhotoUrl,
    this.vehicleInfo,
    this.vehiclePlaca,
    this.vehicleYear,
    this.fechaSolicitud,
    this.fechaAceptacion,
    this.fechaInicio,
    this.fechaFin,
    this.canceladoPor,
    this.motivoCancelacion,
    this.expiraEn,
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
  final int? idZonaDestino;
  final String tipoServicio;
  final double? distanciaKm;
  final bool tarifaEstimada;
  final int numPasajeros;
  final String? driverName;
  final String? driverPhone;
  final double? driverRating;
  final String? driverPhotoUrl;
  final String? vehicleInfo;
  final String? vehiclePlaca;
  final int? vehicleYear;
  final DateTime? fechaSolicitud;
  final DateTime? fechaAceptacion;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final String? canceladoPor;
  final String? motivoCancelacion;
  final DateTime? expiraEn;

  factory Trip.fromJson(Map<String, dynamic> json) {
    final origen = json['origen'] as Map<String, dynamic>? ?? {};
    final destino = json['destino'] as Map<String, dynamic>? ?? {};
    final tarifa = (json['tarifa'] as num?)?.toDouble() ?? 0.0;
    final distancia = (json['distanciaKm'] as num?)?.toDouble() ?? 0.0;

    // Conductor: puede venir anidado en "conductor" o en campos planos
    final conductor = json['conductor'] as Map<String, dynamic>?;
    final driverName = conductor?['nombre'] as String? ?? json['driverName'] as String?;
    final driverPhone = conductor?['telefono'] as String? ?? json['driverPhone'] as String?;
    final driverRating = (conductor?['calificacion'] as num?)?.toDouble();
    final driverPhotoUrl = conductor?['fotoUrl'] as String?;

    // Vehiculo (el backend devuelve modelo/color/anio/placa; no hay "marca").
    final vehiculo = json['vehiculo'] as Map<String, dynamic>?;
    final vehiclePlaca = vehiculo?['placa'] as String?;
    final vehicleYear = (vehiculo?['anio'] as num?)?.toInt();
    final vehicleInfo = vehiculo != null
        ? [vehiculo['modelo'], vehiculo['color']]
            .where((v) => v != null && v.toString().trim().isNotEmpty)
            .join(' · ')
        : json['vehicleInfo'] as String?;

    return Trip(
      id: (json['idViaje'] ?? json['id'] ?? 0).toString(),
      idPasajero: (json['idPasajero'] as num?)?.toInt(),
      idConductor: (json['idConductor'] as num?)?.toInt(),
      idVehiculo: (json['idVehiculo'] as num?)?.toInt(),
      idMunicipio: (json['idMunicipio'] as num?)?.toInt(),
      idZonaDestino: (json['idZonaDestino'] as num?)?.toInt(),
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
      driverName: driverName,
      driverPhone: driverPhone,
      driverRating: driverRating,
      driverPhotoUrl: driverPhotoUrl,
      vehicleInfo: vehicleInfo,
      vehiclePlaca: vehiclePlaca,
      vehicleYear: vehicleYear,
      fechaSolicitud: _parseDate(json['fechaSolicitud']),
      fechaAceptacion: _parseDate(json['fechaAceptacion']),
      fechaInicio: _parseDate(json['fechaInicio']),
      fechaFin: _parseDate(json['fechaFin']),
      canceladoPor: json['canceladoPor'] as String?,
      motivoCancelacion: json['motivoCancelacion'] as String?,
      expiraEn: _parseDate(json['expiraEn']),
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
    double? driverRating,
    String? driverPhotoUrl,
    String? vehicleInfo,
    String? vehiclePlaca,
    int? vehicleYear,
    DateTime? fechaAceptacion,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? canceladoPor,
    String? motivoCancelacion,
    DateTime? expiraEn,
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
      idZonaDestino: idZonaDestino,
      tipoServicio: tipoServicio,
      distanciaKm: distanciaKm,
      tarifaEstimada: tarifaEstimada,
      numPasajeros: numPasajeros ?? this.numPasajeros,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      driverRating: driverRating ?? this.driverRating,
      driverPhotoUrl: driverPhotoUrl ?? this.driverPhotoUrl,
      vehicleInfo: vehicleInfo ?? this.vehicleInfo,
      vehiclePlaca: vehiclePlaca ?? this.vehiclePlaca,
      vehicleYear: vehicleYear ?? this.vehicleYear,
      fechaSolicitud: fechaSolicitud,
      fechaAceptacion: fechaAceptacion ?? this.fechaAceptacion,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      canceladoPor: canceladoPor ?? this.canceladoPor,
      motivoCancelacion: motivoCancelacion ?? this.motivoCancelacion,
      expiraEn: expiraEn ?? this.expiraEn,
    );
  }
}
