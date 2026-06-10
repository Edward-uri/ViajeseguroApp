import '../storage/auth_storage.dart';
import '../storage/sensitive_data_storage.dart';

/// Procesa órdenes de borrado remoto recibidas por FCM.
///
/// El borrado es **específico de un usuario**: solo se ejecuta si el mensaje
/// trae el comando esperado y su `targetUser` coincide con el usuario que está
/// almacenado en el dispositivo.
class RemoteWipeHandler {
  const RemoteWipeHandler(this._sensitiveStorage, this._authStorage);

  final SensitiveDataStorage _sensitiveStorage;
  final AuthStorage _authStorage;

  static const String wipeCommand = 'wipe_secure_data';

  /// Procesa el payload `data` de un mensaje FCM.
  ///
  /// Devuelve `true` únicamente si se ejecutó el borrado (comando válido y
  /// usuario destino coincidente). En cualquier otro caso devuelve `false` y no
  /// modifica nada.
  Future<bool> handle(Map<String, dynamic> data) async {
    if (data['command'] != wipeCommand) return false;

    final targetUser = data['targetUser'];
    final storedUsername = await _sensitiveStorage.readUsername();

    if (targetUser == null ||
        storedUsername == null ||
        storedUsername.isEmpty ||
        targetUser != storedUsername) {
      return false;
    }

    // Elimina los datos sensibles y cierra la sesión (borra el JWT).
    await _sensitiveStorage.clear();
    await _authStorage.clear();
    return true;
  }
}
