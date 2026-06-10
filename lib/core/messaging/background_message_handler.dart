import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../firebase_options.dart';
import '../security/remote_wipe_handler.dart';
import '../storage/secure_auth_storage.dart';
import '../storage/secure_sensitive_data_storage.dart';

/// Handler de mensajes FCM cuando la app está en background o cerrada.
///
/// Se ejecuta en un isolate independiente, por lo que NO hay acceso al árbol de
/// `Provider`: Firebase se inicializa y las dependencias se construyen aquí
/// mismo. El borrado del almacenamiento seguro funciona en este isolate; la
/// navegación a Login ocurrirá al reabrir la app (el Splash detecta que ya no
/// hay sesión).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final handler = RemoteWipeHandler(
    SecureSensitiveDataStorage(),
    SecureAuthStorage(),
  );
  await handler.handle(message.data);
}
