// Smoke test: la app arranca, monta el splash con el branding "Jala".
//
// No corre el flujo completo (el splash hace lecturas async al secure
// storage; testearlo end-to-end requiere mockear AuthStorage). Aca solo
// verificamos que el arbol de widgets se construye sin excepciones.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:viajeseguroapp/app.dart';
import 'package:viajeseguroapp/core/storage/auth_storage.dart';
import 'package:viajeseguroapp/features/auth/domain/entities/register_params.dart';
import 'package:viajeseguroapp/features/auth/domain/repositories/auth_repository.dart';
import 'package:viajeseguroapp/features/profile/domain/entities/profile_photo_upload_ticket.dart';
import 'package:viajeseguroapp/features/profile/domain/repositories/profile_repository.dart';
import 'package:viajeseguroapp/shared/domain/entities/user.dart';

class _FakeAuthStorage implements AuthStorage {
  String? _token;
  @override
  Future<String?> readToken() async => _token;
  @override
  Future<void> writeToken(String token) async => _token = token;
  @override
  Future<void> clear() async => _token = null;
}

class _FakeAuthRepository implements AuthRepository {
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

class _FakeProfileRepository implements ProfileRepository {
  @override
  Future<User> getMe() => throw UnimplementedError();
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

void main() {
  testWidgets('La app monta el SplashScreen con el branding "Jala"',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AuthStorage>(create: (_) => _FakeAuthStorage()),
          Provider<AuthRepository>(create: (_) => _FakeAuthRepository()),
          Provider<ProfileRepository>(create: (_) => _FakeProfileRepository()),
        ],
        child: const JalaApp(),
      ),
    );

    // Primer frame: el splash muestra el branding "Jala".
    expect(find.text('Jala'), findsOneWidget);

    // El splash programa un timer de 600ms + un redirect. Lo drenamos para
    // no dejar timers colgados al terminar el test (sino el framework
    // dispara "A Timer is still pending..."). Tras el redirect el usuario
    // no tiene sesion (fake), asi que cae en Login — que tambien muestra "Jala".
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.text('Jala'), findsWidgets);
  });
}
