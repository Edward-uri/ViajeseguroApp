import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';

/// Acceso a la navegación desde fuera del árbol de widgets.
///
/// Necesario para reaccionar a eventos globales (p. ej. un borrado remoto por
/// FCM) que deben llevar al usuario a la pantalla de Login sin un `context`.
class AppNavigator {
  const AppNavigator._();

  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();

  /// Envía al usuario a Login y limpia la pila de navegación.
  static void goToLogin() {
    final navigator = key.currentState;
    if (navigator == null) return;
    navigator.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }
}
