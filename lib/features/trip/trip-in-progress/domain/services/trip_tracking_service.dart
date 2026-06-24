abstract class TripTrackingService {
  Stream<DriverPosition> startTracking(String tripId);
  void stopTracking();
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
