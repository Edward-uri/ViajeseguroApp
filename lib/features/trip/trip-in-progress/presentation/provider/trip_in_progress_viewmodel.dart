import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/di/core_module.dart';
import '../../../../../core/http/api_exception.dart';
import '../../../../../core/notifications/trip_notification_service.dart';
import '../../../../../core/websocket/socket_service.dart';
import '../../../trip-searching/domain/entities/trip_location.dart';
import '../../../trip-searching/domain/entities/trip_fare.dart';
import '../../di/trip_in_progress_module.dart';
import '../../domain/entities/trip.dart';
import '../../domain/repositories/trip_repository.dart';
import '../../domain/services/trip_tracking_service.dart';

class TripInProgressViewModel extends StateNotifier<TripInProgressViewModelState> {
  TripInProgressViewModel(
    this._tripRepository,
    this._trackingService,
    this._socketService,
    this._tripNotification,
  ) : super(const TripInProgressViewModelState());

  final TripRepository _tripRepository;
  final TripTrackingService _trackingService;
  final SocketService _socketService;
  final TripNotificationService _tripNotification;

  Timer? _pollingTimer;
  StreamSubscription<DriverPosition>? _positionSubscription;
  StreamSubscription<TripSocketEvent>? _acceptedSub;
  StreamSubscription<TripSocketEvent>? _stateChangeSub;
  TripStatus? _notifiedStatus;

  void setTrip(Trip trip) {
    state = state.copyWith(trip: trip, isLoading: false);

    // Socket events
    _listenSocketEvents(trip.id);

    // Tracking de ubicación del conductor
    _startTracking(trip.id);

    // Comparte mi ubicación con el conductor (para que me vea acercarme).
    _trackingService.startSharingLocation(trip.id);

    // Polling como fallback (cada 10s, no 5s — el socket es primario)
    _startPolling(trip.id);
  }

  void _listenSocketEvents(String tripId) {
    final tripIdInt = int.tryParse(tripId);
    if (tripIdInt == null) return;

    // viaje:aceptado → objeto Viaje completo del viaje aceptado
    // El conductor aceptó: refrescar para obtener datos completos del conductor
    _acceptedSub = _socketService.onTripAccepted.listen((event) async {
      if (event.idViaje != tripIdInt) return;
      // Refrescar para obtener driverName, driverPhone, vehicleInfo, etc.
      await _refreshTrip(tripId);
    });

    // viaje:cambio_estado → { idViaje, estado }
    // en_curso, completado, cancelado, solicitado (regreso del conductor)
    _stateChangeSub = _socketService.onTripStateChanged.listen((event) async {
      if (event.idViaje != tripIdInt) return;
      final newStatus = event.estado;
      if (newStatus == null) return;

      final parsed = Trip.parseStatus(newStatus);

      // Si volvió a solicitado (conductor soltó el viaje),
      // refrescar para obtener expiraEn actualizado
      if (parsed == TripStatus.solicitado) {
        await _refreshTrip(tripId);
        return;
      }

      // Si se canceló, refrescar para obtener canceladoPor/motivo
      if (parsed == TripStatus.cancelado) {
        await _refreshTrip(tripId);
        return;
      }

      final updatedTrip = state.trip?.copyWith(status: parsed) ??
          Trip(
            id: tripId,
            origin: TripLocation.empty,
            destination: TripLocation.empty,
            fare: TripFare.empty,
            status: parsed,
          );

      state = state.copyWith(
        trip: updatedTrip,
        driverPosition: state.driverPosition,
      );
      _syncTripNotification();

      if (parsed == TripStatus.completado) {
        _cleanup();
      }
    });
  }

  /// Único punto que mantiene la notificación del viaje sincronizada con el
  /// estado: título/ETA por fase, alerta (sonido+vibración) solo al cambiar
  /// de fase, y se quita cuando el viaje deja de estar activo.
  void _syncTripNotification() {
    final status = state.trip?.status;
    if (status != TripStatus.aceptado && status != TripStatus.enCurso) {
      if (_notifiedStatus != null) {
        _notifiedStatus = null;
        if (status == TripStatus.completado) {
          // Viaje terminado: aviso con sonido y vibración.
          _tripNotification.finish(
            title: 'Viaje completado',
            body: 'Llegaste a tu destino. ¡Gracias por viajar con Jala!',
          );
        } else {
          _tripNotification.cancel();
        }
      }
      return;
    }

    final eta = state.etaMin;
    final String title;
    final String body;
    if (status == TripStatus.aceptado) {
      title = 'Tu mototaxi está en camino';
      body = eta != null ? 'Llega en ~$eta min' : 'Tu conductor va hacia ti';
    } else {
      title = 'Viaje en curso';
      body = eta != null
          ? 'Llegas a tu destino en ~$eta min'
          : 'Rumbo a tu destino';
    }

    _tripNotification.update(
      title: title,
      body: body,
      alert: status != _notifiedStatus,
    );
    _notifiedStatus = status;
  }

