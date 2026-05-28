import '../../../../shared/domain/entities/user.dart';
import '../entities/register_params.dart';


abstract class AuthRepository {
  Future<User> login({required String identifier, required String password});

  Future<User> register(RegisterParams params);

  Future<void> logout();

  Future<bool> hasSession();
}
