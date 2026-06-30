import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/di/core_module.dart';
import '../../../../../core/http/api_exception.dart';
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
  ) : super(const TripInProgressViewModelState());

  final TripRepository _tripRepository;
  final TripTrackingService _trackingService;
  final SocketService _socketService;

  Timer? _pollingTimer;
  StreamSubscription<DriverPosition>? _positionSubscription;
  StreamSubscription<TripSocketEvent>? _acceptedSub;
  StreamSubscription<TripSocketEvent>? _stateChangeSub;

  void setTrip(Trip trip) {
    state = state.copyWith(trip: trip, isLoading: false);

    // Socket events
    _listenSocketEvents(trip.id);

    // Tracking de ubicación del conductor
    _startTracking(trip.id);

    // Polling como fallback (cada 10s, no 5s — el socket es primario)
    _startPolling(trip.id);
  }

  void _listenSocketEvents(String tripId) {
    final tripIdInt = int.tryParse(tripId);
    if (tripIdInt == null) return;

    // viaje:aceptado → objeto Viaje completo del viaje aceptado
    // El conductor aceptó: actualizar con datos del conductor, vehículo, etc.
    _acceptedSub = _socketService.onTripAccepted.listen((event) {
      final updatedTrip = Trip.fromJson(event.data);
      if (updatedTrip.id != tripId) return;

      // Preservar el driverPosition si ya teníamos uno
      state = state.copyWith(
        trip: updatedTrip,
        driverPosition: state.driverPosition,
      );
    });

    // viaje:cambio_estado → { idViaje, estado }
    // en_curso, completado, cancelado
    _stateChangeSub = _socketService.onTripStateChanged.listen((event) {
      if (event.idViaje != tripIdInt) return;
      final newStatus = event.estado;
      if (newStatus == null) return;

      final parsed = Trip.parseStatus(newStatus);
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

      if (parsed == TripStatus.completado ||
          parsed == TripStatus.cancelado) {
        _cleanup();
      }
    });
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
        state = state.copyWith(driverPosition: pos);
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

      if (trip.status == TripStatus.completado ||
          trip.status == TripStatus.cancelado) {
        _cleanup();
      }
    } catch (e) {
      // No mostrar error en polling (es fallback del socket)
      debugPrint('[TripInProgress] Polling error: $e');
    }
  }

  void _cleanup() {
    _pollingTimer?.cancel();
    _stopTracking();
    _acceptedSub?.cancel();
    _stateChangeSub?.cancel();
  }

  void _stopTracking() {
    _trackingService.stopTracking();
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
  );
});
