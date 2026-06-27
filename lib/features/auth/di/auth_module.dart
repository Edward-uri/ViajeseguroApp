import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/core_module.dart';
import '../data/auth_repository_impl.dart';
import '../data/municipios_repository_impl.dart';
import '../data/platform/mock_location_detector_impl.dart';
import '../data/platform/usb_debug_detector_impl.dart';
import '../data/remote/auth_api.dart';
import '../data/remote/dispositivos_api.dart';
import '../data/remote/municipios_api.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/municipios_repository.dart';
import '../domain/services/mock_location_detector.dart';
import '../domain/services/usb_debug_detector.dart';

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(apiClientProvider));
});

final dispositivosApiProvider = Provider<DispositivosApi>((ref) {
  return DispositivosApi(ref.watch(apiClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(authApiProvider),
    ref.watch(authStorageProvider),
    ref.watch(dispositivosApiProvider),
  );
});

final municipiosApiProvider = Provider<MunicipiosApi>((ref) {
  return MunicipiosApi(ref.watch(apiClientProvider));
});

final municipiosRepositoryProvider = Provider<MunicipiosRepository>((ref) {
  return MunicipiosRepositoryImpl(ref.watch(municipiosApiProvider));
});

final mockLocationDetectorProvider = Provider<MockLocationDetector>((ref) {
  return MockLocationDetectorImpl();
});

// ⚠️ TEMPORAL — Bypass de la deteccion de USB debugging para poder perfilar la
// app con `flutter run --profile` (requiere el dispositivo conectado por USB con
// depuracion activa; de lo contrario cae en la pantalla de bloqueo de seguridad).
// REACTIVAR (poner en false) antes de entregar / hacer release.
const bool kBypassUsbDebugCheck = true;

final usbDebugDetectorProvider = Provider<UsbDebugDetector>((ref) {
  // Blindaje: el bypass SOLO surte efecto fuera de release. En un build de
  // produccion la deteccion de USB debugging sigue activa pase lo que pase.
  if (kBypassUsbDebugCheck && !kReleaseMode) {
    return _DisabledUsbDebugDetector();
  }
  return UsbDebugDetectorImpl();
});

/// Detector no-op: reporta que NO hay USB debugging. Se usa solo cuando
/// [kBypassUsbDebugCheck] esta activo en builds no-release.
class _DisabledUsbDebugDetector implements UsbDebugDetector {
  @override
  Future<bool> isUsbDebuggingActive() async => false;
}
