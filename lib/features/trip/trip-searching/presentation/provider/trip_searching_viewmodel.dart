import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../../../core/auth/current_user_provider.dart';
import '../../../../../core/http/api_exception.dart';
import '../../../trip-in-progress/di/trip_in_progress_module.dart';
import '../../../trip-in-progress/domain/entities/estimacion_viaje.dart';
import '../../../trip-in-progress/domain/entities/trip.dart';
import '../../../trip-in-progress/domain/repositories/trip_repository.dart';
import '../../di/trip_searching_module.dart';
import '../../domain/entities/trip_location.dart';
import '../../domain/repositories/trip_search_repository.dart';

enum TripSearchingStep {
  selectingOrigin,
  selectingDestination,
  readyToConfirm,
  fareShown,
}

enum LocationInputMode {
  origin,
  destination,
}

class TripSearchingViewModel extends StateNotifier<TripSearchingViewModelState> {
  TripSearchingViewModel(
    this._tripSearchRepository,
    this._tripRepository,
    this._currentUserNotifier,
  ) : super(const TripSearchingViewModelState());

  final TripSearchRepository _tripSearchRepository;
  final TripRepository _tripRepository;
  final CurrentUserNotifier _currentUserNotifier;

  Timer? _debounceTimer;

  void activateOriginInput() {
    state = state.copyWith(
      activeInput: LocationInputMode.origin,
      searchQuery: '',
      searchResults: [],
      isPickingOnMap: false,
    );
  }

  void activateDestinationInput() {
    if (state.origin == null) return;
    state = state.copyWith(
      activeInput: LocationInputMode.destination,
      searchQuery: '',
      searchResults: [],
      isPickingOnMap: false,
    );
  }

  void startPickOnMap() {
    state = state.copyWith(
      isPickingOnMap: true,
      searchQuery: '',
      searchResults: [],
    );
  }

  void cancelPickOnMap() {
    state = state.copyWith(
      isPickingOnMap: false,
      pendingMapAddress: null,
    );
  }

  void updatePendingMapPosition(double latitude, double longitude) {
    state = state.copyWith(
      pendingMapLat: latitude,
      pendingMapLng: longitude,
    );
  }

