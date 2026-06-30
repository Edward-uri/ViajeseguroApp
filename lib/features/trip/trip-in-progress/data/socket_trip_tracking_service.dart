import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../../../../core/websocket/socket_service.dart';
import '../domain/services/trip_tracking_service.dart';

/// Implementación real de TripTrackingService usando Socket.IO.
///
/// Escucha `viaje:ubicacion_conductor` (conductor → pasajero) y, en sentido
/// inverso, comparte la ubicación del pasajero emitiendo `pasajero:ubicacion`.
class SocketTripTrackingService implements TripTrackingService {
  SocketTripTrackingService(this._socketService);

  final SocketService _socketService;
  StreamController<DriverPosition>? _controller;
  StreamSubscription<TripSocketEvent>? _subscription;
  int? _trackingTripId;
  Timer? _shareTimer;

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

  @override
  void startSharingLocation(String tripId) {
    final id = int.tryParse(tripId);
    if (id == null) return;
    _shareTimer?.cancel();
    // Envía una primera lectura y luego cada 5 s mientras dure el viaje.
    _shareOnce(id);
    _shareTimer = Timer.periodic(const Duration(seconds: 5), (_) => _shareOnce(id));
  }

  Future<void> _shareOnce(int idViaje) async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      _socketService.emitPassengerLocation(
        idViaje: idViaje,
        lat: pos.latitude,
        lng: pos.longitude,
      );
    } catch (_) {
      // Si el GPS falla o no hay permiso, se omite este envío.
    }
  }

  @override
  void stopSharingLocation() {
    _shareTimer?.cancel();
    _shareTimer = null;
  }
}
