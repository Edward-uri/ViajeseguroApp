import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/http/api_exception.dart';
import '../../di/auth_module.dart';
import '../../domain/entities/municipio.dart';
import '../../domain/entities/register_params.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/municipios_repository.dart';

enum RegisterStep {
  email,
  otp,
  formPersonal,
  formAdditional,
}

class RegisterViewModel extends StateNotifier<RegisterViewModelState> {
  RegisterViewModel(this._repository, this._municipiosRepository)
      : super(const RegisterViewModelState());

  final AuthRepository _repository;
  final MunicipiosRepository _municipiosRepository;
  Timer? _errorTimer;

  String _correo = '';
  String _codigo = '';
  String _registrationToken = '';
  String _nombre = '';
  String _apellidoPaterno = '';
  String _apellidoMaterno = '';
  String _telefono = '';
  String _idSexo = '';
  String _fechaNacimiento = '';
  String _idMunicipio = '';
  String _contrasena = '';
  String _confirmarContrasena = '';

  String get correo => _correo;
  String get codigo => _codigo;
  String get nombre => _nombre;
  String get apellidoPaterno => _apellidoPaterno;
  String get apellidoMaterno => _apellidoMaterno;
  String get telefono => _telefono;
  String get idSexo => _idSexo;
  String get fechaNacimiento => _fechaNacimiento;
  String get idMunicipio => _idMunicipio;
  String get contrasena => _contrasena;
  String get confirmarContrasena => _confirmarContrasena;

  void _updateCanSubmit() {
    bool canSubmit;
    switch (state.step) {
      case RegisterStep.email:
        canSubmit = _correo.trim().contains('@') && _correo.length >= 5;
        break;
      case RegisterStep.otp:
        canSubmit = _codigo.length == 6;
        break;
      case RegisterStep.formPersonal:
        canSubmit = _nombre.trim().isNotEmpty &&
            _apellidoPaterno.trim().isNotEmpty;
        break;
      case RegisterStep.formAdditional:
        canSubmit = _telefono.trim().isNotEmpty &&
            _idSexo.isNotEmpty &&
            _fechaNacimiento.isNotEmpty &&
            _idMunicipio.isNotEmpty &&
            _contrasena.length >= 8 &&
            _hasUpperCase(_contrasena) &&
            _hasLowerCase(_contrasena) &&
            _hasDigit(_contrasena) &&
            _confirmarContrasena == _contrasena;
        break;
    }
    if (state.canSubmit != canSubmit) {
      state = state.copyWith(canSubmit: canSubmit);
    }
  }

  void setCorreo(String v) {
    _correo = v;
    _updateCanSubmit();
  }

  void setCodigo(String v) {
    if (v.length <= 6) {
      _codigo = v;
      _updateCanSubmit();
    }
  }

  void setNombre(String v) {
    _nombre = v;
    _updateCanSubmit();
  }

  void setApellidoPaterno(String v) {
    _apellidoPaterno = v;
    _updateCanSubmit();
  }

  void setApellidoMaterno(String v) {
    _apellidoMaterno = v;
  }

  void setTelefono(String v) {
    _telefono = v;
  }

  void setIdSexo(String v) {
    _idSexo = v;
  }

  void setFechaNacimiento(String v) {
    _fechaNacimiento = v;
  }

  void setIdMunicipio(String v) {
    _idMunicipio = v;
    _updateCanSubmit();
  }

  void setContrasena(String v) {
    _contrasena = v;
    _updateCanSubmit();
  }

  void setConfirmarContrasena(String v) {
    _confirmarContrasena = v;
    _updateCanSubmit();
  }

  bool get passwordsMatch => _contrasena == _confirmarContrasena;

  bool _hasUpperCase(String s) => s.contains(RegExp(r'[A-Z]'));
  bool _hasLowerCase(String s) => s.contains(RegExp(r'[a-z]'));
  bool _hasDigit(String s) => s.contains(RegExp(r'[0-9]'));

  bool get passwordHasMinLength => _contrasena.length >= 8;
  bool get passwordHasUpperCase => _hasUpperCase(_contrasena);
  bool get passwordHasLowerCase => _hasLowerCase(_contrasena);
  bool get passwordHasDigit => _hasDigit(_contrasena);
  bool get passwordIsValid =>
      passwordHasMinLength &&
      passwordHasUpperCase &&
      passwordHasLowerCase &&
      passwordHasDigit;

  Future<void> loadMunicipios() async {
    if (state.municipiosLoaded) return;
    state = state.copyWith(municipiosLoading: true);
    try {
      final municipios = await _municipiosRepository.getMunicipios();
      state = state.copyWith(
        municipios: municipios,
        municipiosLoaded: true,
        municipiosLoading: false,
      );
    } catch (_) {
      state = state.copyWith(municipiosLoading: false);
    }
  }

  void clearError() {
    _errorTimer?.cancel();
    _errorTimer = null;
    state = state.copyWith(errorMessage: null);
  }

