import 'package:flutter_test/flutter_test.dart';
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
  Future<User> login({required String identifier, required String password}) =>
      throw UnimplementedError();
  @override
  Future<User> register(RegisterParams params) => throw UnimplementedError();
  @override
  Future<void> logout() async {}
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
      final vm = LoginViewModel(_StubAuthRepository(), detector, usb);

      await vm.checkSecurity();

      expect(detector.calls, 1);
      expect(vm.mockLocationDetected, isTrue);
      expect(vm.checkingSecurity, isFalse);
    });

    test('marca usbDebugDetected = true cuando el detector lo reporta',
        () async {
      final detector = _StubLocationDetector(false);
      final usb = _StubUsbDetector(true);
      final vm = LoginViewModel(_StubAuthRepository(), detector, usb);

      await vm.checkSecurity();

      expect(usb.calls, 1);
      expect(vm.usbDebugDetected, isTrue);
      expect(vm.checkingSecurity, isFalse);
    });

    test('deja todo en false cuando no hay riesgos detectados', () async {
      final vm = LoginViewModel(
        _StubAuthRepository(),
        _StubLocationDetector(false),
        _StubUsbDetector(false),
      );

      await vm.checkSecurity();

      expect(vm.mockLocationDetected, isFalse);
      expect(vm.usbDebugDetected, isFalse);
      expect(vm.checkingSecurity, isFalse);
    });

    test('arranca en estado "verificando" antes de la primera consulta', () {
      final vm = LoginViewModel(
        _StubAuthRepository(),
        _StubLocationDetector(false),
        _StubUsbDetector(false),
      );

      expect(vm.checkingSecurity, isTrue);
      expect(vm.mockLocationDetected, isFalse);
      expect(vm.usbDebugDetected, isFalse);
    });
  });
}
