import 'package:flutter_test/flutter_test.dart';
import 'package:viajeseguroapp/core/auth/current_user_provider.dart';
import 'package:viajeseguroapp/features/auth/domain/entities/register_params.dart';
import 'package:viajeseguroapp/features/auth/domain/repositories/auth_repository.dart';
import 'package:viajeseguroapp/features/auth/domain/services/mock_location_detector.dart';
import 'package:viajeseguroapp/features/auth/domain/services/usb_debug_detector.dart';
import 'package:viajeseguroapp/features/auth/presentation/provider/login_viewmodel.dart';
import 'package:viajeseguroapp/shared/domain/entities/user.dart';

class _StubAuthRepository implements AuthRepository {
  @override
  Future<bool> hasSession() async => false;
  @override
  Future<User> loginWithPassword({required String correo, required String contrasena, String? dispositivo}) =>
      throw UnimplementedError();
  @override
  Future<void> registerStart({required String correo, String rol = 'pasajero'}) async {}
  @override
  Future<String> registerVerify({required String correo, required String codigo, String rol = 'pasajero'}) =>
      throw UnimplementedError();
  @override
  Future<User> registerComplete(RegisterParams params) => throw UnimplementedError();
  @override
  Future<void> logout({String? refreshToken}) async {}
  @override
  Future<User?> getCurrentUser() async => null;
  @override
  Future<void> registrarDispositivo({required String plataforma, required String tokenFcm}) async {}
}

class _StubLocationDetector implements MockLocationDetector {
  _StubLocationDetector(this.result);
  final bool result;
  int calls = 0;
  @override
  Future<bool> isMockLocationActive() async {
    calls++;
    return result;
  }
}

class _StubUsbDetector implements UsbDebugDetector {
  _StubUsbDetector(this.result);
  final bool result;
  int calls = 0;
  @override
  Future<bool> isUsbDebuggingActive() async {
    calls++;
    return result;
  }
}

void main() {
  group('LoginViewModel Security Checks', () {
    test('marca mockLocationDetected = true cuando el detector lo reporta',
        () async {
      final detector = _StubLocationDetector(true);
      final usb = _StubUsbDetector(false);
      final vm = LoginViewModel(
        _StubAuthRepository(),
        detector,
        usb,
        CurrentUserNotifier(),
      );

      await vm.checkSecurity();

      expect(detector.calls, 1);
      expect(vm.state.mockLocationDetected, isTrue);
      expect(vm.state.checkingSecurity, isFalse);
    });

    test('marca usbDebugDetected = true cuando el detector lo reporta',
        () async {
      final detector = _StubLocationDetector(false);
      final usb = _StubUsbDetector(true);
      final vm = LoginViewModel(
        _StubAuthRepository(),
        detector,
        usb,
        CurrentUserNotifier(),
      );

      await vm.checkSecurity();

      expect(usb.calls, 1);
      expect(vm.state.usbDebugDetected, isTrue);
      expect(vm.state.checkingSecurity, isFalse);
    });

    test('deja todo en false cuando no hay riesgos detectados', () async {
      final vm = LoginViewModel(
        _StubAuthRepository(),
        _StubLocationDetector(false),
        _StubUsbDetector(false),
        CurrentUserNotifier(),
      );

      await vm.checkSecurity();

      expect(vm.state.mockLocationDetected, isFalse);
      expect(vm.state.usbDebugDetected, isFalse);
      expect(vm.state.checkingSecurity, isFalse);
    });

    test('arranca en estado "verificando" antes de la primera consulta', () {
      final vm = LoginViewModel(
        _StubAuthRepository(),
        _StubLocationDetector(false),
        _StubUsbDetector(false),
        CurrentUserNotifier(),
      );

      expect(vm.state.checkingSecurity, isTrue);
      expect(vm.state.mockLocationDetected, isFalse);
      expect(vm.state.usbDebugDetected, isFalse);
    });
  });
}
