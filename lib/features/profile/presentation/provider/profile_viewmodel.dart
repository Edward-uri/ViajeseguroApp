import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/core_module.dart';
import '../../../../core/http/api_exception.dart';
import '../../../../core/storage/auth_storage.dart';
import '../../../../shared/domain/entities/user.dart';
import '../../../auth/di/auth_module.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../di/profile_module.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileViewModel extends StateNotifier<ProfileViewModelState> {
  ProfileViewModel(this._profileRepo, this._authRepo, this._authStorage)
      : super(const ProfileViewModelState());

  final ProfileRepository _profileRepo;
  final AuthRepository _authRepo;
  final AuthStorage _authStorage;

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, errorMessage: null, hasSessionExpired: false);
    try {
      final user = await _profileRepo.getMe();
      state = ProfileViewModelState(user: user);
    } on UnauthorizedException {
      await _authRepo.logout();
      state = const ProfileViewModelState(
        errorMessage: 'Tu sesion expiro. Inicia sesion de nuevo.',
        hasSessionExpired: true,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Ocurrio un error inesperado',
      );
    }
  }

  Future<bool> updateProfile({
    String? nombre,
    String? apellidoPaterno,
    String? apellidoMaterno,
    int? idSexo,
    String? fechaNacimiento,
    String? telefono,
  }) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      await _profileRepo.updateProfile(
        nombre: nombre,
        apellidoPaterno: apellidoPaterno,
        apellidoMaterno: apellidoMaterno,
        idSexo: idSexo,
        fechaNacimiento: fechaNacimiento,
        telefono: telefono,
      );
      await loadProfile();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'No se pudo actualizar el perfil',
      );
      return false;
    }
  }

  Future<bool> uploadNewPhoto({
    required List<int> bytes,
    required String contentType,
    required String fileName,
  }) async {
    if (state.user == null) return false;
    state = state.copyWith(isUploadingPhoto: true, errorMessage: null);
    try {
      await _profileRepo.uploadPhotoDirect(
        bytes: bytes,
        fileName: fileName,
        contentType: contentType,
      );
      await loadProfile();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        isUploadingPhoto: false,
        errorMessage: e.message,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isUploadingPhoto: false,
        errorMessage: 'No se pudo actualizar la foto',
      );
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    state = state.copyWith(isDeleting: true, errorMessage: null);
    try {
      await _profileRepo.deleteAccount();
      await _authRepo.logout();
      state = const ProfileViewModelState();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        isDeleting: false,
        errorMessage: e.message,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isDeleting: false,
        errorMessage: 'No se pudo eliminar la cuenta',
      );
      return false;
    }
  }

  Future<void> logout() async {
    final refreshToken = await _authStorage.readRefreshToken();
    await _authRepo.logout(refreshToken: refreshToken);
    state = const ProfileViewModelState();
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

class ProfileViewModelState {
  const ProfileViewModelState({
    this.user,
    this.isLoading = false,
    this.isSaving = false,
    this.isUploadingPhoto = false,
    this.isDeleting = false,
    this.errorMessage,
    this.hasSessionExpired = false,
  });

  final User? user;
  final bool isLoading;
  final bool isSaving;
  final bool isUploadingPhoto;
  final bool isDeleting;
  final String? errorMessage;
  final bool hasSessionExpired;

  ProfileViewModelState copyWith({
    User? user,
    bool? isLoading,
    bool? isSaving,
    bool? isUploadingPhoto,
    bool? isDeleting,
    String? errorMessage,
    bool? hasSessionExpired,
  }) {
    return ProfileViewModelState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isUploadingPhoto: isUploadingPhoto ?? this.isUploadingPhoto,
      isDeleting: isDeleting ?? this.isDeleting,
      errorMessage: errorMessage,
      hasSessionExpired: hasSessionExpired ?? this.hasSessionExpired,
    );
  }
}

final profileViewModelProvider = StateNotifierProvider<ProfileViewModel, ProfileViewModelState>((ref) {
  return ProfileViewModel(
    ref.watch(profileRepositoryProvider),
    ref.watch(authRepositoryProvider),
    ref.watch(authStorageProvider),
  );
});
