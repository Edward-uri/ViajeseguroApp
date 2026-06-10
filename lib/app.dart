import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';

import 'core/navigation/app_navigator.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/profile/presentation/screens/profile_screen.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'routes/app_routes.dart';
import 'theme/theme.dart';
import 'theme/util.dart';

class JalaApp extends StatelessWidget {
  const JalaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = View.of(context).platformDispatcher.platformBrightness;
    final textTheme =
        createTextTheme(context, 'Plus Jakarta Sans', 'Plus Jakarta Sans');
    final theme = MaterialTheme(textTheme);

    return MaterialApp(
      title: 'Jala',
      navigatorKey: AppNavigator.key,
      debugShowCheckedModeBanner: false,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      theme: theme.light(),
      darkTheme: theme.dark(),
      themeMode:
          brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
      initialRoute: AppRoutes.splash,
      routes: <String, WidgetBuilder>{
        AppRoutes.splash: (_) => const SplashScreen(),
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.register: (_) => const RegisterScreen(),
        AppRoutes.profile: (_) => const ProfileScreen(),
      },
    );
  }
}
