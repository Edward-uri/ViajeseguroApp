import 'package:flutter/foundation.dart';

import '../../../../core/http/api_exception.dart';
import '../../../../shared/domain/entities/user.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/repositories/profile_repository.dart';


class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel(this._profileRepo, this._authRepo);

  final ProfileRepository _profileRepo;
  final AuthRepository _authRepo;

  User? _user;
  bool _isLoading = false;
  bool _isUploadingPhoto = false;
  bool _isDeleting = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isUploadingPhoto => _isUploadingPhoto;
  bool get isDeleting => _isDeleting;
  String? get errorMessage => _errorMessage;

  Future<void> loadProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _user = await _profileRepo.getMe();
    } on UnauthorizedException {
      // JWT vencido o invalido. La View detectara `user == null` y
      // sabra que tiene que ir al login.
      await _authRepo.logout();
      _errorMessage = 'Tu sesion expiro. Inicia sesion de nuevo.';
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Ocurrio un error inesperado';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  Future<bool> uploadNewPhoto({
    required List<int> bytes,
    required String contentType,
  }) async {
    if (_user == null) return false;
    _isUploadingPhoto = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final ticket =
          await _profileRepo.requestPhotoUpload(contentType: contentType);
      if (bytes.length > ticket.maxBytes) {
        throw ApiException(
          'La imagen excede el tamano maximo permitido (${ticket.maxBytes ~/ (1024 * 1024)} MB).',
        );
      }
      await _profileRepo.uploadBytesToS3(
        uploadUrl: ticket.uploadUrl,
        bytes: bytes,
        contentType: contentType,
      );
      _user = await _profileRepo.confirmPhotoUpload(s3Key: ticket.s3Key);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'No se pudo actualizar la foto';
      return false;
    } finally {
      _isUploadingPhoto = false;
      notifyListeners();
    }
  }

  Future<bool> deleteAccount() async {
    _isDeleting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _profileRepo.deleteAccount();
      await _authRepo.logout();
      _user = null;
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'No se pudo eliminar la cuenta';
      return false;
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authRepo.logout();
    _user = null;
    notifyListeners();
  }
}