  void _startPolling(String tripId) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      await _refreshTrip(tripId);
    });
  }

  void _startTracking(String tripId) {
    _positionSubscription?.cancel();
    _positionSubscription = _trackingService.startTracking(tripId).listen(
      (pos) {
        // Solo actualizar si el viaje está activo (aceptado o en_curso)
        final status = state.trip?.status;
        if (status != TripStatus.aceptado && status != TripStatus.enCurso) {
          return;
        }
        // El backend recalcula el ETA cada ~15s; si un tick viene sin ETA
        // (OSRM falló), conservar el último conocido para que no parpadee.
        final prev = state.driverPosition;
        state = state.copyWith(
          driverPosition: DriverPosition(
            latitude: pos.latitude,
            longitude: pos.longitude,
            heading: pos.heading,
            speed: pos.speed,
            timestamp: pos.timestamp,
            etaPickupMin: pos.etaPickupMin ?? prev?.etaPickupMin,
            etaDestinationMin:
                pos.etaDestinationMin ?? prev?.etaDestinationMin,
          ),
        );
        _syncTripNotification();
      },
      onError: (e) {
        debugPrint('[TripInProgress] Error tracking: $e');
      },
    );
  }

  Future<void> _refreshTrip(String tripId) async {
    try {
      final trip = await _tripRepository.getTripById(tripId);
      state = state.copyWith(trip: trip, isLoading: false);
      _syncTripNotification();

      if (trip.status == TripStatus.completado) {
        _cleanup();
      } else if (trip.status == TripStatus.cancelado) {
        _cleanup();
      }
      // Si volvió a solicitado, NO limpiar — seguir en la pantalla de búsqueda
    } catch (e) {
      debugPrint('[TripInProgress] Polling error: $e');
    }
  }

  void _cleanup() {
    _pollingTimer?.cancel();
    _stopTracking();
    _acceptedSub?.cancel();
    _stateChangeSub?.cancel();
    _notifiedStatus = null;
    _tripNotification.cancel();
  }

  void _stopTracking() {
    _trackingService.stopTracking();
    _trackingService.stopSharingLocation();
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  Future<void> cancelTrip({String? motivo}) async {
    if (state.trip == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _tripRepository.cancelTrip(state.trip!.id, motivo: motivo);
      final cancelledTrip = state.trip!.copyWith(status: TripStatus.cancelado);
      state = state.copyWith(trip: cancelledTrip, isLoading: false);
      _syncTripNotification();
      _cleanup();
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cancelar viaje',
      );
    }
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }
}

class TripInProgressViewModelState extends Equatable {
  static const _sentinel = Object();

  const TripInProgressViewModelState({
    this.trip,
    this.isLoading = false,
    this.errorMessage,
    this.driverPosition,
  });

  final Trip? trip;
  final bool isLoading;
  final String? errorMessage;
  final DriverPosition? driverPosition;

  bool get hasDriver => trip?.driverName != null;
  bool get isActive =>
      trip?.status == TripStatus.aceptado ||
      trip?.status == TripStatus.enCurso;

  /// ETA en minutos según la fase: llegada del conductor al origen
  /// (aceptado) o llegada al destino (en curso). Null si aún no hay dato.
  int? get etaMin {
    switch (trip?.status) {
      case TripStatus.aceptado:
        return driverPosition?.etaPickupMin;
      case TripStatus.enCurso:
        return driverPosition?.etaDestinationMin;
      default:
        return null;
    }
  }

  TripInProgressViewModelState copyWith({
    Trip? trip,
    bool? isLoading,
    Object? errorMessage = _sentinel,
    DriverPosition? driverPosition,
  }) {
    return TripInProgressViewModelState(
      trip: trip ?? this.trip,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _sentinel) ? this.errorMessage : errorMessage as String?,
      driverPosition: driverPosition ?? this.driverPosition,
    );
  }

  @override
  List<Object?> get props => [trip, isLoading, errorMessage, driverPosition];
}

final tripInProgressViewModelProvider =
    StateNotifierProvider<TripInProgressViewModel, TripInProgressViewModelState>((ref) {
  return TripInProgressViewModel(
    ref.watch(tripRepositoryProvider),
    ref.watch(tripTrackingServiceProvider),
    ref.watch(socketServiceProvider),
    ref.watch(tripNotificationServiceProvider),
  );
});