  void _setError(String message) {
    _errorTimer?.cancel();
    state = state.copyWith(errorMessage: message);
    _errorTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) clearError();
    });
  }

  @override
  void dispose() {
    _errorTimer?.cancel();
    super.dispose();
  }

  void goBackToEmail() {
    _codigo = '';
    state = state.copyWith(
      step: RegisterStep.email,
      errorMessage: null,
    );
    _updateCanSubmit();
  }

  void goBackToOtp() {
    state = state.copyWith(
      step: RegisterStep.otp,
      errorMessage: null,
    );
    _updateCanSubmit();
  }

  void goBackToPersonalForm() {
    state = state.copyWith(
      step: RegisterStep.formPersonal,
      errorMessage: null,
    );
    _updateCanSubmit();
  }

  void resetToEmail() {
    _correo = '';
    _codigo = '';
    _registrationToken = '';
    _nombre = '';
    _apellidoPaterno = '';
    _apellidoMaterno = '';
    _telefono = '';
    _idSexo = '';
    _fechaNacimiento = '';
    _idMunicipio = '';
    _contrasena = '';
    _confirmarContrasena = '';
    state = const RegisterViewModelState();
    _updateCanSubmit();
  }

  void goToAdditionalForm() {
    state = state.copyWith(
      step: RegisterStep.formAdditional,
      errorMessage: null,
    );
    _updateCanSubmit();
  }
  Future<bool> sendOtp() async {
    if (state.step != RegisterStep.email) return false;
    state = state.copyWith(isLoading: true);
    _updateCanSubmit();
    try {
      await _repository.registerStart(correo: _correo.trim());
      state = state.copyWith(
        isLoading: false,
        step: RegisterStep.otp,
      );
      _updateCanSubmit();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false);
      _setError(e.message);
      _updateCanSubmit();
      return false;
    } catch (_) {
      state = state.copyWith(isLoading: false);
      _setError('Ocurrio un error inesperado');
      _updateCanSubmit();
      return false;
    }
  }

  Future<bool> verifyOtp() async {
    if (state.step != RegisterStep.otp) return false;
    state = state.copyWith(isLoading: true);
    _updateCanSubmit();
    try {
      _registrationToken = await _repository.registerVerify(
        correo: _correo.trim(),
        codigo: _codigo,
      );
      state = state.copyWith(
        isLoading: false,
        step: RegisterStep.formPersonal,
      );
      _updateCanSubmit();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false);
      _setError(e.message);
      _updateCanSubmit();
      return false;
    } catch (_) {
      state = state.copyWith(isLoading: false);
      _setError('Ocurrio un error inesperado');
      _updateCanSubmit();
      return false;
    }
  }

  Future<bool> completeRegistration() async {
    if (state.step != RegisterStep.formAdditional) return false;
    state = state.copyWith(isLoading: true);
    _updateCanSubmit();
    try {
      await _repository.registerComplete(RegisterParams(
        registrationToken: _registrationToken,
        nombre: _nombre.trim(),
        apellidoPaterno: _apellidoPaterno.trim(),
        contrasena: _contrasena,
        apellidoMaterno: _apellidoMaterno.trim().isEmpty
            ? null
            : _apellidoMaterno.trim(),
        telefono: _telefono.trim().isEmpty ? null : _telefono.trim(),
        idSexo: _idSexo.isEmpty ? null : int.parse(_idSexo),
        fechaNacimiento: _fechaNacimiento.isEmpty ? null : _fechaNacimiento,
        idMunicipio: _idMunicipio.isEmpty ? null : int.parse(_idMunicipio),
      ));
      state = state.copyWith(isLoading: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false);
      _setError(e.message);
      _updateCanSubmit();
      return false;
    } catch (_) {
      state = state.copyWith(isLoading: false);
      _setError('Ocurrio un error inesperado');
      _updateCanSubmit();
      return false;
    }
  }
}

class RegisterViewModelState {
  const RegisterViewModelState({
    this.step = RegisterStep.email,
    this.isLoading = false,
    this.errorMessage,
    this.canSubmit = false,
    this.municipios = const [],
    this.municipiosLoading = false,
    this.municipiosLoaded = false,
  });

  final RegisterStep step;
  final bool isLoading;
  final String? errorMessage;
  final bool canSubmit;
  final List<Municipio> municipios;
  final bool municipiosLoading;
  final bool municipiosLoaded;

  static const _sentinel = Object();

  RegisterViewModelState copyWith({
    RegisterStep? step,
    bool? isLoading,
    Object? errorMessage = _sentinel,
    bool? canSubmit,
    List<Municipio>? municipios,
    bool? municipiosLoading,
    bool? municipiosLoaded,
  }) {
    return RegisterViewModelState(
      step: step ?? this.step,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      canSubmit: canSubmit ?? this.canSubmit,
      municipios: municipios ?? this.municipios,
      municipiosLoading: municipiosLoading ?? this.municipiosLoading,
      municipiosLoaded: municipiosLoaded ?? this.municipiosLoaded,
    );
  }
}

final registerViewModelProvider =
    StateNotifierProvider<RegisterViewModel, RegisterViewModelState>((ref) {
  return RegisterViewModel(
    ref.watch(authRepositoryProvider),
    ref.watch(municipiosRepositoryProvider),
  );
});
