import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:viajeseguroapp/app.dart';
import 'package:viajeseguroapp/core/di/core_module.dart';
import 'package:viajeseguroapp/core/storage/auth_storage.dart';
import 'package:viajeseguroapp/features/auth/di/auth_module.dart';
import 'package:viajeseguroapp/features/auth/domain/entities/municipio.dart';
import 'package:viajeseguroapp/features/auth/domain/entities/register_params.dart';
import 'package:viajeseguroapp/features/auth/domain/entities/tarifa_zona.dart';
import 'package:viajeseguroapp/features/auth/domain/repositories/auth_repository.dart';
import 'package:viajeseguroapp/features/auth/domain/repositories/municipios_repository.dart';
import 'package:viajeseguroapp/features/auth/domain/services/mock_location_detector.dart';
import 'package:viajeseguroapp/features/auth/domain/services/usb_debug_detector.dart';
import 'package:viajeseguroapp/features/profile/di/profile_module.dart';
import 'package:viajeseguroapp/features/profile/domain/entities/profile_photo_upload_ticket.dart';
import 'package:viajeseguroapp/features/profile/domain/repositories/profile_repository.dart';
import 'package:viajeseguroapp/shared/domain/entities/user.dart';

class _FakeAuthStorage implements AuthStorage {
  String? _token;
  String? _refreshToken;
  String? _user;
  @override
  Future<String?> readToken() async => _token;
  @override
  Future<void> writeToken(String token) async => _token = token;
  @override
  Future<String?> readRefreshToken() async => _refreshToken;
  @override
  Future<void> writeRefreshToken(String token) async => _refreshToken = token;
  @override
  Future<String?> readUser() async => _user;
  @override
  Future<void> writeUser(String userJson) async => _user = userJson;
  @override
  Future<void> clear() async {
    _token = null;
    _refreshToken = null;
    _user = null;
  }
}

class _FakeMockLocationDetector implements MockLocationDetector {
  @override
  Future<bool> isMockLocationActive() async => false;
}

class _FakeUsbDebugDetector implements UsbDebugDetector {
  @override
  Future<bool> isUsbDebuggingActive() async => false;
}

class _FakeAuthRepository implements AuthRepository {
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

class _FakeMunicipiosRepository implements MunicipiosRepository {
  @override
  Future<List<Municipio>> getMunicipios() async => const [
    Municipio(idMunicipio: 1, nombre: 'Suchiapa', estado: 'Chiapas'),
  ];
  @override
  Future<List<TarifaZona>> getTarifas(int idMunicipio) async => const [];
}

class _FakeProfileRepository implements ProfileRepository {
  @override
  Future<User> getMe() => throw UnimplementedError();
  @override
  Future<User> updateProfile({
    String? nombre,
    String? apellidoPaterno,
    String? apellidoMaterno,
    int? idSexo,
    String? fechaNacimiento,
    String? telefono,
  }) =>
      throw UnimplementedError();
  @override
  Future<User> uploadPhotoDirect({
    required List<int> bytes,
    required String fileName,
    required String contentType,
  }) =>
      throw UnimplementedError();
  @override
  Future<ProfilePhotoUploadTicket> requestPhotoUpload({
    required String contentType,
  }) =>
      throw UnimplementedError();
  @override
  Future<User> confirmPhotoUpload({required String s3Key}) =>
      throw UnimplementedError();
  @override
  Future<void> uploadBytesToS3({
    required String uploadUrl,
    required List<int> bytes,
    required String contentType,
  }) =>
      throw UnimplementedError();
  @override
  Future<void> deleteAccount() async {}
}

class _FakeHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(Stream.empty(), 200);
  }
}

void main() {
  testWidgets('La app monta el LoginScreen con el branding "Jala"',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          httpClientProvider.overrideWith((ref) => _FakeHttpClient()),
          authStorageProvider.overrideWith((ref) => _FakeAuthStorage()),
          authRepositoryProvider.overrideWith((ref) => _FakeAuthRepository()),
          mockLocationDetectorProvider.overrideWith((ref) => _FakeMockLocationDetector()),
          usbDebugDetectorProvider.overrideWith((ref) => _FakeUsbDebugDetector()),
          municipiosRepositoryProvider.overrideWith((ref) => _FakeMunicipiosRepository()),
          profileRepositoryProvider.overrideWith((ref) => _FakeProfileRepository()),
        ],
        child: const JalaApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    expect(find.text('Jala'), findsWidgets);
  });
}
