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
  });

  final double latitude;
  final double longitude;
  final double? heading;
  final double? speed;
  final DateTime? timestamp;
}
