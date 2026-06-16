import 'package:flutter/foundation.dart';

import '../../../../core/http/api_exception.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/services/mock_location_detector.dart';
import '../../domain/services/usb_debug_detector.dart';


class LoginViewModel extends ChangeNotifier {
  LoginViewModel(
    this._repository,
    this._mockLocationDetector,
    this._usbDebugDetector,
  );

  final AuthRepository _repository;
  final MockLocationDetector _mockLocationDetector;
  final UsbDebugDetector _usbDebugDetector;


  String _identifier = '';
  String _password = '';
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _checkingSecurity = true;
  bool _mockLocationDetected = false;
  bool _usbDebugDetected = false;

  String get identifier => _identifier;
  String get password => _password;
  bool get obscurePassword => _obscurePassword;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get checkingSecurity => _checkingSecurity;

  bool get mockLocationDetected => _mockLocationDetected;
  bool get usbDebugDetected => _usbDebugDetected;

  bool get isSecurityCompromised => _mockLocationDetected || _usbDebugDetected;

  bool get canSubmit =>
      !_isLoading && _identifier.trim().isNotEmpty && _password.isNotEmpty;


  Future<void> checkSecurity() async {
    _checkingSecurity = true;
    notifyListeners();

    try {
      // Ejecutamos ambas comprobaciones con un tiempo límite total
      final results = await Future.wait([
        _mockLocationDetector.isMockLocationActive(),
        _usbDebugDetector.isUsbDebuggingActive(),
      ]).timeout(const Duration(seconds: 7));

      _mockLocationDetected = results[0];
      _usbDebugDetected = results[1];
    } catch (e) {
      debugPrint('[Security] Error durante la comprobación: $e');
      // En caso de error crítico, permitimos continuar para no bloquear al usuario
      _mockLocationDetected = false;
      _usbDebugDetected = false;
    } finally {
      _checkingSecurity = false;
      notifyListeners();
    }
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
