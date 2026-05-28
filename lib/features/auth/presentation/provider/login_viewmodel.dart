import 'package:flutter/foundation.dart';

import '../../../../core/http/api_exception.dart';
import '../../domain/repositories/auth_repository.dart';


class LoginViewModel extends ChangeNotifier {
  LoginViewModel(this._repository);

  final AuthRepository _repository;


  String _identifier = '';
  String _password = '';
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  String get identifier => _identifier;
  String get password => _password;
  bool get obscurePassword => _obscurePassword;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get canSubmit =>
      !_isLoading && _identifier.trim().isNotEmpty && _password.isNotEmpty;


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
