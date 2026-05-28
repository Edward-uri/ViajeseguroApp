import 'package:flutter/foundation.dart';

import '../../../../core/http/api_exception.dart';
import '../../domain/entities/register_params.dart';
import '../../domain/repositories/auth_repository.dart';


class RegisterViewModel extends ChangeNotifier {
  RegisterViewModel(this._repository);

  final AuthRepository _repository;

  String _nombreUsuario = '';
  String _password = '';
  String _nombre = '';
  String _apellidoPaterno = '';
  String _apellidoMaterno = '';
  String _correoElectronico = '';
  String _telefono = '';


  final String _rol = 'pasajero';

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  String get nombreUsuario => _nombreUsuario;
  String get password => _password;
  String get nombre => _nombre;
  String get apellidoPaterno => _apellidoPaterno;
  String get apellidoMaterno => _apellidoMaterno;
  String get correoElectronico => _correoElectronico;
  String get telefono => _telefono;
  String get rol => _rol;
  bool get obscurePassword => _obscurePassword;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get canSubmit =>
      !_isLoading &&
      _nombreUsuario.trim().length >= 3 &&
      _password.length >= 8 &&
      _nombre.trim().isNotEmpty &&
      _apellidoPaterno.trim().isNotEmpty &&
      _correoElectronico.trim().contains('@');

  void setNombreUsuario(String v) { _nombreUsuario = v; notifyListeners(); }
  void setPassword(String v)      { _password = v;      notifyListeners(); }
  void setNombre(String v)        { _nombre = v;        notifyListeners(); }
  void setApellidoPaterno(String v) { _apellidoPaterno = v; notifyListeners(); }
  void setApellidoMaterno(String v) { _apellidoMaterno = v; notifyListeners(); }
  void setCorreo(String v)        { _correoElectronico = v; notifyListeners(); }
  void setTelefono(String v)      { _telefono = v;      notifyListeners(); }

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
      await _repository.register(
        RegisterParams(
          nombreUsuario: _nombreUsuario.trim(),
          password: _password,
          rol: _rol,
          nombre: _nombre.trim(),
          apellidoPaterno: _apellidoPaterno.trim(),
          apellidoMaterno:
              _apellidoMaterno.trim().isEmpty ? null : _apellidoMaterno.trim(),
          correoElectronico: _correoElectronico.trim(),
          telefono: _telefono.trim().isEmpty ? null : _telefono.trim(),
        ),
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
