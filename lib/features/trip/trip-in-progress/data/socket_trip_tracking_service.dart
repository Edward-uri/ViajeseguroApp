import 'dart:async';

import '../../../../core/websocket/socket_service.dart';
import '../domain/services/trip_tracking_service.dart';

/// Implementación real de TripTrackingService usando Socket.IO.
///
/// Escucha el evento `viaje:ubicacion_conductor` del servidor
/// y emite `DriverPosition` al ViewModel.
class SocketTripTrackingService implements TripTrackingService {
  SocketTripTrackingService(this._socketService);

  final SocketService _socketService;
  StreamController<DriverPosition>? _controller;
  StreamSubscription<TripSocketEvent>? _subscription;
  int? _trackingTripId;

  @override
  Stream<DriverPosition> startTracking(String tripId) {
    _controller = StreamController<DriverPosition>();
    _trackingTripId = int.tryParse(tripId);

    _subscription = _socketService.onDriverPosition.listen((event) {
      if (_trackingTripId == null) return;
      if (event.idViaje != _trackingTripId) return;
      if (event.lat == null || event.lng == null) return;

      _controller?.add(DriverPosition(
        latitude: event.lat!,
        longitude: event.lng!,
        timestamp: DateTime.now(),
      ));
    });

    return _controller!.stream;
  }

  @override
  void stopTracking() {
    _subscription?.cancel();
    _subscription = null;
    _controller?.close();
    _controller = null;
    _trackingTripId = null;
  }
}
