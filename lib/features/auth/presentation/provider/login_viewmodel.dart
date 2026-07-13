import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/current_user_provider.dart';
import '../../../../core/http/api_exception.dart';
import '../../di/auth_module.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/services/mock_location_detector.dart';
import '../../domain/services/usb_debug_detector.dart';

enum LoginStep {
  email,
}

class LoginViewModel extends StateNotifier<LoginViewModelState> {
  LoginViewModel(
    this._repository,
    this._mockLocationDetector,
    this._usbDebugDetector,
    this._currentUserNotifier,
  ) : super(const LoginViewModelState());

  final AuthRepository _repository;
  final MockLocationDetector _mockLocationDetector;
  final UsbDebugDetector _usbDebugDetector;
  final CurrentUserNotifier _currentUserNotifier;
  Timer? _errorTimer;

  String _correo = '';
  String _contrasena = '';
  bool _isChecking = false;

  String get correo => _correo;
  String get contrasena => _contrasena;

  void _updateCanSubmit() {
    bool canSubmit;
    switch (state.step) {
      case LoginStep.email:
        canSubmit = _correo.trim().contains('@') &&
            _correo.length >= 5 &&
            _contrasena.length >= 8;
        break;
    }
    if (state.canSubmit != canSubmit) {
      state = state.copyWith(canSubmit: canSubmit);
    }
  }

  Future<void> checkSecurity() async {
    if (_isChecking) return;
    _isChecking = true;
    state = state.copyWith(checkingSecurity: true);
    _updateCanSubmit();

    try {
      final results = await Future.wait([
        _mockLocationDetector.isMockLocationActive(),
        _usbDebugDetector.isUsbDebuggingActive(),
      ]).timeout(const Duration(seconds: 7));

      if (!_isChecking) return;
      state = state.copyWith(
        checkingSecurity: false,
        mockLocationDetected: results[0],
        usbDebugDetected: results[1],
      );
    } catch (e) {
      if (!_isChecking) return;
      state = state.copyWith(
        checkingSecurity: false,
        mockLocationDetected: false,
        usbDebugDetected: false,
      );
    }
    _isChecking = false;
    _updateCanSubmit();
  }

  void setCorreo(String value) {
    _correo = value;
    _updateCanSubmit();
  }

  void setContrasena(String value) {
    _contrasena = value;
    _updateCanSubmit();
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

  Future<bool> login() async {
    state = state.copyWith(isLoading: true);
    _updateCanSubmit();
    try {
      final user = await _repository.loginWithPassword(
        correo: _correo.trim(),
        contrasena: _contrasena,
      );
      _currentUserNotifier.setUser(user);
      _registrarDispositivo();
      state = state.copyWith(isLoading: false);
      return true;
    } on ApiException catch (e) {
      await _repository.logout();
      _currentUserNotifier.clear();
      state = state.copyWith(isLoading: false);
      _setError(e.message);
      _updateCanSubmit();
      return false;
    } catch (_) {
      await _repository.logout();
      _currentUserNotifier.clear();
      state = state.copyWith(isLoading: false);
      _setError('Ocurrio un error inesperado');
      _updateCanSubmit();
      return false;
    }
  }

  void _registrarDispositivo() {
    Future.microtask(() async {
      try {
        final token = await FirebaseMessaging.instance.getToken();
        if (token == null || token.isEmpty) return;
        await _repository.registrarDispositivo(
          plataforma: Platform.operatingSystem,
          tokenFcm: token,
        );
      } catch (_) {}
    });
  }
}

class LoginViewModelState {
  const LoginViewModelState({
    this.step = LoginStep.email,
    this.isLoading = false,
    this.errorMessage,
    this.checkingSecurity = true,
    this.mockLocationDetected = false,
    this.usbDebugDetected = false,
    this.canSubmit = false,
  });

  final LoginStep step;
  final bool isLoading;
  final String? errorMessage;
  final bool checkingSecurity;
  final bool mockLocationDetected;
  final bool usbDebugDetected;
  final bool canSubmit;

  bool get isSecurityCompromised => mockLocationDetected || usbDebugDetected;

  static const _sentinel = Object();

  LoginViewModelState copyWith({
    LoginStep? step,
    bool? isLoading,
    Object? errorMessage = _sentinel,
    bool? checkingSecurity,
    bool? mockLocationDetected,
    bool? usbDebugDetected,
    bool? canSubmit,
  }) {
    return LoginViewModelState(
      step: step ?? this.step,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      checkingSecurity: checkingSecurity ?? this.checkingSecurity,
      mockLocationDetected: mockLocationDetected ?? this.mockLocationDetected,
      usbDebugDetected: usbDebugDetected ?? this.usbDebugDetected,
      canSubmit: canSubmit ?? this.canSubmit,
    );
  }
}

final loginViewModelProvider =
    StateNotifierProvider<LoginViewModel, LoginViewModelState>((ref) {
  return LoginViewModel(
    ref.watch(authRepositoryProvider),
    ref.watch(mockLocationDetectorProvider),
    ref.watch(usbDebugDetectorProvider),
    ref.watch(currentUserProvider.notifier),
  );
});
