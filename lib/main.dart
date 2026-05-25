import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'features/auth/login_screen.dart';
import 'theme/theme.dart';
import 'theme/util.dart';

void main() {
  runApp(
    DevicePreview(
      enabled: _shouldEnableDevicePreview(),
      builder: (context) => const ViajeSeguroApp(),
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

class ViajeSeguroApp extends StatelessWidget {
  const ViajeSeguroApp({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = View.of(context).platformDispatcher.platformBrightness;
    final textTheme =
        createTextTheme(context, 'Plus Jakarta Sans', 'Plus Jakarta Sans');
    final theme = MaterialTheme(textTheme);

    return MaterialApp(
      title: 'ViajeSeguro',
      debugShowCheckedModeBanner: false,
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      theme: theme.light(),
      darkTheme: theme.dark(),
      themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
      home: const LoginScreen(),
    );
  }
}
