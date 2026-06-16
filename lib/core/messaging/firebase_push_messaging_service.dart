import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../security/remote_wipe_handler.dart';
import '../storage/sensitive_data_debug.dart';
import '../storage/sensitive_data_storage.dart';
import 'push_messaging_service.dart';

/// Implementación de [PushMessagingService] sobre `firebase_messaging`.
///
/// Se suscribe al topic específico del usuario almacenado (`wipe-<username>`) y
/// delega el procesamiento de cada mensaje en [RemoteWipeHandler]. Cuando un
/// mensaje produce un borrado, invoca [onWipeCompleted] (usado para navegar a
/// Login desde la capa de presentación).
class FirebasePushMessagingService implements PushMessagingService {
  FirebasePushMessagingService({
    required RemoteWipeHandler wipeHandler,
    required SensitiveDataStorage sensitiveStorage,
    this.onWipeCompleted,
  })  : _wipeHandler = wipeHandler,
        _sensitiveStorage = sensitiveStorage;

  final RemoteWipeHandler _wipeHandler;
  final SensitiveDataStorage _sensitiveStorage;
  final void Function()? onWipeCompleted;

  static String topicForUser(String username) => 'wipe-$username';

  @override
  Future<void> initialize() async {
    final messaging = FirebaseMessaging.instance;

    try {
      await messaging.requestPermission();

      // Topic específico del usuario almacenado: el borrado se dirige solo a él.
      final username = await _sensitiveStorage.readUsername();
      if (username != null && username.isNotEmpty) {
        await messaging.subscribeToTopic(topicForUser(username));
        if (kDebugMode) {
          debugPrint('[FCM] suscrito al topic: ${topicForUser(username)}');
        }
      }

      // Token del dispositivo, útil para "Enviar mensaje de prueba" en la consola.
      if (kDebugMode) {
        try {
          final token = await messaging.getToken();
          debugPrint('[FCM] token del dispositivo: $token');
        } catch (e) {
          debugPrint('[FCM] No se pudo obtener el token: $e');
        }
      }
    } catch (e) {
      debugPrint('[FCM] Error inicializando mensajería: $e');
      // No bloqueamos el inicio de la app si falla Firebase (ej. sin internet o sin Play Services)
    }

    // App en primer plano.
    FirebaseMessaging.onMessage.listen(_onMessage);

    // App reabierta desde una notificación.
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessage);

    // App lanzada desde estado terminado por una notificación.
    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      await _onMessage(initial);
    }
  }

  Future<void> _onMessage(RemoteMessage message) async {
    if (kDebugMode) {
      debugPrint('[RemoteWipe] mensaje recibido. data=${message.data}');
    }
    final wiped = await _wipeHandler.handle(message.data);
    if (kDebugMode) {
      debugPrint('[RemoteWipe] ¿se ejecutó el borrado? $wiped');
      await debugDumpSensitiveData(_sensitiveStorage, 'después del wipe');
    }
    if (wiped) {
      onWipeCompleted?.call();
    }
  }
}
