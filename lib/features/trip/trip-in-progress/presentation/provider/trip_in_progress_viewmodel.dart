import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/http/api_exception.dart';
import '../../di/trip_in_progress_module.dart';
import '../../domain/entities/trip.dart';
import '../../domain/repositories/trip_repository.dart';
import '../../domain/services/trip_tracking_service.dart';

class TripInProgressViewModel extends StateNotifier<TripInProgressViewModelState> {
  TripInProgressViewModel(this._tripRepository, this._trackingService)
      : super(const TripInProgressViewModelState());

  final TripRepository _tripRepository;
  final TripTrackingService _trackingService;
  Timer? _pollingTimer;
  StreamSubscription<DriverPosition>? _positionSubscription;

  void setTrip(Trip trip) {
    state = state.copyWith(trip: trip, isLoading: false);
    _startPolling(trip.id);
    _startTracking(trip.id);
  }

  void _startPolling(String tripId) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await _refreshTrip(tripId);
    });
  }

  void _startTracking(String tripId) {
    _positionSubscription?.cancel();
    _positionSubscription = _trackingService.startTracking(tripId).listen(
      (pos) {
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
        _pollingTimer?.cancel();
        _stopTracking();
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e is ApiException ? e.message : 'Error al actualizar viaje',
      );
    }
  }

  void _stopTracking() {
    _trackingService.stopTracking();
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  Future<void> cancelTrip() async {
    if (state.trip == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _tripRepository.cancelTrip(state.trip!.id);
      final cancelledTrip = state.trip!.copyWith(status: TripStatus.cancelado);
      state = state.copyWith(trip: cancelledTrip, isLoading: false);
      _pollingTimer?.cancel();
      _stopTracking();
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
    _pollingTimer?.cancel();
    _stopTracking();
    super.dispose();
  }
}

class TripInProgressViewModelState extends Equatable {
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
    String? errorMessage,
    DriverPosition? driverPosition,
  }) {
    return TripInProgressViewModelState(
      trip: trip ?? this.trip,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
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
  );
});