  Future<void> confirmPinFromMap() async {
    final lat = state.pendingMapLat;
    final lng = state.pendingMapLng;
    if (lat == null || lng == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final location = await _tripSearchRepository.reverseGeocode(lat, lng);
      final resolved = location.copyWith(latitude: lat, longitude: lng);

      if (state.activeInput == LocationInputMode.origin) {
        state = state.copyWith(
          origin: resolved,
          activeInput: LocationInputMode.destination,
          step: TripSearchingStep.selectingDestination,
          isPickingOnMap: false,
          pendingMapAddress: null,
          searchQuery: '',
          searchResults: [],
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          destination: resolved,
          step: TripSearchingStep.readyToConfirm,
          isPickingOnMap: false,
          pendingMapAddress: null,
          searchQuery: '',
          searchResults: [],
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e is ApiException ? e.message : 'Error al obtener direccion',
      );
    }
  }

  void searchAddress(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      state = state.copyWith(searchResults: [], isSearching: false);
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      state = state.copyWith(isSearching: true, searchError: null);
      try {
        final results = await _tripSearchRepository.searchAddress(query);
        state = state.copyWith(searchResults: results, isSearching: false);
      } catch (e) {
        state = state.copyWith(
          isSearching: false,
          searchError: e is ApiException ? e.message : 'Error al buscar direccion',
        );
      }
    });
  }

  void selectOrigin(TripLocation location) {
    state = state.copyWith(
      origin: location,
      activeInput: LocationInputMode.destination,
      step: TripSearchingStep.selectingDestination,
      searchResults: [],
      searchQuery: '',
      isPickingOnMap: false,
    );
  }

  void selectDestination(TripLocation location) {
    state = state.copyWith(
      destination: location,
      step: TripSearchingStep.readyToConfirm,
      searchResults: [],
      searchQuery: '',
      isPickingOnMap: false,
    );
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    searchAddress(query);
  }

  void resetDestination() {
    state = TripSearchingViewModelState(
      step: TripSearchingStep.selectingDestination,
      activeInput: LocationInputMode.destination,
      origin: state.origin,
      searchQuery: '',
      searchResults: [],
      isPickingOnMap: false,
    );
  }

  void resetAll() {
    state = const TripSearchingViewModelState();
  }

  void clearError() {
    if (state.errorMessage == null && state.searchError == null) return;
    state = state.copyWith(errorMessage: null, searchError: null);
  }

  List<Point> get routePoints {
    if (state.origin == null || state.destination == null) return [];
    return [
      Point(coordinates: Position(state.origin!.longitude, state.origin!.latitude)),
      Point(coordinates: Position(state.destination!.longitude, state.destination!.latitude)),
    ];
  }

  void setNumPersonas(int n) {
    if (n < 1 || n > 3) return;
    state = state.copyWith(numPersonas: n, estimacion: null);
  }

  Future<void> requestFare() async {
    if (state.origin == null || state.destination == null) return;

    final idMunicipio = _currentUserNotifier.user?.idMunicipio ?? 1;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      // Verificar si ya hay un viaje activo
      final activeTrip = await _tripRepository.getActiveTrip();
      if (activeTrip != null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Ya tienes un viaje activo. Cancélalo primero desde el historial.',
        );
        return;
      }

      final estimacion = await _tripRepository.estimarViaje(
        idMunicipio: idMunicipio,
        origin: state.origin!,
        destination: state.destination!,
        personas: state.numPersonas,
      );
      state = state.copyWith(
        estimacion: estimacion,
        isLoading: false,
        step: TripSearchingStep.fareShown,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al estimar viaje',
      );
    }
  }

  Future<Trip?> confirmFare() async {
    if (state.origin == null || state.destination == null) return null;

    final idMunicipio = _currentUserNotifier.user?.idMunicipio ?? 1;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final trip = await _tripRepository.createTrip(
        idMunicipio: idMunicipio,
        origin: state.origin!,
        destination: state.destination!,
        personas: state.numPersonas,
        idZonaDestino: state.estimacion?.idZonaDestino,
      );
      state = const TripSearchingViewModelState();
      return trip;
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
      return null;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al crear viaje',
      );
      return null;
    }
  }

  Trip? acceptFare() {
    final trip = state.trip;
    if (trip == null) return null;
    state = const TripSearchingViewModelState();
    return trip;
  }

  Future<void> rejectFare() async {
    state = state.copyWith(
      estimacion: null,
      step: TripSearchingStep.readyToConfirm,
      isLoading: false,
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

class TripSearchingViewModelState extends Equatable {
  static const _sentinel = Object();

  const TripSearchingViewModelState({
    this.step = TripSearchingStep.selectingOrigin,
    this.activeInput = LocationInputMode.origin,
    this.origin,
    this.destination,
    this.trip,
    this.estimacion,
    this.numPersonas = 1,
    this.searchQuery = '',
    this.searchResults = const [],
    this.isSearching = false,
    this.searchError,
    this.isLoading = false,
    this.errorMessage,
    this.isPickingOnMap = false,
    this.pendingMapLat,
    this.pendingMapLng,
    this.pendingMapAddress,
  });

  final TripSearchingStep step;
  final LocationInputMode activeInput;
  final TripLocation? origin;
  final TripLocation? destination;
  final Trip? trip;
  final EstimacionViaje? estimacion;
  final int numPersonas;
  final String searchQuery;
  final List<TripLocation> searchResults;
  final bool isSearching;
  final String? searchError;
  final bool isLoading;
  final String? errorMessage;
  final bool isPickingOnMap;
  final double? pendingMapLat;
  final double? pendingMapLng;
  final String? pendingMapAddress;

  bool get hasRoute => origin != null && destination != null;

  bool get isOriginActive => activeInput == LocationInputMode.origin;
  bool get isDestinationActive => activeInput == LocationInputMode.destination;

  TripSearchingViewModelState copyWith({
    TripSearchingStep? step,
    LocationInputMode? activeInput,
    TripLocation? origin,
    TripLocation? destination,
    Trip? trip,
    EstimacionViaje? estimacion,
    int? numPersonas,
    String? searchQuery,
    List<TripLocation>? searchResults,
    bool? isSearching,
    String? searchError,
    bool? isLoading,
    Object? errorMessage = _sentinel,
    bool? isPickingOnMap,
    double? pendingMapLat,
    double? pendingMapLng,
    String? pendingMapAddress,
  }) {
    return TripSearchingViewModelState(
      step: step ?? this.step,
      activeInput: activeInput ?? this.activeInput,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      trip: trip ?? this.trip,
      estimacion: estimacion ?? this.estimacion,
      numPersonas: numPersonas ?? this.numPersonas,
      searchQuery: searchQuery ?? this.searchQuery,
      searchResults: searchResults ?? this.searchResults,
      isSearching: isSearching ?? this.isSearching,
      searchError: searchError ?? this.searchError,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _sentinel) ? this.errorMessage : errorMessage as String?,
      isPickingOnMap: isPickingOnMap ?? this.isPickingOnMap,
      pendingMapLat: pendingMapLat ?? this.pendingMapLat,
      pendingMapLng: pendingMapLng ?? this.pendingMapLng,
      pendingMapAddress: pendingMapAddress ?? this.pendingMapAddress,
    );
  }

  @override
  List<Object?> get props => [
        step,
        activeInput,
        origin,
        destination,
        trip,
        estimacion,
        numPersonas,
        searchQuery,
        searchResults,
        isSearching,
        searchError,
        isLoading,
        errorMessage,
        isPickingOnMap,
        pendingMapLat,
        pendingMapLng,
        pendingMapAddress,
      ];
}

final tripSearchingViewModelProvider =
    StateNotifierProvider<TripSearchingViewModel, TripSearchingViewModelState>((ref) {
  return TripSearchingViewModel(
    ref.watch(tripSearchRepositoryProvider),
    ref.watch(tripRepositoryProvider),
    ref.watch(currentUserProvider.notifier),
  );
});
