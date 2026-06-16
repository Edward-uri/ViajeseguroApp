import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/di/core_module.dart';
import 'core/env/api_config.dart';
import 'core/messaging/background_message_handler.dart';
import 'core/messaging/firebase_push_messaging_service.dart';
import 'core/navigation/app_navigator.dart';
import 'core/security/remote_wipe_handler.dart';
import 'core/storage/secure_auth_storage.dart';
import 'core/storage/secure_sensitive_data_storage.dart';
import 'core/storage/sensitive_data_debug.dart';
import 'core/storage/sensitive_data_seeder.dart';
import 'features/auth/di/auth_module.dart';
import 'features/profile/di/profile_module.dart';
import 'firebase_options.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  debugPrint('[App] Iniciando secuencia de arranque...');

  try {
    await dotenv.load(fileName: ".env");
    debugPrint('[App] .env cargado');
  } catch (e) {
    debugPrint('[App] Advertencia: .env no cargado: $e');
  }

  try {

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 5));
    debugPrint('[App] Firebase inicializado');
  } catch (e) {
    debugPrint('[App] Error o Timeout en Firebase: $e');
  }

  try {
    await _initSecureDataAndRemoteWipe();
    debugPrint('[App] Servicios de seguridad inicializados');
  } catch (e) {
    debugPrint('[App] Error en servicios de seguridad: $e');
  }

  if (kDebugMode) {
    debugPrint('[Jala] API baseUrl = ${ApiConfig.baseUrl}');
  }

  runApp(
    MultiProvider(
      providers: [
        ...CoreModule.providers(),
        ...AuthModule.providers(),
        ...ProfileModule.providers(),
      ],
      child: DevicePreview(
        enabled: _shouldEnableDevicePreview(),
        builder: (context) => const JalaApp(),
      ),
    ),
  );
}

/// Siembra los datos sensibles e inicializa el borrado remoto por FCM.
Future<void> _initSecureDataAndRemoteWipe() async {
  final sensitiveStorage = SecureSensitiveDataStorage();
  await SensitiveDataSeeder(sensitiveStorage).seedIfEmpty();
  await debugDumpSensitiveData(sensitiveStorage, 'arranque');

  if (!_isMessagingSupported()) return;

  // El handler de background debe registrarse antes de runApp.
  try {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('[App] No se pudo registrar el background handler: $e');
  }

  final wipeHandler = RemoteWipeHandler(sensitiveStorage, SecureAuthStorage());
  final messaging = FirebasePushMessagingService(
    wipeHandler: wipeHandler,
    sensitiveStorage: sensitiveStorage,
    onWipeCompleted: AppNavigator.goToLogin,
  );
  
  // No esperamos (await) a que termine la inicialización de mensajería para no bloquear el UI
  // si el servicio de tokens de Google está caído.
  messaging.initialize().catchError((e) {
    debugPrint('[App] Error asíncrono en messaging.initialize: $e');
  });
}

bool _isMessagingSupported() {
  if (kIsWeb) return true;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;
}

bool _shouldEnableDevicePreview() {
  if (kReleaseMode) return false;
  if (kIsWeb) return true;
  return defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS;
}
