import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart';

import '../env/api_config.dart';

/// Eventos de viaje que el servidor emite al pasajero.
class TripSocketEvent {
  final String name;
  final Map<String, dynamic> data;

  TripSocketEvent(this.name, this.data);

  int? get idViaje => data['idViaje'] as int?;
  String? get estado => data['estado'] as String?;

  /// Para `viaje:aceptado`, el objeto Viaje completo.
  Map<String, dynamic>? get viajeData =>
      data.containsKey('idViaje') ? data : null;

  double? get lat => (data['lat'] as num?)?.toDouble();
  double? get lng => (data['lng'] as num?)?.toDouble();
}

/// Servicio global de WebSocket (Socket.IO) para la app del pasajero.
///
/// Se conecta al mismo host de la API con el JWT del usuario.
/// Expone streams para que los ViewModels escuchen eventos de viaje:
/// - `viaje:aceptado` → el conductor aceptó (objeto Viaje completo)
/// - `viaje:cambio_estado` → { idViaje, estado }
/// - `viaje:ubicacion_conductor` → { idViaje, lat, lng }
///
/// Maneja reconexión automática: si el token expira (`connect_error: unauthorized`),
/// pide un token nuevo al [onTokenExpired] callback y reconecta.
class SocketService {
  Socket? _socket;
  final String _baseUrl;
  final String Function() _tokenProvider;
  final Future<bool> Function()? _onTokenExpired;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;

  final StreamController<TripSocketEvent> _tripAcceptedController =
      StreamController<TripSocketEvent>.broadcast();
  final StreamController<TripSocketEvent> _tripStateChangedController =
      StreamController<TripSocketEvent>.broadcast();
  final StreamController<TripSocketEvent> _driverPositionController =
      StreamController<TripSocketEvent>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  SocketService({
    String? baseUrl,
    required String Function() tokenProvider,
    Future<bool> Function()? onTokenExpired,
  })  : _baseUrl = baseUrl ?? ApiConfig.baseUrl,
        _tokenProvider = tokenProvider,
        _onTokenExpired = onTokenExpired;

  /// Streams públicos que los ViewModels escuchan.
  Stream<TripSocketEvent> get onTripAccepted => _tripAcceptedController.stream;
  Stream<TripSocketEvent> get onTripStateChanged =>
      _tripStateChangedController.stream;
  Stream<TripSocketEvent> get onDriverPosition =>
      _driverPositionController.stream;
  Stream<bool> get onConnectionChange => _connectionController.stream;

  bool get isConnected => _socket?.connected ?? false;

  /// Conecta al WebSocket con el JWT actual.
  void connect() {
    if (_socket?.connected ?? false) return;

    final token = _tokenProvider();
    if (token.isEmpty) return;

    _socket = io(
      _baseUrl,
      OptionBuilder()
          .setAuth({'token': token})
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(2000)
          .setReconnectionAttempts(999)
          .build(),
    );

    _socket!.onConnect((_) {
      _reconnectAttempts = 0;
      _connectionController.add(true);
    });

    _socket!.onDisconnect((_) {
      _connectionController.add(false);
    });

    _socket!.onConnectError((e) {
      final msg = e.toString();
      _connectionController.add(false);

      // Si el error es de auth (token expirado), intentar refrescar
      if (msg.contains('unauthorized') || msg.contains('token')) {
        _tryRefreshAndReconnect();
      }
    });

    _socket!.onReconnectAttempt((_) {
      _reconnectAttempts++;
    });

    // === Eventos de viaje → pasajero ===
    // viaje:aceptado → objeto Viaje completo del viaje aceptado
    _socket!.on('viaje:aceptado', (data) {
      if (data is Map<String, dynamic>) {
        _tripAcceptedController.add(TripSocketEvent('viaje:aceptado', data));
      }
    });

    // viaje:cambio_estado → { idViaje, estado }
    _socket!.on('viaje:cambio_estado', (data) {
      if (data is Map<String, dynamic>) {
        _tripStateChangedController
            .add(TripSocketEvent('viaje:cambio_estado', data));
      }
    });

    // viaje:ubicacion_conductor → { idViaje, lat, lng }
    _socket!.on('viaje:ubicacion_conductor', (data) {
      if (data is Map<String, dynamic>) {
        _driverPositionController
            .add(TripSocketEvent('viaje:ubicacion_conductor', data));
      }
    });

    _socket!.connect();
  }

  /// Intenta refrescar el token y reconectar el socket.
  Future<void> _tryRefreshAndReconnect() async {
    if (_onTokenExpired == null) return;
    if (_reconnectAttempts > 5) return;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 2), () async {
      final refreshed = await _onTokenExpired();
      if (refreshed) {
        disconnect();
        connect();
      }
    });
  }

  /// Comparte la ubicación del pasajero con el conductor del viaje activo.
  /// El servidor la reenvía como `viaje:ubicacion_pasajero` al conductor.
  void emitPassengerLocation({
    required int idViaje,
    required double lat,
    required double lng,
  }) {
    _socket?.emit('pasajero:ubicacion', {
      'idViaje': idViaje,
      'lat': lat,
      'lng': lng,
    });
  }

  /// Desconecta y limpia listeners.
  void disconnect() {
    _reconnectTimer?.cancel();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  /// Reconecta con un token nuevo (tras refresh manual).
  void reconnect() {
    disconnect();
    connect();
  }

  void dispose() {
    disconnect();
    _tripAcceptedController.close();
    _tripStateChangedController.close();
    _driverPositionController.close();
    _connectionController.close();
  }
}
