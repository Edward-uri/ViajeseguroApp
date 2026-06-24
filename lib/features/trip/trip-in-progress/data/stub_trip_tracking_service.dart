import 'dart:async';

import '../domain/services/trip_tracking_service.dart';

class StubTripTrackingService implements TripTrackingService {
  StreamController<DriverPosition>? _controller;

  @override
  Stream<DriverPosition> startTracking(String tripId) {
    _controller = StreamController<DriverPosition>();
    return _controller!.stream;
  }

  @override
  void stopTracking() {
    _controller?.close();
    _controller = null;
  }
}
