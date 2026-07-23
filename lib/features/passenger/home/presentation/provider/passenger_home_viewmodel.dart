import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/auth/current_user_provider.dart';
import '../../../../../shared/domain/entities/user.dart';
import '../../../../profile/di/profile_module.dart';
import '../../../../profile/domain/repositories/profile_repository.dart';
import '../../../../trip/trip-in-progress/di/trip_in_progress_module.dart';
import '../../../../trip/trip-in-progress/domain/entities/trip.dart';
import '../../../../trip/trip-in-progress/domain/repositories/trip_repository.dart';

class PassengerHomeViewModel extends StateNotifier<PassengerHomeViewModelState> {
  PassengerHomeViewModel(this._profileRepo, this._currentUserNotifier, this._tripRepo)
      : super(const PassengerHomeViewModelState());

  final ProfileRepository _profileRepo;
  final CurrentUserNotifier _currentUserNotifier;
  final TripRepository _tripRepo;

  Future<void> loadUser() async {
    final cached = _currentUserNotifier.user;
    if (cached != null) {
      state = state.copyWith(user: cached, isLoading: false);
    } else {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }

    // El usuario de la sesion (login/restauracion) no incluye `nombre`; solo
    // /api/users/me lo trae. Pedirlo siempre para mostrar el nombre real del
    // pasajero en el menu y el saludo del home. Si falla pero hay usuario en
    // cache, se conserva sin marcar error.
    try {
      final user = await _profileRepo.getMe();
      _currentUserNotifier.setUser(user);
      state = state.copyWith(user: user, isLoading: false);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: cached == null ? 'No se pudo cargar el perfil' : null,
      );
    }

    // Limpiar viaje activo inmediatamente para que la UI muestre
    // la barra de busqueda mientras se verifica con el backend.
    state = state.copyWith(activeTrip: null);
    await checkActiveTrip();
  }

  Future<void> checkActiveTrip() async {
    try {
      final trip = await _tripRepo.getActiveTrip();
      if (!mounted) return;
      if (trip != null &&
          (trip.status == TripStatus.completado ||
           trip.status == TripStatus.cancelado)) {
        state = state.copyWith(activeTrip: null);
      } else {
        state = state.copyWith(activeTrip: trip);
      }
    } catch (e) {
      debugPrint('[PassengerHome] Error checking active trip: $e');
      if (mounted) state = state.copyWith(activeTrip: null);
    }
  }

  void clearActiveTrip() {
    if (!mounted) return;
    state = state.copyWith(activeTrip: null);
  }

  void selectTab(int index) {
    if (state.selectedIndex == index) return;
    state = state.copyWith(selectedIndex: index);
  }
}

class PassengerHomeViewModelState extends Equatable {
  static const _sentinel = Object();

  const PassengerHomeViewModelState({
    this.selectedIndex = 0,
    this.user,
    this.isLoading = false,
    this.errorMessage,
    this.activeTrip,
  });

  final int selectedIndex;
  final User? user;
  final bool isLoading;
  final String? errorMessage;
  final Trip? activeTrip;

  bool get hasActiveTrip =>
      activeTrip != null &&
      activeTrip!.status != TripStatus.completado &&
      activeTrip!.status != TripStatus.cancelado;

  String get greetingName {
    if (user == null) return 'Pasajero';
    return user!.nombreParaMostrar;
  }

  PassengerHomeViewModelState copyWith({
    int? selectedIndex,
    User? user,
    bool? isLoading,
    Object? errorMessage = _sentinel,
    Object? activeTrip = _sentinel,
  }) {
    return PassengerHomeViewModelState(
      selectedIndex: selectedIndex ?? this.selectedIndex,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _sentinel) ? this.errorMessage : errorMessage as String?,
      activeTrip: identical(activeTrip, _sentinel) ? this.activeTrip : activeTrip as Trip?,
    );
  }

  @override
  List<Object?> get props => [selectedIndex, user, isLoading, errorMessage, activeTrip];
}

final passengerHomeViewModelProvider = StateNotifierProvider<PassengerHomeViewModel, PassengerHomeViewModelState>((ref) {
  return PassengerHomeViewModel(
    ref.watch(profileRepositoryProvider),
    ref.watch(currentUserProvider.notifier),
    ref.watch(tripRepositoryProvider),
  );
});
