abstract class TripTrackingService {
  /// Escucha la ubicación del conductor para este viaje.
  Stream<DriverPosition> startTracking(String tripId);
  void stopTracking();

  /// Empieza a compartir la ubicación del pasajero con el conductor (cada pocos segundos).
  void startSharingLocation(String tripId);
  void stopSharingLocation();
}

class DriverPosition {
  const DriverPosition({
    required this.latitude,
    required this.longitude,
    this.heading,
    this.speed,
    this.timestamp,
    this.etaPickupMin,
    this.etaDestinationMin,
  });

  final double latitude;
  final double longitude;
  final double? heading;
  final double? speed;
  final DateTime? timestamp;

  /// Minutos para que el conductor llegue al origen (viaje aceptado).
  final int? etaPickupMin;

  /// Minutos para llegar al destino (recogida + trayecto en aceptado;
  /// solo trayecto restante en curso).
  final int? etaDestinationMin;
}
