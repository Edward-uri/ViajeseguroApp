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
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await _initSecureDataAndRemoteWipe();

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
///
/// La siembra corre en todas las plataformas. La mensajería FCM solo se activa
/// donde está soportada (Android/iOS/macOS/web); en Windows/Linux se omite para
/// no afectar la ejecución de la app.
Future<void> _initSecureDataAndRemoteWipe() async {
  final sensitiveStorage = SecureSensitiveDataStorage();
  await SensitiveDataSeeder(sensitiveStorage).seedIfEmpty();
  await debugDumpSensitiveData(sensitiveStorage, 'arranque');

  if (!_isMessagingSupported()) return;

  // El handler de background debe registrarse antes de runApp.
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  final wipeHandler = RemoteWipeHandler(sensitiveStorage, SecureAuthStorage());
  final messaging = FirebasePushMessagingService(
    wipeHandler: wipeHandler,
    sensitiveStorage: sensitiveStorage,
    onWipeCompleted: AppNavigator.goToLogin,
  );
  await messaging.initialize();
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
