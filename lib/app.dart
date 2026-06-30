import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';

import 'core/navigation/app_navigator.dart';
import 'core/widgets/page_transitions.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/passenger/home/presentation/screens/passenger_home_screen.dart';
import 'features/profile/presentation/screens/profile_screen.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'features/trip/trip-in-progress/domain/entities/trip.dart';
import 'features/trip/trip-in-progress/presentation/screens/trip_evaluation_screen.dart';
import 'features/trip/trip-in-progress/presentation/screens/trip_in_progress_screen.dart';
import 'features/trip/trip-searching/presentation/screens/trip_searching_screen.dart';
import 'routes/app_routes.dart';
import 'theme/jala_theme.dart';

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
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case AppRoutes.splash:
            return PageTransitions.fadeThrough(const SplashScreen());
          case AppRoutes.login:
            return PageTransitions.slideUp(const LoginScreen());
          case AppRoutes.register:
            return PageTransitions.slideRight(const RegisterScreen());
          case AppRoutes.profile:
            return PageTransitions.scaleFade(const ProfileScreen());
          case AppRoutes.passengerHome:
            return PageTransitions.fadeThrough(const PassengerHomeScreen());
          case AppRoutes.tripSearching:
            return PageTransitions.slideUp(const TripSearchingScreen());
          case AppRoutes.tripInProgress:
            final trip = settings.arguments as Trip;
            return PageTransitions.slideUp(TripInProgressScreen(trip: trip));
          case AppRoutes.tripEvaluation:
            final trip = settings.arguments as Trip;
            return PageTransitions.slideUp(TripEvaluationScreen(trip: trip));
          default:
            return PageTransitions.fadeThrough(const LoginScreen());
        }
      },
    );
  }
}
