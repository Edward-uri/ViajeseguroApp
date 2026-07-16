import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../navigation/app_navigator.dart';
import '../../routes/app_routes.dart';
import '../../theme/theme.dart';

/// Tipo de notificación de viaje — determina título, mensaje y duración.
enum TripNotificationType {
  conductorEnCamino,
  viajeEnCurso,
  viajeTerminado,
}

class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService instance = LocalNotificationService._();
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'jala_trip_channel';
  static const _channelName = 'Estado del viaje';
  static const _channelDescription = 'Notificaciones de cambios de estado del viaje';

  /// Mapa de duración de auto-dismiss por tipo de notificación (en segundos).
  static const _autoDismissSeconds = {
    TripNotificationType.conductorEnCamino: 8,
    TripNotificationType.viajeEnCurso: 5,
    TripNotificationType.viajeTerminado: 10,
  };

  static const _titles = {
    TripNotificationType.conductorEnCamino: 'Conductor en camino',
    TripNotificationType.viajeEnCurso: 'Viaje en curso',
    TripNotificationType.viajeTerminado: 'Viaje terminado',
  };

  static const _messages = {
    TripNotificationType.conductorEnCamino: 'Tu conductor va hacia ti',
    TripNotificationType.viajeEnCurso: 'Tu viaje ha comenzado',
    TripNotificationType.viajeTerminado: 'Gracias por viajar con Jala',
  };

  /// Inicializa el servicio y crea el canal de Android.
  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _createAndroidChannel();
  }

  /// Crea el canal de Android con sonido personalizado y vibración.
  Future<void> _createAndroidChannel() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    // Sonido personalizado desde res/raw
    final androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: false, // Controlado por vibrationPattern
      vibrationPattern: Int64List.fromList([
        0,    // inicio
        110,  // toque 1: vibra 110ms
        50,   // silencio: 50ms
        160,  // toque 2: vibra 160ms
      ]),
      sound: RawResourceAndroidNotificationSound('notificacion_claxon'),
    );

    await androidPlugin.createNotificationChannel(androidChannel);
  }

  /// Muestra una notificación de viaje con auto-dismiss.
  Future<void> showTripNotification(TripNotificationType type, {String? tripId}) async {
    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final title = _titles[type]!;
    final body = _messages[type]!;
    final autoDismissSeconds = _autoDismissSeconds[type]!;

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: JalaBrand.amber,
        // Sonido personalizado
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
        ),
        // Vibración con patrón sincronizado al sonido
        enableVibration: false,
        vibrationPattern: Int64List.fromList([
          0,
          110,  // toque 1
          50,   // silencio
          160,  // toque 2
        ]),
        // Lock screen
        fullScreenIntent: true,
        category: AndroidNotificationCategory.message,
      ),
    );

    await _plugin.show(id, title, body, details, payload: tripId);

    // Auto-dismiss después de N segundos
    Timer(Duration(seconds: autoDismissSeconds), () {
      _plugin.cancel(id);
    });
  }

  /// Maneja el tap en la notificación — navega a la pantalla del viaje.
  void _onNotificationTapped(NotificationResponse response) {
    final tripId = response.payload;
    if (tripId == null || tripId.isEmpty) return;

    // Navegar a la pantalla del viaje en curso
    final navigatorKey = AppNavigator.key;
    final context = navigatorKey.currentContext;
    if (context == null) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.tripInProgress,
      (route) => route.isFirst,
      arguments: tripId,
    );
  }
}
