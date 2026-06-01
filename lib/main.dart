import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/di/core_module.dart';
import 'core/env/api_config.dart';
import 'features/auth/di/auth_module.dart';
import 'features/profile/di/profile_module.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();

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

bool _shouldEnableDevicePreview() {
  if (kReleaseMode) return false;
  if (kIsWeb) return true;
  return defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS;
}
