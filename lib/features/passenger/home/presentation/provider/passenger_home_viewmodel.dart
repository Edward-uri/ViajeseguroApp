import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/auth/current_user_provider.dart';
import '../../../../../shared/domain/entities/user.dart';
import '../../../../profile/di/profile_module.dart';
import '../../../../profile/domain/repositories/profile_repository.dart';

class PassengerHomeViewModel extends StateNotifier<PassengerHomeViewModelState> {
  PassengerHomeViewModel(this._profileRepo, this._currentUserNotifier)
      : super(const PassengerHomeViewModelState());

  final ProfileRepository _profileRepo;
  final CurrentUserNotifier _currentUserNotifier;

  Future<void> loadUser() async {
    final cached = _currentUserNotifier.user;
    if (cached != null) {
      state = state.copyWith(user: cached, isLoading: false);
      return;
    }
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _profileRepo.getMe();
      _currentUserNotifier.setUser(user);
      state = state.copyWith(user: user, isLoading: false);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No se pudo cargar el perfil',
      );
    }
  }

  void selectTab(int index) {
    if (state.selectedIndex == index) return;
    state = state.copyWith(selectedIndex: index);
  }
}

class PassengerHomeViewModelState {
  const PassengerHomeViewModelState({
    this.selectedIndex = 0,
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  final int selectedIndex;
  final User? user;
  final bool isLoading;
  final String? errorMessage;

  String get greetingName {
    if (user == null) return 'Pasajero';
    return user!.nombreParaMostrar;
  }

  PassengerHomeViewModelState copyWith({
    int? selectedIndex,
    User? user,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PassengerHomeViewModelState(
      selectedIndex: selectedIndex ?? this.selectedIndex,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final passengerHomeViewModelProvider = StateNotifierProvider<PassengerHomeViewModel, PassengerHomeViewModelState>((ref) {
  return PassengerHomeViewModel(
    ref.watch(profileRepositoryProvider),
    ref.watch(currentUserProvider.notifier),
  );
});
