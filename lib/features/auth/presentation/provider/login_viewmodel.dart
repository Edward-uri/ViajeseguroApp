import 'package:flutter/foundation.dart';

import '../../../../core/http/api_exception.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/services/mock_location_detector.dart';


class LoginViewModel extends ChangeNotifier {
  LoginViewModel(this._repository, this._mockLocationDetector);

  final AuthRepository _repository;
  final MockLocationDetector _mockLocationDetector;


  String _identifier = '';
  String _password = '';
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _checkingMockLocation = true;
  bool _mockLocationDetected = false;

  String get identifier => _identifier;
  String get password => _password;
  bool get obscurePassword => _obscurePassword;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get checkingMockLocation => _checkingMockLocation;

  bool get mockLocationDetected => _mockLocationDetected;

  bool get canSubmit =>
      !_isLoading && _identifier.trim().isNotEmpty && _password.isNotEmpty;


  Future<void> checkMockLocation() async {
    _checkingMockLocation = true;
    notifyListeners();

    final detected = await _mockLocationDetector.isMockLocationActive();

    _mockLocationDetected = detected;
    _checkingMockLocation = false;
    notifyListeners();
  }


  void setIdentifier(String value) {
    _identifier = value;
    notifyListeners();
  }

  void setPassword(String value) {
    _password = value;
    notifyListeners();
  }

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }


  Future<bool> submit() async {
    if (!canSubmit) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.login(
        identifier: _identifier.trim(),
        password: _password,
      );
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Ocurrio un error inesperado';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
