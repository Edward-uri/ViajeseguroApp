import 'package:flutter_test/flutter_test.dart';
import 'package:viajeseguroapp/features/auth/domain/entities/register_params.dart';
import 'package:viajeseguroapp/features/auth/domain/repositories/auth_repository.dart';
import 'package:viajeseguroapp/features/auth/domain/services/mock_location_detector.dart';
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

class _StubDetector implements MockLocationDetector {
  _StubDetector(this.result);
  final bool result;
  int calls = 0;
  @override
  Future<bool> isMockLocationActive() async {
    calls++;
    return result;
  }
}

void main() {
  group('LoginViewModel.checkMockLocation', () {
    test('marca mockLocationDetected = true cuando el detector lo reporta',
        () async {
      final detector = _StubDetector(true);
      final vm = LoginViewModel(_StubAuthRepository(), detector);

      await vm.checkMockLocation();

      expect(detector.calls, 1);
      expect(vm.mockLocationDetected, isTrue);
      expect(vm.checkingMockLocation, isFalse);
    });

    test('deja mockLocationDetected = false cuando no hay mock', () async {
      final vm = LoginViewModel(_StubAuthRepository(), _StubDetector(false));

      await vm.checkMockLocation();

      expect(vm.mockLocationDetected, isFalse);
      expect(vm.checkingMockLocation, isFalse);
    });

    test('arranca en estado "verificando" antes de la primera consulta', () {
      final vm = LoginViewModel(_StubAuthRepository(), _StubDetector(false));

      expect(vm.checkingMockLocation, isTrue);
      expect(vm.mockLocationDetected, isFalse);
    });
  });
}
