import '../../../../shared/domain/entities/user.dart';
import '../entities/register_params.dart';

abstract class AuthRepository {
  Future<void> registerStart({required String correo, String rol});

  Future<String> registerVerify({
    required String correo,
    required String codigo,
    String rol,
  });

  Future<User> registerComplete(RegisterParams params);

  Future<User> loginWithPassword({
    required String correo,
    required String contrasena,
    String? dispositivo,
  });

  Future<void> logout({String? refreshToken});

  Future<bool> hasSession();

  Future<User?> getCurrentUser();

  Future<void> registrarDispositivo({
    required String plataforma,
    required String tokenFcm,
  });
}
